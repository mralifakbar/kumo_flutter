import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the package fonts so screenshots and layout checks use real glyph
/// metrics instead of the Ahem test font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('../assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('packages/kumo_flutter/Inter', ['Inter-Regular.ttf', 'Inter-Medium.ttf', 'Inter-SemiBold.ttf']);
  await load('packages/kumo_flutter/JetBrainsMono', ['JetBrainsMono-Regular.ttf', 'JetBrainsMono-Medium.ttf']);
  await load('packages/kumo_flutter/Phosphor', ['Phosphor.ttf']);
  await load('packages/kumo_flutter/PhosphorFill', ['Phosphor-Fill.ttf']);
  await testMain();
}
