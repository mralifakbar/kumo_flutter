import 'package:flutter/widgets.dart';

import '../theme/kumo_theme.dart';

/// The backdrop behind dialogs and sheets: Kumo's recessed surface at 80%
/// opacity, so the page behind recedes without going black.
///
/// A tap calls [onPress]; screen readers get a "Close" button for it.
class KumoScrim extends StatelessWidget {
  const KumoScrim({super.key, this.onPress, this.opacity = 1, this.semanticLabel = 'Close'});

  final VoidCallback? onPress;

  /// Multiplies the scrim's own 80% opacity, for drag-driven dimming.
  final double opacity;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final color = kumo.colors.recessed.withValues(alpha: 0.8 * opacity.clamp(0.0, 1.0));
    // The scrim always absorbs taps so the page behind a modal stays inert.
    final scrim = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPress,
      child: ColoredBox(color: color, child: const SizedBox.expand()),
    );
    if (onPress == null) return ExcludeSemantics(child: scrim);
    return Semantics(button: true, label: semanticLabel, onTap: onPress, child: ExcludeSemantics(child: scrim));
  }
}
