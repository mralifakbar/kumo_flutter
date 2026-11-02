import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_menu_parts.dart';
import '../overlays/kumo_sheet.dart';
import '../pickers/kumo_select.dart';
import '../pickers/kumo_select_option.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_focus_ring.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Which buttons [KumoPagination] shows (Kumo's `controls`).
enum KumoPaginationControls {
  /// First, previous, page number, next and last.
  full,

  /// Previous and next only.
  simple,
}

/// How the page number is picked in [KumoPaginationControls.full].
enum KumoPaginationPageSelector {
  /// A 50px field where the page number is typed. Suits any page count.
  input,

  /// A menu listing every page. Only for small page counts.
  dropdown,
}

/// Builds the info text from the current numbers.
typedef KumoPaginationInfoBuilder = Widget? Function(BuildContext context, KumoPaginationInfo info);

/// The numbers handed to [KumoPagination.infoBuilder].
@immutable
class KumoPaginationInfo {
  const KumoPaginationInfo({
    required this.page,
    required this.maxPage,
    this.perPage,
    this.totalCount,
    required this.from,
    required this.to,
  });

  final int page;
  final int maxPage;
  final int? perPage;
  final int? totalCount;

  /// First item on the page, 1-based.
  final int from;

  /// Last item on the page.
  final int to;
}

/// Kumo's `Pagination`: "Showing 1-25 of 500" on the start side and joined
/// first, previous, page number, next and last buttons on the end side.
///
/// Controlled: [page] is 1-based and [onPageChange] receives the next page.
/// With [perPageOptions] and [onPerPageChange], a "Per page" select appears
/// (Kumo's `Pagination.PageSize`). When the total is unknown, pass
/// [hasNextPage] instead of [totalCount]; only previous and next show.
///
/// Below 768px (or with [compact]) the first and last buttons drop and the
/// page size moves under the controls, so everything fits at 390px.
///
/// ```dart
/// KumoPagination(
///   page: page,
///   onPageChange: (p) => setState(() => page = p),
///   perPage: 25,
///   totalCount: 500,
/// )
/// ```
///
/// The table or list it pages owns its empty, loading and error states; with
/// `totalCount: 0` pagination shows a single empty page with navigation off.
class KumoPagination extends StatefulWidget {
  const KumoPagination({
    super.key,
    required this.page,
    required this.onPageChange,
    this.perPage,
    this.totalCount,
    this.hasNextPage,
    this.controls = KumoPaginationControls.full,
    this.pageSelector = KumoPaginationPageSelector.input,
    this.perPageOptions,
    this.onPerPageChange,
    this.showInfo = true,
    this.infoBuilder,
    this.compact,
    this.presentation = KumoPresentation.auto,
    this.perPageLabel,
    this.pageNumberLabel,
    this.pageSizeLabel,
  });

  /// Current page, 1-based.
  final int page;
  final ValueChanged<int>? onPageChange;
  final int? perPage;

  /// Total items across all pages. Null when unknown.
  final int? totalCount;

  /// With an unknown total: whether another page exists. Ignored when
  /// [totalCount] is set.
  final bool? hasNextPage;
  final KumoPaginationControls controls;
  final KumoPaginationPageSelector pageSelector;

  /// Page sizes offered by the "Per page" select. Kumo's default list is
  /// `[25, 50, 100, 250]`.
  final List<int>? perPageOptions;

  /// Shows the "Per page" select when set together with [perPage].
  final ValueChanged<int>? onPerPageChange;

  /// Show "Showing 1-25 of 500".
  final bool showInfo;

  /// Replaces the info text. Return null to show nothing.
  final KumoPaginationInfoBuilder? infoBuilder;

  /// Forces the compact layout on or off. Null follows the window width.
  final bool? compact;

  /// Where the page-size and page menus open.
  final KumoPresentation presentation;

  /// Visible label before the page size select. Defaults to
  /// [KumoStrings.perPage].
  final String? perPageLabel;

  /// Accessible name of the page number field or menu. Defaults to
  /// [KumoStrings.pageNumber].
  final String? pageNumberLabel;

  /// Accessible name of the page size select. Defaults to
  /// [KumoStrings.pageSize].
  final String? pageSizeLabel;

  static const List<int> defaultPerPageOptions = [25, 50, 100, 250];

  @override
  State<KumoPagination> createState() => _KumoPaginationState();
}

class _KumoPaginationState extends State<KumoPagination> {
  late final TextEditingController _input;
  late final FocusNode _inputFocus;

  int get _maxPage => math.max(((widget.totalCount ?? 1) / (widget.perPage ?? 1)).ceil(), 1);
  bool get _knownTotal => widget.totalCount != null;
  bool get _unknownTotal => !_knownTotal && widget.hasNextPage != null;

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: '${widget.page}');
    _inputFocus = FocusNode(debugLabel: 'KumoPagination page')..addListener(_onInputFocus);
  }

  @override
  void didUpdateWidget(KumoPagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) _input.text = '${widget.page}';
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onInputFocus() {
    if (!_inputFocus.hasFocus) _commitInput();
    setState(() {});
  }

  void _commitInput() {
    final text = _input.text.trim();
    final parsed = RegExp(r'^\d+$').hasMatch(text) ? int.parse(text) : null;
    if (parsed == null) {
      _input.text = '${widget.page}';
      return;
    }
    final clamped = parsed.clamp(1, _maxPage);
    _input.text = '$clamped';
    _go(clamped);
  }

  void _go(int page) {
    if (page != widget.page) widget.onPageChange?.call(page);
  }

  KumoPaginationInfo get _info {
    final page = widget.page;
    final perPage = widget.perPage;
    final total = widget.totalCount ?? 0;
    final from = perPage == null ? 0 : page * perPage - perPage + 1;
    final to = perPage == null ? 0 : math.min(page * perPage, total);
    return KumoPaginationInfo(
      page: page,
      maxPage: _maxPage,
      perPage: perPage,
      totalCount: widget.totalCount,
      from: from,
      to: to,
    );
  }

  Widget? _infoWidget(BuildContext context) {
    if (!widget.showInfo) return null;
    final info = _info;
    Widget? content;
    if (widget.infoBuilder != null) {
      content = widget.infoBuilder!(context, info);
    } else if ((widget.totalCount ?? 0) > 0) {
      content = Text(
        context.kumoStrings.showingRange(info.from, info.to, widget.totalCount!),
        style: context.kumo
            .text(size: KumoTextSize.sm, color: KumoColor.textSubtle)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      );
    }
    if (content == null) return null;
    // The range cross-fades briefly when the page changes, so the numbers
    // read as updated rather than flashing. The outgoing text is hidden
    // from screen readers; the live region announces the new one.
    content = AnimatedSwitcher(
      duration: KumoMotion.duration(context, KumoDurations.quick),
      switchInCurve: KumoCurves.enter,
      switchOutCurve: KumoCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          for (final p in previous) ExcludeSemantics(key: p.key, child: p),
          if (current != null) ExcludeSemantics(key: current.key, excluding: false, child: current),
        ],
      ),
      child: KeyedSubtree(key: ValueKey((info.page, info.from, info.to, info.totalCount)), child: content),
    );
    return Semantics(liveRegion: true, container: true, child: content);
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact ?? context.kumoIsNarrow;
    final info = _infoWidget(context);
    final controls = _controls(context, compact: compact);
    final pageSize = _pageSize(context);

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s2,
        children: [
          Row(
            spacing: KumoSpace.s2,
            children: [
              Expanded(child: info ?? const SizedBox.shrink()),
              controls,
            ],
          ),
          if (pageSize != null) Align(alignment: AlignmentDirectional.centerEnd, child: pageSize),
        ],
      );
    }
    return Row(
      spacing: KumoSpace.s2,
      children: [
        ?info,
        if (pageSize != null) ...[
          if (info != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
              child: SizedBox(width: 1, height: 24, child: ColoredBox(color: context.kumo.colors.hairline)),
            ),
          pageSize,
        ],
        Expanded(
          child: Align(alignment: AlignmentDirectional.centerEnd, child: controls),
        ),
      ],
    );
  }

  Widget? _pageSize(BuildContext context) {
    final perPage = widget.perPage;
    if (widget.onPerPageChange == null || perPage == null) return null;
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final options = widget.perPageOptions ?? KumoPagination.defaultPerPageOptions;
    // Kumo's Select trigger is as wide as its value; size it for the widest
    // option so picking one never changes the width.
    final style = kumo.text().copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    var widest = 0.0;
    for (final option in options) {
      final painter = TextPainter(
        text: TextSpan(text: '$option', style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    const size = KumoFieldSize.base;
    final width = (widest + 2 * size.paddingX + 16 + KumoSpace.s2 + 2).ceilToDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: KumoSpace.s2,
      children: [
        Text(
          widget.perPageLabel ?? strings.perPage,
          style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
        ),
        SizedBox(
          width: width,
          child: KumoSelect<int>(
            value: perPage,
            semanticLabel: widget.pageSizeLabel ?? strings.pageSize,
            presentation: widget.presentation,
            onValueChange: (v) {
              if (v != null && v != perPage) widget.onPerPageChange!(v);
            },
            options: [for (final option in options) KumoSelectOption(value: option, label: '$option')],
          ),
        ),
      ],
    );
  }

  Widget _controls(BuildContext context, {required bool compact}) {
    final strings = context.kumoStrings;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final page = widget.page;
    final maxPage = _maxPage;
    final full = widget.controls == KumoPaginationControls.full && !_unknownTotal;
    final interactive = widget.onPageChange != null;
    final nextDisabled = _knownTotal ? page >= maxPage : widget.hasNextPage != true;
    final segments = <Widget>[
      if (full && !compact)
        _GroupButton(
          icon: rtl ? KumoIcons.caretDoubleRight : KumoIcons.caretDoubleLeft,
          label: strings.firstPage,
          onPress: !interactive || page <= 1 ? null : () => _go(1),
        ),
      _GroupButton(
        icon: rtl ? KumoIcons.caretRight : KumoIcons.caretLeft,
        label: strings.previousPage,
        onPress: !interactive || page <= 1 ? null : () => _go(math.max(page - 1, 1)),
      ),
      if (full)
        widget.pageSelector == KumoPaginationPageSelector.dropdown
            ? _PaginationSelect(
                value: page,
                options: [for (var i = 1; i <= maxPage; i++) i],
                semanticLabel: widget.pageNumberLabel ?? strings.pageNumber,
                presentation: widget.presentation,
                onChange: _go,
              )
            : _pageInput(context),
      _GroupButton(
        icon: rtl ? KumoIcons.caretLeft : KumoIcons.caretRight,
        label: strings.nextPage,
        onPress: !interactive || nextDisabled ? null : () => _go(_knownTotal ? math.min(page + 1, maxPage) : page + 1),
      ),
      if (full && !compact)
        _GroupButton(
          icon: rtl ? KumoIcons.caretDoubleLeft : KumoIcons.caretDoubleRight,
          label: strings.lastPage,
          onPress: !interactive || page >= maxPage ? null : () => _go(maxPage),
        ),
    ];
    final c = context.kumo.colors;
    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      if (i > 0) children.add(SizedBox(width: 1, child: ColoredBox(color: c.line)));
      children.add(segments[i]);
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: strings.pagination,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.base,
          borderRadius: BorderRadius.circular(KumoRadius.lg),
          border: KumoRing.border(c.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(KumoRadius.lg),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pageInput(BuildContext context) {
    final kumo = context.kumo;
    final height = _GroupButton.heightOf(context);
    final focused = _inputFocus.hasFocus;
    return Container(
      width: math.max(50, MediaQuery.textScalerOf(context).scale(50)),
      constraints: BoxConstraints(minHeight: height),
      alignment: Alignment.center,
      // Always set, so focusing the field never changes the tree around it.
      foregroundDecoration: BoxDecoration(
        border: KumoRing.inset(
          focused ? kumo.colors.focus.withValues(alpha: 0.5) : const Color(0x00000000),
          width: 1.5,
        ),
      ),
      color: kumo.colors.control,
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1),
      child: KumoEditable(
        controller: _input,
        focusNode: _inputFocus,
        enabled: widget.onPageChange != null,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.go,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        semanticLabel: widget.pageNumberLabel ?? context.kumoStrings.pageNumber,
        onSubmitted: (_) => _commitInput(),
      ),
    );
  }
}

/// One square button inside the joined pagination group.
class _GroupButton extends StatelessWidget {
  const _GroupButton({required this.icon, required this.label, required this.onPress});

  final IconData icon;
  final String label;
  final VoidCallback? onPress;

  /// Kumo's `h-9`, grown to the touch target on touch platforms.
  static double heightOf(BuildContext context) => math.max(36, context.kumo.minTapTarget);

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    final size = heightOf(context);
    final disabled = onPress == null;
    return KumoPressable(
      onPress: onPress,
      disabled: disabled,
      semanticLabel: label,
      excludeChildSemantics: true,
      scaleOnPress: false,
      showFocusRing: false,
      minTapTargetSize: 0,
      builder: (context, state) => KumoFocusRing(
        visible: state.focused,
        color: KumoColor.focus,
        width: 1.5,
        offset: -1.5,
        child: Container(
          width: size,
          constraints: BoxConstraints(minHeight: size),
          alignment: Alignment.center,
          color: disabled ? c.overlay : (state.active ? c.tint : c.base),
          child: KumoIcon(icon, color: disabled ? KumoColor.textInactive : KumoColor.textDefault),
        ),
      ),
    );
  }
}

/// The page number menu, drawn as a segment of the joined button group
/// (Kumo's `pageSelector="dropdown"`). Opens a menu anchored to it on wide
/// screens and a bottom sheet on narrow ones.
class _PaginationSelect extends StatefulWidget {
  const _PaginationSelect({
    required this.value,
    required this.options,
    required this.semanticLabel,
    required this.presentation,
    required this.onChange,
  });

  final int value;
  final List<int> options;
  final String semanticLabel;
  final KumoPresentation presentation;
  final ValueChanged<int> onChange;

  @override
  State<_PaginationSelect> createState() => _PaginationSelectState();
}

class _PaginationSelectState extends State<_PaginationSelect> {
  bool _open = false;

  List<Widget> _rows(VoidCallback close) => [
    for (final option in widget.options)
      KumoMenuRow(
        label: '$option',
        selected: option == widget.value,
        autofocus: option == widget.value,
        trailing: option == widget.value ? const KumoIcon(KumoIcons.check) : null,
        onPress: () {
          close();
          if (option != widget.value) widget.onChange(option);
        },
      ),
  ];

  Future<void> _press() async {
    if (!widget.presentation.usesSheet(context)) {
      setState(() => _open = !_open);
      return;
    }
    setState(() => _open = true);
    await showKumoSheet<void>(
      context: context,
      semanticLabel: widget.semanticLabel,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(KumoSpace.s2),
        child: KumoMenuKeyboard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _rows(() => KumoSheetScope.closeFrom(sheetContext)),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final height = _GroupButton.heightOf(context);
    final trigger = KumoPressable(
      onPress: _press,
      semanticLabel: widget.semanticLabel,
      semanticValue: '${widget.value}',
      expanded: _open,
      scaleOnPress: false,
      showFocusRing: false,
      minTapTargetSize: 0,
      builder: (context, state) {
        final row = Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1_5,
          children: [
            Text('${widget.value}', style: kumo.text().copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            const KumoIcon(KumoIcons.caretUpDown, size: 14, color: KumoColor.textSubtle),
          ],
        );
        return KumoFocusRing(
          visible: state.focused,
          color: KumoColor.focus,
          width: 1.5,
          offset: -1.5,
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
            alignment: Alignment.center,
            color: state.active ? kumo.colors.tint : kumo.colors.control,
            child: row,
          ),
        );
      },
    );
    if (widget.presentation.usesSheet(context)) return trigger;
    return KumoAnchoredOverlay(
      open: _open,
      onDismiss: () => setState(() => _open = false),
      matchAnchorWidth: true,
      align: KumoAlign.start,
      trapFocus: true,
      overlayBuilder: (context, placement) => KumoMenuPanel(
        minWidth: 72,
        maxHeight: math.min(placement.maxHeight, 320),
        semanticLabel: widget.semanticLabel,
        children: _rows(() => setState(() => _open = false)),
      ),
      child: trigger,
    );
  }
}
