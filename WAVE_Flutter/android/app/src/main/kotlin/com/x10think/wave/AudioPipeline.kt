package com.x10think.wave

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioPlaybackCaptureConfiguration
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.media.projection.MediaProjection
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.SystemClock
import java.util.TreeMap
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import kotlin.math.max

/** Real-time audio never crosses the Flutter event channel. V2 has a common host-clock playout deadline. */
internal class AudioPipeline(private val context: Context, private val onFrame: (ByteArray) -> Unit) {
    companion object {
        private const val RATE = 16_000
        private const val FRAME_NS = 20_000_000L
        private const val WRITE_AHEAD_NS = 10_000_000L // heuristic; Android output hardware is not sample-locked
        private const val MAX_FRAMES = 24
    }
    private data class Scheduled(val pcm: ByteArray, val deadlineNs: Long)
    private val captureRunning = AtomicBoolean(false)
    private val playbackRunning = AtomicBoolean(false)
    private val playbackEpoch=java.util.concurrent.atomic.AtomicInteger(0)
    private val reorderLock = Any()
    private val frames = TreeMap<Int, Scheduled>()
    val droppedPlayback = AtomicLong()
    val latePlayback = AtomicLong()
    val underruns = AtomicLong()
    @Volatile var primeFrames = 2
    @Volatile var sourceKind = "off"
        private set
    /** Local and Host requested gains are independent; neither changes system volume. */
    var volume = 0.65f
        @Synchronized set(value) { field = value.coerceIn(0f, 1f); updateOutputGain() }
    var playbackEnabled = true
        @Synchronized set(value) {
            val wasEnabled = field
            field = value
            if (!wasEnabled && value) resetPlaybackStream() // resume at latest live Host timeline
            updateOutputGain()
        }
    /** Global Host play/pause is independent of receiver-local and Host-per-peer controls. */
    var sessionPlaybackEnabled = true
        @Synchronized set(value) {
            val was=field
            field=value
            if(!was && value)resetPlaybackStream()
            updateOutputGain()
        }
    var hostVolume = 1.0f
        @Synchronized set(value) {field=value.coerceIn(0f,1f);updateOutputGain()}
    var hostPlaybackEnabled = true
        @Synchronized set(value) {
            val wasEnabled=field
            field=value
            if(!wasEnabled && value) resetPlaybackStream()
            updateOutputGain()
        }
    @Synchronized private fun updateOutputGain() {
        track?.setVolume(if (playbackEnabled && hostPlaybackEnabled && sessionPlaybackEnabled) volume * hostVolume else 0f)
    }
    @Volatile private var record: AudioRecord? = null
    @Volatile private var track: AudioTrack? = null
    private var captureThread: Thread? = null
    private var playbackThread: Thread? = null
    private var aec: AcousticEchoCanceler? = null
    private var ns: NoiseSuppressor? = null
    private var agc: AutomaticGainControl? = null
    private var projection: MediaProjection? = null
    private var projectionCallback: MediaProjection.Callback? = null
    private val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var previousMode: Int? = null

    val isCapturing: Boolean get() = captureRunning.get()
    val pendingFrames: Int get() = synchronized(reorderLock) { frames.size }
    private fun pcmFormat(mask: Int) = AudioFormat.Builder()
        .setEncoding(AudioFormat.ENCODING_PCM_16BIT).setSampleRate(RATE).setChannelMask(mask).build()

    @SuppressLint("MissingPermission")
    @Synchronized fun startCapture() {
        if (captureRunning.get() && sourceKind == "microphone") return
        stopCapture()
        requireAudioPermission()
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        check(min > 0) { "AudioRecord not supported" }
        // VOICE_COMMUNICATION source enables compatible platform speech processing.
        // Do NOT force global MODE_IN_COMMUNICATION: on many phones this reroutes
        // local media/speaker output and makes microphone audio appear muffled.
        previousMode = null
        val r = try {
            AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                .setAudioFormat(pcmFormat(AudioFormat.CHANNEL_IN_MONO))
                .setBufferSizeInBytes(max(min, MeshProtocol.FRAME_BYTES * 4)).build()
        } catch (t: Throwable) {
            previousMode?.let { manager.mode = it }; previousMode = null
            throw t
        }
        if (r.state != AudioRecord.STATE_INITIALIZED) { r.release(); error("Microphone unavailable") }
        try { if (AcousticEchoCanceler.isAvailable()) aec = AcousticEchoCanceler.create(r.audioSessionId)?.apply { enabled = true } } catch (_: Exception) {}
        try { if (NoiseSuppressor.isAvailable()) ns = NoiseSuppressor.create(r.audioSessionId)?.apply { enabled = true } } catch (_: Exception) {}
        // Avoid forcing a second AGC stage. Several OEM audio paths already
        // apply gain control to VOICE_COMMUNICATION; double AGC causes pumping.
        // Keep AGC off by default; investigate device-specific processing later.
        startRecording(r, "microphone")
    }

    /** MediaProjection permission MUST be granted by visible user action for each new session. */
    @SuppressLint("MissingPermission")
    @Synchronized fun startDeviceAudio(proj: MediaProjection) {
        check(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) { "Device playback capture requires Android 10+" }
        requireAudioPermission()
        stopCapture()
        val config = AudioPlaybackCaptureConfiguration.Builder(proj)
            .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
            .addMatchingUsage(AudioAttributes.USAGE_GAME)
            .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN).build()
        val min = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        check(min > 0) { "Playback capture PCM format unavailable" }
        val cb = object : MediaProjection.Callback() {
            override fun onStop() { Thread { stopCapture() }.start() }
        }
        proj.registerCallback(cb, Handler(Looper.getMainLooper()))
        try {
            val r = AudioRecord.Builder().setAudioPlaybackCaptureConfig(config)
                .setAudioFormat(pcmFormat(AudioFormat.CHANNEL_IN_MONO))
                .setBufferSizeInBytes(max(min, MeshProtocol.FRAME_BYTES * 4)).build()
            if (r.state != AudioRecord.STATE_INITIALIZED) { r.release(); error("Playback capture unavailable") }
            projection = proj; projectionCallback = cb
            startRecording(r, "deviceAudio")
        } catch (t: Throwable) {
            try { proj.unregisterCallback(cb) } catch (_: Exception) {}
            try { proj.stop() } catch (_: Exception) {}
            throw t
        }
    }

    private fun requireAudioPermission() {
        check(context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
            "Microphone / audio capture permission required"
        }
    }

    private fun startRecording(r: AudioRecord, kind: String) {
        record = r
        try { r.startRecording() } catch (t: Throwable) { cleanupCapture(); throw t }
        sourceKind = kind
        captureRunning.set(true)
        captureThread = Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            var consecutiveReadErrors=0
            while (captureRunning.get()) {
                val pcm = ByteArray(MeshProtocol.FRAME_BYTES)
                var filled = 0
                while (filled < pcm.size && captureRunning.get()) {
                    val count = r.read(pcm, filled, pcm.size - filled, AudioRecord.READ_BLOCKING)
                    if (count <= 0) { filled = -1; break }
                    filled += count
                }
                if(filled < 0) {
                    consecutiveReadErrors++
                    if(consecutiveReadErrors>=5) {
                        // Do not busy-spin forever while reporting a live microphone.
                        captureRunning.set(false);sourceKind="off"
                        break
                    }
                    try {Thread.sleep(20)}catch (_:InterruptedException){break}
                    continue
                }
                consecutiveReadErrors=0
                if (filled == pcm.size && captureRunning.get()) onFrame(pcm)
            }
            // Handle device/permission loss without leaving a dead microphone
            // object marked "active". Do not release a newer replacement record.
            synchronized(this@AudioPipeline) {
                if(record === r && !captureRunning.get()) cleanupCapture()
            }
        }, "MeshCapture-$kind").apply { start() }
    }

    @Synchronized fun stopCapture() {
        captureRunning.set(false)
        try { record?.stop() } catch (_: Exception) {}
        try { captureThread?.join(350) } catch (_: InterruptedException) {}
        cleanupCapture()
    }

    private fun cleanupCapture() {
        try { aec?.release() } catch (_: Exception) {}; aec = null
        try { ns?.release() } catch (_: Exception) {}; ns = null
        try { agc?.release() } catch (_: Exception) {}; agc = null
        try { record?.release() } catch (_: Exception) {}; record = null
        previousMode?.let { try { manager.mode = it } catch (_: Exception) {} }; previousMode = null
        val old = projection; val cb = projectionCallback
        projection = null; projectionCallback = null
        if (old != null && cb != null) try { old.unregisterCallback(cb) } catch (_: Exception) {}
        try { old?.stop() } catch (_: Exception) {}
        sourceKind = "off"; captureThread = null
    }

    @Synchronized fun startPlayback() {
        if (playbackRunning.get()) return
        val min = AudioTrack.getMinBufferSize(RATE, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        check(min > 0) { "AudioTrack not supported" }
        val t = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setAudioFormat(pcmFormat(AudioFormat.CHANNEL_OUT_MONO))
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(max(min, MeshProtocol.FRAME_BYTES * 4))
            .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY).build()
        if (t.state != AudioTrack.STATE_INITIALIZED) { t.release(); error("Could not start receiver speaker") }
        track = t
        t.setVolume(if (playbackEnabled && hostPlaybackEnabled && sessionPlaybackEnabled) volume * hostVolume else 0f)
        synchronized(reorderLock) { frames.clear() }
        playbackRunning.set(true)
        playbackThread = Thread({
            Process.setThreadPriority(Process.THREAD_PRIORITY_AUDIO)
            val silence = ByteArray(MeshProtocol.FRAME_BYTES)
            var nextSeq: Int? = null
            var nextDeadlineNs = 0L
            var consecutiveMisses = 0
            var started = false
            var knownEpoch=playbackEpoch.get()
            while (playbackRunning.get()) {
                if(knownEpoch!=playbackEpoch.get()) {
                    knownEpoch=playbackEpoch.get()
                    nextSeq=null;nextDeadlineNs=0;consecutiveMisses=0
                    try{t.pause();t.flush()}catch(_:Exception){}
                    started=false
                }
                var shouldWaitForPrime = false
                synchronized(reorderLock) {
                    if (nextSeq == null) {
                        // Never start from an already-expired first frame.
                        val now = SystemClock.elapsedRealtimeNanos()
                        while (frames.isNotEmpty() && frames.firstEntry().value.deadlineNs < now + WRITE_AHEAD_NS) {
                            frames.pollFirstEntry()
                            latePlayback.incrementAndGet()
                        }
                        if (frames.size < primeFrames) shouldWaitForPrime = true
                        else {
                            val entry = frames.firstEntry()
                            nextSeq = entry.key
                            nextDeadlineNs = entry.value.deadlineNs
                            consecutiveMisses = 0
                        }
                    }
                }
                if (shouldWaitForPrime) {
                    try { Thread.sleep(4) } catch (_: InterruptedException) {}
                    continue
                }
                val seq = nextSeq ?: continue
                val now = SystemClock.elapsedRealtimeNanos()
                if (nextDeadlineNs < now - 90_000_000L) {
                    // A lagging device must skip rather than progressively increase audio latency.
                    droppedPlayback.incrementAndGet()
                    nextSeq = null
                    continue
                }
                val waitNs = nextDeadlineNs - WRITE_AHEAD_NS - now
                if (waitNs > 0) {
                    try { Thread.sleep(waitNs / 1_000_000L, (waitNs % 1_000_000L).toInt()) }
                    catch (_: InterruptedException) { if (!playbackRunning.get()) break }
                }
                // IMPORTANT: only dequeue at scheduled write time; a late-arriving packet may
                // still be in time for its playout deadline.
                val frame = synchronized(reorderLock) {
                    frames.headMap(seq, false).clear()
                    frames.remove(seq)
                }
                if (frame == null) { consecutiveMisses++; underruns.incrementAndGet() }
                else {
                    consecutiveMisses = 0
                    val divergence = frame.deadlineNs - nextDeadlineNs
                    if (kotlin.math.abs(divergence) < 25_000_000L) nextDeadlineNs += divergence / 8
                }
                if (consecutiveMisses >= 6) { nextSeq = null; continue }
                try {
                    if (!started) { t.play(); started = true }
                    t.write(frame?.pcm ?: silence, 0, MeshProtocol.FRAME_BYTES, AudioTrack.WRITE_BLOCKING)
                } catch (_: Exception) { break }
                nextSeq = seq + 1
                nextDeadlineNs += FRAME_NS
            }
        }, "MeshScheduledSpeaker").apply { start() }
    }

    /** Reset sequence/jitter state when the elected Host changes or media seeks.
     * Otherwise new stream seq=0 can be ignored behind old sequence values. */
    fun resetPlaybackStream() {
        synchronized(reorderLock) {frames.clear()}
        playbackEpoch.incrementAndGet()
    }

    /** Invoked for unique audio packets only, with host-clock offset established by four-way sync. */
    fun enqueue(sequence: Int, pcm: ByteArray, deadlineNs: Long) {
        if (!playbackRunning.get()) return
        val now = SystemClock.elapsedRealtimeNanos()
        if (deadlineNs < now - 15_000_000L) { latePlayback.incrementAndGet(); return }
        if (deadlineNs > now + 2_000_000_000L) { droppedPlayback.incrementAndGet(); return }
        synchronized(reorderLock) {
            // First packet wins. Never overwrite a queued frame with a later duplicate.
            if (!frames.containsKey(sequence)) frames[sequence] = Scheduled(pcm, deadlineNs)
            while (frames.size > MAX_FRAMES) { frames.pollFirstEntry(); droppedPlayback.incrementAndGet() }
        }
    }

    @Synchronized fun stopPlayback() {
        playbackRunning.set(false)
        playbackThread?.interrupt()
        try { track?.pause() } catch (_: Exception) {}
        try { track?.flush() } catch (_: Exception) {}
        try { playbackThread?.join(350) } catch (_: InterruptedException) {}
        try { track?.release() } catch (_: Exception) {}
        track = null; playbackThread = null
        synchronized(reorderLock) { frames.clear() }
    }

    /** Local WAVE Media3 audio is already decoded in process: no MediaProjection or
     * RECORD_AUDIO runtime permission is required for this source. */
    @Synchronized fun useInternalMedia() {
        stopCapture()
        sourceKind = "internalMedia"
    }
    fun acceptInternalMedia(pcm: ByteArray) {
        if (sourceKind == "internalMedia" && pcm.size == MeshProtocol.FRAME_BYTES) onFrame(pcm)
    }
    @Synchronized fun releaseInternalMedia() {
        if (sourceKind == "internalMedia") sourceKind = "off"
    }
    fun stopAll() { stopCapture(); releaseInternalMedia(); stopPlayback() }
}
