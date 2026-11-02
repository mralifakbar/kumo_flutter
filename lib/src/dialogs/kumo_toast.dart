import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_theme_data.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Toast styles from Kumo's `toast.tsx`.
enum KumoToastVariant {
  /// Kumo's `default`: no icon, base surface, 1px ring.
  neutral,

  /// Confirmations: check icon and green title.
  success,

  /// Failures that need attention: octagon icon and red title.
  error,

  /// Cautionary messages: warning icon and amber title.
  warning,

  /// Neutral information: info icon and blue title.
  info,
}

/// A button inside a toast.
///
/// ```dart
/// KumoToastAction(label: 'Undo', onPress: restoreRecord, closesToast: true)
/// ```
@immutable
class KumoToastAction {
  const KumoToastAction({
    required this.label,
    required this.onPress,
    this.variant = KumoButtonVariant.secondary,
    this.icon,
    this.closesToast = false,
  });

  final String label;
  final VoidCallback onPress;
  final KumoButtonVariant variant;
  final IconData? icon;

  /// Close the toast after [onPress] runs. Kumo leaves toasts open; set this
  /// for one-shot actions such as Undo.
  final bool closesToast;
}

/// The content of one toast, as stored by [KumoToastManager] and passed to
/// [KumoToastManager.update] callbacks.
@immutable
class KumoToastData {
  const KumoToastData({
    this.title,
    this.description,
    this.variant = KumoToastVariant.neutral,
    this.content,
    this.actions = const [],
    this.timeout,
    this.onClose,
    this.semanticLabel,
  });

  /// Medium-weight heading, colored by [variant].
  final String? title;

  /// Secondary text under the title.
  final String? description;
  final KumoToastVariant variant;

  /// Custom content in place of the icon, title, description and actions.
  /// The close button stays.
  final Widget? content;
  final List<KumoToastAction> actions;

  /// Time before the toast closes on its own. Null uses the
  /// [KumoToaster.timeout]; [Duration.zero] keeps it open until closed.
  final Duration? timeout;

  /// Called once when the toast starts to close, for any reason.
  final VoidCallback? onClose;

  /// What screen readers announce. Defaults to the title and description.
  final String? semanticLabel;

  KumoToastData copyWith({
    String? title,
    String? description,
    KumoToastVariant? variant,
    Widget? content,
    List<KumoToastAction>? actions,
    Duration? timeout,
    VoidCallback? onClose,
    String? semanticLabel,
  }) => KumoToastData(
    title: title ?? this.title,
    description: description ?? this.description,
    variant: variant ?? this.variant,
    content: content ?? this.content,
    actions: actions ?? this.actions,
    timeout: timeout ?? this.timeout,
    onClose: onClose ?? this.onClose,
    semanticLabel: semanticLabel ?? this.semanticLabel,
  );

  String get _announcement => semanticLabel ?? [?title, ?description].join('. ');
}

class _ToastRecord {
  _ToastRecord(this.id, this.data);

  final String id;
  KumoToastData data;
  bool exiting = false;
  bool swiped = false;
  int bumps = 0;
  Duration remaining = Duration.zero;
  DateTime? startedAt;
  Timer? timer;
}

/// Adds, updates and closes the toasts of a [KumoToaster]. Get the one for
/// the current screen with [KumoToast.of], or create one up front and pass
/// it to [KumoToaster.manager] to raise toasts from code outside the widget
/// tree (timers, repositories).
///
/// ```dart
/// final toasts = KumoToast.of(context);
/// final id = toasts.add(title: 'Deploying image-resizer', variant: KumoToastVariant.info);
/// toasts.update(id, (toast) => toast.copyWith(title: 'image-resizer deployed', variant: KumoToastVariant.success));
/// ```
class KumoToastManager extends ChangeNotifier {
  KumoToastManager({this.defaultTimeout = KumoToaster.defaultTimeout});

  /// Used for toasts that do not set their own timeout.
  Duration defaultTimeout;

  final List<_ToastRecord> _records = [];
  int _nextId = 0;
  bool _paused = false;

  /// Ids of the toasts on screen, oldest first, including ones animating out.
  List<String> get ids => [for (final r in _records) r.id];

  /// The current content of toast [id], or null once it is gone.
  KumoToastData? toastFor(String id) => _find(id)?.data;

  _ToastRecord? _find(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Shows a toast and returns its id.
  ///
  /// Adding a toast with the [id] of one that is still on screen does not
  /// stack a copy: the existing toast restarts its timer and "bumps" (a
  /// quick 1.02 scale) so the repeat is noticed. Pass `bump: false` to skip
  /// the bump.
  String add({
    String? id,
    String? title,
    String? description,
    KumoToastVariant variant = KumoToastVariant.neutral,
    Widget? content,
    List<KumoToastAction> actions = const [],
    Duration? timeout,
    bool? bump,
    VoidCallback? onClose,
    String? semanticLabel,
  }) {
    return addToast(
      KumoToastData(
        title: title,
        description: description,
        variant: variant,
        content: content,
        actions: actions,
        timeout: timeout,
        onClose: onClose,
        semanticLabel: semanticLabel,
      ),
      id: id,
      bump: bump,
    );
  }

  /// [add] for a prepared [KumoToastData].
  String addToast(KumoToastData data, {String? id, bool? bump}) {
    final existing = id == null ? null : _find(id);
    if (existing != null) {
      // An exiting toast finishes leaving; the repeat is dropped.
      if (!existing.exiting) {
        if (bump != false) existing.bumps++;
        if (data.timeout != null) existing.data = existing.data.copyWith(timeout: data.timeout);
        _restart(existing);
        notifyListeners();
      }
      return existing.id;
    }
    final record = _ToastRecord(id ?? 'kumo-toast-${_nextId++}', data);
    _records.add(record);
    _restart(record);
    notifyListeners();
    return record.id;
  }

  /// Replaces the content of toast [id] with what [update] returns. A changed
  /// timeout restarts the timer. Pass `bump: true` to bump the toast too.
  void update(String id, KumoToastData Function(KumoToastData toast) update, {bool bump = false}) {
    final record = _find(id);
    if (record == null || record.exiting) return;
    final before = _timeoutOf(record.data);
    record.data = update(record.data);
    if (bump) record.bumps++;
    if (_timeoutOf(record.data) != before) _restart(record);
    notifyListeners();
  }

  /// Shows [loading] until [future] completes, then turns the same toast
  /// into [success] or [error]. The loading toast stays open until then.
  ///
  /// ```dart
  /// await KumoToast.of(context).promise(
  ///   deployWorker(),
  ///   loading: const KumoToastData(title: 'Deploying image-resizer'),
  ///   success: (_) => const KumoToastData(title: 'image-resizer deployed', variant: KumoToastVariant.success),
  ///   error: (e) => KumoToastData(title: 'Deployment failed', description: '$e', variant: KumoToastVariant.error),
  /// );
  /// ```
  Future<T> promise<T>(
    Future<T> future, {
    required KumoToastData loading,
    required KumoToastData Function(T value) success,
    required KumoToastData Function(Object error) error,
  }) async {
    final id = addToast(loading.timeout == null ? loading.copyWith(timeout: Duration.zero) : loading);
    try {
      final value = await future;
      update(id, (_) => success(value));
      return value;
    } catch (e) {
      update(id, (_) => error(e));
      rethrow;
    }
  }

  /// Starts closing toast [id]. It animates out the way it came in.
  void close(String id) {
    final record = _find(id);
    if (record == null || record.exiting) return;
    _beginExit(record);
    notifyListeners();
  }

  /// Closes every toast.
  void closeAll() {
    var changed = false;
    for (final r in _records) {
      if (!r.exiting) {
        _beginExit(r);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _beginExit(_ToastRecord record) {
    record.exiting = true;
    record.timer?.cancel();
    record.timer = null;
    record.data.onClose?.call();
  }

  void _swipeClose(String id) {
    final record = _find(id);
    if (record == null || record.exiting) return;
    record.swiped = true;
    _beginExit(record);
    notifyListeners();
  }

  void _remove(String id) {
    final record = _find(id);
    if (record == null) return;
    record.timer?.cancel();
    _records.remove(record);
    notifyListeners();
  }

  Duration _timeoutOf(KumoToastData data) => data.timeout ?? defaultTimeout;

  void _restart(_ToastRecord record) {
    record.timer?.cancel();
    record.timer = null;
    record.startedAt = null;
    record.remaining = _timeoutOf(record.data);
    if (!_paused) _start(record);
  }

  void _start(_ToastRecord record) {
    if (record.exiting || record.remaining <= Duration.zero || record.timer != null) return;
    record.startedAt = clock.now();
    record.timer = Timer(record.remaining, () {
      record.timer = null;
      close(record.id);
    });
  }

  /// Hovering, focusing or touching the stack, or leaving the app, pauses
  /// every timer; the remaining time carries over.
  void _setPaused(bool paused) {
    if (paused == _paused) return;
    _paused = paused;
    for (final r in _records) {
      if (paused) {
        final timer = r.timer;
        if (timer == null) continue;
        timer.cancel();
        r.timer = null;
        final started = r.startedAt;
        if (started != null) r.remaining -= clock.now().difference(started);
        r.startedAt = null;
      } else {
        _start(r);
      }
    }
  }

  @override
  void dispose() {
    for (final r in _records) {
      r.timer?.cancel();
    }
    super.dispose();
  }
}

class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.manager, required super.child});

  final KumoToastManager manager;

  @override
  bool updateShouldNotify(_ToastScope oldWidget) => manager != oldWidget.manager;
}

/// Shows a toast through the nearest [KumoToaster] and returns its id.
/// Shorthand for `KumoToast.of(context).add(...)`.
///
/// ```dart
/// showKumoToast(context, title: 'Cache purged', description: 'example.com serves fresh content.');
/// showKumoToast(
///   context,
///   title: 'DNS record deleted',
///   variant: KumoToastVariant.success,
///   actions: [KumoToastAction(label: 'Undo', onPress: restoreRecord, closesToast: true)],
/// );
/// ```
String showKumoToast(
  BuildContext context, {
  String? id,
  String? title,
  String? description,
  KumoToastVariant variant = KumoToastVariant.neutral,
  Widget? content,
  List<KumoToastAction> actions = const [],
  Duration? timeout,
  bool? bump,
  VoidCallback? onClose,
  String? semanticLabel,
}) {
  return KumoToast.of(context).add(
    id: id,
    title: title,
    description: description,
    variant: variant,
    content: content,
    actions: actions,
    timeout: timeout,
    bump: bump,
    onClose: onClose,
    semanticLabel: semanticLabel,
  );
}

/// Hosts toasts for everything below it (Kumo's `Toasty`). Place one near
/// the root, above the navigator, so toasts stay visible across routes and
/// over dialogs:
///
/// ```dart
/// KumoThemeProvider(
///   child: MaterialApp(
///     builder: (context, child) => KumoToaster(child: child!),
///     home: const DashboardPage(),
///   ),
/// )
/// ```
///
/// Toasts stack in the bottom end corner (340px wide, 32px from the edges)
/// from 640px up, and across the bottom with 16px gutters on phones, always
/// above the safe area and the keyboard. The newest is in front; up to
/// [limit] older ones peek above it, scaled down. Hovering or focusing the
/// stack, or touching it on a phone, fans the toasts out and pauses their
/// timers.
///
/// Each toast enters from the bottom edge and leaves the way it came. Swipe
/// one down or toward the end edge to dismiss it: it follows the finger and
/// a flick carries on at the finger's speed; a short drag springs back. New
/// toasts are announced to screen readers.
class KumoToaster extends StatefulWidget {
  const KumoToaster({super.key, required this.child, this.manager, this.limit = 3, this.timeout = defaultTimeout});

  /// Kumo's default auto-dismiss time.
  static const Duration defaultTimeout = Duration(milliseconds: 5000);

  final Widget child;

  /// A manager created outside the tree. Null creates one.
  final KumoToastManager? manager;

  /// Toasts shown at once. Older ones wait, hidden, until a slot frees up.
  final int limit;

  /// Auto-dismiss time for toasts that do not set their own.
  final Duration timeout;

  @override
  State<KumoToaster> createState() => _KumoToasterState();
}

/// Vertical peek of each toast behind the front one (`--peek`).
const double _peek = KumoSpace.s3;

/// Gap between fanned-out toasts (`--gap`).
const double _gap = KumoSpace.s3;

class _Layout {
  const _Layout({required this.index, required this.y, required this.scale, required this.height});

  final int index;
  final double y;
  final double scale;
  final double? height;
}

class _KumoToasterState extends State<KumoToaster> with WidgetsBindingObserver {
  KumoToastManager? _own;
  final Map<String, double> _heights = {};
  final Map<String, _Layout> _lastLayout = {};
  final Set<String> _announced = {};
  bool _hovered = false;
  bool _focused = false;
  bool _touchExpanded = false;
  bool _pointerDown = false;
  bool _inBackground = false;

  KumoToastManager get _manager => widget.manager ?? _own!;

  bool get _expanded => _hovered || _focused || _touchExpanded;

  @override
  void initState() {
    super.initState();
    if (widget.manager == null) _own = KumoToastManager(defaultTimeout: widget.timeout);
    _manager.defaultTimeout = widget.timeout;
    _manager.addListener(_onToasts);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(KumoToaster oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldManager = oldWidget.manager ?? _own!;
    if (widget.manager != oldWidget.manager) {
      oldManager.removeListener(_onToasts);
      if (widget.manager == null) _own ??= KumoToastManager(defaultTimeout: widget.timeout);
      _manager.addListener(_onToasts);
    }
    _manager.defaultTimeout = widget.timeout;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manager.removeListener(_onToasts);
    _own?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inBackground = state != AppLifecycleState.resumed;
    _syncPause();
  }

  void _syncPause() => _manager._setPaused(_expanded || _pointerDown || _inBackground);

  void _onToasts() {
    if (!mounted) return;
    void apply() {
      if (!mounted) return;
      setState(() {
        final live = _manager._records.map((r) => r.id).toSet();
        _heights.removeWhere((id, _) => !live.contains(id));
        _lastLayout.removeWhere((id, _) => !live.contains(id));
        _announced.removeWhere((id) => !live.contains(id));
        if (_manager._records.where((r) => !r.exiting).length <= 1) _touchExpanded = false;
        if (_manager._records.isEmpty) _focused = false;
      });
      _announce();
      _syncPause();
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  void _announce() {
    for (final r in _manager._records) {
      if (r.exiting || !_announced.add(r.id)) continue;
      final message = r.data._announcement;
      // Android and the web read the toast's live region; elsewhere the
      // announcement has to be sent explicitly.
      if (message.isEmpty || kIsWeb || defaultTargetPlatform == TargetPlatform.android) continue;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.maybeOf(context) ?? TextDirection.ltr,
      );
    }
  }

  void _setHeight(String id, double height) {
    if (!mounted || _heights[id] == height) return;
    setState(() => _heights[id] = height);
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    return _ToastScope(
      manager: _manager,
      child: Directionality(
        textDirection: direction,
        child: Stack(
          // The child sizes the toaster, so it also works below the root.
          fit: StackFit.passthrough,
          children: [widget.child, _viewport(context)],
        ),
      ),
    );
  }

  Widget _viewport(BuildContext context) {
    final media = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final wide = media.size.width >= KumoBreakpoints.sm;
    final gutter = wide ? KumoSpace.s8 : KumoSpace.s4;
    final width = wide ? 340.0 : math.max(0.0, media.size.width - 2 * KumoSpace.s4);
    final bottom = math.max(media.viewInsets.bottom, media.viewPadding.bottom) + gutter;

    final records = _manager._records.reversed.toList();
    final active = [
      for (final r in records)
        if (!r.exiting) r,
    ];
    final visible = active.take(widget.limit).toList();
    final expanded = _expanded;
    final frontHeight = visible.isEmpty ? 0.0 : (_heights[visible.first.id] ?? 0);

    final layouts = <String, _Layout>{};
    var offset = 0.0;
    for (var i = 0; i < active.length; i++) {
      final r = active[i];
      final index = math.min(i, widget.limit);
      final natural = _heights[r.id];
      if (expanded) {
        layouts[r.id] = _Layout(index: index, y: -offset, scale: 1, height: natural);
        if (i < widget.limit) offset += (natural ?? 0) + _gap;
      } else {
        final scale = math.max(0.0, 1 - index * 0.1);
        layouts[r.id] = _Layout(
          index: index,
          y: -(index * _peek) - (1 - scale) * frontHeight,
          scale: scale,
          height: index == 0 ? natural : frontHeight,
        );
      }
    }
    for (final r in records) {
      if (r.exiting) {
        layouts[r.id] = _lastLayout[r.id] ?? const _Layout(index: 0, y: 0, scale: 1, height: null);
      } else {
        _lastLayout[r.id] = layouts[r.id]!;
      }
    }

    final stackHeight = visible.isEmpty
        ? 0.0
        : expanded
        ? math.max(0.0, offset - _gap)
        : frontHeight + (visible.length - 1) * _peek;

    // Paint the front toast last so it sits on top.
    final ordered = [...records]..sort((a, b) => layouts[b.id]!.index.compareTo(layouts[a.id]!.index));
    final reduceMotion = KumoMotion.reduceMotion(context);

    return PositionedDirectional(
      end: gutter,
      bottom: bottom,
      width: width,
      height: stackHeight,
      child: MouseRegion(
        opaque: false,
        hitTestBehavior: HitTestBehavior.translucent,
        onEnter: (_) {
          setState(() => _hovered = true);
          _syncPause();
        },
        onExit: (_) {
          setState(() => _hovered = false);
          _syncPause();
        },
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (focused) {
            setState(() => _focused = focused);
            _syncPause();
          },
          child: TapRegion(
            onTapOutside: (_) {
              if (_touchExpanded) {
                setState(() => _touchExpanded = false);
                _syncPause();
              }
            },
            child: Listener(
              onPointerDown: (event) {
                _pointerDown = true;
                if (event.kind == PointerDeviceKind.touch && visible.length > 1 && !_touchExpanded) {
                  setState(() => _touchExpanded = true);
                }
                _syncPause();
              },
              onPointerUp: (_) {
                _pointerDown = false;
                _syncPause();
              },
              onPointerCancel: (_) {
                _pointerDown = false;
                _syncPause();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final r in ordered)
                    // Keyed here, on the Stack's direct child: paint order
                    // changes as toasts come and go, and an unkeyed slot would
                    // hand one toast's state to another (it re-entered from
                    // the bottom edge instead of sliding into its new place).
                    Positioned(
                      key: ValueKey(r.id),
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _ToastItem(
                        id: r.id,
                        data: r.data,
                        layout: layouts[r.id]!,
                        bumps: r.bumps,
                        behind: !expanded && layouts[r.id]!.index > 0,
                        limited: !r.exiting && layouts[r.id]!.index >= widget.limit,
                        exiting: r.exiting,
                        swiped: r.swiped,
                        reduceMotion: reduceMotion,
                        onHeight: (h) => _setHeight(r.id, h),
                        onClose: () => _manager.close(r.id),
                        onSwipeDismiss: () => _manager._swipeClose(r.id),
                        onExitComplete: () => _manager._remove(r.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A critically damped spring with a quick response: kicked with velocity
/// from rest it rises to about 1.02 and settles back, Kumo's toast bump.
final SpringDescription _bumpSpring = KumoSprings.of(dampingRatio: 1, response: 0.4);
const double _bumpVelocity = 0.85;

/// Distance past which a released swipe dismisses even when slow
/// (Base UI's swipe threshold).
const double _swipeThreshold = 40;

class _ToastItem extends StatefulWidget {
  const _ToastItem({
    required this.id,
    required this.data,
    required this.layout,
    required this.bumps,
    required this.behind,
    required this.limited,
    required this.exiting,
    required this.swiped,
    required this.reduceMotion,
    required this.onHeight,
    required this.onClose,
    required this.onSwipeDismiss,
    required this.onExitComplete,
  });

  final String id;
  final KumoToastData data;
  final _Layout layout;
  final int bumps;

  /// Collapsed behind the front toast: content hidden and not interactive.
  final bool behind;

  /// Over the limit: hidden until a slot frees up.
  final bool limited;
  final bool exiting;
  final bool swiped;
  final bool reduceMotion;
  final ValueChanged<double> onHeight;
  final VoidCallback onClose;
  final VoidCallback onSwipeDismiss;
  final VoidCallback onExitComplete;

  @override
  State<_ToastItem> createState() => _ToastItemState();
}

class _ToastItemState extends State<_ToastItem> with TickerProviderStateMixin {
  late final AnimationController _presence;
  late final AnimationController _y;
  late final AnimationController _scale;
  late final AnimationController _height;
  late final AnimationController _swipeX;
  late final AnimationController _swipeY;
  late final AnimationController _bump;

  double? _natural;
  bool _heightKnown = false;
  Axis? _axis;
  bool _swipeExiting = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    _presence = AnimationController.unbounded(vsync: this, value: 0);
    _y = AnimationController.unbounded(vsync: this, value: widget.layout.y);
    _scale = AnimationController.unbounded(vsync: this, value: widget.layout.scale);
    _height = AnimationController.unbounded(vsync: this, value: 0);
    _swipeX = AnimationController.unbounded(vsync: this, value: 0);
    _swipeY = AnimationController.unbounded(vsync: this, value: 0);
    _bump = AnimationController.unbounded(vsync: this, value: 1);
    SchedulerBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void dispose() {
    _presence.dispose();
    _y.dispose();
    _scale.dispose();
    _height.dispose();
    _swipeX.dispose();
    _swipeY.dispose();
    _bump.dispose();
    super.dispose();
  }

  void _enter() {
    if (!mounted || widget.exiting) return;
    if (widget.reduceMotion) {
      _presence.animateTo(1, duration: KumoDurations.fast);
    } else {
      KumoMotion.springTo(_presence, 1, spring: KumoSprings.standard);
    }
  }

  void _to(AnimationController c, double target, {double velocity = 0}) {
    if (c.value == target && !c.isAnimating) return;
    if (widget.reduceMotion) {
      c.value = target;
    } else {
      KumoMotion.springTo(c, target, spring: KumoSprings.standard, velocity: velocity);
    }
  }

  @override
  void didUpdateWidget(_ToastItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final layout = widget.layout;
    if (layout.y != oldWidget.layout.y) _to(_y, layout.y, velocity: _y.velocity);
    if (layout.scale != oldWidget.layout.scale) _to(_scale, layout.scale, velocity: _scale.velocity);
    if (layout.height != oldWidget.layout.height && _heightKnown) _to(_height, layout.height ?? _natural ?? 0);
    if (widget.bumps > oldWidget.bumps && !widget.reduceMotion) {
      KumoMotion.springTo(_bump, 1, spring: _bumpSpring, velocity: _bumpVelocity);
    }
    if (widget.exiting && !_exitStarted && !_swipeExiting) _exit();
  }

  void _exit() {
    _exitStarted = true;
    final done = widget.reduceMotion
        ? _presence.animateTo(0, duration: KumoDurations.fast)
        : KumoMotion.springTo(_presence, 0, spring: KumoSprings.standard);
    done.whenComplete(() {
      if (mounted) widget.onExitComplete();
    });
  }

  void _onChildHeight(double h) {
    if (!mounted) return;
    _natural = h;
    widget.onHeight(h);
    if (!_heightKnown) {
      _heightKnown = true;
      _height.value = widget.layout.height ?? h;
      setState(() {});
    } else if (widget.layout.height == null) {
      _to(_height, h);
    }
  }

  bool get _canSwipe => !widget.behind && !widget.limited && !widget.exiting && !_swipeExiting;

  double get _endSign => Directionality.of(context) == TextDirection.rtl ? -1 : 1;

  void _onPanStart(DragStartDetails d) {
    if (!_canSwipe) return;
    _axis = null;
    _swipeX.stop();
    _swipeY.stop();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_canSwipe) return;
    final delta = d.delta;
    if (delta == Offset.zero) return;
    _axis ??= delta.dx.abs() > delta.dy.abs() ? Axis.horizontal : Axis.vertical;
    final size = context.size ?? const Size(340, 64);
    if (_axis == Axis.vertical) {
      final raw = _swipeY.value + delta.dy;
      // Down follows the finger; up, away from the dismiss direction, resists.
      _swipeY.value = raw >= 0 ? raw : -KumoMotion.rubberband(-raw, size.height);
    } else {
      final raw = _swipeX.value + delta.dx;
      final toward = raw * _endSign;
      _swipeX.value = toward >= 0 ? raw : -_endSign * KumoMotion.rubberband(-toward, size.width);
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_axis == null || !_canSwipe) return;
    final v = d.velocity.pixelsPerSecond;
    final size = context.size ?? const Size(340, 64);
    if (_axis == Axis.vertical) {
      final offset = _swipeY.value;
      final projected = offset + KumoMotion.project(v.dy);
      final dismiss = (offset > _swipeThreshold && v.dy > -100) || (projected > size.height / 2 && v.dy > 0);
      if (dismiss) {
        _dismissBySwipe(_swipeY, size.height * 1.5 + KumoSpace.s8, v.dy);
      } else {
        _to(_swipeY, 0, velocity: v.dy);
      }
    } else {
      final sign = _endSign;
      final offset = _swipeX.value * sign;
      final velocity = v.dx * sign;
      final projected = offset + KumoMotion.project(velocity);
      final dismiss = (offset > _swipeThreshold && velocity > -100) || (projected > size.width / 2 && velocity > 0);
      if (dismiss) {
        _dismissBySwipe(_swipeX, sign * size.width * 1.5, v.dx);
      } else {
        _to(_swipeX, 0, velocity: v.dx);
      }
    }
    _axis = null;
  }

  void _dismissBySwipe(AnimationController axis, double target, double velocity) {
    _swipeExiting = true;
    widget.onSwipeDismiss();
    if (widget.reduceMotion) {
      _presence.animateTo(0, duration: KumoDurations.fast).whenComplete(() {
        if (mounted) widget.onExitComplete();
      });
      return;
    }
    // The toast keeps the finger's speed on its way out and fades as it goes.
    _presence.animateTo(0, duration: KumoDurations.slow, curve: KumoCurves.exit);
    KumoMotion.springTo(axis, target, spring: KumoSprings.momentum, velocity: velocity).whenComplete(() {
      if (mounted) widget.onExitComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final reduce = widget.reduceMotion;
    final style = _ToastStyle.of(kumo, widget.data.variant);
    final radius = BorderRadius.circular(KumoRadius.xl);
    final hideContent = widget.behind || widget.limited;

    Widget content = _ToastContent(
      key: ValueKey((widget.data.variant, widget.data.title, widget.data.description)),
      data: widget.data,
      onClose: widget.onClose,
      onCloseRequest: widget.onClose,
    );
    // An update in place (a promise settling, a retry count) cross-fades the
    // old message into the new one. Only the incoming content sizes the toast,
    // so its height springs once, straight to the new message.
    content = AnimatedSwitcher(
      duration: KumoMotion.duration(context, KumoDurations.quick),
      switchInCurve: KumoCurves.enter,
      switchOutCurve: KumoCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        clipBehavior: Clip.none,
        children: [
          for (final p in previous) PositionedDirectional(top: 0, start: 0, end: 0, child: p),
          ?current,
        ],
      ),
      child: content,
    );
    content = AnimatedOpacity(
      opacity: hideContent ? 0 : 1,
      duration: KumoMotion.duration(context, _contentFade),
      child: IgnorePointer(ignoring: hideContent, child: content),
    );

    Widget surface = DecoratedBox(
      decoration: style.decoration(radius),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedBuilder(
          animation: _height,
          builder: (context, child) => _ToastBox(
            height: _heightKnown ? math.max(0.0, _height.value) : null,
            onChildHeight: _onChildHeight,
            child: child,
          ),
          child: content,
        ),
      ),
    );

    surface = AnimatedBuilder(
      animation: _bump,
      child: surface,
      builder: (context, child) => Transform.scale(scale: _bump.value, child: child),
    );

    surface = GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: () {
        if (_axis != null && _canSwipe) {
          _to(_swipeX, 0);
          _to(_swipeY, 0);
        }
        _axis = null;
      },
      child: surface,
    );

    final animated = AnimatedBuilder(
      animation: Listenable.merge([_presence, _y, _scale, _swipeX, _swipeY]),
      child: surface,
      builder: (context, child) {
        final presence = _presence.value;
        final natural = _natural ?? 64;
        final fading = widget.exiting || reduce || _swipeExiting;
        final enterY = reduce || _swipeExiting ? 0.0 : (1 - presence) * natural * 1.5;
        final opacity = widget.limited ? 0.0 : (fading ? presence.clamp(0.0, 1.0) : 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(_swipeX.value, _swipeY.value + _y.value + enterY),
            child: Transform.scale(scale: math.max(0.0, _scale.value), alignment: Alignment.bottomCenter, child: child),
          ),
        );
      },
    );

    Widget result = Semantics(container: true, liveRegion: !widget.exiting, explicitChildNodes: true, child: animated);
    if (widget.limited || widget.exiting) result = ExcludeSemantics(child: IgnorePointer(child: result));
    return result;
  }
}

/// How long hidden toast content takes to fade when the stack collapses or
/// fans out (Kumo's 250ms).
const Duration _contentFade = Duration(milliseconds: 250);

/// Lays its child out at its natural height and takes [height] itself (or
/// the natural height while [height] is null), so a toast behind the front
/// one can shrink to the front toast's height without reflowing its text.
class _ToastBox extends SingleChildRenderObjectWidget {
  const _ToastBox({required this.height, required this.onChildHeight, super.child});

  final double? height;
  final ValueChanged<double> onChildHeight;

  @override
  _RenderToastBox createRenderObject(BuildContext context) => _RenderToastBox(height, onChildHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderToastBox renderObject) {
    renderObject
      ..height = height
      ..onChildHeight = onChildHeight;
  }
}

class _RenderToastBox extends RenderProxyBox {
  _RenderToastBox(this._height, this.onChildHeight);

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
      size = constraints.constrain(Size(constraints.maxWidth, _height ?? 0));
      return;
    }
    child.layout(constraints.copyWith(minHeight: 0, maxHeight: double.infinity), parentUsesSize: true);
    final natural = child.size.height;
    size = constraints.constrain(Size(child.size.width, _height ?? natural));
    if (natural != _reported) {
      _reported = natural;
      SchedulerBinding.instance.addPostFrameCallback((_) => onChildHeight(natural));
    }
  }
}

class _ToastStyle {
  const _ToastStyle({required this.background, required this.ring, required this.ringWidth, this.accent, this.icon});

  final Color background;
  final Color ring;
  final double ringWidth;
  final KumoColor? accent;
  final IconData? icon;

  static _ToastStyle of(KumoThemeData kumo, KumoToastVariant variant) {
    final c = kumo.colors;
    // The surface color, then Kumo's 90% base layer, then the variant tint.
    Color layered(Color surface, Color? tint) {
      final base = Color.alphaBlend(c.base.withValues(alpha: 0.9), surface);
      return tint == null ? base : Color.alphaBlend(tint, base);
    }

    return switch (variant) {
      KumoToastVariant.neutral => _ToastStyle(background: layered(c.base, null), ring: c.line, ringWidth: 1),
      KumoToastVariant.success => _ToastStyle(
        background: layered(c.base, c.successTint.withValues(alpha: 0.2)),
        ring: c.success,
        ringWidth: 0.3,
        accent: KumoColor.textSuccess,
        icon: KumoIcons.checkCircleFill,
      ),
      KumoToastVariant.error => _ToastStyle(
        background: layered(c.base, c.dangerTint.withValues(alpha: 0.5)),
        ring: c.danger,
        ringWidth: 0.3,
        accent: KumoColor.textDanger,
        icon: KumoIcons.warningOctagonFill,
      ),
      KumoToastVariant.warning => _ToastStyle(
        background: layered(c.base, c.warningTint.withValues(alpha: 0.5)),
        ring: c.warning,
        ringWidth: 0.3,
        accent: KumoColor.textWarning,
        icon: KumoIcons.warningFill,
      ),
      KumoToastVariant.info => _ToastStyle(
        background: layered(c.control, c.infoTint.withValues(alpha: 0.5)),
        ring: c.info,
        ringWidth: 0.3,
        accent: KumoColor.textInfo,
        icon: KumoIcons.infoFill,
      ),
    };
  }

  BoxDecoration decoration(BorderRadius radius) => BoxDecoration(
    color: background,
    borderRadius: radius,
    border: KumoRing.border(ring, width: ringWidth),
    boxShadow: KumoShadow.lg.boxShadows,
  );
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({super.key, required this.data, this.onClose, this.onCloseRequest});

  final KumoToastData data;

  /// Shows the close button when set.
  final VoidCallback? onClose;

  /// Called by actions with [KumoToastAction.closesToast].
  final VoidCallback? onCloseRequest;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final style = _ToastStyle.of(kumo, data.variant);
    final strings = context.kumoStrings;
    final accent = style.accent == null ? c.textDefault : kumo.color(style.accent!);
    // Kumo sets toast text in rem: 0.975rem titles, 0.925rem descriptions,
    // both on a 20px line.
    final titleStyle = kumo.typography
        .body(weight: KumoTypography.medium, color: accent)
        .copyWith(fontSize: 15.6, height: 20 / 15.6);
    final descriptionStyle = kumo.typography
        .body(color: c.textDefault.withValues(alpha: 0.7))
        .copyWith(fontSize: 14.8, height: 20 / 14.8);

    final body =
        data.content ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s2,
          children: [
            if (style.icon != null)
              Padding(
                padding: const EdgeInsets.only(top: KumoSpace.s0_5),
                child: KumoIcon(style.icon!, size: 16, color: style.accent),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s1,
                children: [
                  if (data.title != null) Text(data.title!, style: titleStyle),
                  if (data.description != null) Text(data.description!, style: descriptionStyle),
                  if (data.actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: KumoSpace.s1),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          spacing: KumoSpace.s2,
                          children: [
                            for (final a in data.actions)
                              KumoButton(
                                label: a.label,
                                icon: a.icon,
                                variant: a.variant,
                                onPress: () {
                                  a.onPress();
                                  if (a.closesToast) onCloseRequest?.call();
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

    // The close button's visual is 20px; on touch its hit area grows to
    // 44px, so shift it to keep the visual 8px from the corner.
    const closeSize = 20.0;
    final hitPad = math.max(0.0, (kumo.minTapTarget - closeSize) / 2);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            KumoSpace.s4,
            KumoSpace.s4,
            onClose == null ? KumoSpace.s4 : KumoSpace.s4 + KumoSpace.s3,
            KumoSpace.s4,
          ),
          child: DefaultTextStyle(style: kumo.text(), child: body),
        ),
        if (onClose != null)
          PositionedDirectional(
            top: KumoSpace.s2 - hitPad,
            end: KumoSpace.s2 - hitPad,
            child: KumoButton(
              iconWidget: KumoIcon(KumoIcons.x, size: 12, color: style.accent ?? KumoColor.textSubtle),
              shape: KumoButtonShape.square,
              size: KumoButtonSize.xs,
              variant: KumoButtonVariant.ghost,
              semanticLabel: strings.close,
              onPress: onClose,
            ),
          ),
      ],
    );
  }
}

/// One toast surface (Kumo's toast `surface` part), for previews and custom
/// hosts. In an app, raise toasts with [KumoToast.of] or [showKumoToast]
/// instead of placing this widget.
///
/// ```dart
/// const KumoToast(title: 'Worker deployed', description: 'image-resizer is live.', variant: KumoToastVariant.success)
/// ```
class KumoToast extends StatelessWidget {
  const KumoToast({
    super.key,
    this.title,
    this.description,
    this.variant = KumoToastVariant.neutral,
    this.content,
    this.actions = const [],
    this.onClose,
  });

  final String? title;
  final String? description;
  final KumoToastVariant variant;

  /// Custom content in place of the icon, title, description and actions.
  final Widget? content;
  final List<KumoToastAction> actions;

  /// Shows the close button and runs when it is pressed.
  final VoidCallback? onClose;

  /// The [KumoToastManager] of the nearest [KumoToaster].
  ///
  /// ```dart
  /// KumoToast.of(context).add(title: 'API token created', variant: KumoToastVariant.success);
  /// ```
  static KumoToastManager of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_ToastScope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('KumoToast.of() was called with a context that has no KumoToaster above it.'),
        ErrorHint(
          'Place one KumoToaster near the root of the app, for example '
          'MaterialApp(builder: (context, child) => KumoToaster(child: child!)).',
        ),
      ]);
    }
    return scope.manager;
  }

  /// [of], or null when there is no [KumoToaster].
  static KumoToastManager? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ToastScope>()?.manager;

  @override
  Widget build(BuildContext context) {
    final style = _ToastStyle.of(context.kumo, variant);
    final radius = BorderRadius.circular(KumoRadius.xl);
    final data = KumoToastData(
      title: title,
      description: description,
      variant: variant,
      content: content,
      actions: actions,
    );
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: style.decoration(radius),
        child: ClipRRect(
          borderRadius: radius,
          child: _ToastContent(data: data, onClose: onClose, onCloseRequest: onClose),
        ),
      ),
    );
  }
}
