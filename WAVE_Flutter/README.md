# Wave 6.3 — Sihan Translation Integration (source-only)

**Latest input base is Wave 6.2.0; Sihan Member 3 Tamil/English MIC-only translation module has been selectively merged.** This source is an *integration candidate*, not a compiled or device-verified Android production release. The installed Android app label remains **Wave**, brand **ZAEROX**.

**Start here:** [Full integration and verification report](docs/V6_3_SIHAN_TRANSLATION_INTEGRATION.md).

Audio Share and Theater sources remain intact. WAVE maintains Home → feature → method → Host/Receiver → session entry, Sessions Hub, and existing native room transport. The old Translation original-audio-only placeholder UI is replaced with Sihan's real provider/controller gateway flow, themed to WAVE, with encrypted text caption distribution for LAN/Hotspot and direct Bluetooth, and receiver-local TTS. **Translation requires an external running gateway and valid paid API credentials**, not included in this ZIP.

**Product release blockers**: Flutter/Android compile verification; on-device tests; all-translation-participant authentication and paid entitlement, proper per-language distribution, generated voice streaming to receivers, production background MIC behavior, audio/network route recovery and production privacy/security.

Run `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --debug` on a development PC with Dart >=3.12. Python backend: `cd translation_gateway && python -m pytest gateway -q` (54 passed in this workspace). Local Kotlin protocol tests: see `tools/TranslationCaptionWireTest.kt`. See original Wave 6.2.0 ZIP for the pre-merge README and lockfile.
