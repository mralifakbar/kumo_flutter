import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';
import 'data_test_utils.dart';

const _worker = '''export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    return new Response(`Hello from \${url.hostname}`);
  },
};''';

Color? _colorOf(WidgetTester tester, String text) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    Color? found;
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text == text) {
        found = span.style?.color;
        return false;
      }
      return true;
    });
    if (found != null) return found;
  }
  return null;
}

void main() {
  testWidgets('renders every variant in light and dark, with and without numbers', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              for (final v in KumoCodeVariant.values) ...[
                KumoCodeHighlighted(
                  code: _worker,
                  lang: 'ts',
                  variant: v,
                  showLineNumbers: true,
                  highlightLines: const [3],
                ),
                KumoCodeHighlighted(code: _worker, lang: 'ts', variant: v, wrap: true, showLineNumbers: true),
                const KumoCode(code: 'npx wrangler deploy'),
                const KumoCode.block(code: 'npx wrangler deploy', showCopyButton: true),
              ],
            ],
          ),
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('colors tokens from the Kumo palette', (tester) async {
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'const a = "x";', lang: 'ts'));
    final colors = KumoCodeColors.of(KumoThemeData.light());
    expect(_colorOf(tester, 'const'), colors.keyword);
    expect(_colorOf(tester, '"x"'), colors.string);
  });

  testWidgets('unknown languages render plain in text-kumo-subtle', (tester) async {
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'MOVE A TO B.', lang: 'cobol'));
    expect(find.text('MOVE A TO B.'), findsOneWidget);
    expect(_colorOf(tester, 'MOVE A TO B.'), KumoThemeData.light().colors.textSubtle);
  });

  testWidgets('line numbers show for multi-line code only, hidden from screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'a\nb\nc', lang: 'ts', showLineNumbers: true));
    expect(find.text('3'), findsOneWidget);
    expect(find.bySemanticsLabel('3'), findsNothing);
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'one line', lang: 'ts', showLineNumbers: true));
    expect(find.text('1'), findsNothing);
    handle.dispose();
  });

  testWidgets('highlighted lines get the highlight background', (tester) async {
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'a\nb\nc', lang: 'ts', highlightLines: [2]));
    final tint = KumoCodeColors.of(KumoThemeData.light()).lineHighlight;
    final tinted = tester.widgetList<Container>(find.byType(Container)).where((c) => c.color == tint);
    expect(tinted, hasLength(1));
  });

  testWidgets('long lines scroll sideways; wrap keeps them in view', (tester) async {
    final long = 'const token = "${'x' * 200}";';
    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoCodeHighlighted(code: long, lang: 'ts'),
      ),
    );
    expect(tester.takeException(), isNull);
    final scrollable = find.byWidgetPredicate(
      (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
    );
    expect(scrollable, findsOneWidget);
    await tester.drag(scrollable, const Offset(-200, 0));
    await tester.pumpAndSettle();
    final controller = tester.widget<SingleChildScrollView>(scrollable).controller!;
    expect(controller.offset, greaterThan(0));

    await pumpKumo(
      tester,
      SizedBox(
        width: 300,
        child: KumoCodeHighlighted(code: long, lang: 'ts', wrap: true),
      ),
    );
    expect(scrollable, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copy button copies, shows Copied, announces, then resets', (tester) async {
    final copied = mockClipboard(tester);
    final announced = mockAnnouncements(tester);
    var calls = 0;
    await pumpKumo(tester, KumoCodeHighlighted(code: _worker, lang: 'ts', showCopyButton: true, onCopy: () => calls++));
    await tester.tap(find.text('Copy'));
    await settleCopy(tester);
    expect(copied, [_worker]);
    expect(calls, 1);
    expect(find.text('Copied'), findsOneWidget);
    expect(announced, ['Copied']);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('a failed copy shows and announces the failure copy', (tester) async {
    mockClipboard(tester, fail: true);
    final announced = mockAnnouncements(tester);
    var calls = 0;
    await pumpKumo(tester, KumoCode.block(code: 'npx wrangler deploy', showCopyButton: true, onCopy: () => calls++));
    await tester.tap(find.text('Copy'));
    await settleCopy(tester);
    expect(find.text('Could not copy'), findsOneWidget);
    expect(announced, ['Could not copy']);
    expect(calls, 0);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('copy button is hidden until hover with a mouse, always shown on touch', (tester) async {
    double opacity() => tester
        .widget<AnimatedOpacity>(find.ancestor(of: find.text('Copy'), matching: find.byType(AnimatedOpacity)).last)
        .opacity;
    await pumpKumo(tester, const KumoCodeHighlighted(code: 'a\nb', lang: 'ts', showCopyButton: true));
    expect(opacity(), 1);
    await pumpKumo(
      tester,
      const KumoCodeHighlighted(code: 'a\nb', lang: 'ts', showCopyButton: true),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    expect(opacity(), 0);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.byType(KumoCodeHighlighted)));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    await gesture.removePointer();
  });

  testWidgets('copy button is reachable with Tab and fires with Enter', (tester) async {
    final copied = mockClipboard(tester);
    await pumpKumo(
      tester,
      const KumoCodeHighlighted(code: 'a\nb', lang: 'ts', showCopyButton: true),
      tapTargetSize: KumoTapTargetSize.shrinkWrap,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final opacity = tester.widget<AnimatedOpacity>(
      find.ancestor(of: find.text('Copy'), matching: find.byType(AnimatedOpacity)).last,
    );
    expect(opacity.opacity, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settleCopy(tester);
    expect(copied, ['a\nb']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('KumoCode fills {{key}} values and copies the filled text', (tester) async {
    final copied = mockClipboard(tester);
    await pumpKumo(
      tester,
      const KumoCode.block(
        code: 'export CLOUDFLARE_API_TOKEN={{token}}',
        values: {'token': KumoCodeValue('abc123', highlight: true)},
        showCopyButton: true,
      ),
    );
    expect(find.textContaining('abc123', findRichText: true), findsOneWidget);
    expect(find.textContaining('{{token}}', findRichText: true), findsNothing);
    await tester.tap(find.text('Copy'));
    await settleCopy(tester);
    expect(copied, ['export CLOUDFLARE_API_TOKEN=abc123']);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('maxHeight scrolls vertically', (tester) async {
    final code = List.generate(80, (i) => 'line $i').join('\n');
    await pumpKumo(tester, KumoCodeHighlighted(code: code, lang: 'ts', maxHeight: 200));
    expect(tester.getSize(find.byType(KumoCodeHighlighted)).height, lessThanOrEqualTo(202));
  });

  testWidgets('text scale 2.0 at 390px, RTL and reduced motion do not overflow', (tester) async {
    await pumpKumo(
      tester,
      const Padding(
        padding: EdgeInsets.all(16),
        child: KumoCodeHighlighted(code: _worker, lang: 'ts', showLineNumbers: true, showCopyButton: true),
      ),
      textScale: 2,
      textDirection: TextDirection.rtl,
      disableAnimations: true,
    );
    expect(tester.takeException(), isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
