# Native-Driven UI Rebuilds

**Source:** `theater_setup_screen.dart`, lines 54–75 and 154–164.

On the Host screen, `AnimatedBuilder(animation: native, builder: ...)` watches `WaveNative.instance` and re-reads `native.peers` when the listenable notifies. On the Receiver screen, another `AnimatedBuilder` watches the same facade and re-reads `state['speakerRole']`.

`AnimatedBuilder` is being used as a `Listenable` rebuild helper here. There is no animation controller or animated theater-position timeline in this source.

**Separate local state:** `setState` updates the Host's pending ID set. Native peer-role updates and pending-state updates are different responsibilities.

**Not established from this file:** event notification frequency, native listener implementation, message reliability or device-level audio synchronization. This document is source review only.