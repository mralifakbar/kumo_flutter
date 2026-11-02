import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';
import '../typography/kumo_text.dart';

/// [KumoEmpty] sizes, from Kumo's `size` prop.
enum KumoEmptySize {
  /// `px-6 py-8 gap-4`, for cards and side panels. 32px icon.
  sm(KumoSpace.s6, KumoSpace.s8, KumoSpace.s4, 32),

  /// `px-10 py-16 gap-6`, the default. 48px icon.
  base(KumoSpace.s10, KumoSpace.s16, KumoSpace.s6, 48),

  /// `px-12 py-20 gap-8`, for a page with nothing else on it. 64px icon.
  lg(KumoSpace.s12, 80, KumoSpace.s8, 64);

  const KumoEmptySize(this.paddingX, this.paddingY, this.gap, this.iconSize);
  final double paddingX;
  final double paddingY;
  final double gap;

  /// Size Kumo's demos give the icon at this size.
  final double iconSize;
}

/// Kumo's `Empty`: what a list, table or page shows when it has nothing to
/// show.
///
/// ```dart
/// KumoEmpty(
///   icon: KumoIcons.database,
///   title: 'No D1 databases yet',
///   description: 'Databases you create in this account appear here. Create one to store data for your Workers.',
///   contents: KumoButton(label: 'Create database', variant: KumoButtonVariant.primary, onPress: () {}),
/// )
/// ```
///
/// Write the copy for the person looking at it: the [title] names what is
/// missing or why ("No results for \"api\"", "No connection to the API"),
/// and the [description] says the next step ("Clear the filter to see all
/// 24 records"). Put that step in [contents] as a button with a specific
/// label ("Create database", "Retry"), never "Get started".
///
/// A [commandLine] adds a copyable shell command, for empty states whose
/// next step happens in a terminal.
class KumoEmpty extends StatefulWidget {
  const KumoEmpty({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.iconWidget,
    this.iconColor = KumoColor.textInactive,
    this.commandLine,
    this.copyLabel,
    this.contents,
    this.size = KumoEmptySize.base,
  });

  /// Heading. With a [description] it is a 20px heading; alone it is 14px
  /// subtle text, Kumo's minimal empty state. Both are level-2 headings for
  /// screen readers.
  final String title;
  final String? description;

  /// Decorative icon above the title, drawn at [KumoEmptySize.iconSize].
  final IconData? icon;

  /// Custom content in place of [icon] (an illustration the app owns).
  final Widget? iconWidget;

  /// Color of [icon]. Kumo's demos use `text-kumo-inactive`.
  final KumoColor iconColor;

  /// Shell command shown with a "$" prompt and a copy button.
  final String? commandLine;

  /// Accessible name of the command's copy button. Defaults to
  /// [KumoStrings.copyToClipboard].
  final String? copyLabel;

  /// Actions under the description, usually one or two [KumoButton]s in a
  /// [Wrap] so they stack on narrow screens.
  final Widget? contents;
  final KumoEmptySize size;

  @override
  State<KumoEmpty> createState() => _KumoEmptyState();
}

class _KumoEmptyState extends State<KumoEmpty> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final strings = context.kumoStrings;
    final view = View.of(context);
    final direction = Directionality.of(context);
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.commandLine!));
    } on PlatformException {
      ok = false;
    }
    if (!mounted) return;
    unawaited(SemanticsService.sendAnnouncement(view, ok ? strings.copied : strings.copyFailed, direction));
    if (!ok) return;
    setState(() => _copied = true);
    _reset?.cancel();
    // Kumo's useCopyFeedback(1000).
    _reset = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final size = widget.size;
    final hasDescription = widget.description != null;

    final children = <Widget>[
      if (widget.iconWidget != null)
        widget.iconWidget!
      else if (widget.icon != null)
        KumoIcon(widget.icon!, size: size.iconSize, color: widget.iconColor),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          hasDescription
              ? KumoText(
                  widget.title,
                  variant: KumoTextVariant.heading,
                  size: KumoTextSize.lg,
                  textAlign: TextAlign.center,
                  headingLevel: 2,
                )
              : KumoText(
                  widget.title,
                  variant: KumoTextVariant.secondary,
                  textAlign: TextAlign.center,
                  headingLevel: 2,
                ),
          if (hasDescription) ...[
            const SizedBox(height: KumoSpace.s2_5),
            ConstrainedBox(
              // `max-w-140`
              constraints: const BoxConstraints(maxWidth: 560),
              child: KumoText(widget.description!, variant: KumoTextVariant.secondary, textAlign: TextAlign.center),
            ),
          ],
        ],
      ),
      if (widget.commandLine != null)
        _CommandLine(
          command: widget.commandLine!,
          copied: _copied,
          onCopy: _copy,
          label: widget.copyLabel ?? context.kumoStrings.copyToClipboard,
        ),
      ?widget.contents,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: size.paddingX, vertical: size.paddingY),
      decoration: BoxDecoration(
        color: kumo.colors.control,
        borderRadius: BorderRadius.circular(KumoRadius.xl),
        border: Border.all(color: kumo.colors.fill),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: size.gap), children[i]],
        ],
      ),
    );
  }
}

class _CommandLine extends StatelessWidget {
  const _CommandLine({required this.command, required this.copied, required this.onCopy, required this.label});

  final String command;
  final bool copied;
  final VoidCallback onCopy;
  final String label;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final mono = kumo.code(large: true);
    return LayoutBuilder(
      builder: (context, constraints) => ConstrainedBox(
        // `h-10 max-w-8/10`, with a minimum height so 2x text grows the box.
        constraints: BoxConstraints(
          minHeight: 40,
          maxWidth: constraints.hasBoundedWidth ? constraints.maxWidth * 0.8 : double.infinity,
        ),
        child: Container(
          padding: const EdgeInsetsDirectional.only(start: KumoSpace.s3, end: KumoSpace.s2),
          decoration: BoxDecoration(
            color: kumo.colors.overlay,
            borderRadius: BorderRadius.circular(KumoRadius.lg),
            // Kumo draws a white 1px inner border inside the line ring. On a
            // dark overlay a white edge reads as a bright outline, so dark
            // mode keeps only the ring.
            border: kumo.isDark ? KumoRing.border(kumo.colors.line) : Border.all(color: const Color(0xFFFFFFFF)),
            boxShadow: KumoShadow.xs.boxShadows,
          ),
          foregroundDecoration: kumo.isDark
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(KumoRadius.lg + 1),
                  border: KumoRing.border(kumo.colors.line),
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Text(r'$', style: mono.copyWith(color: kumo.colors.textSubtle)),
              ),
              const SizedBox(width: KumoSpace.s2),
              Flexible(
                child: _FadingScroll(child: Text(command, style: mono, softWrap: false, maxLines: 1)),
              ),
              const SizedBox(width: KumoSpace.s2),
              KumoButton(
                size: KumoButtonSize.sm,
                variant: KumoButtonVariant.ghost,
                shape: KumoButtonShape.square,
                semanticLabel: label,
                onPress: onCopy,
                // Keyed, so the button cross-fades copy and check: the check
                // lands with Kumo's bounce-in, and the copy icon fades back.
                iconWidget: copied
                    ? const _BounceIn(
                        key: ValueKey('copied'),
                        child: KumoIcon(KumoIcons.check, color: KumoColor.textSuccess),
                      )
                    : const KumoIcon(KumoIcons.copy, key: ValueKey('copy'), color: KumoColor.textSubtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scroll that fades the edge where more text is hidden, so a
/// clipped command reads as scrollable.
class _FadingScroll extends StatefulWidget {
  const _FadingScroll({required this.child});

  final Widget child;

  @override
  State<_FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<_FadingScroll> {
  bool _fadeStart = false;
  bool _fadeEnd = false;

  bool _onMetrics(ScrollMetrics m) {
    final start = m.pixels > m.minScrollExtent + 0.5;
    final end = m.pixels < m.maxScrollExtent - 0.5;
    if (start != _fadeStart || end != _fadeEnd) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Scroll offsets run from the start edge, so swap the sides in RTL.
    final left = rtl ? _fadeEnd : _fadeStart;
    final right = rtl ? _fadeStart : _fadeEnd;
    Widget scroll = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _onMetrics(n.metrics),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: widget.child),
      ),
    );
    if (left || right) {
      scroll = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final edge = rect.width <= 0 ? 0.0 : (KumoSpace.s6 / rect.width).clamp(0.0, 0.5);
          return LinearGradient(
            colors: [
              Color(left ? 0x00000000 : 0xFF000000),
              const Color(0xFF000000),
              const Color(0xFF000000),
              Color(right ? 0x00000000 : 0xFF000000),
            ],
            stops: [0, edge, 1 - edge, 1],
          ).createShader(rect);
        },
        child: scroll,
      );
    }
    return scroll;
  }
}

/// Kumo's `animate-bounce-in`: scale 0.6 to 1.2 to 1 with a fade, 400ms
/// ease-out. Plays once when the check mark appears; skipped under reduced motion.
class _BounceIn extends StatelessWidget {
  const _BounceIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (KumoMotion.reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: KumoCurves.enter,
      builder: (context, t, child) {
        final scale = t < 0.5 ? 0.6 + 1.2 * t : 1.2 - 0.4 * (t - 0.5);
        return Opacity(
          opacity: (t * 2).clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
