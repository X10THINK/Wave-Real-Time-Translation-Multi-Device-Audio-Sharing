#!/usr/bin/env python3
"""V6 source integration checks. Does not compile Flutter or Android APK."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def t(p): return (r/p).read_text()
flow=t('lib/features/session_flow/flow_coordinator.dart')
setup=t('lib/features/session_flow/presentation/setup_screens.dart')
host=t('lib/features/audio/presentation/audio_live_screens.dart')
controls=t('lib/features/session_flow/presentation/live_network_widgets.dart')
native=t('android/app/src/main/kotlin/com/x10think/wave/MainActivity.kt')
lan=t('android/app/src/main/kotlin/com/x10think/wave/LanEngine.kt')
mesh=t('android/app/src/main/kotlin/com/x10think/wave/MeshEngine.kt')
audio=t('android/app/src/main/kotlin/com/x10think/wave/AudioPipeline.kt')
checks={
 'Audio method direct tap; translation retains Continue': 'widget.feature==WaveFeature.audio' in setup and 'selected==null?null' in setup,
 'Audio Host source selected after creating Lobby': 'if(draft.feature==WaveFeature.audio){_activateHost' in flow and 'onStart' in flow,
 'Audio Host has three source choices': all(x in host for x in ["title:'Music Player'","title:'Video Player'","const WaveLabel('External App Audio Share')"]),
 'No Audio Share microphone source tile': "title:'Microphone'" not in host,
 'No mandatory Audio Share setup page': 'if(draft.feature==WaveFeature.audio){_activateReceiver' in flow and 'NetworkSetupScreen' in flow,
 'Host receiver control sheet': 'ParticipantControlsSheet' in controls and 'controlReceiver' in controls,
 'LAN authenticated control with relay propagation': '"RCMD" ->' in lan and 'clients.values.forEach {child->' in lan,
 'Bluetooth direct per-peer control': 'fun controlReceiver(address:String' in mesh and 'c.origin==remoteNodeId' in mesh,
 'Host gain independent from receiver local gain': 'volume * hostVolume' in audio and 'hostPlaybackEnabled' in audio,
 'Receiver pause/resume control': 'Future<void> togglePause()' in host and 'resetPlaybackStream()' in audio,
 'Theater receiver placement guide': 'WaveReceiverPosition()' in host and 'speakerRole' in lan and 'speakerRole' in mesh,
 'Movie minimized pauses local player': 'didChangeAppLifecycleState' in t('lib/features/media/presentation/wave_media_screen.dart'),
 'Host global playback stop without ending room': 'stopSharedAudio' in native and 'stopSharedAudio' in host,
 'LAN offline connectivity preflight': 'usableLanAddress()!=null' in native,
 'Translation API not connected': 'not configured' in t('lib/features/translation/presentation/translation_screens.dart'),
 'Installed app label Wave': 'android:label="Wave"' in t('android/app/src/main/AndroidManifest.xml'),
 'Bluetooth ready method dispatched once': native.count('"bluetoothReady"->')==1,
 'No secret committed in source': 'AZURE_SPEECH_KEY=' not in native,
}
for label,val in checks.items():print(('PASS' if val else 'FAIL')+' '+label)
assert all(checks.values()),'V6 source integration audit failed'
print(f'PASS: {len(checks)} V6 static checks (NOT an APK build or phone test)')
