import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_routes.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../typography/kumo_text.dart';
import 'kumo_drawer.dart';
import 'kumo_layer_dialog.dart';

/// Desktop widths of a [KumoDialog] (Kumo's `size`). Below the `md`
/// breakpoint every size takes the full width minus 16px gutters.
enum KumoDialogSize {
  /// `sm:w-72`, 288px: short confirmations. Tighter padding and small buttons.
  sm(288, KumoSpace.s4, KumoSpace.s2, KumoButtonSize.sm),

  /// `sm:w-96`, 384px: the default.
  base(384, KumoSpace.s6, KumoSpace.s4, KumoButtonSize.base),

  /// `sm:w-[32rem]`, 512px: forms and longer content.
  lg(512, KumoSpace.s6, KumoSpace.s4, KumoButtonSize.base),

  /// `sm:w-[48rem]`, 768px: detailed views.
  xl(768, KumoSpace.s6, KumoSpace.s4, KumoButtonSize.base);

  const KumoDialogSize(this.width, this.padding, this.gap, this.buttonSize);

  /// Width on wide screens.
  final double width;

  /// Padding around the panel content (`KUMO_DIALOG_STYLING.padding`).
  final double padding;

  /// Space between the header and the body.
  final double gap;

  /// Size of the close button and of the buttons [showKumoAlertDialog] builds.
  final KumoButtonSize buttonSize;
}

/// The ARIA role of a dialog (Kumo's `role` on `Dialog.Root`).
enum KumoDialogRole {
  /// General-purpose modal. A backdrop tap closes it.
  dialog,

  /// A confirmation that needs an explicit choice (`role="alertdialog"`):
  /// the backdrop does not close it and no close X is shown by default.
  /// Escape still cancels, as the ARIA alert dialog pattern expects.
  alertDialog,
}

/// What a dialog's content needs from whoever presented it.
class _KumoDialogScope extends InheritedWidget {
  const _KumoDialogScope({required this.role, required this.close, required super.child});

  final KumoDialogRole role;
  final void Function(Object? result) close;

  @override
  bool updateShouldNotify(_KumoDialogScope oldWidget) => role != oldWidget.role;
}

/// Size of the [KumoDialog] a part sits in, so [KumoDialogClose] matches it.
class _KumoDialogPanelScope extends InheritedWidget {
  const _KumoDialogPanelScope({required this.size, required super.child});

  final KumoDialogSize size;

  @override
  bool updateShouldNotify(_KumoDialogPanelScope oldWidget) => size != oldWidget.size;
}

/// Kumo's dialog shadow: the `shadow-xl` shape at 3% instead of 10%, so the
/// ring carries the edge and the panel barely lifts off the backdrop.
const List<BoxShadow> _dialogShadow = [
  BoxShadow(offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5, color: Color(0x08000000)),
  BoxShadow(offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6, color: Color(0x08000000)),
];

/// Kumo's `Dialog`: a modal panel near the top of the screen over a
/// recessed backdrop.
///
/// Open it with [showKumoDialog], or keep it mounted with [KumoDialogRoot]
/// and drive `open` (Kumo's rule: never conditionally render a dialog).
///
/// ```dart
/// showKumoDialog<void>(
///   context,
///   builder: (context) => KumoDialog(
///     title: 'Rename Worker',
///     description: 'Routes keep working; the workers.dev URL changes.',
///     actions: [
///       const KumoDialogClose(label: 'Cancel'),
///       KumoButton(label: 'Rename', variant: KumoButtonVariant.primary, onPress: rename),
///     ],
///     child: nameField,
///   ),
/// );
/// ```
///
/// Layout: an optional [leading] badge and the title share the first row
/// with the close X; the description sits under them; [child] scrolls inside
/// the panel when it is taller than the screen allows; [actions] line up at
/// the end of the footer and wrap when they do not fit. While the body
/// scrolls, hairlines separate it from the sticky header and footer.
///
/// On screens narrower than 768px the panel takes the full width minus 16px
/// on each side. It sits 32px from the top (64px from 640px up), below the
/// safe area, and stops 16px above the keyboard.
class KumoDialog extends StatefulWidget {
  const KumoDialog({
    super.key,
    this.title,
    this.description,
    this.child,
    this.actions = const [],
    this.leading,
    this.size = KumoDialogSize.base,
    this.showCloseButton,
    this.padding,
    this.semanticLabel,
  });

  /// Heading, sentence case. Also names the dialog for screen readers.
  final String? title;

  /// Supporting copy under the title, in subtle text.
  final String? description;

  /// Body content. Scrolls inside the panel when it does not fit.
  final Widget? child;

  /// Footer buttons, end-aligned. Use [KumoDialogClose] for buttons that
  /// only close the dialog.
  final List<Widget> actions;

  /// Shown before the title, such as a 40px warning badge for destructive
  /// confirmations.
  final Widget? leading;
  final KumoDialogSize size;

  /// Shows the X button in the header. Defaults to true for
  /// [KumoDialogRole.dialog] with a [title], false for alert dialogs, which
  /// need an explicit choice.
  final bool? showCloseButton;

  /// Overrides the size's padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Accessible name when there is no [title].
  final String? semanticLabel;

  /// Closes the dialog [context] belongs to with [result]. Works for dialogs
  /// opened by [showKumoDialog], [KumoDialogRoot], [showKumoLayerDialog] and
  /// [showKumoDrawer].
  ///
  /// ```dart
  /// KumoButton(label: 'Create token', onPress: () => KumoDialog.closeFrom(context, token))
  /// ```
  static void closeFrom(BuildContext context, [Object? result]) {
    final scope = context.getInheritedWidgetOfExactType<_KumoDialogScope>();
    if (scope != null) {
      scope.close(result);
      return;
    }
    KumoSheetScope.closeFrom(context, result);
  }

  /// The role the dialog around [context] was opened with.
  static KumoDialogRole roleOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_KumoDialogScope>()?.role ?? KumoDialogRole.dialog;

  @override
  State<KumoDialog> createState() => _KumoDialogState();
}

class _KumoDialogState extends State<KumoDialog> {
  final ScrollController _scroll = ScrollController();
  bool _contentAbove = false;
  bool _contentBelow = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics m) {
    final above = m.pixels > m.minScrollExtent + 0.5;
    final below = m.pixels < m.maxScrollExtent - 0.5;
    if (above != _contentAbove || below != _contentBelow) {
      // Metrics notifications arrive during layout; wait for the frame.
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
    final kumo = context.kumo;
    final media = MediaQuery.of(context);
    final role = KumoDialog.roleOf(context);
    final size = widget.size;
    final screen = media.size;

    final available = screen.width - 2 * KumoSpace.s4;
    final narrow = context.kumoIsNarrow;
    final duration = KumoMotion.duration(context, KumoDurations.moderate);
    final top = media.padding.top + (screen.width < KumoBreakpoints.sm ? KumoSpace.s8 : KumoSpace.s16);
    final bottomInset = media.viewInsets.bottom > media.padding.bottom ? media.viewInsets.bottom : media.padding.bottom;

    final pad = (widget.padding ?? EdgeInsets.all(size.padding)).resolve(Directionality.of(context));
    final showClose = widget.showCloseButton ?? (role == KumoDialogRole.dialog && widget.title != null);
    final hasHeader = widget.title != null || widget.description != null || widget.leading != null || showClose;
    final hasFooter = widget.actions.isNotEmpty;
    final hasBody = widget.child != null;

    Widget? header;
    if (hasHeader) {
      header = Padding(
        padding: EdgeInsets.fromLTRB(pad.left, pad.top, pad.right, hasBody || hasFooter ? 0 : pad.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: widget.leading != null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              spacing: KumoSpace.s3,
              children: [
                ?widget.leading,
                Expanded(child: widget.title != null ? KumoDialogTitle(widget.title!) : const SizedBox.shrink()),
                if (showClose) const KumoDialogClose(),
              ],
            ),
            if (widget.description != null) ...[
              const SizedBox(height: KumoSpace.s2),
              KumoDialogDescription(widget.description!),
            ],
          ],
        ),
      );
    }

    Widget? body;
    if (hasBody) {
      body = NotificationListener<ScrollMetricsNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) => n.depth == 0 ? _onMetrics(n.metrics) : false,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(
              pad.left,
              hasHeader ? size.gap : pad.top,
              pad.right,
              hasFooter ? 0 : pad.bottom,
            ),
            child: widget.child,
          ),
        ),
      );
    }

    final line = kumo.colors.hairline;
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: kumo.colors.base,
        borderRadius: BorderRadius.circular(KumoRadius.xl),
        border: KumoRing.border(kumo.colors.line),
        boxShadow: _dialogShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KumoRadius.xl),
        // When the content grows or shrinks (a step changes, an error
        // appears) the panel follows it instead of jumping. The content is
        // laid out at its new size at once and clipped while the edge moves.
        child: _SmoothHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              if (body != null) ...[
                if (header != null) _Separator(color: _contentAbove ? line : null),
                Flexible(child: body),
                if (hasFooter) _Separator(color: _contentBelow ? line : null),
              ],
              if (hasFooter)
                Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, pad.left, pad.right, pad.bottom),
                  child: KumoDialogFooter(children: widget.actions),
                ),
            ],
          ),
        ),
      ),
    );

    return _KumoDialogPanelScope(
      size: size,
      child: Padding(
        padding: EdgeInsets.only(top: top, bottom: bottomInset + KumoSpace.s4),
        child: Align(
          alignment: Alignment.topCenter,
          // A new size animates the width; the screen edge clamps it at once,
          // so resizing a window never lags behind.
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: size.width),
            duration: duration,
            curve: KumoCurves.standard,
            builder: (context, sizeWidth, child) =>
                SizedBox(width: narrow || sizeWidth > available ? available : sizeWidth, child: child),
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              role: role == KumoDialogRole.alertDialog ? SemanticsRole.alertDialog : SemanticsRole.dialog,
              label: widget.title == null ? widget.semanticLabel : null,
              child: panel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Takes its child's height through a spring, so the panel edge glides to a
/// new content height. The spring retargets from its current height and
/// speed whenever the child changes again, including every frame of a width
/// change that rewraps the text, so it never jumps. Reduced motion follows
/// the child at once.
class _SmoothHeight extends StatefulWidget {
  const _SmoothHeight({required this.child});

  final Widget child;

  @override
  State<_SmoothHeight> createState() => _SmoothHeightState();
}

class _SmoothHeightState extends State<_SmoothHeight> with SingleTickerProviderStateMixin {
  late final AnimationController _height;
  bool _known = false;

  @override
  void initState() {
    super.initState();
    _height = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _height.dispose();
    super.dispose();
  }

  void _onChildHeight(double h) {
    if (!mounted) return;
    if (!_known || KumoMotion.reduceMotion(context)) {
      _height.value = h;
      if (!_known) setState(() => _known = true);
      return;
    }
    if (h == _height.value && !_height.isAnimating) return;
    KumoMotion.springTo(_height, h, velocity: _height.velocity);
  }

  @override
  Widget build(BuildContext context) {
    final follow = !_known || KumoMotion.reduceMotion(context);
    return AnimatedBuilder(
      animation: _height,
      builder: (context, child) =>
          _HeightBox(height: follow ? null : _height.value, onChildHeight: _onChildHeight, child: child),
      child: widget.child,
    );
  }
}

/// Lays its child out under the incoming constraints and takes [height]
/// (clamped to those constraints) instead of the child's, reporting the
/// child's height after each layout that changes it.
class _HeightBox extends SingleChildRenderObjectWidget {
  const _HeightBox({required this.height, required this.onChildHeight, super.child});

  final double? height;
  final ValueChanged<double> onChildHeight;

  @override
  _RenderHeightBox createRenderObject(BuildContext context) => _RenderHeightBox(height, onChildHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderHeightBox renderObject) {
    renderObject
      ..height = height
      ..onChildHeight = onChildHeight;
  }
}

class _RenderHeightBox extends RenderProxyBox {
  _RenderHeightBox(this._height, this.onChildHeight);

  double? _height;
  set height(double? value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  ValueChanged<double> onChildHeight;
  double? _reported;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    final natural = child.size.height;
    size = constraints.constrain(Size(child.size.width, _height ?? natural));
    if (natural != _reported) {
      _reported = natural;
      // Layout cannot start an animation; the spring picks this up next frame.
      SchedulerBinding.instance.addPostFrameCallback((_) => onChildHeight(natural));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (child.size.height <= size.height + 0.01) {
      context.paintChild(child, offset);
      return;
    }
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
      oldLayer: layer as ClipRectLayer?,
    );
  }

  @override
  void dispose() {
    layer = null;
    super.dispose();
  }
}

/// A 1px line that keeps its space whether or not it is visible, so the
/// sticky header and footer never shift when the separator appears.
class _Separator extends StatelessWidget {
  const _Separator({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(height: 1, child: ColoredBox(color: color ?? const Color(0x00000000)));
}

/// Kumo's `Dialog.Title`: a 20px semibold heading that names the dialog for
/// screen readers. [KumoDialog] renders one from its `title`; use it
/// directly when composing a custom layout.
///
/// ```dart
/// const KumoDialogTitle('Delete zone')
/// ```
class KumoDialogTitle extends StatelessWidget {
  const KumoDialogTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      namesRoute: true,
      container: true,
      child: KumoText(text, variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 2),
    );
  }
}

/// Kumo's `Dialog.Description`: subtle 14px supporting copy.
///
/// ```dart
/// const KumoDialogDescription('DNS records for example.com stop resolving.')
/// ```
class KumoDialogDescription extends StatelessWidget {
  const KumoDialogDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => KumoText(text, variant: KumoTextVariant.secondary);
}

/// The action row of a dialog: buttons aligned to the end with 8px between
/// them, wrapping onto a second line when they do not fit (narrow screens,
/// large text).
///
/// ```dart
/// KumoDialogFooter(children: [
///   const KumoDialogClose(label: 'Cancel'),
///   KumoButton(label: 'Purge cache', variant: KumoButtonVariant.primary, onPress: purge),
/// ])
/// ```
class KumoDialogFooter extends StatelessWidget {
  const KumoDialogFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: KumoSpace.s2,
      runSpacing: KumoSpace.s2,
      children: children,
    );
  }
}

/// Kumo's `Dialog.Close`: a button that closes the dialog it is in.
///
/// Without a [label] it is the square X button from Kumo's dialog header,
/// announced with [KumoStrings.close]. With a label it is a regular button,
/// secondary by default, that closes the dialog with [result] after running
/// [onPress].
///
/// ```dart
/// const KumoDialogClose()                       // the X
/// const KumoDialogClose(label: 'Cancel', result: false)
/// KumoDialogClose(label: 'Delete', variant: KumoButtonVariant.destructive, result: true)
/// ```
class KumoDialogClose extends StatelessWidget {
  const KumoDialogClose({
    super.key,
    this.label,
    this.variant = KumoButtonVariant.secondary,
    this.size,
    this.result,
    this.onPress,
    this.semanticLabel,
    this.autofocus = false,
    this.disabled = false,
  });

  /// Button text. Null renders the icon-only X.
  final String? label;
  final KumoButtonVariant variant;

  /// Defaults to the size the surrounding [KumoDialogSize] uses.
  final KumoButtonSize? size;

  /// Value the dialog closes with (what `showKumoDialog` returns).
  final Object? result;

  /// Runs before the dialog closes.
  final VoidCallback? onPress;

  /// Accessible name of the X. Defaults to [KumoStrings.close].
  final String? semanticLabel;
  final bool autofocus;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final buttonSize =
        size ??
        context.dependOnInheritedWidgetOfExactType<_KumoDialogPanelScope>()?.size.buttonSize ??
        KumoButtonSize.base;
    void close() {
      onPress?.call();
      KumoDialog.closeFrom(context, result);
    }

    if (label == null) {
      return KumoButton(
        icon: KumoIcons.x,
        shape: KumoButtonShape.square,
        variant: variant,
        size: buttonSize,
        semanticLabel: semanticLabel ?? context.kumoStrings.close,
        autofocus: autofocus,
        disabled: disabled,
        onPress: close,
      );
    }
    return KumoButton(
      label: label,
      variant: variant,
      size: buttonSize,
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      disabled: disabled,
      onPress: close,
    );
  }
}

/// Opens [builder]'s dialog (usually a [KumoDialog]) over a Kumo backdrop
/// and returns the value it closes with.
///
/// The panel fades in and scales up from 0.9 (150ms) and leaves the same
/// way. Escape and the system back gesture close it; a backdrop tap closes
/// it too unless [role] is [KumoDialogRole.alertDialog] or [dismissible] is
/// false. Focus moves into the dialog, Tab stays inside, and focus returns
/// to the trigger on close.
///
/// ```dart
/// final name = await showKumoDialog<String>(
///   context,
///   builder: (context) => KumoDialog(
///     title: 'Create R2 bucket',
///     actions: [
///       const KumoDialogClose(label: 'Cancel'),
///       KumoButton(
///         label: 'Create bucket',
///         variant: KumoButtonVariant.primary,
///         onPress: () => KumoDialog.closeFrom(context, 'assets'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showKumoDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  KumoDialogRole role = KumoDialogRole.dialog,
  bool? dismissible,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  late final KumoDialogRoute<T> route;
  route = KumoDialogRoute<T>(
    dismissible: dismissible ?? role == KumoDialogRole.dialog,
    semanticLabel: semanticLabel,
    builder: (context) => _KumoDialogScope(
      role: role,
      close: (result) => _closeRoute(route, result is T ? result : null),
      child: Builder(builder: builder),
    ),
  );
  return navigator.push(route);
}

void _closeRoute<T>(Route<T> route, [T? result]) {
  final navigator = route.navigator;
  if (navigator == null) return;
  if (route.isCurrent) {
    navigator.pop(result);
  } else if (route.isActive) {
    navigator.removeRoute(route, result);
  }
}

/// Asks the user to confirm an action and returns true only when they pick
/// [confirmLabel]. Cancel, Escape and the back gesture return false.
///
/// Built on [KumoDialog] with [KumoDialogRole.alertDialog], so a backdrop tap
/// does not dismiss it. With [destructive], the confirm button is red, a
/// warning badge leads the title, and Cancel takes initial focus so Enter
/// never deletes by accident.
///
/// ```dart
/// final confirmed = await showKumoAlertDialog(
///   context,
///   title: 'Delete image-resizer?',
///   description: 'Routes pointing at this Worker stop serving traffic.',
///   confirmLabel: 'Delete Worker',
///   destructive: true,
/// );
/// if (confirmed) deleteWorker();
/// ```
Future<bool> showKumoAlertDialog(
  BuildContext context, {
  required String title,
  String? description,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
  KumoDialogSize size = KumoDialogSize.base,
  bool useRootNavigator = true,
}) async {
  final confirmed = await showKumoDialog<bool>(
    context,
    role: KumoDialogRole.alertDialog,
    useRootNavigator: useRootNavigator,
    builder: (context) {
      final badgeIcon = icon ?? (destructive ? KumoIcons.warningFill : null);
      return KumoDialog(
        title: title,
        description: description,
        size: size,
        leading: badgeIcon == null ? null : _AlertBadge(icon: badgeIcon, destructive: destructive),
        actions: [
          KumoDialogClose(label: cancelLabel ?? context.kumoStrings.cancel, result: false, autofocus: destructive),
          KumoDialogClose(
            label: confirmLabel,
            result: true,
            variant: destructive ? KumoButtonVariant.destructive : KumoButtonVariant.primary,
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// The 40px round badge Kumo puts before the title of confirmation dialogs.
class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.icon, required this.destructive});

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return Container(
      width: KumoSpace.s10,
      height: KumoSpace.s10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (destructive ? c.danger : c.info).withValues(alpha: 0.2),
      ),
      alignment: Alignment.center,
      child: KumoIcon(icon, size: 20, color: destructive ? KumoColor.textDanger : KumoColor.textInfo),
    );
  }
}

/// Keeps a dialog mounted and opens or closes it from [open], the way
/// Kumo's `Dialog.Root` does. The dialog animates out when [open] turns
/// false, and every dismissal the user makes (X, Cancel, Escape, backdrop,
/// back gesture, swipe) calls [onOpenChange] with false.
///
/// [dialog] is rebuilt with this widget, so state such as a loading flag
/// reaches the open dialog. It is usually a [KumoDialog]; a
/// [KumoLayerDialog] or [KumoDrawer] opens in the sheet route those use.
///
/// ```dart
/// KumoDialogRoot(
///   open: _open,
///   onOpenChange: (open) => setState(() => _open = open),
///   dialog: KumoDialog(
///     title: 'Edit DNS record',
///     actions: [
///       const KumoDialogClose(label: 'Cancel'),
///       KumoButton(label: 'Save record', variant: KumoButtonVariant.primary, loading: _saving, onPress: save),
///     ],
///     child: recordForm,
///   ),
///   child: KumoButton(label: 'Edit record', onPress: () => setState(() => _open = true)),
/// )
/// ```
class KumoDialogRoot extends StatefulWidget {
  const KumoDialogRoot({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.dialog,
    required this.child,
    this.role = KumoDialogRole.dialog,
    this.dismissible,
    this.semanticLabel,
    this.useRootNavigator = true,
  });

  final bool open;
  final ValueChanged<bool> onOpenChange;

  /// The dialog shown while [open] is true.
  final Widget dialog;

  /// The page content, usually including the trigger button.
  final Widget child;
  final KumoDialogRole role;

  /// Backdrop tap closes the dialog. Defaults to true for
  /// [KumoDialogRole.dialog], false for alert dialogs. Read when the dialog
  /// opens.
  final bool? dismissible;
  final String? semanticLabel;
  final bool useRootNavigator;

  @override
  State<KumoDialogRoot> createState() => _KumoDialogRootState();
}

class _KumoDialogRootState extends State<KumoDialogRoot> {
  late final ValueNotifier<Widget> _dialog;
  Route<void>? _route;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _dialog = ValueNotifier(widget.dialog);
    if (widget.open) _scheduleSync();
  }

  @override
  void didUpdateWidget(KumoDialogRoot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSync();
  }

  // The dialog lives in another route; changing it or pushing a route while
  // this subtree builds would mark widgets outside it dirty, so both wait for
  // the end of the frame.
  void _scheduleSync() {
    if (_syncScheduled) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      _dialog.value = widget.dialog;
      final route = _route;
      if (widget.open && route == null) {
        _push();
      } else if (!widget.open && route != null) {
        _route = null;
        _closeRoute(route);
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _push() {
    final navigator = Navigator.of(context, rootNavigator: widget.useRootNavigator);
    late final Route<void> route;
    Widget content(BuildContext context) => _KumoDialogScope(
      role: widget.role,
      close: (_) => _closeRoute(route),
      child: ValueListenableBuilder<Widget>(valueListenable: _dialog, builder: (context, dialog, _) => dialog),
    );
    final usesSheet = widget.dialog is KumoLayerDialog || widget.dialog is KumoDrawer;
    route = usesSheet
        ? KumoSheetRoute<void>(builder: content, semanticLabel: widget.semanticLabel)
        : KumoDialogRoute<void>(
            builder: content,
            dismissible: widget.dismissible ?? widget.role == KumoDialogRole.dialog,
            semanticLabel: widget.semanticLabel,
          );
    _route = route;
    navigator.push(route).then((_) {
      if (_route != route) return;
      _route = null;
      if (mounted && widget.open) widget.onOpenChange(false);
    });
  }

  @override
  void dispose() {
    final route = _route;
    _route = null;
    final dialog = _dialog;
    // The navigator cannot change while the tree is being torn down.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (route != null && route.isActive) route.navigator?.removeRoute(route);
      SchedulerBinding.instance.addPostFrameCallback((_) => dialog.dispose());
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
