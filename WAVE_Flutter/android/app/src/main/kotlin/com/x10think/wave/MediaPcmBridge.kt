package com.x10think.wave

import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.roundToInt

/** Converts Media3's interleaved PCM16 (usually 44.1/48 kHz stereo) into the
 * 20 ms / 16 kHz / mono frames required by the current WAVE transport.
 * This is a continuous resampler: fractional phase is NOT reset at buffer edges.
 * No Android dependency; exercised by desktop JVM tests.
 *
 * A windowed-sinc low-pass filter suppresses aliases before decimation.
 */
internal class MediaPcmBridge(private val output: (ByteArray) -> Unit) {
    private var inputHz = 0
    private var channels = 0
    private var inputIndex = 0L
    private var nextOutputIndex = 0.0
    private var taps = DoubleArray(0)
    private var samples = DoubleArray(0)
    private var cursor = 0
    private var previous = 0.0
    private var partial = ByteArray(MeshProtocol.FRAME_BYTES)
    private var written = 0
    val completedFrames = AtomicLong(0)
    var rejectedFormats = AtomicLong(0)
        private set

    @Synchronized fun configure(rate: Int, channelCount: Int, encoding: Int) {
        // Android/Media3 ENCODING_PCM_16BIT has value 2.
        if (rate !in 8_000..192_000 || channelCount !in 1..8 || encoding != 2) {
            inputHz = 0; channels = 0; rejectedFormats.incrementAndGet(); return
        }
        taps = if (rate <= 16_000) DoubleArray(0) else {
            val half = (rate / 1400).coerceIn(16,140)
            val cutoff = 7300.0 / rate
            val kernel = DoubleArray(2*half+1) { i ->
                val t = i-half
                val sinc = if(t==0) 2*cutoff else kotlin.math.sin(2*Math.PI*cutoff*t)/(Math.PI*t)
                sinc * (0.5 - 0.5*kotlin.math.cos(Math.PI*i/half))
            }
            val gain = kernel.sum()
            DoubleArray(kernel.size) { kernel[it]/gain }
        }
        samples = DoubleArray(taps.size)
        cursor = 0
        inputHz = rate; channels = channelCount
        inputIndex = 0L; nextOutputIndex = 0.0; previous = 0.0
        written = 0; partial = ByteArray(MeshProtocol.FRAME_BYTES)
    }

    @Synchronized fun accept(source: ByteBuffer) {
        if (inputHz == 0 || channels == 0) return
        val bytes = source.asReadOnlyBuffer().order(ByteOrder.LITTLE_ENDIAN)
        val stride = channels * 2
        val frames = bytes.remaining() / stride
        if (frames == 0) return
        val step = inputHz.toDouble() / 16_000.0
        for (i in 0 until frames) {
            var sum = 0.0
            for (ch in 0 until channels) sum += bytes.short.toDouble()
            var sample = sum / channels
            if(taps.isNotEmpty()) {
                samples[cursor] = sample
                var read = cursor
                sample = 0.0
                for(coefficient in taps) {
                    sample += samples[read] * coefficient
                    if (--read < 0) read = samples.lastIndex
                }
                cursor = (cursor + 1) % samples.size
            }
            val index = inputIndex.toDouble()
            while (nextOutputIndex <= index + 0.000000001) {
                val fraction = if (inputIndex == 0L) 1.0
                               else (nextOutputIndex - (inputIndex - 1).toDouble()).coerceIn(0.0, 1.0)
                val interpolated = (previous + (sample - previous) * fraction)
                    .roundToInt().coerceIn(-32768, 32767)
                partial[written++] = (interpolated and 255).toByte()
                partial[written++] = ((interpolated shr 8) and 255).toByte()
                if (written == MeshProtocol.FRAME_BYTES) {
                    val complete = partial
                    partial = ByteArray(MeshProtocol.FRAME_BYTES)
                    written = 0
                    completedFrames.incrementAndGet()
                    // Callback MUST offer into a bounded non-blocking queue; never send from Media3 render thread.
                    output(complete)
                }
                nextOutputIndex += step
            }
            previous = sample
            inputIndex++
        }
    }
    @Synchronized fun reset() { samples.fill(0.0); cursor=0; written=0; inputIndex=0; nextOutputIndex=0.0; previous=0.0 }
}

/** One active WAVE session at a time. Media3 PCM tap is always present but only
 * broadcasts when the user explicitly selected the local media audio source.
 */
internal object WaveInternalMediaTap {
    @Volatile private var sink: ((ByteArray)->Unit)? = null
    private val bridge = MediaPcmBridge { frame -> sink?.invoke(frame) }
    fun setSink(callback: ((ByteArray)->Unit)?) {
        sink = callback
        bridge.reset()
        if(callback!=null)bridge.completedFrames.set(0)
    }
    fun setInputFormat(rate: Int, channelCount: Int, encoding: Int) {
        bridge.configure(rate,channelCount,encoding)
    }
    fun takeBuffer(buffer: ByteBuffer) { if (sink != null) bridge.accept(buffer) }
    fun frameCount(): Long = bridge.completedFrames.get()
    fun reset() {bridge.reset()}
}
