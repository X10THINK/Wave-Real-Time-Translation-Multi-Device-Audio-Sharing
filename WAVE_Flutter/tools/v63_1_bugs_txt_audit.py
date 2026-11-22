#!/usr/bin/env python3
"""WAVE 6.3.1: deterministic source checks, not Flutter/Android compilation."""
from pathlib import Path
r=Path(__file__).resolve().parents[1]
def t(p): return (r/p).read_text()
service=t('android/app/src/main/kotlin/com/x10think/wave/WaveMediaService.kt')
lan=t('android/app/src/main/kotlin/com/x10think/wave/LanEngine.kt')
mesh=t('android/app/src/main/kotlin/com/x10think/wave/MeshEngine.kt')
main=t('android/app/src/main/kotlin/com/x10think/wave/MainActivity.kt')
ui=t('lib/features/media/presentation/wave_media_screen.dart')
host=t('lib/features/audio/presentation/audio_live_screens.dart')
bridge=t('lib/core/native/wave_native.dart')
network=t('lib/features/session_flow/presentation/live_network_widgets.dart')
checks={
  'Only one active Media3 surface; switchTargetView on fullscreen route': 'PlayerView.switchTargetView(active,previous,view)' in service and 'PlayerView.switchTargetView(active,view,previous)' in service,
  'No ExoPlayer double view rebind': 'views.forEach { it.get()?.player = player }' not in service,
  'Encrypted LAN audio fanout sealed once per unique frame': 'val sealed=crypto?.seal(bytes) ?: return' in lan and 'sendEncrypted(sealed,client.address)' in lan,
  'Room commands remain encrypted': 'val message = if (publicAnn) bytes else (crypto?.seal(bytes) ?: return)' in lan,
  'Host global playback command native method and Dart bridge': '"roomPlayback" ->' in main and "'roomPlayback'," in bridge,
  'Host pause and resume source-aware': 'Host Playback Controls' in host and "native.captureSource == 'internalMedia'" in host and "native.captureSource == 'deviceAudio'" in host,
  'Host participant individual controls still present': 'ParticipantControlsSheet(sessionId:' in t('lib/features/session_flow/flow_coordinator.dart') and "send(id, 'PAUSE', 100)" in network,
  'Improved movie fullscreen and seeking': 'class _FullScreenWaveVideoState' in ui and 'AnimatedOpacity(' in ui and 'onChangeEnd:' in ui and 'media.seek(' in ui and 'Icons.aspect_ratio_rounded' in ui,
  'Receiver never receives video surface': "const AndroidView(viewType: 'wave/native_video')" in ui and 'WaveMediaScreen(movie: true)' in host,
  'BT/Wi-Fi coexistence advice only under observed glitch': 'wifiRadioOn' in mesh and 'state[\'wifiRadioOn\'] == true' in network and "state['underruns']" in network,
  'Existing live translation implementation retained': 'Sihan' in t('docs/V6_3_SIHAN_TRANSLATION_INTEGRATION.md') and (r/'lib/features/translation/engine/session_controller.dart').exists(),
}
for label,ok in checks.items():print(f'{"PASS" if ok else "FAIL"} {label}')
assert all(checks.values()), 'Source integration checks failed'
print(f'PASS {len(checks)}/{len(checks)} WAVE 6.3.1 SOURCE assertions (not an APK build)')
