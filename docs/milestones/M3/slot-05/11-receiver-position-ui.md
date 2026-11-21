# Receiver Speaker Position UI

**Source:** `theater_setup_screen.dart`, lines 154–203.

`WaveReceiverPosition` is a `StatelessWidget` containing an `AnimatedBuilder` observing `WaveNative.instance`.

The widget reads the numeric `state['speakerRole']`, falls back to zero when absent, clamps to the `TheaterPositions.names` index range and converts the result to `int`.

When role equals zero, it returns `SizedBox.shrink()` (the card is hidden). Otherwise, a `WaveGlassCard` renders the heading `THEATER SPEAKER POSITION`, the label from `names[role]`, a place icon, the corresponding `hints[role]`, and the caution: `Position assigned — discrete channel audio is not enabled in this build.`

**Boundary:** UI representation of a position does not verify physical placement, role acknowledgement or a separately routed audio channel.