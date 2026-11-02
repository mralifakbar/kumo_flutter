import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

/// Shares the gallery's theme mode and variant with every page.
class GallerySettings extends InheritedWidget {
  const GallerySettings({
    super.key,
    required this.mode,
    required this.variant,
    required this.onModeChange,
    required this.onVariantChange,
    required super.child,
  });

  final KumoThemeMode mode;
  final KumoThemeVariant variant;
  final ValueChanged<KumoThemeMode> onModeChange;
  final ValueChanged<KumoThemeVariant> onVariantChange;

  static GallerySettings? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<GallerySettings>();

  @override
  bool updateShouldNotify(GallerySettings oldWidget) => mode != oldWidget.mode || variant != oldWidget.variant;
}

/// A labeled button that cycles the theme mode: System, Light, Dark.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = GallerySettings.maybeOf(context);
    if (settings == null) return const SizedBox.shrink();
    final (label, icon) = switch (settings.mode) {
      KumoThemeMode.system => ('System', KumoIcons.circleHalf),
      KumoThemeMode.light => ('Light', KumoIcons.sun),
      KumoThemeMode.dark => ('Dark', KumoIcons.moon),
    };
    final next = KumoThemeMode.values[(settings.mode.index + 1) % KumoThemeMode.values.length];
    // Phones with large text get the icon alone; the tooltip and the
    // accessible name still say which theme is on.
    final compact = context.kumoIsNarrow && MediaQuery.textScalerOf(context).scale(14) > 18;
    return KumoButton(
      label: compact ? null : 'Theme: $label',
      icon: icon,
      shape: compact ? KumoButtonShape.square : KumoButtonShape.base,
      title: compact ? 'Theme: $label' : null,
      size: KumoButtonSize.sm,
      variant: KumoButtonVariant.ghost,
      semanticLabel: 'Theme: $label. Switch to ${next.name}',
      onPress: () => settings.onModeChange(next),
    );
  }
}
