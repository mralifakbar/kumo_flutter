import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled fonts so golden images show real Inter, JetBrains Mono
/// and Phosphor glyphs instead of the Ahem test font, and compares goldens
/// with a small tolerance.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('packages/kumo_flutter/Inter', ['Inter-Regular.ttf', 'Inter-Medium.ttf', 'Inter-SemiBold.ttf']);
  await load('packages/kumo_flutter/JetBrainsMono', ['JetBrainsMono-Regular.ttf', 'JetBrainsMono-Medium.ttf']);
  await load('packages/kumo_flutter/Phosphor', ['Phosphor.ttf']);
  await load('packages/kumo_flutter/PhosphorFill', ['Phosphor-Fill.ttf']);

  final current = goldenFileComparator;
  if (current is LocalFileComparator) {
    goldenFileComparator = _TolerantGoldenComparator(current.basedir.resolve('flutter_test_config.dart'));
  }
  await testMain();
}

/// Font anti-aliasing differs slightly between CPU architectures (x86 vs
/// arm64 Macs). Allow up to 0.1% of pixels to differ: far below any real
/// visual change, such as a color or spacing regression.
class _TolerantGoldenComparator extends LocalFileComparator {
  _TolerantGoldenComparator(super.testFile);

  static const double tolerance = 0.001;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
