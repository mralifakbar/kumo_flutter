import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Calendars, date and time pickers and typed date and time fields. Every
/// date, schedule and resource here is sample data.
final KumoDemoCategory datesCategory = KumoDemoCategory(
  title: 'Dates and time',
  description:
      'Calendars, date and range pickers, time pickers and typed date and time fields. Schedules shown are sample data.',
  icon: KumoIcons.calendarDots,
  demos: [
    KumoDemo(
      title: 'KumoCalendar',
      description:
          'Single, multiple and range selection with limits, disabled days, two months and swipe between months.',
      docPath: 'doc/components/KumoCalendar.md',
      builder: (_) => const _CalendarDemo(),
    ),
    KumoDemo(
      title: 'KumoDatePicker',
      description: 'Date fields that open a popover on wide screens and a sheet on phones, with range presets.',
      docPath: 'doc/components/KumoDatePicker.md',
      builder: (_) => const _DatePickerDemo(),
    ),
    KumoDemo(
      title: 'KumoDateRangePicker',
      description: 'Deprecated alias kept for migration; it renders KumoDatePicker.range.',
      docPath: 'doc/components/KumoDateRangePicker.md',
      builder: (_) => const _DateRangePickerDemo(),
    ),
    KumoDemo(
      title: 'KumoTimePicker',
      description: 'Time fields with popover columns on wide screens and snapping wheels in a sheet on phones.',
      docPath: 'doc/components/KumoTimePicker.md',
      builder: (_) => const _TimePickerDemo(),
    ),
    KumoDemo(
      title: 'KumoTimeInput',
      description: 'Typed hours, minutes and seconds with arrow-key steps, 12 and 24 hour formats.',
      docPath: 'doc/components/KumoTimeInput.md',
      builder: (_) => const _TimeInputDemo(),
    ),
    KumoDemo(
      title: 'KumoDateInput',
      description: 'Typed dates with separators inserted as you type, validation and a calendar button.',
      docPath: 'doc/components/KumoDateInput.md',
      builder: (_) => const _DateInputDemo(),
    ),
  ],
);

Widget _column(List<Widget> children) =>
    Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s6, children: children);

Widget _framed(Widget calendar) => Align(alignment: AlignmentDirectional.centerStart, child: calendar);

/// Kumo's demos give the calendar `p-3`; it has no padding of its own.
const EdgeInsets _pad = EdgeInsets.all(KumoSpace.s3);

String _short(BuildContext context, DateTime? d) => d == null ? 'None' : context.kumoStrings.shortDate(d);

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo();

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  DateTime? _single;
  List<DateTime> _maintenance = const [];
  KumoDateRange? _range;
  KumoDateRange? _stay;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final booked = {5, 12, 18, 25};
    return _column([
      DemoSection(
        title: 'Single date',
        caption: 'Tap a day, tap it again to clear. Swipe the grid on touch to change month.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            _framed(
              KumoCalendar.single(padding: _pad, value: _single, onValueChange: (d) => setState(() => _single = d)),
            ),
            KumoText(
              'Selected: ${_short(context, _single)}',
              variant: KumoTextVariant.secondary,
              size: KumoTextSize.sm,
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Multiple dates with a limit',
        caption: 'Pick up to 5 maintenance days for the zone example.com. Booked days are unavailable.',
        child: _framed(
          KumoCalendar.multiple(
            padding: _pad,
            value: _maintenance,
            max: 5,
            fixedWeeks: true,
            isDateDisabled: (d) => d.year == today.year && d.month == today.month && booked.contains(d.day),
            onValueChange: (d) => setState(() => _maintenance = d),
            footer: Text('${_maintenance.length}/5 days selected. Grayed dates are unavailable.'),
          ),
        ),
      ),
      DemoSection(
        title: 'Range across two months',
        caption: 'Side by side when there is room, stacked on a phone. Days outside each month are hidden.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            _framed(
              KumoCalendar.range(
                padding: _pad,
                value: _range,
                numberOfMonths: 2,
                onValueChange: (r) => setState(() => _range = r),
              ),
            ),
            KumoText(
              'Range: ${_range == null ? 'None' : '${_short(context, _range!.from)} – ${_range!.to == null ? '...' : _short(context, _range!.to)}'}',
              variant: KumoTextVariant.secondary,
              size: KumoTextSize.sm,
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Range with minimum and maximum length',
        caption: 'Between 3 and 7 nights, starting today or later.',
        child: _framed(
          KumoCalendar.range(
            padding: _pad,
            value: _stay,
            min: 3,
            max: 7,
            minDate: today,
            onValueChange: (r) => setState(() => _stay = r),
            footer: const Text('Select 3-7 nights'),
          ),
        ),
      ),
      DemoSection(
        title: 'Disabled',
        child: _framed(KumoCalendar.single(padding: _pad, disabled: true, value: today, onValueChange: (_) {})),
      ),
    ]);
  }
}

class _DatePickerDemo extends StatefulWidget {
  const _DatePickerDemo();

  @override
  State<_DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<_DatePickerDemo> {
  DateTime? _expiry;
  KumoDateRange? _period;
  List<DateTime> _freeze = const [];
  DateTime? _start;
  DateTime? _small;
  DateTime? _large;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return _column([
      DemoSection(
        title: 'Single date',
        caption: 'Closes when a day is picked. Popover on wide screens, bottom sheet below 768px.',
        child: KumoDatePicker.single(
          label: 'Certificate expiry',
          description: 'Sample certificate for example.com.',
          value: _expiry,
          minDate: today,
          onValueChange: (d) => setState(() => _expiry = d),
        ),
      ),
      DemoSection(
        title: 'Range with presets',
        caption: 'Kumo\'s presets beside two months; chips above the calendar in the sheet.',
        child: KumoDatePicker.range(
          label: 'Analytics period',
          value: _period,
          maxDate: today,
          presets: KumoDatePickerPreset.kumoDefaults,
          onValueChange: (r) => setState(() => _period = r),
        ),
      ),
      DemoSection(
        title: 'Multiple dates',
        child: KumoDatePicker.multiple(
          label: 'Deploy freeze days',
          value: _freeze,
          max: 3,
          onValueChange: (d) => setState(() => _freeze = d),
        ),
      ),
      DemoSection(
        title: 'Error',
        child: KumoDatePicker.single(
          label: 'Rollout starts',
          value: _start,
          error: _start == null ? 'Pick the first day of the rollout.' : null,
          onValueChange: (d) => setState(() => _start = d),
        ),
      ),
      DemoSection(
        title: 'Sizes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoDatePicker.single(
              size: KumoFieldSize.sm,
              placeholder: 'Small',
              value: _small,
              onValueChange: (d) => setState(() => _small = d),
            ),
            KumoDatePicker.single(
              placeholder: 'Base',
              value: _expiry,
              onValueChange: (d) => setState(() => _expiry = d),
            ),
            KumoDatePicker.single(
              size: KumoFieldSize.lg,
              placeholder: 'Large',
              value: _large,
              onValueChange: (d) => setState(() => _large = d),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Disabled',
        child: KumoDatePicker.single(label: 'Billing date', disabled: true, value: today, onValueChange: (_) {}),
      ),
    ]);
  }
}

class _DateRangePickerDemo extends StatefulWidget {
  const _DateRangePickerDemo();

  @override
  State<_DateRangePickerDemo> createState() => _DateRangePickerDemoState();
}

class _DateRangePickerDemoState extends State<_DateRangePickerDemo> {
  KumoDateRange? _range;

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Deprecated',
        caption: 'Kumo deprecated DateRangePicker. Use KumoDatePicker.range in new code; this alias forwards to it.',
        // ignore: deprecated_member_use
        child: KumoDateRangePicker(
          label: 'Log retention window',
          value: _range,
          onValueChange: (r) => setState(() => _range = r),
        ),
      ),
    ]);
  }
}

class _TimePickerDemo extends StatefulWidget {
  const _TimePickerDemo();

  @override
  State<_TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<_TimePickerDemo> {
  KumoTimeValue? _cron = const KumoTimeValue(hour: 2, minute: 30);
  KumoTimeValue? _utc;
  KumoTimeValue? _slot;

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: '12-hour',
        caption: 'Popover columns on wide screens; on phones, wheels that follow the finger and snap.',
        child: KumoTimePicker(
          label: 'Cron trigger time',
          description: 'Sample schedule for the Worker image-resizer.',
          value: _cron,
          onValueChange: (t) => setState(() => _cron = t),
        ),
      ),
      DemoSection(
        title: '24-hour with seconds',
        child: KumoTimePicker(
          label: 'Purge cache at (UTC)',
          use24Hour: true,
          showSeconds: true,
          value: _utc,
          onValueChange: (t) => setState(() => _utc = t),
        ),
      ),
      DemoSection(
        title: '15-minute steps',
        child: KumoTimePicker(
          label: 'Maintenance slot',
          minuteStep: 15,
          value: _slot,
          error: _slot != null && _slot!.hour < 6 ? 'Pick a slot after 6:00 AM.' : null,
          onValueChange: (t) => setState(() => _slot = t),
        ),
      ),
      DemoSection(
        title: 'Disabled',
        child: KumoTimePicker(
          label: 'Backup time',
          disabled: true,
          value: const KumoTimeValue(hour: 4),
          onValueChange: (_) {},
        ),
      ),
    ]);
  }
}

class _TimeInputDemo extends StatefulWidget {
  const _TimeInputDemo();

  @override
  State<_TimeInputDemo> createState() => _TimeInputDemoState();
}

class _TimeInputDemoState extends State<_TimeInputDemo> {
  KumoTimeValue? _start = const KumoTimeValue(hour: 22, minute: 0);
  KumoTimeValue? _precise;
  KumoTimeValue? _end;

  @override
  Widget build(BuildContext context) {
    final endsBeforeStart = _start != null && _end != null && _end!.compareTo(_start!) <= 0;
    return _column([
      DemoSection(
        title: '12-hour',
        caption: 'Type digits, or use Arrow Up and Down. A and P set AM and PM.',
        child: KumoTimeInput(
          label: 'Backup window starts',
          value: _start,
          minuteStep: 5,
          onValueChange: (t) => setState(() => _start = t),
        ),
      ),
      DemoSection(
        title: '24-hour with seconds',
        child: KumoTimeInput(
          label: 'Rate limit resets at',
          use24Hour: true,
          showSeconds: true,
          value: _precise,
          onValueChange: (t) => setState(() => _precise = t),
        ),
      ),
      DemoSection(
        title: 'Error',
        child: KumoTimeInput(
          label: 'Backup window ends',
          value: _end,
          error: endsBeforeStart ? 'End the window after it starts.' : null,
          onValueChange: (t) => setState(() => _end = t),
        ),
      ),
      DemoSection(
        title: 'Sizes and disabled',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoTimeInput(
              size: KumoFieldSize.sm,
              semanticLabel: 'Small',
              value: _start,
              onValueChange: (t) => setState(() => _start = t),
            ),
            KumoTimeInput(
              size: KumoFieldSize.lg,
              semanticLabel: 'Large',
              value: _start,
              onValueChange: (t) => setState(() => _start = t),
            ),
            const KumoTimeInput(semanticLabel: 'Disabled', disabled: true, value: KumoTimeValue(hour: 9)),
          ],
        ),
      ),
    ]);
  }
}

class _DateInputDemo extends StatefulWidget {
  const _DateInputDemo();

  @override
  State<_DateInputDemo> createState() => _DateInputDemoState();
}

class _DateInputDemoState extends State<_DateInputDemo> {
  DateTime? _expiry;
  DateTime? _launch;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return _column([
      DemoSection(
        title: 'ISO format',
        caption: 'Separators appear as you type. February 30 or a past day shows an error.',
        child: KumoDateInput(
          label: 'API token expires on',
          description: 'Sample token for the R2 bucket assets.',
          value: _expiry,
          minDate: today,
          onValueChange: (d) => setState(() => _expiry = d),
        ),
      ),
      DemoSection(
        title: 'Month first, weekdays only',
        child: KumoDateInput(
          label: 'Launch date',
          format: KumoDateInputFormat.mdy,
          value: _launch,
          isDateDisabled: (d) => d.weekday == DateTime.saturday || d.weekday == DateTime.sunday,
          unavailableDateMessage: 'Launches happen on weekdays. Pick Monday to Friday.',
          onValueChange: (d) => setState(() => _launch = d),
        ),
      ),
      DemoSection(
        title: 'Disabled',
        child: KumoDateInput(label: 'Zone created on', disabled: true, value: today, onValueChange: (_) {}),
      ),
    ]);
  }
}
