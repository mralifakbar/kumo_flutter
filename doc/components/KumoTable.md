# KumoTable

Kumo's `Table`: rows of data under a header, with sorting, row selection, pinned columns, lazy rows and a card layout for phones.

Kumo reference: https://kumo-ui.com/components/table

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoTable<String>(
  rows: const ['image-resizer', 'auth-proxy'],
  columns: [
    KumoTableColumn(id: 'name', label: 'Worker', cell: (context, name) => Text(name)),
  ],
)
```

## When to use / when not to

Use a table for records people compare across columns: Workers, DNS records, API tokens. For a short list of resources with one or two facts each, a list of rows or cards reads better. For key and value details of one resource, use a description layout, not a one-row table.

Put the table in a `KumoLayerCard` with `padding: EdgeInsets.zero`, as Kumo's docs do.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `columns` | `List<KumoTableColumn<T>>` | required | Column definitions |
| `rows` | `List<T>` | required | Already sorted and filtered; the table never reorders them |
| `rowId` | `Object Function(T)?` | the row itself | Stable id for selection and keys. Required with `selected` |
| `layout` | `KumoTableLayout` | `table` | `table`, `cards`, or `auto` (cards below 768px) |
| `headerVariant` | `KumoTableHeaderVariant` | `standard` | `compact`: 12px `text-kumo-strong` on `bg-kumo-elevated` |
| `density` | `KumoTableDensity` | `standard` | `compact` rows use 8px vertical padding |
| `striped` | `bool` | `true` | Every other row on `bg-kumo-elevated` (Kumo `even:`) |
| `stickyHeader` | `bool` | `true` | With a bounded height, the header stays above the scrolling rows |
| `sort` | `KumoTableSort?` | | Current sort; drives the header arrow and sort semantics |
| `onSortChange` | `ValueChanged<KumoTableSort>?` | | Called with the next sort when a sortable header is pressed |
| `selected` | `Set<Object>?` | | Selected row ids. Non-null adds the checkbox column |
| `onSelectionChange` | `ValueChanged<Set<Object>>?` | | Called with the new set from row and select-all checkboxes |
| `rowLabel` | `String Function(T)?` | | Names a row for screen readers ("Select image-resizer") |
| `onRowPress` | `ValueChanged<T>?` | | Makes rows pressable |
| `loading` | `bool` | `false` | Shows a loader in place of the rows |
| `error` | `Widget?` | | Shown in place of the rows, usually a `KumoTablePlaceholder` |
| `empty` | `Widget?` | "No results" placeholder | Shown when `rows` is empty |
| `footer` | `Widget?` | | Below the last row, after a `kumo-fill` border |
| `semanticLabel` | `String?` | | Names the table |
| `controller` | `ScrollController?` | | Vertical controller for the lazy rows |

`KumoTableColumn<T>`:

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `id` | `String` | required | Used by `KumoTableSort` |
| `label` | `String` | required | Header text; may be empty for an actions column |
| `cell` | `Widget Function(BuildContext, T)` | required | Builds a cell; text wraps rather than clips |
| `header` | `Widget?` | | Custom header content |
| `width` | `KumoTableColumnWidth` | `.flex(1, 120)` | `.fixed(px)` or `.flex(flex, minWidth)` |
| `align` | `KumoTableAlign?` | `end` if `numeric`, else `start` | |
| `numeric` | `bool` | `false` | End-aligned, tabular figures |
| `sortable` | `bool` | `false` | Header becomes a sort button |
| `pin` | `KumoTableColumnPin?` | | `start` or `end`: stays visible while scrolling sideways |
| `showInCards` | `bool` | `true` | Include in the card layout |

`KumoTablePlaceholder(title:, icon:, description:, action:, iconColor:)` builds empty and error bodies.

## Examples

### Sorting and selection

The table is controlled. Sort `rows` yourself when `onSortChange` fires, and keep the selection in your state.

```dart
class WorkersTable extends StatefulWidget {
  const WorkersTable({super.key, required this.workers});
  final List<(String, int)> workers;

  @override
  State<WorkersTable> createState() => _WorkersTableState();
}

class _WorkersTableState extends State<WorkersTable> {
  KumoTableSort sort = const KumoTableSort('requests', KumoTableSortDirection.descending);
  Set<Object> selected = {};

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.workers]..sort((a, b) {
        final c = sort.columnId == 'name' ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2);
        return sort.direction == KumoTableSortDirection.ascending ? c : -c;
      });
    return KumoLayerCard(
      padding: EdgeInsets.zero,
      child: KumoTable<(String, int)>(
        rows: rows,
        rowId: (w) => w.$1,
        rowLabel: (w) => w.$1,
        columns: [
          KumoTableColumn(id: 'name', label: 'Worker', sortable: true, cell: (context, w) => Text(w.$1)),
          KumoTableColumn(
            id: 'requests',
            label: 'Requests',
            numeric: true,
            sortable: true,
            width: const KumoTableColumnWidth.fixed(120),
            cell: (context, w) => Text('${w.$2}'),
          ),
        ],
        sort: sort,
        onSortChange: (next) => setState(() => sort = next),
        selected: selected,
        onSelectionChange: (ids) => setState(() => selected = ids),
      ),
    );
  }
}
```

### Lazy rows with a sticky header

Give the table a bounded height and only visible rows are built.

```dart
SizedBox(
  height: 400,
  child: KumoTable<int>(
    rows: List.generate(5000, (i) => i),
    columns: [
      KumoTableColumn(id: 'host', label: 'Hostname', cell: (context, i) => Text('host-$i.example.com')),
    ],
  ),
)
```

### Pinned actions column

```dart
KumoTableColumn<String>(
  id: 'actions',
  label: '',
  pin: KumoTableColumnPin.end,
  showInCards: false,
  width: const KumoTableColumnWidth.fixed(56),
  cell: (context, name) => KumoButton(
    icon: KumoIcons.dotsThree,
    shape: KumoButtonShape.square,
    size: KumoButtonSize.sm,
    variant: KumoButtonVariant.ghost,
    semanticLabel: 'Actions for $name',
    onPress: () {},
  ),
)
```

### Empty, loading and error

```dart
KumoTable<String>(
  rows: const [],
  columns: [KumoTableColumn(id: 'name', label: 'Worker', cell: (context, n) => Text(n))],
  empty: KumoTablePlaceholder(
    icon: KumoIcons.cloud,
    title: 'No Workers yet',
    description: 'Deploy a Worker with Wrangler to see it here.',
    action: KumoButton(label: 'Create Worker', onPress: () {}),
  ),
)
```

### Cards on phones

```dart
KumoTable<String>(
  rows: const ['image-resizer', 'auth-proxy'],
  layout: KumoTableLayout.auto,
  columns: [KumoTableColumn(id: 'name', label: 'Worker', cell: (context, n) => Text(n))],
)
```

## Accessibility

- Sortable headers are buttons named by the column label. Their value is the current sort ("Sorted ascending", like `aria-sort`) and their hint is the next action ("Sort descending", from `KumoStrings`).
- Checkboxes announce checked or mixed. The header one is named `KumoStrings.selectAll`; row ones are "Select" plus `rowLabel`, or `KumoStrings.selectRow` without it.
- Pressable rows are buttons named by `rowLabel` and report `selected`. Their cells stay separate nodes, so buttons inside a row are still reachable.
- Status in a cell is never color alone: pair a status color with an icon or text.

## Motion

- Hover and pressed tints change instantly. Rows do not scale on press. Inside a scroll view the pressed tint waits out Flutter's 100ms press timeout so scrolling never flashes rows.
- Selecting a row eases its tint in and out (100ms) and the checkbox mark lands with Kumo's small bounce.
- The sort arrow turns over (200ms) when the direction flips, from wherever it is if pressed again mid-turn; the unsorted caret cross-fades into the arrow.
- After a sort, and when the body switches between loading, error, empty and rows, the new rows fade in (150ms). Rows never animate their layout, so thousands of rows cost nothing extra.
- Reduced motion makes all of this instant.

## Mobile

- Columns never shrink below their `minWidth`; when they do not fit, the table scrolls sideways and the hidden edge fades (24px, Kumo's sticky-column fade), with a thin scrollbar while scrolling. Pinned columns stay at their edge with the same fade on their inner side.
- `layout: KumoTableLayout.auto` switches to cards below 768px: the first visible column is the card title, the others become label and value pairs (each label centered against its value, so a tall cell such as a switch stays level with its label), and a select-all row sits above the cards.
- Touch rows and sortable headers are at least 44px tall; checkbox cells widen to 44px.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `<Table>` + `<Table.Header>` + `<Table.Body>` | `KumoTable(columns:, rows:)` |
| `<Table.Head>` | `KumoTableColumn(label:, header:)` |
| `<Table.Cell>` | `KumoTableColumn.cell` |
| `<Table.Header variant="compact">` | `headerVariant: KumoTableHeaderVariant.compact` |
| `<Table.Header sticky>` | `stickyHeader` (default on) |
| `<Table.Row variant="selected">` | rows whose id is in `selected` |
| `<Table.CheckHead>`, `<Table.CheckCell>` | `selected` + `onSelectionChange` |
| `sticky="left"` / `"right"` | `pin: KumoTableColumnPin.start` / `.end` |
| `layout="fixed"` + `<colgroup>` | `KumoTableColumnWidth.fixed` / `.flex` |
| `<Table.Footer>` | `footer` |
| `<Table.ResizeHandle>` | not ported |
