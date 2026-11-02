@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('buttons, text and cards in light and dark', (tester) async {
    tester.view.physicalSize = const Size(800, 640) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(goldenPair(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const KumoText('Workers', variant: KumoTextVariant.heading, size: KumoTextSize.lg),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final v in KumoButtonVariant.values) KumoButton(label: v.name, variant: v, onPress: () {}),
          ]),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final s in KumoButtonSize.values) KumoButton(label: s.name, size: s, icon: KumoIcons.plus, onPress: () {}),
            KumoButton(icon: KumoIcons.gear, shape: KumoButtonShape.square, semanticLabel: 'Settings', onPress: () {}),
            const KumoButton(label: 'Disabled'),
          ]),
          const KumoLayerCard(child: KumoText('image-resizer was deployed to production.')),
          const KumoLayerCard.layered(children: [
            KumoLayerCardSecondary(child: Text('Caching')),
            KumoLayerCardPrimary(child: KumoText('Cache static assets at the edge.', variant: KumoTextVariant.secondary)),
          ]),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/foundation.png'));
  });
}
