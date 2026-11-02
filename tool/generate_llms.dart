// Regenerates llms.txt (index) and llms-full.txt (every doc page in one file).
//
//   dart run tool/generate_llms.dart
import 'dart:io';

void main() {
  final guides = _pages('doc/guides');
  final components = _pages('doc/components');

  final index = StringBuffer()
    ..writeln('# kumo_flutter')
    ..writeln()
    ..writeln('> Unofficial Flutter port of Kumo, Cloudflare\'s design system: OKLCH-accurate light and dark '
        'themes, 1,530 Phosphor icons, and accessible, spring-driven components. Not affiliated with Cloudflare.')
    ..writeln()
    ..writeln('Import `package:kumo_flutter/kumo_flutter.dart`, wrap the app in `KumoThemeProvider`, read the theme '
        'with `context.kumo`. Widgets are prefixed `Kumo`; props follow Kumo names; colors are `KumoColor` tokens; '
        'spacing follows the Tailwind 4px grid (`KumoSpace.s3` is 12px); content text is 14px.')
    ..writeln()
    ..writeln('## Guides')
    ..writeln();
  for (final p in guides) {
    index.writeln('- [${_title(p)}](${p.path}): ${_summary(p)}');
  }
  index
    ..writeln()
    ..writeln('## Components')
    ..writeln();
  for (final p in components) {
    index.writeln('- [${_title(p)}](${p.path}): ${_summary(p)}');
  }
  File('llms.txt').writeAsStringSync(index.toString());

  final full = StringBuffer()..writeln(index.toString());
  for (final p in [...guides, ...components]) {
    full
      ..writeln()
      ..writeln('---')
      ..writeln('source: ${p.path}')
      ..writeln('---')
      ..writeln()
      ..writeln(p.readAsStringSync().trim());
  }
  File('llms-full.txt').writeAsStringSync(full.toString());
  stdout.writeln('llms.txt: ${guides.length} guides, ${components.length} components');
}

List<File> _pages(String dir) {
  final d = Directory(dir);
  if (!d.existsSync()) return [];
  return d.listSync().whereType<File>().where((f) => f.path.endsWith('.md')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _title(File f) {
  final line = f.readAsLinesSync().firstWhere((l) => l.startsWith('# '), orElse: () => f.path);
  return line.replaceFirst('# ', '').trim();
}

String _summary(File f) {
  final lines = f.readAsLinesSync();
  final start = lines.indexWhere((l) => l.startsWith('# '));
  var inFence = false;
  for (final l in lines.skip(start + 1)) {
    final t = l.trim();
    if (t.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence || t.isEmpty || t.startsWith('Kumo reference') || t.startsWith('#')) continue;
    return t;
  }
  return '';
}
