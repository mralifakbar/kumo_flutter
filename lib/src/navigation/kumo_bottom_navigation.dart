import 'dart:math' as math;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_haptics.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// One destination of a [KumoBottomNavigation].
///
/// ```dart
/// const KumoBottomNavigationItem(
///   value: 'workers',
///   label: 'Workers',
///   icon: KumoIcons.code,
///   activeIcon: KumoIcons.codeFill,
/// )
/// ```
@immutable
class KumoBottomNavigationItem {
  const KumoBottomNavigationItem({
    required this.value,
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badgeCount,
    this.semanticLabel,
  });

  /// Identifies the destination in [KumoBottomNavigation.value].
  final String value;

  /// Short label, one word where possible.
  final String label;

  /// Regular-weight icon shown while inactive.
  final IconData icon;

  /// Icon shown while active, usually the `...Fill` variant of [icon].
  final IconData? activeIcon;

  /// Unread count shown on the icon; 0 or null hides it. Over 99 shows "99+".
  final int? badgeCount;
  final String? semanticLabel;
}

/// A tab bar for phone layouts of Kumo apps: three to five destinations,
/// each an icon over a label.
///
/// Kumo itself is a dashboard system and has no bottom bar; this follows
/// Kumo's tokens (base surface, hairline top border, subtle inactive text)
/// for apps that bring Kumo to phones. The active destination switches to its
/// fill icon, medium label and a tinted pill, so it never relies on color.
/// Every destination is at least 48px tall and fills its share of the width.
///
/// The bar pads itself for the home indicator. Pass [body] to have it lay
/// out the screen: the body gets the space above the bar, so content is
/// never hidden under it, and its bottom safe-area padding is removed.
///
/// ```dart
/// KumoBottomNavigation(
///   value: section,
///   onValueChange: (v) => setState(() => section = v),
///   items: const [
///     KumoBottomNavigationItem(value: 'home', label: 'Home', icon: KumoIcons.house, activeIcon: KumoIcons.houseFill),
///     KumoBottomNavigationItem(value: 'workers', label: 'Workers', icon: KumoIcons.code, activeIcon: KumoIcons.codeFill),
///     KumoBottomNavigationItem(value: 'alerts', label: 'Alerts', icon: KumoIcons.bell, activeIcon: KumoIcons.bellFill),
///   ],
///   body: const WorkersScreen(),
/// )
/// ```
class KumoBottomNavigation extends StatefulWidget {
  const KumoBottomNavigation({
    super.key,
    required this.items,
    required this.value,
    required this.onValueChange,
    this.body,
    this.safeArea = true,
    this.semanticLabel,
  }) : assert(items.length >= 2 && items.length <= 5, 'Use 3 to 5 destinations (2 at the least)');

  final List<KumoBottomNavigationItem> items;

  /// The active destination's [KumoBottomNavigationItem.value].
  final String value;

  /// Called with the pressed destination's value. Pressing the active one
  /// calls it too, so apps can scroll that screen to the top.
  final ValueChanged<String>? onValueChange;

  /// Screen content shown above the bar.
  final Widget? body;

  /// Pad the bar for the bottom system inset (home indicator, gesture bar).
  final bool safeArea;
  final String? semanticLabel;

  @override
  State<KumoBottomNavigation> createState() => _KumoBottomNavigationState();
}

class _KumoBottomNavigationState extends State<KumoBottomNavigation> with SingleTickerProviderStateMixin {
  /// Where the active pill is, in destinations (0 is the first). It springs
  /// from wherever it is to the new destination, so quick taps turn it
  /// around mid-flight without a jump.
  late final AnimationController _pill;

  List<KumoBottomNavigationItem> get items => widget.items;
  String get value => widget.value;
  ValueChanged<String>? get onValueChange => widget.onValueChange;
  Widget? get body => widget.body;
  bool get safeArea => widget.safeArea;
  String? get semanticLabel => widget.semanticLabel;

  int get _active => items.indexWhere((i) => i.value == value);

  @override
  void initState() {
    super.initState();
    _pill = AnimationController.unbounded(vsync: this, value: math.max(0, _active).toDouble());
  }

  @override
  void didUpdateWidget(KumoBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _active;
    if (target < 0 || target == oldWidget.items.indexWhere((i) => i.value == oldWidget.value)) return;
    if (KumoMotion.reduceMotion(context) || oldWidget.items.length != items.length) {
      _pill.value = target.toDouble();
    } else {
      KumoMotion.springTo(_pill, target.toDouble(), velocity: _pill.velocity);
    }
  }

  @override
  void dispose() {
    _pill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = _bar(context);
    if (body == null) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: MediaQuery.removePadding(context: context, removeBottom: true, child: body!),
        ),
        bar,
      ],
    );
  }

  Widget _bar(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final bottomInset = safeArea ? MediaQuery.viewPaddingOf(context).bottom : 0.0;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: DecoratedBox(
        // Sticky surfaces are separated from content with a border.
        decoration: BoxDecoration(
          color: c.base,
          border: Border(top: BorderSide(color: c.hairline)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: 1, bottom: bottomInset),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            role: SemanticsRole.tabBar,
            // Equal-height destinations; the bar's height comes from its content.
            child: LayoutBuilder(
              builder: (context, constraints) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _Destination(
                          item: items[i],
                          index: i,
                          width: constraints.maxWidth / items.length,
                          pill: _active < 0 ? null : _pill,
                          active: items[i].value == value,
                          onPress: onValueChange == null ? null : () => onValueChange!(items[i].value),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.item,
    required this.index,
    required this.width,
    required this.pill,
    required this.active,
    required this.onPress,
  });

  final KumoBottomNavigationItem item;
  final int index;

  /// Width of each destination, which is how far the pill travels per step.
  final double width;

  /// Position of the active pill, in destinations. Null hides it.
  final Animation<double>? pill;
  final bool active;
  final VoidCallback? onPress;

  static const double _pillWidth = 52;
  static const double _pillHeight = 28;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final count = item.badgeCount ?? 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return KumoPressable(
      onPress: onPress,
      isButton: false,
      selected: active,
      haptic: active ? KumoHaptic.none : KumoHaptic.selection,
      semanticLabel: item.semanticLabel,
      semanticValue: count > 0 ? '$count' : null,
      showFocusRing: false,
      minTapTargetSize: 0,
      builder: (context, state) {
        final fg = active || state.active ? KumoColor.textDefault : KumoColor.textSubtle;
        // The fill icon cross-fades in as the destination becomes active.
        Widget icon = AnimatedSwitcher(
          duration: KumoMotion.duration(context, KumoDurations.quick),
          child: KumoIcon(
            active ? (item.activeIcon ?? item.icon) : item.icon,
            key: ValueKey(active),
            size: 22,
            color: fg,
          ),
        );
        if (count > 0) {
          icon = Stack(
            clipBehavior: Clip.none,
            children: [
              icon,
              PositionedDirectional(
                top: -4,
                start: 14,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.danger,
                    borderRadius: BorderRadius.circular(KumoRadius.full),
                    border: KumoRing.border(c.base, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    semanticsLabel: '',
                    textScaler: TextScaler.noScaling,
                    style: kumo
                        .text(size: KumoTextSize.xs, weight: KumoTypography.medium, height: 1)
                        .copyWith(color: const Color(0xFFFFFFFF), fontSize: 10),
                  ),
                ),
              ),
            ],
          );
        }
        final radius = BorderRadius.circular(KumoRadius.full);
        final pillLayer = <Widget>[
          // Press feedback on an inactive destination: an instant tint.
          if (state.pressed && !active)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.tint.withValues(alpha: c.tint.a * 0.6),
                  borderRadius: radius,
                ),
              ),
            ),
          // The active pill slides between destinations. Each destination
          // paints the part of it that crosses its own area, under its
          // own icon, so the pill never covers a neighbour's icon.
          if (pill != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: pill!,
                builder: (context, _) {
                  final offset = pill!.value - index;
                  if (offset.abs() >= 1) return const SizedBox.shrink();
                  return Transform.translate(
                    offset: Offset(offset * width * (rtl ? -1 : 1), 0),
                    child: DecoratedBox(
                      key: index == pill!.value.round() ? const ValueKey('kumo-bottom-navigation-pill') : null,
                      decoration: BoxDecoration(color: c.tint, borderRadius: radius),
                    ),
                  );
                },
              ),
            ),
        ];
        final slot = SizedBox(
          width: _pillWidth,
          height: _pillHeight,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [...pillLayer, icon]),
        );
        return ClipRect(
          child: Semantics(
            role: SemanticsRole.tab,
            child: Container(
              constraints: BoxConstraints(minHeight: math.max(56, kumo.minTapTarget)),
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1, vertical: KumoSpace.s1_5),
              child: KumoFocusRing(
                visible: state.focused,
                borderRadius: BorderRadius.circular(KumoRadius.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: KumoSpace.s0_5,
                  children: [
                    slot,
                    Text(
                      item.label,
                      semanticsLabel: item.semanticLabel == null ? null : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: kumo.text(
                        size: KumoTextSize.xs,
                        weight: active ? KumoTypography.medium : KumoTypography.normal,
                        color: fg,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
