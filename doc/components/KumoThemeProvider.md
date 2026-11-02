# KumoThemeProvider

The root of a Kumo app: resolves light or dark mode, applies a theme variant and typography, provides `context.kumo`, and cross-fades a mode change.

## Import

```dart
import 'package:kumo_flutter/kumo_flutter.dart';
```

## Usage

```dart
KumoThemeProvider(
  mode: KumoThemeMode.system,
  child: Builder(builder: (context) => MaterialApp(theme: kumoMaterialTheme(context.kumo), home: const SizedBox())),
)
```

## Parameters

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `mode` | `KumoThemeMode` | `system` | `system`, `light`, `dark` |
| `variant` | `KumoThemeVariant` | `kumo` | `kumo` or `fedramp` |
| `typography` | `KumoTypography` | Inter + JetBrains Mono | |
| `tapTargetSize` | `KumoTapTargetSize?` | platform | `padded` (44px hit areas) on touch, `shrinkWrap` with a mouse |
| `light`, `dark` | `KumoThemeData?` | | Full theme overrides |
| `animationDuration` | `Duration` | 300ms | Mode cross-fade |
| `child` | `Widget` | required | |

`KumoTheme(data:, child:)` forces a theme for a subtree. `KumoThemeData` exposes `colors`, `color(token)`, `text()`, `heading()`, `code()`, `shadow()`, `minTapTarget`, `isDark`, `copyWith`, `lerp`.

## Motion

Mode changes interpolate every color token over `animationDuration`, instantly under reduced motion.
