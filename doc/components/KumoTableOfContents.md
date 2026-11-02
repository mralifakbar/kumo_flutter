# KumoTableOfContents

"On this page" navigation beside a long page: section links with a brand rule on the active one, which follows the scroll position. It combines Kumo's `TableOfContents` with its `useTableOfContentsActiveId` hook.

Kumo reference: https://kumo-ui.com/components/table-of-contents

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
class WorkerSettingsPage extends StatefulWidget {
  const WorkerSettingsPage({super.key});

  @override
  State<WorkerSettingsPage> createState() => _WorkerSettingsPageState();
}

class _WorkerSettingsPageState extends State<WorkerSettingsPage> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _anchors = {'routes': GlobalKey(), 'bindings': GlobalKey()};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 200,
          child: KumoTableOfContents(
            title: 'On this page',
            scrollController: _scroll,
            anchors: _anchors,
            items: const [
              KumoTableOfContentsItem(id: 'routes', label: 'Routes'),
              KumoTableOfContentsItem(id: 'bindings', label: 'Bindings'),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KumoText('Routes', key: _anchors['routes'], variant: KumoTextVariant.heading),
                const SizedBox(height: 800),
                KumoText('Bindings', key: _anchors['bindings'], variant: KumoTextVariant.heading),
                const SizedBox(height: 800),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

## When to use / when not to

Use it on long settings or documentation pages with four or more sections. Short pages do not need it; for switching between views use `KumoTabs`.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `items` | `List<KumoTableOfContentsItem>` | required | Sections in page order |
| `title` | `String?` | | Small uppercase heading above the list |
| `scrollController` | `ScrollController?` | | The page's scroll view; enables tracking and tap-to-scroll |
| `anchors` | `Map<String, GlobalKey>` | `const {}` | A key on each section heading, by item id |
| `offset` | `double` | `0` | Activation line below the top (a sticky header's height); taps scroll the heading to it |
| `activeId` | `String?` | | Forces the highlighted item |
| `onActiveIdChange` | `ValueChanged<String>?` | | Tracking moved to another section |
| `onSelect` | `ValueChanged<String>?` | | An item was tapped |
| `semanticLabel` | `String?` | `KumoStrings.tableOfContents` | |

`KumoTableOfContentsItem(id:, label:, children:, selectable:)`. An item with `children` is Kumo's `TableOfContents.Group`: the label heads an indented list. `selectable: false` makes a group label a plain title.

## Examples

### Driven by the app

```dart
KumoTableOfContents(
  activeId: section,
  onSelect: (id) => setState(() => section = id),
  items: const [
    KumoTableOfContentsItem(id: 'intro', label: 'Introduction'),
    KumoTableOfContentsItem(id: 'api', label: 'API reference', selectable: false, children: [
      KumoTableOfContentsItem(id: 'fetch', label: 'fetch handler'),
    ]),
  ],
)
```

## How tracking works

On each scroll, the active section is the first heading (in item order) that is inside the viewport below `offset`, the same rule as Kumo's IntersectionObserver hook. Inside a long section with no heading in view, the last active one stays. A tap selects the section at once, scrolls its heading to the activation line (300ms, standard curve) and pins it until scrolling has been quiet for 150ms, so a short last section stays highlighted even though it cannot reach the top. Headings in lazy lists that are not built yet are skipped.

## Accessibility

The list is a labelled container; the title is a header. Items are links with a selected state on the active one, reachable with Tab and activated with Enter. The active item is marked by a brand rule and medium weight, not color alone.

## Motion

Tapping scrolls with a 300ms animation that the user can interrupt by touching the page. The active item's brand rule is one indicator that springs along the rail from the previous item (`KumoSprings.standard`, continuing from where it is when the active section changes again mid-flight), so it follows the reading position as the page scrolls. Layout changes move it without animating. Hover rules change instantly. Reduced motion jumps the scroll and the rule.

## Mobile

On touch, rows are 44px tall and the 8px gaps between them drop. On phones, place it at the top of the page or in a sheet rather than beside the content.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `<TableOfContents aria-label>` | `semanticLabel` |
| `<TableOfContents.Title>` | `title` |
| `<TableOfContents.Item href active onClick>` | `KumoTableOfContentsItem(id:, label:)`, `activeId`, `onSelect` |
| `<TableOfContents.Group label href>` | item with `children` (`selectable: false` without `href`) |
| `useTableOfContentsActiveId({ ids, offset, root })` | `anchors`, `offset`, `scrollController` |
| `selectSection(id)` | tapping an item |
| `trackHash` | not ported (no URL hash) |

Deviation: the title keeps Kumo's uppercase but not its `tracking-wide`, following the package rule against changing letter spacing.
