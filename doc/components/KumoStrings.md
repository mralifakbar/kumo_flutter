# KumoStrings

All built-in copy (labels, announcements, month names) in one place, provided by `KumoLocale`.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
const KumoLocale(
  strings: KumoStrings(close: 'Tutup', cancel: 'Batal', optional: '(opsional)', firstDayOfWeek: DateTime.monday),
  child: SizedBox(),
)
```

Read them with `context.kumoStrings`.

## Parameters

Every field has an English default matching Kumo: `optional`, `moreInformation`, `close`, `cancel`, `confirm`, `dismiss`, `loading`, `copy`, `copied`, `copyFailed`, `show`, `hide`, `clear`, `search`, `noResults`, `select`, `selectAll`, `selectRow`, `remove`, `more`, `menu`, `expand`, `collapse`, `increment`, `decrement`, `previous`, `next`, `previousPage`, `nextPage`, `firstPage`, `lastPage`, `previousMonth`, `nextMonth`, `today`, `sortAscending`, `sortDescending`, `openSidebar`, `closeSidebar`, `breadcrumbs`, `pagination`, `notifications`, `required`, `monthNames`, `monthNamesShort`, `weekdayNames`, `weekdayNamesShort` (Monday first), `firstDayOfWeek` (Sunday).

Methods: `pageOf(page, total)`, `removeItem(item)`, `showingRange(from, to, total)`, `monthYear(date)`, `shortDate(date)`, `fullDate(date)`.

## Kumo React mapping

| Kumo | Flutter |
| --- | --- |
| `KumoLocaleProvider translations={...}` | `KumoLocale(strings: KumoStrings(...))` |
| `label.optional`, `layerDialog.close` | `optional`, `close` |
