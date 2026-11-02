@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('data category in light and dark', (tester) async {
    tester.view.physicalSize = const Size(800, 900) * tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      goldenPair(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            KumoTable<(String, int)>(
              rows: const [('image-resizer', 18240), ('auth-proxy', 920), ('cron-cleanup', 12)],
              rowId: (r) => r.$1,
              selected: const {'auth-proxy'},
              sort: const KumoTableSort('requests', KumoTableSortDirection.descending),
              onSortChange: (_) {},
              onSelectionChange: (_) {},
              columns: [
                KumoTableColumn(id: 'name', label: 'Worker', cell: (context, r) => Text(r.$1)),
                KumoTableColumn(
                  id: 'requests',
                  label: 'Requests',
                  numeric: true,
                  sortable: true,
                  width: const KumoTableColumnWidth.fixed(110),
                  cell: (context, r) => Text('${r.$2}'),
                ),
              ],
            ),
            const KumoCodeHighlighted(
              code: 'export default {\n  async fetch(request) {\n    return new Response("Hello");\n  },\n};',
              lang: 'ts',
              showLineNumbers: true,
              highlightLines: [3],
            ),
            const KumoClipboardText(text: '023e105f4ecef8ad9ca31a8372d0c353', size: KumoClipboardTextSize.base),
            const KumoTimeline(items: [
              KumoTimelineItem(title: 'Deploying', time: 'Now', status: KumoTimelineStatus.active),
              KumoTimelineItem(title: 'Deployed', time: '2 min ago', status: KumoTimelineStatus.success),
              KumoTimelineItem(title: 'Build failed', time: '1 h ago', status: KumoTimelineStatus.danger),
            ]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Row).first, matchesGoldenFile('../goldens/data.png'));
  });
}
