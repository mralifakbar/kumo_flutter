import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

/// Phone size used by default; pass [kumoDesktopSize] for desktop layouts.
const Size kumoPhoneSize = Size(390, 844);
const Size kumoDesktopSize = Size(1280, 800);

/// Wraps [child] in everything a Kumo widget expects: media query, an app
/// (overlay, navigator, tap regions), directionality and a Kumo theme.
Widget kumoHarness(
  Widget child, {
  Brightness brightness = Brightness.light,
  KumoThemeVariant variant = KumoThemeVariant.kumo,
  KumoTapTargetSize tapTargetSize = KumoTapTargetSize.padded,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  double textScale = 1,
  bool center = true,
  Size size = kumoPhoneSize,
}) {
  final theme = brightness == Brightness.dark
      ? KumoThemeData.dark(variant: variant, tapTargetSize: tapTargetSize)
      : KumoThemeData.light(variant: variant, tapTargetSize: tapTargetSize);
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations, textScaler: TextScaler.linear(textScale), size: size),
    child: KumoTheme(
      data: theme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: kumoMaterialTheme(theme),
        builder: (context, app) => Directionality(textDirection: textDirection, child: app!),
        home: Builder(
          builder: (context) => ColoredBox(
            color: context.kumo.colors.canvas,
            child: DefaultTextStyle(
              style: context.kumo.text(),
              child: center ? Center(child: child) : child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Pumps [child] inside [kumoHarness] and settles animations.
Future<void> pumpKumo(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  KumoThemeVariant variant = KumoThemeVariant.kumo,
  KumoTapTargetSize tapTargetSize = KumoTapTargetSize.padded,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  double textScale = 1,
  bool center = true,
  Size size = kumoPhoneSize,
  bool settle = true,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    kumoHarness(
      child,
      brightness: brightness,
      variant: variant,
      tapTargetSize: tapTargetSize,
      textDirection: textDirection,
      disableAnimations: disableAnimations,
      textScale: textScale,
      center: center,
      size: size,
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// Renders [child] in light and dark side by side for golden comparison.
Widget goldenPair(Widget child, {double width = 360}) {
  Widget pane(Brightness b) => KumoTheme(
    data: b == Brightness.dark
        ? KumoThemeData.dark(tapTargetSize: KumoTapTargetSize.shrinkWrap)
        : KumoThemeData.light(tapTargetSize: KumoTapTargetSize.shrinkWrap),
    child: Builder(
      builder: (context) => Container(
        width: width,
        color: context.kumo.colors.canvas,
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(style: context.kumo.text(), child: child),
      ),
    ),
  );
  return MediaQuery(
    data: const MediaQueryData(size: Size(800, 1200)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [pane(Brightness.light), pane(Brightness.dark)],
        ),
      ),
    ),
  );
}
