# Assignment Feedback and Errors

**Source:** `theater_setup_screen.dart`, lines 41–52.

After `await WaveNative.instance.assignSpeaker(id, role)`, the UI displays `Placement sent; receiver confirmation pending`. This is a sent-request message, **not proof of receiver acceptance**.

If an exception occurs, `catch (e)` displays `Could not assign speaker: $e`. Both toasts are conditional on `mounted`. The `finally` block removes the peer ID from the pending set when mounted.

**What is not provided by this screen:** an explicit acknowledgement event, delivery timeout, retry button, selected-dropdown rollback or evidence of actual multichannel playback.

**Review item:** Investigate whether exception text can reveal transport-specific information and how native assignment acknowledgement should be surfaced. No app source has been changed.