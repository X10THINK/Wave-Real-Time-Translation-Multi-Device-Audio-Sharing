package com.x10think.wave

import android.media.MediaCodec
import android.media.MediaCodecList
import android.media.MediaFormat
import android.os.Build
import java.nio.ByteBuffer
import java.nio.ByteOrder

/** Optional platform Opus MediaCodec path. Android 10+ supports Opus ENCODING
 * at framework level; runtime device codec probing is still mandatory.
 * PCM fallback is supported per-frame in WAVE4. Encoder and decoder are scoped
 * to a stream, not shared between multiple concurrently speaking sources.
 */
internal class OpusFrameCodec {
    private var encoder: MediaCodec? = null
    private var decoder: MediaCodec? = null
    private var frameIndex = 0L
    private var decodeIndex = 0L
    val encoderReady: Boolean get() = encoder != null
    val decoderReady: Boolean get() = decoder != null

    @Synchronized fun startEncoder(): Boolean {
        if (encoder != null) return true
        if (Build.VERSION.SDK_INT < 29) return false
        return try {
            val format=MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_OPUS,16_000,1)
            format.setInteger(MediaFormat.KEY_BIT_RATE,32_000)
            format.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE,640)
            val name=MediaCodecList(MediaCodecList.REGULAR_CODECS).findEncoderForFormat(format)
                ?:return false
            val codec=MediaCodec.createByCodecName(name)
            try {
                codec.configure(format,null,null,MediaCodec.CONFIGURE_FLAG_ENCODE)
                codec.start();encoder=codec;frameIndex=0
                true
            } catch(e:Exception) {codec.release();false}
        } catch(_:Exception){false}
    }

    @Synchronized fun startDecoder(): Boolean {
        if(decoder!=null)return true
        return try {
            val format=MediaFormat.createAudioFormat(MediaFormat.MIMETYPE_AUDIO_OPUS,16_000,1)
            // Identification header, 1ch, 16k input; Opus internals may output
            // a different rate on some devices. Such frames are rejected.
            val head=ByteBuffer.allocate(19).order(ByteOrder.LITTLE_ENDIAN)
            head.put("OpusHead".toByteArray(Charsets.US_ASCII))
            head.put(1.toByte());head.put(1.toByte());head.putShort(0)
            head.putInt(16_000);head.putShort(0);head.put(0.toByte())
            format.setByteBuffer("csd-0", ByteBuffer.wrap(head.array()))
            val codec=MediaCodec.createDecoderByType(MediaFormat.MIMETYPE_AUDIO_OPUS)
            try {codec.configure(format,null,null,0);codec.start();decoder=codec;true}
            catch(e:Exception){codec.release();false}
        } catch(_:Exception){false}
    }

    @Synchronized fun encode(pcm:ByteArray):ByteArray? {
        val c=encoder?:return null
        if(pcm.size!=640)return null
        return try {
            val input=c.dequeueInputBuffer(5000)
            if(input<0)return null
            c.getInputBuffer(input)?.apply {clear();put(pcm)} ?:return null
            val pts = frameIndex++ * 20_000L
            c.queueInputBuffer(input,0,pcm.size,pts,0)
            val info=MediaCodec.BufferInfo()
            repeat(5) {
                val outIndex=c.dequeueOutputBuffer(info,3000)
                if(outIndex>=0) {
                    val bytes=if(info.presentationTimeUs == pts && info.size in 1..512 && info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0) {
                        ByteArray(info.size).also { output ->
                            c.getOutputBuffer(outIndex)?.apply {position(info.offset);limit(info.offset+info.size);get(output)}
                        }
                    } else null
                    c.releaseOutputBuffer(outIndex,false)
                    if(bytes!=null)return bytes
                }
            }
            null
        } catch(_:Exception){closeEncoder();null}
    }

    @Synchronized fun decode(data:ByteArray):ByteArray? {
        val c=decoder?:return null
        return try {
            val input=c.dequeueInputBuffer(6000)
            if(input<0)return null
            c.getInputBuffer(input)?.apply {clear();put(data)}?:return null
            val pts = decodeIndex++ * 20_000L
            c.queueInputBuffer(input,0,data.size,pts,0)
            val info=MediaCodec.BufferInfo()
            repeat(5) {
                val out=c.dequeueOutputBuffer(info,3000)
                if(out>=0) {
                    val pcm=if(info.presentationTimeUs == pts && info.size == MeshProtocol.FRAME_BYTES)
                        ByteArray(info.size).also { bytes ->
                            c.getOutputBuffer(out)?.apply {position(info.offset);limit(info.offset+info.size);get(bytes)}
                        } else null
                    c.releaseOutputBuffer(out,false)
                    if(pcm!=null)return pcm
                }
            }
            null
        } catch(_:Exception){closeDecoder();null}
    }
    @Synchronized fun closeEncoder(){try{encoder?.stop()}catch(_:Exception){};try{encoder?.release()}catch(_:Exception){};encoder=null}
    @Synchronized fun closeDecoder(){try{decoder?.stop()}catch(_:Exception){};try{decoder?.release()}catch(_:Exception){};decoder=null}
    @Synchronized fun close(){closeEncoder();closeDecoder()}
}
