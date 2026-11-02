import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records clipboard writes, or fails them when [fail] is true.
List<String> mockClipboard(WidgetTester tester, {bool fail = false}) {
  final copied = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      if (fail) throw PlatformException(code: 'denied', message: 'Clipboard blocked');
      copied.add((call.arguments as Map<Object?, Object?>)['text']! as String);
    }
    return null;
  });
  addTearDown(() => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return copied;
}

/// Records screen reader announcements.
List<String> mockAnnouncements(WidgetTester tester) {
  final messages = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (message) async {
    final map = message! as Map<Object?, Object?>;
    if (map['type'] == 'announce') {
      messages.add((map['data']! as Map<Object?, Object?>)['message']! as String);
    }
    return null;
  });
  addTearDown(() => messenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));
  return messages;
}

/// Lets the async clipboard write resolve and the feedback frame build.
Future<void> settleCopy(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
