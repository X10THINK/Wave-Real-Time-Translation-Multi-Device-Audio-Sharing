package com.x10think.wave

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException

fun main() {
    val greeting = MeshProtocol.parseGreeting(MeshProtocol.greeting("123456", 423L, true).data)
    check(greeting.room == "123456" && greeting.nodeId == 423L && greeting.host)
    val pcm = ByteArray(MeshProtocol.FRAME_BYTES) { (it % 127).toByte() }
    val audio = MeshProtocol.audio(423L, 77, 2, 900_000_000_000L, 280, pcm)
    val wire = ByteArrayOutputStream()
    MeshProtocol.write(DataOutputStream(wire), audio)
    val p = MeshProtocol.read(DataInputStream(ByteArrayInputStream(wire.toByteArray())))
    val parsed = MeshProtocol.parseAudio(p.data)
    check(parsed.sequence == 77 && parsed.origin == 423L && parsed.hops == 2)
    check(parsed.capturedAtNs == 900_000_000_000L && parsed.playoutDelayMs == 280)
    check(parsed.pcm.contentEquals(pcm))
    val req = MeshProtocol.parseSyncRequest(MeshProtocol.syncRequest(99L, 3, 1_000_000_000L, 2).data)
    check(req.requester == 99L && req.requestSeq == 3 && req.t1 == 1_000_000_000L && req.hops == 2)
    val reply = MeshProtocol.parseSyncReply(MeshProtocol.syncReply(99L, 3, 1_000_000_000L, 1_070_000_000L, 1_071_000_000L, 1).data)
    val sample = ClockMath.estimate(reply.t1, reply.t2, reply.t3, 1_101_000_000L)!!
    check(sample.offsetNanos == 20_000_000L && sample.rttNanos == 100_000_000L)
    check(ClockMath.receiverDeadline(1_000_000_000L, 280, 20_000_000L) == 1_260_000_000L)
    val dedup = FrameHistory()
    check(dedup.firstTime(423L, 77) && !dedup.firstTime(423L, 77))
    check(dedup.firstTime(423L, 78))
    check(MeshProtocol.parseToken(MeshProtocol.millisToken(927231L)) == 927231L)
    val corrupt = wire.toByteArray().clone().apply { this[0] = 0 }
    var rejected = false
    try { MeshProtocol.read(DataInputStream(ByteArrayInputStream(corrupt))) }
    catch (_: IOException) { rejected = true }
    check(rejected)
    println("PASS: WAVE4 framing, PCM and timestamps, clock handshake, dedup and route fallback, corruption")
}
