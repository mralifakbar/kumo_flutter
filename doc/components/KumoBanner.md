# KumoBanner

A full-width inline message for information, warnings and errors that belong to a page or a section, with optional accent-tinted actions.

Kumo reference: https://kumo-ui.com/components/banner

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
import 'package:kumo_flutter/kumo_flutter.dart';

const updateBanner = KumoBanner(
  icon: KumoIcons.infoFill,
  title: 'Update available',
  description: 'Wrangler 4.2 is ready to install.',
);
```

## When to use / when not to

- Use for messages tied to what is on screen: an expiring certificate on a zone page, a failed save above a form, a read-only notice in a dialog.
- Use `KumoToast` for transient outcomes of an action, and `KumoDialog` when the user must decide before going on.
- With `onDismiss`, the X collapses the banner and then calls `onDismiss`; the parent removes it (or sets `open: false`).

## Parameters

### KumoBanner

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `title` | `String?` | `null` | The message, medium weight. |
| `description` | `String?` | `null` | Supporting text, 13px. |
| `child` | `Widget?` | `null` | Custom description content in place of `description`; inherits the banner text color. |
| `icon` | `IconData?` | `null` | Leading icon in the accent color, the size of the text. Kumo pairs banners with filled icons. |
| `actions` | `List<Widget>` | `const []` | Usually `KumoBannerAction`s. Beside the text when the banner is 360px or wider, under it otherwise. |
| `variant` | `KumoBannerVariant` | `info` | `info` (blue), `alert` (amber), `error` (red), `secondary` (neutral). |
| `size` | `KumoBannerSize` | `base` | `sm`: compact, title and description share a line, 13px text, extra-small actions. |
| `onDismiss` | `VoidCallback?` | `null` | Adds a ghost X action. Runs after the banner has collapsed. |
| `open` | `bool` | `true` | Shown while true. Changes expand or collapse the banner; mounting with `true` shows it at rest. |
| `dismissLabel` | `String?` | `KumoStrings.dismiss` | Accessible name of the X. |

At least one of `title`, `description` or `child` is required.

### KumoBannerAction

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `label` | `String?` | `null` | Null makes an icon-only square action. |
| `icon` | `IconData?` | `null` | |
| `onPress` | `VoidCallback?` | required | Null disables it. |
| `variant` | `KumoBannerActionVariant` | `primary` | `primary`: accent gradient. `secondary`: accent outline. `ghost`: text only with a faint accent hover. |
| `semanticLabel` | `String?` | `null` | Required for icon-only actions. |
| `loading` | `bool` | `false` | Shows a spinner and blocks presses. |
| `disabled` | `bool` | `false` | |

Actions are 26px tall in a base banner and 20px in a compact one; on touch their hit area is padded to 44x44.

## Examples

### Actions and dismiss

```dart
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

Widget paymentBanner({required VoidCallback retry, required VoidCallback openBilling, required VoidCallback hide}) {
  return KumoBanner(
    variant: KumoBannerVariant.error,
    icon: KumoIcons.warningCircleFill,
    title: 'Payment failed',
    description: 'Update your card to avoid interruption.',
    actions: [
      KumoBannerAction(label: 'Retry', onPress: retry),
      KumoBannerAction(label: 'Go to billing', variant: KumoBannerActionVariant.secondary, onPress: openBilling),
    ],
    onDismiss: hide,
  );
}
```

### Compact, inside a dialog

```dart
import 'package:kumo_flutter/kumo_flutter.dart';

const readOnlyNotice = KumoBanner(
  size: KumoBannerSize.sm,
  icon: KumoIcons.infoFill,
  title: 'Read only.',
  description: 'Ask an admin for edit access.',
);
```

## Accessibility

- The title carries the message, so status never rests on color alone; add an icon for a second cue.
- Error banners are live regions, so they are announced when they appear.
- The dismiss X is announced with `KumoStrings.dismiss`. Text colors come from Kumo's text tokens on their tints.

## Motion

- Pressing the X collapses the banner from its bottom edge (200ms, height and opacity, content clipped at its size) so the content below slides up into its place; `onDismiss` runs when it is gone.
- Driving `open` expands or collapses it the same way, reversing from its current height if it flips mid-flight. The banner ignores taps while moving.
- Hover backgrounds on actions switch instantly; presses scale to 0.98 through `KumoPressable`.
- Reduced motion shows and hides it at once.

## Mobile

Below 360px of banner width the actions move under the text and wrap. Text scales with the platform setting; the icon stays aligned with the first line.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `variant="default"` | `KumoBannerVariant.info` |
| `variant="alert"` / `"error"` / `"secondary"` | `KumoBannerVariant.alert` / `.error` / `.secondary` |
| `size="base"` / `"sm"` | `KumoBannerSize.base` / `.sm` |
| `icon={<Info weight="fill" />}` | `icon: KumoIcons.infoFill` |
| `title` / `description` | `title:` / `description:` (or `child:` for custom content) |
| `action={<>...</>}` | `actions: [...]` |
| `Banner.Action variant` | `KumoBannerAction(variant:)` |
| `<Banner.Action variant="ghost" icon={<X />} aria-label="Dismiss" />` | `onDismiss:` |
| `children` / `text` (deprecated) | `child:` / `description:` |
