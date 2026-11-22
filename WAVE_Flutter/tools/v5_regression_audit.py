#!/usr/bin/env python3
"""V5 source integration assertions. These DO NOT compile the Android app or test phones."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def src(path):
    p=root/path;assert p.exists(),f'Missing {path}';return p.read_text(encoding='utf-8')
k='android/app/src/main/kotlin/com/x10think/wave/'
media=src(k+'WaveMediaService.kt')
bridge=src(k+'MediaPcmBridge.kt')
lan=src(k+'LanEngine.kt')
mesh=src(k+'MeshEngine.kt')
main=src(k+'MainActivity.kt')
pipeline=src(k+'AudioPipeline.kt')
ui=src('lib/features/media/presentation/wave_media_screen.dart')
network=src('lib/features/session_flow/presentation/live_network_widgets.dart')
translate=src('lib/features/translation/presentation/translation_screens.dart')
checks={
  'Media3 directly tees decoded PCM, not Android screen projection':
      'TeeAudioProcessor' in media and 'WaveInternalMediaTap.takeBuffer' in media,
  'PCM source format resampling 16k / 20ms maintained across buffers':
      'nextOutputIndex' in bridge and 'MeshProtocol.FRAME_BYTES' in bridge,
  'Network host activates imported media automatically':
      '"mediaOpen"' in main and 'mesh.setInternalMedia(true)' in main and 'lan.setInternalMedia(true)' in main,
  'Host media does not request MediaProjection permission':
      'Audio shares automatically while playing' in ui and 'captureDeviceAudio()' not in ui and 'Enable Imported' not in ui,
  'External app capture still consented':
      'createScreenCaptureIntent()' in main and 'captureDeviceAudio' in main,
  'Direct media available on Bluetooth and LAN':
      'fun setInternalMedia(enabled: Boolean)' in lan and 'fun setInternalMedia(enabled: Boolean)' in mesh,
  'Sender uplink bounded queue / worker':
      all('LinkedBlockingDeque<QueuedPcm>(8)' in t and 'startUplinkWorker()' in t for t in (lan,mesh)),
  'Original capture timestamp retained across queued send':
      'capturedNs,targetDelayMs' in lan and 'capturedNs, targetDelayMs' in mesh,
  'LAN delay feedback uses cumulative counters':
      'QualitySample' in lan and 'totalGlitches' in lan and '(targetDelayMs-10)' in lan,
  'Bluetooth stale frames cannot be sent indefinitely':
      'queued.enqueuedMs>280L' in mesh and 'RelayLinkPolicy.shouldClose(' in mesh,
  'Media video supports Fit Fill Zoom Fullscreen':
      'setFitMode' in media and '_FullScreenWaveVideo' in ui and '_fitVideo' in ui,
  'No rapid seeks on every slider tick':
      'onChangeEnd:' in ui and '_dragPositionMs' in ui,
  'Audio status counters shown in UI':
      'senderDrops' in network and 'mediaPcmFrames' in network,
  'Host video only; receiver audio only':
      'Others hear only its audio' in ui and 'AndroidView' in ui,
  'No translation API or fake translated output':
      'API is intentionally not configured' in translate and 'azure.cognitiveservices' not in src('pubspec.yaml').lower(),
}
for k,v in checks.items():print(('PASS' if v else 'FAIL')+' '+k)
assert all(checks.values()),'V5 source regression checks failed'
print(f'PASS {len(checks)} V5 SOURCE assertions (no APK compilation or device measurement)')
