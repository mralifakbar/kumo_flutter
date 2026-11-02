// Copies the kumo_flutter agent skill and reference docs into a project.
//
//   dart run kumo_flutter:install_skill [--target <dir>] [--agents]
//
// Installs two skills: kumo-flutter (components and tokens) and
// kumo-flutter-craft (design, accessibility, motion and copy standard).
//
// --target  skills directory to write into (default: .claude/skills)
// --agents  also append a pointer block to AGENTS.md in the current directory
import 'dart:io';
import 'dart:isolate';

Future<void> main(List<String> args) async {
  if (args.contains('-h') || args.contains('--help')) {
    stdout.writeln('usage: dart run kumo_flutter:install_skill [--target <dir>] [--agents]');
    return;
  }
  final targetIndex = args.indexOf('--target');
  final target = targetIndex >= 0 && targetIndex + 1 < args.length
      ? args[targetIndex + 1]
      : '.claude/skills';

  final libUri = await Isolate.resolvePackageUri(Uri.parse('package:kumo_flutter/kumo_flutter.dart'));
  if (libUri == null) {
    stderr.writeln('kumo_flutter is not a dependency of this project. Run `flutter pub add kumo_flutter` first.');
    exit(1);
  }
  final root = File.fromUri(libUri).parent.parent;

  final out = Directory('$target/kumo-flutter')..createSync(recursive: true);
  File('${root.path}/skills/kumo-flutter/SKILL.md').copySync('${out.path}/SKILL.md');
  _copyDir(Directory('${root.path}/doc'), Directory('${out.path}/references'));
  final craft = Directory('$target/kumo-flutter-craft')..createSync(recursive: true);
  File('${root.path}/skills/kumo-flutter-craft/SKILL.md').copySync('${craft.path}/SKILL.md');
  stdout.writeln('Installed skills to $target: kumo-flutter, kumo-flutter-craft');

  if (args.contains('--agents')) {
    final agents = File('AGENTS.md');
    const start = '<!-- kumo-flutter:start -->';
    const end = '<!-- kumo-flutter:end -->';
    final block = '$start\n## kumo_flutter\n'
        'This app uses kumo_flutter (Kumo design system for Flutter). Before UI work, read '
        '`${out.path}/SKILL.md` (components) and `${craft.path}/SKILL.md` (craft standard and '
        'delivery checklist) and follow both.\n$end\n';
    var text = agents.existsSync() ? agents.readAsStringSync() : '';
    final i = text.indexOf(start);
    final j = text.indexOf(end);
    text = i >= 0 && j > i ? text.replaceRange(i, j + end.length + 1, block) : '$text${text.isEmpty ? '' : '\n'}$block';
    agents.writeAsStringSync(text);
    stdout.writeln('Updated AGENTS.md');
  }
}

void _copyDir(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync(recursive: true)) {
    final relative = entity.path.substring(from.path.length + 1);
    if (entity is Directory) {
      Directory('${to.path}/$relative').createSync(recursive: true);
    } else if (entity is File && entity.path.endsWith('.md')) {
      File('${to.path}/$relative').parent.createSync(recursive: true);
      entity.copySync('${to.path}/$relative');
    }
  }
}
