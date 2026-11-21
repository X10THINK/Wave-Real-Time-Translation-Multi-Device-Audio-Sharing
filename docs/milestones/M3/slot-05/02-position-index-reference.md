# Theater Position Index Reference

## Source
`theater_setup_screen.dart`, lines 8–19, 108–124, 160–175.

| Index | Source label | Meaning |
|---:|---|---|
| 0 | Unassigned | No position |
| 1 | Front Left | Front-left placement |
| 2 | Front Right | Front-right placement |
| 3 | Center | Front-center placement |
| 4 | Surround Left | Behind-left placement |
| 5 | Surround Right | Behind-right placement |
| 6 | Sub / LFE | Low-frequency speaker position label |
| 7 | Rear Left | Far-behind-left placement |
| 8 | Rear Right | Far-behind-right placement |

These identifiers are placement labels, **not verified separate playback channels**.

## Mapping paths
- Host dropdown generates items from `0` to `TheaterPositions.names.length - 1`.
- Host reads `(peer['role'] as num?)?.toInt() ?? 0` as its initial selection.
- Receiver reads `speakerRole`, clamps the index to a valid range, and looks up the matching label and hint.
- Role zero hides the receiver card.

## Review note
The host dropdown does not locally clamp a nonzero invalid role. Investigate upstream validation before asserting resilience for out-of-range peer data.