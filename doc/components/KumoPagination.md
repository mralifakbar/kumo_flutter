# KumoPagination

Page navigation under a table or list: "Showing 1-25 of 500" on one side, joined first, previous, page number, next and last buttons on the other.

Kumo reference: https://kumo-ui.com/components/pagination

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoPagination(
  page: page,
  onPageChange: (p) => setState(() => page = p),
  perPage: 25,
  totalCount: 500,
)
```

## When to use / when not to

Use it for server-paged data where people jump between pages. For feeds that only grow, load more on scroll instead.

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `page` | `int` | required | Current page, 1-based |
| `onPageChange` | `ValueChanged<int>?` | required | Next page. Null disables every control |
| `perPage` | `int?` | | Items per page |
| `totalCount` | `int?` | | Total items. Null when unknown |
| `hasNextPage` | `bool?` | | With an unknown total: whether another page exists |
| `controls` | `KumoPaginationControls` | `full` | `full` or `simple` (previous and next only) |
| `pageSelector` | `KumoPaginationPageSelector` | `input` | `input` (typed, 50px) or `dropdown` (menu of every page) |
| `perPageOptions` | `List<int>?` | `[25, 50, 100, 250]` | |
| `onPerPageChange` | `ValueChanged<int>?` | | Shows the "Per page" select (with `perPage`) |
| `showInfo` | `bool` | `true` | |
| `infoBuilder` | `KumoPaginationInfoBuilder?` | | Replaces the info text; gets `KumoPaginationInfo` (`page`, `maxPage`, `perPage`, `totalCount`, `from`, `to`) |
| `compact` | `bool?` | narrow window | Drops first and last, puts the page size under the controls |
| `presentation` | `KumoPresentation` | `auto` | Where the page size and page menus open |
| `perPageLabel` | `String?` | `KumoStrings.perPage` | |
| `pageNumberLabel` | `String?` | `KumoStrings.pageNumber` | Accessible name of the page field or menu |
| `pageSizeLabel` | `String?` | `KumoStrings.pageSize` | Accessible name of the page size select |

The info text comes from `KumoStrings.showingRange` and the button names from `KumoStrings.firstPage`, `previousPage`, `nextPage`, `lastPage` and `pagination`, so `KumoLocale` translates them.

## Examples

### Page size

```dart
KumoPagination(
  page: page,
  onPageChange: (p) => setState(() => page = p),
  perPage: perPage,
  totalCount: 500,
  onPerPageChange: (v) => setState(() {
    perPage = v;
    page = 1;
  }),
)
```

### Unknown total

```dart
KumoPagination(
  page: page,
  onPageChange: (p) => setState(() => page = p),
  hasNextPage: cursor != null,
  infoBuilder: (context, info) => KumoText('Page ${info.page}', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
)
```

Only previous and next show; next is enabled while `hasNextPage` is true.

### Empty, loading and error

The table owns those states. With `totalCount: 0` pagination shows one empty page, no info text and disabled buttons. While a page loads, keep the old `page` until data arrives, or pass `onPageChange: null` to disable the controls.

## Accessibility

The button group is a labelled container ("Pagination"); each icon button has its name and enabled state. The page field accepts digits only, commits on Enter or when it loses focus, clamps to the last page and restores the current page for empty or invalid input. The info text is a live region, so screen readers hear the new range. Selects announce their name and value.

## Motion

The "Showing 1-25 of 500" range cross-fades in 150ms when the page or page size changes; the outgoing text is hidden from screen readers and the live region announces the new one. Kumo's pagination has no page list, so there is no highlight to move: the page number field updates in place. The page size picker is a `KumoSelect` and the `dropdown` page selector a menu joined to the buttons; both open with the popover motion on wide screens and as a bottom sheet that follows the finger on narrow ones. Reduced motion swaps the range text in one frame.

## Mobile

Below 768px the compact layout keeps previous, the page field and next (about 150px) beside the info text, and moves the page size select under them, so it fits at 390px with 2x text. On touch, every button is 44x44. Chevrons mirror in RTL.

## Kumo React mapping

| Kumo prop | Flutter parameter |
| --- | --- |
| `page` / `setPage` | `page` / `onPageChange` |
| `perPage`, `totalCount`, `hasNextPage` | same names |
| `controls` | `controls` |
| `Pagination.Controls pageSelector` | `pageSelector` |
| `Pagination.PageSize value / onChange / options / label` | `perPage` / `onPerPageChange` / `perPageOptions` / `perPageLabel` |
| `Pagination.Info children`, legacy `text` | `infoBuilder` |
| `labels.pageNumber`, `labels.pageSize` | `pageNumberLabel`, `pageSizeLabel` |
| other `labels` | `KumoStrings` |
| `Pagination.Separator` | drawn between the info and the page size |

The compound layout is fixed (info, separator, page size, controls); `compact` is an addition for phones.
