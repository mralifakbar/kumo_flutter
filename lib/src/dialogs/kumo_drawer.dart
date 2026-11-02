import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_routes.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_strings.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../typography/kumo_text.dart';
import 'kumo_dialog.dart';

/// A panel that slides in from a screen edge: a side panel for details and
/// filters on wide screens, a bottom drawer on phones.
///
/// Open it with [showKumoDrawer] or keep it mounted in a [KumoDialogRoot].
///
/// ```dart
/// showKumoDrawer<void>(
///   context,
///   builder: (context) => KumoDrawer(
///     title: 'image-resizer',
///     description: 'Worker settings',
///     actions: [
///       const KumoDialogClose(label: 'Cancel'),
///       KumoButton(label: 'Save settings', variant: KumoButtonVariant.primary, onPress: save),
///     ],
///     child: settingsForm,
///   ),
/// );
/// ```
///
/// The drawer follows the finger 1:1, rubberbands past its open position,
/// and a flick toward its edge dismisses it at the finger's velocity; a
/// short drag springs back. Escape, a backdrop tap and the back gesture
/// close it along the path it came in on. Focus stays inside while it is
/// open and returns to the trigger afterwards.
///
/// The header (title, description, X) and the footer stay put while the
/// body scrolls, separated from it by hairlines once content passes under
/// them. Bottom drawers show a grab handle and hand vertical drags from the
/// top of their scrolled content to the drawer itself.
class KumoDrawer extends StatefulWidget {
  const KumoDrawer({
    super.key,
    this.side = KumoSheetEdge.end,
    this.title,
    this.description,
    required this.child,
    this.actions = const [],
    this.showCloseButton = true,
    this.maxWidth = 384,
    this.dismissible = true,
    this.semanticLabel,
  });

  /// Edge the drawer is attached to. [KumoSheetEdge.start] and
  /// [KumoSheetEdge.end] follow the text direction.
  final KumoSheetEdge side;

  /// Heading of the drawer; also its accessible name.
  final String? title;
  final String? description;

  /// Body content. Scrolls when it does not fit.
  final Widget child;

  /// Footer buttons, end-aligned. [KumoDialogClose] works here too.
  final List<Widget> actions;

  /// Shows the X in the header.
  final bool showCloseButton;

  /// Largest width of a start or end drawer. It never takes more than 85%
  /// of the screen, so the page behind stays visible as a cue.
  final double maxWidth;

  /// False blocks backdrop taps and drag dismissal (Escape still closes).
  final bool dismissible;

  /// Accessible name when there is no [title].
  final String? semanticLabel;

  @override
  State<KumoDrawer> createState() => _KumoDrawerState();
}

class _KumoDrawerState extends State<KumoDrawer> {
  bool _contentAbove = false;
  bool _contentBelow = false;

  bool get _vertical => widget.side == KumoSheetEdge.bottom || widget.side == KumoSheetEdge.top;

  bool _onMetrics(ScrollMetrics m) {
    final above = m.pixels > m.minScrollExtent + 0.5;
    final below = m.pixels < m.maxScrollExtent - 0.5;
    if (above != _contentAbove || below != _contentBelow) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _contentAbove = above;
            _contentBelow = below;
          });
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fraction = _vertical ? 0.85 : math.min(0.85, widget.maxWidth / math.max(width, 1));
    final kumo = context.kumo;
    Widget panel = _panel(context);
    // KumoSheet draws its dark-mode edge for side sheets with a directional
    // border and a zero radius, which Flutter rejects. Side drawers hide the
    // dark flag from the sheet and draw that edge themselves.
    final patchDarkEdge = kumo.isDark && !_vertical;
    if (patchDarkEdge) {
      final line = BorderSide(color: kumo.colors.line);
      panel = KumoTheme(
        data: kumo,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: widget.side == KumoSheetEdge.start ? BorderDirectional(end: line) : BorderDirectional(start: line),
          ),
          position: DecorationPosition.foreground,
          child: panel,
        ),
      );
    }
    final Widget sheet = KumoSheet(
      edge: widget.side,
      maxExtentFraction: fraction,
      preventDismissGestures: !widget.dismissible,
      accessibilityLabel: widget.title ?? widget.semanticLabel,
      child: panel,
    );
    return patchDarkEdge
        ? KumoTheme(
            data: kumo.copyWith(brightness: Brightness.light),
            child: sheet,
          )
        : sheet;
  }

  Widget _panel(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final side = widget.side;
    final hasHeader = widget.title != null || widget.description != null || widget.showCloseButton;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // A side panel only touches the screen edge it is attached to, so only
    // that side needs the safe-area inset.
    final onLeft = (side == KumoSheetEdge.start && !rtl) || (side == KumoSheetEdge.end && rtl);
    final onRight = (side == KumoSheetEdge.end && !rtl) || (side == KumoSheetEdge.start && rtl);

    final header = !hasHeader
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(KumoSpace.s5, KumoSpace.s4, KumoSpace.s3, KumoSpace.s4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s3,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    spacing: KumoSpace.s1,
                    children: [
                      if (widget.title != null)
                        Semantics(
                          namesRoute: true,
                          container: true,
                          child: KumoText(widget.title!, variant: KumoTextVariant.heading, headingLevel: 2),
                        ),
                      if (widget.description != null) KumoText(widget.description!, variant: KumoTextVariant.secondary),
                    ],
                  ),
                ),
                if (widget.showCloseButton)
                  KumoButton(
                    iconWidget: const KumoIcon(KumoIcons.x, size: 15),
                    shape: KumoButtonShape.square,
                    size: KumoButtonSize.sm,
                    variant: KumoButtonVariant.ghost,
                    semanticLabel: strings.close,
                    onPress: () => KumoDialog.closeFrom(context),
                  ),
              ],
            ),
          );

    final body = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 ? _onMetrics(n.metrics) : false,
        child: SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(
            KumoSpace.s5,
            header == null ? KumoSpace.s4 : 0,
            KumoSpace.s5,
            KumoSpace.s4,
          ),
          child: widget.child,
        ),
      ),
    );

    Color edge(bool visible) => visible ? c.hairline : const Color(0x00000000);
    final footer = widget.actions.isEmpty
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: edge(_contentBelow))),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s5, vertical: KumoSpace.s4),
              child: KumoDialogFooter(children: widget.actions),
            ),
          );

    final column = Column(
      mainAxisSize: _vertical ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (side == KumoSheetEdge.bottom)
          KumoSheetHandle(
            semanticLabel: strings.close,
            onAccessibilityPress: widget.dismissible ? () => KumoDialog.closeFrom(context) : null,
          ),
        if (header != null) ...[header, SizedBox(height: 1, child: ColoredBox(color: edge(_contentAbove)))],
        if (_vertical) Flexible(child: body) else Expanded(child: body),
        ?footer,
        if (side == KumoSheetEdge.top)
          KumoSheetHandle(
            semanticLabel: strings.close,
            onAccessibilityPress: widget.dismissible ? () => KumoDialog.closeFrom(context) : null,
          ),
      ],
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.title == null ? widget.semanticLabel : null,
      child: SafeArea(
        top: side != KumoSheetEdge.bottom,
        bottom: side != KumoSheetEdge.top,
        left: !onRight,
        right: !onLeft,
        child: column,
      ),
    );
  }
}

/// Opens [builder]'s [KumoDrawer] and returns the value it closes with.
///
/// ```dart
/// final filter = await showKumoDrawer<String>(
///   context,
///   builder: (context) => KumoDrawer(
///     side: KumoSheetEdge.bottom,
///     title: 'Filter zones',
///     child: KumoButton(label: 'Active zones', onPress: () => KumoDialog.closeFrom(context, 'active')),
///   ),
/// );
/// ```
Future<T?> showKumoDrawer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  return Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  ).push<T>(KumoSheetRoute<T>(builder: builder, semanticLabel: semanticLabel));
}
