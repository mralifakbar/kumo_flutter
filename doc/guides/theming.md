# Theming

## Modes

`KumoThemeProvider(mode: ...)` takes `KumoThemeMode.system` (default, follows the platform), `.light` or `.dark`. Mode changes cross-fade every token over 300ms, instantly under reduced motion.

Force a mode for one subtree, the way Kumo's `data-mode` attribute does:

```dart
KumoTheme(
  data: KumoThemeData.dark(),
  child: const KumoText('Always dark'),
)
```

## Theme variants

Kumo ships two themes on top of the modes: `KumoThemeVariant.kumo` (default) and `KumoThemeVariant.fedramp`, which recolors the canvas, base and hairline tokens.

```dart
KumoThemeProvider(variant: KumoThemeVariant.fedramp, child: const SizedBox())
```

## Brand overrides

Every color is a `KumoColor` token. Override tokens with `copyWith` and pass full themes to the provider:

```dart
final light = KumoThemeData.light().copyWith(
  colors: KumoColorSchemes.light.copyWith({KumoColor.brand: const Color(0xFF0A66C2)}),
);
final dark = KumoThemeData.dark().copyWith(
  colors: KumoColorSchemes.dark.copyWith({KumoColor.brand: const Color(0xFF3B8FE0)}),
);
KumoThemeProvider(light: light, dark: dark, child: const SizedBox());
```

Check new pairings with `KumoColorUtils.contrastRatio`: 4.5 for text, 3 for control boundaries.

## Fonts

Inter (400, 500, 600) and JetBrains Mono (400, 500) are bundled under the SIL OFL. To use your own faces, declare them in your app's pubspec and pass their family names with `package: null`:

```dart
KumoThemeProvider(
  typography: const KumoTypography(sans: 'BrandSans', mono: 'BrandMono', package: null),
  child: const SizedBox(),
)
```

The OFL and Phosphor MIT license texts are registered with Flutter's license page automatically by the provider (`registerKumoLicenses`).

## Tap targets

Kumo's controls are dense (36px buttons). On touch platforms the provider pads hit areas to 44x44 without changing the visuals (`KumoTapTargetSize.padded`); with a mouse they match the visual (`shrinkWrap`). Override with `tapTargetSize:`.

## Material bridge

`kumoMaterialTheme(context.kumo)` builds a `ThemeData` from the Kumo theme (colors, text theme, no ink splashes). `KumoMaterialTheme` does the same as a widget for a subtree.

## Copy and locale

Built-in strings ("Close", "(optional)", month names, pagination text) come from `KumoStrings`. Provide your own with `KumoLocale`:

```dart
KumoLocale(
  strings: const KumoStrings(close: 'Tutup', cancel: 'Batal', optional: '(opsional)', firstDayOfWeek: DateTime.monday),
  child: const SizedBox(),
)
```
