import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Step diagrams: request paths, deploy stages and routing rules. Every
/// Worker, zone and binding name here is sample data.
final KumoDemoCategory flowCategory = KumoDemoCategory(
  title: 'Flow diagrams',
  description: 'Step diagrams with connectors, parallel branches and anchors.',
  icon: KumoIcons.flowArrow,
  demos: [
    KumoDemo(
      title: 'KumoFlowDiagram',
      description: 'Orientation, alignment, panning large diagrams, RTL and live structure changes.',
      docPath: 'doc/components/KumoFlowDiagram.md',
      builder: (_) => const _DiagramDemo(),
    ),
    KumoDemo(
      title: 'KumoFlowNode',
      description: 'Default, custom, pressable, selected, disabled and status nodes.',
      docPath: 'doc/components/KumoFlowNode.md',
      builder: (_) => const _NodeDemo(),
    ),
    KumoDemo(
      title: 'KumoFlowParallel',
      description: 'Branches that fan out from one step and join at the next.',
      docPath: 'doc/components/KumoFlowParallel.md',
      builder: (_) => const _ParallelDemo(),
    ),
    KumoDemo(
      title: 'KumoFlowList',
      description: 'Branches with more than one step.',
      docPath: 'doc/components/KumoFlowList.md',
      builder: (_) => const _ListDemo(),
    ),
    KumoDemo(
      title: 'KumoFlowAnchor',
      description: 'Connectors that meet a header and leave from a footer.',
      docPath: 'doc/components/KumoFlowAnchor.md',
      builder: (_) => const _AnchorDemo(),
    ),
  ],
);

/// A rounded frame so the diagram's panning area is visible.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(KumoRadius.lg),
      border: Border.all(color: context.kumo.colors.hairline),
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(KumoRadius.lg), child: child),
  );
}

const _requestPath = [
  KumoFlowNode(label: 'Request'),
  KumoFlowNode(label: 'WAF'),
  KumoFlowNode(label: 'image-resizer'),
  KumoFlowNode(label: 'Origin'),
];

class _DiagramDemo extends StatefulWidget {
  const _DiagramDemo();

  @override
  State<_DiagramDemo> createState() => _DiagramDemoState();
}

enum _RoutesState { loaded, loading, empty }

class _DiagramDemoState extends State<_DiagramDemo> {
  KumoFlowOrientation _orientation = KumoFlowOrientation.auto;
  KumoFlowOrientation? _resolved;
  bool _cache = false;
  _RoutesState _routes = _RoutesState.loaded;

  Future<void> _reload() async {
    setState(() => _routes = _RoutesState.loading);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _routes = _RoutesState.loaded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s8,
      children: [
        const DemoSection(
          title: 'Sequential',
          caption: 'A request path from the edge to the origin. On a phone it pans sideways.',
          child: KumoFlowDiagram(semanticLabel: 'Request path', children: _requestPath),
        ),
        DemoSection(
          title: 'Orientation',
          caption:
              'Auto picks horizontal when the diagram fits and vertical when it does not. '
              'Showing: ${_resolved?.name ?? '...'}.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              Wrap(
                spacing: KumoSpace.s2,
                runSpacing: KumoSpace.s2,
                children: [
                  for (final o in KumoFlowOrientation.values)
                    KumoButton(
                      label: switch (o) {
                        KumoFlowOrientation.horizontal => 'Horizontal',
                        KumoFlowOrientation.vertical => 'Vertical',
                        KumoFlowOrientation.auto => 'Auto',
                      },
                      size: KumoButtonSize.sm,
                      variant: o == _orientation ? KumoButtonVariant.primary : KumoButtonVariant.secondary,
                      onPress: () => setState(() => _orientation = o),
                    ),
                ],
              ),
              KumoFlowDiagram(
                orientation: _orientation,
                align: KumoFlowAlign.center,
                onGeometryChange: (g) {
                  if (g.orientation != _resolved) setState(() => _resolved = g.orientation);
                },
                children: const [
                  KumoFlowNode(label: 'Request'),
                  KumoFlowParallel(
                    children: [
                      KumoFlowNode(label: 'WAF'),
                      KumoFlowNode(label: 'Rate limit'),
                    ],
                  ),
                  KumoFlowNode(label: 'image-resizer'),
                  KumoFlowNode(label: 'Origin'),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Panning large diagrams',
          caption: 'Drag or flick sideways, or scroll with a trackpad. The fading edge shows there is more.',
          child: _Frame(
            child: KumoFlowDiagram(
              semanticLabel: 'Deploy pipeline',
              children: [
                for (final step in [
                  'Push to main', 'Install', 'Lint', 'Test', 'Build', //
                  'Upload assets', 'Deploy preview', 'Smoke test', 'Promote', 'Purge cache',
                ])
                  KumoFlowNode(label: step),
              ],
            ),
          ),
        ),
        const DemoSection(
          title: 'Centered alignment',
          caption: 'Nodes of different heights centered on one line.',
          child: KumoFlowDiagram(
            align: KumoFlowAlign.center,
            children: [
              KumoFlowNode(semanticLabel: 'Entry point', render: _Dot()),
              KumoFlowNode(label: 'my-worker'),
              KumoFlowNode(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: KumoSpace.s4),
                  child: Text('Taller node'),
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Adding and removing steps',
          caption: 'Connectors re-route as the structure changes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              KumoButton(
                label: _cache ? 'Remove cache step' : 'Add cache step',
                size: KumoButtonSize.sm,
                onPress: () => setState(() => _cache = !_cache),
              ),
              KumoFlowDiagram(
                children: [
                  const KumoFlowNode(id: 'request', label: 'Request'),
                  if (_cache) const KumoFlowNode(id: 'cache', label: 'Cache'),
                  const KumoFlowNode(id: 'origin', label: 'Origin'),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Loading and empty states',
          caption: 'The caller shows these in place of the diagram.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              Wrap(
                spacing: KumoSpace.s2,
                runSpacing: KumoSpace.s2,
                children: [
                  KumoButton(
                    label: 'Reload routes',
                    size: KumoButtonSize.sm,
                    loading: _routes == _RoutesState.loading,
                    onPress: _reload,
                  ),
                  KumoButton(
                    label: 'Show empty zone',
                    size: KumoButtonSize.sm,
                    onPress: () => setState(() => _routes = _RoutesState.empty),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: switch (_routes) {
                  _RoutesState.loaded => const KumoFlowDiagram(
                    semanticLabel: 'Routes for example.com',
                    children: [
                      KumoFlowNode(label: 'example.com/*'),
                      KumoFlowNode(label: 'image-resizer'),
                    ],
                  ),
                  _RoutesState.loading => const Padding(
                    padding: EdgeInsets.symmetric(vertical: KumoSpace.s16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: KumoSpace.s2,
                      children: [
                        KumoLoader(size: KumoLoaderSize.sm, semanticLabel: 'Loading routes'),
                        KumoText('Loading routes for example.com', variant: KumoTextVariant.secondary),
                      ],
                    ),
                  ),
                  _RoutesState.empty => const Padding(
                    padding: EdgeInsets.symmetric(vertical: KumoSpace.s12),
                    child: KumoText(
                      'No routes on example.com yet. Add a route to a Worker to see its request path.',
                      variant: KumoTextVariant.secondary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Right to left',
          caption: 'The flow starts on the right and the connectors mirror.',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: KumoFlowDiagram(
              children: [
                KumoFlowNode(label: 'Request'),
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'WAF'),
                    KumoFlowNode(label: 'Bot score'),
                  ],
                ),
                KumoFlowNode(label: 'Origin'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
    width: KumoSpace.s4,
    height: KumoSpace.s4,
    decoration: BoxDecoration(color: context.kumo.colors.hairline, shape: BoxShape.circle),
  );
}

/// Kumo's custom node demo: `rounded-lg bg-kumo-contrast px-3 py-2 font-medium text-kumo-inverse`.
class _ContrastPill extends StatelessWidget {
  const _ContrastPill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s2),
    decoration: BoxDecoration(color: context.kumo.colors.contrast, borderRadius: BorderRadius.circular(KumoRadius.lg)),
    child: KumoText(label, bold: true, color: KumoColor.textInverse),
  );
}

class _NodeDemo extends StatefulWidget {
  const _NodeDemo();

  @override
  State<_NodeDemo> createState() => _NodeDemoState();
}

enum _StepStatus { passed, running, failed }

class _NodeDemoState extends State<_NodeDemo> {
  String _selected = 'waf';
  _StepStatus _deploy = _StepStatus.failed;

  static const _details = {
    'request': 'Requests to assets.example.com arrive at the nearest data center.',
    'waf': 'Managed rules block known exploits before the request reaches the Worker.',
    'worker': 'image-resizer reads the width parameter and resizes on the fly.',
    'r2': 'Originals are read from the R2 bucket named assets.',
  };

  Future<void> _retry() async {
    setState(() => _deploy = _StepStatus.running);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _deploy = _StepStatus.passed);
  }

  KumoFlowNode _select(String id, String label) =>
      KumoFlowNode(id: id, label: label, selected: _selected == id, onPress: () => setState(() => _selected = id));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s8,
      children: [
        DemoSection(
          title: 'Pressable and selected',
          caption: 'Press a step to see what it does.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s2,
            children: [
              KumoFlowDiagram(
                orientation: KumoFlowOrientation.auto,
                align: KumoFlowAlign.center,
                padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s6),
                children: [
                  _select('request', 'Request'),
                  _select('waf', 'WAF'),
                  _select('worker', 'image-resizer'),
                  _select('r2', 'R2: assets'),
                ],
              ),
              KumoText(_details[_selected]!, variant: KumoTextVariant.secondary),
            ],
          ),
        ),
        const DemoSection(
          title: 'Custom nodes',
          caption: 'render replaces the card; the diagram still measures and connects it.',
          child: KumoFlowDiagram(
            align: KumoFlowAlign.center,
            children: [
              KumoFlowNode(semanticLabel: 'Entry point', render: _Dot()),
              KumoFlowNode(semanticLabel: 'my-worker', render: _ContrastPill('my-worker')),
            ],
          ),
        ),
        const DemoSection(
          title: 'Disabled',
          caption: 'Connectors to a disabled node are greyed out; the label says why.',
          child: KumoFlowDiagram(
            children: [
              KumoFlowNode(label: 'Request'),
              KumoFlowParallel(
                children: [
                  KumoFlowNode(label: 'Primary handler'),
                  KumoFlowNode(label: 'Backup handler, paused', disabled: true),
                ],
              ),
              KumoFlowNode(label: 'Response'),
            ],
          ),
        ),
        DemoSection(
          title: 'Step status',
          caption: 'Status is an icon plus text, never color alone.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              KumoFlowDiagram(
                orientation: KumoFlowOrientation.auto,
                children: [
                  const KumoFlowNode(
                    semanticLabel: 'Build, passed',
                    child: _Status(icon: KumoIcons.checkCircle, color: KumoColor.textSuccess, text: 'Build passed'),
                  ),
                  KumoFlowNode(
                    semanticLabel: switch (_deploy) {
                      _StepStatus.passed => 'Deploy, passed',
                      _StepStatus.running => 'Deploy, running',
                      _StepStatus.failed => 'Deploy, failed',
                    },
                    child: switch (_deploy) {
                      _StepStatus.passed => const _Status(
                        icon: KumoIcons.checkCircle,
                        color: KumoColor.textSuccess,
                        text: 'Deploy passed',
                      ),
                      _StepStatus.running => const Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: KumoSpace.s1_5,
                        children: [
                          KumoLoader(size: KumoLoaderSize.sm, semanticLabel: 'Deploying'),
                          Text('Deploying'),
                        ],
                      ),
                      _StepStatus.failed => const _Status(
                        icon: KumoIcons.warningCircle,
                        color: KumoColor.textDanger,
                        text: 'Deploy failed',
                      ),
                    },
                  ),
                  KumoFlowNode(label: 'Purge cache', disabled: _deploy != _StepStatus.passed),
                ],
              ),
              KumoButton(
                label: 'Retry deploy',
                size: KumoButtonSize.sm,
                icon: KumoIcons.arrowsClockwise,
                disabled: _deploy == _StepStatus.passed,
                loading: _deploy == _StepStatus.running,
                onPress: _retry,
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Nodes that change size',
          caption: 'Expand a node; the connectors follow its new center.',
          child: KumoFlowDiagram(
            align: KumoFlowAlign.center,
            orientation: KumoFlowOrientation.auto,
            children: [
              KumoFlowNode(label: 'Incoming request'),
              KumoFlowParallel(
                children: [
                  KumoFlowNode(
                    id: 'auth',
                    render: _Expandable(title: 'Auth service', body: 'Validates JWTs and session cookies.'),
                  ),
                  KumoFlowNode(
                    id: 'rate',
                    render: _Expandable(title: 'Rate limiter', body: 'Sample rule: 100 requests a minute per IP.'),
                  ),
                ],
              ),
              KumoFlowNode(label: 'Route to origin'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.color, required this.text});
  final IconData icon;
  final KumoColor color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: KumoSpace.s1_5,
    children: [
      KumoIcon(icon, color: color),
      Text(text),
    ],
  );
}

/// Kumo's expandable node demo: a header button that reveals a body.
class _Expandable extends StatefulWidget {
  const _Expandable({required this.title, required this.body});
  final String title;
  final String body;

  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: kumo.colors.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(kumo.colors.hairline),
        boxShadow: KumoShadow.sm.boxShadows,
      ),
      // Shrink to the header, grow with the body, never past 200px.
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KumoPressable(
              onPress: () => setState(() => _open = !_open),
              expanded: _open,
              semanticLabel: widget.title,
              borderRadius: BorderRadius.circular(KumoRadius.lg),
              builder: (context, state) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: KumoSpace.s2,
                  children: [
                    Flexible(child: KumoText(widget.title, size: KumoTextSize.sm, bold: true)),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: KumoMotion.duration(context, KumoDurations.moderate),
                      curve: KumoCurves.standard,
                      child: const KumoIcon(KumoIcons.caretDown, color: KumoColor.textSubtle),
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: kumo.colors.hairline)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s2),
                  child: KumoText(widget.body, size: KumoTextSize.sm, variant: KumoTextVariant.secondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ParallelDemo extends StatelessWidget {
  const _ParallelDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s8,
      children: [
        DemoSection(
          title: 'Branches',
          caption: 'The step before connects to every branch; every branch connects to the step after.',
          child: KumoFlowDiagram(
            orientation: KumoFlowOrientation.auto,
            children: [
              KumoFlowNode(label: 'Request'),
              KumoFlowParallel(
                children: [
                  KumoFlowNode(label: 'WAF'),
                  KumoFlowNode(label: 'Bot score'),
                  KumoFlowNode(label: 'Rate limit'),
                ],
              ),
              KumoFlowNode(label: 'Origin'),
            ],
          ),
        ),
        DemoSection(
          title: 'Fan in and fan out',
          caption: 'Two triggers start one Worker, which writes to three places.',
          child: _Frame(
            child: KumoFlowDiagram(
              children: [
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'HTTP trigger'),
                    KumoFlowNode(label: 'Cron trigger'),
                  ],
                ),
                KumoFlowNode(label: 'Process request'),
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'Log analytics'),
                    KumoFlowNode(label: 'Update cache'),
                    KumoFlowNode(label: 'Send notification'),
                  ],
                ),
                KumoFlowNode(label: 'Complete'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Align end',
          caption: 'Branches of different widths end on the same line.',
          child: KumoFlowDiagram(
            orientation: KumoFlowOrientation.auto,
            children: [
              KumoFlowNode(label: 'Start'),
              KumoFlowParallel(
                align: KumoFlowParallelAlign.end,
                children: [
                  KumoFlowNode(label: 'DNS'),
                  KumoFlowNode(label: 'Page Rules'),
                  KumoFlowNode(label: 'Transform Rules'),
                ],
              ),
              KumoFlowNode(label: 'End'),
            ],
          ),
        ),
        DemoSection(
          title: 'Back-to-back groups',
          caption: 'Two parallel groups in a row are not connected to each other.',
          child: _Frame(
            child: KumoFlowDiagram(
              children: [
                KumoFlowNode(label: 'Incoming request'),
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'Validate headers'),
                    KumoFlowNode(label: 'Check API token'),
                  ],
                ),
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'Write to D1'),
                    KumoFlowNode(label: 'Update KV'),
                  ],
                ),
                KumoFlowNode(label: 'Return response'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Vertical',
          caption: 'Branches sit side by side.',
          child: KumoFlowDiagram(
            orientation: KumoFlowOrientation.vertical,
            align: KumoFlowAlign.center,
            children: [
              KumoFlowNode(label: 'Start'),
              KumoFlowParallel(
                children: [
                  KumoFlowNode(label: 'Branch A'),
                  KumoFlowNode(label: 'Branch B'),
                  KumoFlowNode(label: 'Branch C'),
                ],
              ),
              KumoFlowNode(label: 'End'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListDemo extends StatelessWidget {
  const _ListDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s8,
      children: [
        DemoSection(
          title: 'Branches with several steps',
          caption: 'Each list is one branch; outside steps connect to its first and last node.',
          child: _Frame(
            child: KumoFlowDiagram(
              children: [
                KumoFlowNode(label: 'Request'),
                KumoFlowParallel(
                  children: [
                    KumoFlowList(
                      children: [
                        KumoFlowNode(label: 'Cache lookup'),
                        KumoFlowNode(label: 'Serve from cache'),
                      ],
                    ),
                    KumoFlowNode(label: 'Bypass cache'),
                  ],
                ),
                KumoFlowNode(label: 'Response'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Nested groups',
          caption: 'A list can start with its own parallel group.',
          child: _Frame(
            child: KumoFlowDiagram(
              children: [
                KumoFlowParallel(
                  children: [
                    KumoFlowList(
                      children: [
                        KumoFlowNode(label: 'Client users'),
                        KumoFlowNode(label: 'Engineering access'),
                      ],
                    ),
                    KumoFlowList(
                      children: [
                        KumoFlowParallel(
                          children: [
                            KumoFlowNode(label: 'All authenticated users'),
                            KumoFlowNode(label: 'Site users'),
                          ],
                        ),
                        KumoFlowNode(label: 'Contractor access'),
                      ],
                    ),
                  ],
                ),
                KumoFlowNode(label: 'Destinations'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnchorDemo extends StatelessWidget {
  const _AnchorDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s8,
      children: [
        DemoSection(
          title: 'Header in, footer out',
          caption: 'Traffic arrives at the Worker name and leaves from its bindings.',
          child: _Frame(
            child: KumoFlowDiagram(
              children: [
                KumoFlowNode(label: 'Load balancer'),
                KumoFlowNode(semanticLabel: 'my-worker, 2 bindings', render: _WorkerCard()),
                KumoFlowParallel(
                  children: [
                    KumoFlowNode(label: 'DATABASE'),
                    KumoFlowNode(label: 'OTHER_SERVICE'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kumo's anchor demo node: an overlay surface with the Worker name as the
/// incoming anchor and a raised bindings row as the outgoing one.
class _WorkerCard extends StatelessWidget {
  const _WorkerCard();

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kumo.colors.overlay,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(kumo.colors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KumoFlowAnchor(
            type: KumoFlowAnchorType.end,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KumoSpace.s10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: KumoSpace.s2_5),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 1,
                  child: KumoText('my-worker', variant: KumoTextVariant.secondary),
                ),
              ),
            ),
          ),
          KumoFlowAnchor(
            type: KumoFlowAnchorType.start,
            child: Container(
              margin: const EdgeInsetsDirectional.fromSTEB(KumoSpace.s1_5, 0, KumoSpace.s1_5, KumoSpace.s1_5),
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1_5),
              decoration: BoxDecoration(
                color: kumo.colors.base,
                borderRadius: BorderRadius.circular(KumoRadius.sm),
                border: KumoRing.border(kumo.colors.hairline),
                boxShadow: KumoShadow.sm.boxShadows,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s3,
                children: [
                  KumoText('Bindings'),
                  KumoText('2', variant: KumoTextVariant.secondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
