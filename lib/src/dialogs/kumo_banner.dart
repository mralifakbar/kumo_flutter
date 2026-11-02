import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../feedback/kumo_loader.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../utils/kumo_color_utils.dart';
import '../system/kumo_size_reveal.dart';

/// Banner styles from Kumo's `banner.tsx`.
enum KumoBannerVariant {
  /// Kumo's `default`: informational, blue tint.
  info,

  /// Kumo's `alert`: cautionary, amber tint.
  alert,

  /// Kumo's `error`: critical problems, red tint. Announced when it appears.
  error,

  /// Kumo's `secondary`: neutral contextual notes.
  secondary,
}

/// Banner sizes.
enum KumoBannerSize {
  /// Title over description, 14px text, `px-4 py-3`, small actions.
  base,

  /// Compact, for dialogs and tight spaces: title and description share a
  /// line, 13px text, `px-3 py-2`, extra-small actions.
  sm,
}

/// Emphasis of a [KumoBannerAction], tinted with the banner's accent.
enum KumoBannerActionVariant {
  /// Filled accent gradient, for the main action.
  primary,

  /// Transparent with an accent outline.
  secondary,

  /// Text only, with a faint accent hover. Dismiss buttons use it.
  ghost,
}

class _BannerScope extends InheritedWidget {
  const _BannerScope({required this.variant, required this.size, required super.child});

  final KumoBannerVariant variant;
  final KumoBannerSize size;

  @override
  bool updateShouldNotify(_BannerScope oldWidget) => variant != oldWidget.variant || size != oldWidget.size;
}

/// Tailwind `neutral-700`, Kumo's accent for actions in secondary banners.
const Color _neutral700 = Color(0xFF404040);

Color _accent(KumoThemeData kumo, KumoBannerVariant variant) => switch (variant) {
  KumoBannerVariant.info => kumo.colors.info,
  KumoBannerVariant.alert => kumo.colors.warning,
  KumoBannerVariant.error => kumo.colors.danger,
  KumoBannerVariant.secondary => _neutral700,
};

Color _textColor(KumoThemeData kumo, KumoBannerVariant variant) => switch (variant) {
  KumoBannerVariant.info => kumo.colors.textInfo,
  KumoBannerVariant.alert => kumo.colors.textWarning,
  KumoBannerVariant.error => kumo.colors.textDanger,
  KumoBannerVariant.secondary => kumo.colors.textDefault.withValues(alpha: 0.7),
};

/// Kumo's `Banner`: a full-width message bar for information, warnings and
/// errors that belong to a page or a section.
///
/// ```dart
/// KumoBanner(
///   variant: KumoBannerVariant.alert,
///   icon: KumoIcons.warningFill,
///   title: 'SSL certificate expires in 6 days',
///   description: 'Renew it to keep serving example.com over HTTPS.',
///   actions: [KumoBannerAction(label: 'Renew certificate', onPress: renew)],
///   onDismiss: () => setState(() => _showBanner = false),
/// )
/// ```
///
/// The title carries the message, so status never rests on color alone.
/// Actions sit at the end of the row; when the banner is narrower than
/// 360px they move under the text. [KumoBannerAction]s pick up the banner's
/// accent color and size on their own.
///
/// Pressing the X collapses the banner (height and opacity, content clipped
/// at its size) so the content below slides up into its place, then calls
/// [onDismiss]. Drive [open] to show and hide a banner that stays mounted:
/// it expands from and collapses to its top edge, reversing mid-flight.
class KumoBanner extends StatefulWidget {
  const KumoBanner({
    super.key,
    this.title,
    this.description,
    this.child,
    this.icon,
    this.actions = const [],
    this.variant = KumoBannerVariant.info,
    this.size = KumoBannerSize.base,
    this.onDismiss,
    this.dismissLabel,
    this.open = true,
  }) : assert(title != null || description != null || child != null, 'Give the banner a title, description or child');

  /// The message in medium weight.
  final String? title;

  /// Supporting text, 13px.
  final String? description;

  /// Custom description content, shown in place of [description]. It
  /// inherits the banner's text color.
  final Widget? child;

  /// Leading icon in the accent color, optically the size of the text.
  /// Kumo pairs filled icons with banners (`KumoIcons.infoFill`).
  final IconData? icon;

  /// Buttons at the end of the banner, usually [KumoBannerAction]s.
  final List<Widget> actions;
  final KumoBannerVariant variant;
  final KumoBannerSize size;

  /// Shows a ghost X action. The banner collapses, then this runs; the
  /// parent removes the banner or sets [open] to false.
  final VoidCallback? onDismiss;

  /// Accessible name of the X. Defaults to [KumoStrings.dismiss].
  final String? dismissLabel;

  /// Shown while true. Changes expand or collapse the banner instead of
  /// popping it in or out; a banner mounted with true appears at rest.
  final bool open;

  @override
  State<KumoBanner> createState() => _KumoBannerState();
}

class _KumoBannerState extends State<KumoBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _presence;
  late final CurvedAnimation _curve;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _presence = AnimationController(vsync: this, value: widget.open ? 1 : 0, duration: KumoDurations.moderate);
    _curve = CurvedAnimation(parent: _presence, curve: KumoCurves.standard);
  }

  @override
  void didUpdateWidget(KumoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    if (widget.open) _dismissed = false;
    _animateTo(widget.open ? 1 : 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _presence.dispose();
    super.dispose();
  }

  TickerFuture _animateTo(double target) {
    if (KumoMotion.reduceMotion(context)) {
      _presence.value = target;
      return TickerFuture.complete();
    }
    return _presence.animateTo(target);
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _animateTo(0).whenCompleteOrCancel(() {
      // A parent that reopened the banner mid-collapse keeps it.
      if (mounted && _dismissed && _presence.value == 0) widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = _BannerContent(banner: widget, onDismiss: widget.onDismiss == null ? null : _dismiss);
    // One tree at rest and in flight, so the X keeps focus while it collapses.
    return AnimatedBuilder(
      animation: _presence,
      builder: (context, child) => ExcludeSemantics(
        excluding: _presence.value <= 0,
        child: IgnorePointer(ignoring: _presence.value < 1, child: child),
      ),
      child: KumoSizeReveal(
        sizeFactor: _curve,
        child: FadeTransition(opacity: _curve, child: content),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.banner, required this.onDismiss});

  final KumoBanner banner;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final KumoBanner(:title, :description, :child, :icon, :actions, :variant, :size, :dismissLabel) = banner;
    final kumo = context.kumo;
    final compact = size == KumoBannerSize.sm;
    final textSize = compact ? KumoTextSize.sm : KumoTextSize.base;
    final color = _textColor(kumo, variant);
    final background = switch (variant) {
      KumoBannerVariant.info => kumo.colors.infoTint,
      KumoBannerVariant.alert => kumo.colors.warningTint,
      KumoBannerVariant.error => kumo.colors.dangerTint,
      KumoBannerVariant.secondary => kumo.colors.contrast.withValues(alpha: 0.05),
    };
    const lineHeight = 1.375;
    final baseStyle = kumo.typography.body(size: textSize, color: color, height: lineHeight);
    final titleStyle = baseStyle.copyWith(fontWeight: KumoTypography.medium);
    final descriptionStyle = kumo.typography.body(size: KumoTextSize.sm, color: color, height: lineHeight);

    final allActions = [
      ...actions,
      if (onDismiss != null)
        KumoBannerAction(
          icon: KumoIcons.x,
          variant: KumoBannerActionVariant.ghost,
          semanticLabel: dismissLabel ?? context.kumoStrings.dismiss,
          onPress: onDismiss,
        ),
    ];

    final descriptionWidget = child != null
        ? DefaultTextStyle(style: descriptionStyle, child: child)
        : (description != null ? Text(description, style: descriptionStyle) : null);

    final Widget text;
    if (compact) {
      text = Wrap(
        spacing: KumoSpace.s1_5,
        children: [
          if (title != null) Text(title, style: titleStyle),
          ?descriptionWidget,
        ],
      );
    } else {
      text = Padding(
        padding: EdgeInsets.only(top: title == null ? KumoSpace.px : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s0_5,
          children: [
            if (title != null) Text(title, style: titleStyle),
            ?descriptionWidget,
          ],
        ),
      );
    }

    final rowGap = compact ? KumoSpace.s2 : KumoSpace.s3;
    Widget content = text;
    if (allActions.isNotEmpty) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final actionRow = Wrap(
            spacing: KumoSpace.s2,
            runSpacing: KumoSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: allActions,
          );
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: KumoSpace.s2,
              children: [text, actionRow],
            );
          }
          return Row(
            spacing: rowGap,
            children: [
              Expanded(child: text),
              actionRow,
            ],
          );
        },
      );
    }

    final iconSize = textSize.fontSize;
    final iconBox = compact ? 1.25 * iconSize : lineHeight * iconSize;

    return _BannerScope(
      variant: variant,
      size: size,
      child: Semantics(
        container: true,
        liveRegion: variant == KumoBannerVariant.error,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(compact ? KumoRadius.md : KumoRadius.lg),
          ),
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: KumoSpace.s3, vertical: KumoSpace.s2)
                : const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s3),
            child: DefaultTextStyle(
              style: baseStyle,
              child: Row(
                crossAxisAlignment: compact && allActions.isEmpty
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                spacing: compact ? KumoSpace.s2 : KumoSpace.s3,
                children: [
                  if (icon != null)
                    SizedBox(
                      height: iconBox,
                      child: Center(
                        widthFactor: 1,
                        child: KumoIcon(icon, size: iconSize, dangerouslySetColor: _accent(kumo, variant)),
                      ),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kumo's `Banner.Action`: a button tinted with the accent of the
/// [KumoBanner] it sits in, sized from the banner (small in a base banner,
/// extra small in a compact one).
///
/// ```dart
/// KumoBannerAction(label: 'Retry', onPress: retry)
/// KumoBannerAction(label: 'Go to billing', variant: KumoBannerActionVariant.secondary, onPress: openBilling)
/// KumoBannerAction(icon: KumoIcons.x, variant: KumoBannerActionVariant.ghost, semanticLabel: 'Dismiss', onPress: hide)
/// ```
class KumoBannerAction extends StatelessWidget {
  const KumoBannerAction({
    super.key,
    this.label,
    this.icon,
    required this.onPress,
    this.variant = KumoBannerActionVariant.primary,
    this.semanticLabel,
    this.loading = false,
    this.disabled = false,
  }) : assert(label != null || semanticLabel != null, 'Icon-only banner actions need a semanticLabel');

  final String? label;
  final IconData? icon;

  /// Null renders the action disabled.
  final VoidCallback? onPress;
  final KumoBannerActionVariant variant;
  final String? semanticLabel;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final scope = context.dependOnInheritedWidgetOfExactType<_BannerScope>();
    final bannerVariant = scope?.variant ?? KumoBannerVariant.info;
    final size = scope?.size == KumoBannerSize.sm ? KumoButtonSize.xs : KumoButtonSize.sm;
    final accent = _accent(kumo, bannerVariant);
    final inherit = _textColor(kumo, bannerVariant);
    final secondaryBanner = bannerVariant == KumoBannerVariant.secondary;
    final isDisabled = disabled || onPress == null;
    final iconOnly = label == null;
    final radius = BorderRadius.circular(size.radius);
    final primary = variant == KumoBannerActionVariant.primary;

    final fg = primary ? const Color(0xFFFFFFFF) : inherit;
    final iconColor = primary ? fg : (secondaryBanner ? c.textSubtle : accent);

    return KumoPressable(
      onPress: isDisabled ? null : onPress,
      disabled: isDisabled,
      loading: loading,
      borderRadius: radius,
      semanticLabel: semanticLabel,
      excludeChildSemantics: iconOnly || semanticLabel != null,
      builder: (context, state) {
        final hover = state.active;
        Gradient? gradient;
        Color? background;
        Border? border;
        var shadows = const <BoxShadow>[];
        switch (variant) {
          case KumoBannerActionVariant.primary:
            gradient = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [KumoColorUtils.mix(accent, const Color(0xFFFFFFFF), hover ? 0.3 : 0.15), accent],
            );
            border = KumoRing.border(KumoColorUtils.mix(accent, const Color(0xFF000000), 0.1));
            shadows = KumoShadow.xs.boxShadows;
          case KumoBannerActionVariant.secondary:
            background = hover ? (secondaryBanner ? c.contrast : accent).withValues(alpha: 0.1) : null;
            border = KumoRing.border(secondaryBanner ? c.focus.withValues(alpha: 0.2) : accent.withValues(alpha: 0.5));
          case KumoBannerActionVariant.ghost:
            background = hover ? (secondaryBanner ? c.contrast : accent).withValues(alpha: 0.1) : null;
        }
        if (state.focused) border = null;

        final textStyle = kumo.typography.body(
          size: size.fontSize == 12 ? KumoTextSize.xs : KumoTextSize.base,
          weight: KumoTypography.medium,
          color: fg,
          height: 1.25,
        );
        final leading = loading
            ? KumoLoader(dimension: 14, dangerouslySetColor: iconColor)
            : (icon != null ? KumoIcon(icon!, size: size.iconSize, dangerouslySetColor: iconColor) : null);

        Widget inner;
        if (iconOnly) {
          inner = Center(child: leading);
        } else {
          inner = Padding(
            padding: EdgeInsetsDirectional.only(
              start: leading != null ? size.iconLeadingPadding : size.paddingX,
              end: size.paddingX,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: size.gap,
              children: [
                ?leading,
                Flexible(
                  child: Transform.translate(
                    offset: Offset(0, -size.textLift),
                    child: Text(
                      label!,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget surface = Container(
          height: size.height,
          width: iconOnly ? size.height : null,
          decoration: BoxDecoration(
            gradient: gradient,
            color: background,
            borderRadius: radius,
            border: border,
            boxShadow: shadows,
          ),
          child: inner,
        );
        if (primary) {
          // The 1px top highlight of Kumo's emphasis buttons.
          surface = Stack(
            children: [
              surface,
              Positioned(
                left: size.radius / 2,
                right: size.radius / 2,
                top: 0,
                height: 1,
                child: ColoredBox(color: KumoColorUtils.mix(accent, const Color(0xFFFFFFFF), 0.3)),
              ),
            ],
          );
        }
        if (isDisabled) surface = Opacity(opacity: 0.5, child: surface);
        return surface;
      },
    );
  }
}
