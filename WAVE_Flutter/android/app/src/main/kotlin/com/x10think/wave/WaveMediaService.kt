package com.x10think.wave

import android.content.Intent
import android.net.Uri
import android.view.View
import android.content.Context
import android.content.res.Resources
import android.widget.FrameLayout
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.common.audio.AudioProcessor
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.audio.AudioSink
import androidx.media3.exoplayer.audio.DefaultAudioSink
import androidx.media3.exoplayer.audio.TeeAudioProcessor
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import java.nio.ByteBuffer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.session.MediaSession.ControllerInfo
import androidx.media3.ui.PlayerView
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import java.io.File
import java.lang.ref.WeakReference

/** Media3 player owned by Android Service, not by a Flutter route. Activity navigation
 * and screen lock do not automatically dispose it. Force-stop / process kill cannot
 * guarantee continuity; external MediaProjection consent is also not restorable.
 */
@OptIn(UnstableApi::class)
class WaveMediaService : MediaSessionService() {
    companion object {
        const val LOAD = "wave.media.LOAD"
        const val PLAY = "wave.media.PLAY"
        const val PAUSE = "wave.media.PAUSE"
        const val SEEK = "wave.media.SEEK"
        const val SPEED = "wave.media.SPEED"
        const val STOP = "wave.media.STOP"
        @Volatile var instance: WaveMediaService? = null
            private set
        private val views = mutableListOf<WeakReference<PlayerView>>()
        @Volatile private var fitMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        // Media3 ExoPlayer renders video to a single Surface. Binding a player to
        // both the inline PlayerView and fullscreen PlayerView can steal the
        // Surface during seeking/route transitions and leave a black/glitched view.
        // The newest visible Flutter platform view owns the player exclusively.
        fun addView(view: PlayerView) {
            synchronized(views) {
                views.removeAll { it.get() == null || it.get() === view }
                val previous=views.lastOrNull()?.get()
                views.add(WeakReference(view))
                view.resizeMode = fitMode
                val active=instance?.player
                if (active != null) PlayerView.switchTargetView(active,previous,view)
                else previous?.player = null
            }
        }
        fun removeView(view: PlayerView) {
            synchronized(views) {
                views.removeAll { it.get() == null || it.get() === view }
                val previous=views.lastOrNull()?.get()
                previous?.resizeMode = fitMode
                val active=instance?.player
                if(active!=null && view.player===active)
                    PlayerView.switchTargetView(active,view,previous)
                else view.player = null
            }
        }
        fun setFitMode(mode: String) {
            fitMode = when(mode){
                "fill" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
                "zoom" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
            }
            synchronized(views){views.forEach { it.get()?.resizeMode=fitMode }}
        }
        private fun rebind(player: Player?) {
            synchronized(views) {
                views.removeAll { it.get() == null }
                // Rebind to exactly one active video Surface (even on Activity
                // recreation). Never assign ExoPlayer to several PlayerViews.
                views.forEach { it.get()?.player = null }
                views.lastOrNull()?.get()?.player = player
            }
        }
    }
    private var session: MediaSession? = null
    lateinit var player: ExoPlayer
        private set
    private var loadedPath = ""
    private var mediaKind="audio"
    private var mediaTitle="Selected media"
    private var playbackError=""
    private fun syncSharedPlayback() {
        val playing=player.isPlaying
        val lan=LanRuntime.get(this);val mesh=MeshRuntime.get(this)
        if(lan.isRunning() && lan.state()["host"]==true && lan.state()["captureSource"]=="internalMedia")lan.setGlobalPlaybackState(playing)
        if(mesh.isRunning() && mesh.state()["host"]==true && mesh.state()["captureSource"]=="internalMedia")mesh.setGlobalPlaybackState(playing)
    }

    override fun onCreate() {
        super.onCreate()
        // Direct PCM tap for imported movies/music. Does not depend on MediaProjection,
        // and never carries movie video to receivers.
        val rendererFactory=object:DefaultRenderersFactory(this){
            override fun buildAudioSink(context:Context, enableFloatOutput:Boolean,
                                        enableAudioOutputPlaybackParams:Boolean): AudioSink {
                val tee=TeeAudioProcessor(object:TeeAudioProcessor.AudioBufferSink{
                    override fun flush(sampleRateHz:Int, channelCount:Int, encoding:Int){
                        WaveInternalMediaTap.setInputFormat(sampleRateHz,channelCount,encoding)
                    }
                    override fun handleBuffer(buffer:ByteBuffer){WaveInternalMediaTap.takeBuffer(buffer)}
                })
                return DefaultAudioSink.Builder(context).setAudioProcessors(arrayOf<AudioProcessor>(tee)).build()
            }
        }
        player = ExoPlayer.Builder(this,rendererFactory)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA).setContentType(C.AUDIO_CONTENT_TYPE_MUSIC).build(),true)
            .setHandleAudioBecomingNoisy(true).build()
        player.addListener(object:Player.Listener {
            override fun onIsPlayingChanged(isPlaying:Boolean){syncSharedPlayback()}
            override fun onPlaybackStateChanged(playbackState:Int){syncSharedPlayback()}
            override fun onPlayerError(error:PlaybackException){playbackError="Playback failed. Try another file or reopen this file.";syncSharedPlayback()}
        })
        session = MediaSession.Builder(this, player).build()
        instance = this
        rebind(player)
    }

    override fun onGetSession(controllerInfo: ControllerInfo): MediaSession? = session

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val result = super.onStartCommand(intent, flags, startId)
        when(intent?.action) {
            LOAD -> {
                val path = intent.getStringExtra("path") ?: ""
                val uri=Uri.parse(path)
                val isContent=uri.scheme=="content"
                val file=if(isContent)null else File(path)
                if (path.isNotEmpty() && (isContent || (file?.isFile == true && file.canRead()))) {
                    player.pause()
                    playbackError=""
                    mediaKind=intent.getStringExtra("kind")?:"audio"
                    mediaTitle=intent.getStringExtra("title")?:"Selected media"
                    loadedPath = path
                    player.setMediaItem(MediaItem.fromUri(if(isContent) uri else Uri.fromFile(file!!)))
                    player.prepare()
                    getSharedPreferences("wave_media",MODE_PRIVATE).edit()
                        .putString("path",loadedPath).apply()
                }
            }
            PLAY -> if(player.mediaItemCount>0) player.play()
            PAUSE -> player.pause()
            SEEK -> player.seekTo((intent.getLongExtra("position",0L)).coerceAtLeast(0))
            SPEED -> player.setPlaybackSpeed(intent.getFloatExtra("speed",1f).coerceIn(0.5f,2f))
            STOP -> {
                player.pause();player.seekTo(0)
                WaveInternalMediaTap.setSink(null)
            }
        }
        return if(intent?.action==STOP) START_NOT_STICKY else result
    }

    fun snapshot(): Map<String,Any> = mapOf(
        "initialized" to (player.mediaItemCount>0 &&
            (player.playbackState==Player.STATE_READY || player.playbackState==Player.STATE_ENDED)),
        "isPlaying" to player.isPlaying,
        "durationMs" to player.duration.coerceAtLeast(0),
        "positionMs" to player.currentPosition.coerceAtLeast(0),
        "width" to (player.videoSize.width), "height" to (player.videoSize.height),
        "file" to loadedPath,"kind" to mediaKind,"title" to mediaTitle,
        "error" to playbackError,"buffering" to (player.playbackState==Player.STATE_BUFFERING),
        "speed" to player.playbackParameters.speed.toDouble(),
        "tappedFrames" to WaveInternalMediaTap.frameCount()
    )
    override fun onTaskRemoved(rootIntent:Intent?) {
        if (::player.isInitialized) {
            player.pause()
            WaveInternalMediaTap.setSink(null)
        }
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }
    override fun onDestroy() {
        rebind(null)
        session?.release();session=null
        WaveInternalMediaTap.setSink(null)
        player.release()
        instance=null
        super.onDestroy()
    }
}

internal class WaveVideoViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val root = FrameLayout(context)
        val video=PlayerView(context).apply {
            useController = false
            keepScreenOn = true
            layoutParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT)
        }
        root.addView(video)
        WaveMediaService.addView(video)
        return object: PlatformView {
            override fun getView(): View = root
            override fun dispose() { WaveMediaService.removeView(video);root.removeView(video) }
        }
    }
}
