import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

final _march4 = DateTime(2026, 3, 4);

Future<void> _at(DateTime now, Future<void> Function() body) => withClock(Clock.fixed(now), body);

Finder _day(int day, {int month = 3}) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(const KumoStrings().fullDate(DateTime(2026, month, day)))}'));

class _SingleHost extends StatefulWidget {
  const _SingleHost({this.disabled = false, this.initial});

  final bool disabled;
  final DateTime? initial;

  @override
  State<_SingleHost> createState() => _SingleHostState();
}

class _SingleHostState extends State<_SingleHost> {
  late DateTime? value = widget.initial;
  final opens = <bool>[];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 280,
        child: KumoDatePicker.single(
          label: 'Certificate expiry',
          description: 'Renew before this date.',
          disabled: widget.disabled,
          value: value,
          onOpenChange: opens.add,
          onValueChange: (d) => setState(() => value = d),
        ),
      ),
    ),
  );
}

class _RangeHost extends StatefulWidget {
  const _RangeHost();

  @override
  State<_RangeHost> createState() => _RangeHostState();
}

class _RangeHostState extends State<_RangeHost> {
  KumoDateRange? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 320,
        child: KumoDatePicker.range(
          label: 'Analytics period',
          presets: KumoDatePickerPreset.kumoDefaults,
          value: value,
          onValueChange: (r) => setState(() => value = r),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders placeholder, label and description in light and dark', (tester) async {
    await _at(_march4, () async {
      for (final b in Brightness.values) {
        await pumpKumo(tester, const _SingleHost(), brightness: b, center: false);
        expect(find.text('Pick a date'), findsOneWidget);
        expect(find.text('Certificate expiry'), findsOneWidget);
        expect(find.text('Renew before this date.'), findsOneWidget);
      }
    });
  });

  testWidgets('wide: opens a popover, picking a day closes it and shows the value', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _SingleHost(), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoPopupSurface), findsOneWidget);
      expect(find.byType(KumoSheet), findsNothing);
      await tester.tap(_day(18));
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
      expect(find.text('Mar 18, 2026'), findsOneWidget);
      final host = tester.state<_SingleHostState>(find.byType(_SingleHost));
      expect(host.opens, [true, false]);
    });
  });

  testWidgets('narrow: opens a bottom sheet with Done', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _SingleHost(), center: false);
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsOneWidget);
      expect(find.byType(KumoPopupSurface), findsNothing);
      await tester.tap(_day(9));
      await tester.pumpAndSettle();
      // Single pickers close on pick, in the sheet too.
      expect(find.byType(KumoSheet), findsNothing);
      expect(find.text('Mar 9, 2026'), findsOneWidget);
    });
  });

  testWidgets('sheet reflects controlled values while open', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _RangeHost(), center: false);
      await tester.tap(find.text('Select dates'));
      await tester.pumpAndSettle();
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      await tester.tap(_day(12));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(_day(11)), containsSemantics(isSelected: true));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoSheet), findsNothing);
      expect(find.text('Mar 10, 2026 – Mar 12, 2026'), findsOneWidget);
    });
  });

  testWidgets('presets set the range and move the calendar to it', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _RangeHost(), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Select dates'));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('April 2026'), findsOneWidget);
      await tester.tap(find.text('Last month'));
      await tester.pumpAndSettle();
      final host = tester.state<_RangeHostState>(find.byType(_RangeHost));
      expect(host.value, KumoDateRange(from: DateTime(2026, 2, 1), to: DateTime(2026, 2, 28)));
      expect(find.text('February 2026'), findsOneWidget);
      // The active preset is announced as selected.
      expect(tester.getSemantics(find.text('Last month')), containsSemantics(isSelected: true));
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      expect(host.value, KumoDateRange(from: DateTime(2026, 2, 26), to: _march4));
    });
  });

  testWidgets('clear button clears and is announced', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, _SingleHost(initial: DateTime(2026, 3, 2)), center: false);
      expect(find.text('Mar 2, 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Pick a date'), findsOneWidget);
      expect(find.byType(KumoSheet), findsNothing);
    });
  });

  testWidgets('disabled does not open', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _SingleHost(disabled: true), size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Pick a date'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
    });
  });

  testWidgets('semantics: label, value and expanded state', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, _SingleHost(initial: DateTime(2026, 3, 2)), size: kumoDesktopSize, center: false);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Certificate expiry').last),
        containsSemantics(
          label: 'Certificate expiry',
          value: 'Mar 2, 2026',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
    });
  });

  testWidgets('keyboard: Enter opens, focus moves to the selected day, Escape closes and restores focus', (
    tester,
  ) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        _SingleHost(initial: DateTime(2026, 3, 12)),
        size: kumoDesktopSize,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
        center: false,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final host = tester.state<_SingleHostState>(find.byType(_SingleHost));
      expect(host.value, DateTime(2026, 3, 13));
      expect(find.byType(KumoCalendar), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
    });
  });

  testWidgets('multiple mode lists the days in order', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        KumoDatePicker.multiple(value: [DateTime(2026, 3, 9), DateTime(2026, 3, 2)], onValueChange: (_) {}),
      );
      expect(find.text('Mar 2, 2026, Mar 9, 2026'), findsOneWidget);
    });
  });

  testWidgets('error replaces the description and rings the field', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        SizedBox(
          width: 300,
          child: KumoDatePicker.single(label: 'Start date', error: 'Pick a date after today', onValueChange: (_) {}),
        ),
      );
      expect(find.text('Pick a date after today'), findsOneWidget);
      final box = tester.widget<KumoFieldBox>(find.byType(KumoFieldBox));
      expect(box.error, isTrue);
    });
  });

  testWidgets('text scale 2.0 at 390px: field and sheet do not overflow', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _RangeHost(), textScale: 2, center: false);
      await tester.tap(find.text('Select dates'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(KumoSheet), findsOneWidget);
    });
  });

  testWidgets('reduced motion opens and closes without lingering animations', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _SingleHost(), disableAnimations: true, size: kumoDesktopSize, center: false);
      await tester.tap(find.text('Pick a date'));
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsOneWidget);
      await tester.tapAt(const Offset(900, 700));
      await tester.pumpAndSettle();
      expect(find.byType(KumoCalendar), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('deprecated KumoDateRangePicker forwards to the range picker', (tester) async {
    await _at(_march4, () async {
      KumoDateRange? picked;
      await pumpKumo(
        tester,
        SizedBox(
          width: 320,
          // ignore: deprecated_member_use_from_same_package
          child: KumoDateRangePicker(
            value: KumoDateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 3)),
            onValueChange: (r) => picked = r,
            presentation: KumoPresentation.popover,
          ),
        ),
        size: kumoDesktopSize,
      );
      expect(find.byType(KumoDatePicker), findsOneWidget);
      expect(find.text('Mar 1, 2026 – Mar 3, 2026'), findsOneWidget);
      await tester.tap(find.text('Mar 1, 2026 – Mar 3, 2026'));
      await tester.pumpAndSettle();
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      expect(picked, KumoDateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 10)));
    });
  });

  testWidgets('the field rings on pointer-down, before the panel opens', (tester) async {
    await _at(DateTime(2026, 3, 4), () async {
      await pumpKumo(tester, const _SingleHost(), size: kumoDesktopSize);
      final box = find.byType(KumoFieldBox);
      expect(tester.widget<KumoFieldBox>(box).focused, isFalse);
      final gesture = await tester.startGesture(tester.getCenter(box));
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.widget<KumoFieldBox>(box).focused, isTrue);
      await gesture.cancel();
      await tester.pumpAndSettle();
    });
  });
}
