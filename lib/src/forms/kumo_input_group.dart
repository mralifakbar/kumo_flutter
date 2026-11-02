import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../overlays/kumo_anchored_overlay.dart';
import '../overlays/kumo_tooltip.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'src/forms_internal.dart';

/// Which side of the input a [KumoInputGroupAddon] sits on.
enum KumoInputGroupAlign {
  /// Before the input (left in LTR).
  start,

  /// After the input and any suffix.
  end,
}

/// Kumo's `InputGroup`: one field built from an input and the parts around
/// it, sharing a single ring and a single focus ring.
///
/// Parts:
/// * [KumoInputGroupInput], the text input (exactly one).
/// * [KumoInputGroupAddon], an icon, text or compact button at the start or end.
/// * [KumoInputGroupSuffix], text that follows the typed value (`.workers.dev`).
/// * [KumoInputGroupButton], a ghost button inside an addon, or a solid
///   button attached to the end of the group as a direct child.
///
/// Start addons are always drawn first and end addons last, whatever their
/// order in [children]. Solid direct buttons sit outside the shared ring, each
/// with its own border and focus treatment (Kumo's hybrid focus mode).
///
/// ```dart
/// KumoInputGroup(
///   label: 'Subdomain',
///   children: [
///     KumoInputGroupInput(value: subdomain, onValueChange: (v) => setState(() => subdomain = v)),
///     const KumoInputGroupSuffix('.workers.dev'),
///     const KumoInputGroupAddon(
///       align: KumoInputGroupAlign.end,
///       child: KumoIcon(KumoIcons.checkCircle, color: KumoColor.textSuccess, semanticLabel: 'Available'),
///     ),
///   ],
/// )
/// ```
///
/// Tapping anywhere in the group that is not a button focuses the input.
class KumoInputGroup extends StatefulWidget {
  const KumoInputGroup({
    super.key,
    required this.children,
    this.size = KumoFieldSize.base,
    this.disabled = false,
    this.label,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
  });

  /// The parts: one [KumoInputGroupInput] plus addons, a suffix and buttons.
  final List<Widget> children;

  /// Applies to every part.
  final KumoFieldSize size;

  /// Disables the input and every button in the group.
  final bool disabled;

  /// Text above the group; also the input's accessible name.
  final String? label;
  final String? labelTooltip;
  final String? description;

  /// Error message below the group; also turns the ring red.
  final String? error;
  final bool required;

  /// Shows "(optional)" after the label.
  final bool showOptional;

  @override
  State<KumoInputGroup> createState() => _KumoInputGroupState();
}

/// Spacing for one group size (Kumo's `INPUT_GROUP_SIZE`).
class _GroupTokens {
  const _GroupTokens({
    required this.inputOuter,
    required this.inputSeam,
    required this.addonOuter,
    required this.addonButtonOuterStart,
    required this.addonButtonOuterEnd,
    required this.iconSize,
  });

  /// Input padding at the group edge (`px-3` at base).
  final double inputOuter;

  /// Input padding on a side that touches an addon (`pl-2` at base).
  final double inputSeam;

  /// Addon padding on the group-edge side.
  final double addonOuter;

  /// Addon padding when it holds a button, which brings its own padding.
  final double addonButtonOuterStart;
  final double addonButtonOuterEnd;
  final double iconSize;

  static _GroupTokens of(KumoFieldSize size) => switch (size) {
    KumoFieldSize.xs => const _GroupTokens(
      inputOuter: 6,
      inputSeam: 4,
      addonOuter: 6,
      addonButtonOuterStart: 4,
      addonButtonOuterEnd: 4,
      iconSize: 10,
    ),
    KumoFieldSize.sm => const _GroupTokens(
      inputOuter: 8,
      inputSeam: 6,
      addonOuter: 6,
      addonButtonOuterStart: 4,
      addonButtonOuterEnd: 4,
      iconSize: 13,
    ),
    KumoFieldSize.base => const _GroupTokens(
      inputOuter: 12,
      inputSeam: 8,
      addonOuter: 8,
      addonButtonOuterStart: 4,
      addonButtonOuterEnd: 4,
      iconSize: 18,
    ),
    KumoFieldSize.lg => const _GroupTokens(
      inputOuter: 16,
      inputSeam: 10,
      addonOuter: 10,
      addonButtonOuterStart: 6,
      addonButtonOuterEnd: 2,
      iconSize: 20,
    ),
  };
}

class _GroupHandle {
  FocusNode? input;
}

class _InputGroupScope extends InheritedWidget {
  const _InputGroupScope({
    required this.size,
    required this.disabled,
    required this.label,
    required this.description,
    required this.error,
    required this.tooltip,
    required this.required,
    required this.hasStartAddon,
    required this.hasEndAddon,
    required this.hasSuffix,
    required this.handle,
    required super.child,
  });

  final KumoFieldSize size;
  final bool disabled;
  final String? label;
  final String? description;
  final String? error;
  final String? tooltip;
  final bool required;
  final bool hasStartAddon;
  final bool hasEndAddon;
  final bool hasSuffix;
  final _GroupHandle handle;

  _GroupTokens get tokens => _GroupTokens.of(size);

  static _InputGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InputGroupScope>();

  @override
  bool updateShouldNotify(_InputGroupScope old) =>
      size != old.size ||
      disabled != old.disabled ||
      label != old.label ||
      description != old.description ||
      error != old.error ||
      tooltip != old.tooltip ||
      required != old.required ||
      hasStartAddon != old.hasStartAddon ||
      hasEndAddon != old.hasEndAddon ||
      hasSuffix != old.hasSuffix;
}

/// Marks a solid button attached to the end of the group.
class _EdgeButtonScope extends InheritedWidget {
  const _EdgeButtonScope({required this.last, required super.child});

  final bool last;

  static _EdgeButtonScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_EdgeButtonScope>();

  @override
  bool updateShouldNotify(_EdgeButtonScope old) => last != old.last;
}

class _KumoInputGroupState extends State<KumoInputGroup> {
  final _handle = _GroupHandle();
  bool _focusWithin = false;

  void _focusInput() {
    if (!widget.disabled) _handle.input?.requestFocus();
  }

  bool _isEdgeButton(Widget w) => w is KumoInputGroupButton && w.variant != KumoButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final dir = Directionality.of(context);

    final startAddons = <Widget>[];
    final endAddons = <Widget>[];
    final edgeButtons = <Widget>[];
    final middle = <Widget>[];
    for (final child in widget.children) {
      if (child is KumoInputGroupAddon) {
        (child.align == KumoInputGroupAlign.start ? startAddons : endAddons).add(child);
      } else if (_isEdgeButton(child)) {
        edgeButtons.add(child);
      } else {
        middle.add(child);
      }
    }
    final hasSuffix = middle.any((w) => w is KumoInputGroupSuffix);
    final split = edgeButtons.isNotEmpty;

    final middleRow = hasSuffix
        ? LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                for (final w in middle)
                  if (w is KumoInputGroupInput)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                      child: w,
                    )
                  else if (w is KumoInputGroupSuffix)
                    Expanded(child: w)
                  else
                    w,
              ],
            ),
          )
        : Row(
            children: [
              for (final w in middle)
                if (w is KumoInputGroupInput) Expanded(child: w) else w,
            ],
          );

    final radius = size.radius;
    final zoneRadius = split
        ? BorderRadiusDirectional.horizontal(start: Radius.circular(radius)).resolve(dir)
        : BorderRadius.circular(radius);

    Widget zone = KumoFieldBox(
      size: size,
      focused: _focusWithin,
      error: widget.error != null,
      disabled: widget.disabled,
      padding: EdgeInsets.zero,
      borderRadius: zoneRadius,
      child: Row(
        children: [
          ...startAddons,
          Expanded(child: middleRow),
          ...endAddons,
        ],
      ),
    );
    zone = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) {
        if (v != _focusWithin) setState(() => _focusWithin = v);
      },
      child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _focusInput, child: zone),
    );

    Widget group = zone;
    if (split) {
      // Both sides have the group's min height and the same text size, so
      // they stay level at any text scale without intrinsic sizing.
      group = Row(
        children: [
          Expanded(child: zone),
          for (var i = 0; i < edgeButtons.length; i++)
            _EdgeButtonScope(last: i == edgeButtons.length - 1, child: edgeButtons[i]),
        ],
      );
    }

    group = Semantics(
      container: true,
      explicitChildNodes: true,
      child: _InputGroupScope(
        size: size,
        disabled: widget.disabled,
        label: widget.label,
        description: widget.description,
        error: widget.error,
        tooltip: widget.labelTooltip,
        required: widget.required,
        hasStartAddon: startAddons.isNotEmpty,
        hasEndAddon: endAddons.isNotEmpty,
        hasSuffix: hasSuffix,
        handle: _handle,
        child: group,
      ),
    );

    return FormsFieldFrame(
      label: widget.label,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      showOptional: widget.showOptional,
      onLabelTap: _focusInput,
      child: group,
    );
  }
}

/// The text input of a [KumoInputGroup]. Size, disabled state, label and
/// error come from the group.
///
/// ```dart
/// KumoInputGroupInput(
///   placeholder: 'endpoint',
///   semanticLabel: 'API path',
///   value: path,
///   onValueChange: (v) => setState(() => path = v),
/// )
/// ```
///
/// Next to a [KumoInputGroupSuffix] the input is as wide as its text, so the
/// suffix follows the value as it is typed.
class KumoInputGroupInput extends StatefulWidget {
  const KumoInputGroupInput({
    super.key,
    this.value,
    this.onValueChange,
    this.controller,
    this.focusNode,
    this.placeholder,
    this.semanticLabel,
    this.readOnly = false,
    this.obscureText = false,
    this.mono = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.passwordManagerIgnore = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.maxLength,
    this.autofocus = false,
    this.onSubmitted,
    this.scrollPadding = formsScrollPadding,
  });

  /// The text. Null leaves the input uncontrolled.
  final String? value;
  final ValueChanged<String>? onValueChange;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? placeholder;

  /// Accessible name when the group has no label.
  final String? semanticLabel;
  final bool readOnly;
  final bool obscureText;
  final bool mono;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  /// Keeps password managers away from a non-credential field.
  final bool passwordManagerIgnore;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final EdgeInsets scrollPadding;

  @override
  State<KumoInputGroupInput> createState() => _KumoInputGroupInputState();
}

class _KumoInputGroupInputState extends FormsTextState<KumoInputGroupInput> {
  _InputGroupScope? _scope;

  @override
  String? get controlledValue => widget.value;
  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleText);
  }

  @override
  void didUpdateWidget(KumoInputGroupInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    previousController(oldWidget.controller)?.removeListener(_handleText);
    syncWidget(oldWidget.controller, oldWidget.focusNode);
    controller.addListener(_handleText);
  }

  @override
  void dispose() {
    controller.removeListener(_handleText);
    if (_scope?.handle.input == focusNode) _scope!.handle.input = null;
    super.dispose();
  }

  // Only the suffix layout depends on the text width.
  void _handleText() {
    if (_scope?.hasSuffix ?? false) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope = _InputGroupScope.maybeOf(context);
    scope?.handle.input = focusNode;
    final size = scope?.size ?? KumoFieldSize.base;
    final tokens = _GroupTokens.of(size);
    final disabled = scope?.disabled ?? false;
    final hasSuffix = scope?.hasSuffix ?? false;
    final ignorePm = widget.passwordManagerIgnore;

    final start = (scope?.hasStartAddon ?? false) ? tokens.inputSeam : tokens.inputOuter;
    final end = hasSuffix ? 0.0 : ((scope?.hasEndAddon ?? false) ? tokens.inputSeam : tokens.inputOuter);

    Widget editable = KumoEditable(
      controller: controller,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      size: size.textSize,
      mono: widget.mono,
      enabled: !disabled,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autofocus: widget.autofocus,
      autocorrect: widget.autocorrect && !ignorePm,
      enableSuggestions: widget.enableSuggestions && !ignorePm,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      autofillHints: ignorePm ? null : widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      onChanged: widget.onValueChange,
      onSubmitted: widget.onSubmitted,
      scrollPadding: widget.scrollPadding,
    );

    if (hasSuffix) {
      // field-sizing: content. Measure the text (or the placeholder) so the
      // suffix sits right after it; the caret needs a little room too.
      final kumo = context.kumo;
      final style = widget.mono
          ? kumo.code(large: size == KumoFieldSize.base || size == KumoFieldSize.lg)
          : kumo.text(size: size.textSize);
      final text = controller.text.isEmpty ? (widget.placeholder ?? '') : controller.text;
      final painter = TextPainter(
        text: TextSpan(text: widget.obscureText ? '•' * text.length : text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width + 4;
      painter.dispose();
      editable = SizedBox(width: width, child: editable);
    }

    return Padding(
      padding: EdgeInsetsDirectional.only(start: start, end: end),
      child: FormsFieldSemantics(
        label: scope?.label ?? widget.semanticLabel,
        description: scope?.description,
        error: scope?.error,
        tooltip: scope?.tooltip,
        required: scope?.required ?? false,
        child: editable,
      ),
    );
  }
}

/// An icon, text or compact button at the start or end of a
/// [KumoInputGroup], in subtle text.
///
/// ```dart
/// const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass)
/// const KumoInputGroupAddon(text: '/api/')
/// const KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '.json')
/// ```
///
/// Icons given as [icon] are sized to the group (18px at base). Decorative
/// icons stay hidden from screen readers; a status icon in [child] needs its
/// own `semanticLabel`.
class KumoInputGroupAddon extends StatelessWidget {
  const KumoInputGroupAddon({super.key, this.align = KumoInputGroupAlign.start, this.icon, this.text, this.child});

  final KumoInputGroupAlign align;
  final IconData? icon;
  final String? text;

  /// Any other content: a [KumoInputGroupButton], a [KumoLoader], a status icon.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scope = _InputGroupScope.maybeOf(context);
    final size = scope?.size ?? KumoFieldSize.base;
    final tokens = _GroupTokens.of(size);
    final kumo = context.kumo;
    final hasButton = child is KumoInputGroupButton;
    final outer = align == KumoInputGroupAlign.start
        ? (hasButton ? tokens.addonButtonOuterStart : tokens.addonOuter)
        : (hasButton ? tokens.addonButtonOuterEnd : tokens.addonOuter);

    return Padding(
      padding: align == KumoInputGroupAlign.start
          ? EdgeInsetsDirectional.only(start: outer)
          : EdgeInsetsDirectional.only(end: outer),
      child: DefaultTextStyle.merge(
        style: kumo.text(size: size.textSize, color: KumoColor.textSubtle),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1_5,
          children: [
            if (icon != null) KumoIcon(icon!, size: tokens.iconSize, color: KumoColor.textSubtle),
            if (text != null) Text(text!, maxLines: 1),
            ?child,
          ],
        ),
      ),
    );
  }
}

/// Text that follows the typed value inside a [KumoInputGroup], such as a
/// domain (`.workers.dev`). It truncates when the value fills the field.
///
/// ```dart
/// const KumoInputGroupSuffix('.workers.dev')
/// ```
class KumoInputGroupSuffix extends StatelessWidget {
  const KumoInputGroupSuffix(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scope = _InputGroupScope.maybeOf(context);
    final size = scope?.size ?? KumoFieldSize.base;
    final tokens = _GroupTokens.of(size);
    final pad = (scope?.hasEndAddon ?? false) ? tokens.inputSeam : tokens.inputOuter;
    return Padding(
      padding: EdgeInsetsDirectional.only(end: pad),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: context.kumo.text(size: size.textSize, color: KumoColor.textSubtle),
      ),
    );
  }
}

/// A button inside a [KumoInputGroup].
///
/// Inside a [KumoInputGroupAddon] it is a compact ghost button one size
/// below the group (a 26px button in a 36px group), for actions on the value:
/// show or hide, clear, copy, help. As a direct child of the group with a
/// solid [variant] it attaches to the end of the group at full height, with
/// its own border and focus treatment (a "Search" or "Apply" button).
///
/// ```dart
/// KumoInputGroupAddon(
///   align: KumoInputGroupAlign.end,
///   child: KumoInputGroupButton(
///     icon: KumoIcons.x,
///     semanticLabel: 'Clear search',
///     onPress: () => setState(() => query = ''),
///   ),
/// )
/// KumoInputGroupButton(label: 'Search', variant: KumoButtonVariant.secondary, onPress: search)
/// ```
class KumoInputGroupButton extends StatelessWidget {
  const KumoInputGroupButton({
    super.key,
    this.label,
    this.icon,
    this.onPress,
    this.variant = KumoButtonVariant.ghost,
    this.semanticLabel,
    this.tooltip,
    this.disabled = false,
  }) : assert(label != null || icon != null, 'Pass a label or an icon'),
       assert(
         label != null || semanticLabel != null || tooltip != null,
         'Icon-only buttons need a semanticLabel or tooltip',
       );

  final String? label;
  final IconData? icon;
  final VoidCallback? onPress;

  /// [KumoButtonVariant.ghost] (default) for buttons inside an addon. Any
  /// other variant, as a direct child of the group, attaches the button to
  /// the group's end.
  final KumoButtonVariant variant;

  /// Accessible name; defaults to [tooltip] for icon-only buttons.
  final String? semanticLabel;

  /// Tooltip shown below the button on hover, long press and keyboard focus.
  final String? tooltip;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final scope = _InputGroupScope.maybeOf(context);
    final size = scope?.size ?? KumoFieldSize.base;
    final isDisabled = disabled || (scope?.disabled ?? false) || onPress == null;
    final name = semanticLabel ?? tooltip ?? label!;
    final edge = _EdgeButtonScope.maybeOf(context);

    Widget button;
    if (edge != null) {
      button = _EdgeButton(
        label: label,
        icon: icon,
        variant: variant,
        size: size,
        last: edge.last,
        disabled: isDisabled,
        onPress: onPress,
        semanticLabel: semanticLabel ?? (label == null ? name : null),
      );
    } else if (label == null) {
      return FormsCompactButton(
        icon: icon!,
        semanticLabel: name,
        fieldSize: size,
        iconSize: _GroupTokens.of(size).iconSize,
        disabled: isDisabled,
        onPress: onPress,
        tooltip: tooltip,
      );
    } else {
      button = _CompactTextButton(
        label: label!,
        icon: icon,
        size: size,
        disabled: isDisabled,
        onPress: onPress,
        semanticLabel: semanticLabel,
      );
    }
    if (tooltip != null) button = KumoTooltip(content: tooltip!, side: KumoSide.bottom, child: button);
    return button;
  }
}

/// A ghost button with a label inside an addon.
class _CompactTextButton extends StatelessWidget {
  const _CompactTextButton({
    required this.label,
    required this.icon,
    required this.size,
    required this.disabled,
    required this.onPress,
    required this.semanticLabel,
  });

  final String label;
  final IconData? icon;
  final KumoFieldSize size;
  final bool disabled;
  final VoidCallback? onPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final edge = formsCompactButtonExtent(size);
    final r = BorderRadius.circular(KumoRadius.concentric(size.radius, (size.height - edge) / 2));
    return KumoPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      semanticLabel: semanticLabel,
      excludeChildSemantics: semanticLabel != null,
      borderRadius: r,
      focusRingColor: KumoColor.focus,
      focusRingWidth: 1.5,
      minTapTargetSize: 0,
      builder: (context, state) {
        final fg = state.active ? c.textDefault : c.textSubtle;
        Widget visual = Container(
          constraints: BoxConstraints(minHeight: edge, minWidth: kumo.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
          decoration: BoxDecoration(color: state.active ? c.tint : null, borderRadius: r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: KumoSpace.s1,
            children: [
              if (icon != null) KumoIcon(icon!, size: formsIconSize(size), dangerouslySetColor: fg),
              Text(
                label,
                maxLines: 1,
                style: kumo.text(size: size.textSize, weight: KumoTypography.medium).copyWith(color: fg),
              ),
            ],
          ),
        );
        if (disabled) visual = Opacity(opacity: 0.5, child: visual);
        return visual;
      },
    );
  }
}

/// A solid button attached to the end of the group, at the group's height.
/// Only its outer corners are rounded; the seam with the field is 1px.
class _EdgeButton extends StatelessWidget {
  const _EdgeButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.size,
    required this.last,
    required this.disabled,
    required this.onPress,
    required this.semanticLabel,
  });

  final String? label;
  final IconData? icon;
  final KumoButtonVariant variant;
  final KumoFieldSize size;
  final bool last;
  final bool disabled;
  final VoidCallback? onPress;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final dir = Directionality.of(context);
    final radius = last
        ? BorderRadiusDirectional.horizontal(end: Radius.circular(size.radius)).resolve(dir)
        : BorderRadius.zero;
    final emphasis = switch (variant) {
      KumoButtonVariant.primary => c.brand,
      KumoButtonVariant.destructive => c.danger,
      _ => null,
    };
    final small = size == KumoFieldSize.xs || size == KumoFieldSize.sm;

    final pressable = KumoPressable(
      onPress: disabled ? null : onPress,
      disabled: disabled,
      semanticLabel: semanticLabel,
      excludeChildSemantics: semanticLabel != null,
      borderRadius: radius,
      showFocusRing: false,
      // Scaling would open a gap at the seam with the field; the press shows
      // through the hover fill instead, as in a button group.
      scaleOnPress: false,
      minTapTargetSize: 0,
      builder: (context, state) {
        final hover = state.active && !disabled;
        Color? bg;
        Color fg;
        Color ring;
        if (disabled) {
          bg = c.overlay;
          fg = c.textInactive;
          ring = c.line;
        } else if (emphasis != null) {
          bg = hover ? Color.lerp(emphasis, const Color(0xFFFFFFFF), 0.12) : emphasis;
          fg = const Color(0xFFFFFFFF);
          ring = emphasis;
        } else {
          bg = variant == KumoButtonVariant.outline ? null : (hover ? c.tint : c.base);
          fg = variant == KumoButtonVariant.secondaryDestructive ? c.textDanger : c.textDefault;
          ring = c.line;
        }
        if (state.focused) ring = c.focus.withValues(alpha: 0.5);
        return Container(
          constraints: BoxConstraints(minHeight: size.height, minWidth: kumo.minTapTarget),
          padding: EdgeInsets.symmetric(horizontal: size.paddingX),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: KumoRing.border(ring, width: state.focused ? 1.5 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: small ? KumoSpace.s1 : KumoSpace.s1_5,
            children: [
              if (icon != null) KumoIcon(icon!, size: small ? 12 : 16, dangerouslySetColor: fg),
              if (label != null)
                Text(
                  label!,
                  maxLines: 1,
                  style: kumo.text(size: size.textSize, weight: KumoTypography.medium).copyWith(color: fg),
                ),
            ],
          ),
        );
      },
    );
    // Overlap the previous part by 1px so the two rings read as one line
    // (Kumo's `-ml-px`).
    return Transform.translate(offset: Offset(dir == TextDirection.ltr ? -1 : 1, 0), child: pressable);
  }
}
