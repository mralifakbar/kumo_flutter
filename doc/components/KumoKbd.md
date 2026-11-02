# KumoKbd

Keyboard key chips: one key ("K") or a shortcut ("⌘ K" on a Mac, "Ctrl K" elsewhere), named the way each platform names it.

Kumo reference: none. Kumo has no keyboard key component; the chip uses Kumo tokens (12px medium `textSubtle` on `base`, `line` ring, `shadow-xs`).

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoKbd('K', modifiers: [KumoKbdModifier.mod])
```

## When to use / when not to

Use it to show a shortcut next to a menu item, in a tooltip or in a help panel. Show only shortcuts that work: build the chip from the same `SingleActivator` that handles the key with `KumoKbd.fromActivator`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `keyLabel` | `String` (positional) | required | A character (`'K'`, `'/'`) or a `KumoKbdKeys` name |
| `modifiers` | `List<KumoKbdModifier>` | `[]` | Held keys, shown first |
| `platform` | `TargetPlatform?` | `defaultTargetPlatform` | Which platform's names to use |
| `semanticLabel` | `String?` | | Replaces the spelled-out names |

`KumoKbdModifier`: `mod` (Command on macOS and iOS, Ctrl elsewhere), `control`, `alt` (Option on Apple platforms), `shift`, `meta` (Command on Apple platforms, Win on Windows, Super elsewhere).

`KumoKbdKeys`: `enter`, `escape`, `tab`, `space`, `backspace`, `delete`, `arrowUp`, `arrowDown`, `arrowLeft`, `arrowRight`. Arrows draw as glyphs everywhere; Return and Backspace draw as glyphs on Apple platforms.

## Examples

### From a SingleActivator

```dart
KumoKbd.fromActivator(const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true))
```

### In a menu row

```dart
const Row(children: [
  Expanded(child: KumoText('Open command palette')),
  KumoKbd('K', modifiers: [KumoKbdModifier.mod]),
])
```

## Accessibility

The chips are one node read with full names: "Command Shift P", "Ctrl K", "Up arrow", "Escape". On Apple platforms modifiers follow the macOS menu order (Control, Option, Shift, Command) whatever order they are passed in; `mod` and `meta` together show one Command key.

## Motion

None.

## Mobile

Chips have a 20px minimum size and grow with the text. Long combinations wrap.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| (no Kumo component) | |
| shadcn `KeyboardDisplay(keys)` | `KumoKbd(key, modifiers:)` / `KumoKbd.fromActivator` |
