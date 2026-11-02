@Tags(['golden'])
library;

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('calendar range and multiple, today and disabled days', (tester) async {
    await withClock(Clock.fixed(DateTime(2026, 3, 4)), () async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        goldenPair(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              KumoCalendar.range(
                padding: const EdgeInsets.all(12),
                value: KumoDateRange(from: DateTime(2026, 3, 6), to: DateTime(2026, 3, 17)),
                isDateDisabled: (d) => d.day == 25,
                onValueChange: (_) {},
                footer: const Text('Sample data'),
              ),
              KumoCalendar.multiple(
                padding: const EdgeInsets.all(12),
                value: [DateTime(2026, 3, 2), DateTime(2026, 3, 9)],
                max: 2,
                onValueChange: (_) {},
              ),
            ],
          ),
          width: 330,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/dates.png'));
    });
  });
}
