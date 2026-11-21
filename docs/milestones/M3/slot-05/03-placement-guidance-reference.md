# Theater Placement Guidance — Source Reference

Source: `WAVE_Flutter/lib/features/audio/presentation/theater_setup_screen.dart`, lines 8–30 and 154–203. This is a review of existing code, not a test report.

## Placement hints by role

| Role | Label | Source hint |
|---:|---|---|
| 0 | Unassigned | Awaiting Host assignment |
| 1 | Front Left | Place at front-left of viewer |
| 2 | Front Right | Place at front-right of viewer |
| 3 | Center | Place in front, center of viewer |
| 4 | Surround Left | Place behind-left of viewer |
| 5 | Surround Right | Place behind-right of viewer |
| 6 | Sub / LFE | Place near center/front; phone speakers have limited low bass |
| 7 | Rear Left | Place far behind-left of viewer |
| 8 | Rear Right | Place far behind-right of viewer |

## Receiver presentation

`WaveReceiverPosition` reads `speakerRole` from `WaveNative.instance.state`, clamps it to the valid array bounds, hides the card when the role is zero, and otherwise displays the selected name and hint.

## Do not overclaim

These are placement labels and qualitative hints, not precisely measured coordinates, a calibrated speaker array, or separate rendered surround audio channels. The screen explicitly warns that discrete channel audio is not enabled in the current build. The `Sub / LFE` label does not make ordinary phone speakers reproduce low bass accurately.

## Maintenance check

Review both `names` and `hints` together whenever changing a position index, since both arrays must stay aligned.