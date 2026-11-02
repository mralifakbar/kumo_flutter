import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

Object? _result;

class _Launcher extends StatelessWidget {
  const _Launcher({required this.dialog});

  final WidgetBuilder dialog;

  @override
  Widget build(BuildContext context) {
    return KumoButton(
      label: 'Open',
      onPress: () async {
        _result = await showKumoLayerDialog<Object>(context, builder: dialog);
      },
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Widget _longBody() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (var i = 0; i < 60; i++) Text('Shortcut $i')],
    );

KumoLayerDialog _informational({Widget? body}) => KumoLayerDialog(
      title: 'Keyboard shortcuts',
      description: 'Browse shortcuts without changing a setting.',
      body: body ?? const Text('Press / to search Workers.'),
    );

KumoLayerDialog _withAction({VoidCallback? onSave, bool dismissDisabled = false, String? dismissLabel}) => KumoLayerDialog(
      title: 'Configure custom hostname',
      description: 'Route requests for this hostname to your Worker.',
      body: const Text('api.example.com'),
      dismissLabel: dismissLabel,
      dismissDisabled: dismissDisabled,
      action: KumoLayerDialogAction(label: 'Save hostname', onPress: onSave ?? () {}),
    );

void main() {
  setUp(() => _result = null);

  for (final brightness in Brightness.values) {
    for (final size in [kumoPhoneSize, kumoDesktopSize]) {
      testWidgets('renders in ${brightness.name} at ${size.width.toInt()}px', (tester) async {
        await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()), brightness: brightness, size: size);
        await _open(tester);
        expect(find.text('Configure custom hostname'), findsOneWidget);
        expect(find.text('Save hostname'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  group('desktop', () {
    testWidgets('without an action it shows an X and no footer', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _informational()), size: kumoDesktopSize);
      await _open(tester);
      expect(find.byIcon(KumoIcons.x), findsOneWidget);
      expect(find.text('Close'), findsNothing);
      await tester.tap(find.byIcon(KumoIcons.x));
      await tester.pumpAndSettle();
      expect(find.text('Keyboard shortcuts'), findsNothing);
    });

    testWidgets('with an action it shows Close and the action instead of the X', (tester) async {
      var saved = 0;
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction(onSave: () => saved++)), size: kumoDesktopSize);
      await _open(tester);
      expect(find.byIcon(KumoIcons.x), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text('Save hostname'));
      expect(saved, 1);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsNothing);
    });

    testWidgets('centers at the size width and rises 8px on the way in', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()), size: kumoDesktopSize);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final midway = tester.getTopLeft(find.text('Configure custom hostname')).dy;
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(find.text('Configure custom hostname')).dy;
      expect(midway, greaterThan(settled));
      expect(midway - settled, lessThanOrEqualTo(8));
      final frame = tester.getRect(find.ancestor(of: find.text('Close'), matching: find.byType(DecoratedBox)).last);
      expect(frame.width, KumoLayerDialogSize.base.width);
      expect(frame.center.dx, kumoDesktopSize.width / 2);
      expect(frame.center.dy, closeTo(kumoDesktopSize.height / 2, 1));
    });

    testWidgets('top alignment sits 64px from the top', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(
          dialog: (_) => const KumoLayerDialog(
            title: 'Search',
            verticalAlign: KumoLayerDialogVerticalAlign.top,
            size: KumoLayerDialogSize.sm,
            body: Text('No Workers match.'),
          ),
        ),
        size: kumoDesktopSize,
      );
      await _open(tester);
      final frame = tester.getRect(find.ancestor(of: find.text('Search'), matching: find.byType(DecoratedBox)).last);
      expect(frame.top, 64);
      expect(frame.width, 448);
    });

    testWidgets('backdrop and Escape dismiss a standard dialog', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()), size: kumoDesktopSize);
      await _open(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsNothing);

      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsNothing);
    });

    testWidgets('an alert ignores the backdrop, says Cancel and still closes on Escape', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(
          dialog: (_) => KumoLayerDialog.alert(
            title: 'Delete production-api?',
            body: const Text('Requests to its routes fail until you deploy again.'),
            action: KumoLayerDialogAction(
              label: 'Delete Worker',
              variant: KumoLayerDialogActionVariant.destructive,
              onPress: () {},
            ),
          ),
        ),
        size: kumoDesktopSize,
      );
      await _open(tester);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(KumoIcons.x), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Delete production-api?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete production-api?'), findsNothing);
    });

    testWidgets('dismissDisabled blocks Escape, backdrop and the dismiss button', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction(dismissDisabled: true)), size: kumoDesktopSize);
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(const Offset(10, 10));
      await tester.tap(find.text('Close'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsOneWidget);

      // Closing from code still works.
      Navigator.of(tester.element(find.text('Close'))).pop('saved');
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsNothing);
      expect(_result, 'saved');
    });

    testWidgets('dismissLabel renames the dismiss button', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction(dismissLabel: 'Keep editing')), size: kumoDesktopSize);
      await _open(tester);
      expect(find.text('Keep editing'), findsOneWidget);
    });

    testWidgets('the split menu offers related actions', (tester) async {
      var drafts = 0;
      await pumpKumo(
        tester,
        _Launcher(
          dialog: (_) => KumoLayerDialog(
            title: 'Deploy changes',
            body: const Text('image-resizer'),
            action: KumoLayerDialogAction(
              label: 'Save and deploy',
              onPress: () {},
              menu: [KumoLayerDialogMenuItem(label: 'Save as draft', onPress: () => drafts++)],
            ),
          ),
        ),
        size: kumoDesktopSize,
      );
      await _open(tester);
      await tester.tap(find.bySemanticsLabel('More actions').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save as draft'));
      await tester.pumpAndSettle();
      expect(drafts, 1);
      expect(find.text('Save as draft'), findsNothing);
      expect(find.text('Deploy changes'), findsOneWidget);
    });
  });

  group('phone', () {
    testWidgets('opens as a bottom sheet with a handle that flicks away', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()));
      await _open(tester);
      expect(find.byType(KumoSheet), findsOneWidget);
      final rect = tester.getRect(find.byType(KumoLayerDialog));
      expect(rect.bottom, kumoPhoneSize.height);
      expect(find.text('Close'), findsOneWidget, reason: 'the footer stays visible on phones');
      await tester.fling(find.text('Configure custom hostname'), const Offset(0, 300), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Configure custom hostname'), findsNothing);
    });

    testWidgets('an alert cannot be swiped away', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(
          dialog: (_) => KumoLayerDialog.alert(
            title: 'Rotate API token?',
            body: const Text('Apps using the old token stop working.'),
            action: KumoLayerDialogAction(label: 'Rotate token', onPress: () {}),
          ),
        ),
      );
      await _open(tester);
      await tester.fling(find.text('Rotate API token?'), const Offset(0, 300), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Rotate API token?'), findsOneWidget);
    });

    testWidgets('caps at 85% of the screen and scrolls the body', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _informational(body: _longBody())));
      await _open(tester);
      final sheet = tester.getRect(find.descendant(of: find.byType(KumoSheet), matching: find.byType(ClipRRect)).first);
      expect(sheet.height, lessThanOrEqualTo(kumoPhoneSize.height * 0.85 + 1));
      final titleTop = tester.getTopLeft(find.text('Keyboard shortcuts')).dy;
      await tester.drag(find.text('Shortcut 10'), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Keyboard shortcuts')).dy, titleTop, reason: 'the title frame is sticky');
    });

    testWidgets('2x text does not overflow', (tester) async {
      await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()), textScale: 2);
      await _open(tester);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the description folds away once the body scrolls', (tester) async {
    await pumpKumo(tester, _Launcher(dialog: (_) => _informational(body: _longBody())), size: kumoDesktopSize);
    await _open(tester);
    Align fold() => tester.widget<Align>(
          find.ancestor(of: find.text('Browse shortcuts without changing a setting.'), matching: find.byType(Align)).first,
        );
    expect(fold().heightFactor, 1);
    await tester.drag(find.text('Shortcut 5'), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(fold().heightFactor, 0);
    expect(find.text('Browse shortcuts without changing a setting.', skipOffstage: false), findsOneWidget);
    await tester.drag(find.text('Shortcut 12'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(fold().heightFactor, 1);
  });

  testWidgets('a separator spans the full body width', (tester) async {
    await pumpKumo(
      tester,
      _Launcher(
        dialog: (_) => const KumoLayerDialog(
          title: 'Deployment summary',
          body: Column(children: [Text('production-api'), KumoLayerDialogSeparator(), Text('2026-10-26')]),
        ),
      ),
      size: kumoDesktopSize,
    );
    await _open(tester);
    final line = tester.getRect(
      find.descendant(of: find.byType(KumoLayerDialogSeparator), matching: find.byType(ColoredBox)),
    );
    // 576px panel minus the 6px frame padding on both sides.
    expect(line.width, 576 - 12);
  });

  testWidgets('title is a heading that names the route', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpKumo(tester, _Launcher(dialog: (_) => _informational()), size: kumoDesktopSize);
    await _open(tester);
    expect(
      tester.getSemantics(find.text('Keyboard shortcuts')),
      matchesSemantics(label: 'Keyboard shortcuts', isHeader: true, namesRoute: true),
    );
    semantics.dispose();
  });

  testWidgets('KumoDialogRoot drives a layer dialog', (tester) async {
    await pumpKumo(tester, const _RootHost(), size: kumoDesktopSize);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.text('Configure custom hostname'), findsOneWidget);
    await tester.tap(find.text('Save hostname'));
    await tester.pumpAndSettle();
    expect(find.text('Configure custom hostname'), findsNothing);
  });

  testWidgets('reduced motion settles with no running animations', (tester) async {
    await pumpKumo(tester, _Launcher(dialog: (_) => _withAction()), size: kumoDesktopSize, disableAnimations: true);
    await _open(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Configure custom hostname'), findsNothing);
  });
}

class _RootHost extends StatefulWidget {
  const _RootHost();

  @override
  State<_RootHost> createState() => _RootHostState();
}

class _RootHostState extends State<_RootHost> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: _open,
      onOpenChange: (open) => setState(() => _open = open),
      dialog: KumoLayerDialog(
        title: 'Configure custom hostname',
        body: const Text('api.example.com'),
        action: KumoLayerDialogAction(label: 'Save hostname', onPress: () => setState(() => _open = false)),
      ),
      child: KumoButton(label: 'Open settings', onPress: () => setState(() => _open = true)),
    );
  }
}
