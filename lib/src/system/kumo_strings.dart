import 'package:flutter/widgets.dart';

/// Every piece of built-in copy Kumo components show or announce. Override
/// any of it for another language or a product voice with [KumoLocale].
///
/// ```dart
/// KumoLocale(
///   strings: const KumoStrings(close: 'Tutup', cancel: 'Batal', optional: '(opsional)'),
///   child: app,
/// )
/// ```
@immutable
class KumoStrings {
  const KumoStrings({
    this.optional = '(optional)',
    this.moreInformation = 'More information',
    this.close = 'Close',
    this.cancel = 'Cancel',
    this.confirm = 'Confirm',
    this.dismiss = 'Dismiss',
    this.loading = 'Loading',
    this.copy = 'Copy',
    this.copied = 'Copied',
    this.copyFailed = 'Could not copy',
    this.show = 'Show',
    this.clickToReveal = 'Click to reveal',
    this.tapToReveal = 'Tap to reveal',
    this.valueHidden = 'Value hidden',
    this.hide = 'Hide',
    this.clear = 'Clear',
    this.search = 'Search',
    this.noResults = 'No results',
    this.select = 'Select',
    this.selectAll = 'Select all',
    this.selectRow = 'Select row',
    this.remove = 'Remove',
    this.more = 'More',
    this.menu = 'Menu',
    this.expand = 'Expand',
    this.collapse = 'Collapse',
    this.increment = 'Increase',
    this.decrement = 'Decrease',
    this.back = 'Back',
    this.previous = 'Previous',
    this.next = 'Next',
    this.previousPage = 'Previous page',
    this.nextPage = 'Next page',
    this.firstPage = 'First page',
    this.lastPage = 'Last page',
    this.previousMonth = 'Previous month',
    this.nextMonth = 'Next month',
    this.today = 'Today',
    this.sortAscending = 'Sort ascending',
    this.sortDescending = 'Sort descending',
    this.sortedAscending = 'Sorted ascending',
    this.sortedDescending = 'Sorted descending',
    this.copyToClipboard = 'Copy to clipboard',
    this.openSidebar = 'Open sidebar',
    this.closeSidebar = 'Close sidebar',
    this.collapseSidebar = 'Collapse sidebar',
    this.expandSidebar = 'Expand sidebar',
    this.switchLabel = 'Switch',
    this.breadcrumbs = 'Breadcrumbs',
    this.pagination = 'Pagination',
    this.notifications = 'Notifications',
    this.required = 'Required',
    this.retry = 'Retry',
    this.loadingChart = 'Loading chart',
    this.noDataInRange = 'No data in this time range',
    this.flowDiagram = 'Flow diagram',
    this.done = 'Done',
    this.refresh = 'Refresh',
    this.loadFailedRetry = 'Could not load. Press to retry.',
    this.finish = 'Finish',
    this.moreActions = 'More actions',
    this.navigation = 'Navigation',
    this.opensInNewWindow = 'Opens in a new window',
    this.pageNumber = 'Page number',
    this.pageSize = 'Page size',
    this.perPage = 'Per page:',
    this.tableOfContents = 'Table of contents',
    this.scrollTabsStart = 'Scroll tabs left',
    this.scrollTabsEnd = 'Scroll tabs right',
    this.showOptions = 'Show options',
    this.addTag = 'Add',
    this.searchFailed = 'Search failed. Check your connection and try again.',
    this.pickDate = 'Pick a date',
    this.pickDates = 'Select dates',
    this.pickTime = 'Pick a time',
    this.chooseDateFromCalendar = 'Choose date from calendar',
    this.hours = 'Hours',
    this.minutes = 'Minutes',
    this.seconds = 'Seconds',
    this.dayPeriod = 'AM or PM',
    this.monthNames = const [
      'January', 'February', 'March', 'April', 'May', 'June', //
      'July', 'August', 'September', 'October', 'November', 'December',
    ],
    this.monthNamesShort = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    this.weekdayNamesShort = const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'],
    this.weekdayNames = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
    this.firstDayOfWeek = DateTime.sunday,
  });

  final String optional;
  final String moreInformation;
  final String close;
  final String cancel;
  final String confirm;
  final String dismiss;
  final String loading;
  final String copy;
  final String copied;
  final String copyFailed;
  final String show;

  /// Hint on a masked sensitive value with a mouse, and with touch.
  final String clickToReveal;
  final String tapToReveal;

  /// Announced when a revealed sensitive value is masked again.
  final String valueHidden;
  final String hide;
  final String clear;
  final String search;
  final String noResults;
  final String select;
  final String selectAll;
  final String selectRow;
  final String remove;
  final String more;
  final String menu;
  final String expand;
  final String collapse;
  final String increment;
  final String decrement;
  final String back;
  final String previous;
  final String next;
  final String previousPage;
  final String nextPage;
  final String firstPage;
  final String lastPage;
  final String previousMonth;
  final String nextMonth;
  final String today;
  final String sortAscending;
  final String sortDescending;

  /// Screen reader value of the column a table is sorted by.
  final String sortedAscending;
  final String sortedDescending;

  /// Accessible name of copy buttons next to a value.
  final String copyToClipboard;
  final String openSidebar;
  final String closeSidebar;
  final String collapseSidebar;
  final String expandSidebar;

  /// Fallback accessible name of a switch with no label.
  final String switchLabel;
  final String breadcrumbs;
  final String pagination;
  final String notifications;
  final String required;
  final String retry;

  /// Screen reader label of a chart's loading skeleton.
  final String loadingChart;

  /// Empty state of a time series chart.
  final String noDataInRange;

  /// Accessible name of a flow diagram without its own label.
  final String flowDiagram;
  final String done;
  final String refresh;

  /// A lazily loaded section (a tree node) that failed and can be retried.
  final String loadFailedRetry;

  /// Label of the last step's primary button in a stepper.
  final String finish;
  final String moreActions;

  /// Accessible name of a sidebar or other navigation region.
  final String navigation;

  /// Hint on links that leave the app.
  final String opensInNewWindow;
  final String pageNumber;
  final String pageSize;
  final String perPage;
  final String tableOfContents;
  final String scrollTabsStart;
  final String scrollTabsEnd;

  /// Accessible name of a combobox's open button.
  final String showOptions;

  /// Label of the add button in a tag input.
  final String addTag;
  final String searchFailed;

  /// Date and time field placeholders.
  final String pickDate;
  final String pickDates;
  final String pickTime;
  final String chooseDateFromCalendar;

  /// Names of time field segments, for screen readers.
  final String hours;
  final String minutes;
  final String seconds;
  final String dayPeriod;

  /// Twelve month names, January first.
  final List<String> monthNames;
  final List<String> monthNamesShort;

  /// Seven weekday names, Monday first (ISO order, matching [DateTime.weekday] - 1).
  final List<String> weekdayNamesShort;
  final List<String> weekdayNames;

  /// [DateTime.monday] through [DateTime.sunday]. Kumo's date picker starts on Sunday.
  final int firstDayOfWeek;

  /// A flow node's place in a sequence: "Step 2 of 4".
  String flowStep(int index, int count) => 'Step $index of $count';

  /// A flow node's branch inside a parallel group: "branch 1 of 3".
  String flowBranch(int index, int count) => 'branch $index of $count';

  /// A flow diagram's value: "4 steps".
  String flowSteps(int count) => count == 1 ? '1 step' : '$count steps';

  /// "Step 2 of 5" in steps and steppers.
  String stepOf(int step, int total) => 'Step $step of $total';

  /// Error for a tag the validator rejected without its own message.
  String invalidValue(String value) => '"$value" is not valid';

  /// Error when a tag input already holds its maximum.
  String maxValuesReached(int max) => 'You can add up to $max';

  /// Overflow chip of an avatar group: "Show 3 more".
  String showMore(int count) => 'Show $count more';

  /// "Page 2 of 10".
  String pageOf(int page, int total) => 'Page $page of $total';

  /// "Remove production" for a tag chip.
  String removeItem(String item) => '$remove $item';

  /// "Showing 1-10 of 42".
  String showingRange(int from, int to, int total) => 'Showing $from-$to of $total';

  /// "March 2026".
  String monthYear(DateTime month) => '${monthNames[month.month - 1]} ${month.year}';

  /// "Mar 4, 2026".
  String shortDate(DateTime d) => '${monthNamesShort[d.month - 1]} ${d.day}, ${d.year}';

  /// "Wednesday, March 4, 2026", for screen readers.
  String fullDate(DateTime d) => '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}, ${d.year}';
}

/// Provides [KumoStrings] to a subtree. Without one, English defaults apply.
class KumoLocale extends InheritedWidget {
  const KumoLocale({super.key, required this.strings, required super.child});

  final KumoStrings strings;

  static KumoStrings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KumoLocale>()?.strings ?? const KumoStrings();

  @override
  bool updateShouldNotify(KumoLocale oldWidget) => strings != oldWidget.strings;
}

/// `context.kumoStrings` shorthand for [KumoLocale.of].
extension KumoStringsContext on BuildContext {
  KumoStrings get kumoStrings => KumoLocale.of(this);
}
