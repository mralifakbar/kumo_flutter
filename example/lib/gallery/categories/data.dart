import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Tables, code, copy controls, grids, trees and timelines.
final KumoDemoCategory dataCategory = KumoDemoCategory(
  title: 'Data',
  description: 'Tables, code blocks, copyable values, grids, trees and timelines.',
  icon: KumoIcons.table,
  demos: [
    KumoDemo(
      title: 'KumoTable',
      description: 'Sortable, selectable rows with pinned columns, lazy building and a card layout for phones.',
      docPath: 'doc/components/KumoTable.md',
      builder: (context) => const _TableDemo(),
    ),
    KumoDemo(
      title: 'KumoCodeHighlighted',
      description: 'Syntax-colored code with line numbers, highlighted lines and a copy button.',
      docPath: 'doc/components/KumoCodeHighlighted.md',
      builder: (context) => const _CodeHighlightedDemo(),
    ),
    KumoDemo(
      title: 'KumoCode',
      description: 'Plain monospace code, bare or in a bordered block, with template values.',
      docPath: 'doc/components/KumoCode.md',
      builder: (context) => const _CodeDemo(),
    ),
    KumoDemo(
      title: 'KumoClipboardText',
      description: 'A read-only value with a copy button, optional masking and a tooltip mode.',
      docPath: 'doc/components/KumoClipboardText.md',
      builder: (context) => const _ClipboardTextDemo(),
    ),
    KumoDemo(
      title: 'KumoInlineCopyText',
      description: 'A borderless copy control for short IDs in text and table cells.',
      docPath: 'doc/components/KumoInlineCopyText.md',
      builder: (context) => const _InlineCopyTextDemo(),
    ),
    KumoDemo(
      title: 'KumoGrid',
      description: 'Responsive column grids that collapse at Kumo breakpoints.',
      docPath: 'doc/components/KumoGrid.md',
      builder: (context) => const _GridDemo(),
    ),
    KumoDemo(
      title: 'KumoTree',
      description: 'Nested, expandable items with selection, keyboard arrows and lazy children.',
      docPath: 'doc/components/KumoTree.md',
      builder: (context) => const _TreeDemo(),
    ),
    KumoDemo(
      title: 'KumoTimeline',
      description: 'A vertical history of events with a status marker for each.',
      docPath: 'doc/components/KumoTimeline.md',
      builder: (context) => const _TimelineDemo(),
    ),
  ],
);

const _gap = SizedBox(height: KumoSpace.s8);

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) _gap, children[i]],
        ],
      );
}

// Sample data: invented resources for the demos, not real metrics.
class _Worker {
  const _Worker(this.name, this.route, this.requests, this.errors, this.status);
  final String name;
  final String route;
  final int requests;
  final double errors;
  final String status;
}

const _workers = [
  _Worker('image-resizer', 'images.example.com/*', 182400, 0.2, 'Active'),
  _Worker('auth-proxy', 'example.com/login*', 92050, 1.4, 'Active'),
  _Worker('cron-cleanup', 'Scheduled', 1440, 0, 'Paused'),
  _Worker('og-image', 'example.com/og/*', 30812, 0.6, 'Active'),
  _Worker('webhook-relay', 'hooks.example.com/*', 4521, 3.1, 'Degraded'),
];

String _thousands(int n) {
  final s = '$n';
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

class _TableDemo extends StatefulWidget {
  const _TableDemo();

  @override
  State<_TableDemo> createState() => _TableDemoState();
}

class _TableDemoState extends State<_TableDemo> {
  KumoTableSort _sort = const KumoTableSort('requests', KumoTableSortDirection.descending);
  Set<Object> _selected = {'auth-proxy'};
  String? _opened;
  bool _loading = false;
  bool _failed = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<_Worker> get _sorted {
    final list = [..._workers];
    int compare(_Worker a, _Worker b) => switch (_sort.columnId) {
          'name' => a.name.compareTo(b.name),
          'errors' => a.errors.compareTo(b.errors),
          _ => a.requests.compareTo(b.requests),
        };
    list.sort(_sort.direction == KumoTableSortDirection.ascending ? compare : (a, b) => compare(b, a));
    return list;
  }

  List<KumoTableColumn<_Worker>> _columns({bool actions = false}) => [
        KumoTableColumn(
          id: 'name',
          label: 'Worker',
          sortable: true,
          width: const KumoTableColumnWidth.flex(2, 140),
          cell: (context, w) => Text(w.name),
        ),
        KumoTableColumn(
          id: 'route',
          label: 'Route',
          width: const KumoTableColumnWidth.flex(2, 180),
          cell: (context, w) => KumoText(w.route, variant: KumoTextVariant.monoSecondary),
        ),
        KumoTableColumn(
          id: 'requests',
          label: 'Requests',
          numeric: true,
          sortable: true,
          width: const KumoTableColumnWidth.fixed(110),
          cell: (context, w) => Text(_thousands(w.requests)),
        ),
        KumoTableColumn(
          id: 'errors',
          label: 'Errors',
          numeric: true,
          sortable: true,
          width: const KumoTableColumnWidth.fixed(90),
          cell: (context, w) => Text('${w.errors.toStringAsFixed(1)}%'),
        ),
        KumoTableColumn(
          id: 'status',
          label: 'Status',
          width: const KumoTableColumnWidth.fixed(120),
          cell: (context, w) => Row(
            mainAxisSize: MainAxisSize.min,
            spacing: KumoSpace.s1_5,
            children: [
              KumoIcon(
                switch (w.status) {
                  'Active' => KumoIcons.checkCircle,
                  'Paused' => KumoIcons.pauseCircle,
                  _ => KumoIcons.warningCircle,
                },
                size: 14,
                color: switch (w.status) {
                  'Active' => KumoColor.textSuccess,
                  'Paused' => KumoColor.textSubtle,
                  _ => KumoColor.textWarning,
                },
              ),
              Flexible(child: Text(w.status)),
            ],
          ),
        ),
        if (actions)
          KumoTableColumn(
            id: 'actions',
            label: '',
            pin: KumoTableColumnPin.end,
            showInCards: false,
            width: const KumoTableColumnWidth.fixed(56),
            align: KumoTableAlign.end,
            cell: (context, w) => KumoButton(
              icon: KumoIcons.dotsThree,
              shape: KumoButtonShape.square,
              size: KumoButtonSize.sm,
              variant: KumoButtonVariant.ghost,
              semanticLabel: 'Actions for ${w.name}',
              onPress: () => setState(() => _opened = '${w.name} actions'),
            ),
          ),
      ];

  void _reload({required bool fail}) {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _failed = false;
    });
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = fail;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sorted;
    return _Page(children: [
      DemoSection(
        title: 'Sorting and selection',
        caption: 'Sample data. Press a header to sort, a checkbox to select, a row to open it. '
            'Scroll sideways on a phone; the actions column stays pinned.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s2,
          children: [
            KumoLayerCard(
              padding: EdgeInsets.zero,
              child: KumoTable<_Worker>(
                rows: rows,
                columns: _columns(actions: true),
                rowId: (w) => w.name,
                rowLabel: (w) => w.name,
                sort: _sort,
                onSortChange: (s) => setState(() => _sort = s),
                selected: _selected,
                onSelectionChange: (ids) => setState(() => _selected = ids),
                onRowPress: (w) => setState(() => _opened = w.name),
                semanticLabel: 'Workers',
              ),
            ),
            KumoText(
              '${_selected.length} selected${_opened == null ? '' : ', last opened: $_opened'}',
              variant: KumoTextVariant.secondary,
              size: KumoTextSize.sm,
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Compact header and rows',
        caption: 'Kumo\'s compact header on bg-kumo-elevated, with 8px row padding.',
        child: KumoLayerCard(
          padding: EdgeInsets.zero,
          child: KumoTable<_Worker>(
            rows: rows.take(3).toList(),
            columns: _columns(),
            headerVariant: KumoTableHeaderVariant.compact,
            density: KumoTableDensity.compact,
            sort: _sort,
            onSortChange: (s) => setState(() => _sort = s),
          ),
        ),
      ),
      DemoSection(
        title: 'Cards on phones',
        caption: 'layout: KumoTableLayout.cards stacks each row as a card. KumoTableLayout.auto switches below 768px.',
        child: KumoTable<_Worker>(
          rows: rows.take(3).toList(),
          columns: _columns(),
          layout: KumoTableLayout.cards,
          rowId: (w) => w.name,
          rowLabel: (w) => w.name,
          selected: _selected,
          onSelectionChange: (ids) => setState(() => _selected = ids),
        ),
      ),
      DemoSection(
        title: 'Lazy rows with a sticky header',
        caption: '1,000 sample rows in a 320px box. Only visible rows are built; the header stays above them.',
        child: KumoLayerCard(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 320,
            child: KumoTable<int>(
              rows: List.generate(1000, (i) => i),
              columns: [
                KumoTableColumn(id: 'record', label: 'DNS record', cell: (context, i) => Text('host-$i.example.com')),
                KumoTableColumn(id: 'type', label: 'Type', width: const KumoTableColumnWidth.fixed(72), cell: (context, i) => Text(i.isEven ? 'A' : 'AAAA')),
                KumoTableColumn(
                  id: 'ttl',
                  label: 'TTL',
                  numeric: true,
                  width: const KumoTableColumnWidth.fixed(80),
                  cell: (context, i) => Text('${300 + (i % 5) * 60}'),
                ),
              ],
            ),
          ),
        ),
      ),
      DemoSection(
        title: 'Empty, loading and error',
        caption: 'Every data view needs these. Copy names the cause and the next step.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s4,
          children: [
            Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
              KumoButton(label: 'Reload', icon: KumoIcons.arrowsClockwise, onPress: () => _reload(fail: false)),
              KumoButton(label: 'Reload with an error', onPress: () => _reload(fail: true)),
            ]),
            KumoLayerCard(
              padding: EdgeInsets.zero,
              child: KumoTable<_Worker>(
                rows: _failed ? const [] : rows.take(2).toList(),
                columns: _columns(),
                loading: _loading,
                error: _failed
                    ? KumoTablePlaceholder(
                        icon: KumoIcons.warningCircle,
                        iconColor: KumoColor.textDanger,
                        title: 'Could not load Workers',
                        description: 'The request timed out. Check your connection, then retry.',
                        action: KumoButton(label: 'Retry', onPress: () => _reload(fail: false)),
                      )
                    : null,
              ),
            ),
            KumoLayerCard(
              padding: EdgeInsets.zero,
              child: KumoTable<_Worker>(
                rows: const [],
                columns: _columns(),
                empty: KumoTablePlaceholder(
                  icon: KumoIcons.cloud,
                  title: 'No Workers yet',
                  description: 'Deploy a Worker with Wrangler to see it here.',
                  action: KumoButton(label: 'Create Worker', variant: KumoButtonVariant.primary, onPress: () {}),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

const _workerSource = '''export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // Serve resized images from the R2 bucket.
    const object = await env.ASSETS.get(url.pathname.slice(1));
    if (object === null) {
      return new Response("Not found", { status: 404 });
    }
    return new Response(object.body, {
      headers: { "cache-control": "public, max-age=86400" },
    });
  },
} satisfies ExportedHandler<Env>;''';

const _wrangler = '''name = "image-resizer"
main = "src/index.ts"
compatibility_date = "2026-01-01"

[[r2_buckets]]
binding = "ASSETS"
bucket_name = "assets"''';

class _CodeHighlightedDemo extends StatefulWidget {
  const _CodeHighlightedDemo();

  @override
  State<_CodeHighlightedDemo> createState() => _CodeHighlightedDemoState();
}

class _CodeHighlightedDemoState extends State<_CodeHighlightedDemo> {
  bool _wrap = false;

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      const DemoSection(
        title: 'TypeScript',
        caption: 'Line numbers, lines 5 and 6 highlighted, and a copy button.',
        child: KumoCodeHighlighted(
          code: _workerSource,
          lang: 'ts',
          showLineNumbers: true,
          highlightLines: [5, 6],
          showCopyButton: true,
        ),
      ),
      DemoSection(
        title: 'Long lines',
        caption: 'Long lines scroll sideways with a fade on the cut-off edge, or wrap.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s2,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KumoButton(
                label: _wrap ? 'Scroll long lines' : 'Wrap long lines',
                size: KumoButtonSize.sm,
                onPress: () => setState(() => _wrap = !_wrap),
              ),
            ),
            KumoCodeHighlighted(
              code: 'curl -X POST "https://api.cloudflare.com/client/v4/zones/023e105f4ecef8ad9ca31a8372d0c353/purge_cache" '
                  '-H "Authorization: Bearer \$CLOUDFLARE_API_TOKEN" --data \'{"purge_everything":true}\'',
              lang: 'bash',
              wrap: _wrap,
              showCopyButton: true,
            ),
          ],
        ),
      ),
      const DemoSection(
        title: 'Languages',
        caption: 'TOML, JSON, YAML, CSS, HTML and diff. Unknown languages render as plain text.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoCodeHighlighted(code: _wrangler, lang: 'toml'),
            KumoCodeHighlighted(
              code: '{\n  "name": "image-resizer",\n  "private": true,\n  "scripts": { "deploy": "wrangler deploy" }\n}',
              lang: 'json',
            ),
            KumoCodeHighlighted(
              code: 'on: push\njobs:\n  deploy:\n    runs-on: ubuntu-latest\n    steps:\n      - run: npx wrangler deploy # sample',
              lang: 'yaml',
            ),
            KumoCodeHighlighted(code: '.banner {\n  padding: 12px 16px;\n  color: #1447e6;\n}', lang: 'css'),
            KumoCodeHighlighted(code: '<a href="/workers" class="link">Workers &amp; Pages</a>', lang: 'html'),
            KumoCodeHighlighted(code: '-compatibility_date = "2025-06-01"\n+compatibility_date = "2026-01-01"', lang: 'diff'),
            KumoCodeHighlighted(code: 'IDENTIFICATION DIVISION.', lang: 'cobol'),
          ],
        ),
      ),
      const DemoSection(
        title: 'Plain variant',
        caption: 'No frame or padding, for code inside another surface.',
        child: KumoLayerCard(
          child: KumoCodeHighlighted(code: 'npx wrangler r2 bucket create assets', lang: 'sh', variant: KumoCodeVariant.plain),
        ),
      ),
    ]);
  }
}

class _CodeDemo extends StatelessWidget {
  const _CodeDemo();

  @override
  Widget build(BuildContext context) {
    return const _Page(children: [
      DemoSection(title: 'Bare', caption: 'Kumo Code: text-kumo-subtle, 13px on 20px lines.', child: KumoCode(code: 'npx wrangler deploy')),
      DemoSection(
        title: 'Block',
        caption: 'Kumo Code.Block, with a copy button.',
        child: KumoCode.block(code: 'npm create cloudflare@latest -- image-resizer', showCopyButton: true),
      ),
      DemoSection(
        title: 'Template values',
        caption: 'Highlighted values stand out; the copy button copies the filled-in text.',
        child: KumoCode.block(
          code: 'export CLOUDFLARE_ACCOUNT_ID={{account}}\nexport CLOUDFLARE_API_TOKEN={{token}}',
          values: {
            'account': KumoCodeValue('023e105f4ecef8ad9ca31a8372d0c353'),
            'token': KumoCodeValue('your-api-token', highlight: true),
          },
          showLineNumbers: true,
          showCopyButton: true,
        ),
      ),
    ]);
  }
}

class _ClipboardTextDemo extends StatefulWidget {
  const _ClipboardTextDemo();

  @override
  State<_ClipboardTextDemo> createState() => _ClipboardTextDemoState();
}

class _ClipboardTextDemoState extends State<_ClipboardTextDemo> {
  int _copies = 0;

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      DemoSection(
        title: 'Sizes',
        caption: 'sm 26px, base 36px, lg 40px (the default). Sample values.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            for (final s in KumoClipboardTextSize.values)
              KumoClipboardText(text: '023e105f4ecef8ad9ca31a8372d0c353', size: s, onCopy: () => setState(() => _copies++)),
            KumoText('Copied $_copies times', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          ],
        ),
      ),
      const DemoSection(
        title: 'Masked',
        caption: 'Hidden until revealed. The full value is copied either way.',
        child: KumoClipboardText(text: 'cf_sample_7Hq2xK9mZpL4', masked: true, block: true),
      ),
      const DemoSection(
        title: 'Shortened value',
        caption: 'Shows a short form and copies the full token with textToCopy.',
        child: KumoClipboardText(text: 'cf_sample_7Hq2...', textToCopy: 'cf_sample_7Hq2xK9mZpL4'),
      ),
      const DemoSection(
        title: 'Tooltip mode',
        caption: 'A tooltip on hover; after a copy, a Copied bubble that bumps on every repeat.',
        child: KumoClipboardText(
          text: 'npx wrangler deploy',
          tooltip: KumoClipboardTextTooltip(text: 'Copy command', copiedText: 'Command copied'),
        ),
      ),
      const DemoSection(
        title: 'Long values',
        caption: 'Truncated with an ellipsis; block fills the width.',
        child: KumoClipboardText(text: 'https://assets.example.com/images/2026/hero-banner-wide-2400.webp', block: true),
      ),
    ]);
  }
}

class _InlineCopyTextDemo extends StatelessWidget {
  const _InlineCopyTextDemo();

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return _Page(children: [
      const DemoSection(
        title: 'Identifier',
        caption: 'The icon appears on hover and focus with a mouse, and is always shown on touch screens.',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: KumoInlineCopyText(
            'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5',
            copyLabel: 'Copy database ID',
            copiedLabel: 'Database ID copied',
          ),
        ),
      ),
      DemoSection(
        title: 'Resource row',
        caption: 'Inside a table, hovering the row reveals the icon.',
        child: KumoLayerCard(
          padding: EdgeInsets.zero,
          child: KumoTable<(String, String)>(
            rows: const [
              ('production-db', 'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5'),
              ('staging-db', '1c0e44a9-7b1d-4f0c-9e2a-5d6f7a8b9c0d'),
            ],
            columns: [
              KumoTableColumn(id: 'name', label: 'D1 database', cell: (context, r) => Text(r.$1)),
              KumoTableColumn(
                id: 'id',
                label: 'ID',
                width: const KumoTableColumnWidth.flex(2, 200),
                cell: (context, r) => KumoInlineCopyText(r.$2, copyLabel: 'Copy ID of ${r.$1}', copiedLabel: 'ID copied'),
              ),
            ],
          ),
        ),
      ),
      DemoSection(
        title: 'Rich content',
        caption: 'Show any content and copy a separate value.',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: KumoInlineCopyText.rich(
            value: 'f86b3f10-32e9-4db7-ae95-84a1b2c3d4e5',
            copyLabel: 'Copy database ID',
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Database ID: '),
              TextSpan(text: 'f86b3f10...', style: kumo.text(weight: KumoTypography.medium)),
            ])),
          ),
        ),
      ),
    ]);
  }
}

class _GridDemo extends StatelessWidget {
  const _GridDemo();

  Widget _tile(String title, String body) => KumoLayerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: [
            KumoText(title, bold: true),
            KumoText(body, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      DemoSection(
        title: 'twoUp',
        caption: 'One column on phones, two from 768px. Cells in a row share a height.',
        child: KumoGrid(variant: KumoGridVariant.twoUp, children: [
          _tile('Workers', 'Run code at the edge.'),
          _tile('R2', 'Object storage without egress fees, for images, backups and build artifacts.'),
        ]),
      ),
      DemoSection(
        title: 'threeUp, small gap',
        caption: '1, then 2 from 768px, then 3 from 1024px.',
        child: KumoGrid(variant: KumoGridVariant.threeUp, gap: KumoGridGap.sm, children: [
          _tile('DNS', '12 records'),
          _tile('Caching', 'Standard'),
          _tile('SSL/TLS', 'Full (strict)'),
        ]),
      ),
      DemoSection(
        title: 'twoOne',
        caption: 'Two thirds and one third from 768px.',
        child: KumoGrid(variant: KumoGridVariant.twoOne, children: [
          _tile('Overview', 'Main content takes two thirds.'),
          _tile('Details', 'The sidebar takes one.'),
        ]),
      ),
      DemoSection(
        title: 'Explicit columns',
        caption: 'KumoGridColumns(base: 2, md: 4): two on phones, four from 768px.',
        child: KumoGrid(
          columns: const KumoGridColumns(base: 2, md: 4),
          gap: KumoGridGap.sm,
          children: [for (final name in ['assets', 'backups', 'logs', 'uploads']) _tile(name, 'R2 bucket')],
        ),
      ),
      DemoSection(
        title: 'fourUp with mobile dividers',
        caption: 'Stacked items are separated by a hairline while the grid is one column.',
        child: KumoGrid(
          variant: KumoGridVariant.fourUp,
          mobileDivider: true,
          children: [
            for (final (title, body) in [
              ('Requests', 'Sample: 1.2M'),
              ('Bandwidth', 'Sample: 48 GB'),
              ('Cached', 'Sample: 82%'),
              ('Threats', 'Sample: 310'),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  KumoText(title, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
                  KumoText(body, variant: KumoTextVariant.heading),
                ],
              ),
          ],
        ),
      ),
    ]);
  }
}

const _bundle = [
  KumoTreeNode(
    id: 'src',
    label: 'src',
    icon: KumoIcons.folder,
    expandedIcon: KumoIcons.folderOpen,
    children: [
      KumoTreeNode(id: 'src/index.ts', label: 'index.ts', icon: KumoIcons.fileTs),
      KumoTreeNode(
        id: 'src/lib',
        label: 'lib',
        icon: KumoIcons.folder,
        expandedIcon: KumoIcons.folderOpen,
        children: [
          KumoTreeNode(id: 'src/lib/resize.ts', label: 'resize.ts', icon: KumoIcons.fileTs),
          KumoTreeNode(id: 'src/lib/cache.ts', label: 'cache.ts', icon: KumoIcons.fileTs),
        ],
      ),
    ],
  ),
  KumoTreeNode(
    id: 'assets',
    label: 'assets (loads on expand)',
    icon: KumoIcons.folder,
    expandedIcon: KumoIcons.folderOpen,
    hasChildren: true,
  ),
  KumoTreeNode(id: 'wrangler.toml', label: 'wrangler.toml', icon: KumoIcons.file),
  KumoTreeNode(id: 'package.json', label: 'package.json', icon: KumoIcons.file),
];

class _TreeDemo extends StatefulWidget {
  const _TreeDemo();

  @override
  State<_TreeDemo> createState() => _TreeDemoState();
}

class _TreeDemoState extends State<_TreeDemo> {
  Set<Object> _expanded = {'src'};
  Object? _value = 'src/index.ts';
  bool _guides = true;

  Future<List<KumoTreeNode>> _loadAssets(KumoTreeNode node) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      KumoTreeNode(id: 'assets/logo.svg', label: 'logo.svg', icon: KumoIcons.fileSvg),
      KumoTreeNode(id: 'assets/hero.webp', label: 'hero.webp', icon: KumoIcons.fileImage),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      DemoSection(
        title: 'Worker bundle',
        caption: 'Sample files. Press to select and expand. With a keyboard: arrows move, Right expands, Left collapses.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: KumoButton(
                label: _guides ? 'Hide guides' : 'Show guides',
                size: KumoButtonSize.sm,
                onPress: () => setState(() => _guides = !_guides),
              ),
            ),
            KumoLayerCard(
              padding: const EdgeInsets.all(KumoSpace.s2),
              child: KumoTree(
                nodes: _bundle,
                expanded: _expanded,
                onExpandedChange: (ids) => setState(() => _expanded = ids),
                value: _value,
                onValueChange: (id) => setState(() => _value = id),
                loadChildren: _loadAssets,
                showGuides: _guides,
                semanticLabel: 'Worker files',
              ),
            ),
            KumoText('Selected: ${_value ?? 'none'}', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          ],
        ),
      ),
    ]);
  }
}

class _TimelineDemo extends StatefulWidget {
  const _TimelineDemo();

  @override
  State<_TimelineDemo> createState() => _TimelineDemoState();
}

class _TimelineDemoState extends State<_TimelineDemo> {
  String? _opened;

  @override
  Widget build(BuildContext context) {
    return _Page(children: [
      DemoSection(
        title: 'Deployment history',
        caption: 'Sample events for a Worker. Each status pairs a tint with its own icon.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoTimeline(
              semanticLabel: 'Deployment history',
              items: [
                const KumoTimelineItem(
                  title: 'Deploying version 8f2c1a0',
                  time: 'Now',
                  description: 'Gradual rollout at 10% of traffic',
                  status: KumoTimelineStatus.active,
                  statusLabel: 'In progress',
                ),
                KumoTimelineItem(
                  title: 'Deployed version 7d1e9b3',
                  time: '2 h ago',
                  description: 'image-resizer, 100% of traffic',
                  status: KumoTimelineStatus.success,
                  statusLabel: 'Succeeded',
                  onPress: () => setState(() => _opened = '7d1e9b3'),
                  semanticLabel: 'Open deployment 7d1e9b3',
                ),
                const KumoTimelineItem(
                  title: 'Build failed',
                  time: 'Yesterday',
                  description: 'wrangler.toml is missing compatibility_date.',
                  status: KumoTimelineStatus.danger,
                  statusLabel: 'Failed',
                  content: KumoCode.block(code: 'Error: compatibility_date is required'),
                ),
                const KumoTimelineItem(
                  title: 'Secret API_TOKEN rotated',
                  time: 'Mar 2',
                  status: KumoTimelineStatus.info,
                  statusLabel: 'Info',
                ),
                const KumoTimelineItem(
                  title: 'Error rate above 2%',
                  time: 'Mar 1',
                  status: KumoTimelineStatus.warning,
                  statusLabel: 'Warning',
                ),
                const KumoTimelineItem(title: 'Worker created', time: 'Feb 27'),
              ],
            ),
            if (_opened != null) KumoText('Opened deployment $_opened', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          ],
        ),
      ),
    ]);
  }
}
