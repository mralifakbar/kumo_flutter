# KumoTabs

A row of tabs with a moving active indicator, for switching between views of one resource (a Worker's overview, metrics and settings). `KumoTabPanels` adds content pages that swipe with the finger.

Kumo reference: https://kumo-ui.com/components/tabs

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
class WorkerTabs extends StatefulWidget {
  const WorkerTabs({super.key});

  @override
  State<WorkerTabs> createState() => _WorkerTabsState();
}

class _WorkerTabsState extends State<WorkerTabs> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    return KumoTabs(
      tabs: const [
        KumoTab(value: 'overview', label: 'Overview'),
        KumoTab(value: 'metrics', label: 'Metrics'),
        KumoTab(value: 'settings', label: 'Settings'),
      ],
      value: _tab,
      onValueChange: (v) => setState(() => _tab = v),
    );
  }
}
```

## When to use / when not to

Use tabs for sibling views of the same thing, where only one is shown at a time. Use `KumoBreadcrumbs` or a sidebar for moving between different pages, and a radio group or segmented control in a form for choosing a value that gets saved.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `tabs` | `List<KumoTab>` | required | An empty list renders nothing |
| `value` | `String?` | required | Active tab's `value`. Null or unknown shows no indicator |
| `onValueChange` | `ValueChanged<String>?` | required | Next value. Null makes the tabs read-only |
| `variant` | `KumoTabsVariant` | `segmented` | `segmented` (pill on a recessed track) or `underline` (2px brand bar) |
| `size` | `KumoTabsSize` | `base` | `base` 36px track, 14px text; `sm` 26px track, 12px text |
| `activateOnFocus` | `bool` | `false` | Select as arrow keys move focus |
| `pageController` | `PageController?` | | Shared with `KumoTabPanels`; the indicator follows page drags |
| `haptic` | `KumoHaptic?` | selection for segmented, none for underline | Fires on selection change |
| `semanticLabel` | `String?` | | Accessible name of the tab list |
| `scrollStartLabel` | `String?` | `KumoStrings.scrollTabsStart` | Accessible name of the start chevron |
| `scrollEndLabel` | `String?` | `KumoStrings.scrollTabsEnd` | Accessible name of the end chevron |

`KumoTab`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | Identifies the tab |
| `label` | `String` | required | |
| `icon` | `IconData?` | | Leading icon, 16px (14px at `sm`) |
| `disabled` | `bool` | `false` | Dimmed, skipped by arrow keys, cannot be selected |
| `semanticLabel` | `String?` | | |

`KumoTabPanels`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `panels` | `List<KumoTabPanel>` | required | `KumoTabPanel(value:, child:)`, one per tab, same order |
| `value` | `String?` | required | The visible panel; match `KumoTabs.value` |
| `onValueChange` | `ValueChanged<String>?` | required | Called when a swipe lands on another panel |
| `controller` | `PageController?` | created internally | Pass the same controller to `KumoTabs.pageController` |
| `swipeable` | `bool` | `true` | False switches panels only through the tabs |

`KumoTabPanels` is a `PageView`: give it a bounded height (`Expanded` or a `SizedBox`). Offscreen panels are not kept alive; keep their state above the panels or with `AutomaticKeepAliveClientMixin`.

## Examples

### Underline, small

```dart
KumoTabs(
  variant: KumoTabsVariant.underline,
  size: KumoTabsSize.sm,
  tabs: const [
    KumoTab(value: 'logs', label: 'Logs', icon: KumoIcons.listBullets),
    KumoTab(value: 'metrics', label: 'Metrics', icon: KumoIcons.chartBar),
    KumoTab(value: 'traces', label: 'Traces', disabled: true),
  ],
  value: tab,
  onValueChange: (v) => setState(() => tab = v),
)
```

### Many tabs

When the tabs are wider than their parent, the row scrolls: the edges fade (Kumo's scroll-fade, 48px) and the segmented variant shows chevron buttons that page by the width of the visible tabs. The selected tab scrolls into view, clear of the fades. A mouse can drag the row.

### Swipeable panels

```dart
class WorkerSections extends StatefulWidget {
  const WorkerSections({super.key});

  @override
  State<WorkerSections> createState() => _WorkerSectionsState();
}

class _WorkerSectionsState extends State<WorkerSections> {
  final PageController _pages = PageController();
  String _tab = 'overview';

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [
      KumoTab(value: 'overview', label: 'Overview'),
      KumoTab(value: 'logs', label: 'Logs'),
    ];
    return Column(
      children: [
        KumoTabs(tabs: tabs, value: _tab, pageController: _pages, onValueChange: (v) => setState(() => _tab = v)),
        Expanded(
          child: KumoTabPanels(
            controller: _pages,
            value: _tab,
            onValueChange: (v) => setState(() => _tab = v),
            panels: const [
              KumoTabPanel(value: 'overview', child: KumoText('Deployed from main')),
              KumoTabPanel(value: 'logs', child: KumoText('No logs in the last hour')),
            ],
          ),
        ),
      ],
    );
  }
}
```

## Accessibility

The list is a tab bar; each tab has the tab role with its selected state. Focus is roving, like Base UI's tabs: Tab reaches the active tab only, Left and Right move between tabs (wrapping, skipping disabled ones, mirrored in RTL), Home and End jump to the ends, Enter or Space selects. Focus shows Kumo's 2px brand ring (inset on segmented tabs). The overflow chevrons are buttons with their own labels and leave the Tab order while hidden. Panels have the tab panel role.

## Motion

The indicator springs (`KumoSprings.standard`, an unbounded controller driven by `KumoMotion.springTo`) from wherever it is to the new tab, carrying its velocity, so a second tap mid-flight turns it around without a jump; resizes and text scale changes move it without animating. On touch, the segmented pill can be grabbed: it shrinks slightly, follows the finger with rubber-banding past the ends, gives a selection tick as it crosses tabs, and on release the projected fling picks the tab (disabled tabs are skipped). With a `pageController`, the indicator tracks the page 1:1 as it is dragged and springs to the active tab when the page settles; `KumoTabPanels` pages follow the finger and settle with the page physics, and a tab tap slides the pages over 300ms. The overflow chevrons fade in and out in 150ms. Reduced motion moves the indicator instantly and jumps the scroll and the pages.

## Mobile

Tabs stay their visual size (36px or 26px track), but on touch the hit area of every tab is 44px tall. Labels never wrap; a row wider than the screen scrolls with fades instead of overflowing, including at 2x text. Panels swipe with the finger on touch only.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `tabs` | `tabs` (`KumoTab` instead of `TabsItem`) |
| `value` / `onValueChange` | `value` / `onValueChange` |
| `selectedValue` | not ported (controlled only) |
| `variant`, `size` | `variant`, `size` |
| `activateOnFocus` | `activateOnFocus` |
| `labels.scrollStart` / `labels.scrollEnd` | `scrollStartLabel` / `scrollEndLabel` |
| `TabsItem.render` (link tabs) | navigate in `onValueChange` |
| `className`, `listClassName`, `indicatorClassName` | not ported |

Additions over Kumo: `KumoTab.icon`, `KumoTab.disabled`, the draggable pill and `KumoTabPanels`. Underline tabs fill the available width so the hairline spans it; segmented tabs shrink to their content.
