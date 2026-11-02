import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

final _march4 = DateTime(2026, 3, 4);

Future<void> _at(DateTime now, Future<void> Function() body) => withClock(Clock.fixed(now), body);

/// Hosts a calendar with live state, the way an app would.
class _Single extends StatefulWidget {
  const _Single({super.key, this.initial, this.minDate, this.maxDate, this.isDateDisabled, this.required = false});

  final DateTime? initial;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool Function(DateTime)? isDateDisabled;
  final bool required;

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  late DateTime? value = widget.initial;
  final changes = <DateTime?>[];

  @override
  Widget build(BuildContext context) => KumoCalendar.single(
    value: value,
    required: widget.required,
    minDate: widget.minDate,
    maxDate: widget.maxDate,
    isDateDisabled: widget.isDateDisabled,
    onValueChange: (d) => setState(() {
      changes.add(d);
      value = d;
    }),
  );
}

class _Range extends StatefulWidget {
  const _Range({this.max, this.numberOfMonths = 1});

  final int? max;
  final int numberOfMonths;

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  KumoDateRange? value;

  @override
  Widget build(BuildContext context) => KumoCalendar.range(
    value: value,
    max: widget.max,
    numberOfMonths: widget.numberOfMonths,
    onValueChange: (r) => setState(() => value = r),
  );
}

class _Multiple extends StatefulWidget {
  const _Multiple({this.max});

  final int? max;

  @override
  State<_Multiple> createState() => _MultipleState();
}

class _MultipleState extends State<_Multiple> {
  List<DateTime> value = const [];

  @override
  Widget build(BuildContext context) =>
      KumoCalendar.multiple(value: value, max: widget.max, onValueChange: (d) => setState(() => value = d));
}

Finder _day(int day, {int month = 3, int year = 2026}) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(const KumoStrings().fullDate(DateTime(year, month, day)))}'));

void main() {
  testWidgets('renders in light and dark with the month caption and weekday row', (tester) async {
    await _at(_march4, () async {
      for (final b in Brightness.values) {
        await pumpKumo(tester, const _Single(), brightness: b);
        expect(find.text('March 2026'), findsOneWidget);
        expect(find.text('Su'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  testWidgets('week starts on KumoStrings.firstDayOfWeek', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        const KumoLocale(
          strings: KumoStrings(firstDayOfWeek: DateTime.monday),
          child: _Single(),
        ),
      );
      final mo = tester.getTopLeft(find.text('Mo')).dx;
      final su = tester.getTopLeft(find.text('Su')).dx;
      expect(mo, lessThan(su));
      // March 1, 2026 is a Sunday: the last column of the first week.
      final first = tester.getCenter(_day(1));
      expect(first.dx, closeTo(tester.getCenter(find.text('Su')).dx, 1));
    });
  });

  testWidgets('single: tap selects, tapping again clears, required keeps it', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Single());
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      expect(state.value, DateTime(2026, 3, 10));
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      expect(state.value, isNull);

      await pumpKumo(tester, _Single(key: UniqueKey(), initial: DateTime(2026, 3, 10), required: true));
      final required = tester.state<_SingleState>(find.byType(_Single));
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      expect(required.changes, isEmpty);
    });
  });

  testWidgets('reflects the value it is given', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(value: DateTime(2026, 3, 20), onValueChange: (_) {}));
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(_day(20)),
        containsSemantics(
          label: 'Friday, March 20, 2026',
          isSelected: true,
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  testWidgets('disabled days, min and max do not fire and announce as disabled', (tester) async {
    await _at(_march4, () async {
      final handle = tester.ensureSemantics();
      await pumpKumo(
        tester,
        _Single(
          minDate: DateTime(2026, 3, 3),
          maxDate: DateTime(2026, 3, 28),
          isDateDisabled: (d) => d.weekday == DateTime.saturday,
        ),
      );
      final state = tester.state<_SingleState>(find.byType(_Single));
      await tester.tap(_day(2));
      await tester.tap(_day(7));
      await tester.tap(_day(30));
      await tester.pumpAndSettle();
      expect(state.changes, isEmpty);
      expect(tester.getSemantics(_day(7)), containsSemantics(isEnabled: false, hasEnabledState: true));
      // Navigation stops at the min and max months.
      expect(tester.getSemantics(find.bySemanticsLabel('Previous month')), containsSemantics(isEnabled: false));
      handle.dispose();
    });
  });

  testWidgets('today is announced and drawn semibold in the link color', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Single());
      expect(find.bySemanticsLabel('Wednesday, March 4, 2026, Today'), findsOneWidget);
      final text = tester.widget<Text>(find.descendant(of: _day(4), matching: find.text('4')));
      expect(text.style!.fontWeight, FontWeight.w600);
      expect(text.style!.color, KumoColorSchemes.light.textLink);
    });
  });

  testWidgets('withClock decides today, not the wall clock', (tester) async {
    await _at(DateTime(2031, 7, 15, 9, 30), () async {
      await pumpKumo(tester, const _Single());
      expect(find.text('July 2031'), findsOneWidget);
      expect(find.bySemanticsLabel('Tuesday, July 15, 2031, Today'), findsOneWidget);
    });
  });

  testWidgets('range follows react-day-picker rules and paints a band', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Range());
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      expect(state.value, KumoDateRange(from: DateTime(2026, 3, 10), to: DateTime(2026, 3, 10)));
      await tester.tap(_day(14));
      await tester.pumpAndSettle();
      expect(state.value, KumoDateRange(from: DateTime(2026, 3, 10), to: DateTime(2026, 3, 14)));
      expect(state.value!.nights, 4);
      await tester.tap(_day(8));
      await tester.pumpAndSettle();
      expect(state.value, KumoDateRange(from: DateTime(2026, 3, 8), to: DateTime(2026, 3, 14)));
      // Middle days are selected too.
      final handle = tester.ensureSemantics();
      expect(tester.getSemantics(_day(11)), containsSemantics(isSelected: true));
      handle.dispose();
    });
  });

  testWidgets('range max nights restarts the range', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Range(max: 3));
      final state = tester.state<_RangeState>(find.byType(_Range));
      await tester.tap(_day(10));
      await tester.pumpAndSettle();
      await tester.tap(_day(20));
      await tester.pumpAndSettle();
      expect(state.value, KumoDateRange(from: DateTime(2026, 3, 20)));
    });
  });

  testWidgets('multiple toggles days and disables the rest at max', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Multiple(max: 2));
      final state = tester.state<_MultipleState>(find.byType(_Multiple));
      await tester.tap(_day(2));
      await tester.pumpAndSettle();
      await tester.tap(_day(3));
      await tester.pumpAndSettle();
      expect(state.value, [DateTime(2026, 3, 2), DateTime(2026, 3, 3)]);
      await tester.tap(_day(9));
      await tester.pumpAndSettle();
      expect(state.value.length, 2);
      await tester.tap(_day(2));
      await tester.pumpAndSettle();
      expect(state.value, [DateTime(2026, 3, 3)]);
    });
  });

  testWidgets('nav buttons change month with a slide and report it', (tester) async {
    await _at(_march4, () async {
      final months = <DateTime>[];
      await pumpKumo(tester, KumoCalendar.single(onValueChange: (_) {}, onMonthChange: months.add));
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Mid-slide both grids are on screen and clipped.
      expect(find.byType(ClipRect), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      expect(months, [DateTime(2026, 4)]);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  testWidgets('a second press mid-slide continues from where the month is', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(onValueChange: (_) {}));
      List<double> offsets() => tester
          .widgetList<FractionalTranslation>(
            find.descendant(of: find.byType(KumoCalendar), matching: find.byType(FractionalTranslation)),
          )
          .map((t) => t.translation.dx)
          .toList();
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      // April, the current month, is part of the way in.
      final april = offsets().firstWhere((dx) => dx > 0 && dx < 1);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      // April is now the month leaving, still where it was, not recentered.
      final after = offsets();
      expect(after.any((dx) => (dx - april).abs() < 0.1), isTrue, reason: '$after vs $april');
      expect(after.any((dx) => dx == 0), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('May 2026'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('controlled month follows the parent', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(month: DateTime(2026, 8), onValueChange: (_) {}));
      expect(find.text('August 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      // The parent kept August, so the calendar stays there.
      expect(find.text('August 2026'), findsOneWidget);
    });
  });

  testWidgets('swipe follows the finger and velocity picks the month', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(onValueChange: (_) {}));
      final grid = tester.getCenter(_day(18));
      // A slow short drag snaps back.
      final gesture = await tester.startGesture(grid, kind: PointerDeviceKind.touch);
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(tester.getCenter(_day(18)).dx, lessThan(grid.dx - 20));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
      expect(tester.getCenter(_day(18)).dx, closeTo(grid.dx, 0.5));
      // A quick flick to the left goes to the next month.
      await tester.fling(find.text('18'), const Offset(-120, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      // And to the right comes back.
      await tester.fling(find.text('18'), const Offset(120, 0), 1200);
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  testWidgets('swipe past the min month rubberbands back', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(minDate: DateTime(2026, 3, 1), onValueChange: (_) {}));
      await tester.fling(find.text('18'), const Offset(200, 0), 1500);
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  testWidgets('keyboard: arrows, Page Up and Down, Home and End, Enter selects', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Single(), tapTargetSize: KumoTapTargetSize.shrinkWrap, size: kumoDesktopSize);
      final state = tester.state<_SingleState>(find.byType(_Single));
      // Tab order follows react-day-picker: previous, next, then the grid.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.pump();
      Future<void> key(LogicalKeyboardKey k) async {
        await tester.sendKeyEvent(k);
        await tester.pumpAndSettle();
      }

      // Tab lands on today.
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 3, 4));
      await key(LogicalKeyboardKey.arrowRight);
      await key(LogicalKeyboardKey.arrowDown);
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 3, 12));
      await key(LogicalKeyboardKey.home);
      await key(LogicalKeyboardKey.space);
      expect(state.value, DateTime(2026, 3, 8));
      await key(LogicalKeyboardKey.end);
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 3, 14));
      await key(LogicalKeyboardKey.pageDown);
      expect(find.text('April 2026'), findsOneWidget);
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 4, 14));
      await key(LogicalKeyboardKey.arrowUp);
      await key(LogicalKeyboardKey.arrowUp);
      await key(LogicalKeyboardKey.arrowUp);
      expect(find.text('March 2026'), findsOneWidget);
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 3, 24));
      await key(LogicalKeyboardKey.pageUp);
      await key(LogicalKeyboardKey.enter);
      expect(state.value, DateTime(2026, 2, 24));
    });
  });

  testWidgets('keyboard skips disabled days', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        _Single(isDateDisabled: (d) => d.day == 5 || d.day == 6),
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
        size: kumoDesktopSize,
      );
      final state = tester.state<_SingleState>(find.byType(_Single));
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(state.value, DateTime(2026, 3, 7));
    });
  });

  testWidgets('RTL flips arrow keys and the nav chevrons', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        const _Single(),
        textDirection: TextDirection.rtl,
        tapTargetSize: KumoTapTargetSize.shrinkWrap,
      );
      final state = tester.state<_SingleState>(find.byType(_Single));
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(state.value, DateTime(2026, 3, 5));
      // In RTL the first column is on the right.
      expect(tester.getCenter(find.text('Su')).dx, greaterThan(tester.getCenter(find.text('Sa')).dx));
    });
  });

  testWidgets('outside days show for one month and hide for two', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Single());
      // March 2026 ends on a Tuesday; April 1-4 fill the last week.
      expect(_day(1, month: 4), findsOneWidget);
      await pumpKumo(tester, const _Range(numberOfMonths: 2), size: kumoDesktopSize);
      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('April 2026'), findsOneWidget);
      // April 1 appears once: in April, not as an outside day of March.
      expect(_day(1, month: 4), findsOneWidget);
      // Side by side on a wide screen.
      expect(tester.getTopLeft(find.text('April 2026')).dy, tester.getTopLeft(find.text('March 2026')).dy);
    });
  });

  testWidgets('two months stack on a phone', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Range(numberOfMonths: 2));
      expect(tester.getTopLeft(find.text('April 2026')).dy, greaterThan(tester.getTopLeft(find.text('March 2026')).dy));
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('reduced motion cross-fades and leaves nothing animating', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, KumoCalendar.single(onValueChange: (_) {}), disableAnimations: true);
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(
        find.descendant(of: find.byType(KumoCalendar), matching: find.byType(FractionalTranslation)),
        findsNothing,
      );
      expect(find.descendant(of: find.byType(KumoCalendar), matching: find.byType(Opacity)), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(
        tester,
        const Padding(padding: EdgeInsets.all(16), child: _Range(numberOfMonths: 2)),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(KumoCalendar)).width, lessThanOrEqualTo(358));
    });
  });

  testWidgets('touch slots are at least 44px', (tester) async {
    await _at(_march4, () async {
      await pumpKumo(tester, const _Single());
      final size = tester.getSize(find.ancestor(of: find.text('18'), matching: find.byType(KumoPressable)).first);
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });
  });

  testWidgets('footer and disabled calendar', (tester) async {
    await _at(_march4, () async {
      DateTime? picked;
      await pumpKumo(
        tester,
        KumoCalendar.single(disabled: true, onValueChange: (d) => picked = d, footer: const Text('2 of 5 days used')),
      );
      expect(find.text('2 of 5 days used'), findsOneWidget);
      await tester.tap(find.text('18'));
      expect(picked, isNull);
    });
  });

  test('KumoDateRange equality and contains', () {
    final r = KumoDateRange(from: DateTime(2026, 3, 1), to: DateTime(2026, 3, 7, 15));
    expect(r, KumoDateRange(from: DateTime(2026, 3, 1, 8), to: DateTime(2026, 3, 7)));
    expect(r.contains(DateTime(2026, 3, 7, 23)), isTrue);
    expect(r.contains(DateTime(2026, 3, 8)), isFalse);
    expect(r.nights, 6);
    expect(KumoDateRange(from: DateTime(2026, 3, 1)).isComplete, isFalse);
  });
}
