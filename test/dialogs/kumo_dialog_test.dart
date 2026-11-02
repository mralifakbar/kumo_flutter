import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// A trigger that opens whatever [open] shows and keeps the result.
class _Launcher extends StatelessWidget {
  const _Launcher({required this.open});

  final Future<Object?> Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) {
    return KumoButton(
      label: 'Open',
      onPress: () async {
        _result = await open(context);
      },
    );
  }
}

Object? _result;
bool _wide = false;

Finder get _panel => find.descendant(of: find.byType(KumoDialog), matching: find.byType(ClipRRect)).first;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

KumoDialog _sample({List<Widget>? actions, Widget? child, KumoDialogSize size = KumoDialogSize.base}) => KumoDialog(
      title: 'Rename Worker',
      description: 'The workers.dev URL changes; routes keep working.',
      size: size,
      actions: actions ??
          const [
            KumoDialogClose(label: 'Cancel', result: 'cancel'),
            KumoDialogClose(label: 'Rename', variant: KumoButtonVariant.primary, result: 'rename'),
          ],
      child: child,
    );

void main() {
  setUp(() => _result = null);

  for (final brightness in Brightness.values) {
    testWidgets('renders in ${brightness.name} mode', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())),
        brightness: brightness,
      );
      await _open(tester);
      expect(find.text('Rename Worker'), findsOneWidget);
      expect(find.text('The workers.dev URL changes; routes keep working.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a close part returns its result and animates out', (tester) async {
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Rename Worker'), findsOneWidget, reason: 'still fading out');
    await tester.pumpAndSettle();
    expect(find.text('Rename Worker'), findsNothing);
    expect(_result, 'rename');
  });

  testWidgets('the X closes a dialog and is announced as Close', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    expect(find.bySemanticsLabel('Close'), findsWidgets);
    await tester.tap(find.byIcon(KumoIcons.x));
    await tester.pumpAndSettle();
    expect(find.text('Rename Worker'), findsNothing);
    expect(_result, isNull);
    semantics.dispose();
  });

  testWidgets('title is a heading that names the route', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    expect(
      tester.getSemantics(find.text('Rename Worker')),
      matchesSemantics(label: 'Rename Worker', isHeader: true, namesRoute: true),
    );
    semantics.dispose();
  });

  testWidgets('backdrop tap closes a dialog but not an alert dialog', (tester) async {
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    await tester.tapAt(const Offset(10, 800));
    await tester.pumpAndSettle();
    expect(find.text('Rename Worker'), findsNothing);

    await pumpKumo(
      tester,
      _Launcher(
        open: (context) => showKumoDialog<String>(context, role: KumoDialogRole.alertDialog, builder: (_) => _sample()),
      ),
    );
    await _open(tester);
    expect(find.byIcon(KumoIcons.x), findsNothing, reason: 'alert dialogs need an explicit choice');
    await tester.tapAt(const Offset(10, 800));
    await tester.pumpAndSettle();
    expect(find.text('Rename Worker'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Rename Worker'), findsNothing, reason: 'Escape still cancels an alert dialog');
  });

  testWidgets('Tab stays inside the dialog', (tester) async {
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    final dialog = find.byType(KumoDialog);
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(find.descendant(of: dialog, matching: find.byElementPredicate((e) => e == focused)), findsOneWidget);
    }
  });

  testWidgets('Enter on a focused close part activates it', (tester) async {
    await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<String>(context, builder: (_) => _sample())));
    await _open(tester);
    // X, Cancel, Rename.
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_result, 'rename');
  });

  group('showKumoAlertDialog', () {
    Widget launcher({bool destructive = true}) => _Launcher(
          open: (context) => showKumoAlertDialog(
            context,
            title: 'Delete image-resizer?',
            description: 'Routes pointing at this Worker stop serving traffic.',
            confirmLabel: 'Delete Worker',
            destructive: destructive,
          ),
        );

    testWidgets('returns true on confirm and false on cancel', (tester) async {
      await pumpKumo(tester, launcher());
      await _open(tester);
      expect(find.byIcon(KumoIcons.warningFill), findsOneWidget);
      await tester.tap(find.text('Delete Worker'));
      await tester.pumpAndSettle();
      expect(_result, isTrue);

      await _open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_result, isFalse);

      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_result, isFalse);
    });

    testWidgets('a destructive confirmation focuses Cancel first', (tester) async {
      await pumpKumo(tester, launcher());
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Delete Worker'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_result, isFalse);
    });

    testWidgets('the backdrop does not dismiss it', (tester) async {
      await pumpKumo(tester, launcher(destructive: false));
      await _open(tester);
      expect(find.byIcon(KumoIcons.warningFill), findsNothing);
      await tester.tapAt(const Offset(10, 800));
      await tester.pumpAndSettle();
      expect(find.text('Delete Worker'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('takes the full width minus 16px gutters on a phone', (tester) async {
      await pumpKumo(tester, _Launcher(open: (context) => showKumoDialog<void>(context, builder: (_) => _sample())));
      await _open(tester);
      final rect = tester.getRect(_panel);
      expect(rect.width, kumoPhoneSize.width - 32);
      expect(rect.left, 16);
      expect(rect.top, 32);
    });

    for (final size in KumoDialogSize.values) {
      testWidgets('${size.name} is ${size.width}px wide on desktop', (tester) async {
        await pumpKumo(
          tester,
          _Launcher(open: (context) => showKumoDialog<void>(context, builder: (_) => _sample(size: size))),
          size: kumoDesktopSize,
        );
        await _open(tester);
        final rect = tester.getRect(_panel);
        expect(rect.width, size.width);
        expect(rect.center.dx, kumoDesktopSize.width / 2);
        expect(rect.top, 64);
      });
    }

    testWidgets('long content scrolls inside with the header and footer pinned', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(
          open: (context) => showKumoDialog<void>(
            context,
            builder: (_) => _sample(
              child: Column(children: [for (var i = 0; i < 40; i++) Text('record-$i.example.com')]),
            ),
          ),
        ),
      );
      await _open(tester);
      final panel = tester.getRect(_panel);
      expect(panel.bottom, lessThanOrEqualTo(kumoPhoneSize.height - 16));
      expect(find.text('Rename'), findsOneWidget);
      final titleTop = tester.getTopLeft(find.text('Rename Worker')).dy;
      await tester.drag(find.text('record-5.example.com'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Rename Worker')).dy, titleTop);
      expect(tester.getRect(find.text('Rename')).bottom, lessThanOrEqualTo(panel.bottom));
    });

    testWidgets('stays above the keyboard', (tester) async {
      tester.view.viewInsets = FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await pumpKumo(
        tester,
        _Launcher(
          open: (context) => showKumoDialog<void>(
            context,
            builder: (_) => _sample(child: Column(children: [for (var i = 0; i < 40; i++) Text('Row $i')])),
          ),
        ),
      );
      await _open(tester);
      final insets = MediaQuery.viewInsetsOf(tester.element(find.byType(KumoDialog)));
      expect(tester.getRect(_panel).bottom, lessThanOrEqualTo(kumoPhoneSize.height - insets.bottom - 16 + 0.01));
    });

    testWidgets('2x text at 390px wide does not overflow', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(
          open: (context) => showKumoDialog<void>(
            context,
            builder: (_) => _sample(child: const Text('Workers on this route keep serving until the rename finishes.')),
          ),
        ),
        textScale: 2,
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('RTL puts the close X on the left', (tester) async {
      await pumpKumo(
        tester,
        _Launcher(open: (context) => showKumoDialog<void>(context, builder: (_) => _sample())),
        textDirection: TextDirection.rtl,
      );
      await _open(tester);
      expect(tester.getCenter(find.byIcon(KumoIcons.x)).dx, lessThan(tester.getCenter(find.text('Rename Worker')).dx));
    });
  });

  testWidgets('reduced motion opens without a scale', (tester) async {
    await pumpKumo(
      tester,
      _Launcher(open: (context) => showKumoDialog<void>(context, builder: (_) => _sample())),
      disableAnimations: true,
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.ancestor(of: find.byType(KumoDialog), matching: find.byType(ScaleTransition)), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  group('KumoDialogRoot', () {
    testWidgets('opens from open, reports dismissal and animates out', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _RootHost(onChange: changes.add));
      expect(find.text('Edit DNS record'), findsNothing);
      await tester.tap(find.text('Edit record'));
      await tester.pumpAndSettle();
      expect(find.text('Edit DNS record'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(changes, [true, false]);
      expect(find.text('Edit DNS record'), findsNothing);
    });

    testWidgets('closing from the parent animates the dialog out', (tester) async {
      await pumpKumo(tester, const _RootHost());
      await tester.tap(find.text('Edit record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save record'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Edit DNS record'), findsOneWidget, reason: 'mid exit');
      await tester.pumpAndSettle();
      expect(find.text('Edit DNS record'), findsNothing);
    });

    testWidgets('state changes reach the open dialog', (tester) async {
      await pumpKumo(tester, const _RootHost());
      await tester.tap(find.text('Edit record'));
      await tester.pumpAndSettle();
      expect(find.text('Saved 0 times'), findsOneWidget);
      await tester.tap(find.text('Save draft'));
      await tester.pumpAndSettle();
      expect(find.text('Saved 1 times'), findsOneWidget);
    });

    testWidgets('the close part asks the parent to close', (tester) async {
      final changes = <bool>[];
      await pumpKumo(tester, _RootHost(onChange: changes.add));
      await tester.tap(find.text('Edit record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(changes.last, isFalse);
      expect(find.text('Edit DNS record'), findsNothing);
    });

    testWidgets('unmounting while open removes the dialog', (tester) async {
      await pumpKumo(tester, const _RootHost(initiallyOpen: true));
      await tester.pumpAndSettle();
      expect(find.text('Edit DNS record'), findsOneWidget);
      await pumpKumo(tester, const SizedBox());
      await tester.pumpAndSettle();
      expect(find.text('Edit DNS record'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
  group('motion', () {
    Widget growing() => _Launcher(
          open: (context) => showKumoDialog<void>(
            context,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) => KumoDialog(
                title: 'Create API token',
                size: _wide ? KumoDialogSize.lg : KumoDialogSize.base,
                showCloseButton: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A plain tap target: this test is about the panel, not buttons.
                    GestureDetector(onTap: () => setState(() => _wide = !_wide), child: const Text('Add permission')),
                    if (_wide) ...[const SizedBox(height: 120), const Text('Workers edit')],
                  ],
                ),
              ),
            ),
          ),
        );

    setUp(() => _wide = false);

    testWidgets('the panel follows its content and size instead of jumping', (tester) async {
      await pumpKumo(tester, growing(), size: kumoDesktopSize);
      await _open(tester);
      final before = tester.getSize(_panel);
      expect(before.width, 384);
      await tester.tap(find.text('Add permission'));
      await tester.pump();
      // The new content height reaches the panel's spring one frame later.
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getSize(_panel);
      expect(mid.height, greaterThan(before.height));
      expect(mid.width, greaterThan(384));
      expect(mid.width, lessThan(512));
      await tester.pumpAndSettle();
      final after = tester.getSize(_panel);
      expect(after.width, 512);
      expect(after.height, greaterThan(mid.height));
    });

    testWidgets('reduced motion: the panel resizes at once', (tester) async {
      await pumpKumo(tester, growing(), size: kumoDesktopSize, disableAnimations: true);
      await _open(tester);
      final before = tester.getSize(_panel);
      await tester.tap(find.text('Add permission'));
      await tester.pump();
      final after = tester.getSize(_panel);
      expect(after.width, 512);
      expect(after.height, greaterThan(before.height + 100));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

}

class _RootHost extends StatefulWidget {
  const _RootHost({this.onChange, this.initiallyOpen = false});

  final ValueChanged<bool>? onChange;
  final bool initiallyOpen;

  @override
  State<_RootHost> createState() => _RootHostState();
}

class _RootHostState extends State<_RootHost> {
  late bool _open = widget.initiallyOpen;
  int _saves = 0;

  void _set(bool open) {
    widget.onChange?.call(open);
    setState(() => _open = open);
  }

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: _open,
      onOpenChange: _set,
      dialog: KumoDialog(
        title: 'Edit DNS record',
        actions: [
          const KumoDialogClose(label: 'Cancel'),
          KumoButton(label: 'Save draft', onPress: () => setState(() => _saves++)),
          KumoButton(label: 'Save record', variant: KumoButtonVariant.primary, onPress: () => _set(false)),
        ],
        child: Text('Saved $_saves times'),
      ),
      child: KumoButton(label: 'Edit record', onPress: () => _set(true)),
    );
  }

}
