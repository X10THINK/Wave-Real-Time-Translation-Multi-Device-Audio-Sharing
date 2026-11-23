# WAVE 6.3.1 — Emergency milestone handoff

This is an **assigned-file package**, NOT a standalone runnable Flutter application. The team lead must first commit the **complete original WAVE ZIP** to `main` as the shared baseline. Then each member checks out the same repository, creates a feature branch, and copies ONLY their assigned files from this package into the matching paths. Do not delete any other repository files.

**Emergency scope:** preserve existing implementation; do not implement the upcoming major update yet. No production readiness claims.

**Strict ownership:** Only edit assigned paths. Shared files require lead approval and coordination. Pull requests only; do not push directly to `main`. Merge conflicts are reduced, not mathematically impossible.

**Important:** Do not commit API keys, `.env`, local secrets, build outputs, or generated files.

## Milestone 5: Translation and Gateway

**Branch:** `milestone/M5-translation-and-gateway`

**Assigned source files (40):**

- `WAVE_Flutter/RUN_TRANSLATION_CHECKS.bat`
- `WAVE_Flutter/RUN_TRANSLATION_CHECKS.sh`
- `WAVE_Flutter/lib/features/translation/engine/adaptive_startup_buffer.dart`
- `WAVE_Flutter/lib/features/translation/engine/gateway_provider.dart`
- `WAVE_Flutter/lib/features/translation/engine/microphone_input.dart`
- `WAVE_Flutter/lib/features/translation/engine/models.dart`
- `WAVE_Flutter/lib/features/translation/engine/session_controller.dart`
- `WAVE_Flutter/lib/features/translation/engine/speech_activity_monitor.dart`
- `WAVE_Flutter/lib/features/translation/engine/translation_provider.dart`
- `WAVE_Flutter/lib/features/translation/engine/voice_output.dart`
- `WAVE_Flutter/lib/features/translation/presentation/translation_screens.dart`
- `WAVE_Flutter/lib/features/translation/translation_configuration.dart`
- `WAVE_Flutter/test/sihan_adaptive_startup_buffer_test.dart`
- `WAVE_Flutter/test/sihan_session_controller_test.dart`
- `WAVE_Flutter/test/sihan_speech_activity_monitor_test.dart`
- `WAVE_Flutter/test/sihan_translation_provider_test.dart`
- `WAVE_Flutter/tools/TranslationCaptionWireTest.kt`
- `WAVE_Flutter/tools/v63_translation_source_audit.py`
- `WAVE_Flutter/translation_gateway/.env.example`
- `WAVE_Flutter/translation_gateway/PROVIDER_DECISION.md`
- `WAVE_Flutter/translation_gateway/README_WAVE.md`
- `WAVE_Flutter/translation_gateway/SIHAN_ORIGINAL_README.md`
- `WAVE_Flutter/translation_gateway/gateway/__init__.py`
- `WAVE_Flutter/translation_gateway/gateway/app.py`
- `WAVE_Flutter/translation_gateway/gateway/audio.py`
- `WAVE_Flutter/translation_gateway/gateway/audio_pacing.py`
- `WAVE_Flutter/translation_gateway/gateway/caption_tts.py`
- `WAVE_Flutter/translation_gateway/gateway/diagnostics.py`
- `WAVE_Flutter/translation_gateway/gateway/protocol.py`
- `WAVE_Flutter/translation_gateway/gateway/realtime_translation.py`
- `WAVE_Flutter/translation_gateway/gateway/requirements.txt`
- `WAVE_Flutter/translation_gateway/gateway/test_audio_pacing.py`
- `WAVE_Flutter/translation_gateway/gateway/test_audio_protocol.py`
- `WAVE_Flutter/translation_gateway/gateway/test_caption_freeze_contract.py`
- `WAVE_Flutter/translation_gateway/gateway/test_caption_state.py`
- `WAVE_Flutter/translation_gateway/gateway/test_caption_tts.py`
- `WAVE_Flutter/translation_gateway/gateway/test_diagnostics.py`
- `WAVE_Flutter/translation_gateway/gateway/test_fast_websocket.py`
- `WAVE_Flutter/translation_gateway/gateway/test_realtime_translation.py`
- `WAVE_Flutter/translation_gateway/requirements.txt`

## Git workflow
1. Lead commits the original complete ZIP contents (inside `WAVE_Flutter/`) to `main`, pushes, and protects `main`.
2. Member clones the repository, checks out updated `main`, then runs `git switch -c milestone/M5-translation-and-gateway`.
3. Copy assigned files to the corresponding paths **only if changed or needed**. For the emergency baseline, the files will already be identical; a no-change PR is not useful. Instead make a small, legitimate module-specific improvement (e.g. tests or documentation) only if authorized, or create a GitHub issue/milestone to record ownership and review.
4. Run relevant tests; commit only owned paths: `git add <explicit assigned paths>` (never blindly `git add .`).
5. `git commit -m "chore(m5): verify assigned module"` and `git push -u origin milestone/M5-translation-and-gateway`.
6. Open a PR targeting `main`, ask the lead to review, and merge only after checks pass.
7. Rebase/merge the latest `main` before further changes; never force-push shared branches without coordination.

## Verification
From the Flutter project root: `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug` (requires compatible Flutter/Android SDK). Translation gateway: `python -m pytest translation_gateway/gateway -q` with Python dependencies installed. Record actual results; do not claim tests passed unless run.
