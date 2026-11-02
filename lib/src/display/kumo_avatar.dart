import 'package:flutter/widgets.dart';

import '../system/kumo_strings.dart';

import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_pressable.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// [KumoAvatar] sizes.
enum KumoAvatarSize {
  /// 24px, inline with 14px text and in dense tables.
  sm(24, KumoTextSize.xs, 12),

  /// 32px, list rows and menus.
  base(32, KumoTextSize.sm, 16),

  /// 40px, profile headers and cards.
  lg(40, KumoTextSize.base, 20);

  const KumoAvatarSize(this.dimension, this.textSize, this.iconSize);
  final double dimension;
  final KumoTextSize textSize;
  final double iconSize;
}

/// [KumoAvatar] shapes.
enum KumoAvatarShape {
  /// People.
  circle,

  /// Accounts, teams and organizations (`rounded-lg`).
  square,
}

/// Presence shown as a dot on a [KumoAvatar]. Set it only when presence is
/// real, live data; a stale "online" dot is worse than none.
enum KumoAvatarStatus {
  online(KumoColor.success, 'Online'),
  away(KumoColor.warning, 'Away'),
  busy(KumoColor.danger, 'Busy'),
  offline(KumoColor.interact, 'Offline');

  const KumoAvatarStatus(this.color, this.label);
  final KumoColor color;

  /// English name read by screen readers; override with [KumoAvatar.statusLabel].
  final String label;
}

/// A person's or account's picture, with their initials while it loads or
/// when there is none.
///
/// ```dart
/// const KumoAvatar(name: 'Ada Lovelace')
/// KumoAvatar(name: 'Ada Lovelace', image: NetworkImage(user.avatarUrl), status: KumoAvatarStatus.online)
/// const KumoAvatar(name: 'example.com', shape: KumoAvatarShape.square, size: KumoAvatarSize.lg)
/// ```
///
/// Only show a picture the person or account uploaded. Without one the
/// avatar shows initials from [name] (or a person glyph without a name);
/// it never generates a face. An image that fails to load falls back to the
/// initials too.
///
/// The avatar is read as [name] (plus the status, if any). Kumo has no avatar
/// component; this one uses Kumo's fill, line and text tokens.
class KumoAvatar extends StatelessWidget {
  const KumoAvatar({
    super.key,
    this.name,
    this.image,
    this.size = KumoAvatarSize.base,
    this.shape = KumoAvatarShape.circle,
    this.status,
    this.statusLabel,
    this.semanticLabel,
  });

  /// Full name or account name. Initials come from its first and last words.
  final String? name;

  /// The uploaded picture.
  final ImageProvider? image;
  final KumoAvatarSize size;
  final KumoAvatarShape shape;
  final KumoAvatarStatus? status;

  /// Replaces the English status name read by screen readers.
  final String? statusLabel;

  /// Replaces the spoken "name, status".
  final String? semanticLabel;

  /// Up to two initials from [name]: "Ada Lovelace" gives "AL",
  /// "image-resizer" gives "IR", "Ada" gives "A". An email address uses
  /// the part before the @.
  static String initialsOf(String name) {
    final base = name.contains('@') ? name.split('@').first : name;
    final words = base.trim().split(RegExp(r'[\s\-_.]+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
    return words.length == 1 ? first(words.first) : first(words.first) + first(words.last);
  }

  BorderRadius get _radius => BorderRadius.circular(shape == KumoAvatarShape.circle ? KumoRadius.full : KumoRadius.lg);

  String? get _spoken {
    if (semanticLabel != null) return semanticLabel;
    final parts = [?name, if (status != null) statusLabel ?? status!.label];
    return parts.isEmpty ? null : parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final d = size.dimension;
    final initials = name == null ? '' : initialsOf(name!);
    final Widget fallback = Center(
      child: initials.isEmpty
          ? KumoIcon(KumoIcons.user, size: size.iconSize, color: KumoColor.textSubtle)
          : Text(
              initials,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              // Initials scale with text up to a point, then stay inside the circle.
              textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
              style: kumo.text(size: size.textSize, weight: KumoTypography.medium, height: 1),
            ),
    );

    Widget face = fallback;
    if (image != null) {
      final fade = KumoMotion.duration(context, KumoDurations.quick);
      face = Image(
        image: image!,
        width: d,
        height: d,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, sync) {
          if (sync) return child;
          return Stack(
            fit: StackFit.expand,
            children: [
              fallback,
              AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: fade, curve: KumoCurves.enter, child: child),
            ],
          );
        },
        errorBuilder: (context, error, stack) => fallback,
      );
    }

    Widget avatar = Container(
      width: d,
      height: d,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: kumo.colors.fill, borderRadius: _radius),
      // An inset line ring keeps light photos from bleeding into the page.
      foregroundDecoration: BoxDecoration(borderRadius: _radius, border: KumoRing.inset(kumo.colors.line)),
      child: face,
    );

    if (status != null) {
      final dot = (d * 0.28).clamp(8.0, 12.0);
      avatar = SizedBox.square(
        dimension: d,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            PositionedDirectional(
              end: shape == KumoAvatarShape.circle ? 0 : -2,
              bottom: shape == KumoAvatarShape.circle ? 0 : -2,
              // A presence change (online to away) eases the dot's color.
              child: AnimatedContainer(
                duration: KumoMotion.duration(context, KumoDurations.quick),
                curve: KumoCurves.standard,
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: kumo.color(status!.color),
                  shape: BoxShape.circle,
                  // Cuts the dot out of the picture with the surface color.
                  border: KumoRing.border(kumo.colors.base, width: 2),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final spoken = _spoken;
    return Semantics(label: spoken, image: image != null, excludeSemantics: true, child: avatar);
  }
}

/// Overlapping avatars with a "+3" chip for the ones that do not fit.
///
/// ```dart
/// const KumoAvatarGroup(
///   max: 3,
///   avatars: [
///     KumoAvatar(name: 'Ada Lovelace'),
///     KumoAvatar(name: 'Grace Hopper'),
///     KumoAvatar(name: 'Alan Turing'),
///     KumoAvatar(name: 'Katherine Johnson'),
///   ],
/// )
/// ```
///
/// The group is read as one label ("Ada Lovelace, Grace Hopper, Alan Turing
/// and 1 more"). Each avatar gets a 2px ring in [ringColor] so the overlap
/// reads as a cut-out; set it to the surface the group sits on.
class KumoAvatarGroup extends StatelessWidget {
  const KumoAvatarGroup({
    super.key,
    required this.avatars,
    this.max,
    this.size = KumoAvatarSize.base,
    this.ringColor = KumoColor.base,
    this.onOverflowPress,
    this.semanticLabel,
  }) : assert(max == null || max > 0);

  /// The avatars, in order. Their own [KumoAvatar.size] is replaced by [size]
  /// so the stack lines up.
  final List<KumoAvatar> avatars;

  /// How many avatars to show before the overflow chip. Null shows all.
  final int? max;
  final KumoAvatarSize size;
  final KumoColor ringColor;

  /// Makes the overflow chip a button, for example to open the member list.
  final VoidCallback? onOverflowPress;

  /// Replaces the generated "names and N more" label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final visibleCount = max == null ? avatars.length : avatars.length.clamp(0, max!);
    final hidden = avatars.length - visibleCount;
    final d = size.dimension;
    final ring = KumoRing.border(kumo.color(ringColor), width: 2);

    Widget ringed(Widget child, KumoAvatarShape shape) => DecoratedBox(
      decoration: BoxDecoration(
        border: ring,
        borderRadius: BorderRadius.circular(shape == KumoAvatarShape.circle ? KumoRadius.full : KumoRadius.lg),
      ),
      child: child,
    );

    final items = <Widget>[
      for (final a in avatars.take(visibleCount))
        ringed(
          KumoAvatar(
            name: a.name,
            image: a.image,
            size: size,
            shape: a.shape,
            status: a.status,
            statusLabel: a.statusLabel,
            semanticLabel: a.semanticLabel,
          ),
          a.shape,
        ),
      if (hidden > 0) _OverflowChip(count: hidden, size: size, ring: ring, onPress: onOverflowPress),
    ];

    final names = [for (final a in avatars.take(visibleCount)) ?(a.semanticLabel ?? a.name)];
    final spoken =
        semanticLabel ?? [if (names.isNotEmpty) names.join(', '), if (hidden > 0) 'and $hidden more'].join(' ');

    // Each avatar after the first gives up a quarter of its width, so it
    // overlaps the one before it on the start side (RTL aware).
    final pressableChip = onOverflowPress != null && hidden > 0;
    final tap = pressableChip ? kumo.minTapTarget : 0.0;
    final extra = tap > d ? tap - d : 0.0;
    final height = d + extra;
    Widget slot(Widget child, {bool chip = false}) {
      // The pressable chip pads itself to the touch target; its slot grows
      // by half the padding on the end side so the hit area is reachable.
      final grow = chip ? extra : 0.0;
      return SizedBox(
        width: d * 0.75 + grow / 2,
        height: height,
        child: OverflowBox(
          alignment: AlignmentDirectional.centerEnd,
          minWidth: d + grow,
          maxWidth: d + grow,
          maxHeight: height,
          child: child,
        ),
      );
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          i == 0 ? items[i] : slot(items[i], chip: pressableChip && i == items.length - 1),
      ],
    );

    if (pressableChip) {
      // Each avatar reads its own name and the chip stays a separate button.
      return Semantics(container: true, explicitChildNodes: true, child: row);
    }
    return Semantics(label: spoken, excludeSemantics: true, child: row);
  }
}

class _OverflowChip extends StatelessWidget {
  const _OverflowChip({required this.count, required this.size, required this.ring, this.onPress});

  final int count;
  final KumoAvatarSize size;
  final Border ring;
  final VoidCallback? onPress;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final d = size.dimension;
    Widget chip(bool active) => Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? kumo.colors.fillHover : kumo.colors.fill,
        shape: BoxShape.circle,
        border: ring,
      ),
      child: Text(
        '+$count',
        maxLines: 1,
        softWrap: false,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
        style: kumo.text(size: size.textSize, weight: KumoTypography.medium, color: KumoColor.textSubtle, height: 1),
      ),
    );
    if (onPress == null) return chip(false);
    return KumoPressable(
      onPress: onPress,
      borderRadius: BorderRadius.circular(KumoRadius.full),
      semanticLabel: context.kumoStrings.showMore(count),
      excludeChildSemantics: true,
      builder: (context, state) => chip(state.active),
    );
  }
}
