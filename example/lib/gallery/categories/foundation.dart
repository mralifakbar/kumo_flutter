import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Buttons, text, loaders, tooltips, cards and the overlay primitives the
/// other categories are built on. All resource names are sample data.
final KumoDemoCategory foundationCategory = KumoDemoCategory(
  title: 'Foundation',
  description: 'Buttons, text, loaders, tooltips, cards and the overlay primitives.',
  icon: KumoIcons.cube,
  demos: [
    KumoDemo(
      title: 'KumoButton',
      description: 'Six variants, four sizes, icon-only shapes, loading and disabled.',
      docPath: 'doc/components/KumoButton.md',
      builder: (_) => const _ButtonDemo(),
    ),
    KumoDemo(
      title: 'KumoText',
      description: 'Every variant on the Kumo scale.',
      docPath: 'doc/components/KumoText.md',
      builder: (_) => const _TextDemo(),
    ),
    KumoDemo(
      title: 'KumoLoader',
      description: 'Three sizes; it moves only while it is on screen.',
      docPath: 'doc/components/KumoLoader.md',
      builder: (_) => const _LoaderDemo(),
    ),
    KumoDemo(
      title: 'KumoTooltip',
      description: 'Hover, keyboard focus or long press a control to see its label.',
      docPath: 'doc/components/KumoTooltip.md',
      builder: (_) => const _TooltipDemo(),
    ),
    KumoDemo(
      title: 'KumoLayerCard',
      description: 'Plain, layered and pressable cards.',
      docPath: 'doc/components/KumoLayerCard.md',
      builder: (_) => const _LayerCardDemo(),
    ),
    KumoDemo(
      title: 'KumoAnchoredOverlay',
      description: 'A custom popup that flips, follows its trigger and scales from it.',
      docPath: 'doc/components/KumoAnchoredOverlay.md',
      builder: (_) => const _OverlayDemo(),
    ),
    KumoDemo(
      title: 'KumoSheet',
      description: 'A bottom sheet that follows the finger and snaps by velocity.',
      docPath: 'doc/components/KumoSheet.md',
      builder: (_) => const _SheetDemo(),
    ),
  ],
);

class _ButtonDemo extends StatefulWidget {
  const _ButtonDemo();

  @override
  State<_ButtonDemo> createState() => _ButtonDemoState();
}

class _ButtonDemoState extends State<_ButtonDemo> {
  bool _deploying = false;
  int _presses = 0;

  Future<void> _deploy() async {
    setState(() => _deploying = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _deploying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Variants',
          caption: 'Pressed $_presses times',
          child: Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
            KumoButton(label: 'Create Worker', variant: KumoButtonVariant.primary, onPress: () => setState(() => _presses++)),
            KumoButton(label: 'Cancel', onPress: () => setState(() => _presses++)),
            KumoButton(label: 'Edit', variant: KumoButtonVariant.ghost, onPress: () => setState(() => _presses++)),
            KumoButton(label: 'Filter', variant: KumoButtonVariant.outline, onPress: () => setState(() => _presses++)),
            KumoButton(label: 'Revoke token', variant: KumoButtonVariant.secondaryDestructive, onPress: () => setState(() => _presses++)),
            KumoButton(label: 'Delete zone', variant: KumoButtonVariant.destructive, onPress: () => setState(() => _presses++)),
          ]),
        ),
        DemoSection(
          title: 'Sizes',
          child: Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final s in KumoButtonSize.values) KumoButton(label: 'Size ${s.name}', size: s, onPress: () {}),
          ]),
        ),
        DemoSection(
          title: 'Icons',
          child: Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
            KumoButton(label: 'Add record', icon: KumoIcons.plus, onPress: () {}),
            KumoButton(label: 'Actions', endIcon: KumoIcons.caretDown, onPress: () {}),
            KumoButton(icon: KumoIcons.copy, shape: KumoButtonShape.square, title: 'Copy token', onPress: () {}),
            KumoButton(icon: KumoIcons.gear, shape: KumoButtonShape.circle, title: 'Settings', onPress: () {}),
            KumoRefreshButton(onPress: () {}),
          ]),
        ),
        DemoSection(
          title: 'Loading and disabled',
          caption: 'The label stays while loading, so the width does not jump.',
          child: Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
            KumoButton(
              label: _deploying ? 'Deploying' : 'Deploy',
              variant: KumoButtonVariant.primary,
              loading: _deploying,
              onPress: _deploy,
            ),
            const KumoButton(label: 'Disabled'),
            const KumoButton(label: 'Disabled primary', variant: KumoButtonVariant.primary),
          ]),
        ),
        DemoSection(
          title: 'Block',
          child: KumoButton(label: 'Deploy to production', variant: KumoButtonVariant.primary, block: true, onPress: () {}),
        ),
      ],
    );
  }
}

class _TextDemo extends StatelessWidget {
  const _TextDemo();

  @override
  Widget build(BuildContext context) {
    return const KumoLayerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KumoSpace.s2,
        children: [
          KumoText('Workers', variant: KumoTextVariant.heading, size: KumoTextSize.lg),
          KumoText('Recent deployments', variant: KumoTextVariant.heading),
          KumoText('image-resizer was deployed to production.'),
          KumoText('Deployed by the CI token', bold: true),
          KumoText('3 minutes ago', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          KumoText('Route matched', variant: KumoTextVariant.success),
          KumoText('Build failed: missing binding', variant: KumoTextVariant.error),
          KumoText('wrangler.toml', variant: KumoTextVariant.mono),
          KumoText('a1b2c3d4', variant: KumoTextVariant.monoSecondary),
        ],
      ),
    );
  }
}

class _LoaderDemo extends StatelessWidget {
  const _LoaderDemo();

  @override
  Widget build(BuildContext context) {
    return const KumoLayerCard(
      child: Row(
        spacing: KumoSpace.s6,
        children: [
          KumoLoader(size: KumoLoaderSize.sm),
          KumoLoader(),
          KumoLoader(size: KumoLoaderSize.lg),
          Expanded(child: KumoText('Loading deployments', variant: KumoTextVariant.secondary)),
        ],
      ),
    );
  }
}

class _TooltipDemo extends StatelessWidget {
  const _TooltipDemo();

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: [
      for (final side in KumoSide.values)
        KumoTooltip(
          content: 'Opens on the ${side.name}',
          side: side,
          child: KumoButton(label: side.name, onPress: () {}),
        ),
      const KumoTooltip(
        content: 'Served from the edge cache',
        child: Padding(padding: EdgeInsets.all(KumoSpace.s2), child: KumoIcon(KumoIcons.info, semanticLabel: 'About caching')),
      ),
    ]);
  }
}

class _LayerCardDemo extends StatefulWidget {
  const _LayerCardDemo();

  @override
  State<_LayerCardDemo> createState() => _LayerCardDemoState();
}

class _LayerCardDemoState extends State<_LayerCardDemo> {
  int _opened = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s4,
      children: [
        const KumoLayerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s1_5,
            children: [
              KumoText('Web Analytics', variant: KumoTextVariant.heading),
              KumoText('Measure site traffic without changing your code.', variant: KumoTextVariant.secondary),
            ],
          ),
        ),
        KumoLayerCard.layered(children: [
          KumoLayerCardSecondary(
            trailing: KumoButton(label: 'Configure', size: KumoButtonSize.sm, onPress: () {}),
            child: const Text('Caching'),
          ),
          const KumoLayerCardPrimary(child: KumoText('Cache static assets at the edge for 4 hours.')),
        ]),
        KumoLayerCard(
          onPress: () => setState(() => _opened++),
          semanticLabel: 'Open image-resizer',
          child: Row(children: [
            const Expanded(child: KumoText('image-resizer', bold: true)),
            KumoText('Opened $_opened times', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
            const SizedBox(width: KumoSpace.s2),
            const KumoIcon(KumoIcons.caretRight, color: KumoColor.textSubtle),
          ]),
        ),
      ],
    );
  }
}

class _OverlayDemo extends StatefulWidget {
  const _OverlayDemo();

  @override
  State<_OverlayDemo> createState() => _OverlayDemoState();
}

class _OverlayDemoState extends State<_OverlayDemo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: KumoAnchoredOverlay(
        open: _open,
        align: KumoAlign.start,
        onDismiss: () => setState(() => _open = false),
        overlayBuilder: (context, placement) => KumoPopupSurface(
          placement: placement,
          showArrow: true,
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s1_5,
              children: [
                const KumoText('Popup', variant: KumoTextVariant.heading),
                KumoText('This popup sits on the ${placement.side.name} side. Tap outside or press Escape to close.', variant: KumoTextVariant.secondary),
              ],
            ),
          ),
        ),
        child: KumoButton(label: _open ? 'Close popup' : 'Open popup', onPress: () => setState(() => _open = !_open)),
      ),
    );
  }
}

class _SheetDemo extends StatefulWidget {
  const _SheetDemo();

  @override
  State<_SheetDemo> createState() => _SheetDemoState();
}

class _SheetDemoState extends State<_SheetDemo> {
  String? _region;

  Future<void> _open() async {
    const regions = ['Frankfurt', 'Singapore', 'Sao Paulo', 'Ashburn'];
    final picked = await showKumoSheet<String>(
      context: context,
      semanticLabel: 'Choose a region',
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(KumoSpace.s4, KumoSpace.s2, KumoSpace.s4, KumoSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s1,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: KumoSpace.s2),
              child: KumoText('Choose a region', variant: KumoTextVariant.heading, headingLevel: 2),
            ),
            for (final r in regions)
              KumoMenuRow(
                label: r,
                selected: r == _region,
                trailing: r == _region ? const KumoIcon(KumoIcons.check) : null,
                onPress: () => KumoSheetScope.closeFrom(context, r),
              ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _region = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: KumoSpace.s3,
      children: [
        KumoButton(label: 'Choose region', icon: KumoIcons.globe, onPress: _open),
        Expanded(child: KumoText(_region == null ? 'No region chosen' : 'Region: $_region', variant: KumoTextVariant.secondary)),
      ],
    );
  }
}
