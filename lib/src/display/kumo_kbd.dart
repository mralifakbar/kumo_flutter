import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Modifier keys a [KumoKbd] can show.
enum KumoKbdModifier {
  /// The platform's primary shortcut modifier: Command on macOS and iOS,
  /// Ctrl everywhere else. Use it for shortcuts like "mod K".
  mod,

  /// Ctrl on every platform (Control on Apple platforms).
  control,

  /// Option on Apple platforms, Alt elsewhere.
  alt,

  /// Shift.
  shift,

  /// Command on Apple platforms, the Windows or Super key elsewhere.
  meta,
}

/// A key name that maps to a glyph or a short label, used by [KumoKbd] for
/// keys that have no printable character.
abstract final class KumoKbdKeys {
  static const String enter = 'Enter';
  static const String escape = 'Esc';
  static const String tab = 'Tab';
  static const String space = 'Space';
  static const String backspace = 'Backspace';
  static const String delete = 'Delete';
  static const String arrowUp = 'ArrowUp';
  static const String arrowDown = 'ArrowDown';
  static const String arrowLeft = 'ArrowLeft';
  static const String arrowRight = 'ArrowRight';
}

/// Keyboard key chips: one key ("K") or a shortcut ("⌘ K", "Ctrl K").
///
/// Modifiers render the way the platform names them: Apple platforms get
/// the ⌘ ⌥ ⇧ ⌃ glyphs, other platforms get "Ctrl", "Alt", "Shift" and "Win".
/// [KumoKbdModifier.mod] picks Command or Ctrl so one shortcut reads right
/// everywhere. Screen readers hear the spelled-out names ("Command K").
///
/// ```dart
/// const KumoKbd('K', modifiers: [KumoKbdModifier.mod])
/// const KumoKbd(KumoKbdKeys.enter)
/// KumoKbd.fromActivator(const SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true))
/// ```
///
/// Kumo has no keyboard key component; the chip follows its tokens: 12px
/// medium text in `text-kumo-subtle` on `bg-kumo-base`, with a `ring-kumo-line`
/// outline and `shadow-xs`.
class KumoKbd extends StatelessWidget {
  const KumoKbd(this.keyLabel, {super.key, this.modifiers = const [], this.platform, this.semanticLabel});

  /// Builds the chips for a Flutter shortcut, so the hint shown in the UI
  /// stays in step with the binding that handles it.
  factory KumoKbd.fromActivator(SingleActivator activator, {Key? key, TargetPlatform? platform}) {
    final trigger = activator.trigger;
    final name = switch (trigger) {
      LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter => KumoKbdKeys.enter,
      LogicalKeyboardKey.escape => KumoKbdKeys.escape,
      LogicalKeyboardKey.tab => KumoKbdKeys.tab,
      LogicalKeyboardKey.space => KumoKbdKeys.space,
      LogicalKeyboardKey.backspace => KumoKbdKeys.backspace,
      LogicalKeyboardKey.delete => KumoKbdKeys.delete,
      LogicalKeyboardKey.arrowUp => KumoKbdKeys.arrowUp,
      LogicalKeyboardKey.arrowDown => KumoKbdKeys.arrowDown,
      LogicalKeyboardKey.arrowLeft => KumoKbdKeys.arrowLeft,
      LogicalKeyboardKey.arrowRight => KumoKbdKeys.arrowRight,
      _ => trigger.keyLabel.length == 1 ? trigger.keyLabel.toUpperCase() : trigger.keyLabel,
    };
    return KumoKbd(
      name,
      key: key,
      platform: platform,
      modifiers: [
        if (activator.control) KumoKbdModifier.control,
        if (activator.alt) KumoKbdModifier.alt,
        if (activator.shift) KumoKbdModifier.shift,
        if (activator.meta) KumoKbdModifier.meta,
      ],
    );
  }

  /// The main key: a character ("K", "/") or one of [KumoKbdKeys].
  final String keyLabel;

  /// Held keys, shown before [keyLabel]. Apple platforms order them
  /// ⌃ ⌥ ⇧ ⌘ (the macOS menu order) whatever order is passed.
  final List<KumoKbdModifier> modifiers;

  /// Which platform's names to use. Defaults to [defaultTargetPlatform].
  final TargetPlatform? platform;

  /// Replaces the spelled-out names read by screen readers.
  final String? semanticLabel;

  static bool _isApple(TargetPlatform p) => p == TargetPlatform.macOS || p == TargetPlatform.iOS;

  /// Spoken name of [modifier] on [platform], such as "Command" or "Ctrl".
  static String modifierName(KumoKbdModifier modifier, TargetPlatform platform) {
    final apple = _isApple(platform);
    return switch (modifier) {
      KumoKbdModifier.mod => apple ? 'Command' : 'Ctrl',
      KumoKbdModifier.control => apple ? 'Control' : 'Ctrl',
      KumoKbdModifier.alt => apple ? 'Option' : 'Alt',
      KumoKbdModifier.shift => 'Shift',
      KumoKbdModifier.meta => apple ? 'Command' : (platform == TargetPlatform.windows ? 'Win' : 'Super'),
    };
  }

  static String _spokenKey(String key) => switch (key) {
    KumoKbdKeys.arrowUp => 'Up arrow',
    KumoKbdKeys.arrowDown => 'Down arrow',
    KumoKbdKeys.arrowLeft => 'Left arrow',
    KumoKbdKeys.arrowRight => 'Right arrow',
    KumoKbdKeys.escape => 'Escape',
    _ => key,
  };

  @override
  Widget build(BuildContext context) {
    final p = platform ?? defaultTargetPlatform;
    final apple = _isApple(p);
    final ordered = [
      ...{...modifiers},
    ];
    if (apple) {
      const order = [
        KumoKbdModifier.control,
        KumoKbdModifier.alt,
        KumoKbdModifier.shift,
        KumoKbdModifier.mod,
        KumoKbdModifier.meta,
      ];
      ordered.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      // mod and meta are both Command on Apple platforms.
      if (ordered.contains(KumoKbdModifier.mod) && ordered.contains(KumoKbdModifier.meta)) {
        ordered.remove(KumoKbdModifier.meta);
      }
    }

    final chips = <Widget>[
      for (final m in ordered) _KbdChip(child: _modifierContent(context, m, apple, p)),
      _KbdChip(child: _keyContent(context, keyLabel, apple)),
    ];
    final spoken = semanticLabel ?? [for (final m in ordered) modifierName(m, p), _spokenKey(keyLabel)].join(' ');
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Wrap(
        spacing: KumoSpace.s1,
        runSpacing: KumoSpace.s1,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
    );
  }

  Widget _modifierContent(BuildContext context, KumoKbdModifier m, bool apple, TargetPlatform p) {
    if (!apple) return _label(context, modifierName(m, p));
    // Phosphor glyphs instead of the Unicode symbols, which many fallback
    // fonts render at mismatched sizes.
    return _glyph(switch (m) {
      KumoKbdModifier.mod || KumoKbdModifier.meta => KumoIcons.command,
      KumoKbdModifier.control => KumoIcons.control,
      KumoKbdModifier.alt => KumoIcons.option,
      KumoKbdModifier.shift => KumoIcons.arrowFatUp,
    });
  }

  Widget _keyContent(BuildContext context, String key, bool apple) => switch (key) {
    KumoKbdKeys.arrowUp => _glyph(KumoIcons.arrowUp),
    KumoKbdKeys.arrowDown => _glyph(KumoIcons.arrowDown),
    KumoKbdKeys.arrowLeft => _glyph(KumoIcons.arrowLeft),
    KumoKbdKeys.arrowRight => _glyph(KumoIcons.arrowRight),
    KumoKbdKeys.enter when apple => _glyph(KumoIcons.keyReturn),
    KumoKbdKeys.backspace when apple => _glyph(KumoIcons.backspace),
    _ => _label(context, key),
  };

  Widget _glyph(IconData icon) => KumoIcon(icon, size: 12, color: KumoColor.textSubtle);

  Widget _label(BuildContext context, String text) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    style: context.kumo.text(
      size: KumoTextSize.xs,
      weight: KumoTypography.medium,
      color: KumoColor.textSubtle,
      height: 4 / 3,
    ),
  );
}

class _KbdChip extends StatelessWidget {
  const _KbdChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    // 20px tall at 1x text; minimum sizes so 2x text grows the chip instead of clipping.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kumo.colors.base,
          borderRadius: BorderRadius.circular(KumoRadius.sm),
          border: KumoRing.border(kumo.colors.line),
          boxShadow: KumoShadow.xs.boxShadows,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s1, vertical: KumoSpace.s0_5),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
