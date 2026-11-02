import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../feedback/kumo_loader.dart';
import '../forms/src/field_motion.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../overlays/kumo_routes.dart';
import '../overlays/kumo_sheet.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'picker_internals.dart';

/// An inclusive `(start, end)` character range of a match, like Kumo's
/// `HighlightRange`.
typedef KumoHighlightRange = (int start, int end);

/// One command in a [KumoCommandPalette] (Kumo's `CommandPalette.Item` and
/// `ResultItem` data).
///
/// ```dart
/// KumoCommandItem(
///   title: 'Deploy image-resizer',
///   icon: KumoIcons.rocket,
///   breadcrumbs: ['Workers'],
///   shortcut: 'D',
///   keywords: ['publish', 'release'],
///   onSelect: () => deploy('image-resizer'),
/// )
/// ```
@immutable
class KumoCommandItem {
  const KumoCommandItem({
    required this.title,
    this.id,
    this.icon,
    this.description,
    this.breadcrumbs = const [],
    this.shortcut,
    this.keywords = const [],
    this.external = false,
    this.disabled = false,
    this.showArrow = true,
    this.onSelect,
    this.value,
  });

  final String title;

  /// Stable identity for the row; defaults to [title].
  final String? id;
  final IconData? icon;

  /// Secondary line under the title.
  final String? description;

  /// Path shown before the title with carets, such as `['Workers', 'Settings']`.
  final List<String> breadcrumbs;

  /// Key hint shown at the end of the row, such as `⌘D`.
  final String? shortcut;

  /// Extra terms the filter matches but the row does not show.
  final List<String> keywords;

  /// Marks a command that leaves the app (shows an external-link icon).
  final bool external;
  final bool disabled;

  /// Show an arrow on the highlighted row (Kumo's `showArrow`).
  final bool showArrow;

  /// Runs the command. Called after the palette starts closing.
  final VoidCallback? onSelect;

  /// Any data the app wants back from [showKumoCommandPalette].
  final Object? value;

  String get key => id ?? title;
}

/// A titled group of commands (Kumo's `CommandPalette.Group` + `GroupLabel`).
@immutable
class KumoCommandGroup {
  const KumoCommandGroup({this.label, required this.items});

  /// Heading above the group. Null for a flat list.
  final String? label;
  final List<KumoCommandItem> items;
}

/// Searches outside the palette (an API) for [query]; results are shown
/// after the local commands.
typedef KumoCommandSearch = Future<List<KumoCommandGroup>> Function(String query);

/// Kumo's `CommandPalette` panel: a search field over a list of grouped
/// commands, with empty, loading and error states and a footer for key
/// hints. Usually opened with [showKumoCommandPalette]; use the widget
/// directly to embed the panel in a page or your own dialog (Kumo's
/// `CommandPalette.Panel`).
///
/// * Filtering is built in and forgiving: every word typed must appear in
///   the title, breadcrumbs, description or keywords, or its letters in
///   order in the title. Best matches come first in each group and matched
///   letters are marked.
/// * The first result is highlighted; Up and Down move (wrapping), Enter
///   runs the command and Cmd+Enter (Ctrl+Enter elsewhere) runs it with
///   `newTab: true`. Focus stays in the search field.
/// * [onSearch] adds remote results with a loading row and an error row.
///
/// ```dart
/// KumoCommandPalette(
///   placeholder: 'Search commands',
///   groups: [
///     KumoCommandGroup(label: 'Workers', items: [
///       KumoCommandItem(title: 'Deploy image-resizer', icon: KumoIcons.rocket, onSelect: () {}),
///     ]),
///   ],
/// )
/// ```
class KumoCommandPalette extends StatefulWidget {
  const KumoCommandPalette({
    super.key,
    required this.groups,
    this.onSearch,
    this.filter,
    this.loading = false,
    this.placeholder,
    this.emptyMessage,
    this.searchErrorMessage,
    this.footer,
    this.onSelect,
    this.onClose,
    this.onQueryChange,
    this.initialQuery = '',
    this.inputLeading,
    this.inputTrailing,
    this.autofocus = true,
    this.semanticLabel,
    this.expand = false,
  });

  final List<KumoCommandGroup> groups;
  final KumoCommandSearch? onSearch;

  /// Replaces the built-in matching. Return true to keep [item] for
  /// [query]. [KumoCommandPalette.noFilter] keeps everything (the caller
  /// filters, as Kumo's default does).
  final bool Function(KumoCommandItem item, String query)? filter;

  /// Shows the loading state in place of the results.
  final bool loading;
  final String? placeholder;

  /// Empty state text. Defaults to [KumoStrings.noResults].
  final String? emptyMessage;

  /// Shown when [onSearch] fails. Default [KumoStrings.searchFailed].
  final String? searchErrorMessage;

  /// Usually a [KumoCommandPaletteFooter] of [KumoCommandPaletteKeyHint]s.
  final Widget? footer;

  /// Called after a command's own [KumoCommandItem.onSelect], with
  /// `newTab` true for Cmd/Ctrl+Enter or a Cmd/Ctrl+click.
  final void Function(KumoCommandItem item, {required bool newTab})? onSelect;

  /// Asks the container to close: with the command that ran, or null for
  /// Escape. [showKumoCommandPalette] pops its route here.
  final ValueChanged<KumoCommandItem?>? onClose;
  final ValueChanged<String>? onQueryChange;
  final String initialQuery;

  /// Replaces the search icon (a back button for drill-down pages).
  final Widget? inputLeading;

  /// Content at the end of the search row (an Esc hint, a close button).
  final Widget? inputTrailing;
  final bool autofocus;
  final String? semanticLabel;

  /// Fill the available height instead of sizing to the results (a
  /// full-height sheet).
  final bool expand;

  /// A [filter] that keeps every command.
  static bool noFilter(KumoCommandItem item, String query) => true;

  @override
  State<KumoCommandPalette> createState() => _KumoCommandPaletteState();
}

class _Match {
  const _Match(this.score, this.ranges);
  final int score;
  final List<KumoHighlightRange> ranges;
}

bool _wordStart(String s, int i) => i == 0 || !RegExp(r'[a-z0-9]').hasMatch(s[i - 1]);

/// Scores [item] for [query]; null when it does not match.
_Match? _matchCommand(KumoCommandItem item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const _Match(0, []);
  final title = item.title.toLowerCase();
  final rest = [...item.breadcrumbs, ...item.keywords, ?item.description].join(' ').toLowerCase();
  var score = 0;
  final ranges = <KumoHighlightRange>[];
  for (final token in q.split(RegExp(r'\s+'))) {
    final i = title.indexOf(token);
    if (i >= 0) {
      score += i == 0 ? 100 : (_wordStart(title, i) ? 60 : 30);
      ranges.add((i, i + token.length - 1));
      continue;
    }
    if (rest.contains(token)) {
      score += 10;
      continue;
    }
    if (token.length < 3) return null;
    // Letters in order ("dpl" finds "Deploy").
    final hits = <int>[];
    var from = 0;
    for (final ch in token.split('')) {
      final at = title.indexOf(ch, from);
      if (at < 0) return null;
      hits.add(at);
      from = at + 1;
    }
    score += 5;
    ranges.addAll(hits.map((h) => (h, h)));
  }
  return _Match(score, ranges);
}

enum _RowKind { label, item, gap }

class _Row {
  const _Row.label(this.text) : kind = _RowKind.label, item = null, ranges = const [], selectable = -1, height = 0;
  const _Row.item(this.item, this.ranges, this.selectable) : kind = _RowKind.item, text = null, height = 0;
  const _Row.gap(this.height) : kind = _RowKind.gap, text = null, item = null, ranges = const [], selectable = -1;

  final _RowKind kind;
  final String? text;
  final KumoCommandItem? item;
  final List<KumoHighlightRange> ranges;

  /// Index among selectable rows, or -1.
  final int selectable;
  final double height;
}

class _KumoCommandPaletteState extends State<KumoCommandPalette> {
  late final TextEditingController _text = TextEditingController(text: widget.initialQuery);
  final FocusNode _focus = FocusNode(debugLabel: 'KumoCommandPalette search');
  final ScrollController _scroll = ScrollController();
  final Map<int, BuildContext> _rowContexts = {};
  int _highlight = 0;

  List<KumoCommandGroup> _remote = const [];
  bool _pending = false;
  bool _failed = false;
  int _seq = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    widget.onQueryChange?.call(q);
    setState(() => _highlight = 0);
    _search(q);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _search(String q) {
    final search = widget.onSearch;
    if (search == null) return;
    final seq = ++_seq;
    if (q.trim().isEmpty) {
      setState(() {
        _remote = const [];
        _pending = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _pending = true;
      _failed = false;
    });
    search(q).then(
      (groups) {
        if (!mounted || seq != _seq) return;
        setState(() {
          _remote = groups;
          _pending = false;
        });
      },
      onError: (Object _) {
        if (!mounted || seq != _seq) return;
        setState(() {
          _remote = const [];
          _pending = false;
          _failed = true;
        });
      },
    );
  }

  ({List<_Row> rows, List<KumoCommandItem> selectable}) _results() {
    final q = _text.text;
    final rows = <_Row>[];
    final selectable = <KumoCommandItem>[];
    void addGroup(KumoCommandGroup g, {required bool remote}) {
      final matches = <(KumoCommandItem, _Match, int)>[];
      for (var i = 0; i < g.items.length; i++) {
        final item = g.items[i];
        _Match? m;
        if (remote) {
          m = _matchCommand(item, q) ?? const _Match(0, []);
        } else if (widget.filter != null) {
          m = q.trim().isEmpty || widget.filter!(item, q) ? const _Match(0, []) : null;
        } else {
          m = _matchCommand(item, q);
        }
        if (m != null) matches.add((item, m, i));
      }
      if (matches.isEmpty) return;
      if (!remote && widget.filter == null) {
        matches.sort((a, b) => b.$2.score != a.$2.score ? b.$2.score - a.$2.score : a.$3 - b.$3);
      }
      if (rows.isNotEmpty) rows.add(const _Row.gap(KumoSpace.s3));
      if (g.label != null) rows.add(_Row.label(g.label));
      for (var k = 0; k < matches.length; k++) {
        if (k > 0) rows.add(const _Row.gap(KumoSpace.s0_5));
        final (item, m, _) = matches[k];
        rows.add(_Row.item(item, m.ranges, item.disabled ? -1 : selectable.length));
        if (!item.disabled) selectable.add(item);
      }
    }

    for (final g in widget.groups) {
      addGroup(g, remote: false);
    }
    for (final g in _remote) {
      addGroup(g, remote: true);
    }
    return (rows: rows, selectable: selectable);
  }

  void _run(KumoCommandItem item, {required bool newTab}) {
    if (item.disabled) return;
    widget.onClose?.call(item);
    item.onSelect?.call();
    widget.onSelect?.call(item, newTab: newTab);
  }

  bool get _modifier {
    final kb = HardwareKeyboard.instance;
    return kb.isMetaPressed || kb.isControlPressed;
  }

  void _move(int to, int count) {
    if (count == 0) return;
    setState(() => _highlight = (to % count + count) % count);
    SchedulerBinding.instance.addPostFrameCallback((_) => _revealHighlight());
  }

  void _revealHighlight() {
    if (!mounted) return;
    final ctx = _rowContexts[_highlight];
    if (ctx == null || !ctx.mounted) return;
    unawaited(Scrollable.ensureVisible(ctx, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd));
    unawaited(Scrollable.ensureVisible(ctx, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event, List<KumoCommandItem> selectable) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(_highlight + 1, selectable.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(_highlight - 1, selectable.length);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_highlight < selectable.length) _run(selectable[_highlight], newTab: _modifier);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && widget.onClose != null) {
      widget.onClose!(null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildRow(BuildContext context, _Row row) {
    switch (row.kind) {
      case _RowKind.gap:
        return SizedBox(height: row.height);
      case _RowKind.label:
        return KumoCommandPaletteGroupLabel(row.text!);
      case _RowKind.item:
        final item = row.item!;
        final i = row.selectable;
        final tile = KumoCommandPaletteItem(
          item: item,
          titleHighlights: row.ranges,
          highlighted: i >= 0 && i == _highlight,
          onHover: i < 0 ? null : () => setState(() => _highlight = i),
          onPress: () => _run(item, newTab: _modifier),
        );
        return i < 0 ? tile : PickerRevealTarget(index: i, rows: _rowContexts, child: tile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final results = _results();
    final rows = results.rows;
    final selectable = results.selectable;
    if (_highlight >= selectable.length) _highlight = 0;

    final loadingAll = widget.loading || (_pending && rows.isEmpty);
    Widget body;
    final String bodyKind;
    if (loadingAll) {
      bodyKind = 'loading';
    } else if (rows.isEmpty && _failed) {
      bodyKind = 'error';
    } else if (rows.isEmpty) {
      bodyKind = 'empty';
    } else {
      bodyKind = 'list';
    }
    if (loadingAll) {
      body = const KumoCommandPaletteLoading();
    } else if (rows.isEmpty && _failed) {
      body = _ErrorRow(text: widget.searchErrorMessage ?? strings.searchFailed);
    } else if (rows.isEmpty) {
      body = KumoCommandPaletteEmpty(text: widget.emptyMessage ?? strings.noResults);
    } else {
      final extra = <Widget>[
        if (_pending) const _InlineLoading(),
        if (_failed) _ErrorRow(text: widget.searchErrorMessage ?? strings.searchFailed),
      ];
      body = ExcludeFocus(
        child: ListView.builder(
          controller: _scroll,
          shrinkWrap: true,
          padding: const EdgeInsets.all(KumoSpace.s2),
          itemCount: rows.length + extra.length,
          itemBuilder: (context, i) => i < rows.length ? _buildRow(context, rows[i]) : extra[i - rows.length],
        ),
      );
    }
    // Loading, empty, error and results swap with a short fade, and the
    // panel's height follows the results as they narrow instead of jumping.
    // Rows are reused by position while filtering, so they never flash.
    body = FadeInOnChange(token: bodyKind, child: body);
    if (!KumoMotion.reduceMotion(context) && !widget.expand) {
      body = AnimatedSize(
        duration: KumoDurations.quick,
        curve: KumoCurves.standard,
        alignment: Alignment.topCenter,
        child: body,
      );
    }

    final input = KumoCommandPaletteInput(
      controller: _text,
      focusNode: _focus,
      autofocus: widget.autofocus,
      placeholder: widget.placeholder,
      semanticLabel: widget.semanticLabel ?? widget.placeholder ?? strings.search,
      leading: widget.inputLeading,
      trailing: widget.inputTrailing,
      onChanged: _onChanged,
      onKeyEvent: (node, event) => _onKey(node, event, selectable),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: Container(
        decoration: BoxDecoration(color: kumo.colors.elevated, borderRadius: BorderRadius.circular(KumoRadius.lg)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            input,
            Flexible(
              fit: widget.expand ? FlexFit.tight : FlexFit.loose,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kumo.colors.base,
                  border: Border(top: BorderSide(color: kumo.colors.hairline)),
                  borderRadius: widget.footer == null
                      ? null
                      : const BorderRadius.vertical(bottom: Radius.circular(KumoRadius.lg)),
                ),
                child: body,
              ),
            ),
            ?widget.footer,
          ],
        ),
      ),
    );
  }
}

/// The search row at the top of the palette: `px-4 py-3 bg-kumo-base`, a
/// search icon and a borderless 14px input.
class KumoCommandPaletteInput extends StatelessWidget {
  const KumoCommandPaletteInput({
    super.key,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.semanticLabel,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onKeyEvent,
    this.autofocus = true,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final String? semanticLabel;

  /// Replaces the search icon.
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  /// Key handling for the field (arrows, Enter) while focus stays in it.
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return ColoredBox(
      color: kumo.colors.base,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s3),
        child: Row(
          spacing: KumoSpace.s3,
          children: [
            leading ?? const KumoIcon(KumoIcons.magnifyingGlass, color: KumoColor.textSubtle),
            Expanded(
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onKeyEvent: onKeyEvent,
                child: KumoEditable(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  placeholder: placeholder,
                  semanticLabel: semanticLabel,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.go,
                  onChanged: onChanged,
                  onEditingComplete: () {},
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A group heading: `px-2 pt-1 mb-2 text-xs font-semibold text-kumo-subtle`.
class KumoCommandPaletteGroupLabel extends StatelessWidget {
  const KumoCommandPaletteGroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(
        start: KumoSpace.s2,
        end: KumoSpace.s2,
        top: KumoSpace.s1,
        bottom: KumoSpace.s2,
      ),
      child: Text(
        text,
        style: context.kumo.text(size: KumoTextSize.xs, weight: KumoTypography.semibold, color: KumoColor.textSubtle),
      ),
    ),
  );
}

/// Text with matched ranges marked (`bg-kumo-warning/50`), Kumo's
/// `CommandPalette.HighlightedText`. Ranges are inclusive and may overlap.
///
/// ```dart
/// const KumoCommandPaletteHighlightedText('Purge cache', highlights: [(0, 4)])
/// ```
class KumoCommandPaletteHighlightedText extends StatelessWidget {
  const KumoCommandPaletteHighlightedText(
    this.text, {
    super.key,
    this.highlights = const [],
    this.style,
    this.maxLines = 1,
  });

  final String text;
  final List<KumoHighlightRange> highlights;
  final TextStyle? style;
  final int? maxLines;

  /// Sorted, merged ranges clipped to [length]: adjacent or overlapping
  /// ranges become one.
  static List<KumoHighlightRange> merge(List<KumoHighlightRange> ranges, int length) {
    final sorted = [...ranges.where((r) => r.$1 <= r.$2 && r.$1 < length)]..sort((a, b) => a.$1 - b.$1);
    final out = <KumoHighlightRange>[];
    for (final r in sorted) {
      final end = r.$2 >= length ? length - 1 : r.$2;
      if (out.isNotEmpty && r.$1 <= out.last.$2 + 1) {
        final last = out.removeLast();
        out.add((last.$1, end > last.$2 ? end : last.$2));
      } else {
        out.add((r.$1 < 0 ? 0 : r.$1, end));
      }
    }
    return out;
  }

  /// [text] split into spans, with the [highlights] marked, for use inside
  /// a larger [Text.rich].
  static List<TextSpan> spans(BuildContext context, String text, List<KumoHighlightRange> highlights) {
    final kumo = context.kumo;
    final mark = TextStyle(backgroundColor: kumo.colors.warning.withValues(alpha: 0.5), color: kumo.colors.textDefault);
    final out = <TextSpan>[];
    var at = 0;
    for (final (start, end) in merge(highlights, text.length)) {
      if (start > at) out.add(TextSpan(text: text.substring(at, start)));
      out.add(TextSpan(text: text.substring(start, end + 1), style: mark));
      at = end + 1;
    }
    if (at < text.length) out.add(TextSpan(text: text.substring(at)));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.kumo.text();
    final spans = KumoCommandPaletteHighlightedText.spans(context, text, highlights);
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// One palette row (Kumo's `CommandPalette.ResultItem`): icon, breadcrumbs,
/// title with marked matches, external-link icon, description, shortcut and
/// an arrow on the highlighted row. `rounded-lg px-2 py-1.5`, highlighted
/// with `bg-kumo-overlay`.
class KumoCommandPaletteItem extends StatelessWidget {
  const KumoCommandPaletteItem({
    super.key,
    required this.item,
    this.titleHighlights = const [],
    this.highlighted = false,
    this.onPress,
    this.onHover,
  });

  final KumoCommandItem item;
  final List<KumoHighlightRange> titleHighlights;

  /// The keyboard highlight (Kumo's `data-highlighted`).
  final bool highlighted;
  final VoidCallback? onPress;

  /// Called when a mouse enters the row, to move the highlight to it.
  final VoidCallback? onHover;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final title = Text.rich(
      TextSpan(
        children: [
          for (final crumb in item.breadcrumbs) ...[
            TextSpan(text: crumb),
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: KumoSpace.s2),
                child: KumoIcon(KumoIcons.caretRight, size: 12, color: KumoColor.textSubtle),
              ),
            ),
          ],
          ...KumoCommandPaletteHighlightedText.spans(context, item.title, titleHighlights),
          if (item.external)
            const WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: KumoSpace.s2),
                child: KumoIcon(KumoIcons.arrowSquareOut, size: 14, color: KumoColor.textSubtle),
              ),
            ),
        ],
      ),
      style: kumo.text(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final semantic = [...item.breadcrumbs, item.title].join(', ');
    return MouseRegion(
      onEnter: onHover == null ? null : (_) => onHover!(),
      child: KumoPressable(
        onPress: item.disabled ? null : onPress,
        disabled: item.disabled,
        scaleOnPress: false,
        showFocusRing: false,
        minTapTargetSize: 0,
        semanticLabel: semantic,
        semanticHint: item.description,
        selected: highlighted,
        isLink: item.external,
        excludeChildSemantics: true,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        builder: (context, state) => Opacity(
          opacity: item.disabled ? 0.5 : 1,
          child: _HighlightFill(
            highlighted: highlighted && !state.active,
            color: c.overlay,
            child: Container(
              constraints: BoxConstraints(minHeight: kumo.minTapTarget > 0 ? 44 : 0),
              padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1_5),
              // The keyboard highlight fades between rows (Kumo's
              // `transition-colors`); the pointer's own hover shows at once.
              decoration: BoxDecoration(
                color: state.active ? c.overlay : null,
                borderRadius: BorderRadius.circular(KumoRadius.lg),
              ),
              child: Row(
                spacing: KumoSpace.s3,
                children: [
                  if (item.icon != null) KumoIcon(item.icon!, color: KumoColor.textSubtle),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        if (item.description != null)
                          Text(
                            item.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
                          ),
                      ],
                    ),
                  ),
                  if (item.shortcut != null) KumoCommandPaletteKbd(item.shortcut!),
                  if (item.showArrow && !item.external)
                    AnimatedOpacity(
                      opacity: highlighted ? 1 : 0,
                      duration: KumoMotion.duration(context, KumoDurations.fast),
                      curve: KumoCurves.standard,
                      child: const KumoIcon(KumoIcons.arrowRight, color: KumoColor.textSubtle),
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

/// Paints the keyboard highlight behind a palette row, fading in and out
/// over Kumo's 100ms so the highlight reads as moving between rows.
class _HighlightFill extends StatelessWidget {
  const _HighlightFill({required this.highlighted, required this.color, required this.child});

  final bool highlighted;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: highlighted ? 1 : 0,
            duration: KumoMotion.duration(context, KumoDurations.fast),
            curve: KumoCurves.standard,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(KumoRadius.lg)),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

/// A key cap: `rounded border border-kumo-hairline bg-kumo-base px-1.5
/// py-0.5 text-[10px]`, as in Kumo's palette footer.
class KumoCommandPaletteKbd extends StatelessWidget {
  const KumoCommandPaletteKbd(this.text, {super.key, this.icon});

  final String text;

  /// Draws an icon in place of [text] (arrow keys); [text] is still read
  /// by screen readers.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1_5, vertical: KumoSpace.s0_5),
        decoration: BoxDecoration(
          color: kumo.colors.base,
          borderRadius: BorderRadius.circular(KumoRadius.sm),
          border: Border.all(color: kumo.colors.hairline),
        ),
        child: icon != null
            ? KumoIcon(icon!, size: 10, color: KumoColor.textSubtle)
            : Text(
                text,
                style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle).copyWith(fontSize: 10),
              ),
      ),
    );
  }
}

/// A footer hint: key caps followed by what they do ("Navigate").
///
/// ```dart
/// KumoCommandPaletteKeyHint(label: 'Navigate', keys: ['Up', 'Down'], icons: [KumoIcons.arrowUp, KumoIcons.arrowDown])
/// ```
class KumoCommandPaletteKeyHint extends StatelessWidget {
  const KumoCommandPaletteKeyHint({super.key, required this.label, required this.keys, this.icons = const []});

  final String label;

  /// Key names, read by screen readers and drawn unless [icons] has an icon
  /// at the same position.
  final List<String> keys;
  final List<IconData> icons;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: KumoSpace.s2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1,
          children: [
            for (var i = 0; i < keys.length; i++)
              KumoCommandPaletteKbd(keys[i], icon: i < icons.length ? icons[i] : null),
          ],
        ),
        Text(label),
      ],
    );
  }
}

/// The palette footer: `bg-kumo-elevated px-4 py-3 text-xs text-kumo-subtle`,
/// children spread across the row (wrapping on narrow widths). Kumo leaves
/// the hints to the app so they can be translated.
class KumoCommandPaletteFooter extends StatelessWidget {
  const KumoCommandPaletteFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return ColoredBox(
      color: kumo.colors.elevated,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s3),
        child: DefaultTextStyle.merge(
          style: kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: KumoSpace.s4,
            runSpacing: KumoSpace.s2,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// The empty state: centered subtle text with `p-8`, announced.
class KumoCommandPaletteEmpty extends StatelessWidget {
  const KumoCommandPaletteEmpty({super.key, this.text});

  /// Defaults to [KumoStrings.noResults].
  final String? text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(KumoSpace.s8),
      child: Text(
        text ?? context.kumoStrings.noResults,
        textAlign: TextAlign.center,
        style: context.kumo.text(color: KumoColor.textSubtle),
      ),
    ),
  );
}

/// The loading state: a centered 24px [KumoLoader] with `p-8`.
class KumoCommandPaletteLoading extends StatelessWidget {
  const KumoCommandPaletteLoading({super.key, this.child});

  /// Replaces the spinner.
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KumoSpace.s8),
    child: Center(child: child ?? KumoLoader(semanticLabel: context.kumoStrings.loading)),
  );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KumoSpace.s2),
    child: PickerStatusRow(text: context.kumoStrings.loading, loading: true),
  );
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.all(KumoSpace.s4),
      child: Row(
        spacing: KumoSpace.s2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: KumoIcon(KumoIcons.warningCircle, color: KumoColor.textDanger),
          ),
          Expanded(
            child: Text(text, style: context.kumo.text(color: KumoColor.textDanger)),
          ),
        ],
      ),
    ),
  );
}

// The open palette's route. A route that was removed without completing
// (its navigator went away) is no longer active, so it never blocks.
Route<Object?>? _openPalette;

/// Opens a [KumoCommandPalette] and completes with the command that ran, or
/// null when it was dismissed.
///
/// * Wide screens: a dialog 10% from the top, up to 672px wide and 60% of
///   the screen tall, over the Kumo scrim ([KumoDialogRoute]). Escape or a
///   scrim tap closes it.
/// * Below 768px ([KumoPresentation.auto]): a full-height sheet that
///   follows the finger, with a Cancel button, and without the [footer]
///   (key hints mean little on a touch keyboard).
///
/// The search field takes focus right away. Only one palette opens at a
/// time; a second call while one is open returns null.
///
/// ```dart
/// final ran = await showKumoCommandPalette(
///   context: context,
///   placeholder: 'Search commands',
///   groups: [
///     KumoCommandGroup(label: 'Cache', items: [
///       KumoCommandItem(title: 'Purge everything', icon: KumoIcons.trash, onSelect: () {}),
///     ]),
///   ],
/// );
/// ```
Future<KumoCommandItem?> showKumoCommandPalette({
  required BuildContext context,
  required List<KumoCommandGroup> groups,
  KumoCommandSearch? onSearch,
  bool Function(KumoCommandItem item, String query)? filter,
  String? placeholder,
  String? emptyMessage,
  Widget? footer,
  void Function(KumoCommandItem item, {required bool newTab})? onSelect,
  KumoPresentation presentation = KumoPresentation.auto,
  String? semanticLabel,
  bool useRootNavigator = true,
}) async {
  if (_openPalette?.isActive ?? false) return null;
  try {
    final sheet = presentation.usesSheet(context);
    Widget palette(BuildContext context, {required void Function(KumoCommandItem?) close}) => KumoCommandPalette(
      groups: groups,
      onSearch: onSearch,
      filter: filter,
      placeholder: placeholder,
      emptyMessage: emptyMessage,
      footer: sheet ? null : footer,
      onSelect: onSelect,
      semanticLabel: semanticLabel,
      onClose: close,
      expand: sheet,
      inputTrailing: sheet
          ? KumoButton(
              label: context.kumoStrings.cancel,
              variant: KumoButtonVariant.ghost,
              size: KumoButtonSize.sm,
              onPress: () => close(null),
            )
          : null,
    );

    if (sheet) {
      return await showKumoSheet<KumoCommandItem>(
        context: context,
        useRootNavigator: useRootNavigator,
        semanticLabel: semanticLabel ?? placeholder,
        snapPoints: const [1],
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Builder(
            builder: (inner) {
              _openPalette = ModalRoute.of(inner);
              return palette(inner, close: (item) => KumoSheetScope.closeFrom(inner, item));
            },
          ),
        ),
      );
    }
    final route = KumoDialogRoute<KumoCommandItem>(
      semanticLabel: semanticLabel ?? placeholder,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: size.height * 0.1, left: KumoSpace.s4, right: KumoSpace.s4),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 672, maxHeight: size.height * 0.6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KumoRadius.lg),
                  border: KumoRing.border(context.kumo.colors.line),
                  boxShadow: KumoShadow.lg.boxShadows,
                ),
                child: palette(context, close: (item) => Navigator.of(context).pop(item)),
              ),
            ),
          ),
        );
      },
    );
    _openPalette = route;
    return await Navigator.of(context, rootNavigator: useRootNavigator).push<KumoCommandItem>(route);
  } finally {
    _openPalette = null;
  }
}

/// Opens the command palette on Cmd+K (macOS and iOS) or Ctrl+K (other
/// platforms) from anywhere in [child], including from inside text fields.
/// The shortcut is ignored while another route covers this one, so a
/// palette that is already open is not opened again.
///
/// ```dart
/// KumoCommandPaletteShortcut(
///   onTrigger: () => showKumoCommandPalette(context: context, groups: commands),
///   child: const DashboardPage(),
/// )
/// ```
class KumoCommandPaletteShortcut extends StatefulWidget {
  const KumoCommandPaletteShortcut({
    super.key,
    required this.child,
    required this.onTrigger,
    this.letter = LogicalKeyboardKey.keyK,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTrigger;

  /// The letter combined with Cmd or Ctrl.
  final LogicalKeyboardKey letter;
  final bool enabled;

  /// Whether this platform uses Cmd (rather than Ctrl) for the shortcut.
  static bool get usesMeta =>
      defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

  /// The shortcut as text for a hint, such as "⌘K" or "Ctrl K".
  static String label({LogicalKeyboardKey key = LogicalKeyboardKey.keyK}) =>
      usesMeta ? '⌘${key.keyLabel.toUpperCase()}' : 'Ctrl ${key.keyLabel.toUpperCase()}';

  @override
  State<KumoCommandPaletteShortcut> createState() => _KumoCommandPaletteShortcutState();
}

class _KumoCommandPaletteShortcutState extends State<KumoCommandPaletteShortcut> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handle);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handle);
    super.dispose();
  }

  bool _handle(KeyEvent event) {
    if (!widget.enabled || !mounted || event is! KeyDownEvent || event.logicalKey != widget.letter) return false;
    final kb = HardwareKeyboard.instance;
    final modifier = KumoCommandPaletteShortcut.usesMeta ? kb.isMetaPressed : kb.isControlPressed;
    if (!modifier || kb.isShiftPressed || kb.isAltPressed) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    widget.onTrigger();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
