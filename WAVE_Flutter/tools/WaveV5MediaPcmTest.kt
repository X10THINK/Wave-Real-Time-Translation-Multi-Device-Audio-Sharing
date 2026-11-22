package com.x10think.wave

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs
import kotlin.math.sin

/** Execute with desktop Kotlin: MediaPcmBridge and protocol have no Android imports. */
fun main() {
    for (hz in listOf(16_000,24_000,44_100,48_000)) for (ch in listOf(1,2)) {
        val output=mutableListOf<ByteArray>()
        val bridge=MediaPcmBridge { output.add(it) }
        bridge.configure(hz,ch,2)
        val frames=hz // 1 second test signal
        // Deliver deliberately irregular buffer sizes, not multiples of 20ms.
        var position=0
        while(position<frames) {
            val count=minOf((position%517)+31,frames-position)
            val buf=ByteBuffer.allocate(count*ch*2).order(ByteOrder.LITTLE_ENDIAN)
            repeat(count) { i ->
                val sample=(sin(2*Math.PI*440*(position+i)/hz)*10000).toInt().toShort()
                repeat(ch){buf.putShort(sample)}
            }
            buf.flip(); bridge.accept(buf);position+=count
        }
        // Input exactly 1s => ~50 frames at 20ms, tolerance due to phase rounding.
        check(output.size in 49..51){"Bad output 1s $hz/$ch: ${output.size}"}
        check(output.all{it.size==MeshProtocol.FRAME_BYTES})
        val pcm=output.flatMap { bytes ->
            ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).let { b ->
                List(bytes.size/2) { b.short.toInt() }
            }
        }
        val peak=pcm.maxOf{ abs(it) }
        check(peak in 8000..10500){"PCM magnitude bad: $peak at $hz/$ch"}
        println("PASS: $hz Hz / $ch ch -> ${output.size} 20ms frames, peak=$peak")
    }
    val results=mutableListOf<ByteArray>()
    val bad=MediaPcmBridge{results.add(it)}
    bad.configure(48_000,2,999)
    bad.accept(ByteBuffer.allocate(960))
    check(results.isEmpty() && bad.rejectedFormats.get()==1L)
    println("PASS: invalid PCM format rejected")
}
