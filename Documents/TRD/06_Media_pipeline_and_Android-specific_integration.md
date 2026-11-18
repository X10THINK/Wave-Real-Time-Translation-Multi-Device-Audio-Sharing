# Wave TRD — 06 Media pipeline and Android-specific integration

**From:** `05_TRD_Wave_Technical_Requirements_Document_TRD_v1.0.pdf`  
**Pages:** 8  
**Status:** Source working draft; no claim of implemented completion.

## 06 Media pipeline and Android-specific integration

### Audio Share media path

Source (music/video/external capture) -> audio decode/mix as applicable -> encode into transport-appropriate frames -> timestamp/sequence -> authenticated media transport -> receiver jitter buffer/Sync Engine -> decoder -> audio output. Preserve session and media-state identifiers when changing sources.

### Media import / playback

- Local music and movie selectors rely on Android-supported document/media access and content URIs; manage user-granted access rather than assuming raw filesystem access.

- Host movie renders only on Host. Extract/transmit only movie audio to Receivers. Seek, play and pause update the current source timeline and sync epochs.

- On Host movie player exit or lock, pause both video and shared movie audio but keep session/membership active; require explicit Host resume.

- Music should continue in supported background conditions using Android-compliant playback service behavior; verify Doze, audio focus and vendor battery limits.

- Codec choice, sample rate, channels, bitrate and frame size are engineering decisions tied to device/transport tests, not preapproved fixed values.

### External-app playback capture restrictions

Android AudioPlaybackCaptureConfiguration only captures eligible audio usages when the source app/player permits playback capture and required user authorization is obtained. Treat permission denial, source opt-out, stopped projection and silence as distinct states. Use MediaProjection/playback capture only within supported Android APIs, never bypass app capture policy. [A1, A2]

### Foreground and microphone services

Declare Android foreground-service types and permissions appropriate to real use (mediaPlayback, mediaProjection, microphone, connectedDevice as applicable). Android 14+ foreground-service and while-in-use microphone rules restrict launch conditions. Plan consent, notifications, audio focus and cleanup around those OS constraints; do not assume microphone recording can begin or continue silently from background. [A3, A4]

| Android concern | Required test / implementation response |
| --- | --- |
| MediaProjection consent | Request on the applicable source path; show Capturing/Denied/Stopped states. |
| Source opted out | Return Unsupported/No capturable audio; do not retry as if temporarily broken. |
| Foreground service | Visible playback/translation indicators and correct service types across target OS levels. |
| Background execution | Verify screen-off, app switch, Doze, audio focus, OEM killing and process recreation. |
| Output route change | Handle wired/Bluetooth headphone routes, focus and latency recalibration. |
| Transport permissions | Use contextual Bluetooth/nearby/network/system prompts and revalidate after return. |
