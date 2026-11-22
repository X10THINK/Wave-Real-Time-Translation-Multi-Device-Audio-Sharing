package com.x10think.wave

import android.content.Context
import android.media.projection.MediaProjection
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.net.wifi.WifiManager
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.SocketException
import java.util.UUID
import java.util.concurrent.LinkedBlockingDeque
import java.util.concurrent.TimeUnit
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/** Local LAN audio transport. Audio uses time-stamped UDP datagrams, not a server or the Internet.
 * WAVE4 encrypted invitation authenticates packets using a group secret (AES-GCM).
 * Group participants still share one secret and can impersonate each other.
 * Not production-safe for confidential audio without per-device identity and rekeying.
 */
internal class LanEngine(private val context: Context, private val callback: (Map<String, Any?>) -> Unit) {
    private companion object { const val PORT = 42561; const val MAX_HOPS = 5; const val PREFIX = "WAVE3" }
    private data class Peer(val address: InetAddress, val id: String, var lastHeard: Long, val hops: Int = 1)
    private data class Request(val id: String, val address: InetAddress, val relay: InetAddress?,
                               val createdAt: Long = SystemClock.elapsedRealtime())
    private val main = Handler(Looper.getMainLooper())
    private val running = AtomicBoolean(false)
    @Volatile private var crypto: SecureEnvelope? = null
    @Volatile private var inviteSecret: String = ""
    fun inviteSecretForHost(): String = if (host && running.get()) inviteSecret else ""
    private val joined = AtomicBoolean(false)
    @Volatile private var sourceId = UUID.randomUUID().toString().substring(0, 12)
    private val epoch = SystemClock.elapsedRealtimeNanos()
    private val currentSeq = AtomicInteger(0)
    private val sent = AtomicLong(0)
    private val received = AtomicLong(0)
    private val forwarded = AtomicLong(0)
    private val duplicates = AtomicLong(0)
    private val history = FrameHistory()
    @Volatile private var lastAudioOrigin: Long? = null
    private val clients = ConcurrentHashMap<String, Peer>()
    private val nearby = ConcurrentHashMap<String, Map<String, String>>()
    private data class Candidate(val address:InetAddress,val hops:Int,var lastSeen:Long)
    private val candidates = ConcurrentHashMap<String,Candidate>()
    private val pending = ConcurrentHashMap<String, Request>()
    private val names=ConcurrentHashMap<String,String>()
    private data class ReturnRoute(val child: InetAddress, val listener: InetAddress, val created: Long)
    private val admissionRoutes = ConcurrentHashMap<String, ReturnRoute>()
    private val relayedLastSeen=ConcurrentHashMap<String,Long>()
    private val desired=ConcurrentHashMap<String,MutableMap<String,Int>>()
    private var displayName="Listener"
    private var parentAttemptAt=0L
    private val approved = ConcurrentHashMap.newKeySet<String>()
    private val memberAddresses = ConcurrentHashMap<String, InetAddress>()
    private val approvedRoster = ConcurrentHashMap.newKeySet<String>()
    @Volatile private var election: LeaderElection? = null
    @Volatile private var votersRevision = ""
    // Immutable voting roster for this session; later joiners can listen/relay,
    // but voting membership cannot change without a separate safe reconfiguration.
    @Volatile private var frozenVoters: Set<String>? = null
    @Volatile private var lastHostView = 0L
    @Volatile private var lastElectionAttempt = 0L
    @Volatile private var electionInProgress = false
    @Volatile private var takeoverTerm = 0L
    @Volatile private var lastViewSent = 0L
    private val logs = ArrayDeque<String>()
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
                if(running.get() && host) emitAudio(pcm.pcm,pcm.capturedNs)
            }
        }, "WAVELanEngineAudioSender").apply {isDaemon=true;start()}
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
    @Volatile private var socket: DatagramSocket? = null
    @Volatile private var groupLock: WifiManager.MulticastLock? = null
    @Volatile private var worker: Thread? = null
    @Volatile private var heartbeat: Thread? = null
    @Volatile private var room = ""
    @Volatile private var title = "WAVE Room"
    @Volatile private var host = false
    @Volatile private var requireApproval = false
    @Volatile private var capacity = 10
    @Volatile private var parent: InetAddress? = null
    @Volatile private var parentId = ""
    @Volatile private var hostAddress: InetAddress? = null
    @Volatile private var hostId: String = sourceId
    @Volatile private var hopCount = 0
    @Volatile private var lastUpstream = 0L
    @Volatile private var joinDenied = false
    private var lastAnnouncementAt = 0L
    @Volatile private var offsetNs: Long? = null
    @Volatile private var syncRttMs: Double = -1.0
    private var lastSyncAt = 0L
    private var lastJoinAt = 0L
    private var lastBeatAt = 0L
    private var targetDelayMs = 280
    @Volatile private var lastLocalIp: String = ""
    @Volatile private var networkMigrating = false
    @Volatile private var lastAddressCheckAt = 0L
    private data class QualitySample(val atMs: Long, val totalGlitches: Int,
                                     val newGlitches: Int, val rttMs: Double)
    private val lastRemoteCommand = java.util.concurrent.atomic.AtomicLong(-1L)
    private val remoteSeq = AtomicLong(0L)
    @Volatile private var speakerRole = 0
    /** Only authorized local Host can command group listeners. Transmits over
     * authenticated session transport. A group secret is not individual identity. */
    fun controlReceiver(id: String, action: String, value: Int) {
        check(host && running.get()) { "Only current Host can control receivers" }
        require(id.matches(Regex("[A-Za-z0-9-]{8,40}"))) { "Invalid receiver ID" }
        require(action in setOf("PLAY","PAUSE","GAIN","ROLE")) { "Invalid receiver command" }
        require(value in 0..100) { "Volume outside range" }
        desired.getOrPut(id){ConcurrentHashMap()}[action]=value
        val seq=remoteSeq.incrementAndGet()
        // Every permitted first-hop relay forwards to admitted children. Direct
        // clients act as targets; unconnected devices cannot be commanded.
        clients.values.forEach { peer ->
            sendCtrl(peer.address,"RCMD",sourceId,id,action,value.toString(),seq.toString())
        }
        log("Receiver command submitted for $id; delivery not acknowledged")
    }
    private val captionCounter = AtomicLong(0L)
    private val captionInbox = TranslationCaptionWire.Inbox()
    @Volatile private var lastCaption: TranslationCaptionWire.Caption? = null

    fun broadcastTranslationCaption(language:String, text:String) {
        check(host && running.get()) { "Only Host can broadcast translated captions" }
        require(language in setOf("ta","en"))
        val pieces=TranslationCaptionWire.split(text)
        val seq=captionCounter.incrementAndGet()
        clients.values.forEach { child ->
            pieces.forEach { part ->
                sendCtrl(child.address,"TCAP",sourceId,seq.toString(),language,
                    part.total.toString(),part.index.toString(),part.value)
            }
        }
    }

    @Volatile private var globalPlaybackPaused=false
    private var lastPlaybackAnnounced=0L
    fun setGlobalPlaybackState(playing:Boolean) {
        check(host && running.get()) { "Only Host may change shared playback" }
        globalPlaybackPaused=!playing
        broadcastGlobalPlayback()
        push()
    }
    private fun broadcastGlobalPlayback() {
        if(!host || !running.get())return
        val sequence=remoteSeq.incrementAndGet()
        val op=if(globalPlaybackPaused) "SPAUSE" else "SPLAY"
        clients.values.forEach { peer->
            sendCtrl(peer.address,"RCMD",sourceId,"ALL",op,"100",sequence.toString())
        }
        lastPlaybackAnnounced=SystemClock.elapsedRealtime()
    }
    private val receiverQuality = ConcurrentHashMap<String, QualitySample>()
    @Volatile private var lastQualitySent=0L
    @Volatile private var lastQualityAdjust=0L

    @Synchronized fun start(roomCode: String, sessionName: String, isHost: Boolean, approval: Boolean, maxUsers: Int, invite: String, userName:String="Listener") {
        check(!running.get()) { "Another LAN session is already active" }
        val normalized = roomCode.trim().uppercase()
        require(normalized.matches(Regex("[A-Z0-9-]{4,12}"))) { "Room code must be 4-12 letters, numbers or hyphens" }
        val s = DatagramSocket(null)
        s.reuseAddress = true
        s.broadcast = true
        s.soTimeout = 500
        s.bind(InetSocketAddress(PORT))
        socket = s
        sourceId = UUID.randomUUID().toString().substring(0, 12) // New source identity each session.
        room = normalized
        val secure = SecureEnvelope(invite, normalized)
        crypto = secure
        inviteSecret = invite
        displayName=userName.take(40)
        admissionRoutes.clear();names.clear();desired.clear();relayedLastSeen.clear();parentAttemptAt=0L
        title = sessionName.take(70).ifBlank { "WAVE Room" }
        host = isHost
        requireApproval = approval
        capacity = maxUsers.coerceIn(1,100)
        hostId = if (host) sourceId else ""
        hopCount = if (host) 0 else 99
        parent = null
        parentId = ""
        hostAddress = if (host) findLanIp()?.let { InetAddress.getByName(it) } else null
        lastUpstream = 0
        lastLocalIp = findLanIp().orEmpty();networkMigrating=false
        receiverQuality.clear();lastQualitySent=0;lastQualityAdjust=0
        lastAnnouncementAt = 0
        lastJoinAt = 0
        lastBeatAt = 0
        lastSyncAt = 0
        joinDenied = false
        lastRemoteCommand.set(-1L); remoteSeq.set(0L);speakerRole=0
        captionCounter.set(0L); captionInbox.clear(); lastCaption=null
        globalPlaybackPaused=false;lastPlaybackAnnounced=0L
        audio.playbackEnabled=true;audio.volume=.8f
        audio.sessionPlaybackEnabled=true
        audio.hostPlaybackEnabled=true;audio.hostVolume=1.0f
        offsetNs = if (host) 0L else null
        syncRttMs = -1.0
        approved.clear();pending.clear();clients.clear();history.clear();nearby.clear();candidates.clear()
        memberAddresses.clear(); approvedRoster.clear(); frozenVoters=null
        lastHostView = SystemClock.elapsedRealtime()
        lastElectionAttempt=0; lastViewSent=0; electionInProgress=false
        takeoverTerm=context.getSharedPreferences("wave_elections",Context.MODE_PRIVATE).getLong(normalized,0)
        election=LeaderElection(sourceId,takeoverTerm)
        currentSeq.set(0);sent.set(0);received.set(0);forwarded.set(0);duplicates.set(0)
        lastAudioOrigin=null
        audio.droppedPlayback.set(0);audio.latePlayback.set(0);audio.underruns.set(0)
        joined.set(host)
        try { if (!host) audio.startPlayback() }
        catch (t: Throwable) {
            try { s.close() } catch (_: Exception) {}
            socket = null
            joined.set(false)
            throw t
        }
        running.set(true)
        startUplinkWorker()
        try {
            val wifi = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            groupLock = wifi.createMulticastLock("wave-lan-discovery").apply { setReferenceCounted(false); acquire() }
        } catch (_: Exception) { }
        worker = Thread({ receiveLoop(s) }, "WAVELanRead").apply { isDaemon=true;start() }
        heartbeat = Thread({ maintenanceLoop() }, "WAVELanMaintenance").apply { isDaemon=true;start() }
        log("${if(host) "Host ready" else "Receiver waiting"} on $normalized")
    }

    @Synchronized fun stop() {
        if (!running.getAndSet(false)) return
        WaveInternalMediaTap.setSink(null)
        outgoingAudio.clear()
        droppedSenderFrames.set(0)
        uplinkThread?.interrupt();uplinkThread=null
        audio.stopAll()
        opus.close();opusEnabled=false
        crypto = null; inviteSecret = ""
        try { socket?.close() } catch (_: Exception) {}
        socket = null
        try { groupLock?.release() } catch (_: Exception) {}
        groupLock = null
        try { worker?.interrupt() } catch (_: Exception) {}
        try { heartbeat?.interrupt() } catch (_: Exception) {}
        worker=null; heartbeat=null
        parent=null; clients.clear(); pending.clear(); approved.clear()
        memberAddresses.clear();approvedRoster.clear();frozenVoters=null;election=null
        joinDenied = false
        joined.set(false)
        push()
    }

    /** Receiver joins an IP endpoint (host or a relay). Automatic subnet discovery also works when broadcast is allowed. */
    fun join(target: String?) {
        check(running.get() && !host) { "Start receiver network session first" }
        val requested = target?.trim()?.takeIf { it.isNotEmpty() }
        val ip = if (requested != null) InetAddress.getByName(requested)
            else nearby[room]?.get("ip")?.let { InetAddress.getByName(it) }
        if (ip == null) { log("Waiting for nearby room $room (or enter IP with room code)"); return }
        parent = ip
        parentAttemptAt=SystemClock.elapsedRealtime()
        joinDenied = false
        history.clear() // Fresh stream after a denial or a new parent.
        offsetNs = null // Re-sync to Host before using its timestamps.
        lastJoinAt = 0
        joined.set(false)
        sendCtrl(ip,"JOIN",displayName)
        log("Join request sent to ${ip.hostAddress}")
        push()
    }

    /** Approved on the original Host only; relay requests are forwarded upstream. */
    @Synchronized fun approve(id: String, accept: Boolean) {
        check(host) { "Only Host can approve listeners" }
        val req = pending.remove(id) ?: return
        if (accept && (id in approved || approved.size < capacity)) {
            approved.add(id)
            approvedRoster.add(id); memberAddresses[id] = req.address
            val endpoint = req.relay ?: req.address
            if (req.relay == null) {
                clients[id] = Peer(req.address,id,SystemClock.elapsedRealtime())
                sendCtrl(req.address,"OK",sourceId,"0",hostAddress?.hostAddress.orEmpty(),title)
            } else {
                relayedLastSeen[id]=SystemClock.elapsedRealtime()
                sendCtrl(endpoint,"ALLOW",id,req.address.hostAddress)
            }
            log("Approved listener $id")
        } else {
            val reason = if(accept) "Room is full" else "Host rejected request"
            if(req.relay == null) sendCtrl(req.address,"DENY",reason) else sendCtrl(req.relay,"RELAY_DENY",id,reason)
            log("Rejected listener $id")
        }
        push()
    }

    fun disconnect(id: String) {
        val peer = clients[id]
        // Removing a voter requires group-key rotation and joint membership consensus.
        check(id !in (frozenVoters ?: emptySet())) {
            "This device is an election voter. End and recreate the secure session to revoke it safely."
        }
        clients.remove(id)
        approved.remove(id)
        approvedRoster.remove(id);memberAddresses.remove(id)
        if (peer != null) sendCtrl(peer.address,"DENY","Removed by Host")
        push()
    }

    private fun maintenanceLoop() {
        while (running.get()) {
            val now = SystemClock.elapsedRealtime()
            if(now-lastAddressCheckAt>1800L) {
                val newIp=findLanIp().orEmpty()
                if(newIp!=lastLocalIp) {
                    val previous=lastLocalIp;lastLocalIp=newIp
                    networkMigrating=true
                    if(host) {
                        hostAddress=newIp.takeIf {it.isNotBlank()}?.let {InetAddress.getByName(it)}
                        lastViewSent=0L;lastAnnouncementAt=0L
                    } else {
                        parent=null;parentId="";joined.set(false);offsetNs=null
                        lastJoinAt=0;nearby.clear();history.clear()
                    }
                    log("LAN address moved $previous -> $newIp. Re-discovering peers")
                }
                if(networkMigrating && (host || joined.get())) networkMigrating=false
                lastAddressCheckAt=now
            }
            if(!host && joined.get() && now-lastQualitySent>2000L) {
                hostAddress?.let{sendCtrl(it,"QUALITY",audio.latePlayback.get().toString(),
                    audio.underruns.get().toString(),syncRttMs.toString())}
                lastQualitySent=now
            }
            if(host && now-lastQualityAdjust>3000L) {
                val reports=receiverQuality.values.filter{now-it.atMs<7000L}
                // V4 stored the delta as if it were the total, so the delay could
                // rise monotonically even after loss stopped. Use actual cumulative
                // counters and permit slow recovery toward an initial target.
                if(reports.isNotEmpty()) {
                    val unstable=reports.any { it.newGlitches>2 || it.rttMs>350.0 }
                    targetDelayMs=if(unstable)(targetDelayMs+20).coerceAtMost(480)
                                  else (targetDelayMs-10).coerceAtLeast(180)
                }
                lastQualityAdjust=now
            }
            if (host || joined.get()) {
                if (now - lastAnnouncementAt > 1600L) {
                    sendAnnouncement()
                    lastAnnouncementAt = now
                }
                if (now-lastBeatAt > 900) {
                    if (!host) parent?.let { sendCtrl(it,"BEAT",sourceId) }
                    clients.values.forEach { sendCtrl(it.address,"BEAT",sourceId) }
                    lastBeatAt = now
                }
            }
            // Receiver that joins while Host is paused learns the paused state.
            if(host && now-lastPlaybackAnnounced>1600L) {
                broadcastGlobalPlayback()
                desired.forEach {(id,values)->values.forEach {(op,value)->controlReceiver(id,op,value)}}
            }
            if (host && now-lastViewSent > 1300L) {
                publishHostView()
                lastViewSent = now
            }
            if (!host && now-lastHostView > 5500L && now-lastElectionAttempt > 4500L) {
                initiateFailover()
                lastElectionAttempt = now
            }
            if (!host) {
                if(!joined.get() && !joinDenied && now-parentAttemptAt>6000L) {
                    val alternative=candidates.values.filter{now-it.lastSeen<6000L && it.address!=parent}.minByOrNull{it.hops}
                    parent=alternative?.address;parentAttemptAt=now
                    if(parent==null)nearby.clear()
                }
                if (!joined.get() && !joinDenied && now-lastJoinAt > 1500L) {
                    parent?.let { sendCtrl(it,"JOIN",displayName) }
                    if (parent==null) nearby[room]?.get("ip")?.let {
                        try { parent=InetAddress.getByName(it);sendCtrl(parent!!,"JOIN",displayName) } catch (_: Exception) {}
                    }
                    lastJoinAt=now
                }
                if (joined.get() && now-lastUpstream>4000L) {
                    joined.set(false)
                    log("Upstream link lost; attempting recovery")
                    val alternative = candidates.values
                        .filter { now - it.lastSeen < 6500L && it.address != parent }
                        .minWithOrNull(compareBy<Candidate>{it.hops}.thenBy{it.address.hostAddress})
                    if (alternative != null) parent=alternative.address
                    history.clear()
                    offsetNs=null
                    lastJoinAt=0L
                }
                if (joined.get() && hostAddress != null && now-lastSyncAt>1800L) {
                    val t1=SystemClock.elapsedRealtimeNanos()
                    hostAddress?.let { sendCtrl(it,"SYNC",sourceId,t1.toString()) }
                    lastSyncAt=now
                }
            }
            if(!host && joined.get()) clients.values.filter{now-it.lastHeard<8000L}.forEach {child->parent?.let{sendCtrl(it,"CHILD_ALIVE",child.id)}}
            relayedLastSeen.entries.removeIf {entry->
                if(now-entry.value>12000L){approved.remove(entry.key);true}else false
            }
            // Capacity counts CURRENTly connected listeners, not all historical approvals.
            val expired = clients.values.filter { now - it.lastHeard > 8000L }.map { it.id }
            expired.forEach { clients.remove(it); if(host) approved.remove(it) }
            pending.entries.removeIf { now - it.value.createdAt > 30_000L }
            candidates.entries.removeIf {now-it.value.lastSeen>10_000L}
            if (running.get()) push()
            try { Thread.sleep(450L) } catch (_: InterruptedException) { break }
        }
    }

    private fun receiveLoop(s: DatagramSocket) {
        val buffer=ByteArray(1600)
        while (running.get()) {
            try {
                val dp=DatagramPacket(buffer,buffer.size)
                s.receive(dp)
                if (!running.get()) break
                val incoming=dp.data.copyOf(dp.length)
                // ANN is public discovery ONLY; it never authorizes a peer.
                if(incoming.size >= 9 && incoming.toString(Charsets.UTF_8).startsWith("WAVECTL3|") &&
                    incoming.toString(Charsets.UTF_8).split('|').getOrNull(2) == "ANN") {
                    parseControl(incoming.toString(Charsets.UTF_8), dp.address)
                } else {
                    val unsealed = crypto?.open(incoming) ?: continue
                    if (unsealed.size>=9 && unsealed.toString(Charsets.UTF_8).startsWith("WAVECTL3|")) {
                        parseControl(unsealed.toString(Charsets.UTF_8), dp.address)
                    } else {
                        val packet=MeshProtocol.read(DataInputStream(ByteArrayInputStream(unsealed)))
                        if(packet.kind == MeshProtocol.AUDIO) onAudio(packet,dp.address)
                    }
                }
            } catch (_: java.net.SocketTimeoutException) {
            } catch (_: SocketException) {
                if(!running.get()) break
            } catch (_: Exception) { /* Ignore hostile or malformed LAN datagrams. */ }
        }
    }

    private fun parseControl(message: String, sender: InetAddress) {
        val p=message.split('|',limit=10)
        if (p.size<4 || p[0]!="WAVECTL3") return
        val packetRoom=p[1]
        val type=p[2]
        val senderId=p[3]
        val now=SystemClock.elapsedRealtime()
        if (senderId.length !in 8..40 || !senderId.all { it.isLetterOrDigit() || it == '-' }) return
        if (type=="ANN") {
            if(packetRoom==room && !host) {
                val addr=p.getOrNull(4)?.takeIf { it.isNotBlank() } ?: sender.hostAddress
                val hops=p.getOrNull(5)?.toIntOrNull() ?: 99
                candidates[sender.hostAddress]=Candidate(sender,hops,now)
                val existing=nearby[packetRoom]
                if(existing==null || now-(existing["seen"]?.toLongOrNull()?:0L)>5000L || (existing["hops"]?.toIntOrNull()?:99)>=hops) {
                    nearby[packetRoom]=mapOf("seen" to now.toString(),"ip" to sender.hostAddress,"hops" to hops.toString(),"hostId" to (p.getOrNull(6)?:senderId),"title" to (p.getOrNull(7)?:"WAVE Room"))
                }
            }
            return
        }
        if(packetRoom!=room || !running.get())return
        if (senderId==sourceId) return
        when(type) {
            "TCAP" -> {
                // Authenticated by SecureEnvelope, then bound to the verified
                // upstream peer and current host's identity before display.
                if(host || !joined.get() || sender!=parent || senderId!=parentId)return
                val origin=p.getOrNull(4)?:return
                val sequence=p.getOrNull(5)?.toLongOrNull()?:return
                val language=p.getOrNull(6)?:return
                val total=p.getOrNull(7)?.toIntOrNull()?:return
                val index=p.getOrNull(8)?.toIntOrNull()?:return
                val data=p.getOrNull(9)?:return
                if(origin!=hostId)return
                val result=captionInbox.accept(sequence,language,total,index,data)
                if(result!=null){lastCaption=result;push()}
                // Forward only authenticated Host-origin caption fragments;
                // local mute/pause must not interrupt downstream delivery.
                clients.values.forEach {child->if(child.address!=sender)
                    sendCtrl(child.address,"TCAP",origin,sequence.toString(),language,
                        total.toString(),index.toString(),data)
                }
            }
            "RCMD" -> {
                if (host || !joined.get() || sender!=parent || senderId!=parentId) return
                val origin=p.getOrNull(4)?:return
                val target=p.getOrNull(5)?:return
                val op=p.getOrNull(6)?:return
                val gain=p.getOrNull(7)?.toIntOrNull()?:return
                val sequence=p.getOrNull(8)?.toLongOrNull()?:return
                if(origin!=hostId || gain !in 0..100 || sequence<=lastRemoteCommand.get())return
                if(op !in setOf("PLAY","PAUSE","GAIN","ROLE","SPLAY","SPAUSE"))return
                if(op=="ROLE" && gain !in 0..8)return
                if((op=="SPLAY" || op=="SPAUSE") && target!="ALL")return
                lastRemoteCommand.set(sequence)
                if(target==sourceId || target=="ALL") {
                    when(op) {
                        "PLAY" -> audio.hostPlaybackEnabled=true
                        "PAUSE" -> audio.hostPlaybackEnabled=false
                        "GAIN" -> audio.hostVolume=gain/100f
                        "ROLE" -> speakerRole=gain
                        "SPLAY" -> {globalPlaybackPaused=false;audio.sessionPlaybackEnabled=true}
                        "SPAUSE" -> {globalPlaybackPaused=true;audio.sessionPlaybackEnabled=false}
                    }
                    push()
                }
                // Do not let local pause/volume changes interrupt forwarding.
                clients.values.forEach {child->
                    if(child.address!=sender)
                        sendCtrl(child.address,"RCMD",origin,target,op,gain.toString(),sequence.toString())
                }
            }
            "VIEW" -> {
                if (host || (hostId.isNotBlank() && senderId != hostId)) return
                val view=p.getOrNull(4)?:return
                val remoteTerm=p.getOrNull(5)?.toLongOrNull()?:return
                val participants=p.getOrNull(6)?.split(',')?.mapNotNull { value ->
                    val pair=value.split('@');if(pair.size!=2) null else pair[0] to pair[1]
                }?:return
                val members=participants.associate { it.first to it.second }
                if (members.isEmpty()) return
                if (election?.installView(view,members.keys,senderId,remoteTerm) != true) return
                if(frozenVoters!=null && members.keys!=frozenVoters) return
                frozenVoters=members.keys.toSet()
                memberAddresses.clear()
                for ((id,ip) in members) try {memberAddresses[id]=InetAddress.getByName(ip)} catch (_:Exception) {}
                approvedRoster.clear(); approvedRoster.addAll(members.keys.filter { it!=senderId })
                capacity=p.getOrNull(7)?.toIntOrNull()?.coerceIn(1,100)?:capacity
                requireApproval=p.getOrNull(8)=="true"
                title=p.getOrNull(9)?.take(70)?:title
                votersRevision=view; takeoverTerm=remoteTerm;lastHostView=now
                persistTerm(remoteTerm)
            }
            "QUALITY" -> if(host && (senderId in approvedRoster)) {
                val late=p.getOrNull(4)?.toLongOrNull()?:return
                val underruns=p.getOrNull(5)?.toLongOrNull()?:return
                val count=((late+underruns).coerceAtMost(1_000_000L)).toInt()
                val previous=receiverQuality[senderId]?.totalGlitches ?: count
                val recentLoss=if(count>=previous) count-previous else 0
                val rtt=p.getOrNull(6)?.toDoubleOrNull() ?: -1.0
                receiverQuality[senderId]=QualitySample(now,count,recentLoss,rtt)
            }
            "VOTE_REQ" -> {
                val requestedTerm=p.getOrNull(4)?.toLongOrNull()?:return
                val revision=p.getOrNull(5)?:return
                if (memberAddresses[senderId]!=sender) return
                val ballot=election?.requestVote(senderId,requestedTerm,revision)?:return
                persistTerm(ballot.term)
                sendCtrl(sender,"VOTE",ballot.term.toString(),revision,ballot.granted.toString())
            }
            "VOTE" -> {
                if(memberAddresses[senderId]!=sender || !electionInProgress) return
                val voteTerm=p.getOrNull(4)?.toLongOrNull()?:return
                val revision=p.getOrNull(5)?:return
                val granted=p.getOrNull(6)=="true"
                if(election?.countVote(senderId,voteTerm,granted,revision)==true) {
                    electionInProgress=false
                    becomeHost(voteTerm)
                }
            }
            "LEADER" -> {
                val announcedTerm=p.getOrNull(4)?.toLongOrNull()?:return
                val revision=p.getOrNull(5)?:return
                if(memberAddresses[senderId]!=sender) return
                if(election?.acknowledgeLeader(senderId,announcedTerm,revision)!=true)return
                persistTerm(announcedTerm)
                if(senderId!=sourceId) {
                    // Demote stale host; old audio source must not keep broadcasting.
                    if(host){audio.stopAll();audio.startPlayback()}
                    host=false; joined.set(false);parent=sender;hostAddress=sender;hostId=senderId
                    hopCount=1;lastJoinAt=0;lastUpstream=now;lastHostView=now
                    history.clear();audio.resetPlaybackStream();opus.closeDecoder()
                    lastRemoteCommand.set(-1L);audio.hostPlaybackEnabled=true;audio.hostVolume=1f;globalPlaybackPaused=false;audio.sessionPlaybackEnabled=true
                    lastAudioOrigin=null;offsetNs=null;clients.clear()
                    log("Host changed to $senderId; rejoining same room")
                }
            }
            "JOIN" -> {
                names[senderId]=(p.getOrNull(4)?:"Listener").take(40)
                if (host) {
                    val existing=clients[senderId]
                    if(existing!=null){
                        // Do not let a different LAN address impersonate an admitted peer ID.
                        if (existing.address != sender) return
                        existing.lastHeard=now
                        sendCtrl(sender,"OK",sourceId,"0",hostAddress?.hostAddress.orEmpty(),title);return
                    }
                    if (!pending.containsKey(senderId) && pending.size >= capacity.coerceAtLeast(2)) {
                        sendCtrl(sender,"DENY","Too many pending requests"); return
                    }
                    val req=Request(senderId,sender,null)
                    pending[senderId]=req
                    if (senderId in approvedRoster || !requireApproval) approve(senderId,true)
                    else {sendCtrl(sender,"WAIT",sourceId);push()}
                } else if(joined.get() && !clients.containsKey(senderId) && parent!=sender) {
                    // Admission is decided at Host even for relay-connected devices.
                    admissionRoutes.entries.removeIf { now - it.value.created > 60_000 }
                    if (admissionRoutes.size >= capacity && senderId !in admissionRoutes.keys) return
                    admissionRoutes[senderId] = ReturnRoute(sender,sender,now)
                    parent?.let { sendCtrl(it,"RELAY_REQ",senderId,sender.hostAddress,findLanIp().orEmpty(),names[senderId] ?: "Listener") }
                    sendCtrl(sender,"WAIT",sourceId)
                } else if(clients[senderId]?.address == sender) {
                    clients[senderId]?.lastHeard=now
                    sendCtrl(sender,"OK",hostId,hopCount.toString(),hostAddress?.hostAddress.orEmpty(),title)
                }
            }
            "RELAY_REQ" -> {
                val id=p.getOrNull(4)?:return
                val ip=p.getOrNull(5)?:return
                if(clients[senderId]?.address != sender) return
                val listener = InetAddress.getByName(ip)
                if(listener.isMulticastAddress || listener.isAnyLocalAddress || listener.isLoopbackAddress) return
                val name = p.getOrNull(7)?.take(40) ?: "Listener"
                if (host) {
                    if (!pending.containsKey(id) && pending.size >= capacity.coerceAtLeast(2)) return
                    names[id] = name
                    val req=Request(id,listener,sender)
                    pending[id]=req
                    if (!requireApproval || (id in approved && memberAddresses[id] == listener)) approve(id,true) else push()
                } else if(joined.get() && clients.values.any{it.address==sender}) {
                    admissionRoutes.entries.removeIf { now - it.value.created > 60_000 }
                    if (admissionRoutes.size >= capacity && id !in admissionRoutes.keys) return
                    admissionRoutes[id] = ReturnRoute(sender,listener,now)
                    parent?.let { sendCtrl(it,"RELAY_REQ",id,ip,findLanIp().orEmpty(),name) }
                }
            }
            "ALLOW" -> {
                if (!host && joined.get() && sender==parent) {
                    val id=p.getOrNull(4)?:return
                    val ip=p.getOrNull(5)?:return
                    val route=admissionRoutes.remove(id) ?: return
                    val address=InetAddress.getByName(ip)
                    if (address != route.listener) return
                    if (route.child != address) {
                        sendCtrl(route.child,"ALLOW",id,ip)
                        return
                    }
                    clients[id]=Peer(address,id,now,hopCount+1)
                    sendCtrl(address,"OK",hostId,hopCount.toString(),hostAddress?.hostAddress.orEmpty(),title)
                    log("New relay listener $id")
                }
            }
            "OK" -> if(!host && sender==parent) {
                parentId=senderId
                hostId=p.getOrNull(4)?:senderId
                hopCount=(p.getOrNull(5)?.toIntOrNull()?:0)+1
                hostAddress=p.getOrNull(6)?.takeIf { it.isNotBlank() }?.let { InetAddress.getByName(it) }
                title=p.getOrNull(7)?.take(70)?.ifBlank{"WAVE Room"}?:title
                joined.set(true);lastUpstream=now
                log("Joined $room via ${sender.hostAddress}")
                push()
            }
            "RELAY_DENY" -> if(!host && sender==parent) {
                val id=p.getOrNull(4)?:return
                val route=admissionRoutes.remove(id)?:return
                val reason=p.getOrNull(5)?:"Access denied"
                if(route.child==route.listener) sendCtrl(route.child,"DENY",reason)
                else sendCtrl(route.child,"RELAY_DENY",id,reason)
            }
            "WAIT" -> if(!host) {log("Waiting for host approval")}
            "DENY" -> if(!host && sender == parent) {
                joined.set(false);parent=null;joinDenied=true
                log("Join denied: ${p.getOrNull(4)?:"Access denied"}. Re-open Join to retry.")
            }
            "CHILD_ALIVE" -> {
                if(clients[senderId]?.address!=sender)return
                val id=p.getOrNull(4)?:return
                if(host){if(id in approved)relayedLastSeen[id]=now}
                else parent?.let{sendCtrl(it,"CHILD_ALIVE",id)}
            }
            "BEAT" -> {
                if (sender==parent && !host) lastUpstream=now
                clients[senderId]?.let { peer -> if (peer.address == sender) peer.lastHeard=now }
            }
            "SYNC" -> if (host) {
                val reqId=p.getOrNull(4)?:return
                val t1=p.getOrNull(5)?:return
                val t2=SystemClock.elapsedRealtimeNanos()
                val t3=SystemClock.elapsedRealtimeNanos()
                sendCtrl(sender,"SYNC_ACK",reqId,t1,t2.toString(),t3.toString())
            }
            "SYNC_ACK" -> if(!host && sender==hostAddress) {
                val reqId=p.getOrNull(4)?:return
                if (reqId!=sourceId) return
                val t1=p.getOrNull(5)?.toLongOrNull()?:return
                val t2=p.getOrNull(6)?.toLongOrNull()?:return
                val t3=p.getOrNull(7)?.toLongOrNull()?:return
                val estimate=ClockMath.estimate(t1,t2,t3,SystemClock.elapsedRealtimeNanos())?:return
                if (offsetNs==null || estimate.rttNanos/1e6 < syncRttMs*1.5 || syncRttMs < 0) {
                    offsetNs= if(offsetNs==null) estimate.offsetNanos else (offsetNs!!*3 + estimate.offsetNanos)/4
                    syncRttMs=estimate.rttNanos/1e6
                }
            }
            "LEAVE" -> {
                if (clients[senderId]?.address == sender) {
                    clients.remove(senderId)
                    if (host) approved.remove(senderId)
                }
            }
        }
    }

    private fun onAudio(packet: MeshProtocol.Packet,sender: InetAddress) {
        if(!joined.get() || host || sender != parent) return
        val frame=MeshProtocol.parseAudio(packet.data)
        if(frame.hops>MAX_HOPS) return
        if(hostId.isNotBlank() && frame.origin != hostId.hashCode().toLong()) return
        if(lastAudioOrigin!=frame.origin) {
            lastAudioOrigin=frame.origin
            history.clear();audio.resetPlaybackStream();opus.closeDecoder()
        }
        if(!history.firstTime(frame.origin,frame.sequence)) { duplicates.incrementAndGet();return }
        lastUpstream=SystemClock.elapsedRealtime()
        received.incrementAndGet()
        val offset=offsetNs
        val deadline=if(offset!=null) ClockMath.receiverDeadline(frame.capturedAtNs,frame.playoutDelayMs,offset)
            else SystemClock.elapsedRealtimeNanos()+160_000_000L
        val pcm=if(frame.codec==1){if(opus.startDecoder()) opus.decode(frame.pcm) else null}else frame.pcm
        if(pcm!=null)audio.enqueue(frame.sequence,pcm,deadline)
        if(frame.hops<MAX_HOPS && clients.isNotEmpty()) {
            val onwards=MeshProtocol.audio(frame.origin,frame.sequence,frame.hops+1,
                frame.capturedAtNs,frame.playoutDelayMs,frame.pcm,frame.codec)
            sendAudio(onwards,exclude=sender)
        }
    }

    private fun emitAudio(pcm: ByteArray,capturedNs:Long) {
        if (!running.get() || !host) return
        val seq=currentSeq.getAndIncrement()
        val encoded=if(opusEnabled) opus.encode(pcm) else null
        val packet=MeshProtocol.audio(sourceId.hashCode().toLong(),seq,0,
            capturedNs,targetDelayMs,encoded ?: pcm,
            if(encoded==null) 0 else 1)
        sendAudio(packet)
    }

    private fun sendAudio(packet: MeshProtocol.Packet, exclude: InetAddress?=null) {
        // Encrypt ONCE per unique frame, not once per receiver. All members of
        // this room already share the same group key; this is the SAME signed
        // packet addressed to different clients (no new nonce reuse across
        // different plaintexts). Avoid frame-rate crypto/GC scaling with N.
        if (!running.get()) return
        val bytes=ByteArrayOutputStream().also { MeshProtocol.write(DataOutputStream(it),packet) }.toByteArray()
        val sealed=crypto?.seal(bytes) ?: return
        clients.values.forEach { client ->
            if(client.address!=exclude){
                sendEncrypted(sealed,client.address)
                if(host)sent.incrementAndGet() else forwarded.incrementAndGet()
            }
        }
    }

    private fun sendAnnouncement() {
        val ip=findLanIp() ?: return
        val body="WAVECTL3|$room|ANN|$sourceId|$ip|$hopCount|$hostId|${title.replace('|',' ').take(45)}"
        val bytes=body.toByteArray(Charsets.UTF_8)
        val addresses=mutableSetOf<InetAddress>()
        try { addresses.add(InetAddress.getByName("255.255.255.255")) } catch (_: Exception) {}
        try {
            val nics=NetworkInterface.getNetworkInterfaces()
            while(nics.hasMoreElements()) {
                val nic=nics.nextElement()
                if (!nic.isUp || nic.isLoopback) continue
                for (a in nic.interfaceAddresses) if(a.broadcast!=null) addresses.add(a.broadcast)
            }
        } catch (_: Exception) {}
        addresses.forEach { sendRaw(bytes,it) }
    }

    private fun sendCtrl(target:InetAddress,kind:String,vararg data:String) {
        val msg=(listOf("WAVECTL3",room,kind,sourceId)+data.map { it.replace('|',' ').take(150) }).joinToString("|")
        sendRaw(msg.toByteArray(Charsets.UTF_8),target)
    }
    private fun sendRaw(bytes:ByteArray,to:InetAddress) {
        if (!running.get()) return
        val publicAnn = bytes.toString(Charsets.UTF_8).startsWith("WAVECTL3|$room|ANN|")
        val message = if (publicAnn) bytes else (crypto?.seal(bytes) ?: return)
        sendEncrypted(message,to)
    }
    private fun sendEncrypted(message:ByteArray,to:InetAddress) {
        try {
            if(running.get()) socket?.send(DatagramPacket(message,message.size,to,PORT))
        } catch (_:Exception) {
            // UDP loss is expected on busy networks. The sender must keep
            // going for other receivers; diagnostics report receiver glitches.
        }
    }

    private fun findLanIp():String? {
        try {
            val all=NetworkInterface.getNetworkInterfaces()
            val addresses=mutableListOf<Pair<Int,String>>()
            while(all.hasMoreElements()){
                val network=all.nextElement()
                if(!network.isUp || network.isLoopback) continue
                val nic=network.name.lowercase()
                // Hotspot/Wi-Fi IP must not be replaced by mobile data or VPN IPs.
                if(nic.startsWith("tun") || nic.startsWith("rmnet") || nic.startsWith("ccmni") ||
                   nic.startsWith("pdp") || nic.startsWith("v4-") || nic.startsWith("clat")) continue
                val preference=when {
                    nic.startsWith("wlan") || nic.startsWith("swlan") || nic.startsWith("ap") -> 0
                    nic.contains("wifi") || nic.startsWith("p2p") -> 1
                    nic.startsWith("eth") -> 2
                    else -> 5
                }
                val iterator=network.inetAddresses
                while(iterator.hasMoreElements()) {
                    val addr=iterator.nextElement()
                    if(addr is Inet4Address && !addr.isLoopbackAddress && addr.isSiteLocalAddress)
                        addresses.add(preference to addr.hostAddress)
                }
            }
            return addresses.minWithOrNull(compareBy<Pair<Int,String>> { it.first }
                .thenBy { if(it.second.startsWith("192.168."))0 else 1 })?.second
        } catch (_:Exception) { return null }
    }

    fun setMic(enabled:Boolean){check(host && running.get());if(enabled){WaveInternalMediaTap.setSink(null);outgoingAudio.clear();audio.startCapture();setGlobalPlaybackState(true)}else audio.stopCapture();push()}
    fun setDeviceAudio(projection:MediaProjection){check(host && running.get());WaveInternalMediaTap.setSink(null);outgoingAudio.clear();audio.startDeviceAudio(projection);setGlobalPlaybackState(true);push()}
    fun setTargetDelay(ms:Int){require(ms in 160..600);targetDelayMs=ms;push()}
    fun setPlayback(enabled:Boolean,volume:Double){audio.playbackEnabled=enabled;audio.volume=volume.toFloat();push()}
    /** Publish fixed-size voter view: Host plus up to 4 admitted members. Dynamic
     * membership still needs a joint-consensus protocol for full split-brain safety.
     * This election is conservative and refuses promotion without majority.
     */
    private fun publishHostView() {
        if(!host)return
        val ip=hostAddress?.hostAddress ?: findLanIp() ?: return
        if(frozenVoters==null) {
            if(approvedRoster.size<2)return
            frozenVoters=(listOf(sourceId)+approvedRoster.sorted().take(2)).toSet()
        }
        val members=frozenVoters ?: return
        val entries=members.mapNotNull { id ->
            if(id==sourceId) id to ip else memberAddresses[id]?.let { id to it.hostAddress }
        }.sortedBy { it.first }
        if(entries.size != members.size || entries.size<3)return
        val revision=entries.joinToString(","){it.first+"@"+it.second}
        val viewId=revision.hashCode().toUInt().toString(16)
        election?.installView(viewId,entries.map{it.first}.toSet(),sourceId,takeoverTerm)
        votersRevision=viewId
        for((id,address) in memberAddresses) if(id in approvedRoster) {
            sendCtrl(address,"VIEW",viewId,takeoverTerm.toString(),revision,capacity.toString(),requireApproval.toString(),title)
        }
    }
    private fun initiateFailover() {
        val state=election?:return
        val next=state.initiate()?:return
        persistTerm(next)
        electionInProgress=true
        log("Original Host unreachable; requesting quorum (term $next)")
        for(id in state.voters) {
            if(id==sourceId)continue
            memberAddresses[id]?.let { sendCtrl(it,"VOTE_REQ",next.toString(),state.view) }
        }
    }
    @Synchronized private fun becomeHost(term: Long) {
        if(host || !running.get())return
        // The original mic/movie source is NOT recoverable after phone loss.
        audio.stopAll(); history.clear(); currentSeq.set(0)
        host=true; joined.set(true);hostId=sourceId;hopCount=0;parent=null;parentId=""
        hostAddress=findLanIp()?.let { InetAddress.getByName(it) }
        hostAddress?.let { memberAddresses[sourceId]=it }
        offsetNs=0L;takeoverTerm=term;lastHostView=SystemClock.elapsedRealtime()
        clients.clear();pending.clear();approved.clear()
        persistTerm(term)
        for((id,addr) in memberAddresses) if(id != sourceId) {
            sendCtrl(addr,"LEADER",term.toString(),votersRevision)
        }
        sendCtrl(InetAddress.getByName("255.255.255.255"),"LEADER",term.toString(),votersRevision)
        log("Elected new Session Host (term $term); select a new audio source")
        push()
    }
    private fun persistTerm(term:Long) {
        context.getSharedPreferences("wave_elections",Context.MODE_PRIVATE)
            .edit().putLong(room,term).apply()
    }
    fun isRunning()=running.get()
    fun state():Map<String,Any?> = mapOf(
        "running" to running.get(),"host" to host,"room" to room,"joined" to joined.get(),
        "sessionName" to title,"capacity" to capacity,"approval" to requireApproval,
        "connected" to clients.size,"peers" to clients.values.map { mapOf("id" to it.id,"ip" to it.address.hostAddress,"hops" to it.hops,"name" to (names[it.id]?:"Listener"),"gain" to (desired[it.id]?.get("GAIN")),"role" to (desired[it.id]?.get("ROLE"))) },
        "pending" to pending.values.map{mapOf("id" to it.id,"ip" to it.address.hostAddress,"name" to (names[it.id]?:"Listener"))},
        "localIp" to (findLanIp()?:""),"hostIp" to (hostAddress?.hostAddress?:""),
        "parentIp" to (parent?.hostAddress?:""),"joinDenied" to joinDenied,
        "hopCount" to hopCount,"networkMigrating" to networkMigrating,"relay" to (clients.isNotEmpty() && !host),
        "hostTerm" to (election?.term ?: takeoverTerm),
        "hostElectionStatus" to (if(electionInProgress) "seeking_quorum" else if(host) "host" else "follower"),
        "voterCount" to (election?.voters?.size ?: 0),
        "capturing" to audio.isCapturing,"captureSource" to audio.sourceKind,
            "senderQueue" to outgoingAudio.size,"senderDrops" to droppedSenderFrames.get(),
            "mediaPcmFrames" to WaveInternalMediaTap.frameCount(),
        "sent" to sent.get(),"received" to received.get(),"forwarded" to forwarded.get(),
        "duplicates" to duplicates.get(),"audioDrops" to audio.droppedPlayback.get(),
        "underruns" to audio.underruns.get(),"clockSynced" to (offsetNs!=null),"clockRttMs" to syncRttMs,
        "targetDelayMs" to targetDelayMs,"opusEnabled" to opusEnabled,"playbackEnabled" to audio.playbackEnabled,"hostPlaybackEnabled" to audio.hostPlaybackEnabled,
        "hostVolume" to audio.hostVolume.toDouble(),"volume" to audio.volume.toDouble(),
        "hostStreamPaused" to globalPlaybackPaused,
        "speakerRole" to speakerRole,
        "translationRevision" to (lastCaption?.sequence ?: 0L),
        "translationText" to (lastCaption?.text ?: ""),
        "translationLanguage" to (lastCaption?.language ?: ""),
        "backupRouteCount" to candidates.size,"nearby" to nearby.map { (key,value)-> mapOf("room" to key)+value },"logs" to synchronized(logs){logs.toList()}
    )
    fun push(){val snapshot=state();main.post{callback(snapshot)}}
    private fun log(m:String){synchronized(logs){if(logs.size>22)logs.removeFirst();logs.addLast(m)};push()}
}
