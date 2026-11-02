# KumoPageHeader

The top of a page: breadcrumbs, a title and description, then segmented tabs with the page's actions.

Kumo reference: https://kumo-ui.com/blocks/page-header

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoPageHeader(
  title: 'image-resizer',
  description: 'Resizes and converts images at the edge.',
  tabs: const [
    KumoPageHeaderTab(label: 'Overview', value: 'overview'),
    KumoPageHeaderTab(label: 'Settings', value: 'settings'),
  ],
  value: tab,
  onValueChange: (v) => setState(() => tab = v),
  actions: [
    KumoButton(label: 'Edit code', icon: KumoIcons.code, size: KumoButtonSize.sm, onPress: () {}),
    KumoButton(label: 'Visit', variant: KumoButtonVariant.primary, size: KumoButtonSize.sm, onPress: () {}),
  ],
)
```

## When to use / when not to

Use one at the top of every resource and settings page. For a section heading inside a page, use `KumoText` with `KumoTextVariant.heading`. For a list page with an aside, `KumoResourceList` already draws its own title.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `breadcrumbs` | `Widget?` | | Breadcrumb trail, drawn above a bottom border |
| `title` | `String?` | | 30px semibold, the level 1 heading |
| `description` | `String?` | | Subtle 14px text, at most about 65 characters wide |
| `tabs` | `List<KumoPageHeaderTab>?` | | `KumoPageHeaderTab(label:, value:)`, drawn as a segmented `KumoTabs` |
| `value` | `String?` | first tab | Selected tab |
| `onValueChange` | `ValueChanged<String>?` | | |
| `actions` | `List<Widget>` | `[]` | At the end of the tab row, or beside the title without tabs |
| `spacing` | `KumoPageHeaderSpacing` | `base` | Gap between sections: `compact` 4, `base` 8, `relaxed` 16 |
| `narrowBreakpoint` | `double` | `640` | Below this width, actions stack under the title or tabs |

## Examples

### Breadcrumbs and title

```dart
KumoPageHeader(
  breadcrumbs: myBreadcrumbs,
  title: 'assets',
  description: 'Object storage for the images and fonts your sites serve.',
)
```

### Title with actions, no tabs

```dart
KumoPageHeader(
  title: 'API tokens',
  actions: [KumoButton(label: 'Create token', variant: KumoButtonVariant.primary, onPress: () {})],
)
```

## Accessibility

- The title is announced as a level 1 heading.
- Tabs are buttons in a mutually exclusive group; the selected one is announced as selected. Left and Right arrows move focus between tabs, Enter and Space select.

## Motion

The tabs are a segmented `KumoTabs`: the indicator springs from wherever it is to the selected tab (a tap mid-flight turns it around), and on touch the pill can be dragged across tabs. Under reduced motion it moves at once. Tab hover color is instant.

## Mobile

Below 640px of width the actions move under the tabs (or under the title) and wrap; the tab strip scrolls sideways. Tabs keep a 44px minimum width on touch.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `breadcrumbs` | `breadcrumbs` (any widget) |
| `title`, `description` | `title`, `description` |
| `tabs: TabsItem[]` | `tabs: List<KumoPageHeaderTab>` |
| `defaultTab` | `value` (controlled) |
| `onValueChange` | `onValueChange` |
| `children` (actions in the tab row) | `actions` |
| `spacing` | `spacing` |
