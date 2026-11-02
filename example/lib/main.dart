import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import 'gallery/categories.dart';
import 'gallery/category_page.dart';
import 'gallery/foundations/colors_page.dart';
import 'gallery/foundations/icons_page.dart';
import 'gallery/foundations/typography_page.dart';
import 'gallery/home_page.dart';
import 'gallery/settings_scope.dart';
import 'sample/console_app.dart';
import 'sample/sample_data.dart';
import 'sample/worker_page.dart';

void main() => runApp(const GalleryApp());

/// The kumo_flutter gallery: every component with live demos, plus the
/// foundations (colors, type, icons) and a sample console app.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key, this.home});

  /// Overrides the start page, for tests and screenshots.
  final Widget? home;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  KumoThemeMode _mode = KumoThemeMode.system;
  KumoThemeVariant _variant = KumoThemeVariant.kumo;

  @override
  Widget build(BuildContext context) {
    return GallerySettings(
      mode: _mode,
      variant: _variant,
      onModeChange: (m) => setState(() => _mode = m),
      onVariantChange: (v) => setState(() => _variant = v),
      child: KumoThemeProvider(
        mode: _mode,
        variant: _variant,
        child: Builder(
          builder: (context) => MaterialApp(
            title: 'kumo_flutter',
            debugShowCheckedModeBanner: false,
            theme: kumoMaterialTheme(context.kumo),
            builder: (context, child) => KumoToaster(child: child!),
            home: widget.home ?? _startPage(),
          ),
        ),
      ),
    );
  }
}

/// Start page chosen with `--dart-define=KUMO_GALLERY_START=<page>`, for
/// screenshots: `console`, `console:dns`, `colors`, `typography`, `icons`,
/// a category title (`Forms`) or `demo:<ClassName>`.
Widget _startPage() {
  const start = String.fromEnvironment('KUMO_GALLERY_START');
  if (start.isEmpty) return const HomePage();
  if (start == 'console') return const ConsoleApp(simulateLoading: false);
  if (start == 'console:dns') return const ConsoleApp(initialSection: ConsoleSection.dns, simulateLoading: false);
  if (start == 'console:worker') {
    final worker = sampleWorkers().firstWhere((w) => w.name == 'auth-proxy');
    return WorkerPage(worker: worker, onChanged: () {}, onDeleted: () {});
  }
  if (start == 'colors') return const ColorsPage();
  if (start == 'typography') return const TypographyPage();
  if (start == 'icons') return const IconsPage();
  for (final c in galleryCategories) {
    if (c.title == start) return CategoryPage(category: c);
    for (final d in c.demos) {
      if ('demo:${d.title}' == start) return DemoPage(demo: d);
    }
  }
  return const HomePage();
}
