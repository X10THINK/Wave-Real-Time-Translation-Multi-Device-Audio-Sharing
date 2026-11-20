package com.x10think.wave

import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** All timestamps in audio and sync messages use SystemClock.elapsedRealtimeNanos() on their originating devices. */
internal object MeshProtocol {
    private const val MAGIC = 0x57415634 // WAV4; deliberate breaking change for secure wire-format
    const val HELLO = 1
    const val AUDIO = 2
    const val PING = 3
    const val PONG = 4
    const val SYNC_REQ = 5
    const val SYNC_REPLY = 6
    const val REMOTE_CONTROL = 7
    const val ADMITTED = 8
    const val TRANSLATION_CAPTION = 9
    const val FRAME_BYTES = 640 // 20 ms, 16 kHz mono 16-bit PCM
    private const val MAX_PAYLOAD = 2048

    data class Packet(val kind: Int, val data: ByteArray)
    data class Audio(val origin: Long, val sequence: Int, val hops: Int, val capturedAtNs: Long,
                     val playoutDelayMs: Int, val pcm: ByteArray, val codec: Int = 0)
    data class ReceiverControl(val origin: Long, val target: Long, val seq: Int,
                               val action: Int, val gainPercent: Int)
    fun control(origin:Long,target:Long,seq:Int,action:Int,gain:Int):Packet {
        require(action in 1..6 && gain in 0..100)
        return Packet(REMOTE_CONTROL,ByteBuffer.allocate(26).order(ByteOrder.BIG_ENDIAN)
            .putLong(origin).putLong(target).putInt(seq).put(action.toByte())
            .put(gain.toByte()).putInt(0).array())
    }
    fun parseControl(data:ByteArray):ReceiverControl {
        if(data.size!=26) throw IOException("Malformed receiver control")
        val b=ByteBuffer.wrap(data).order(ByteOrder.BIG_ENDIAN)
        val out=ReceiverControl(b.long,b.long,b.int,b.get().toInt() and 255,b.get().toInt() and 255)
        if(out.action !in 1..6 || out.gainPercent !in 0..100 ||
           (out.action==4 && out.gainPercent !in 0..8) || b.int!=0)
            throw IOException("Invalid receiver control")
        return out
    }
    data class Greeting(val room: String, val nodeId: Long, val host: Boolean,val name:String="Listener")
    data class SyncRequest(val requester: Long, val requestSeq: Int, val t1: Long, val hops: Int)
    data class SyncReply(val requester: Long, val requestSeq: Int, val t1: Long, val t2: Long,
                         val t3: Long, val hops: Int)

    fun write(out: DataOutputStream, packet: Packet) {
        require(packet.data.size <= MAX_PAYLOAD)
        out.writeInt(MAGIC)
        out.writeByte(packet.kind)
        out.writeShort(packet.data.size)
        out.write(packet.data)
        out.flush()
    }

    @Throws(IOException::class)
    fun read(input: DataInputStream): Packet {
        if (input.readInt() != MAGIC) throw IOException("WAVE protocol version mismatch (install V2 on all phones)")
        val kind = input.readUnsignedByte()
        val length = input.readUnsignedShort()
        if (length > MAX_PAYLOAD) throw IOException("Oversized frame $length")
        val data = ByteArray(length)
        input.readFully(data)
        return Packet(kind, data)
    }

    fun greeting(room: String, nodeId: Long, host: Boolean,name:String="Listener"): Packet {
        val bytes = ByteArrayOutputStream()
        val out = DataOutputStream(bytes)
        out.writeUTF(room); out.writeLong(nodeId); out.writeBoolean(host);out.writeUTF(name.take(40))
        return Packet(HELLO, bytes.toByteArray())
    }

    fun parseGreeting(bytes: ByteArray): Greeting {
        val input = DataInputStream(bytes.inputStream())
        val room=input.readUTF();val node=input.readLong();val host=input.readBoolean()
        val greeting = Greeting(room,node,host,if(input.available()>0)input.readUTF() else "Listener")
        if (input.available() != 0) throw IOException("Trailing HELLO data")
        return greeting
    }

    fun audio(origin: Long, seq: Int, hops: Int, capturedAtNs: Long, playoutDelayMs: Int,
              pcm: ByteArray, codec: Int = 0): Packet {
        require(hops in 0..255 && playoutDelayMs in 80..2000)
        require(codec in 0..1 && if(codec==0) pcm.size==FRAME_BYTES else pcm.size in 1..512)
        val b = ByteBuffer.allocate(8 + 4 + 1 + 8 + 2 + 1 + pcm.size).order(ByteOrder.BIG_ENDIAN)
        b.putLong(origin); b.putInt(seq); b.put(hops.toByte()); b.putLong(capturedAtNs)
        b.putShort(playoutDelayMs.toShort()); b.put(codec.toByte());b.put(pcm)
        return Packet(AUDIO, b.array())
    }

    fun parseAudio(bytes: ByteArray): Audio {
        if (bytes.size !in 25..(24+FRAME_BYTES)) throw IOException("Bad WAVE4 audio frame")
        val b = ByteBuffer.wrap(bytes).order(ByteOrder.BIG_ENDIAN)
        val origin = b.long; val sequence = b.int; val hops = b.get().toInt() and 255
        val captured = b.long; val delay = b.short.toInt() and 65535
        if (delay !in 80..2000) throw IOException("Bad scheduled delay")
        val codec=b.get().toInt() and 255
        val pcm = ByteArray(b.remaining()); b.get(pcm)
        if(codec !in 0..1 || (codec==0 && pcm.size!=FRAME_BYTES) || (codec==1 && pcm.size !in 1..512))
            throw IOException("Unsupported or malformed audio codec")
        return Audio(origin, sequence, hops, captured, delay, pcm, codec)
    }

    fun syncRequest(requester: Long, seq: Int, t1: Long, hops: Int): Packet {
        require(hops in 0..255)
        val b = ByteBuffer.allocate(21)
        b.putLong(requester); b.putInt(seq); b.putLong(t1); b.put(hops.toByte())
        return Packet(SYNC_REQ, b.array())
    }

    fun parseSyncRequest(bytes: ByteArray): SyncRequest {
        if (bytes.size != 21) throw IOException("Bad SYNC_REQ")
        val b = ByteBuffer.wrap(bytes)
        return SyncRequest(b.long, b.int, b.long, b.get().toInt() and 255)
    }

    fun syncReply(requester: Long, seq: Int, t1: Long, t2: Long, t3: Long, hops: Int): Packet {
        require(hops in 0..255)
        val b = ByteBuffer.allocate(37)
        b.putLong(requester); b.putInt(seq); b.putLong(t1); b.putLong(t2); b.putLong(t3)
        b.put(hops.toByte())
        return Packet(SYNC_REPLY, b.array())
    }

    fun parseSyncReply(bytes: ByteArray): SyncReply {
        if (bytes.size != 37) throw IOException("Bad SYNC_REPLY")
        val b = ByteBuffer.wrap(bytes)
        return SyncReply(b.long, b.int, b.long, b.long, b.long, b.get().toInt() and 255)
    }

    fun millisToken(t: Long): ByteArray = ByteBuffer.allocate(8).putLong(t).array()
    fun parseToken(b: ByteArray): Long {
        if (b.size != 8) throw IOException("Bad RTT token")
        return ByteBuffer.wrap(b).long
    }
}

/** Per-origin sequence dedup for diamond-route packets. */
internal class FrameHistory(private val capacity: Int = 2048) {
    private val recent = LinkedHashSet<Pair<Long, Int>>()
    @Synchronized fun firstTime(origin: Long, sequence: Int): Boolean {
        val key = origin to sequence
        if (!recent.add(key)) return false
        if (recent.size > capacity) recent.remove(recent.first())
        return true
    }
    @Synchronized fun clear() = recent.clear()
}

/** Host clock minus receiver clock, estimated from 4 timestamps (NTP-like). */
internal object ClockMath {
    data class Estimate(val offsetNanos: Long, val rttNanos: Long)
    fun estimate(t1: Long, t2: Long, t3: Long, t4: Long): Estimate? {
        if (t4 <= t1 || t3 < t2) return null
        val rtt = (t4 - t1) - (t3 - t2)
        if (rtt < 0 || rtt > 5_000_000_000L) return null
        val offset = ((t2 - t1) + (t3 - t4)) / 2L
        return Estimate(offset, rtt)
    }
    fun receiverDeadline(hostCapturedNs: Long, delayMs: Int, hostMinusReceiverNs: Long): Long =
        hostCapturedNs + delayMs * 1_000_000L - hostMinusReceiverNs
}
