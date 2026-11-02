import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Object? _result;

class _Launcher extends StatelessWidget {
  const _Launcher({required this.drawer});

  final WidgetBuilder drawer;

  @override
  Widget build(BuildContext context) {
    return KumoButton(
      label: 'Open',
      onPress: () async {
        _result = await showKumoDrawer<Object>(context, builder: drawer);
      },
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

KumoDrawer _drawer({
  KumoSheetEdge side = KumoSheetEdge.end,
  bool dismissible = true,
  Widget? child,
}) =>
    KumoDrawer(
      side: side,
      dismissible: dismissible,
      title: 'image-resizer',
      description: 'Worker settings',
      actions: const [
        KumoDialogClose(label: 'Cancel'),
        KumoDialogClose(label: 'Save settings', variant: KumoButtonVariant.primary, result: 'saved'),
      ],
      child: child ?? const Text('Compatibility date 2026-10-26'),
    );

Rect _surface(WidgetTester tester) =>
    tester.getRect(find.descendant(of: find.byType(KumoSheet), matching: find.byType(ClipRRect)).first);

void main() {
  setUp(() => _result = null);

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} mode', (tester) async {
      await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), brightness: brightness, size: kumoDesktopSize);
      await _open(tester);
      expect(find.text('image-resizer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('an end drawer is attached to the right edge and capped at 384px', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    final rect = _surface(tester);
    expect(rect.right, kumoDesktopSize.width);
    expect(rect.width, 384);
    expect(rect.height, kumoDesktopSize.height);
  });

  testWidgets('on a phone a side drawer takes at most 85% of the width', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer(side: KumoSheetEdge.start)));
    await _open(tester);
    final rect = _surface(tester);
    expect(rect.left, 0);
    expect(rect.width, closeTo(kumoPhoneSize.width * 0.85, 0.5));
  });

  testWidgets('start follows the text direction', (tester) async {
    await pumpKumo(
      tester,
      _Launcher(drawer: (_) => _drawer(side: KumoSheetEdge.start)),
      size: kumoDesktopSize,
      textDirection: TextDirection.rtl,
    );
    await _open(tester);
    expect(_surface(tester).right, kumoDesktopSize.width);
  });

  testWidgets('a flick toward the edge dismisses; a short drag springs back', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    final before = _surface(tester).left;
    await tester.drag(find.text('Worker settings'), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(_surface(tester).left, closeTo(before, 1));

    await tester.fling(find.text('Worker settings'), const Offset(150, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsNothing);
  });

  testWidgets('follows the finger while dragged', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    final before = _surface(tester).left;
    final gesture = await tester.startGesture(tester.getCenter(find.text('Worker settings')));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(_surface(tester).left, closeTo(before + 60, 21));
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a non-dismissible drawer ignores flicks and the backdrop', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer(dismissible: false)), size: kumoDesktopSize);
    await _open(tester);
    await tester.fling(find.text('Worker settings'), const Offset(200, 0), 2000);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsOneWidget);
  });

  testWidgets('footer buttons close it with a value; Escape and the X close it', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();
    expect(_result, 'saved');
    expect(find.text('image-resizer'), findsNothing);

    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsNothing);

    await _open(tester);
    await tester.tap(find.byIcon(KumoIcons.x));
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsNothing);
  });

  testWidgets('focus stays inside while open', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    for (var i = 0; i < 5; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.descendant(of: find.byType(KumoDrawer), matching: find.byElementPredicate((e) => e == focused)),
        findsOneWidget,
      );
    }
  });

  testWidgets('a bottom drawer shows a handle and dismisses with a downward flick', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer(side: KumoSheetEdge.bottom)));
    await _open(tester);
    expect(find.byType(KumoSheetHandle), findsOneWidget);
    expect(_surface(tester).bottom, kumoPhoneSize.height);
    await tester.fling(find.text('Worker settings'), const Offset(0, 300), 1500);
    await tester.pumpAndSettle();
    expect(find.text('image-resizer'), findsNothing);
  });

  testWidgets('long content scrolls between a pinned header and footer', (tester) async {
    await pumpKumo(
      tester,
      _Launcher(
        drawer: (_) => _drawer(child: Column(children: [for (var i = 0; i < 60; i++) Text('Route $i')])),
      ),
      size: kumoDesktopSize,
    );
    await _open(tester);
    final titleTop = tester.getTopLeft(find.text('image-resizer')).dy;
    await tester.drag(find.text('Route 3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('image-resizer')).dy, titleTop);
    expect(tester.getRect(find.text('Save settings')).bottom, lessThanOrEqualTo(kumoDesktopSize.height));
  });

  testWidgets('2x text at 390px does not overflow', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), textScale: 2);
    await _open(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title names the route', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize);
    await _open(tester);
    expect(
      tester.getSemantics(find.text('image-resizer')),
      matchesSemantics(label: 'image-resizer', isHeader: true, namesRoute: true),
    );
    semantics.dispose();
  });

  testWidgets('KumoDialogRoot drives a drawer', (tester) async {
    await pumpKumo(tester, const _RootHost(), size: kumoDesktopSize);
    await tester.tap(find.text('Show filters'));
    await tester.pumpAndSettle();
    expect(find.text('Filter zones'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Filter zones'), findsNothing);
    expect(find.text('closed'), findsOneWidget);
  });

  testWidgets('reduced motion opens and closes without springs', (tester) async {
    await pumpKumo(tester, _Launcher(drawer: (_) => _drawer()), size: kumoDesktopSize, disableAnimations: true);
    await _open(tester);
    expect(_surface(tester).right, kumoDesktopSize.width);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}

class _RootHost extends StatefulWidget {
  const _RootHost();

  @override
  State<_RootHost> createState() => _RootHostState();
}

class _RootHostState extends State<_RootHost> {
  bool _open = false;
  bool _closed = false;

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: _open,
      onOpenChange: (open) => setState(() {
        _open = open;
        if (!open) _closed = true;
      }),
      dialog: const KumoDrawer(title: 'Filter zones', child: Text('Active zones')),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KumoButton(label: 'Show filters', onPress: () => setState(() => _open = true)),
          if (_closed) const Text('closed'),
        ],
      ),
    );
  }
}
