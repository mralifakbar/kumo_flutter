# KumoBottomNavigation

A tab bar for phone layouts of Kumo apps: three to five destinations, each an icon over a label, pinned to the bottom with room for the home indicator.

Kumo reference: none. Kumo is a dashboard system; this bar uses its tokens for apps that bring Kumo to phones.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoBottomNavigation(
  value: section,
  onValueChange: (v) => setState(() => section = v),
  items: const [
    KumoBottomNavigationItem(value: 'home', label: 'Home', icon: KumoIcons.house, activeIcon: KumoIcons.houseFill),
    KumoBottomNavigationItem(value: 'workers', label: 'Workers', icon: KumoIcons.code, activeIcon: KumoIcons.codeFill),
    KumoBottomNavigationItem(value: 'alerts', label: 'Alerts', icon: KumoIcons.bell, activeIcon: KumoIcons.bellFill, badgeCount: 3),
  ],
  body: const KumoText('Workers'),
)
```

## When to use / when not to

Use it as the top-level navigation of a phone app with three to five sections. On tablets and desktop, use a sidebar instead (switch on `context.kumoIsNarrow`). Do not use it for views of one resource (`KumoTabs`).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoBottomNavigationItem>` | required | 2 to 5 (asserted); 3 to 5 recommended |
| `value` | `String` | required | Active destination |
| `onValueChange` | `ValueChanged<String>?` | required | Also called for the active one, so the app can scroll it to the top |
| `body` | `Widget?` | | Screen content laid out above the bar |
| `safeArea` | `bool` | `true` | Pad for the bottom system inset |
| `semanticLabel` | `String?` | | |

`KumoBottomNavigationItem`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | |
| `label` | `String` | required | One short word |
| `icon` | `IconData` | required | Regular weight, inactive |
| `activeIcon` | `IconData?` | `icon` | Usually the `...Fill` variant |
| `badgeCount` | `int?` | | Unread count on the icon; over 99 shows "99+" |
| `semanticLabel` | `String?` | `label` | |

## Examples

### Content never hides under the bar

With `body`, the bar lays out a `Column`: the body gets the space above the bar and its bottom safe-area padding is removed (the bar already pads for it). Without `body`, place the bar at the bottom of your own `Column` and leave the body in an `Expanded`.

```dart
Column(
  children: [
    const Expanded(child: KumoText('Alerts')),
    KumoBottomNavigation(
      value: 'alerts',
      onValueChange: (v) {},
      items: const [
        KumoBottomNavigationItem(value: 'home', label: 'Home', icon: KumoIcons.house),
        KumoBottomNavigationItem(value: 'alerts', label: 'Alerts', icon: KumoIcons.bell),
        KumoBottomNavigationItem(value: 'account', label: 'Profile', icon: KumoIcons.user),
      ],
    ),
  ],
)
```

## Accessibility

The bar is a tab bar; each destination is a tab with its selected state and its label; an unread count is the value ("3"). Tab and Enter work with a keyboard. The active destination is marked by the fill icon, medium label and a tinted pill, not color alone.

## Motion

Press scales the destination (0.98 spring) and shows an instant tint on an inactive pill. The active pill slides from the previous destination to the new one on a spring (`KumoSprings.standard`) that starts from where it is, so a second tap mid-flight turns it around; each destination paints the part of the pill that crosses it, under its own icon. The fill icon cross-fades in over 150ms. A selection haptic fires when the destination changes. Reduced motion moves the pill and swaps the icon in one frame.

## Mobile

`base` surface with a hairline top border. Each destination fills its share of the width and is at least 56px tall (44px minimum target). At 2x text labels grow; they truncate with an ellipsis rather than wrap.
