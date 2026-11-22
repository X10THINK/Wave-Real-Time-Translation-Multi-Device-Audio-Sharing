package com.x10think.wave

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.media.projection.MediaProjection
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.util.UUID
import java.util.concurrent.LinkedBlockingDeque
import java.util.concurrent.TimeUnit
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/** Android Bluetooth Classic RFCOMM application-level audio relay experiment.
 *  Physical peer pairing/mesh edges require explicit setup. No cloud or auto physical mesh.
 *  Relays forward packets from every validated source even when their speaker is muted.
 */
internal class MeshEngine(private val context: Context, private val callback: (Map<String, Any?>) -> Unit) {
    companion object {
        // Three distinct SDP services per phone: RFCOMM accepts one peer per occupied slot.
        private val SLOTS = (1..3).map { i ->
            UUID.fromString("72617665-6d65-7368-8000-00000000000$i")
        }
        private const val MAX_HOPS = 5
        private const val RECONNECT_DELAY_MS = 4_000L
        private const val PEER_JOIN_GRACE_MS = RelayLinkPolicy.JOIN_GRACE_MS
        private const val QUEUE_CAPACITY = 6 // bounded queues; low latency wins over stale packets
    }

    private val main = Handler(Looper.getMainLooper())
    private val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val adapter: BluetoothAdapter? get() = btManager.adapter
    private val prefs = context.getSharedPreferences("wave_mesh", Context.MODE_PRIVATE)
    val nodeId: Long by lazy {
        val old = prefs.getLong("nodeId", 0L)
        if (old != 0L) old else UUID.randomUUID().mostSignificantBits.let { value ->
            (if (value == 0L) 1L else value).also { prefs.edit().putLong("nodeId", it).apply() }
        }
    }
    private val running = AtomicBoolean(false)
    @Volatile private var crypto: SecureEnvelope? = null
    @Volatile private var inviteSecret: String = ""
    fun inviteSecretForHost(): String = if (host && running.get()) inviteSecret else ""
    @Volatile private var globalPlaybackPaused=false
    private var lastGlobalStateMs=0L
    fun setGlobalPlaybackState(playing:Boolean) {
        check(host && running.get()) { "Host-only shared playback" }
        globalPlaybackPaused=!playing
        broadcastGlobalState()
        push()
    }
    private fun broadcastGlobalState() {
        if(!host || !running.get())return
        val action=if(globalPlaybackPaused)6 else 5
        val sequence=directRemoteSeq.incrementAndGet()
        peers.values.filter { it.verified.get() }.forEach { p->
            p.enqueue(MeshProtocol.control(nodeId,0L,sequence,action,100))
        }
        lastGlobalStateMs=SystemClock.elapsedRealtime()
    }
    private val directRemoteSeq = AtomicInteger(0)
    private val acceptedHostCommands = ConcurrentHashMap<Long,Int>()
    @Volatile private var speakerRole=0
    /** Direct verified Bluetooth peers only. Routed downstream receiver
     * controls need a separately authenticated host-identity protocol. */
    fun controlReceiver(address:String, action:String, value:Int) {
        check(host && running.get()) { "Only Host can command receiver" }
        require(action in setOf("PLAY","PAUSE","GAIN","ROLE") && value in 0..100)
        if(action=="ROLE")require(value in 0..8)
        val peer=peers[address] ?: error("Receiver has no direct Bluetooth link")
        check(peer.verified.get()) { "Peer is not verified" }
        desired.getOrPut(address){ConcurrentHashMap()}[action]=value
        val type=when(action){"PLAY"->1;"PAUSE"->2;"GAIN"->3;else->4}
        peer.enqueue(MeshProtocol.control(nodeId,peer.remoteNodeId,
            directRemoteSeq.incrementAndGet(),type,value))
    }
    private val captionInbox=TranslationCaptionWire.Inbox()
    private val captionCounter=AtomicLong(0L)
    @Volatile private var lastCaption:TranslationCaptionWire.Caption?=null

    /** Verified DIRECT Bluetooth Host->Receiver captions only. Forwarding
     * over untrusted downstream links needs separately authenticated identities. */
    fun broadcastTranslationCaption(language:String,text:String) {
        check(host && running.get()) { "Only Host can broadcast translation" }
        require(language in setOf("ta","en"))
        require(text.toByteArray(Charsets.UTF_8).size <= 360) {
            "Bluetooth captions over 360 UTF-8 bytes need smaller utterances"
        }
        val pieces=TranslationCaptionWire.split(text)
        val seq=captionCounter.incrementAndGet()
        peers.values.filter {it.verified.get()}.forEach {peer ->
            pieces.forEach {part ->
                val wire=listOf(nodeId.toString(),seq.toString(),language,
                    part.total.toString(),part.index.toString(),part.value).joinToString("|")
                peer.enqueue(MeshProtocol.Packet(MeshProtocol.TRANSLATION_CAPTION,
                    wire.toByteArray(Charsets.UTF_8)))
            }
        }
    }

    private val history = FrameHistory()
    @Volatile private var lastAudioOrigin: Long? = null
    private val syncReqHistory = FrameHistory()
    private val syncReplyHistory = FrameHistory()
    private val syncSeq = AtomicInteger(0)
    @Volatile private var hostClockOffsetNs: Long? = null // host - receiver
    @Volatile private var syncRttMs = -1.0
    @Volatile private var lastSyncSampleMs = 0L
    @Volatile private var targetDelayMs = 280
    private val waitingForSync = AtomicLong(0)

    private val peers = ConcurrentHashMap<String, Peer>()
    private val connecting = ConcurrentHashMap.newKeySet<String>()
    private val wantedOutgoing = ConcurrentHashMap.newKeySet<String>()
    private val lastAttempt = ConcurrentHashMap<String, Long>()
    // Remember verified remote identities. Only one side automatically re-dials a
    // broken established link, avoiding simultaneous RFCOMM reconnect collisions.
    private val knownRemoteNodeIds = ConcurrentHashMap<String, Long>()
    @Volatile private var joinGraceUntilMs = 0L
    @Volatile private var lastDisconnectReason: String = ""
    @Synchronized private fun protectExistingLinksDuringJoin() {
        val until = SystemClock.elapsedRealtime() + PEER_JOIN_GRACE_MS
        if (until > joinGraceUntilMs) joinGraceUntilMs = until
    }
    private val listeners = arrayOfNulls<BluetoothServerSocket>(SLOTS.size)
    private val listenerLock = Any()
    private var statsThread: Thread? = null
    private var room: String = ""
    private var host = false
    private var requireApproval=false
    private var capacity=10
    private var displayName="Listener"
    private val desired=ConcurrentHashMap<String,MutableMap<String,Int>>()
    private val denied=ConcurrentHashMap.newKeySet<String>()
    private val sequence = AtomicInteger(0)
    @Volatile private var streamOrigin = UUID.randomUUID().mostSignificantBits
    private val sent = AtomicLong(0)
    private val received = AtomicLong(0)
    private val duplicates = AtomicLong(0)
    private val forwarded = AtomicLong(0)
    private val linkDrops = AtomicLong(0)
    private val events = ArrayDeque<String>()
    private val eventLock = Any()
    private val opus = OpusFrameCodec()
    @Volatile private var opusEnabled = false
    fun setOpus(enabled:Boolean): Boolean {
        opusEnabled=enabled && opus.startEncoder()
        push();return opusEnabled
    }
    // Never encode, encrypt, or send on AudioRecord / Media3 rendering threads.
    private data class QueuedPcm(val pcm:ByteArray,val capturedNs:Long)
    private val outgoingAudio = LinkedBlockingDeque<QueuedPcm>(8)
    private val droppedSenderFrames=AtomicLong(0)
    private var uplinkThread: Thread? = null
    private val audio = AudioPipeline(context) { pcm -> queueAudio(pcm) }
    private fun queueAudio(pcm: ByteArray) {
        if(!running.get() || !host)return
        val item=QueuedPcm(pcm,SystemClock.elapsedRealtimeNanos())
        if(!outgoingAudio.offerLast(item)) {
            outgoingAudio.pollFirst();droppedSenderFrames.incrementAndGet();outgoingAudio.offerLast(item)
        }
    }
    private fun startUplinkWorker() {
        uplinkThread = Thread({
            while(running.get()) {
                val pcm=try {outgoingAudio.poll(200,TimeUnit.MILLISECONDS)}
                    catch (_:InterruptedException) {break} ?: continue
                if(SystemClock.elapsedRealtimeNanos()-pcm.capturedNs>180_000_000L) {
                    droppedSenderFrames.incrementAndGet();continue
                }
                if(running.get() && host) emitMicAudio(pcm.pcm,pcm.capturedNs)
            }
        }, "WAVEMeshEngineAudioSender").apply {isDaemon=true;start()}
    }
    /** Global Stop Playback keeps the room alive and stops the current source.
     * The receiver jitter buffer drains, then becomes silent. */
    fun stopSharedAudio() {
        check(host && running.get()) { "Only Host can stop shared playback" }
        WaveInternalMediaTap.setSink(null)
        outgoingAudio.clear()
        audio.stopCapture()
        audio.releaseInternalMedia()
        push()
    }
    fun setInternalMedia(enabled: Boolean) {
        check(host && running.get()) {"Only the active host may share imported media"}
        WaveInternalMediaTap.setSink(null)
        outgoingAudio.clear()
        if(enabled) {
            audio.useInternalMedia()
            WaveInternalMediaTap.setSink {pcm -> audio.acceptInternalMedia(pcm)}
        } else audio.releaseInternalMedia()
        push()
    }
    @Volatile private var lastSyncRequestMs = 0L

    fun isRunning() = running.get()

    fun permissions(isHost: Boolean): Array<String> = buildList {
        if (Build.VERSION.SDK_INT >= 31) add(Manifest.permission.BLUETOOTH_CONNECT)
        if (isHost) add(Manifest.permission.RECORD_AUDIO)
    }.toTypedArray()

    fun hasPermissions(isHost: Boolean) = permissions(isHost).all {
        context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED
    }

    fun bluetoothReady() = adapter?.isEnabled == true

    @SuppressLint("MissingPermission")
    fun pairedDevices(): List<Map<String, String>> {
        check(context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < 31) {
            "Bluetooth permission not granted"
        }
        return (adapter?.bondedDevices ?: emptySet()).map { d ->
            mapOf("name" to (d.name ?: "Android device"), "address" to d.address)
        }.sortedBy { it["name"] }
    }

    @Volatile private var selectedHost: String? = null

    @Synchronized fun start(roomCode: String, isHost: Boolean, invite: String, approval:Boolean=false, maxUsers:Int=10, userName:String="Listener") {
        check(!running.get()) { "Stop current session first" }
        check(hasPermissions(false)) { "Required Bluetooth permission missing" }
        check(bluetoothReady()) { "Enable Bluetooth in Android Settings" }
        val normalized = roomCode.trim().uppercase()
        require(normalized.matches(Regex("[A-Z0-9-]{4,12}"))) { "Room code must be 4-12 letters/numbers" }
        selectedHost = null
        room = normalized
        requireApproval=approval;capacity=maxUsers.coerceIn(1,100);displayName=userName.take(40);desired.clear();denied.clear()
        globalPlaybackPaused=false;lastGlobalStateMs=0L
        audio.playbackEnabled=true;audio.volume=.8f
        audio.sessionPlaybackEnabled=true
        crypto = SecureEnvelope(invite, normalized)
        inviteSecret = if (isHost) invite else ""
        host = isHost
        captionInbox.clear();captionCounter.set(0L);lastCaption=null
        streamOrigin = UUID.randomUUID().mostSignificantBits
        sequence.set(0)
        sent.set(0); received.set(0); duplicates.set(0); forwarded.set(0); linkDrops.set(0)
        history.clear(); syncReqHistory.clear(); syncReplyHistory.clear()
        lastAudioOrigin=null
        hostClockOffsetNs = if (host) 0L else null
        syncRttMs = -1.0; lastSyncSampleMs = 0L; lastSyncRequestMs = 0L
        audio.droppedPlayback.set(0);audio.latePlayback.set(0);audio.underruns.set(0)
        waitingForSync.set(0)
        synchronized(eventLock) { events.clear() }
        knownRemoteNodeIds.clear()
        acceptedHostCommands.clear();directRemoteSeq.set(0);speakerRole=0
        audio.hostPlaybackEnabled=true;audio.hostVolume=1.0f
        joinGraceUntilMs = 0L
        lastDisconnectReason = ""
        running.set(true)
        startUplinkWorker()
        try {
            if (!host) audio.startPlayback()
            SLOTS.indices.forEach { startSlot(it) }
            statsThread = Thread({
                while (running.get()) {
                    for (p in peers.values) {
                        // Joining another phone can temporarily stall the radio, SDP and RFCOMM.
                        // Never tear down A↔B merely because D is joining B. Keep sockets
                        // independently alive while the radio is establishing peer links.
                        val now = SystemClock.elapsedRealtime()
                        if (p.verified.get() && RelayLinkPolicy.shouldClose(
                                now, p.lastHeardMs, p.writingSinceMs, joinGraceUntilMs)) {
                            val why = if (p.writingSinceMs > 0 &&
                                now - p.writingSinceMs >= RelayLinkPolicy.WRITE_STALL_MS)
                                "stalled RFCOMM writer" else "peer heartbeat timeout"
                            p.close("watchdog: $why")
                            continue
                        }
                        if (p.verified.get()) p.enqueue(MeshProtocol.Packet(MeshProtocol.PING,
                            MeshProtocol.millisToken(SystemClock.elapsedRealtimeNanos())))
                    }
                    if (!host && peers.values.any { it.verified.get() } &&
                        SystemClock.elapsedRealtime() - lastSyncRequestMs >= 2_000L) {
                        sendClockSyncRequest()
                        lastSyncRequestMs = SystemClock.elapsedRealtime()
                    }
                    for (address in wantedOutgoing) {
                        if (!peers.containsKey(address) && !connecting.contains(address)) {
                            val last = lastAttempt[address] ?: 0L
                            val remoteNodeId = knownRemoteNodeIds[address]
                            if (remoteNodeId != null &&
                                !RelayLinkPolicy.isReconnectOwner(nodeId, remoteNodeId)) continue
                            if (SystemClock.elapsedRealtime() - last >= RECONNECT_DELAY_MS) connectTo(address, false)
                        }
                    }
                    if(host && SystemClock.elapsedRealtime()-lastGlobalStateMs>1500L) {
                        broadcastGlobalState()
                        desired.forEach {(address,values)->if(peers[address]?.verified?.get()==true)values.forEach {(op,value)->controlReceiver(address,op,value)}}
                    }
                    // A neighbor connection is not proof that the Host is still reachable.
                    if(!host && SystemClock.elapsedRealtime()-lastSyncSampleMs>7000L)hostClockOffsetNs=null
                    peers.values.filter{!it.verified.get() && SystemClock.elapsedRealtime()-it.lastHeardMs>30000L}.forEach{it.close("Join timed out")}
                    push()
                    try { Thread.sleep(1000) } catch (_: InterruptedException) { break }
                }
            }, "MeshStatistics").apply { start() }
            log(if (host) "HOST ready. Connect peers, then Start microphone." else "RECEIVER ready. Connect to nearby paired phones.")
        } catch (t: Throwable) {
            stop()
            throw t
        }
    }

    @Synchronized fun stop() {
        if (!running.getAndSet(false)) return
        // First shut down audio; then terminate all socket readers/writers/listener slots.
        WaveInternalMediaTap.setSink(null)
        outgoingAudio.clear()
        droppedSenderFrames.set(0)
        uplinkThread?.interrupt();uplinkThread=null
        audio.stopAll()
        opus.close();opusEnabled=false
        crypto = null; inviteSecret = ""
        synchronized(listenerLock) {
            listeners.forEachIndexed { slot, server ->
                try { server?.close() } catch (_: Exception) {}
                listeners[slot] = null
            }
        }
        peers.values.toList().forEach { it.close("session stopped") }
        peers.clear()
        wantedOutgoing.clear()
        knownRemoteNodeIds.clear()
        connecting.clear()
        statsThread?.interrupt()
        statsThread = null
        log("Session ended")
        push()
    }

    @SuppressLint("MissingPermission")
    private fun startSlot(slot: Int) {
        Thread({
            while (running.get()) {
                var server: BluetoothServerSocket? = null
                try {
                    server = adapter?.listenUsingRfcommWithServiceRecord("WAVE Mesh ${slot + 1}", SLOTS[slot])
                        ?: throw IOException("No Bluetooth adapter")
                    synchronized(listenerLock) { if (running.get()) listeners[slot] = server }
                    if (!running.get()) { server.close(); break }
                    val socket = server.accept()
                    protectExistingLinksDuringJoin()
                    try { server.close() } catch (_: Exception) {}
                    synchronized(listenerLock) { if (listeners[slot] === server) listeners[slot] = null }
                    if (!running.get()) { socket.close(); break }
                    val peer = attach(socket, inboundSlot = slot)
                    // This RFCOMM service UUID/slot is occupied until its accepted socket dies.
                    while (running.get() && peer != null && peer.alive.get()) {
                        try { Thread.sleep(250) } catch (_: InterruptedException) { break }
                    }
                } catch (e: Exception) {
                    if (running.get()) log("Accept slot ${slot + 1}: ${e.message}")
                } finally {
                    try { server?.close() } catch (_: Exception) {}
                    synchronized(listenerLock) { if (listeners[slot] === server) listeners[slot] = null }
                }
                if (running.get()) try { Thread.sleep(250) } catch (_: InterruptedException) { break }
            }
        }, "MeshAccept$slot").start()
    }

    @SuppressLint("MissingPermission")
    @Synchronized fun connectTo(address: String, manual: Boolean = true) {
        check(running.get()) { "Start a session before connecting" }
        require(BluetoothAdapter.checkBluetoothAddress(address)) { "Invalid device address" }
        if (!host && manual && selectedHost != address) {
            check(peers.values.none { it.verified.get() }) { "Disconnect from the current host first" }
            val previous = selectedHost
            selectedHost = address
            if (previous != null) {
                wantedOutgoing.remove(previous)
                peers[previous]?.close("Host selection changed")
            }
        }
        if(!host && selectedHost != address) return
        if (manual) wantedOutgoing.add(address)
        if (peers.containsKey(address) || !connecting.add(address)) return
        // Only user-initiated new joins extend the grace window. Automatic
        // retries must not renew grace forever and suppress dead-link recovery.
        if (manual) protectExistingLinksDuringJoin()
        lastAttempt[address] = SystemClock.elapsedRealtime()
        Thread({
            try {
                val device = adapter?.getRemoteDevice(address) ?: throw IOException("Bluetooth unavailable")
                try { adapter?.cancelDiscovery() } catch (_: Exception) {}
                var connected = false
                var error: String = "No open RFCOMM slot"
                for (slot in SLOTS) {
                    if (!running.get() || peers.containsKey(address)) break
                    var socket: BluetoothSocket? = null
                    try {
                        socket = device.createRfcommSocketToServiceRecord(slot)
                        socket.connect()
                        if (running.get()) {
                            if (attach(socket, null) != null) connected = true else socket.close()
                        } else socket.close()
                        if (connected) break
                    } catch (t: Exception) {
                        error = t.message ?: "Connection refused"
                        try { socket?.close() } catch (_: Exception) {}
                    }
                }
                if (!connected && running.get() && !peers.containsKey(address)) log("Connect $address failed: $error")
            } finally {
                connecting.remove(address)
                push()
            }
        }, "MeshConnect-${address.takeLast(5)}").start()
    }

    @Synchronized fun approve(address:String,allow:Boolean) {
        check(host && running.get())
        val peer=peers[address]?:return
        if(!peer.helloReceived)return
        if(!allow || peers.values.count{it.verified.get()}>=capacity){denied.add(address);peer.close("Host denied request or room full");return}
        peer.verified.set(true)
        peer.enqueue(MeshProtocol.Packet(MeshProtocol.ADMITTED,byteArrayOf()))
        broadcastGlobalState();push()
    }
    @Synchronized fun blockPeer(address: String) {
        check(host)
        denied.add(address)
        disconnect(address)
    }

    fun disconnect(address: String) {
        wantedOutgoing.remove(address)
        peers[address]?.close("user disconnected peer")
        push()
    }

    @SuppressLint("MissingPermission")
    private fun attach(socket: BluetoothSocket, inboundSlot: Int?): Peer? {
        val address = try { socket.remoteDevice.address } catch (_: Exception) { socket.close(); return null }
        if (!host && address != selectedHost) { socket.close(); return null }
        val peer = Peer(socket, address, inboundSlot)
        val existing = peers.putIfAbsent(address, peer)
        if (existing != null) {
            // Two simultaneous dials to same phone: keep one socket, never double-play.
            try { socket.close() } catch (_: Exception) {}
            return null
        }
        peer.launch()
        log("Linked $address; validating room...")
        push()
        return peer
    }

    private data class Outbound(val packet:MeshProtocol.Packet,val enqueuedMs:Long)
    private inner class Peer(
        val socket: BluetoothSocket,
        val address: String,
        val inboundSlot: Int?
    ) {
        val alive = AtomicBoolean(true)
        val verified = AtomicBoolean(false)
        val out = LinkedBlockingDeque<Outbound>(QUEUE_CAPACITY)
        @Volatile var writingSinceMs=0L
        val dropped = AtomicLong(0)
        @Volatile var remoteNodeId = 0L
        @Volatile var remoteHost=false
        @Volatile var remoteName="Listener"
        @Volatile var helloReceived=false
        @Volatile var rttMs = -1.0
        @Volatile var lastHeardMs = SystemClock.elapsedRealtime()

        fun enqueue(packet: MeshProtocol.Packet) {
            if (!alive.get()) return
            // Translation captions are best-effort and must NEVER close an
            // active audio link if the small Bluetooth writer queue fills.
            val important = packet.kind != MeshProtocol.AUDIO &&
                packet.kind != MeshProtocol.TRANSLATION_CAPTION
            val item=Outbound(packet,SystemClock.elapsedRealtime())
            // Subtitle fragments are lower priority than handshake and audio.
            // Never evict an audio packet or disconnect a peer for captions.
            if(packet.kind==MeshProtocol.TRANSLATION_CAPTION){
                if(out.size >= QUEUE_CAPACITY-2 || !out.offerLast(item)) dropped.incrementAndGet()
                return
            }

            if (if (important) out.offerLast(item) else out.offerLast(item)) return
            // Favor a newer audio frame over old audio. Preserve urgent control where possible.
            val oldAudio=out.firstOrNull{it.packet.kind==MeshProtocol.AUDIO}
            if(oldAudio!=null && out.remove(oldAudio)) {
                dropped.incrementAndGet();linkDrops.incrementAndGet()
                if(important)out.offerLast(item)else out.offerLast(item)
            } else if(important) {
                // Never silently drop a handshake/control command behind audio.
                close("Control queue stalled; reconnecting")
            } else {dropped.incrementAndGet();linkDrops.incrementAndGet()}

        }

        fun launch() {
            Thread({
                try {
                    val stream = DataOutputStream(socket.outputStream)
                    enqueue(MeshProtocol.greeting(room, nodeId, host,displayName))
                    while (running.get() && alive.get()) {
                        val queued = out.poll(500, java.util.concurrent.TimeUnit.MILLISECONDS) ?: continue
                        // An obsolete audio packet is worse than a dropped frame.
                        if(queued.packet.kind==MeshProtocol.AUDIO &&
                           SystemClock.elapsedRealtime()-queued.enqueuedMs>280L) {
                            dropped.incrementAndGet();linkDrops.incrementAndGet();continue
                        }
                        val packet=queued.packet
                        val sendPacket = if (host && packet.kind == MeshProtocol.SYNC_REPLY) {
                            val sync = MeshProtocol.parseSyncReply(packet.data)
                            MeshProtocol.syncReply(sync.requester, sync.requestSeq,
                                sync.t1, sync.t2, SystemClock.elapsedRealtimeNanos(), sync.hops)
                        } else packet
                        // The encrypted blob is length-prefixed; plaintext never crosses RFCOMM.
                        val raw = java.io.ByteArrayOutputStream().also {
                            MeshProtocol.write(DataOutputStream(it), sendPacket)
                        }.toByteArray()
                        val sealed = crypto?.seal(raw) ?: break
                        writingSinceMs=SystemClock.elapsedRealtime()
                        stream.writeShort(sealed.size)
                        stream.write(sealed)
                        stream.flush()
                        writingSinceMs=0L
                    }
                } catch (e: Exception) {
                    if (running.get()) log("Writer $address: ${e.message}")
                    close("writer failed: ${e.javaClass.simpleName}")
                } finally { close("writer ended") }
            }, "MeshWriter-${address.takeLast(5)}").start()

            Thread({
                try {
                    val stream = DataInputStream(socket.inputStream)
                    while (running.get() && alive.get()) {
                        val length = stream.readUnsignedShort()
                        if(length !in 33..4096) throw IOException("Invalid secure Bluetooth frame size")
                        val sealed = ByteArray(length)
                        stream.readFully(sealed)
                        val raw = crypto?.open(sealed) ?: break
                        val packet = MeshProtocol.read(DataInputStream(raw.inputStream()))
                        lastHeardMs = SystemClock.elapsedRealtime()
                        when (packet.kind) {
                            MeshProtocol.HELLO -> {
                                val hello = MeshProtocol.parseGreeting(packet.data)
                                if (helloReceived || hello.room != room || hello.nodeId == nodeId || (host && hello.host)) {
                                    throw IOException("Wrong room or duplicate host")
                                }
                                remoteHost=hello.host;remoteName=hello.name;helloReceived=true
                                remoteNodeId = hello.nodeId
                                knownRemoteNodeIds[address] = hello.nodeId
                                if(host) {
                                    if(address in denied || peers.values.count{it.verified.get()}>=capacity){close("Room full or access denied");continue}
                                    if(requireApproval){log("Join request from ${hello.name}");push();continue}
                                    approve(address,true)
                                    if (!verified.get()) continue
                                } else if(!hello.host) {
                                    // Relay admission requires a host-issued identity protocol.
                                    close("Connect directly to the Host in this edition");continue
                                }
                                // Receivers wait for explicit admission, not just HELLO.
                                if(!host)continue
                                verified.set(true)
                                protectExistingLinksDuringJoin()
                                // Kick off host clock sync immediately after peer verification;
                                // waiting for the 1-second stats tick delays initial audio.
                                if(!host) {
                                    sendClockSyncRequest()
                                    lastSyncRequestMs=SystemClock.elapsedRealtime()
                                }
                                // Remember authenticated reachable neighbours, including inbound
                                // links, so either peer can re-dial after radio disruption.
                                wantedOutgoing.add(address)
                                log("Verified $address in room $room")
                                if(host) broadcastGlobalState()
                            }
                            MeshProtocol.ADMITTED -> {
                                if(!host && remoteHost && helloReceived) {
                                    verified.set(true);wantedOutgoing.add(address)
                                    sendClockSyncRequest();lastSyncRequestMs=SystemClock.elapsedRealtime();push()
                                }
                            }
                            MeshProtocol.TRANSLATION_CAPTION -> if(verified.get() && !host && remoteHost) {
                                val fields=packet.data.toString(Charsets.UTF_8).split('|',limit=6)
                                if(fields.size==6 && fields[0]==remoteNodeId.toString()){
                                    val seq=fields[1].toLongOrNull()
                                    val count=fields[3].toIntOrNull()
                                    val index=fields[4].toIntOrNull()
                                    if(seq!=null && count!=null && index!=null){
                                        val caption=captionInbox.accept(seq,fields[2],count,index,fields[5])
                                        if(caption!=null){lastCaption=caption;push()}
                                    }
                                }
                            }
                            MeshProtocol.AUDIO -> if (verified.get()) processAudio(this, packet.data)
                            MeshProtocol.PING -> if (verified.get()) enqueue(MeshProtocol.Packet(MeshProtocol.PONG, packet.data))
                            MeshProtocol.PONG -> if (verified.get()) {
                                val elapsed = SystemClock.elapsedRealtimeNanos() - MeshProtocol.parseToken(packet.data)
                                if (elapsed >= 0) rttMs = elapsed / 1_000_000.0
                            }
                            MeshProtocol.SYNC_REQ -> if (verified.get()) processSyncRequest(this, packet.data)
                            MeshProtocol.SYNC_REPLY -> if (verified.get()) processSyncReply(this, packet.data)
                            MeshProtocol.REMOTE_CONTROL -> if (verified.get()) {
                                val c=MeshProtocol.parseControl(packet.data)
                                // Direct Host link authentication; never accept spoofed
                                // forwarded instructions from arbitrary neighbours.
                                if(!host && remoteHost && (c.target==nodeId || (c.target==0L && c.action in 5..6))
                                    && c.origin==remoteNodeId) {
                                    val prev=acceptedHostCommands[c.origin]?:-1
                                    if(c.seq>prev) {
                                        acceptedHostCommands[c.origin]=c.seq
                                        when(c.action) {
                                            1->audio.hostPlaybackEnabled=true
                                            2->audio.hostPlaybackEnabled=false
                                            3->audio.hostVolume=c.gainPercent/100f
                                            4->if(c.gainPercent in 0..8)speakerRole=c.gainPercent
                                            5->{globalPlaybackPaused=false;audio.sessionPlaybackEnabled=true}
                                            6->{globalPlaybackPaused=true;audio.sessionPlaybackEnabled=false}
                                        }
                                        push()
                                    }
                                }
                            }
                            else -> throw IOException("Unknown packet type")
                        }
                    }
                } catch (e: Exception) {
                    if (running.get()) log("Link $address lost: ${e.message}")
                    close("reader failed: ${e.javaClass.simpleName}")
                } finally { close("reader ended") }
            }, "MeshReader-${address.takeLast(5)}").start()
        }

        fun close(reason: String = "connection closed") {
            if (!alive.compareAndSet(true, false)) return
            verified.set(false)
            if (running.get()) lastDisconnectReason = "$address: $reason"
            writingSinceMs=0L
            try { socket.close() } catch (_: Exception) {}
            peers.remove(address, this)
            if (running.get()) log("Disconnected $address ($reason); ${peers.size} routes remain")
            push()
        }
    }

    /** Four timestamp handshake, flooded through existing relay graph. No assumed shared device clock. */
    private fun sendClockSyncRequest() {
        val seq = syncSeq.incrementAndGet()
        val now = SystemClock.elapsedRealtimeNanos()
        syncReqHistory.firstTime(nodeId, seq)
        val msg = MeshProtocol.syncRequest(nodeId, seq, now, 0)
        for (p in peers.values) if (p.verified.get()) p.enqueue(msg)
    }

    private fun processSyncRequest(from: Peer, data: ByteArray) {
        val req = MeshProtocol.parseSyncRequest(data)
        if (req.hops > MAX_HOPS || !syncReqHistory.firstTime(req.requester, req.requestSeq)) return
        if (host) {
            val t2 = SystemClock.elapsedRealtimeNanos()
            val t3 = SystemClock.elapsedRealtimeNanos()
            from.enqueue(MeshProtocol.syncReply(req.requester, req.requestSeq, req.t1, t2, t3, 0))
        } else if (req.hops < MAX_HOPS) {
            val fwd = MeshProtocol.syncRequest(req.requester, req.requestSeq, req.t1, req.hops + 1)
            for (p in peers.values) if (p !== from && p.verified.get()) p.enqueue(fwd)
        }
    }

    private fun processSyncReply(from: Peer, data: ByteArray) {
        val rep = MeshProtocol.parseSyncReply(data)
        if (rep.hops > MAX_HOPS) return
        if (rep.requester == nodeId && !host) {
            // Permit duplicate replies for the same request via different diamond paths:
            // the lower-RTT sample has a better chance of estimating the host clock.

            val estimate = ClockMath.estimate(rep.t1, rep.t2, rep.t3,
                SystemClock.elapsedRealtimeNanos()) ?: return
            val now = SystemClock.elapsedRealtime()
            val delay = estimate.rttNanos / 1_000_000.0
            // Use lowest-delay route to suppress asymmetric queuing bias. Refresh stale reference.
            if (hostClockOffsetNs == null || now - lastSyncSampleMs > 20_000L ||
                delay < syncRttMs * 1.10) {
                val old = hostClockOffsetNs
                hostClockOffsetNs = if (old == null) estimate.offsetNanos
                    else (old * 3 + estimate.offsetNanos) / 4
                syncRttMs = delay
                lastSyncSampleMs = now
            }
            push()
        } else if (rep.hops < MAX_HOPS && syncReplyHistory.firstTime(rep.requester, rep.requestSeq)) {
            val fwd = MeshProtocol.syncReply(rep.requester, rep.requestSeq,
                rep.t1, rep.t2, rep.t3, rep.hops + 1)
            for (p in peers.values) if (p !== from && p.verified.get()) p.enqueue(fwd)
        }
    }

    private fun processAudio(from: Peer, data: ByteArray) {
        val a = MeshProtocol.parseAudio(data)
        if (a.hops > MAX_HOPS) return
        if(lastAudioOrigin!=a.origin) {
            lastAudioOrigin=a.origin
            history.clear();audio.resetPlaybackStream();opus.closeDecoder()
        }
        if (!history.firstTime(a.origin, a.sequence)) { duplicates.incrementAndGet(); return }
        received.incrementAndGet()
        if (!host) {
            val offset = hostClockOffsetNs
            if (offset == null) waitingForSync.incrementAndGet()
            else {
                val pcm=if(a.codec==1){if(opus.startDecoder()) opus.decode(a.pcm) else null}else a.pcm
                if(pcm!=null) audio.enqueue(a.sequence, pcm,
                    ClockMath.receiverDeadline(a.capturedAtNs, a.playoutDelayMs, offset))
            }
        }
        if (a.hops < MAX_HOPS) {
            val onward = MeshProtocol.audio(a.origin, a.sequence, a.hops + 1,
                a.capturedAtNs, a.playoutDelayMs, a.pcm, a.codec)
            for (p in peers.values) {
                if (p !== from && p.verified.get()) { p.enqueue(onward); forwarded.incrementAndGet() }
            }
        }
    }

    private fun emitMicAudio(pcm: ByteArray,capturedNs:Long) {
        if (!running.get() || !host) return
        val seq = sequence.getAndIncrement()
        history.firstTime(streamOrigin, seq)
        val encoded=if(opusEnabled) opus.encode(pcm) else null
        val packet = MeshProtocol.audio(streamOrigin, seq, 0,
            capturedNs, targetDelayMs, encoded ?: pcm,
            if(encoded==null) 0 else 1)
        for (p in peers.values) {
            if (p.verified.get()) { p.enqueue(packet); sent.incrementAndGet() }
        }
    }

    fun setMic(enabled: Boolean) {
        check(running.get() && host) { "Microphone only available to active host" }
        if (enabled) {WaveInternalMediaTap.setSink(null);outgoingAudio.clear();audio.startCapture();setGlobalPlaybackState(true)} else audio.stopCapture()
        log(if (enabled) "Host microphone LIVE" else "Host microphone stopped")
        push()
    }

    fun setDeviceAudio(projection: MediaProjection) {
        check(running.get() && host) { "Start HOST session first" }
        WaveInternalMediaTap.setSink(null);outgoingAudio.clear()
        audio.startDeviceAudio(projection)
        setGlobalPlaybackState(true)
        log("Device audio capture active — only capturable media will stream")
        push()
    }

    fun setTargetDelay(ms: Int) {
        require(ms in 160..600) { "Delay target must be 160..600 ms" }
        targetDelayMs = ms
        log("Shared playout delay target: ${ms}ms")
        push()
    }

    fun setFastMode(fast: Boolean) {
        audio.primeFrames = if (fast) 2 else 3
        push()
    }

    fun setPlayback(enabled: Boolean, volume: Double) {
        audio.volume = volume.toFloat()
        audio.playbackEnabled = enabled
        push()
    }

    private fun wifiRadioOn(): Boolean = try {
        val wifi=context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? android.net.wifi.WifiManager
        wifi?.isWifiEnabled == true
    } catch (_:Exception) { false }
    fun state(): Map<String, Any?> {
        val peerStates = peers.values.map { p ->
            mapOf<String, Any?>(
                "address" to p.address, "verified" to p.verified.get(),"name" to p.remoteName,
                "gain" to desired[p.address]?.get("GAIN"),"role" to desired[p.address]?.get("ROLE"),
                "rfcommSlot" to (p.inboundSlot?.let { it + 1 } ?: 0),
                "rttMs" to p.rttMs, "pending" to p.out.size,
                "dropped" to p.dropped.get(), "remoteNodeId" to p.remoteNodeId,
                "ageMs" to (SystemClock.elapsedRealtime() - p.lastHeardMs)
            )
        }.sortedBy { it["address"].toString() }
        return mapOf(
            "running" to running.get(), "host" to host, "room" to room,
            "joined" to (host || (hostClockOffsetNs != null && peerStates.any { it["verified"] == true })),
            "relay" to (!host && peerStates.count { it["verified"] == true } > 1),
            "nodeId" to nodeId.toString(), "connected" to peerStates.count { it["verified"] == true },
            "peers" to peerStates.filter{it["verified"]==true},
            "pending" to peers.values.filter{host && it.helloReceived && !it.verified.get()}.map{mapOf("id" to it.address,"name" to it.remoteName,"ip" to it.address)}, "capturing" to audio.isCapturing,
            "captureSource" to audio.sourceKind,
            "senderQueue" to outgoingAudio.size,"senderDrops" to droppedSenderFrames.get(),
            "mediaPcmFrames" to WaveInternalMediaTap.frameCount(), "targetDelayMs" to targetDelayMs,"opusEnabled" to opusEnabled,
            "clockSynced" to (host || hostClockOffsetNs != null),
            "clockRttMs" to syncRttMs, "clockOffsetMs" to ((hostClockOffsetNs ?: 0L) / 1_000_000.0),
            "unsyncedAudioFrames" to waitingForSync.get(), "lateAudioFrames" to audio.latePlayback.get(),
            "audioQueued" to audio.pendingFrames, "primeFrames" to audio.primeFrames,
            "sent" to sent.get(), "received" to received.get(),
            "forwarded" to forwarded.get(), "duplicates" to duplicates.get(),
            "linkDrops" to linkDrops.get(), "lastDisconnectReason" to lastDisconnectReason,
            "relayJoinGraceActive" to (SystemClock.elapsedRealtime() < joinGraceUntilMs),
            "wifiRadioOn" to wifiRadioOn(),
            "audioDrops" to audio.droppedPlayback.get(),
            "underruns" to audio.underruns.get(),
            "playbackEnabled" to audio.playbackEnabled,
            "hostPlaybackEnabled" to audio.hostPlaybackEnabled,
            "hostStreamPaused" to globalPlaybackPaused,
            "hostVolume" to audio.hostVolume.toDouble(), "volume" to audio.volume.toDouble(),
            "speakerRole" to speakerRole,
            "translationRevision" to (lastCaption?.sequence ?: 0L),
            "translationText" to (lastCaption?.text ?: ""),
            "translationLanguage" to (lastCaption?.language ?: ""),
            "logs" to synchronized(eventLock) { events.toList() }
        )
    }

    fun push() {
        val snapshot = state()
        main.post { callback(snapshot) }
    }

    private fun log(s: String) {
        synchronized(eventLock) {
            if (events.size >= 18) events.removeFirst()
            events.addLast("${SystemClock.elapsedRealtime() / 1000}s  $s")
        }
        push()
    }
}
