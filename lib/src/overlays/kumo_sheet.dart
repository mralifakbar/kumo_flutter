import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../system/kumo_focus_trap.dart';
import '../system/kumo_haptics.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import 'kumo_routes.dart';
import 'kumo_scrim.dart';

/// The screen edge a sheet is attached to.
enum KumoSheetEdge { bottom, top, start, end }

/// Lets descendants close the sheet they are in.
class KumoSheetScope extends InheritedWidget {
  const KumoSheetScope({super.key, required this.close, required super.child});

  final void Function([Object? result]) close;

  static KumoSheetScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<KumoSheetScope>();

  /// Closes the sheet that [context] belongs to. Works from inside the sheet
  /// and from the context of the widget that builds it (a State whose build
  /// returns the tray), where the scope is not yet an ancestor: the sheet's
  /// route is popped instead, which animates out along the same path.
  static void closeFrom(BuildContext context, [Object? result]) {
    final scope = context.getInheritedWidgetOfExactType<KumoSheetScope>();
    if (scope != null) {
      scope.close(result);
      return;
    }
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) Navigator.of(context).pop(result);
  }

  @override
  bool updateShouldNotify(KumoSheetScope oldWidget) => false;
}

/// A sheet attached to a screen edge. Usually opened with [showKumoSheet].
///
/// A sheet that follows the finger, rubberbands past its open position,
/// projects release velocity to pick a snap point or dismiss, and can be
/// grabbed mid-animation. Draws its own scrim, dimmed in proportion to how
/// far the sheet is open.
class KumoSheet extends StatefulWidget {
  const KumoSheet({
    super.key,
    required this.edge,
    required this.child,
    this.header,
    this.maxExtentFraction = 0.75,
    this.snapPoints,
    this.initialSnapPointIndex,
    this.preventDismissGestures = false,
    this.onCloseComplete,
    this.onOpenComplete,
    this.accessibilityLabel,
    this.borderRadius = KumoRadius.xl,
    this.reduceMotion,
  });

  final KumoSheetEdge edge;

  /// Content of the sheet surface.
  final Widget child;

  /// Drawn outside the surface, on the side facing the screen center (the
  /// outside handle bar of a tray).
  final Widget? header;

  /// Largest share of the screen the sheet may take along its axis.
  final double maxExtentFraction;

  /// Visible heights as fractions of the available screen height, for bottom
  /// and top sheets. Null sizes the sheet to its content.
  final List<double>? snapPoints;

  /// Index into the sorted [snapPoints] to open at. Defaults to the smallest.
  final int? initialSnapPointIndex;
  final bool preventDismissGestures;

  /// Called when the sheet finishes leaving and is not inside a sheet route.
  final VoidCallback? onCloseComplete;
  final VoidCallback? onOpenComplete;
  final String? accessibilityLabel;

  /// Radius of the corners facing the screen center (bottom and top sheets).
  final double borderRadius;

  /// Overrides the platform reduced-motion setting.
  final bool? reduceMotion;

  @override
  State<KumoSheet> createState() => KumoSheetState();
}

class KumoSheetState extends State<KumoSheet> with TickerProviderStateMixin {
  late final AnimationController _offset;
  late final AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _offset = AnimationController.unbounded(vsync: this, value: 0)..addListener(_onOffsetTick);
    _fade = AnimationController(vsync: this, duration: KumoDurations.moderate);
  }

  double _extent = 0;
  bool _measured = false;
  bool _entered = false;
  List<double> _snapOffsets = const [0];
  int _snapIndex = 0;

  bool _dragging = false;
  double _dragRaw = 0;
  bool _scrollDragActive = false;

  bool _exiting = false;
  bool _exitFinished = false;
  Object? _exitResult;

  KumoSheetRoute<dynamic>? _route;
  Animation<double>? _routeAnimation;

  bool get _reduceMotion => widget.reduceMotion ?? KumoMotion.reduceMotion(context);

  bool get _vertical => widget.edge == KumoSheetEdge.bottom || widget.edge == KumoSheetEdge.top;

  /// Converts a screen-axis delta into an offset delta (positive = toward dismiss).
  double get _sign {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return switch (widget.edge) {
      KumoSheetEdge.bottom => 1,
      KumoSheetEdge.top => -1,
      KumoSheetEdge.start => rtl ? 1 : -1,
      KumoSheetEdge.end => rtl ? -1 : 1,
    };
  }

  double get _maxOpenOffset => _snapOffsets.last;

  /// Size of the area the sheet lives in, from the last layout.
  Size _area = Size.zero;

  double get _rubberDimension {
    final size = _area == Size.zero ? MediaQuery.sizeOf(context) : _area;
    return _vertical ? size.height : size.width;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final sheetRoute = route is KumoSheetRoute ? route : null;
    if (sheetRoute != _route) {
      _routeAnimation?.removeStatusListener(_onRouteStatus);
      _route = sheetRoute;
      _routeAnimation = sheetRoute?.animation;
      _routeAnimation?.addStatusListener(_onRouteStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_onRouteStatus);
    _offset.dispose();
    _fade.dispose();
    super.dispose();
  }

  void _onRouteStatus(AnimationStatus status) {
    // A pop that did not come from this sheet (back button, Escape,
    // Navigator.pop in app code): leave along the entry path.
    if (status == AnimationStatus.reverse && !_exiting) _startExit(velocity: 0);
  }

  void _onSize(Size size) {
    if (!mounted) return;
    final extent = _vertical ? size.height : size.width;
    final available = _availableExtent;
    final points = widget.snapPoints;
    List<double> offsets;
    if (points == null || points.isEmpty || !_vertical) {
      offsets = const [0];
    } else {
      final sorted = [...points]..sort();
      final maxPoint = sorted.last;
      offsets = [for (final p in sorted.reversed) (maxPoint - p) * available];
    }
    final changed = extent != _extent || !_listEquals(offsets, _snapOffsets);
    setState(() {
      _extent = extent;
      _snapOffsets = offsets;
      _measured = true;
    });
    if (!_entered) {
      _entered = true;
      _enter();
    } else if (changed && !_dragging && !_exiting) {
      _snapIndex = _snapIndex.clamp(0, _snapOffsets.length - 1);
      _settleTo(_snapIndex, 0);
    }
  }

  double get _availableExtent {
    final size = _area == Size.zero ? MediaQuery.sizeOf(context) : _area;
    final padding = MediaQuery.paddingOf(context);
    return _vertical ? size.height - padding.top - padding.bottom : size.width;
  }

  void _enter() {
    final points = widget.snapPoints;
    final count = _snapOffsets.length;
    // _snapOffsets is ordered from most open (0) to least open.
    _snapIndex = points == null || points.isEmpty
        ? 0
        : (count - 1 - (widget.initialSnapPointIndex ?? 0)).clamp(0, count - 1);
    final target = _snapOffsets[_snapIndex];
    if (_reduceMotion) {
      _offset.value = target;
      _fade.forward(from: 0).whenComplete(() => widget.onOpenComplete?.call());
      return;
    }
    _fade.value = 1;
    _offset.value = _extent;
    KumoMotion.springTo(_offset, target, spring: KumoSprings.sheet).whenComplete(() {
      if (mounted && !_exiting && !_dragging) widget.onOpenComplete?.call();
    });
  }

  double _visualFromRaw(double raw) {
    if (raw < 0) return -KumoMotion.rubberband(-raw, _rubberDimension);
    if (widget.preventDismissGestures && raw > _maxOpenOffset) {
      return _maxOpenOffset + KumoMotion.rubberband(raw - _maxOpenOffset, _rubberDimension);
    }
    return raw;
  }

  double _rawFromVisual(double visual) {
    double inverse(double r) {
      const c = 0.55;
      final d = _rubberDimension;
      if (r >= d) return r * 10;
      return r * d / (c * (d - r));
    }

    if (visual < 0) return -inverse(-visual);
    if (widget.preventDismissGestures && visual > _maxOpenOffset) {
      return _maxOpenOffset + inverse(visual - _maxOpenOffset);
    }
    return visual;
  }

  void _beginDrag() {
    if (_exitFinished || (_route?.isExiting ?? false)) return;
    _offset.stop();
    _exiting = false;
    _dragging = true;
    _dragRaw = _rawFromVisual(_offset.value);
  }

  void _dragBy(double offsetDelta) {
    if (!_dragging) return;
    _dragRaw += offsetDelta;
    _offset.value = _visualFromRaw(_dragRaw);
  }

  void _endDrag(double offsetVelocity) {
    if (!_dragging) return;
    _dragging = false;
    final current = _offset.value;
    final projected = current + KumoMotion.project(offsetVelocity);
    final dismissible = !widget.preventDismissGestures;

    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < _snapOffsets.length; i++) {
      final d = (projected - _snapOffsets[i]).abs();
      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }
    final dismissDistance = (projected - _extent).abs();
    // Dismiss only when the gesture is heading toward the edge, so a sheet
    // that is pulled down and then pushed back up stays open.
    if (dismissible && dismissDistance < bestDistance && offsetVelocity >= 0) {
      _startExit(velocity: offsetVelocity);
      return;
    }
    if (bestIndex != _snapIndex) kumoHaptic(KumoHaptic.selection);
    _settleTo(bestIndex, offsetVelocity);
  }

  void _settleTo(int index, double velocity) {
    _snapIndex = index;
    final target = _snapOffsets[index];
    if (_reduceMotion) {
      _offset.value = target;
      return;
    }
    KumoMotion.springTo(_offset, target, spring: KumoSprings.sheet, velocity: velocity);
  }

  /// Closes the sheet with an animation along its entry path.
  void close([Object? result]) {
    if (_exiting || _exitFinished) return;
    _exitResult = result;
    _startExit(velocity: 0);
  }

  void _startExit({required double velocity}) {
    if (_exitFinished) return;
    _exiting = true;
    _dragging = false;
    _scrollDragActive = false;
    if (!_measured || _extent <= 0) {
      _finishExit();
      return;
    }
    if (_reduceMotion) {
      _fade.reverse().whenComplete(() {
        if (_exiting) _finishExit();
      });
      return;
    }
    KumoMotion.springTo(_offset, _extent, spring: KumoSprings.sheet, velocity: math.max(velocity, 0)).whenComplete(() {
      if (_exiting) _finishExit();
    });
  }

  void _onOffsetTick() {
    // The spring overshoots past the edge before settling; the sheet is
    // already invisible once it crosses it, so finish there.
    if (_exiting && !_exitFinished && _measured && _offset.value >= _extent) {
      _offset.stop();
      _finishExit();
    }
  }

  void _finishExit() {
    if (_exitFinished) return;
    _exitFinished = true;
    final route = _route;
    if (route != null) {
      final alreadyPopping = route.isExiting;
      route.completeExit();
      if (!alreadyPopping) {
        final navigator = route.navigator;
        if (navigator != null) {
          if (route.isCurrent) {
            navigator.pop(_exitResult);
          } else if (route.isActive) {
            navigator.removeRoute(route, _exitResult);
          }
        }
      }
    } else {
      widget.onCloseComplete?.call();
    }
  }

  // Scroll hand-off: called by _SheetScrollPhysics for drags that start on
  // scrollable content inside a bottom sheet.
  double _handleScrollOffset(ScrollMetrics position, double offset) {
    if (widget.edge != KumoSheetEdge.bottom || position.axisDirection != AxisDirection.down) return offset;
    final atTop = position.pixels <= position.minScrollExtent;
    final displaced = _offset.value > 0.5;
    if (!_scrollDragActive) {
      final wantsSheet = (offset > 0 && atTop) || (offset < 0 && displaced);
      if (!wantsSheet || (_route?.isExiting ?? false) || _exitFinished) return offset;
      _scrollDragActive = true;
      _beginDrag();
    }
    final nextRaw = _dragRaw + offset;
    if (offset < 0 && nextRaw <= 0) {
      // Sheet is fully open again; the rest of the drag scrolls the content.
      final remainder = nextRaw;
      _dragBy(-_dragRaw);
      _scrollDragActive = false;
      _endDrag(0);
      return remainder;
    }
    _dragBy(offset);
    return 0;
  }

  bool _handleScrollRelease(double scrollVelocity) {
    if (!_scrollDragActive) return false;
    _scrollDragActive = false;
    _endDrag(-scrollVelocity);
    return true;
  }

  void _onDragStart(DragStartDetails _) => _beginDrag();

  void _onDragUpdate(DragUpdateDetails d) => _dragBy(d.primaryDelta! * _sign);

  void _onDragEnd(DragEndDetails d) => _endDrag(d.primaryVelocity! * _sign);

  void _onDragCancel() => _endDrag(0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _area = constraints.biggest;
        return _buildSheet(context, constraints.biggest);
      },
    );
  }

  Widget _buildSheet(BuildContext context, Size size) {
    final theme = context.kumo;
    final padding = MediaQuery.paddingOf(context);
    final surfaceColor = theme.colors.base;
    final radius = Radius.circular(widget.borderRadius);
    final borderRadius = switch (widget.edge) {
      KumoSheetEdge.bottom => BorderRadius.only(topLeft: radius, topRight: radius),
      KumoSheetEdge.top => BorderRadius.only(bottomLeft: radius, bottomRight: radius),
      _ => BorderRadius.zero,
    };
    final line = BorderSide(color: theme.colors.line);
    final border = theme.isDark
        ? switch (widget.edge) {
            KumoSheetEdge.bottom => Border(top: line, left: line, right: line),
            KumoSheetEdge.top => Border(bottom: line, left: line, right: line),
            KumoSheetEdge.start => BorderDirectional(end: line),
            KumoSheetEdge.end => BorderDirectional(start: line),
          }
        : null;

    // Sheets live in their own route, outside the app's DefaultTextStyle.
    Widget body = DefaultTextStyle(
      style: theme.text(),
      child: IconTheme(
        data: IconThemeData(color: theme.colors.textDefault, size: 16),
        child: widget.child,
      ),
    );
    if (widget.edge == KumoSheetEdge.bottom) {
      body = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(physics: _SheetScrollPhysics(this)),
        child: body,
      );
    }

    final points = widget.snapPoints;
    final BoxConstraints bodyConstraints;
    if (_vertical) {
      final available = size.height - padding.top;
      bodyConstraints = points != null && points.isNotEmpty
          ? BoxConstraints.tightFor(height: points.reduce(math.max) * available)
          : BoxConstraints(maxHeight: available * widget.maxExtentFraction);
    } else {
      bodyConstraints = BoxConstraints.tightFor(width: size.width * widget.maxExtentFraction, height: size.height);
    }

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        // Flutter rejects a directional border combined with a radius; side
        // sheets have square corners, so pass no radius there.
        borderRadius: borderRadius == BorderRadius.zero ? null : borderRadius,
        border: border,
        boxShadow: KumoShadow.xl.boxShadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: ConstrainedBox(constraints: bodyConstraints, child: body),
      ),
    );

    final measured = _SizeReporter(
      onSize: _onSize,
      child: _vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.edge == KumoSheetEdge.bottom ? [?widget.header, surface] : [surface, ?widget.header],
            )
          : surface,
    );

    final draggable = !widget.preventDismissGestures || (points != null && points.length > 1);
    Widget sheet = AnimatedBuilder(
      animation: _offset,
      child: measured,
      builder: (context, child) {
        final value = _offset.value;
        final overdrag = value < 0 ? -value : 0.0;
        final translate = value > 0 ? value : 0.0;
        final filler = overdrag > 0
            ? (_vertical
                  ? SizedBox(
                      height: overdrag,
                      child: ColoredBox(color: surfaceColor),
                    )
                  : SizedBox(
                      width: overdrag,
                      child: ColoredBox(color: surfaceColor),
                    ))
            : null;
        final Widget content = switch (widget.edge) {
          KumoSheetEdge.bottom => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [child!, ?filler],
          ),
          KumoSheetEdge.top => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [?filler, child!],
          ),
          KumoSheetEdge.start => Row(mainAxisSize: MainAxisSize.min, children: [?filler, child!]),
          KumoSheetEdge.end => Row(mainAxisSize: MainAxisSize.min, children: [child!, ?filler]),
        };
        final screenDelta = translate * _sign;
        // The stretch filler can make the sheet taller than the screen; let it
        // overflow toward the screen center instead of failing layout.
        return Transform.translate(
          offset: _vertical ? Offset(0, screenDelta) : Offset(screenDelta, 0),
          child: OverflowBox(
            fit: OverflowBoxFit.deferToChild,
            alignment: switch (widget.edge) {
              KumoSheetEdge.bottom => Alignment.bottomCenter,
              KumoSheetEdge.top => Alignment.topCenter,
              KumoSheetEdge.start => AlignmentDirectional.centerStart,
              KumoSheetEdge.end => AlignmentDirectional.centerEnd,
            },
            maxHeight: _vertical ? double.infinity : null,
            maxWidth: _vertical ? null : double.infinity,
            child: content,
          ),
        );
      },
    );

    if (draggable) {
      sheet = _vertical
          ? GestureDetector(
              onVerticalDragStart: _onDragStart,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              onVerticalDragCancel: _onDragCancel,
              child: sheet,
            )
          : GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              child: sheet,
            );
    }

    sheet = Semantics(explicitChildNodes: true, label: widget.accessibilityLabel, child: sheet);

    final alignment = switch (widget.edge) {
      KumoSheetEdge.bottom => Alignment.bottomCenter,
      KumoSheetEdge.top => Alignment.topCenter,
      KumoSheetEdge.start => AlignmentDirectional.centerStart,
      KumoSheetEdge.end => AlignmentDirectional.centerEnd,
    };

    final layered = Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_offset, _fade]),
          builder: (context, _) {
            final open = _extent <= 0 ? 0.0 : (1 - _offset.value / _extent).clamp(0.0, 1.0);
            return KumoScrim(
              opacity: _measured ? open * _fade.value : 0,
              onPress: widget.preventDismissGestures ? null : close,
            );
          },
        ),
        Align(
          alignment: alignment,
          child: FadeTransition(
            opacity: _fade,
            child: Opacity(opacity: _measured ? 1 : 0, child: sheet),
          ),
        ),
      ],
    );

    return KumoSheetScope(
      close: close,
      child: KumoFocusTrap(onEscPress: close, child: layered),
    );
  }
}

bool _listEquals(List<double> a, List<double> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > 0.5) return false;
  }
  return true;
}

/// Routes drags on scrollable content to the sheet: pulling down at the top
/// of the content moves the sheet, and pushing a displaced sheet back up
/// moves the sheet before the content scrolls again.
class _SheetScrollPhysics extends ScrollPhysics {
  const _SheetScrollPhysics(this.sheet, {super.parent});

  final KumoSheetState sheet;

  @override
  _SheetScrollPhysics applyTo(ScrollPhysics? ancestor) => _SheetScrollPhysics(sheet, parent: buildParent(ancestor));

  @override
  ScrollPhysics buildParent(ScrollPhysics? ancestor) => super.buildParent(ancestor) ?? const ClampingScrollPhysics();

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Picker wheels scroll on their own; they never drag the sheet.
    if (!sheet.mounted || position is FixedExtentMetrics) return super.applyPhysicsToUserOffset(position, offset);
    final remaining = sheet._handleScrollOffset(position, offset);
    if (remaining == 0) return 0;
    return super.applyPhysicsToUserOffset(position, remaining);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (sheet.mounted && position is! FixedExtentMetrics && sheet._handleScrollRelease(velocity)) return null;
    return super.createBallisticSimulation(position, velocity);
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  _RenderSizeReporter createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final current = size;
    if (current != _reported) {
      _reported = current;
      SchedulerBinding.instance.addPostFrameCallback((_) => onSize(current));
    }
  }
}

/// The grab handle at the top of a bottom sheet. It shows the sheet can be
/// dragged; screen reader users can activate it to close the sheet.
class KumoSheetHandle extends StatelessWidget {
  const KumoSheetHandle({super.key, this.onAccessibilityPress, this.semanticLabel = 'Close'});

  final VoidCallback? onAccessibilityPress;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Semantics(
      container: true,
      button: onAccessibilityPress != null,
      label: semanticLabel,
      onTap: onAccessibilityPress,
      child: Padding(
        padding: const EdgeInsets.only(top: KumoSpace.s2, bottom: KumoSpace.s1),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: kumo.colors.interact,
              borderRadius: BorderRadius.circular(KumoRadius.full),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a sheet attached to a screen edge and returns the value it closes
/// with. Bottom sheets follow the finger, snap to [snapPoints] by release
/// velocity and dismiss with a flick toward the edge; Escape, a scrim tap and
/// the back gesture close it along the same path it came in on.
///
/// Kumo components use this on narrow screens in place of anchored menus.
///
/// ```dart
/// final region = await showKumoSheet<String>(
///   context: context,
///   semanticLabel: 'Choose a region',
///   builder: (context) => RegionList(onPick: (r) => KumoSheetScope.closeFrom(context, r)),
/// );
/// ```
Future<T?> showKumoSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  KumoSheetEdge edge = KumoSheetEdge.bottom,
  List<double>? snapPoints,
  int? initialSnapPointIndex,
  bool dismissible = true,
  bool showHandle = true,
  double maxExtentFraction = 0.85,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    KumoSheetRoute<T>(
      semanticLabel: semanticLabel,
      builder: (context) => KumoSheet(
        edge: edge,
        snapPoints: snapPoints,
        initialSnapPointIndex: initialSnapPointIndex,
        preventDismissGestures: !dismissible,
        maxExtentFraction: maxExtentFraction,
        accessibilityLabel: semanticLabel,
        child: Builder(
          builder: (context) {
            final content = SafeArea(
              top: edge == KumoSheetEdge.top,
              bottom: edge != KumoSheetEdge.top,
              child: builder(context),
            );
            if (!showHandle || edge != KumoSheetEdge.bottom) return content;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KumoSheetHandle(onAccessibilityPress: dismissible ? () => KumoSheetScope.closeFrom(context) : null),
                Flexible(child: content),
              ],
            );
          },
        ),
      ),
    ),
  );
}
