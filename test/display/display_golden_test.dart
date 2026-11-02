@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('display category in light and dark', (tester) async {
    tester.view.physicalSize = const Size(800, 700) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    final days = [
      for (var i = 0; i < 30; i++)
        KumoTrackerDay(
          date: DateTime(2026, 10, 2).add(Duration(days: i)),
          status: switch (i) {
            0 || 1 => KumoTrackerStatus.noData,
            12 => KumoTrackerStatus.degraded,
            20 => KumoTrackerStatus.outage,
            _ => KumoTrackerStatus.operational,
          },
        ),
    ];
    await tester.pumpWidget(
      goldenPair(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in [
                  KumoBadgeVariant.primary,
                  KumoBadgeVariant.secondary,
                  KumoBadgeVariant.error,
                  KumoBadgeVariant.warning,
                  KumoBadgeVariant.success,
                  KumoBadgeVariant.info,
                  KumoBadgeVariant.outline,
                  KumoBadgeVariant.beta,
                  KumoBadgeVariant.teal,
                  KumoBadgeVariant.tealSubtle,
                  KumoBadgeVariant.orangeSubtle,
                ])
                  KumoBadge('Badge', variant: v),
                const KumoBadge('Healthy', variant: KumoBadgeVariant.success, appearance: KumoBadgeAppearance.dot),
                const KumoBadge('Verified', variant: KumoBadgeVariant.success, icon: KumoIcons.checkCircle),
              ],
            ),
            const KumoMeter(
              label: 'R2 storage',
              value: 9,
              max: 10,
              customValue: '9 / 10 GB',
              thresholds: [KumoMeterThreshold(value: 8, tone: KumoMeterTone.warning, label: 'Approaching the limit')],
            ),
            const Row(
              spacing: 12,
              children: [
                Expanded(child: KumoProgress(value: 64, label: 'Uploading', showValue: true)),
                KumoProgress(value: 64, variant: KumoProgressVariant.circular),
              ],
            ),
            const KumoSkeletonLine(widthFactor: 0.7),
            const Row(
              spacing: 12,
              children: [
                KumoAvatarGroup(
                  max: 3,
                  avatars: [
                    KumoAvatar(name: 'Ada Lovelace'),
                    KumoAvatar(name: 'Grace Hopper'),
                    KumoAvatar(name: 'Alan Turing'),
                    KumoAvatar(name: 'Katherine Johnson'),
                  ],
                ),
                KumoAvatar(name: 'example.com', shape: KumoAvatarShape.square, status: KumoAvatarStatus.online),
                KumoKbd('K', modifiers: [KumoKbdModifier.mod], platform: TargetPlatform.macOS),
                KumoKbd('K', modifiers: [KumoKbdModifier.mod], platform: TargetPlatform.windows),
              ],
            ),
            KumoTracker(label: 'image-resizer', valueText: '96.7% uptime', days: days),
            const KumoSeparator(label: 'or'),
            const KumoEmpty(
              size: KumoEmptySize.sm,
              icon: KumoIcons.database,
              title: 'No D1 databases',
              description: 'Databases you create appear here.',
              commandLine: 'npx wrangler d1 create app-db',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/display.png'));
  });
}
