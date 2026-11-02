import 'package:flutter/widgets.dart';

/// Kumo's spacing follows Tailwind's 4px grid. Names match the Tailwind step
/// (`p-3` is [s3], 12px), so values read the same as in Kumo's React source.
abstract final class KumoSpace {
  static const double s0 = 0;
  static const double px = 1;
  static const double s0_5 = 2;
  static const double s1 = 4;
  static const double s1_5 = 6;
  static const double s2 = 8;
  static const double s2_5 = 10;
  static const double s3 = 12;
  static const double s3_5 = 14;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Any Tailwind step: `KumoSpace.step(7)` is 28px.
  static double step(double n) => n * 4;
}

/// Corner radii (Tailwind v4 scale). Kumo's controls and cards use [lg].
abstract final class KumoRadius {
  static const double none = 0;
  static const double xs = 2;

  /// `rounded-sm`: checkboxes, xs buttons.
  static const double sm = 4;

  /// `rounded-md`: small buttons, menu items.
  static const double md = 6;

  /// `rounded-lg`: buttons, inputs, cards, popovers.
  static const double lg = 8;

  /// `rounded-xl`: dialogs and large panels.
  static const double xl = 12;
  static const double xxl = 16;

  /// `rounded-full`: switches, avatars, circle buttons.
  static const double full = 9999;

  /// Radius for a surface nested [padding] inside one with radius [outer],
  /// so the two corners stay concentric (Kumo rule: outer = inner + padding).
  static double concentric(double outer, double padding) => (outer - padding).clamp(0, outer);
}

/// Elevation steps. Kumo keeps most surfaces flat with a 1px ring and saves
/// shadows for things that float: menus and popovers ([lg]), dialogs ([xl]).
enum KumoShadow {
  none([]),

  /// `shadow-xs`: resting controls (buttons, inputs, cards).
  xs([BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000))]),

  /// `shadow-sm`.
  sm([
    BoxShadow(offset: Offset(0, 1), blurRadius: 3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, spreadRadius: -1, color: Color(0x1A000000)),
  ]),

  /// `shadow-md`.
  md([
    BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -1, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 4, spreadRadius: -2, color: Color(0x1A000000)),
  ]),

  /// `shadow-lg`: popovers, menus, toasts.
  lg([
    BoxShadow(offset: Offset(0, 10), blurRadius: 15, spreadRadius: -3, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 4), blurRadius: 6, spreadRadius: -4, color: Color(0x1A000000)),
  ]),

  /// `shadow-xl`: dialogs.
  xl([
    BoxShadow(offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5, color: Color(0x1A000000)),
    BoxShadow(offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6, color: Color(0x1A000000)),
  ]);

  const KumoShadow(this.boxShadows);
  final List<BoxShadow> boxShadows;
}

/// Kumo draws borders as CSS rings: a stroke outside the box that takes no
/// layout space. These build the Flutter equivalent.
abstract final class KumoRing {
  /// A ring of [width] drawn outside the box edge.
  static Border border(Color color, {double width = 1}) =>
      Border.all(color: color, width: width, strokeAlign: BorderSide.strokeAlignOutside);

  /// A ring drawn inside the box edge (`ring-inset`).
  static Border inset(Color color, {double width = 1}) =>
      Border.all(color: color, width: width, strokeAlign: BorderSide.strokeAlignInside);
}

/// Width breakpoints (Tailwind defaults). Kumo is built for wide dashboards;
/// below [md] components switch to their touch layouts (sheets instead of
/// dialogs and menus, a drawer instead of a sidebar).
abstract final class KumoBreakpoints {
  static const double sm = 640;
  static const double md = 768;
  static const double lg = 1024;
  static const double xl = 1280;
  static const double xxl = 1536;
}

/// Coarse layout class for a width.
enum KumoWindowSize {
  /// Phones in portrait, under 640px.
  compact,

  /// Large phones in landscape and small tablets, 640 to 1023px.
  medium,

  /// Tablets in landscape, laptops and up, 1024px and wider.
  expanded;

  static KumoWindowSize of(double width) => width < KumoBreakpoints.sm
      ? compact
      : width < KumoBreakpoints.lg
          ? medium
          : expanded;
}

/// Window size helpers on [BuildContext].
extension KumoWindowSizeContext on BuildContext {
  /// The [KumoWindowSize] for the current window width.
  KumoWindowSize get kumoWindowSize => KumoWindowSize.of(MediaQuery.sizeOf(this).width);

  /// True below the `md` breakpoint (768px), where Kumo uses touch layouts.
  bool get kumoIsNarrow => MediaQuery.sizeOf(this).width < KumoBreakpoints.md;
}
