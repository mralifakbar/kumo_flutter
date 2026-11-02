import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_menu_parts.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Breadcrumb sizes.
enum KumoBreadcrumbsSize {
  /// 40px row (`h-10`), 13px text, 2px gaps.
  sm(40, KumoTextSize.sm, 2),

  /// 48px row (`h-12`), 14px text, 4px gaps. The default.
  base(48, KumoTextSize.base, 4);

  const KumoBreadcrumbsSize(this.height, this.textSize, this.gap);
  final double height;
  final KumoTextSize textSize;
  final double gap;
}

/// What [KumoBreadcrumbs] shows below 640px (Kumo's `sm` breakpoint).
enum KumoBreadcrumbsNarrowLayout {
  /// A single back link to the parent page, the usual pattern on phones.
  back,

  /// Kumo's mobile trail: a "More" menu holding the earlier pages, then the
  /// parent and the current page.
  trail,

  /// The full trail, collapsing like the wide layout when space is tight.
  full,
}

/// An ancestor page in a [KumoBreadcrumbs] trail (Kumo's `Breadcrumbs.Link`).
///
/// ```dart
/// KumoBreadcrumbsItem(label: 'Workers', icon: KumoIcons.code, onPress: openWorkers)
/// ```
@immutable
class KumoBreadcrumbsItem {
  const KumoBreadcrumbsItem({required this.label, required this.onPress, this.icon, this.semanticLabel});

  final String label;

  /// Navigates to the page. Null shows the crumb as plain text.
  final VoidCallback? onPress;
  final IconData? icon;
  final String? semanticLabel;
}

/// Kumo's `Breadcrumbs`: where the current page sits in the hierarchy.
///
/// Ancestors are links in subtle text; the current page is medium weight and
/// the only crumb that truncates. When the trail does not fit, the middle
/// ancestors collapse into a "More" menu (a bottom sheet on phones). Below
/// 640px, [narrowLayout] decides: a back link to the parent by default.
///
/// ```dart
/// KumoBreadcrumbs(
///   items: [
///     KumoBreadcrumbsItem(label: 'Account home', icon: KumoIcons.house, onPress: goHome),
///     KumoBreadcrumbsItem(label: 'example.com', onPress: goZone),
///     KumoBreadcrumbsItem(label: 'DNS', onPress: goDns),
///   ],
///   current: 'Records',
/// )
/// ```
class KumoBreadcrumbs extends StatefulWidget {
  const KumoBreadcrumbs({
    super.key,
    this.items = const [],
    required this.current,
    this.currentIcon,
    this.loading = false,
    this.size = KumoBreadcrumbsSize.base,
    this.copyText,
    this.narrowLayout = KumoBreadcrumbsNarrowLayout.back,
    this.presentation = KumoPresentation.auto,
    this.semanticLabel,
  });

  /// Ancestor pages, root first. The current page is not in this list.
  final List<KumoBreadcrumbsItem> items;

  /// Title of the current page (Kumo's `Breadcrumbs.Current`).
  final String current;
  final IconData? currentIcon;

  /// Shows a placeholder bar instead of [current] while its title loads.
  final bool loading;
  final KumoBreadcrumbsSize size;

  /// Adds Kumo's `Breadcrumbs.Clipboard`: a copy button for a deep link.
  /// It appears on hover with a mouse and stays visible on touch.
  final String? copyText;
  final KumoBreadcrumbsNarrowLayout narrowLayout;

  /// Where the "More" menu opens: popover on wide screens, sheet on narrow.
  final KumoPresentation presentation;

  /// Accessible name of the trail. Defaults to [KumoStrings.breadcrumbs].
  final String? semanticLabel;

  @override
  State<KumoBreadcrumbs> createState() => _KumoBreadcrumbsState();
}

class _KumoBreadcrumbsState extends State<KumoBreadcrumbs> {
  bool _hovered = false;
  bool _focusWithin = false;
  bool _menuOpen = false;

  /// After the first frame, crumbs that appear fade in. The first layout
  /// shows at once.
  bool _built = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _built = true;
    });
  }

  TextStyle _linkStyle(BuildContext context) =>
      context.kumo.text(size: widget.size.textSize, color: KumoColor.textSubtle);

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w.ceilToDouble() + 1;
  }

  double _crumbWidth(BuildContext context, KumoBreadcrumbsItem item) {
    final w = _textWidth(context, item.label, _linkStyle(context)) + (item.icon != null ? 16 + KumoSpace.s1 : 0);
    return math.max(w, context.kumo.minTapTarget);
  }

  /// Which ancestors stay visible, as indexes into items, and whether a
  /// "More" menu stands in for the rest.
  ({List<int> shown, List<int> hidden}) _fit(BuildContext context, double maxWidth) {
    final items = widget.items;
    final all = [for (var i = 0; i < items.length; i++) i];
    if (!maxWidth.isFinite || items.isEmpty) return (shown: all, hidden: const []);
    final kumo = context.kumo;
    final gap = widget.size.gap;
    const separator = 24.0;
    final more = math.max(28.0, kumo.minTapTarget);
    final copy = widget.copyText == null ? 0.0 : math.max(26.0, kumo.minTapTarget) + gap;
    // The current page may truncate, but keeps room for a few characters.
    final currentMin = math.min(
      _textWidth(context, widget.current, kumo.text(size: widget.size.textSize, weight: KumoTypography.medium)),
      80.0,
    );
    final widths = [for (final item in items) _crumbWidth(context, item)];
    double total(List<int> shown, bool withMore) {
      final count = shown.length + (withMore ? 1 : 0);
      var w = currentMin + copy + count * (separator + 2 * gap);
      for (final i in shown) {
        w += widths[i];
      }
      if (withMore) w += more;
      return w;
    }

    if (total(all, false) <= maxWidth) return (shown: all, hidden: const []);
    // Keep the root and as many of the closest ancestors as fit.
    for (var start = 2; start < items.length; start++) {
      final shown = [0, for (var i = start; i < items.length; i++) i];
      if (total(shown, true) <= maxWidth) {
        return (shown: shown, hidden: [for (var i = 1; i < start; i++) i]);
      }
    }
    final last = items.length - 1;
    return (shown: [last], hidden: [for (var i = 0; i < last; i++) i]);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final width = MediaQuery.sizeOf(context).width;
    // Kumo switches to its mobile trail below `sm` (640px), not `md`.
    final phone = width < KumoBreakpoints.sm;
    Widget body;
    if (phone && widget.narrowLayout == KumoBreadcrumbsNarrowLayout.back && widget.items.isNotEmpty) {
      body = _backLink(context);
    } else if (phone && widget.narrowLayout == KumoBreadcrumbsNarrowLayout.trail && widget.items.length >= 2) {
      final last = widget.items.length - 1;
      body = _trail(context, shown: [last], hidden: [for (var i = 0; i < last; i++) i], moreFirst: true);
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final fit = _fit(context, constraints.maxWidth);
          return _trail(
            context,
            shown: fit.shown,
            hidden: fit.hidden,
            moreFirst: fit.shown.isEmpty || fit.shown.first != 0,
          );
        },
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel ?? strings.breadcrumbs,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (f) => setState(() => _focusWithin = f),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: widget.size.height),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _backLink(BuildContext context) {
    final parent = widget.items.last;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      child: _Crumb(
        item: KumoBreadcrumbsItem(
          label: parent.label,
          onPress: parent.onPress,
          icon: Directionality.of(context) == TextDirection.rtl ? KumoIcons.caretRight : KumoIcons.caretLeft,
          semanticLabel: parent.semanticLabel ?? '${context.kumoStrings.back}, ${parent.label}',
        ),
        excludeLabelSemantics: true,
        shrink: true,
        size: widget.size,
        height: widget.size.height,
      ),
    );
  }

  Widget _trail(BuildContext context, {required List<int> shown, required List<int> hidden, required bool moreFirst}) {
    // Keyed so a crumb that comes out of (or goes into) the "More" menu as
    // the width changes is a fresh element: it fades in instead of popping,
    // while the crumbs that stay keep their place.
    final children = <Widget>[];
    void add(String key, Widget child) => children.add(_Reveal(key: ValueKey(key), animate: _built, child: child));
    void sep(String after) => add('sep-$after', const _Separator());
    final more = hidden.isEmpty ? null : _more(context, hidden);
    if (more != null && moreFirst) {
      add('more', more);
      sep('more');
    }
    // Ancestors keep their width (Kumo: only the current page truncates),
    // unless a single one is left and still does not fit.
    final lone = shown.length == 1;
    for (final i in shown) {
      final crumb = _Crumb(item: widget.items[i], size: widget.size, height: widget.size.height, shrink: lone);
      if (lone) {
        children.add(
          Flexible(
            key: ValueKey('crumb-$i'),
            child: _Reveal(animate: _built, child: crumb),
          ),
        );
      } else {
        add('crumb-$i', crumb);
      }
      sep('$i');
      if (i == 0 && more != null && !moreFirst) {
        add('more', more);
        sep('more');
      }
    }
    children.add(Flexible(key: const ValueKey('current'), child: _current(context)));
    if (widget.copyText != null) {
      final kumo = context.kumo;
      final show = _hovered || _focusWithin || kumo.minTapTarget > 0;
      // Kumo fades the copy button in on hover (`transition-[opacity]`).
      children.add(
        AnimatedOpacity(
          key: const ValueKey('copy'),
          opacity: show ? 1 : 0,
          duration: KumoMotion.duration(context, KumoDurations.fast),
          curve: KumoCurves.standard,
          child: _CopyButton(text: widget.copyText!),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, spacing: widget.size.gap, children: children);
  }

  Widget _current(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final icon = widget.currentIcon == null ? null : KumoIcon(widget.currentIcon!);
    if (widget.loading) {
      return Semantics(
        label: strings.loading,
        child: SizedBox(
          width: 125,
          child: Row(
            spacing: KumoSpace.s1,
            children: [
              ?icon,
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: kumo.colors.fill,
                    borderRadius: BorderRadius.circular(KumoRadius.full),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: KumoSpace.s1,
      children: [
        ?icon,
        Flexible(
          child: Text(
            widget.current,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: kumo.text(size: widget.size.textSize, weight: KumoTypography.medium),
          ),
        ),
      ],
    );
  }

  Widget _more(BuildContext context, List<int> hidden) {
    final strings = context.kumoStrings;
    final sheet = widget.presentation.usesSheet(context);
    List<Widget> rows(VoidCallback close) => [
      for (final i in hidden)
        KumoMenuRow(
          isLink: true,
          label: widget.items[i].label,
          icon: widget.items[i].icon,
          disabled: widget.items[i].onPress == null,
          onPress: () {
            close();
            widget.items[i].onPress?.call();
          },
        ),
    ];
    final trigger = KumoPressable(
      semanticLabel: strings.more,
      excludeChildSemantics: true,
      expanded: _menuOpen,
      scaleOnPress: false,
      borderRadius: BorderRadius.circular(KumoRadius.sm),
      onPress: () async {
        if (!sheet) {
          setState(() => _menuOpen = !_menuOpen);
          return;
        }
        setState(() => _menuOpen = true);
        await showKumoSheet<void>(
          context: context,
          semanticLabel: strings.more,
          builder: (sheetContext) => Padding(
            padding: const EdgeInsets.all(KumoSpace.s2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows(() => KumoSheetScope.closeFrom(sheetContext)),
            ),
          ),
        );
        if (mounted) setState(() => _menuOpen = false);
      },
      builder: (context, state) => SizedBox(
        height: widget.size.height,
        child: Center(
          widthFactor: 1,
          child: KumoFocusRing(
            visible: state.focused,
            borderRadius: BorderRadius.circular(KumoRadius.sm),
            child: Container(
              width: 28,
              height: 24,
              decoration: BoxDecoration(
                color: state.active ? context.kumo.colors.tint : null,
                borderRadius: BorderRadius.circular(KumoRadius.sm),
              ),
              alignment: Alignment.center,
              child: const KumoIcon(KumoIcons.dotsThree, color: KumoColor.textSubtle),
            ),
          ),
        ),
      ),
    );
    if (sheet) return trigger;
    return KumoAnchoredOverlay(
      open: _menuOpen,
      onDismiss: () => setState(() => _menuOpen = false),
      align: KumoAlign.start,
      trapFocus: true,
      overlayBuilder: (context, placement) =>
          KumoMenuPanel(semanticLabel: strings.more, children: rows(() => setState(() => _menuOpen = false))),
      child: trigger,
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.item,
    required this.size,
    required this.height,
    this.excludeLabelSemantics = false,
    this.shrink = false,
  });

  /// Truncate the label with an ellipsis when space runs out.
  final bool shrink;

  final KumoBreadcrumbsItem item;

  /// The semantic label replaces the visible text instead of joining it.
  final bool excludeLabelSemantics;
  final KumoBreadcrumbsSize size;
  final double height;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final interactive = item.onPress != null;
    return KumoPressable(
      onPress: item.onPress,
      isLink: interactive,
      isButton: false,
      scaleOnPress: false,
      showFocusRing: false,
      semanticLabel: item.semanticLabel,
      excludeChildSemantics: excludeLabelSemantics,
      builder: (context, state) {
        final fg = state.active ? KumoColor.textDefault : KumoColor.textSubtle;
        return SizedBox(
          height: height,
          child: Center(
            widthFactor: 1,
            child: KumoFocusRing(
              visible: state.focused,
              borderRadius: BorderRadius.circular(KumoRadius.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s1,
                children: [
                  if (item.icon != null) KumoIcon(item.icon!, color: fg),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: shrink ? TextOverflow.ellipsis : TextOverflow.clip,
                      style: kumo.text(size: size.textSize, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(
        painter: _ChevronPainter(color: context.kumo.colors.textInactive, rtl: rtl),
      ),
    );
  }
}

/// Kumo's 24px separator: a 1.5px chevron (`M10.75 8.75L14.25 12L10.75 15.25`).
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color, required this.rtl});

  final Color color;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    double x(double v) => (rtl ? 24 - v : v) * s;
    final path = Path()
      ..moveTo(x(10.75), 8.75 * s)
      ..lineTo(x(14.25), 12 * s)
      ..lineTo(x(10.75), 15.25 * s);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color || old.rtl != rtl;
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool? _ok;
  Timer? _reset;
  int _attempt = 0;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final attempt = ++_attempt;
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.text));
    } catch (_) {
      ok = false;
    }
    if (!mounted || attempt != _attempt) return;
    setState(() => _ok = ok);
    final strings = context.kumoStrings;
    final view = View.maybeOf(context);
    if (view != null) {
      unawaited(
        SemanticsService.sendAnnouncement(
          view,
          ok ? strings.copied : strings.copyFailed,
          Directionality.maybeOf(context) ?? TextDirection.ltr,
        ),
      );
    }
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _ok = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final ok = _ok;
    final icon = switch (ok) {
      true => const KumoIcon(KumoIcons.check, key: ValueKey('copied'), size: 14, color: KumoColor.textSuccess),
      false => const KumoIcon(KumoIcons.warningCircle, key: ValueKey('failed'), size: 14, color: KumoColor.textDanger),
      null => const KumoIcon(KumoIcons.copy, key: ValueKey('copy'), size: 14),
    };
    return KumoButton(
      variant: KumoButtonVariant.ghost,
      shape: KumoButtonShape.square,
      size: KumoButtonSize.sm,
      semanticLabel: switch (ok) {
        true => strings.copied,
        false => strings.copyFailed,
        null => strings.copy,
      },
      onPress: _copy,
      iconWidget: _CheckSwap(child: icon),
    );
  }
}

/// Cross-fades an icon swap. A check (any child keyed `copied`) lands with
/// Kumo's small bounce; the glyph it replaces fades out. Instant under
/// reduced motion.
class _CheckSwap extends StatelessWidget {
  const _CheckSwap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: KumoMotion.duration(context, KumoDurations.moderate),
      reverseDuration: KumoMotion.duration(context, KumoDurations.fast),
      transitionBuilder: (child, animation) {
        final landing = child.key == const ValueKey('copied');
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: const Interval(0, 0.5))),
          child: landing
              ? ScaleTransition(
                  scale: animation.drive(Tween<double>(begin: 0.6, end: 1).chain(CurveTween(curve: KumoCurves.bounce))),
                  child: child,
                )
              : child,
        );
      },
      child: child,
    );
  }
}

/// Fades its child in when it is first mounted after the trail has laid out
/// once: a crumb or the "More" button appearing as the trail collapses or
/// expands. Opacity only, so the row never lags a window resize.
class _Reveal extends StatefulWidget {
  const _Reveal({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final Animation<double> _opacity;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: KumoDurations.quick, value: 1);
    _opacity = _fade.drive(CurveTween(curve: KumoCurves.enter));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.animate && !KumoMotion.reduceMotion(context)) _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
