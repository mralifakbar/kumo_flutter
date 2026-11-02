import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../menus/kumo_dropdown_menu.dart' show KumoDropdownCaret;
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_menu_parts.dart';
import '../overlays/kumo_routes.dart';
import '../overlays/kumo_scrim.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_focus_trap.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../typography/kumo_text.dart';
import 'kumo_dialog.dart';

/// Desktop widths of a [KumoLayerDialog]. Phones always get a full-width
/// bottom sheet.
enum KumoLayerDialogSize {
  /// `sm:max-w-md`, 448px.
  sm(448),

  /// `sm:max-w-xl`, 576px: the default.
  base(576),

  /// `sm:max-w-2xl`, 672px.
  lg(672),

  /// `sm:max-w-3xl`, 768px.
  xl(768);

  const KumoLayerDialogSize(this.width);
  final double width;
}

/// Where a desktop [KumoLayerDialog] sits. Phones always use a bottom sheet.
enum KumoLayerDialogVerticalAlign {
  /// 64px from the top (`sm:items-start sm:pt-16 sm:pb-6`).
  top,

  /// Centered with 24px above and below (`sm:items-center sm:py-6`): the default.
  center,
}

/// Emphasis of the single primary action.
enum KumoLayerDialogActionVariant {
  /// Brand blue: the default.
  primary,

  /// Red, for irreversible confirmations such as a delete.
  destructive,
}

/// A related action offered from the split-button menu of a
/// [KumoLayerDialogAction] ("Save as draft" next to "Save and deploy").
@immutable
class KumoLayerDialogMenuItem {
  const KumoLayerDialogMenuItem({required this.label, required this.onPress, this.icon, this.destructive = false});

  final String label;
  final VoidCallback onPress;
  final IconData? icon;
  final bool destructive;
}

/// The one primary action of a [KumoLayerDialog] (Kumo's `LayerDialog.Action`).
///
/// ```dart
/// KumoLayerDialogAction(label: 'Save hostname', onPress: save, loading: saving)
/// KumoLayerDialogAction(
///   label: 'Save and deploy',
///   onPress: deploy,
///   menu: [KumoLayerDialogMenuItem(label: 'Save as draft', onPress: saveDraft)],
/// )
/// ```
@immutable
class KumoLayerDialogAction {
  const KumoLayerDialogAction({
    required this.label,
    required this.onPress,
    this.variant = KumoLayerDialogActionVariant.primary,
    this.loading = false,
    this.disabled = false,
    this.menu = const [],
    this.menuLabel,
  });

  final String label;

  /// Null disables the action.
  final VoidCallback? onPress;
  final KumoLayerDialogActionVariant variant;
  final bool loading;
  final bool disabled;

  /// Related actions behind a caret button next to the action.
  final List<KumoLayerDialogMenuItem> menu;

  /// Accessible name of the caret button. Defaults to
  /// [KumoStrings.moreActions].
  final String? menuLabel;
}

/// Kumo's `LayerDialog`: a strict responsive dialog. On screens 640px and
/// wider it is a centered panel; on phones it is a bottom sheet that follows
/// the finger and dismisses with a downward flick.
///
/// Open it with [showKumoLayerDialog] or keep it mounted in a
/// [KumoDialogRoot].
///
/// ```dart
/// showKumoLayerDialog<void>(
///   context,
///   builder: (context) => KumoLayerDialog(
///     title: 'Configure custom hostname',
///     description: 'Route requests for this hostname to your Worker.',
///     body: hostnameForm,
///     action: KumoLayerDialogAction(label: 'Save hostname', onPress: save),
///   ),
/// );
/// ```
///
/// The composition is fixed, like Kumo's:
///
/// * Without [action]: an X in the title frame and no footer, for read-only
///   content.
/// * With [action]: no X; a footer with an automatic dismiss button (Close,
///   or Cancel in [KumoLayerDialog.alert]) at the start and the action at
///   the end. On phones the footer stays visible under the scrolling body
///   behind a hairline; on desktop it sits outside the body surface.
///
/// The title frame stays put while [body] scrolls. Once the body scrolls
/// past its top, the [description] folds away to give the content room and
/// unfolds at the top again. A fade at the scroll edges signals more content.
class KumoLayerDialog extends StatelessWidget {
  const KumoLayerDialog({
    super.key,
    required this.title,
    this.description,
    required this.body,
    this.action,
    this.dismissLabel,
    this.closeLabel,
    this.size = KumoLayerDialogSize.base,
    this.verticalAlign = KumoLayerDialogVerticalAlign.center,
    this.dismissDisabled = false,
  }) : alert = false;

  /// A confirmation that needs an explicit choice (`LayerDialog.Alert`):
  /// announced as an alert dialog, no X, no backdrop or swipe dismissal, and
  /// the footer's dismiss button reads Cancel. Escape still cancels.
  ///
  /// ```dart
  /// KumoLayerDialog.alert(
  ///   title: 'Delete production-api?',
  ///   body: const KumoText('Requests to its routes fail until you deploy again.'),
  ///   action: KumoLayerDialogAction(
  ///     label: 'Delete Worker',
  ///     variant: KumoLayerDialogActionVariant.destructive,
  ///     onPress: delete,
  ///   ),
  /// )
  /// ```
  const KumoLayerDialog.alert({
    super.key,
    required this.title,
    this.description,
    required this.body,
    required KumoLayerDialogAction this.action,
    this.dismissLabel,
    this.closeLabel,
    this.size = KumoLayerDialogSize.base,
    this.verticalAlign = KumoLayerDialogVerticalAlign.center,
    this.dismissDisabled = false,
  }) : alert = true;

  /// Heading of the sticky title frame; also the dialog's accessible name.
  final String title;

  /// Supporting copy under the title. Folds away while the body scrolls.
  final String? description;

  /// Scrollable content. Use [KumoLayerDialogSeparator] between sections.
  final Widget body;

  /// The single primary action. Its presence replaces the X with a footer.
  final KumoLayerDialogAction? action;

  /// Text of the footer's dismiss button. Defaults to [KumoStrings.close],
  /// or [KumoStrings.cancel] in an alert. Say Cancel only when the workflow
  /// has a real cancel outcome.
  final String? dismissLabel;

  /// Accessible name of the X. Defaults to [KumoStrings.close].
  final String? closeLabel;

  /// Desktop width.
  final KumoLayerDialogSize size;

  /// Desktop placement.
  final KumoLayerDialogVerticalAlign verticalAlign;

  /// Blocks every user dismissal (X, dismiss button, Escape, backdrop,
  /// swipe, back gesture) while work is pending. Closing from code still
  /// works, so a finished save can close the dialog.
  final bool dismissDisabled;

  /// True for [KumoLayerDialog.alert].
  final bool alert;

  /// The route [showKumoLayerDialog] pushes, for apps that drive the
  /// [Navigator] themselves. [builder] should return a [KumoLayerDialog].
  static Route<T> createRoute<T>({required WidgetBuilder builder, String? semanticLabel}) =>
      KumoSheetRoute<T>(builder: builder, semanticLabel: semanticLabel);

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= KumoBreakpoints.sm;
    Widget frame = _LayerDialogFrame(dialog: this, desktop: desktop);
    frame = PopScope(
      canPop: !dismissDisabled,
      child: _EscapeGuard(blocked: dismissDisabled, child: frame),
    );
    if (desktop) {
      return _LayerDialogDesktop(
        width: size.width,
        verticalAlign: verticalAlign,
        backdropDismisses: !alert && !dismissDisabled,
        escapeCloses: !dismissDisabled,
        child: frame,
      );
    }
    return KumoSheet(
      edge: KumoSheetEdge.bottom,
      maxExtentFraction: 0.85,
      borderRadius: KumoRadius.xl,
      preventDismissGestures: alert || dismissDisabled,
      accessibilityLabel: title,
      child: frame,
    );
  }
}

/// Opens [builder]'s [KumoLayerDialog] and returns the value it closes with.
///
/// The presentation is chosen when it opens: a bottom sheet below 640px, a
/// centered panel that fades in and rises 8px (200ms) from 640px up.
///
/// ```dart
/// showKumoLayerDialog<void>(
///   context,
///   builder: (context) => const KumoLayerDialog(
///     title: 'Keyboard shortcuts',
///     body: KumoText('Press / to search Workers.'),
///   ),
/// );
/// ```
Future<T?> showKumoLayerDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  ).push<T>(KumoLayerDialog.createRoute<T>(builder: builder, semanticLabel: semanticLabel));
}

/// Kumo's `LayerDialog.Separator`: a hairline between sections of the body
/// that runs through the body's side padding to both edges.
///
/// ```dart
/// Column(children: [
///   const KumoText('production-api deploys to the global network.'),
///   const KumoLayerDialogSeparator(),
///   const KumoText('Compatibility date 2026-10-26.'),
/// ])
/// ```
class KumoLayerDialogSeparator extends StatelessWidget {
  const KumoLayerDialogSeparator({super.key});

  @override
  Widget build(BuildContext context) {
    final inset = context.dependOnInheritedWidgetOfExactType<_BodyInset>()?.value ?? 0;
    final color = context.kumo.colors.hairline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KumoSpace.s4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth + 2 * inset;
          return SizedBox(
            height: 1,
            child: OverflowBox(
              minWidth: width,
              maxWidth: width,
              child: ColoredBox(
                color: color,
                child: SizedBox(width: width, height: 1),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BodyInset extends InheritedWidget {
  const _BodyInset({required this.value, required super.child});

  final double value;

  @override
  bool updateShouldNotify(_BodyInset oldWidget) => value != oldWidget.value;
}

/// Swallows Escape while dismissal is blocked, before the sheet or panel
/// focus trap sees it.
class _EscapeGuard extends StatelessWidget {
  const _EscapeGuard({required this.blocked, required this.child});

  final bool blocked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (blocked && event.logicalKey == LogicalKeyboardKey.escape) return KeyEventResult.handled;
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Desktop presentation inside a [KumoSheetRoute]: the backdrop, a fade and
/// an 8px rise on the way in, the reverse on the way out, focus trapping
/// and Escape.
class _LayerDialogDesktop extends StatefulWidget {
  const _LayerDialogDesktop({
    required this.width,
    required this.verticalAlign,
    required this.backdropDismisses,
    required this.escapeCloses,
    required this.child,
  });

  final double width;
  final KumoLayerDialogVerticalAlign verticalAlign;
  final bool backdropDismisses;
  final bool escapeCloses;
  final Widget child;

  @override
  State<_LayerDialogDesktop> createState() => _LayerDialogDesktopState();
}

class _LayerDialogDesktopState extends State<_LayerDialogDesktop> with SingleTickerProviderStateMixin {
  late final AnimationController _presence;
  KumoSheetRoute<dynamic>? _route;
  Animation<double>? _routeAnimation;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _presence = AnimationController(vsync: this, duration: KumoDurations.moderate);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _presence.duration = KumoMotion.reduceMotion(context) ? KumoDurations.fast : KumoDurations.moderate;
    if (!_presence.isAnimating && _presence.value == 0 && !_exiting) _presence.forward();
    final route = ModalRoute.of(context);
    final sheetRoute = route is KumoSheetRoute ? route : null;
    if (sheetRoute != _route) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _route = sheetRoute;
      _routeAnimation = sheetRoute?.animation;
      _routeAnimation?.addStatusListener(_onRouteStatus);
    }
  }

  void _onRouteStatus(AnimationStatus status) {
    if (status != AnimationStatus.reverse || _exiting) return;
    _exiting = true;
    _presence.reverse().whenComplete(() => _route?.completeExit());
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _presence.dispose();
    super.dispose();
  }

  void _close() => KumoDialog.closeFrom(context);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduce = KumoMotion.reduceMotion(context);
    final curve = CurvedAnimation(parent: _presence, curve: KumoCurves.standard);
    final top = widget.verticalAlign == KumoLayerDialogVerticalAlign.top ? KumoSpace.s16 : KumoSpace.s6;
    final bottomInset = math.max(media.viewInsets.bottom, media.padding.bottom);
    final available = media.size.width - 2 * KumoSpace.s4;

    Widget panel = SizedBox(width: math.min(widget.width, available), child: widget.child);
    panel = AnimatedBuilder(
      animation: curve,
      child: panel,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: reduce ? child : Transform.translate(offset: Offset(0, 8 * (1 - curve.value)), child: child),
      ),
    );

    return KumoFocusTrap(
      onEscPress: widget.escapeCloses ? _close : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: curve,
            child: KumoScrim(onPress: widget.backdropDismisses ? _close : null),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              KumoSpace.s4,
              media.padding.top + top,
              KumoSpace.s4,
              bottomInset + KumoSpace.s6,
            ),
            child: Align(
              alignment: widget.verticalAlign == KumoLayerDialogVerticalAlign.top
                  ? Alignment.topCenter
                  : Alignment.center,
              child: panel,
            ),
          ),
        ],
      ),
    );
  }
}

/// The elevated frame around the body surface, with the drag handle on
/// phones and the footer outside the body on desktop.
class _LayerDialogFrame extends StatelessWidget {
  const _LayerDialogFrame({required this.dialog, required this.desktop});

  final KumoLayerDialog dialog;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final media = MediaQuery.of(context);
    final action = dialog.action;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!desktop && !dialog.alert)
          Padding(
            padding: const EdgeInsets.only(top: KumoSpace.s1_5, bottom: KumoSpace.s3),
            child: Center(
              child: ExcludeSemantics(
                child: Container(
                  width: KumoSpace.s10,
                  height: KumoSpace.s1,
                  decoration: BoxDecoration(color: c.fill, borderRadius: BorderRadius.circular(KumoRadius.full)),
                ),
              ),
            ),
          ),
        Flexible(
          child: _LayerDialogBody(dialog: dialog, desktop: desktop),
        ),
        if (desktop && action != null)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: _LayerDialogActions(dialog: dialog, action: action, desktop: true),
          ),
      ],
    );

    content = Padding(
      padding: EdgeInsets.fromLTRB(
        KumoSpace.s1_5,
        KumoSpace.s1_5,
        KumoSpace.s1_5,
        KumoSpace.s1_5 + (desktop ? 0 : math.max(media.padding.bottom, media.viewInsets.bottom)),
      ),
      child: content,
    );

    final decoration = desktop
        ? BoxDecoration(
            color: c.elevated,
            borderRadius: BorderRadius.circular(KumoRadius.xl),
            border: KumoRing.border(c.line),
            boxShadow: _layerShadow,
          )
        : BoxDecoration(
            color: c.elevated,
            border: Border(top: BorderSide(color: c.hairline)),
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: dialog.alert ? SemanticsRole.alertDialog : SemanticsRole.dialog,
      child: DecoratedBox(
        decoration: decoration,
        child: DefaultTextStyle(style: kumo.text(), child: content),
      ),
    );
  }
}

/// Kumo's soft dialog shadow (the `shadow-xl` shape at 3%).
const List<BoxShadow> _layerShadow = [
  BoxShadow(offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5, color: Color(0x08000000)),
  BoxShadow(offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6, color: Color(0x08000000)),
];

/// Scroll distance before the description folds away.
const double _condenseThreshold = 8;

/// Overflow that must remain once the description is folded, or folding it
/// would clamp the scroll back under the threshold and unfold it again.
const double _condenseMinOverflow = 16;

/// Height of the fade at a scroll edge that has content beyond it.
const double _edgeFade = 24;

/// Kumo's `LayerDialog.Body`: the base surface with the sticky title frame,
/// the scrolling content and, on phones, the footer.
class _LayerDialogBody extends StatefulWidget {
  const _LayerDialogBody({required this.dialog, required this.desktop});

  final KumoLayerDialog dialog;
  final bool desktop;

  @override
  State<_LayerDialogBody> createState() => _LayerDialogBodyState();
}

class _LayerDialogBodyState extends State<_LayerDialogBody> with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _descriptionKey = GlobalKey();
  late final AnimationController _fold;
  bool _condensed = false;
  double _fadeTop = 0;
  double _fadeBottom = 0;

  @override
  void initState() {
    super.initState();
    _fold = AnimationController(vsync: this, duration: KumoDurations.moderate, value: 1);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _fold.dispose();
    super.dispose();
  }

  void _setCondensed(bool value) {
    if (_condensed == value) return;
    _condensed = value;
    if (KumoMotion.reduceMotion(context)) {
      _fold.value = value ? 0 : 1;
    } else if (value) {
      _fold.animateTo(0, curve: KumoCurves.enter);
    } else {
      _fold.animateTo(1, curve: KumoCurves.enter);
    }
  }

  bool _onScroll(ScrollMetrics m) {
    final top = math.min(_edgeFade, math.max(0.0, m.pixels - m.minScrollExtent));
    final bottom = math.min(_edgeFade, math.max(0.0, m.maxScrollExtent - m.pixels));
    if (top != _fadeTop || bottom != _fadeBottom) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _fadeTop = top;
            _fadeBottom = bottom;
          });
        }
      });
    }
    if (widget.dialog.description != null) {
      if (m.pixels <= _condenseThreshold) {
        _setCondensed(false);
      } else if (!_condensed) {
        final descriptionHeight = _descriptionKey.currentContext?.size?.height ?? 0;
        if (m.maxScrollExtent - descriptionHeight > _condenseMinOverflow) _setCondensed(true);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final dialog = widget.dialog;
    final desktop = widget.desktop;
    final strings = context.kumoStrings;
    final inset = desktop ? 18.0 : KumoSpace.s4;
    final action = dialog.action;
    const radius = BorderRadius.all(Radius.circular(KumoRadius.lg));

    final title = Semantics(
      header: true,
      namesRoute: true,
      container: true,
      child: Text(dialog.title, style: kumo.heading().copyWith(fontWeight: KumoTypography.medium)),
    );

    Widget? description;
    if (dialog.description != null) {
      // Folding clips the description instead of reflowing it, and it stays
      // in the semantics tree while folded so it still describes the dialog.
      description = ClipRect(
        child: AnimatedBuilder(
          animation: _fold,
          builder: (context, child) => Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: _fold.value,
            child: Opacity(opacity: _fold.value, child: child),
          ),
          child: Padding(
            key: _descriptionKey,
            padding: const EdgeInsets.only(top: KumoSpace.s1),
            child: KumoText(dialog.description!, variant: KumoTextVariant.secondary),
          ),
        ),
      );
    }

    final header = Padding(
      padding: EdgeInsets.fromLTRB(inset, KumoSpace.s4, inset, KumoSpace.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KumoSpace.s4,
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, ?description],
            ),
          ),
          if (action == null)
            Transform.translate(
              offset: Offset(Directionality.of(context) == TextDirection.rtl ? -6 : 6, -6),
              child: KumoButton(
                iconWidget: const KumoIcon(KumoIcons.x, size: 15),
                shape: KumoButtonShape.square,
                size: KumoButtonSize.sm,
                variant: KumoButtonVariant.ghost,
                semanticLabel: dialog.closeLabel ?? strings.close,
                disabled: dialog.dismissDisabled,
                onPress: () => KumoDialog.closeFrom(context),
              ),
            ),
        ],
      ),
    );

    final scroll = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onScroll(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 ? _onScroll(n.metrics) : false,
        child: SingleChildScrollView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(inset, KumoSpace.s0_5, inset, inset),
          child: _BodyInset(value: inset, child: dialog.body),
        ),
      ),
    );

    final faded = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final h = bounds.height <= 0 ? 1.0 : bounds.height;
        const clear = Color(0x00000000);
        const solid = Color(0xFF000000);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fadeTop > 0 ? clear : solid, solid, solid, _fadeBottom > 0 ? clear : solid],
          stops: [0, (_fadeTop / h).clamp(0.0, 0.5), (1 - _fadeBottom / h).clamp(0.5, 1.0), 1],
        ).createShader(bounds);
      },
      child: scroll,
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: c.base, borderRadius: radius),
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: radius, border: KumoRing.inset(c.fill)),
        position: DecorationPosition.foreground,
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Flexible(child: faded),
              if (!desktop && action != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.hairline)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(KumoSpace.s4),
                    child: _LayerDialogActions(dialog: dialog, action: action, desktop: false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kumo's `LayerDialog.Actions`: the automatic dismiss button at the start
/// and the single primary action at the end.
class _LayerDialogActions extends StatelessWidget {
  const _LayerDialogActions({required this.dialog, required this.action, required this.desktop});

  final KumoLayerDialog dialog;
  final KumoLayerDialogAction action;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final strings = context.kumoStrings;
    final label = dialog.dismissLabel ?? (dialog.alert ? strings.cancel : strings.close);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: KumoSpace.s2,
      children: [
        Flexible(
          child: KumoButton(
            label: label,
            variant: desktop ? KumoButtonVariant.ghost : KumoButtonVariant.secondary,
            disabled: dialog.dismissDisabled,
            onPress: () => KumoDialog.closeFrom(context),
          ),
        ),
        Flexible(child: _PrimaryAction(action: action)),
      ],
    );
  }
}

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({required this.action});

  final KumoLayerDialogAction action;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final variant = action.variant == KumoLayerDialogActionVariant.destructive
        ? KumoButtonVariant.destructive
        : KumoButtonVariant.primary;
    final button = KumoButton(
      label: action.label,
      variant: variant,
      loading: action.loading,
      disabled: action.disabled,
      onPress: action.onPress,
    );
    if (action.menu.isEmpty) return button;

    final menuLabel = action.menuLabel ?? context.kumoStrings.moreActions;
    final caret = KumoAnchoredOverlay(
      open: _menuOpen,
      side: KumoSide.top,
      align: KumoAlign.end,
      trapFocus: true,
      onDismiss: () => setState(() => _menuOpen = false),
      overlayBuilder: (context, placement) => KumoMenuKeyboard(
        child: KumoMenuPanel(
          semanticLabel: menuLabel,
          children: [
            for (final item in action.menu)
              KumoMenuRow(
                label: item.label,
                icon: item.icon,
                destructive: item.destructive,
                onPress: () {
                  setState(() => _menuOpen = false);
                  item.onPress();
                },
              ),
          ],
        ),
      ),
      child: KumoButton(
        // Turns over while the menu above it is open.
        iconWidget: KumoDropdownCaret(open: _menuOpen, size: KumoButtonSize.base.iconSize),
        shape: KumoButtonShape.square,
        variant: variant,
        semanticLabel: menuLabel,
        disabled: action.disabled || action.loading,
        onPress: () => setState(() => _menuOpen = !_menuOpen),
      ),
    );
    return Semantics(
      container: true,
      label: menuLabel,
      explicitChildNodes: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: KumoSpace.px,
        children: [
          Flexible(child: button),
          caret,
        ],
      ),
    );
  }
}
