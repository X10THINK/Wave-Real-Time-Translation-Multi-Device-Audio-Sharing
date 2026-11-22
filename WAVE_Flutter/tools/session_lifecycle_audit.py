#!/usr/bin/env python3
"""Offline source checks for reported SESSION_ACTIVE regression; not a device test."""
from pathlib import Path
base=Path(__file__).resolve().parents[1]
main=(base/'android/app/src/main/kotlin/com/x10think/wave/MainActivity.kt').read_text()
bridge=(base/'lib/core/native/wave_native.dart').read_text()
flow=(base/'lib/features/session_flow/flow_coordinator.dart').read_text()
setup=(base/'lib/features/session_flow/presentation/setup_screens.dart').read_text()
controller=(base/'lib/state/wave_controller.dart').read_text()
checks={
 'duplicate native start guarded': '"SESSION_ACTIVE"' in main and 'if (isActive())' in main,
 'active mode recovery': 'private fun activeMode()' in main and 'mode = activeMode()' in main,
 'feature and mode saved': 'putString("feature"' in main and 'putString("mode"' in main,
 'native state returned and refreshed': 'Future<void> refresh()' in bridge and 'await refresh();' in bridge,
 'restart session state rebuilt': 'WaveNative.instance.running' in controller and 'repository.put(WaveSession(' in controller,
 'active room resume': 'resume(context, existing)' in flow,
 'explicit prior session stop confirmation': "'Stop & Start New'" in flow,
 'double tap guard': 'if (starting) return;' in setup and 'onPressed:starting?null:_startOnce' in setup,
}
for name,success in checks.items():
 print(('PASS' if success else 'FAIL')+': '+name)
assert all(checks.values()),'Lifecycle audit failed'
