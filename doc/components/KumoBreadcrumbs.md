# KumoBreadcrumbs

The trail from the account root to the current page, for dashboards with nested resources (account, zone, DNS, record).

Kumo reference: https://kumo-ui.com/components/breadcrumbs

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoBreadcrumbs(
  items: [
    KumoBreadcrumbsItem(label: 'Account home', icon: KumoIcons.house, onPress: () => Navigator.of(context).popUntil((r) => r.isFirst)),
    KumoBreadcrumbsItem(label: 'example.com', onPress: () => Navigator.of(context).pop()),
  ],
  current: 'DNS records',
)
```

## When to use / when not to

Use breadcrumbs at the top of a page that sits two or more levels deep. Do not use them for steps of a flow (`KumoSteps`) or for switching sibling views (`KumoTabs`).

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoBreadcrumbsItem>` | `const []` | Ancestor pages, root first; not the current page |
| `current` | `String` | required | Title of the current page |
| `currentIcon` | `IconData?` | | |
| `loading` | `bool` | `false` | Placeholder bar in place of `current`, announced as loading |
| `size` | `KumoBreadcrumbsSize` | `base` | `base` 48px row, 14px; `sm` 40px row, 13px |
| `copyText` | `String?` | | Adds a copy button for a deep link (Kumo's `Breadcrumbs.Clipboard`) |
| `narrowLayout` | `KumoBreadcrumbsNarrowLayout` | `back` | What shows below 640px |
| `presentation` | `KumoPresentation` | `auto` | Where the More menu opens: popover, or a sheet below 768px |
| `semanticLabel` | `String?` | `KumoStrings.breadcrumbs` | |

`KumoBreadcrumbsItem(label:, onPress:, icon:, semanticLabel:)`. A null `onPress` shows the crumb as plain text.

`KumoBreadcrumbsNarrowLayout`:

| Value | Below 640px |
| --- | --- |
| `back` | One back link: a caret and the parent's label, announced as "Back, parent" |
| `trail` | Kumo's mobile trail: More menu, parent, current page |
| `full` | The whole trail, collapsing as on wide screens |

## Examples

### Collapsing when tight

On any width, when the trail does not fit, the middle ancestors move into a "More" menu (three dots) after the root: `Account home > ... > Records > api.example.com`. If even that does not fit, only the parent and current page remain. Ancestors never shrink (as in Kumo); the current page truncates with an ellipsis.

### Loading and copy

```dart
KumoBreadcrumbs(
  items: [KumoBreadcrumbsItem(label: 'Workers', onPress: () {})],
  current: 'image-resizer',
  loading: false,
  copyText: 'https://dash.example.com/workers/image-resizer',
)
```

The copy button appears on hover with a mouse and stays visible on touch. After copying it shows a check for 2 seconds.

## Accessibility

The trail is a labelled container ("Breadcrumbs"). Ancestors are links; the current page is plain medium-weight text. Separators are decorative. The More button announces "More" and its expanded state; its menu rows are links and the menu takes focus (arrow keys move, Escape closes and returns focus). Every link has Kumo's focus ring.

## Motion

When the width changes and crumbs move into or out of the More menu, the crumbs (or the More button) that appear fade in over 150ms; opacity only, so the row never lags a window resize, and the first layout shows at once. The copy button fades in on hover (100ms, Kumo's `transition-[opacity]`), and its check lands with a small bounce after a copy. The More menu opens with the popover motion of `KumoAnchoredOverlay`, or as a sheet that follows the finger. Reduced motion is instant.

## Mobile

Below 640px (Kumo's `sm`) the layout follows `narrowLayout`, a back link by default. Below 768px the More menu opens in a bottom sheet. Links have 44px hit areas on touch. At 2x text, a lone crumb or the current page truncates instead of overflowing.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `<Breadcrumbs.Link href>` children | `items: [KumoBreadcrumbsItem(label:, onPress:)]` |
| `Breadcrumbs.Link icon` | `KumoBreadcrumbsItem.icon` |
| `<Breadcrumbs.Current>` | `current` |
| `Breadcrumbs.Current icon` / `loading` | `currentIcon` / `loading` |
| `<Breadcrumbs.Separator />` | drawn automatically between crumbs |
| `<Breadcrumbs.Clipboard text>` | `copyText` |
| `size` | `size` |

Kumo's mobile ellipsis is decorative; here it is a working More menu. The overflow collapse on wide screens and the back-link layout are additions.
