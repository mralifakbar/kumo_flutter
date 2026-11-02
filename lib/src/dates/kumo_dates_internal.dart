import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_popup_surface.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

// Not exported. Date math and the popover-or-sheet host shared by the
// widgets in `dates/`. Every date here is a local calendar day at midnight.

DateTime kumoDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime kumoFirstOfMonth(DateTime d) => DateTime(d.year, d.month);

/// [month] shifted by [delta] months, as the first of that month.
DateTime kumoAddMonths(DateTime month, int delta) => DateTime(month.year, month.month + delta);

int kumoDaysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

/// Whole months from [a] to [b], ignoring the day.
int kumoMonthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + b.month - a.month;

bool kumoSameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

bool kumoSameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// Calendar days from [a] to [b]. Counted on UTC dates so a daylight saving
/// change between them never makes a day 23 or 25 hours long.
int kumoDaysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

DateTime kumoAddDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// Same day of the month [delta] months away, clamped to that month's length.
DateTime kumoAddMonthsKeepDay(DateTime d, int delta) {
  final first = kumoAddMonths(d, delta);
  final day = d.day.clamp(1, kumoDaysInMonth(first));
  return DateTime(first.year, first.month, day);
}

/// Column (0-6) of [d] in a week that starts on [firstDayOfWeek].
int kumoWeekColumn(DateTime d, int firstDayOfWeek) => (d.weekday - firstDayOfWeek + 7) % 7;

String kumoTwoDigits(int n) => n.toString().padLeft(2, '0');

/// Shows a panel next to [child]: an anchored popover on wide screens, a
/// bottom sheet on narrow ones (see [KumoPresentation]). The host owns no
/// value; it rebuilds an open sheet whenever it is rebuilt, so controlled
/// values flow into the sheet as they do into the popover.
class KumoDatesPanelHost extends StatefulWidget {
  const KumoDatesPanelHost({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.presentation,
    required this.panelBuilder,
    required this.child,
    this.sheetLabel,
    this.popoverPadding = const EdgeInsets.all(KumoSpace.s3),
  });

  final bool open;
  final ValueChanged<bool> onOpenChange;
  final KumoPresentation presentation;

  /// Builds the panel content. `inSheet` is true inside the bottom sheet.
  final Widget Function(BuildContext context, bool inSheet) panelBuilder;
  final Widget child;
  final String? sheetLabel;
  final EdgeInsetsGeometry popoverPadding;

  @override
  State<KumoDatesPanelHost> createState() => _KumoDatesPanelHostState();
}

class _KumoDatesPanelHostState extends State<KumoDatesPanelHost> {
  final ValueNotifier<int> _revision = ValueNotifier(0);
  BuildContext? _sheetContext;
  bool _sheetShowing = false;
  bool _usesSheet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _usesSheet = widget.presentation.usesSheet(context);
  }

  @override
  void initState() {
    super.initState();
    if (widget.open) SchedulerBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(KumoDatesPanelHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _usesSheet = widget.presentation.usesSheet(context);
    // The sheet lives in its own route; bump the revision so it rebuilds
    // with this build's values.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revision.value++;
      if (widget.open != oldWidget.open) _sync();
    });
  }

  @override
  void dispose() {
    _revision.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    if (widget.open && _usesSheet && !_sheetShowing) {
      _openSheet();
    } else if (!widget.open && _sheetShowing) {
      final sheetContext = _sheetContext;
      if (sheetContext != null && sheetContext.mounted) KumoSheetScope.closeFrom(sheetContext);
    }
  }

  Future<void> _openSheet() async {
    _sheetShowing = true;
    await showKumoSheet<void>(
      context: context,
      semanticLabel: widget.sheetLabel,
      builder: (sheetContext) => ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (context, _, _) {
          _sheetContext = context;
          if (!mounted) return const SizedBox.shrink();
          return widget.panelBuilder(context, true);
        },
      ),
    );
    _sheetShowing = false;
    _sheetContext = null;
    if (mounted && widget.open) widget.onOpenChange(false);
  }

  @override
  Widget build(BuildContext context) {
    return KumoAnchoredOverlay(
      open: widget.open && !_usesSheet,
      onDismiss: () => widget.onOpenChange(false),
      align: KumoAlign.start,
      preferredExtent: 360,
      trapFocus: true,
      overlayBuilder: (context, placement) => KumoPopupSurface(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Padding(padding: widget.popoverPadding, child: widget.panelBuilder(context, false)),
        ),
      ),
      child: widget.child,
    );
  }
}

/// The field that opens a date or time panel: the value (or placeholder) in
/// a [KumoFieldBox] with a leading icon and an optional clear button.
/// Shared by the pickers in `dates/`.
class KumoDatesTrigger extends StatelessWidget {
  const KumoDatesTrigger({
    super.key,
    required this.size,
    required this.icon,
    required this.text,
    required this.placeholder,
    required this.open,
    required this.error,
    required this.disabled,
    required this.semanticLabel,
    required this.onPress,
    required this.onClear,
  });

  final KumoFieldSize size;
  final IconData icon;
  final String? text;
  final String placeholder;
  final bool open;
  final bool error;
  final bool disabled;
  final String semanticLabel;
  final VoidCallback onPress;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final iconSize = size.textSize == KumoTextSize.xs ? 14.0 : 16.0;
    final clearSlot = SizedBox(width: iconSize + KumoSpace.s1, height: iconSize);
    final field = KumoPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      showFocusRing: false,
      scaleOnPress: false,
      expanded: open,
      semanticLabel: semanticLabel,
      semanticValue: text,
      excludeChildSemantics: true,
      builder: (context, state) => KumoFieldBox(
        size: size,
        // The ring answers the press on pointer-down, before the panel opens.
        focused: state.focused || state.pressed || open,
        hovered: state.hovered,
        error: error,
        disabled: disabled,
        leading: KumoIcon(icon, size: iconSize, color: KumoColor.textSubtle),
        trailing: onClear != null ? clearSlot : null,
        child: Text(
          text ?? placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: kumo.text(
            size: size.textSize,
            color: text == null ? KumoColor.textPlaceholder : KumoColor.textDefault,
          ),
        ),
      ),
    );
    if (onClear == null) return field;
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        field,
        PositionedDirectional(
          end: size.paddingX - KumoSpace.s1,
          top: 0,
          bottom: 0,
          child: Center(
            child: KumoPressable(
              onPress: onClear,
              semanticLabel: strings.clear,
              excludeChildSemantics: true,
              minTapTargetSize: 0,
              borderRadius: BorderRadius.circular(KumoRadius.sm),
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(KumoSpace.s1),
                child: KumoIcon(
                  KumoIcons.x,
                  size: iconSize - 2,
                  color: state.active ? KumoColor.textDefault : KumoColor.textSubtle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
