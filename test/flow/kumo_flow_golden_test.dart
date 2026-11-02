@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('flow diagram golden: branches, a disabled branch, a selected node', (tester) async {
    tester.view.physicalSize = const Size(800, 1200) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      goldenPair(
        width: 380,
        KumoFlowDiagram(
          orientation: KumoFlowOrientation.vertical,
          align: KumoFlowAlign.center,
          padding: const EdgeInsets.all(KumoSpace.s4),
          children: [
            const KumoFlowNode(label: 'Request'),
            KumoFlowParallel(
              children: [
                KumoFlowNode(label: 'WAF', selected: true, onPress: () {}),
                const KumoFlowNode(label: 'Rate limit, paused', disabled: true),
              ],
            ),
            const KumoFlowNode(label: 'image-resizer'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/flow_diagram.png'));
  });
}
