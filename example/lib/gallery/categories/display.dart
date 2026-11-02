import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Badges, empty states, meters, skeletons, progress, avatars, uptime
/// trackers, key chips and separators. Every name, figure and status here
/// is sample data.
final KumoDemoCategory displayCategory = KumoDemoCategory(
  title: 'Display',
  description:
      'Badges, empty states, meters, progress, avatars, uptime trackers and key chips.',
  icon: KumoIcons.tag,
  demos: [
    KumoDemo(
      title: 'KumoBadge',
      description:
          'Semantic, color and subtle variants, dot status, icons and a linked badge.',
      docPath: 'doc/components/KumoBadge.md',
      builder: (_) => const _BadgeDemo(),
    ),
    KumoDemo(
      title: 'KumoEmpty',
      description:
          'Three sizes, a copyable command, and a list that moves between empty, loading, error and filled.',
      docPath: 'doc/components/KumoEmpty.md',
      builder: (_) => const _EmptyDemo(),
    ),
    KumoDemo(
      title: 'KumoMeter',
      description:
          'Quota meters with custom values and thresholds that change tone and add a status line.',
      docPath: 'doc/components/KumoMeter.md',
      builder: (_) => const _MeterDemo(),
    ),
    KumoDemo(
      title: 'KumoSkeletonLine',
      description:
          'Static placeholder lines, with the shimmer tied to a loading flag.',
      docPath: 'doc/components/KumoSkeletonLine.md',
      builder: (_) => const _SkeletonDemo(),
    ),
    KumoDemo(
      title: 'KumoProgress',
      description:
          'Linear and circular progress, indeterminate only while preparing.',
      docPath: 'doc/components/KumoProgress.md',
      builder: (_) => const _ProgressDemo(),
    ),
    KumoDemo(
      title: 'KumoAvatar',
      description:
          'Initials fallback, sizes, shapes, presence and an overlapping group.',
      docPath: 'doc/components/KumoAvatar.md',
      builder: (_) => const _AvatarDemo(),
    ),
    KumoDemo(
      title: 'KumoTracker',
      description:
          'Day-by-day uptime with a tooltip per bar, a legend and its loading, error and empty states.',
      docPath: 'doc/components/KumoTracker.md',
      builder: (_) => const _TrackerDemo(),
    ),
    KumoDemo(
      title: 'KumoKbd',
      description:
          'Key chips and shortcuts, named the way each platform names them.',
      docPath: 'doc/components/KumoKbd.md',
      builder: (_) => const _KbdDemo(),
    ),
    KumoDemo(
      title: 'KumoSeparator',
      description: 'Horizontal, labeled and vertical hairlines.',
      docPath: 'doc/components/KumoSeparator.md',
      builder: (_) => const _SeparatorDemo(),
    ),
  ],
);

const _sampleNote = 'Sample data.';

Widget _wrap(List<Widget> children) => Wrap(
  spacing: KumoSpace.s2,
  runSpacing: KumoSpace.s2,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

class _BadgeDemo extends StatefulWidget {
  const _BadgeDemo();

  @override
  State<_BadgeDemo> createState() => _BadgeDemoState();
}

class _BadgeDemoState extends State<_BadgeDemo> {
  int _opened = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Semantic variants',
          child: _wrap(const [
            KumoBadge('Primary'),
            KumoBadge('Secondary', variant: KumoBadgeVariant.secondary),
            KumoBadge('Error', variant: KumoBadgeVariant.error),
            KumoBadge('Success', variant: KumoBadgeVariant.success),
            KumoBadge('Warning', variant: KumoBadgeVariant.warning),
            KumoBadge('Info', variant: KumoBadgeVariant.info),
            KumoBadge('Outline', variant: KumoBadgeVariant.outline),
            KumoBadge('Beta', variant: KumoBadgeVariant.beta),
          ]),
        ),
        DemoSection(
          title: 'Color variants',
          caption:
              'For product categories where a semantic color would say the wrong thing.',
          child: _wrap(const [
            KumoBadge('Neutral', variant: KumoBadgeVariant.neutral),
            KumoBadge('Red', variant: KumoBadgeVariant.red),
            KumoBadge('Green', variant: KumoBadgeVariant.green),
            KumoBadge('Orange', variant: KumoBadgeVariant.orange),
            KumoBadge('Teal', variant: KumoBadgeVariant.teal),
            KumoBadge('Blue', variant: KumoBadgeVariant.blue),
            KumoBadge('Purple', variant: KumoBadgeVariant.purple),
          ]),
        ),
        DemoSection(
          title: 'Subtle and inverted',
          child: _wrap(const [
            KumoBadge('Teal subtle', variant: KumoBadgeVariant.tealSubtle),
            KumoBadge('Orange subtle', variant: KumoBadgeVariant.orangeSubtle),
            KumoBadge(
              'Neutral subtle',
              variant: KumoBadgeVariant.neutralSubtle,
            ),
            KumoBadge('Inverted', variant: KumoBadgeVariant.inverted),
          ]),
        ),
        DemoSection(
          title: 'Dot status',
          caption: 'The label names the state; the dot only reinforces it.',
          child: _wrap(const [
            KumoBadge(
              'Healthy',
              variant: KumoBadgeVariant.success,
              appearance: KumoBadgeAppearance.dot,
            ),
            KumoBadge(
              'Rate limited',
              variant: KumoBadgeVariant.warning,
              appearance: KumoBadgeAppearance.dot,
            ),
            KumoBadge(
              'Down',
              variant: KumoBadgeVariant.error,
              appearance: KumoBadgeAppearance.dot,
            ),
            KumoBadge(
              'Paused',
              variant: KumoBadgeVariant.neutral,
              appearance: KumoBadgeAppearance.dot,
            ),
          ]),
        ),
        DemoSection(
          title: 'With an icon, and sizes',
          child: _wrap(const [
            KumoBadge(
              'Verified',
              variant: KumoBadgeVariant.success,
              icon: KumoIcons.checkCircle,
            ),
            KumoBadge(
              'Proxied',
              variant: KumoBadgeVariant.info,
              icon: KumoIcons.cloud,
            ),
            KumoBadge('Base'),
            KumoBadge('Large', size: KumoBadgeSize.lg),
          ]),
        ),
        const DemoSection(
          title: 'In a sentence',
          child: Row(
            spacing: KumoSpace.s2,
            children: [
              KumoText('Workers'),
              KumoBadge('New', variant: KumoBadgeVariant.secondary),
            ],
          ),
        ),
        DemoSection(
          title: 'Linked badge',
          caption: _opened == 0
              ? 'Hover to see the ring, tap to open.'
              : 'Changelog opened $_opened times.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoBadge(
              'View changelog',
              variant: KumoBadgeVariant.outline,
              isLink: true,
              onPress: () => setState(() => _opened++),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ListState { empty, loading, error, filled }

class _EmptyDemo extends StatefulWidget {
  const _EmptyDemo();

  @override
  State<_EmptyDemo> createState() => _EmptyDemoState();
}

class _EmptyDemoState extends State<_EmptyDemo> {
  _ListState _state = _ListState.empty;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _load(_ListState then) {
    _timer?.cancel();
    setState(() => _state = _ListState.loading);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _state = then);
    });
  }

  Widget _bucketList() {
    return switch (_state) {
      _ListState.empty => KumoEmpty(
        size: KumoEmptySize.sm,
        icon: KumoIcons.archive,
        title: 'No R2 buckets yet',
        description:
            'Buckets in this account appear here. Create one to store objects for your Workers.',
        contents: _wrap([
          KumoButton(
            label: 'Create bucket',
            variant: KumoButtonVariant.primary,
            icon: KumoIcons.plus,
            onPress: () => _load(_ListState.filled),
          ),
        ]),
      ),
      _ListState.loading => const KumoLayerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            KumoSkeletonLine(
              widthFactor: 0.4,
              animate: true,
              semanticLabel: 'Loading R2 buckets',
            ),
            KumoSkeletonLine(animate: true),
            KumoSkeletonLine(animate: true),
          ],
        ),
      ),
      _ListState.error => KumoEmpty(
        size: KumoEmptySize.sm,
        icon: KumoIcons.cloudSlash,
        title: 'Could not load buckets',
        description:
            'The request to the R2 API timed out. Check your connection, then retry.',
        contents: KumoButton(
          label: 'Retry',
          variant: KumoButtonVariant.primary,
          onPress: () => _load(_ListState.filled),
        ),
      ),
      _ListState.filled => const KumoLayerCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            Row(
              children: [
                Expanded(
                  child: KumoText('assets', variant: KumoTextVariant.mono),
                ),
                KumoBadge('Public', variant: KumoBadgeVariant.info),
              ],
            ),
            KumoSeparator(),
            Row(
              children: [
                Expanded(
                  child: KumoText('backups', variant: KumoTextVariant.mono),
                ),
                KumoBadge('Private', variant: KumoBadgeVariant.secondary),
              ],
            ),
          ],
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'One list, four states',
          caption: 'Switch the state of a sample bucket list. $_sampleNote',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s3,
            children: [
              _wrap([
                for (final s in _ListState.values)
                  KumoButton(
                    label: switch (s) {
                      _ListState.empty => 'Empty',
                      _ListState.loading => 'Loading',
                      _ListState.error => 'Error',
                      _ListState.filled => 'Filled',
                    },
                    size: KumoButtonSize.sm,
                    variant: _state == s
                        ? KumoButtonVariant.primary
                        : KumoButtonVariant.secondary,
                    onPress: () {
                      _timer?.cancel();
                      setState(() => _state = s);
                    },
                  ),
              ]),
              _bucketList(),
            ],
          ),
        ),
        const DemoSection(
          title: 'With a command line',
          caption: 'Tap the copy button: the check mark confirms for a second.',
          child: KumoEmpty(
            icon: KumoIcons.folderOpen,
            title: 'No Workers in this account',
            description:
                'Create a Worker from the command line, then deploy it with wrangler.',
            commandLine: 'npm create cloudflare@latest',
          ),
        ),
        for (final s in KumoEmptySize.values)
          DemoSection(
            title: 'Size ${s.name}',
            child: KumoEmpty(
              size: s,
              icon: KumoIcons.database,
              title: 'No D1 databases',
              description: 'Databases you create appear here.',
            ),
          ),
        const DemoSection(
          title: 'Minimal',
          caption: 'Only a title, for small panels.',
          child: KumoEmpty(title: 'No API tokens match "deploy"'),
        ),
      ],
    );
  }
}

class _MeterDemo extends StatefulWidget {
  const _MeterDemo();

  @override
  State<_MeterDemo> createState() => _MeterDemoState();
}

class _MeterDemoState extends State<_MeterDemo> {
  double _gb = 6;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Thresholds',
          caption:
              'Upload or delete to cross the 8 GB and 10 GB marks. The bar eases from where it is. $_sampleNote',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s3,
            children: [
              KumoMeter(
                label: 'R2 storage in assets',
                value: _gb,
                max: 10,
                customValue: '${_gb.toStringAsFixed(0)} / 10 GB',
                thresholds: const [
                  KumoMeterThreshold(
                    value: 8,
                    tone: KumoMeterTone.warning,
                    label: 'Approaching the 10 GB limit',
                  ),
                  KumoMeterThreshold(
                    value: 10,
                    tone: KumoMeterTone.danger,
                    label: 'Limit reached. Uploads are paused',
                  ),
                ],
              ),
              _wrap([
                KumoButton(
                  label: 'Upload 1 GB',
                  icon: KumoIcons.uploadSimple,
                  size: KumoButtonSize.sm,
                  disabled: _gb >= 10,
                  onPress: () => setState(() => _gb = (_gb + 1).clamp(0, 10)),
                ),
                KumoButton(
                  label: 'Delete 1 GB',
                  icon: KumoIcons.trash,
                  size: KumoButtonSize.sm,
                  disabled: _gb <= 0,
                  onPress: () => setState(() => _gb = (_gb - 1).clamp(0, 10)),
                ),
              ]),
            ],
          ),
        ),
        const DemoSection(
          title: 'Basic',
          child: KumoMeter(label: 'Storage used', value: 65),
        ),
        const DemoSection(
          title: 'Custom value',
          child: KumoMeter(
            label: 'API requests',
            value: 750,
            max: 1000,
            customValue: '750 / 1,000',
          ),
        ),
        const DemoSection(
          title: 'Hidden value',
          child: KumoMeter(label: 'Progress', value: 40, showValue: false),
        ),
        const DemoSection(
          title: 'Full',
          child: KumoMeter(label: 'Quota reached', value: 100),
        ),
        const DemoSection(
          title: 'Low',
          child: KumoMeter(label: 'Memory usage', value: 15),
        ),
        const DemoSection(
          title: 'Custom tone',
          child: KumoMeter(
            label: 'Cache hit ratio',
            value: 80,
            tone: KumoMeterTone.success,
          ),
        ),
      ],
    );
  }
}

class _SkeletonDemo extends StatefulWidget {
  const _SkeletonDemo();

  @override
  State<_SkeletonDemo> createState() => _SkeletonDemoState();
}

class _SkeletonDemoState extends State<_SkeletonDemo> {
  bool _loading = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    _timer?.cancel();
    setState(() => _loading = true);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Card loading state',
          caption: 'The shimmer runs only while the request is in flight.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              KumoButton(
                label: 'Reload zone settings',
                icon: KumoIcons.arrowClockwise,
                size: KumoButtonSize.sm,
                loading: _loading,
                onPress: _reload,
              ),
              KumoLayerCard(
                child: _loading
                    ? const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: KumoSpace.s2,
                        children: [
                          KumoSkeletonLine(
                            widthFactor: 0.5,
                            blockHeight: 24,
                            animate: true,
                            semanticLabel: 'Loading zone settings',
                          ),
                          KumoSkeletonLine(blockHeight: 21, animate: true),
                          KumoSkeletonLine(
                            blockHeight: 21,
                            minWidth: 50,
                            maxWidth: 70,
                            animate: true,
                          ),
                        ],
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: KumoSpace.s2,
                        children: [
                          KumoText(
                            'example.com',
                            variant: KumoTextVariant.heading,
                          ),
                          KumoText('SSL/TLS mode: Full (strict)'),
                          KumoText(
                            'Always Use HTTPS is on',
                            variant: KumoTextVariant.secondary,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Default',
          caption: 'Each line picks a width between 30% and 100% once.',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              KumoSkeletonLine(),
              KumoSkeletonLine(),
              KumoSkeletonLine(),
            ],
          ),
        ),
        const DemoSection(
          title: 'Width ranges',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              KumoSkeletonLine(minWidth: 80, maxWidth: 100),
              KumoSkeletonLine(minWidth: 60, maxWidth: 80),
              KumoSkeletonLine(minWidth: 40, maxWidth: 60),
            ],
          ),
        ),
        const DemoSection(
          title: 'Heights',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              KumoSkeletonLine(widthFactor: 1, height: 8),
              KumoSkeletonLine(widthFactor: 1, height: 16),
              KumoSkeletonLine(widthFactor: 1, height: 24),
              KumoSkeletonLine(widthFactor: 1, height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDemo extends StatefulWidget {
  const _ProgressDemo();

  @override
  State<_ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<_ProgressDemo> {
  // null: idle, -1: preparing (indeterminate), 0-100: uploading.
  double? _upload;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _upload = -1);
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _upload = 0);
      _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (!mounted) return t.cancel();
        setState(() => _upload = (_upload! + 9).clamp(0, 100));
        if (_upload! >= 100) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final upload = _upload;
    final running = upload != null && upload < 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Upload',
          caption:
              'Indeterminate while the upload is prepared, then the real percentage. $_sampleNote',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s3,
            children: [
              if (upload == null)
                const KumoText(
                  'No upload running.',
                  variant: KumoTextVariant.secondary,
                  size: KumoTextSize.sm,
                )
              else
                KumoProgress(
                  value: upload < 0 ? null : upload,
                  label: upload < 0
                      ? 'Preparing 1,204 objects'
                      : (upload >= 100
                            ? 'Uploaded to assets'
                            : 'Uploading to assets'),
                  showValue: true,
                  tone: upload >= 100
                      ? KumoMeterTone.success
                      : KumoMeterTone.brand,
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KumoButton(
                  label: running ? 'Uploading' : 'Upload objects',
                  icon: KumoIcons.uploadSimple,
                  loading: running,
                  onPress: _start,
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Linear sizes',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              for (final s in KumoProgressSize.values)
                KumoProgress(value: 60, size: s),
            ],
          ),
        ),
        DemoSection(
          title: 'Circular',
          child: _wrap([
            for (final s in KumoProgressSize.values)
              KumoProgress(
                value: 70,
                size: s,
                variant: KumoProgressVariant.circular,
              ),
            const KumoProgress(
              value: 35,
              variant: KumoProgressVariant.circular,
              label: 'Migrating tables',
              showValue: true,
            ),
          ]),
        ),
      ],
    );
  }
}

class _AvatarDemo extends StatefulWidget {
  const _AvatarDemo();

  @override
  State<_AvatarDemo> createState() => _AvatarDemoState();
}

class _AvatarDemoState extends State<_AvatarDemo> {
  bool _showAll = false;

  static const _team = [
    KumoAvatar(name: 'Ada Lovelace'),
    KumoAvatar(name: 'Grace Hopper'),
    KumoAvatar(name: 'Alan Turing'),
    KumoAvatar(name: 'Katherine Johnson'),
    KumoAvatar(name: 'Edsger Dijkstra'),
    KumoAvatar(name: 'Barbara Liskov'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Sizes',
          caption: 'Initials until a picture is uploaded. Sample names.',
          child: _wrap([
            for (final s in KumoAvatarSize.values)
              KumoAvatar(name: 'Ada Lovelace', size: s),
          ]),
        ),
        DemoSection(
          title: 'Shapes and fallbacks',
          child: _wrap(const [
            KumoAvatar(name: 'Grace Hopper'),
            KumoAvatar(name: 'example.com', shape: KumoAvatarShape.square),
            KumoAvatar(name: 'ops@example.com'),
            KumoAvatar(),
          ]),
        ),
        DemoSection(
          title: 'Presence',
          caption:
              'Only for live presence data. Screen readers hear the status.',
          child: _wrap([
            for (final s in KumoAvatarStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s2,
                children: [
                  KumoAvatar(name: 'Alan Turing', status: s),
                  KumoText(s.label, size: KumoTextSize.sm),
                ],
              ),
          ]),
        ),
        DemoSection(
          title: 'Group',
          caption: _showAll
              ? 'Showing all members.'
              : 'Tap the +3 chip to show everyone.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoAvatarGroup(
              avatars: _team,
              max: _showAll ? null : 3,
              onOverflowPress: () => setState(() => _showAll = true),
            ),
          ),
        ),
      ],
    );
  }
}

List<KumoTrackerDay> _sampleDays(
  int count,
  Map<int, (KumoTrackerStatus, String)> incidents,
) {
  final today = DateTime(2026, 10, 31);
  return [
    for (var i = 0; i < count; i++)
      KumoTrackerDay(
        date: today.subtract(Duration(days: count - 1 - i)),
        status: incidents[i]?.$1 ?? KumoTrackerStatus.operational,
        note: incidents[i]?.$2,
      ),
  ];
}

class _TrackerDemo extends StatefulWidget {
  const _TrackerDemo();

  @override
  State<_TrackerDemo> createState() => _TrackerDemoState();
}

class _TrackerDemoState extends State<_TrackerDemo> {
  bool _loading = false;
  bool _failed = false;
  Timer? _timer;

  static final _ninety = _sampleDays(90, {
    for (var i = 0; i < 12; i++)
      i: (KumoTrackerStatus.noData, 'Monitor not created yet'),
    31: (KumoTrackerStatus.degraded, 'Elevated 5xx responses for 22 min'),
    58: (KumoTrackerStatus.outage, 'Origin unreachable for 41 min'),
    59: (KumoTrackerStatus.degraded, 'Increased latency in one region'),
    77: (KumoTrackerStatus.degraded, 'Slow cold starts after deploy'),
  });

  static final _thirty = _sampleDays(30, {
    9: (KumoTrackerStatus.outage, 'DNS resolution failures for 12 min'),
  });

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _failed = false;
    });
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Last 90 days',
          caption:
              'Hover, tap, or long press and slide across the bars. Tab in and use the arrow keys. $_sampleNote',
          child: KumoTracker(
            label: 'image-resizer',
            valueText: '99.9% uptime',
            startLabel: '90 days ago',
            endLabel: 'Today',
            days: _ninety,
          ),
        ),
        DemoSection(
          title: 'Loading and error',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s3,
            children: [
              KumoTracker(
                label: 'api.example.com',
                valueText: _loading || _failed ? null : '99.97% uptime',
                startLabel: '30 days ago',
                endLabel: 'Today',
                loading: _loading,
                error: _failed
                    ? 'Could not load health checks for api.example.com'
                    : null,
                days: _thirty,
              ),
              _wrap([
                KumoButton(
                  label: 'Refresh checks',
                  icon: KumoIcons.arrowClockwise,
                  size: KumoButtonSize.sm,
                  loading: _loading,
                  onPress: _refresh,
                ),
                KumoButton(
                  label: 'Simulate failure',
                  size: KumoButtonSize.sm,
                  onPress: () {
                    _timer?.cancel();
                    setState(() {
                      _loading = false;
                      _failed = true;
                    });
                  },
                ),
              ]),
            ],
          ),
        ),
        const DemoSection(
          title: 'Empty',
          child: KumoTracker(label: 'staging.example.com', days: []),
        ),
      ],
    );
  }
}

class _KbdDemo extends StatelessWidget {
  const _KbdDemo();

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Widget kbd) => Row(
      children: [
        Expanded(child: KumoText(label, size: KumoTextSize.sm)),
        kbd,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Shortcuts on this platform',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              row(
                'Open command palette',
                const KumoKbd('K', modifiers: [KumoKbdModifier.mod]),
              ),
              row('Search zones', const KumoKbd('/')),
              row(
                'Purge cache',
                const KumoKbd(
                  'P',
                  modifiers: [KumoKbdModifier.mod, KumoKbdModifier.shift],
                ),
              ),
              row('Close dialog', const KumoKbd(KumoKbdKeys.escape)),
              row(
                'Move selection',
                const Wrap(
                  spacing: KumoSpace.s1,
                  children: [
                    KumoKbd(KumoKbdKeys.arrowUp),
                    KumoKbd(KumoKbdKeys.arrowDown),
                  ],
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Same shortcut, each platform',
          caption: 'mod is Command on Apple platforms and Ctrl elsewhere.',
          child: Column(
            spacing: KumoSpace.s3,
            children: [
              for (final p in [
                TargetPlatform.macOS,
                TargetPlatform.windows,
                TargetPlatform.linux,
              ])
                row(
                  p.name,
                  KumoKbd(
                    'K',
                    modifiers: const [KumoKbdModifier.mod, KumoKbdModifier.alt],
                    platform: p,
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'From a SingleActivator',
          caption: 'The hint and the binding share one definition.',
          child: row(
            'Deploy Worker',
            KumoKbd.fromActivator(
              const SingleActivator(LogicalKeyboardKey.enter, meta: true),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeparatorDemo extends StatelessWidget {
  const _SeparatorDemo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Horizontal',
          child: KumoLayerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: KumoSpace.s3,
              children: [
                KumoText('DNS records', variant: KumoTextVariant.heading),
                KumoSeparator(),
                KumoText(
                  '12 records, 3 proxied',
                  variant: KumoTextVariant.secondary,
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'With a label',
          child: KumoSeparator(label: 'or sign in with an API token'),
        ),
        DemoSection(
          title: 'Vertical',
          caption: 'In an IntrinsicHeight row, the line takes the row height.',
          child: IntrinsicHeight(
            child: Row(
              spacing: KumoSpace.s3,
              children: [
                KumoText('Workers', size: KumoTextSize.sm),
                KumoSeparator.vertical(),
                KumoText('Pages', size: KumoTextSize.sm),
                KumoSeparator.vertical(),
                KumoText('R2', size: KumoTextSize.sm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
