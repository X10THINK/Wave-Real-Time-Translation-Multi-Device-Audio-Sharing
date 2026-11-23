"""Source invariant smoke test only — NOT a Dart/Kotlin compile or device test."""
from pathlib import Path
r = Path(__file__).resolve().parents[1]
read=lambda path:(r/path).read_text(encoding='utf-8')
host=read('lib/features/translation/presentation/translation_screens.dart')
config=read('lib/features/translation/translation_configuration.dart')
native=read('lib/core/native/wave_native.dart')
main=read('android/app/src/main/kotlin/com/x10think/wave/MainActivity.kt')
lan=read('android/app/src/main/kotlin/com/x10think/wave/LanEngine.kt')
mesh=read('android/app/src/main/kotlin/com/x10think/wave/MeshEngine.kt')
mp=read('android/app/src/main/kotlin/com/x10think/wave/MeshProtocol.kt')
checks={
 'base Wave navigation preserved': 'LiveTranslationHostScreen(' in read('lib/features/session_flow/flow_coordinator.dart') and 'LiveTranslationReceiverScreen(' in read('lib/features/session_flow/flow_coordinator.dart'),
 'Sihan engine files integrated': all((r/f'lib/features/translation/engine/{f}.dart').exists() for f in ('models','session_controller','gateway_provider','microphone_input','voice_output')),
 'Sihan server copied': (r/'translation_gateway/gateway/app.py').exists(),
 'no stand-alone MaterialApp or separate main copied': 'MaterialApp(' not in host,
 'translation Host uses Sihan controller': 'TranslationSessionController(' in host and 'RecordMicrophoneInput()' in host,
 'explicit Host gateway microphone consent': 'setCloudConsentGiven' in host,
 'no mock-to-receiver relay': 'if (segment.isMock) return;' in host,
 'host native mic not double-enabled': 'WaveNative.instance.mic(' not in host,
 'native bridge has role/feature guard': "currentFeature != 'translation'" in native and 'translationCaption' in main,
 'LAN translation control fragments': '"TCAP" ->' in lan and 'TranslationCaptionWire.split(text)' in lan,
 'LAN verifies upstream and origin': 'sender!=parent || senderId!=parentId' in lan and 'origin!=hostId' in lan,
 'Bluetooth verifies remote Host': 'MeshProtocol.TRANSLATION_CAPTION -> if(verified.get() && !host && remoteHost)' in mesh,
 'Bluetooth does not evict audio for caption': 'if(packet.kind==MeshProtocol.TRANSLATION_CAPTION)' in mesh,
 'protocol kind assigned': 'const val TRANSLATION_CAPTION = 9' in mp,
 'translation receiver TTS optional': 'FlutterTts' in host and 'Speak translated captions' in host,
 'production key stays on gateway': 'OPENAI_API_KEY' in read('translation_gateway/gateway/app.py') and 'OPENAI_API_KEY' not in config,
 'release cleartext traffic disabled': 'android:usesCleartextTraffic="false"' in read('android/app/src/main/AndroidManifest.xml'),
 'SDK reconciled': ">=3.12.0" in read('pubspec.yaml'),
 'installed label Wave': 'android:label="Wave"' in read('android/app/src/main/AndroidManifest.xml'),
 'Audio Share untouched': (r/'lib/features/audio/presentation/audio_live_screens.dart').exists(),
}
for name, ok in checks.items(): print(('PASS' if ok else 'FAIL') + ' ' + name)
assert all(checks.values())
