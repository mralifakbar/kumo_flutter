import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icons.g.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import 'src/field_motion.dart';
import 'src/forms_internal.dart';

enum _Mode { masked, revealed, empty }

/// Kumo's `SensitiveInput`: a field for secrets (API tokens, passwords,
/// signing keys) that shows a mask until it is tapped, with a show/hide
/// toggle and a copy button.
///
/// * Masked: eight dots, whatever the length. Tapping the field, or pressing
///   Enter or Space on it, reveals the value and focuses it.
/// * Revealed: a normal text field with a hide button. Escape masks it again,
///   and so does moving focus out of the field.
/// * Empty: a normal text field; typing reveals what is typed.
///
/// With a mouse, a "Copy" tab appears on the field's top edge while it is
/// hovered or focused, as in Kumo. On touch screens, where there is no hover,
/// the copy button sits inside the field instead.
///
/// ```dart
/// KumoSensitiveInput(
///   label: 'API token',
///   value: token,
///   onValueChange: (v) => setState(() => token = v),
///   onCopy: () => showCopiedToast(),
/// )
/// ```
class KumoSensitiveInput extends StatefulWidget {
  const KumoSensitiveInput({
    super.key,
    this.value,
    this.onValueChange,
    this.controller,
    this.focusNode,
    this.onCopy,
    this.size = KumoFieldSize.base,
    this.label,
    this.labelTooltip,
    this.description,
    this.error,
    this.required = false,
    this.showOptional = false,
    this.placeholder,
    this.semanticLabel,
    this.disabled = false,
    this.readOnly = false,
    this.mono = false,
    this.revealText,
    this.hiddenAnnouncement,
    this.scrollPadding = formsScrollPadding,
  });

  /// The secret. Null leaves the field uncontrolled.
  final String? value;
  final ValueChanged<String>? onValueChange;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Called after the value is copied to the clipboard.
  final VoidCallback? onCopy;
  final KumoFieldSize size;

  /// Text above the field, and the name screen readers use for it.
  final String? label;
  final String? labelTooltip;
  final String? description;
  final String? error;
  final bool required;
  final bool showOptional;
  final String? placeholder;

  /// Accessible name when there is no [label]. Defaults to "Sensitive value".
  final String? semanticLabel;
  final bool disabled;

  /// Can be revealed and copied but not edited.
  final bool readOnly;

  /// Monospace text, which keeps similar characters in tokens apart.
  final bool mono;

  /// Shown over the mask on hover and focus, and read as the hint. Defaults
  /// to "Click to reveal" with a mouse and "Tap to reveal" on touch.
  final String? revealText;

  /// Announced when the value is masked again.
  final String? hiddenAnnouncement;

  /// Space kept around the field when it scrolls into view above the keyboard.
  final EdgeInsets scrollPadding;

  @override
  State<KumoSensitiveInput> createState() => _KumoSensitiveInputState();
}

class _KumoSensitiveInputState extends FormsTextState<KumoSensitiveInput> {
  late _Mode _mode;
  final _maskFocus = FocusNode(debugLabel: 'KumoSensitiveInput mask');
  final _link = LayerLink();
  final _tabController = OverlayPortalController();
  bool _focusWithin = false;
  bool _hovered = false;
  bool _tabHovered = false;
  bool _copied = false;
  bool _revealing = false;
  Timer? _copiedTimer;

  @override
  String? get controlledValue => widget.value;
  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  bool get _hasValue => controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _mode = _hasValue ? _Mode.masked : _Mode.empty;
    controller.addListener(_handleText);
    _tabController.show();
  }

  @override
  void didUpdateWidget(KumoSensitiveInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    previousController(oldWidget.controller)?.removeListener(_handleText);
    syncWidget(oldWidget.controller, oldWidget.focusNode);
    controller.addListener(_handleText);
    _handleText();
  }

  @override
  void dispose() {
    controller.removeListener(_handleText);
    _copiedTimer?.cancel();
    _maskFocus.dispose();
    super.dispose();
  }

  void _handleText() {
    final next = switch (_mode) {
      _Mode.empty when _hasValue => _focusWithin ? _Mode.revealed : _Mode.masked,
      _Mode.masked when !_hasValue => _Mode.empty,
      _ => _mode,
    };
    if (next != _mode && mounted) setState(() => _mode = next);
  }

  void _reveal() {
    if (widget.disabled || !_hasValue) return;
    _revealing = true;
    setState(() => _mode = _Mode.revealed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
      _revealing = false;
    });
  }

  void _mask({bool keepFocus = false}) {
    if (!_hasValue || _mode == _Mode.masked) return;
    setState(() => _mode = _Mode.masked);
    formsAnnounce(context, widget.hiddenAnnouncement ?? context.kumoStrings.valueHidden);
    if (keepFocus) {
      _revealing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maskFocus.requestFocus();
        _revealing = false;
      });
    }
  }

  void _handleFocusWithin(bool value) {
    if (value == _focusWithin) return;
    setState(() => _focusWithin = value);
    if (!value && !_revealing && _hasValue) _mask();
  }

  Future<void> _copy() async {
    final strings = context.kumoStrings;
    final text = controller.text;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      if (mounted) formsAnnounce(context, strings.copyFailed);
      return;
    }
    if (!mounted) return;
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    formsAnnounce(context, strings.copied);
    widget.onCopy?.call();
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final size = widget.size;
    final touch = kumo.minTapTarget > 0;
    final hasOverlay = Overlay.maybeOf(context) != null;
    final inlineCopy = touch || !hasOverlay;
    final name = widget.label ?? widget.semanticLabel ?? 'Sensitive value';
    final revealText = widget.revealText ?? (touch ? context.kumoStrings.tapToReveal : context.kumoStrings.clickToReveal);
    final iconSize = formsIconSize(size);
    final buttonExtent = iconSize + 4;
    final masked = _mode == _Mode.masked && _hasValue;
    final canCopy = _hasValue && !widget.disabled;

    final textStyle = widget.mono
        ? kumo.code(large: size == KumoFieldSize.base || size == KumoFieldSize.lg)
        : kumo.text(size: size.textSize);

    Widget content;
    if (masked) {
      final showHint = !widget.disabled && (_hovered || _focusWithin);
      content = KumoPressable(
        focusNode: _maskFocus,
        onPress: widget.disabled ? null : _reveal,
        disabled: widget.disabled,
        showFocusRing: false,
        scaleOnPress: false,
        minTapTargetSize: 0,
        semanticLabel: name,
        semanticHint: revealText,
        excludeChildSemantics: true,
        builder: (context, state) => Align(
          alignment: AlignmentDirectional.centerStart,
          // Both texts stay laid out so the field never changes size.
          child: Stack(
            children: [
              Visibility.maintain(
                visible: !showHint,
                child: Text('•' * 8, maxLines: 1, style: textStyle),
              ),
              Positioned.fill(
                child: Visibility.maintain(
                  visible: showHint,
                  child: Text(
                    revealText,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: kumo.text(size: size.textSize, color: KumoColor.textSubtle),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => _mask(keepFocus: true)},
        child: FormsFieldSemantics(
          label: name,
          description: widget.description,
          error: widget.error,
          tooltip: widget.labelTooltip,
          required: widget.required,
          child: KumoEditable(
            controller: controller,
            focusNode: focusNode,
            placeholder: widget.placeholder,
            size: size.textSize,
            mono: widget.mono,
            enabled: !widget.disabled,
            readOnly: widget.readOnly,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            onChanged: widget.onValueChange,
            scrollPadding: widget.scrollPadding,
          ),
        ),
      );
    }

    final trailing = <Widget>[
      if (canCopy && inlineCopy)
        FormsCompactButton(
          icon: _copied ? KumoIcons.check : KumoIcons.copy,
          semanticLabel: _copied ? strings.copied : strings.copy,
          fieldSize: size,
          extent: buttonExtent,
          iconSize: iconSize,
          onPress: _copy,
        ),
      if (_mode == _Mode.revealed && _hasValue && !widget.disabled)
        FormsCompactButton(
          icon: KumoIcons.eyeSlash,
          semanticLabel: strings.hide,
          fieldSize: size,
          extent: buttonExtent,
          iconSize: iconSize,
          onPress: _mask,
        ),
    ];

    Widget box = KumoFieldBox(
      size: size,
      focused: _focusWithin,
      error: widget.error != null,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      trailing: trailing.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, spacing: touch ? 0 : KumoSpace.s1, children: trailing),
      // Revealing and masking fade the new text in rather than flashing it.
      child: FadeInOnChange(token: masked, child: content),
    );

    box = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.disabled ? null : (masked ? _reveal : focusNode.requestFocus),
      child: MouseRegion(
        cursor: masked && !widget.disabled ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: box,
      ),
    );

    if (!inlineCopy) {
      final visible = canCopy && (_hovered || _tabHovered || _focusWithin);
      box = OverlayPortal(
        controller: _tabController,
        overlayChildBuilder: (context) => _CopyTab(
          link: _link,
          visible: visible,
          copied: _copied,
          onPress: _copy,
          onHover: (v) {
            if (v != _tabHovered) setState(() => _tabHovered = v);
          },
        ),
        child: CompositedTransformTarget(link: _link, child: box),
      );
    }

    box = FocusTraversalGroup(
      policy: WidgetOrderTraversalPolicy(),
      child: Focus(canRequestFocus: false, skipTraversal: true, onFocusChange: _handleFocusWithin, child: box),
    );

    return FormsFieldFrame(
      label: widget.label,
      labelTooltip: widget.labelTooltip,
      description: widget.description,
      error: widget.error,
      required: widget.required,
      showOptional: widget.showOptional,
      onLabelTap: masked ? _reveal : focusNode.requestFocus,
      child: box,
    );
  }
}

/// Kumo's brand "Copy" tab on the field's top edge, shown on hover and focus.
class _CopyTab extends StatelessWidget {
  const _CopyTab({
    required this.link,
    required this.visible,
    required this.copied,
    required this.onPress,
    required this.onHover,
  });

  final LayerLink link;
  final bool visible;
  final bool copied;
  final VoidCallback onPress;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final strings = context.kumoStrings;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    const radius = BorderRadius.vertical(top: Radius.circular(KumoRadius.md));
    final tab = KumoPressable(
      onPress: onPress,
      semanticLabel: copied ? strings.copied : strings.copy,
      excludeChildSemantics: true,
      borderRadius: radius,
      minTapTargetSize: 0,
      canRequestFocus: visible,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s0_5),
        decoration: BoxDecoration(
          color: state.active ? Color.lerp(kumo.colors.brand, const Color(0xFFFFFFFF), 0.15) : kumo.colors.brand,
          borderRadius: radius,
        ),
        child: Text(
          copied ? strings.copied : strings.copy,
          style: kumo.typography.body(size: KumoTextSize.xs, color: const Color(0xFFFFFFFF), height: 1.4),
        ),
      ),
    );
    // The overlay hands down tight constraints; loosen them so the follower
    // is only as big as the tab.
    return Align(
      alignment: Alignment.topLeft,
      child: CompositedTransformFollower(
        link: link,
        targetAnchor: rtl ? Alignment.topLeft : Alignment.topRight,
        followerAnchor: rtl ? Alignment.bottomLeft : Alignment.bottomRight,
        offset: Offset(rtl ? KumoSpace.s2 : -KumoSpace.s2, -1),
        child: IgnorePointer(
          ignoring: !visible,
          child: ExcludeSemantics(
            excluding: !visible,
            child: MouseRegion(
              onEnter: (_) => onHover(true),
              onExit: (_) => onHover(false),
              child: AnimatedOpacity(
                opacity: visible ? 1 : 0,
                duration: KumoMotion.duration(context, KumoDurations.fast),
                curve: KumoCurves.standard,
                child: tab,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
