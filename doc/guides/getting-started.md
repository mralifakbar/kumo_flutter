# Getting started

Install the package, wrap your app in `KumoThemeProvider`, and build with `Kumo*` widgets.

## Install

```sh
flutter pub add kumo_flutter
```

Flutter 3.38 or newer. Inter, JetBrains Mono and the Phosphor icon fonts are bundled; there is nothing else to set up.

## Wrap the app

`KumoThemeProvider` resolves light or dark mode, provides `context.kumo` and sets the default text style. Put it above `MaterialApp` and use `kumoMaterialTheme` so the Material widgets you still use (Scaffold, scroll bars, text selection) match Kumo.

```dart
import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return KumoThemeProvider(
      mode: KumoThemeMode.system,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: kumoMaterialTheme(context.kumo),
          home: const WorkersPage(),
        ),
      ),
    );
  }
}

class WorkersPage extends StatelessWidget {
  const WorkersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KumoSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s4,
            children: [
              const KumoText('Workers', variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 1),
              KumoLayerCard(
                child: Row(
                  children: [
                    const Expanded(child: KumoText('image-resizer')),
                    KumoButton(label: 'Deploy', variant: KumoButtonVariant.primary, onPress: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Read the theme

```dart
final kumo = context.kumo;
final surface = kumo.colors.base;            // a token as a field
final danger = kumo.color(KumoColor.danger); // a token by enum
final body = kumo.text();                    // 14px Inter, text-kumo-default
final muted = kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle);
```

## Next

- [Theming](theming.md): modes, the FedRAMP theme, brand overrides, custom fonts.
- [Tokens](tokens.md): colors, spacing, radii, shadows, breakpoints.
- [Motion](motion.md): springs, gestures, reduced motion.
- [Mobile](mobile.md): how a desktop-first system adapts to phones.
- [Accessibility](accessibility.md).
- [For AI agents](for-ai-agents.md): how to build screens with this package from an agent.
