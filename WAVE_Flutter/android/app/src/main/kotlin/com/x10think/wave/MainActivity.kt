package com.x10think.wave

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.provider.Settings
import android.provider.MediaStore
import android.content.ContentUris
import android.net.Uri
import android.media.MediaMetadataRetriever
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformViewRegistry

/** Android transport/lifecycle bridge: all raw audio stays native, never passes through Dart. */
class MainActivity:FlutterActivity() {
    private val commands="wave.native/commands"
    private val events="wave.native/events"
    private val mesh by lazy {MeshRuntime.get(applicationContext)}
    private val lan by lazy {LanRuntime.get(applicationContext)}
    private val mediaIo=java.util.concurrent.Executors.newSingleThreadExecutor()
    private var mode=""
    private val sessionPrefs by lazy { getSharedPreferences("wave_active_session", Context.MODE_PRIVATE) }
    /** FlutterActivity can be recreated while the native foreground session stays alive. */
    private fun activeMode(): String = when {
        mesh.isRunning() -> "bluetooth"
        lan.isRunning() -> if (mode == "hotspot" || (mode.isBlank() && sessionPrefs.getString("mode", "") == "hotspot")) "hotspot" else "wifi"
        else -> ""
    }
    private var sink:EventChannel.EventSink?=null
    private var meshObserver:((Map<String,Any?>)->Unit)?=null
    private var lanObserver:((Map<String,Any?>)->Unit)?=null
    private var permissionResult:MethodChannel.Result?=null
    private var projectionResult:MethodChannel.Result?=null
    private val permissionReq=4102
    private val projectionReq=4103

    override fun configureFlutterEngine(flutterEngine:FlutterEngine){
        super.configureFlutterEngine(flutterEngine)
        mode = activeMode() // Recover persisted Activity state after notification tap/rotation.
        flutterEngine.platformViewsController.registry.registerViewFactory("wave/native_video",WaveVideoViewFactory())
        meshObserver={data->runOnUiThread {sink?.success(state())}}
        lanObserver={data->runOnUiThread {sink?.success(state())}}
        meshObserver?.let{MeshRuntime.observe(it)}
        lanObserver?.let{LanRuntime.observe(it)}
        EventChannel(flutterEngine.dartExecutor.binaryMessenger,events).setStreamHandler(object:EventChannel.StreamHandler{
            override fun onListen(arguments:Any?,events:EventChannel.EventSink){sink=events;push()}
            override fun onCancel(arguments:Any?){sink=null}
        })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,commands).setMethodCallHandler{call,result->
            try {
                when(call.method){
                    "permissions"->{
                        val bt=call.argument<Boolean>("bluetooth")?:false
                        val needsMic=call.argument<Boolean>("host")?:true
                        val missing=requiredPermissions(bt,needsMic).filter{checkSelfPermission(it)!=PackageManager.PERMISSION_GRANTED}
                        if(missing.isEmpty())result.success(true)
                        else if(permissionResult!=null)result.error("BUSY","Another permission request is open",null)
                        else{permissionResult=result;requestPermissions(missing.toTypedArray(),permissionReq)}
                    }
                    "start"->{
                        if (isActive()) {
                            result.error("SESSION_ACTIVE", "An existing WAVE session is still running. Resume it or confirm Stop & Start New.", state())
                        } else {
                        val next=call.argument<String>("mode")?:"wifi"
                        require(next == "wifi" || next == "hotspot" || next == "bluetooth") { "Unsupported network mode" }
                        if(next!="bluetooth")check(usableLanAddress()!=null) {
                            if(next=="hotspot")
                                "Host: enable your hotspot; Receiver: connect to Host hotspot, then retry"
                            else "Connect this phone to reachable Wi-Fi, then retry"
                        }
                        val room=call.argument<String>("room")?:""
                        val host=call.argument<Boolean>("host")?:false
                        val invite=call.argument<String>("invite") ?: ""
                        // Reject legacy/insecure room-code-only sessions.
                        SecureEnvelope(invite, room)
                        check(requiredPermissions(next=="bluetooth",false).all{checkSelfPermission(it)==PackageManager.PERMISSION_GRANTED}){
                            "Grant required Android audio and wireless permissions first"
                        }
                        startForegroundService(Intent(this,MeshForegroundService::class.java).putExtra("host", host))
                        try {
                            if(next=="bluetooth") mesh.start(room,host,invite,call.argument<Boolean>("approval")?:false,call.argument<Int>("capacity")?:10,call.argument<String>("displayName")?:"Listener")
                            else lan.start(room,call.argument<String>("name")?:"WAVE Room",host,
                                call.argument<Boolean>("approval")?:false,call.argument<Int>("capacity")?:10,invite,call.argument<String>("displayName")?:"Listener")
                            val initialVolume=call.argument<Double>("volume")?:0.8
                            if(next=="bluetooth")mesh.setPlayback(true,initialVolume) else lan.setPlayback(true,initialVolume)
                            mode=next
                            sessionPrefs.edit()
                                .putLong("startedAt",System.currentTimeMillis())
                                .putString("mode", next)
                                .putString("feature", call.argument<String>("feature") ?: "audio")
                                .putString("sessionName", call.argument<String>("name") ?: "WAVE Room")
                                .apply()
                            result.success(state())
                        } catch(e:Exception){stopService(Intent(this,MeshForegroundService::class.java));throw e}
                        }
                    }
                    "invite"->result.success(if (isHost()) { if(activeMode()=="bluetooth") mesh.inviteSecretForHost() else lan.inviteSecretForHost() } else "")
                    "join"->{
                        check(activeMode()!="bluetooth") {"Select a paired Bluetooth peer to connect"}
                        lan.join(call.argument<String>("ip"))
                        result.success(state())
                    }
                    "state"->result.success(state())
                    "stop"->{
                        mesh.stop();lan.stop()
                        startService(Intent(this,WaveMediaService::class.java).setAction(WaveMediaService.STOP))
                        stopService(Intent(this,MeshForegroundService::class.java))
                        mode="";sessionPrefs.edit().clear().apply();result.success(state())
                    }
                    "translationCaption" -> {
                        check(isActive() && isHost() &&
                            sessionPrefs.getString("feature", "") == "translation") {
                            "Translation requires an active Live Translation Host room"
                        }
                        val language=call.argument<String>("language") ?: ""
                        val caption=call.argument<String>("text") ?: ""
                        check(language=="ta" || language=="en") { "Unsupported translation language" }
                        if(activeMode()=="bluetooth") mesh.broadcastTranslationCaption(language,caption)
                        else lan.broadcastTranslationCaption(language,caption)
                        result.success(true)
                    }
                    "roomPlayback" -> {
                        check(isActive() && isHost()) { "Host-only playback action" }
                        val play=call.argument<Boolean>("play") ?: false
                        if(activeMode()=="bluetooth")mesh.setGlobalPlaybackState(play)
                        else lan.setGlobalPlaybackState(play)
                        result.success(state())
                    }
                    "receiverControl"->{
                        val id=call.argument<String>("id")?:""
                        val action=call.argument<String>("action")?:""
                        val gain=call.argument<Int>("value")?:100
                        check(isActive() && isHost()) { "Host-only action" }
                        if(activeMode()=="bluetooth")mesh.controlReceiver(id,action,gain)
                        else lan.controlReceiver(id,action,gain)
                        result.success(true)
                    }
                    "receiverPlayback"->{
                        check(isActive() && !isHost()) { "Receiver-only control" }
                        val play=call.argument<Boolean>("play")?:true
                        val vol=(state()["volume"] as? Number)?.toDouble()?:0.7
                        if(activeMode()=="bluetooth")mesh.setPlayback(play,vol)
                        else lan.setPlayback(play,vol)
                        result.success(state())
                    }
                    "pairedDevices"->result.success(mesh.pairedDevices())
                    "bluetoothReady"->result.success(mesh.bluetoothReady())
                    "connectBluetooth"->{check(activeMode()=="bluetooth");mesh.connectTo(call.argument<String>("address")?:"");result.success(true)}
                    "disconnectBluetooth"->{mesh.disconnect(call.argument<String>("address")?:"");result.success(true)}
                    "approve"->{if(activeMode()=="bluetooth")mesh.approve(call.argument<String>("id")?:"",call.argument<Boolean>("allow")?:false) else lan.approve(call.argument<String>("id")?:"",call.argument<Boolean>("allow")?:false);result.success(true)}
                    "remove" -> {
                        check(isHost() && call.argument<String>("room") == state()["room"]) { "Room changed" }
                        val id = requireNotNull(call.argument<String>("id"))
                        if(activeMode()=="bluetooth") mesh.blockPeer(id) else lan.disconnect(id)
                        result.success(true);push()
                    }
                    "mic"->{val enabled=call.argument<Boolean>("enabled")?:false
                        if(enabled && isHost()) {
                            MeshForegroundService.instance?.enableHostMicrophone()
                                ?:error("Active foreground service required")
                        }
                        if(activeMode()=="bluetooth")mesh.setMic(enabled) else lan.setMic(enabled)
                        result.success(true)
                    }
                    "volume"->{val enabled=call.argument<Boolean>("enabled")?:true
                        val volume=(call.argument<Double>("volume")?:0.7).coerceIn(0.0,1.0)
                        if(activeMode()=="bluetooth")mesh.setPlayback(enabled,volume) else lan.setPlayback(enabled,volume)
                        result.success(true)
                    }
                    "targetDelay"->{val ms=call.argument<Int>("milliseconds")?:280
                        if(activeMode()=="bluetooth")mesh.setTargetDelay(ms) else lan.setTargetDelay(ms)
                        result.success(true)
                    }
                    "opus" -> {
                        val requested=call.argument<Boolean>("enabled") ?: false
                        val active=if(activeMode()=="bluetooth") mesh.setOpus(requested) else lan.setOpus(requested)
                        result.success(active)
                    }
                    "stopSharedAudio" -> {
                        check(isActive() && isHost()) { "Only the Host can stop shared playback" }
                        if(activeMode()=="bluetooth") {
                            mesh.setGlobalPlaybackState(false);mesh.stopSharedAudio()
                        } else {
                            lan.setGlobalPlaybackState(false);lan.stopSharedAudio()
                        }
                        startService(Intent(this,WaveMediaService::class.java).setAction(WaveMediaService.STOP))
                        result.success(state())
                    }
                    "internalMedia" -> {
                        check(isActive() && isHost()) { "Start WAVE as Host to broadcast imported media" }
                        val enabled=call.argument<Boolean>("enabled") ?: true
                        if(activeMode()=="bluetooth")mesh.setInternalMedia(enabled)
                        else lan.setInternalMedia(enabled)
                        result.success(true)
                    }
                    "musicPermission" -> {
                        val perm=if(Build.VERSION.SDK_INT>=33)
                            Manifest.permission.READ_MEDIA_AUDIO
                        else if(Build.VERSION.SDK_INT>=23)
                            Manifest.permission.READ_EXTERNAL_STORAGE
                        else ""
                        if(perm.isEmpty() || checkSelfPermission(perm)==PackageManager.PERMISSION_GRANTED)
                            result.success(true)
                        else if(permissionResult!=null)
                            result.error("BUSY","Another Android permission dialog is open",null)
                        else { permissionResult=result;requestPermissions(arrayOf(perm),permissionReq) }
                    }
                    "musicLibrary" -> {
                        val perm=if(Build.VERSION.SDK_INT>=33) Manifest.permission.READ_MEDIA_AUDIO
                            else if(Build.VERSION.SDK_INT>=23) Manifest.permission.READ_EXTERNAL_STORAGE else ""
                        check(perm.isEmpty() || checkSelfPermission(perm)==PackageManager.PERMISSION_GRANTED) {
                            "Allow music library access first"
                        }
                        mediaIo.execute { try {val tracks=readMusicLibrary();runOnUiThread {result.success(tracks)}} catch(e:Exception){runOnUiThread {result.error("LIBRARY","Unable to read music. Check permission and retry.",null)}} }
                    }
                    "mediaFit" -> {
                        WaveMediaService.setFitMode(call.argument<String>("mode") ?: "fit")
                        result.success(true)
                    }
                    "mediaOpen" -> {
                        val path=call.argument<String>("path")?:""
                        val kind=call.argument<String>("kind")?:""
                        check(kind=="audio" || kind=="video") { "Select Music or Video first" }
                        mediaIo.execute {
                            try {
                                validateMedia(path,kind)
                                runOnUiThread {
                                  try {
                                    startService(Intent(this,WaveMediaService::class.java).setAction(WaveMediaService.LOAD)
                                      .putExtra("path",path).putExtra("kind",kind).putExtra("title",call.argument<String>("title")?:"Selected media"))
                                    if(isActive() && isHost()) {
                                      if(activeMode()=="bluetooth")mesh.setInternalMedia(true) else lan.setInternalMedia(true)
                                    }
                                    result.success(true)
                                  }catch(e:Exception){result.error("MEDIA","Could not open selected media",null)}
                                }
                            }catch(e:Exception){runOnUiThread {result.error("MEDIA",e.message?:"Unsupported file",null)}}
                        }
                    }

                    "mediaPlay" -> {
                        if(isActive() && isHost()) {
                            if(activeMode()=="bluetooth")mesh.setInternalMedia(true)
                            else lan.setInternalMedia(true)
                        }
                        startService(Intent(this,WaveMediaService::class.java)
                        .setAction(WaveMediaService.PLAY))
                        if(isActive() && isHost()) {
                            if(activeMode()=="bluetooth")mesh.setGlobalPlaybackState(true)
                            else lan.setGlobalPlaybackState(true)
                        }
                        result.success(true)}
                    "mediaPause" -> {startService(Intent(this,WaveMediaService::class.java)
                        .setAction(WaveMediaService.PAUSE))
                        if(isActive() && isHost()) {
                            if(activeMode()=="bluetooth")mesh.setGlobalPlaybackState(false)
                            else lan.setGlobalPlaybackState(false)
                        }
                        result.success(true)}
                    "mediaSpeed" -> {
                        val speed=(call.argument<Double>("speed")?:1.0).toFloat()
                        check(speed in 0.5f..2.0f) { "Unsupported speed" }
                        startService(Intent(this,WaveMediaService::class.java)
                            .setAction(WaveMediaService.SPEED).putExtra("speed",speed))
                        result.success(true)
                    }
                    "mediaSeek" -> {WaveInternalMediaTap.reset()
                        startService(Intent(this,WaveMediaService::class.java)
                        .setAction(WaveMediaService.SEEK)
                        .putExtra("position",call.argument<Int>("position")?.toLong()?:0L));result.success(true)}
                    "mediaStop" -> {startService(Intent(this,WaveMediaService::class.java)
                        .setAction(WaveMediaService.STOP))
                        if(isActive() && isHost()) {
                            if(activeMode()=="bluetooth") {
                                mesh.setGlobalPlaybackState(false)
                                mesh.setInternalMedia(false)
                            } else {
                                lan.setGlobalPlaybackState(false)
                                lan.setInternalMedia(false)
                            }
                        }
                        result.success(true)}
                    "mediaState" -> result.success(WaveMediaService.instance?.snapshot()
                        ?:mapOf("initialized" to false,"isPlaying" to false))
                    "captureDeviceAudio"->{
                        check(isActive()){"Start an audio sharing session first"}
                        check(isHost()){"Only session Host may capture device audio"}
                        check(Build.VERSION.SDK_INT>=29){"Device playback capture requires Android 10+"}
                        check(projectionResult==null){"An audio capture permission dialog is already open"}
                        projectionResult=result
                        val mgr=getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        startActivityForResult(mgr.createScreenCaptureIntent(),projectionReq)
                    }
                    "appSettings"->{startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:$packageName")));result.success(true)}
                    "wifiSettings"->{startActivity(Intent(Settings.ACTION_WIFI_SETTINGS));result.success(true)}
                    "hotspotSettings"->{startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS));result.success(true)}
                    "bluetoothSettings"->{startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS));result.success(true)}
                    else->result.notImplemented()
                }
            } catch(t:Throwable){result.error("WAVE_NATIVE",t.message?:t.javaClass.simpleName,null)}
        }
    }

    /** Prevent video-only files in Music and audio-only/image files in Video.
     * The picker extension is advisory; actual media tracks are validated here.
     */
    private fun validateMedia(path:String, kind:String) {
        val uri=Uri.parse(path)
        val isContent=uri.scheme=="content"
        if(!isContent) check(File(path).isFile) { "File unavailable or removed" }
        val retriever=MediaMetadataRetriever()
        try {
            if(isContent) retriever.setDataSource(this,uri)
            else retriever.setDataSource(path)
            val hasVideo=retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_VIDEO)=="yes"
            val hasAudio=retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_HAS_AUDIO)=="yes"
            if(kind=="video") check(hasVideo) { "This file has no playable video track" }
            else check(hasAudio && !hasVideo) { "Select an audio-only music file" }
        } catch (e:IllegalStateException) { throw e }
        catch (e:Exception) { throw IllegalArgumentException("Unsupported or unreadable ${kind} file",e) }
        finally { try {retriever.release()}catch(_:Exception){} }
    }

    /** Query Android's accessible on-device music collection after user consent.
     * Never scrape all storage paths or request MANAGE_EXTERNAL_STORAGE.
     */
    private fun readMusicLibrary():List<Map<String,Any?>> {
        val tracks=mutableListOf<Map<String,Any?>>()
        val uri=MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val columns=arrayOf(MediaStore.Audio.Media._ID,MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,MediaStore.Audio.Media.DURATION)
        contentResolver.query(uri,columns,"${MediaStore.Audio.Media.DURATION}>0",
            null,"${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC")?.use {cursor->
            val idIndex=cursor.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleIndex=cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistIndex=cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val durationIndex=cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            while(cursor.moveToNext()) {
                val id=cursor.getLong(idIndex)
                tracks.add(mapOf("uri" to ContentUris.withAppendedId(uri,id).toString(),
                    "title" to cursor.getString(titleIndex).orEmpty(),
                    "artist" to cursor.getString(artistIndex).orEmpty(),
                    "durationMs" to cursor.getLong(durationIndex)))
            }
        }
        return tracks
    }

    /** Current Android device IPv4 endpoint for the existing UDP LAN engine.
     * Exclude mobile data, VPN and loopback: they cannot join an offline LAN. */
    private fun usableLanAddress():String? = try {
        val nics=java.net.NetworkInterface.getNetworkInterfaces()
        var found:String?=null
        while(nics.hasMoreElements() && found==null){
            val nic=nics.nextElement()
            val name=nic.name.lowercase()
            if(!nic.isUp || nic.isLoopback || name.startsWith("rmnet") ||
               name.startsWith("pdp") || name.startsWith("tun") ||
               name.startsWith("clat") || name.startsWith("v4-"))continue
            val ips=nic.inetAddresses
            while(ips.hasMoreElements()){
                val ip=ips.nextElement()
                if(ip is java.net.Inet4Address && ip.isSiteLocalAddress &&
                   !ip.isLoopbackAddress){found=ip.hostAddress;break}
            }
        }
        found
    }catch(_:Exception){null}

    private fun isActive()=mesh.isRunning()||lan.isRunning()
    private fun isHost():Boolean = (state()["host"] as? Boolean)==true
    private fun state():Map<String,Any?> {
        val current = activeMode()
        val base = when(current){
            "bluetooth" -> mesh.state()
            "wifi", "hotspot" -> lan.state()
            else -> mapOf("running" to false, "connected" to 0)
        }
        return base + mapOf(
            "mode" to current,
            "feature" to (if(current.isNotEmpty()) sessionPrefs.getString("feature", "audio") else ""),
            "sessionName" to (base["sessionName"] ?: if(current.isNotEmpty()) sessionPrefs.getString("sessionName", "WAVE Room") else ""),
            "startedAt" to sessionPrefs.getLong("startedAt",System.currentTimeMillis())
        )
    }
    private fun push(){if(sink!=null)sink?.success(state())}
    private fun requiredPermissions(bluetooth:Boolean, needsMic:Boolean):List<String> = buildList {
        if(needsMic) add(Manifest.permission.RECORD_AUDIO)
        if(bluetooth && Build.VERSION.SDK_INT>=31)add(Manifest.permission.BLUETOOTH_CONNECT)
    }

    override fun onActivityResult(requestCode:Int,resultCode:Int,data:Intent?){
        super.onActivityResult(requestCode,resultCode,data)
        if(requestCode!=projectionReq)return
        val reply=projectionResult;projectionResult=null
        if(resultCode!=Activity.RESULT_OK || data==null){reply?.error("CANCELLED","Screen/audio capture permission denied",null);return}
        try {
            MeshForegroundService.instance?.enableMediaProjection()
                ?:error("Foreground service not running")
            val mgr=getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val projection=mgr.getMediaProjection(resultCode,data) ?: error("Android could not start audio capture")
            if(activeMode()=="bluetooth")mesh.setDeviceAudio(projection) else lan.setDeviceAudio(projection)
            reply?.success(true)
        }catch(t:Throwable){reply?.error("CAPTURE",t.message?:"Could not capture device audio",null)}
    }
    override fun onRequestPermissionsResult(requestCode:Int,permissions:Array<out String>,grantResults:IntArray){
        super.onRequestPermissionsResult(requestCode,permissions,grantResults)
        if(requestCode==permissionReq){permissionResult?.success(grantResults.isNotEmpty()&&grantResults.all{it==PackageManager.PERMISSION_GRANTED});permissionResult=null}
    }
    override fun onDestroy(){mediaIo.shutdown();meshObserver?.let{MeshRuntime.unobserve(it)};lanObserver?.let{LanRuntime.unobserve(it)};meshObserver=null;lanObserver=null;sink=null;super.onDestroy()}
}
