// Motion pieces shared by the fields, pickers, dates and controls folders.
// Not exported from the package barrel.
import 'package:flutter/widgets.dart';

import '../../icons/kumo_icon.dart';
import '../../icons/kumo_icons.g.dart';
import '../../theme/generated/kumo_colors.g.dart';
import '../../theme/kumo_motion.dart';
import '../../theme/kumo_theme.dart';
import '../../theme/kumo_tokens.dart';
import '../../theme/kumo_typography.dart';
import '../../system/kumo_size_reveal.dart';

/// The line under a field: its error (danger icon and text, announced) or its
/// description. A message that appears grows the space it needs and fades in;
/// one that goes away fades and closes the space, so the content below slides
/// instead of jumping. Swapping description and error cross-fades. The text
/// keeps its size and is clipped while the space changes. Reduced motion
/// shows and hides it at once.
class FieldMessage extends StatefulWidget {
  const FieldMessage({
    super.key,
    this.description,
    this.error,
    this.controlDescribed = false,
    this.animateIn = false,
    this.gap = KumoSpace.s2,
    this.onHidden,
  });

  final String? description;
  final String? error;

  /// The control already announces [description] as its hint, so the text
  /// is hidden from screen readers.
  final bool controlDescribed;

  /// Animate a message that is already set when this mounts. False for the
  /// first build of a screen, true when the field gains a message later.
  final bool animateIn;

  /// Space above the message, part of what opens and closes.
  final double gap;

  /// Called once the space has closed after the message went away.
  final VoidCallback? onHidden;

  @override
  State<FieldMessage> createState() => _FieldMessageState();
}

class _FieldMessageState extends State<FieldMessage> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;

  /// The last message shown, kept while it animates away.
  ({String text, bool error})? _shown;

  ({String text, bool error})? get _current => widget.error != null
      ? (text: widget.error!, error: true)
      : widget.description != null
      ? (text: widget.description!, error: false)
      : null;

  @override
  void initState() {
    super.initState();
    _shown = _current;
    _reveal = AnimationController(
      vsync: this,
      duration: KumoDurations.quick,
      value: _shown != null && !widget.animateIn ? 1 : 0,
    )..addStatusListener(_onStatus);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion is read from the context, which initState cannot do.
    if (_started) return;
    _started = true;
    if (_shown != null && widget.animateIn) _show();
  }

  @override
  void didUpdateWidget(FieldMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _current;
    if (current != null) {
      _shown = current;
      _show();
    } else if (_shown != null) {
      _hide();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  bool get _reduce => KumoMotion.reduceMotion(context);

  void _show() {
    if (_reduce) {
      _reveal.value = 1;
    } else {
      _reveal.animateTo(1, curve: KumoCurves.enter);
    }
  }

  void _hide() {
    if (_reduce) {
      _reveal.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onStatus(AnimationStatus.dismissed));
    } else {
      _reveal.animateBack(0, curve: KumoCurves.exit);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || !mounted || _current != null) return;
    if (_shown != null) setState(() => _shown = null);
    widget.onHidden?.call();
  }

  Widget _message(BuildContext context, ({String text, bool error}) m) {
    final kumo = context.kumo;
    if (!m.error) {
      return ExcludeSemantics(
        excluding: widget.controlDescribed,
        child: Text(
          m.text,
          style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KumoSpace.s1_5,
        children: [
          const SizedBox(
            height: 21,
            child: Center(child: KumoIcon(KumoIcons.warningCircle, size: 14, color: KumoColor.textDanger)),
          ),
          Expanded(
            child: Text(
              m.text,
              style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textDanger, height: 21 / 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    if (shown == null) return const SizedBox.shrink();
    final message = KeyedSubtree(key: ValueKey(shown), child: _message(context, shown));
    // Under reduced motion the swap is instant. AnimatedSize is left out
    // rather than given a zero duration, which asserts when its child
    // changes size during layout.
    final Widget body = _reduce
        ? message
        : AnimatedSize(
            duration: KumoDurations.fast,
            curve: KumoCurves.standard,
            alignment: AlignmentDirectional.topStart,
            child: AnimatedSwitcher(
              duration: KumoDurations.fast,
              switchInCurve: KumoCurves.enter,
              switchOutCurve: KumoCurves.exit,
              layoutBuilder: (current, previous) => Stack(
                alignment: AlignmentDirectional.topStart,
                children: [
                  for (final p in previous) Positioned(top: 0, left: 0, right: 0, child: p),
                  ?current,
                ],
              ),
              child: message,
            ),
          );
    return KumoSizeReveal(
      sizeFactor: _reveal,
      child: FadeTransition(
        opacity: _reveal,
        // Announced from the first frame, not once it is visible.
        alwaysIncludeSemantics: true,
        child: Padding(
          padding: EdgeInsets.only(top: widget.gap),
          child: body,
        ),
      ),
    );
  }
}

/// Fades [child] in whenever [token] changes, for content that swaps in
/// place (masked and revealed text, loading and results), so the new content
/// arrives instead of flashing. Nothing runs on the first build or under
/// reduced motion.
class FadeInOnChange extends StatefulWidget {
  const FadeInOnChange({super.key, required this.token, required this.child, this.duration = KumoDurations.fast});

  final Object? token;
  final Widget child;
  final Duration duration;

  @override
  State<FadeInOnChange> createState() => _FadeInOnChangeState();
}

class _FadeInOnChangeState extends State<FadeInOnChange> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final CurvedAnimation _opacity;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: widget.duration, value: 1);
    _opacity = CurvedAnimation(parent: _fade, curve: KumoCurves.enter);
  }

  @override
  void didUpdateWidget(FadeInOnChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.token == oldWidget.token) return;
    if (KumoMotion.reduceMotion(context)) {
      _fade.value = 1;
    } else {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _opacity.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
