import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _token = 'cf_live_8f2b91c4d7e6';
const _dots = '••••••••';

class _Secret extends StatefulWidget {
  const _Secret({this.initial = _token, this.onCopy, this.readOnly = false});

  final String initial;
  final VoidCallback? onCopy;
  final bool readOnly;

  @override
  State<_Secret> createState() => _SecretState();
}

class _SecretState extends State<_Secret> {
  late String value = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KumoSensitiveInput(
          label: 'API token',
          value: value,
          readOnly: widget.readOnly,
          onCopy: widget.onCopy,
          onValueChange: (v) => setState(() => value = v),
        ),
        KumoButton(label: 'Clear', onPress: () => setState(() => value = '')),
        KumoButton(label: 'Rotate', onPress: () => setState(() => value = 'cf_live_rotated')),
      ],
    ),
  );
}

void _mockClipboard(WidgetTester tester, List<String> copied) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      copied.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
}

void main() {
  testWidgets('renders every size and state in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (final s in KumoFieldSize.values) KumoSensitiveInput(size: s, label: s.name, value: _token),
              const KumoSensitiveInput(label: 'Key', value: 'bad', error: 'This key is not valid'),
              const KumoSensitiveInput(label: 'Key', value: _token, disabled: true),
              const KumoSensitiveInput(label: 'Key', value: _token, readOnly: true),
              const KumoSensitiveInput(label: 'Key', placeholder: 'Paste a token'),
            ],
          ),
        ),
        brightness: b,
        center: false,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('starts masked and never renders the secret', (tester) async {
    await pumpKumo(tester, const _Secret());
    expect(find.text(_dots), findsOneWidget);
    expect(find.text(_token), findsNothing);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('tap reveals and focuses; hide button masks again', (tester) async {
    await pumpKumo(tester, const _Secret());
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pumpAndSettle();
    expect(find.text(_token), findsOneWidget);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Hide'));
    await tester.pumpAndSettle();
    expect(find.text(_dots), findsOneWidget);
    expect(find.text(_token), findsNothing);
  });

  testWidgets('moving focus away masks the value', (tester) async {
    await pumpKumo(tester, const _Secret());
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pumpAndSettle();
    expect(find.text(_token), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text(_dots), findsOneWidget);
  });

  testWidgets('keyboard: Enter reveals, Escape masks and keeps focus on the field', (tester) async {
    await pumpKumo(tester, const _Secret(), tapTargetSize: KumoTapTargetSize.shrinkWrap, size: kumoDesktopSize);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text(_token), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text(_dots), findsOneWidget);
    expect(tester.widget<KumoFieldBox>(find.byType(KumoFieldBox)).focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text(_token), findsOneWidget);
  });

  testWidgets('editing reports the value; clearing switches to the empty state', (tester) async {
    await pumpKumo(tester, const _Secret());
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'cf_test_123');
    await tester.pump();
    expect(find.text('cf_test_123'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text(_dots), findsNothing);
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('typing into an empty field shows what is typed', (tester) async {
    await pumpKumo(tester, const _Secret(initial: ''));
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();
    expect(find.text('abc'), findsOneWidget);
    expect(find.text(_dots), findsNothing);
  });

  testWidgets('a new value from outside is masked', (tester) async {
    await pumpKumo(tester, const _Secret(initial: ''));
    await tester.tap(find.text('Rotate'));
    await tester.pumpAndSettle();
    expect(find.text(_dots), findsOneWidget);
    expect(find.text('cf_live_rotated'), findsNothing);
  });

  testWidgets('touch: inline copy button copies the value and shows Copied for 2s', (tester) async {
    final copied = <String>[];
    var onCopy = 0;
    _mockClipboard(tester, copied);
    await pumpKumo(tester, _Secret(onCopy: () => onCopy++));
    await tester.tap(find.bySemanticsLabel('Copy'));
    await tester.pump();
    expect(copied, [_token]);
    expect(onCopy, 1);
    expect(find.bySemanticsLabel('Copied'), findsOneWidget);
    // Copying does not reveal the secret.
    expect(find.text(_dots), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.bySemanticsLabel('Copy'), findsOneWidget);
  });

  testWidgets('mouse: the Copy tab appears on hover and copies', (tester) async {
    final copied = <String>[];
    _mockClipboard(tester, copied);
    await pumpKumo(tester, const _Secret(), tapTargetSize: KumoTapTargetSize.shrinkWrap, size: kumoDesktopSize);
    final tab = find.text('Copy');
    double opacity() =>
        tester.widget<AnimatedOpacity>(find.ancestor(of: tab, matching: find.byType(AnimatedOpacity))).opacity;
    expect(opacity(), 0);
    expect(find.text('Click to reveal'), findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(KumoFieldBox)));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    // The tab sits on the top edge, above the field.
    expect(tester.getRect(tab).bottom, lessThanOrEqualTo(tester.getRect(find.byType(KumoFieldBox)).top));

    await mouse.moveTo(tester.getCenter(tab));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    await tester.tap(tab);
    await tester.pump();
    expect(copied, [_token]);
    expect(find.text('Copied'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(opacity(), 0);
  });

  testWidgets('reduced motion shows the Copy tab without a fade', (tester) async {
    await pumpKumo(
      tester,
      const _Secret(),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
      size: kumoDesktopSize,
      disableAnimations: true,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byType(KumoFieldBox)));
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    final opacity = tester.renderObject<RenderAnimatedOpacity>(
      find.ancestor(of: find.text('Copy'), matching: find.byType(AnimatedOpacity)),
    );
    expect(opacity.opacity.value, 1);
  });

  testWidgets('disabled cannot reveal or copy', (tester) async {
    await pumpKumo(
      tester,
      const SizedBox(
        width: 300,
        child: KumoSensitiveInput(label: 'Key', value: _token, disabled: true),
      ),
    );
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pumpAndSettle();
    expect(find.text(_token), findsNothing);
    expect(find.bySemanticsLabel('Copy'), findsNothing);
  });

  testWidgets('read-only reveals without editing', (tester) async {
    await pumpKumo(tester, const _Secret(readOnly: true));
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pumpAndSettle();
    expect(find.text(_token), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).readOnly, isTrue);
  });

  testWidgets('semantics: masked field is a button named by the label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const _Secret());
    expect(
      tester.getSemantics(find.text(_dots)),
      matchesSemantics(
        label: 'API token',
        hint: 'Tap to reveal',
        isButton: true,
        hasTapAction: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('secret fields turn off suggestions and autocorrect', (tester) async {
    await pumpKumo(tester, const _Secret(initial: ''));
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enableSuggestions, isFalse);
    expect(field.autocorrect, isFalse);
    expect(field.keyboardType, TextInputType.visiblePassword);
  });

  testWidgets('text scale 2.0 at 390px does not overflow', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoSensitiveInput(
          label: 'Account API token',
          description: 'Store it in a secret manager; it is shown once.',
          value: _token,
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('revealing fades the value in; reduced motion swaps at once', (tester) async {
    double fade() => tester
        .widget<FadeTransition>(
          find.ancestor(of: find.byType(EditableText), matching: find.byType(FadeTransition)).first,
        )
        .opacity
        .value;
    await pumpKumo(tester, const _Secret());
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(fade(), inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(fade(), 1);

    await pumpKumo(tester, const _Secret(), disableAnimations: true);
    await tester.tap(find.byType(KumoFieldBox));
    await tester.pump();
    expect(fade(), 1);
  });
}
