import 'package:flutter/widgets.dart';

import '../system/kumo_pressable.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_typography.dart';

/// Kumo's `LayerCard`: the standard container for a block of content.
///
/// Plain form: a base surface with a 1px ring and a light shadow.
///
/// ```dart
/// KumoLayerCard(child: Text('Requests today'))
/// ```
///
/// Layered form: an elevated frame holding a [KumoLayerCardSecondary] header
/// strip and a [KumoLayerCardPrimary] content panel.
///
/// ```dart
/// KumoLayerCard.layered(children: [
///   KumoLayerCardSecondary(child: Text('Analytics')),
///   KumoLayerCardPrimary(child: Text('Measure traffic without changing your code.')),
/// ])
/// ```
///
/// Never nest one layer card inside another; use a heading and a single
/// card instead.
class KumoLayerCard extends StatelessWidget {
  const KumoLayerCard({
    super.key,
    required Widget this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: KumoSpace.s5, vertical: KumoSpace.s4),
    this.onPress,
    this.semanticLabel,
  }) : children = null;

  const KumoLayerCard.layered({super.key, required List<Widget> this.children, this.onPress, this.semanticLabel})
      : child = null,
        padding = EdgeInsets.zero;

  final Widget? child;
  final List<Widget>? children;

  /// Padding of the plain form. Vertical padding is smaller than horizontal
  /// so text looks evenly spaced (line height adds space above and below).
  final EdgeInsetsGeometry padding;

  /// Makes the whole card pressable.
  final VoidCallback? onPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    const radius = BorderRadius.all(Radius.circular(KumoRadius.lg));
    final layered = children != null;

    Widget card(bool hovered) => DecoratedBox(
          decoration: BoxDecoration(
            color: layered ? c.elevated : (hovered ? c.tint : c.base),
            borderRadius: radius,
            border: KumoRing.border(layered ? c.hairline : c.line),
            boxShadow: layered ? null : KumoShadow.xs.boxShadows,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: layered
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children!,
                  )
                : Padding(padding: padding, child: child),
          ),
        );

    if (onPress == null) return card(false);
    return KumoPressable(
      onPress: onPress,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      builder: (context, state) => card(state.active),
    );
  }
}

/// The header strip of a layered [KumoLayerCard]: medium-weight subtle text
/// on the elevated frame.
class KumoLayerCardSecondary extends StatelessWidget {
  const KumoLayerCardSecondary({super.key, required this.child, this.trailing});

  final Widget child;

  /// Actions at the end of the strip.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KumoSpace.s4, KumoSpace.s2, KumoSpace.s4, KumoSpace.s2),
      child: DefaultTextStyle(
        style: kumo.text(weight: KumoTypography.medium, color: KumoColor.textSubtle),
        child: Row(
          spacing: KumoSpace.s2,
          children: [Expanded(child: child), ?trailing],
        ),
      ),
    );
  }
}

/// The content panel of a layered [KumoLayerCard]: a base surface inset in
/// the frame, its corners concentric with the frame's.
class KumoLayerCardPrimary extends StatelessWidget {
  const KumoLayerCardPrimary({
    super.key,
    required this.child,
    this.padding = const EdgeInsetsDirectional.fromSTEB(KumoSpace.s4, KumoSpace.s4, KumoSpace.s3, KumoSpace.s4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.inset(c.fill),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
