package com.x10think.wave

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream

/** Pure JVM localhost test of real socket framing + AES-GCM, not Android radio testing. */
fun main() {
    val room="TEST-42"
    val secret=SecureEnvelope.generateInvite()
    val host=SecureEnvelope(secret,room)
    val receiver=SecureEnvelope(secret,room)
    DatagramSocket(0,InetAddress.getLoopbackAddress()).use { tx ->
        DatagramSocket(0,InetAddress.getLoopbackAddress()).use { rx ->
            rx.soTimeout=1500
            val pcm=ByteArray(MeshProtocol.FRAME_BYTES){(it and 0x7f).toByte()}
            val seen=FrameHistory(256)
            for(seq in 0 until 100) {
                val frame=MeshProtocol.audio(1001,seq,0,System.nanoTime(),260,pcm)
                val bytes=ByteArrayOutputStream().also { MeshProtocol.write(DataOutputStream(it),frame) }.toByteArray()
                val encrypted=host.seal(bytes)
                tx.send(DatagramPacket(encrypted,encrypted.size,InetAddress.getLoopbackAddress(),rx.localPort))
                val buffer=ByteArray(2048)
                val d=DatagramPacket(buffer,buffer.size)
                rx.receive(d)
                val raw=receiver.open(d.data.copyOf(d.length))
                val decoded=MeshProtocol.parseAudio(MeshProtocol.read(DataInputStream(ByteArrayInputStream(raw))).data)
                check(decoded.sequence==seq && decoded.pcm.contentEquals(pcm))
                check(seen.firstTime(decoded.origin,decoded.sequence))
                check(!seen.firstTime(decoded.origin,decoded.sequence))
            }
        }
    }
    println("PASS: 100/100 localhost encrypted UDP audio frames received/decoded; dedup applies")
}
