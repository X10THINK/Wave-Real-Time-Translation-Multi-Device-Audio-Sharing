# Host Speaker-Position Dropdown

Source: `theater_setup_screen.dart`, lines 8–19 and 83–133.

## Initial value
The host reads `final role = (peer['role'] as num?)?.toInt() ?? 0;`. Missing or null role becomes `0` (Unassigned). The host uses `initialValue: role`.

## Items
The widget creates a `DropdownMenuItem<int>` for every index from zero to `TheaterPositions.names.length - 1`, with the text from `TheaterPositions.names[i]`. Current source defines nine names.

## Identity and UI
The key is `ValueKey((id, role))`, a record that reflects current peer ID and role. It can cause Flutter to replace a field when its peer ID or role changes.

## On selection
A null value is ignored. When not pending, the selected index is passed to `assign(id, v)`. The source does not directly mutate `peer['role']` in the dropdown callback.

## Validation caveat
Unlike receiver display, the host dropdown does not clamp its `initialValue` to the valid nine-index range in this file. Upstream values should be reviewed before claiming complete input validation.