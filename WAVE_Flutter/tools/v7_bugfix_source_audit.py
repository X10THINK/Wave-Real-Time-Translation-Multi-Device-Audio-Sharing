#!/usr/bin/env python3
"""V7 patch integrity checks; source assertions are not an Android integration test."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def t(x):return (r/x).read_text()
main=t('android/app/src/main/kotlin/com/x10think/wave/MainActivity.kt')
service=t('android/app/src/main/kotlin/com/x10think/wave/MeshForegroundService.kt')
mediaService=t('android/app/src/main/kotlin/com/x10think/wave/WaveMediaService.kt')
crypto=t('android/app/src/main/kotlin/com/x10think/wave/SecureEnvelope.kt')
mediaUi=t('lib/features/media/presentation/wave_media_screen.dart')
receiver=t('lib/features/audio/presentation/audio_live_screens.dart')
playback=t('lib/core/media/wave_media_playback.dart')
flow=t('lib/features/session_flow/flow_coordinator.dart')
lan=t('android/app/src/main/kotlin/com/x10think/wave/LanEngine.kt')
mesh=t('android/app/src/main/kotlin/com/x10think/wave/MeshEngine.kt')
source=t('lib/features/audio/presentation/music_screens.dart')
checks={
 'Compact authenticated W6 join code':"generateCompactInvite" in crypto and "W6:" in flow and 'Secure Join Code' in t('lib/features/session_flow/presentation/live_network_widgets.dart'),
 'No room-id-only authentication': "Enter the Secure Join Code" in flow and "Valid WAVE6 compact or WAVE4" in crypto,
 'Recents task removal end': 'onTaskRemoved' in service and 'MeshRuntime.get(this).stop()' in service and 'LanRuntime.get(this).stop()' in service,
 'Host video + receiver audio-only': 'AndroidView' in mediaUi and 'Others hear only its audio' in mediaUi,
 'Host global pause via both transports': 'setGlobalPlaybackState' in main and 'setGlobalPlaybackState' in lan and 'setGlobalPlaybackState' in mesh,
 'Receiver paused UI reflects Host': "hostStreamPaused" in receiver and 'sessionPlaybackEnabled' in t('android/app/src/main/kotlin/com/x10think/wave/AudioPipeline.kt'),
 'Music MediaStore query with Android consent': 'readMusicLibrary()' in main and 'musicPermission' in main and 'READ_MEDIA_AUDIO' in t('android/app/src/main/AndroidManifest.xml'),
 'Music library displayed': 'media.musicLibrary' in mediaUi and 'loadMusicLibrary()' in mediaUi,
 'Real track type validation': 'validateMedia(path,kind)' in main and 'METADATA_KEY_HAS_VIDEO' in main,
 'Movie fullscreen controls + seek throttling': '_FullScreenWaveVideoState' in mediaUi and 'onChangeEnd:' in mediaUi,
 'No duplicate player broadcast card': 'Enable Imported Movie' not in mediaUi and 'Audio Broadcast Enabled' not in mediaUi,
 'Audio Share mic source removed': "title:'Microphone'" not in source,
 'Technical panel collapsed': 'ExpansionTile(' in t('lib/features/session_flow/presentation/live_network_widgets.dart') and "const WaveLabel('Audio Codec')" not in receiver,
 'No translation API connected': 'azure.cognitiveservices' not in t('pubspec.yaml'),
}
for k,v in checks.items():print(('PASS' if v else 'FAIL')+' '+k)
assert all(checks.values()),'V7 source integrity audit failed'
print(f'PASS {len(checks)} V7 source assertions — Android build/real device not checked')
