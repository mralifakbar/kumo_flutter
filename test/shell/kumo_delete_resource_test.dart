import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

/// Holds the dialog's open state the way an app would.
class _Host extends StatefulWidget {
  const _Host({this.caseSensitive = true, this.errorMessage, this.deleting = false, this.onDelete, this.openChanges});

  final bool caseSensitive;
  final String? errorMessage;
  final bool deleting;
  final VoidCallback? onDelete;
  final List<bool>? openChanges;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return KumoDeleteResource(
      open: open,
      onOpenChange: (v) {
        widget.openChanges?.add(v);
        setState(() => open = v);
      },
      resourceType: 'Zone',
      resourceName: 'example.com',
      caseSensitive: widget.caseSensitive,
      errorMessage: widget.errorMessage,
      isDeleting: widget.deleting,
      onDelete: () => widget.onDelete?.call(),
      child: KumoButton(
        label: 'Delete zone',
        variant: KumoButtonVariant.destructive,
        onPress: () => setState(() => open = true),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Delete zone'));
  await tester.pumpAndSettle();
}

KumoButton _deleteButton(WidgetTester tester) =>
    tester.widget<KumoButton>(find.widgetWithText(KumoButton, 'Delete Zone'));

void main() {
  testWidgets('opens with clear copy in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        KeyedSubtree(key: ValueKey(b), child: const _Host()),
        brightness: b,
      );
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Delete example.com'), findsOneWidget);
      expect(
        find.textContaining(
          'This action cannot be undone. This will permanently delete the example.com zone.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    }
  });

  testWidgets('delete stays disabled until the exact name is typed', (tester) async {
    var deletes = 0;
    await pumpKumo(tester, _Host(onDelete: () => deletes++));
    await _open(tester);
    expect(_deleteButton(tester).disabled, isTrue);
    await tester.tap(find.text('Delete Zone'));
    expect(deletes, 0);
    await tester.enterText(find.byType(EditableText), 'Example.com');
    await tester.pump();
    expect(_deleteButton(tester).disabled, isTrue, reason: 'case-sensitive by default');
    await tester.enterText(find.byType(EditableText), 'example.com');
    await tester.pump();
    expect(_deleteButton(tester).disabled, isFalse);
    await tester.tap(find.text('Delete Zone'));
    await tester.pump();
    expect(deletes, 1);
  });

  testWidgets('Enter in the field confirms once the name matches', (tester) async {
    var deletes = 0;
    await pumpKumo(tester, _Host(onDelete: () => deletes++));
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'example.co');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(deletes, 0);
    await tester.enterText(find.byType(EditableText), 'example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(deletes, 1);
  });

  testWidgets('caseSensitive false accepts any case', (tester) async {
    await pumpKumo(tester, const _Host(caseSensitive: false));
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'EXAMPLE.COM');
    await tester.pump();
    expect(_deleteButton(tester).disabled, isFalse);
  });

  testWidgets('field is focused and labeled for screen readers', (tester) async {
    await pumpKumo(tester, const _Host());
    await _open(tester);
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Type example.com to confirm deletion'), findsOneWidget);
    expect(find.bySemanticsLabel('Copy example.com to clipboard'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Cancel, close and Escape close it and clear the field', (tester) async {
    final changes = <bool>[];
    await pumpKumo(tester, _Host(openChanges: changes));
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'example');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(changes, [false]);
    expect(find.text('Delete example.com'), findsNothing);

    await _open(tester);
    expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, isEmpty);
    await tester.tap(find.byWidgetPredicate((w) => w is KumoButton && w.semanticLabel == 'Close'));
    await tester.pumpAndSettle();
    expect(find.text('Delete example.com'), findsNothing);

    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Delete example.com'), findsNothing);
    expect(changes.last, isFalse);
  });

  testWidgets('while deleting, closing is blocked and the button shows progress', (tester) async {
    await pumpKumo(tester, const _Host(deleting: true));
    // The button's spinner runs while deleting, so pump by time instead of
    // settling.
    await tester.tap(find.text('Delete zone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_deleteButton(tester).loading, isTrue);
    await tester.tap(find.text('Cancel'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete example.com'), findsOneWidget);
    // The loader spins while deleting; dispose the tree to stop it.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('error message shows in a banner', (tester) async {
    await pumpKumo(tester, const _Host(errorMessage: 'Could not delete example.com. Try again in a minute.'));
    await _open(tester);
    expect(find.text('Could not delete example.com. Try again in a minute.'), findsOneWidget);
    expect(find.byIcon(KumoIcons.warningCircle), findsOneWidget);
  });

  testWidgets('name chip copies to the clipboard and shows a check', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpKumo(tester, const _Host());
    await _open(tester);
    await tester.tap(find.bySemanticsLabel('Copy example.com to clipboard'));
    await tester.pump();
    expect(copied, ['example.com']);
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byIcon(KumoIcons.check), findsNothing);
  });

  testWidgets('driving open to false animates the dialog out', (tester) async {
    var open = true;
    late StateSetter set;
    await pumpKumo(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return KumoDeleteResource(
            open: open,
            onOpenChange: (v) => setState(() => open = v),
            resourceType: 'Worker',
            resourceName: 'image-resizer',
            onDelete: () {},
          );
        },
      ),
    );
    expect(find.text('Delete image-resizer'), findsOneWidget);
    expect(find.text('Delete Worker'), findsOneWidget);
    set(() => open = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Delete image-resizer'), findsOneWidget, reason: 'still fading out');
    await tester.pumpAndSettle();
    expect(find.text('Delete image-resizer'), findsNothing);
  });

  testWidgets('narrow screens get full width minus 16px gutters; wide get 384px', (tester) async {
    await pumpKumo(tester, const _Host());
    await _open(tester);
    final surface = find.ancestor(of: find.text('Cancel'), matching: find.byType(ClipRRect)).first;
    expect(tester.getSize(surface).width, kumoPhoneSize.width - 32);
    await tester.pumpWidget(const SizedBox());
    await pumpKumo(tester, const _Host(), size: kumoDesktopSize);
    await _open(tester);
    expect(tester.getSize(find.ancestor(of: find.text('Cancel'), matching: find.byType(ClipRRect)).first).width, 384);
  });

  testWidgets('390px with 2x text does not overflow', (tester) async {
    await pumpKumo(tester, const _Host(errorMessage: 'Could not delete example.com.'), textScale: 2);
    await _open(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the delete button eases on as the name matches', (tester) async {
    await pumpKumo(tester, const _Host());
    await _open(tester);
    expect(_buttonOpacity(tester), closeTo(0.5, 0.001));
    await tester.enterText(find.byType(EditableText), 'example.com');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_buttonOpacity(tester), inExclusiveRange(0.5, 1));
    await tester.pumpAndSettle();
    expect(_buttonOpacity(tester), 1);
    await tester.enterText(find.byType(EditableText), 'example.co');
    await tester.pumpAndSettle();
    expect(_buttonOpacity(tester), closeTo(0.5, 0.001));
  });

  testWidgets('reduced motion: the delete button switches on in one frame', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'example.com');
    await tester.pump();
    expect(_buttonOpacity(tester), 1);
    // The text field itself keeps a few frames of caret work after typing.
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the error banner grows in and the copy slides down', (tester) async {
    String? error;
    late StateSetter set;
    var open = false;
    await pumpKumo(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return KumoDeleteResource(
            open: open,
            onOpenChange: (v) => setState(() => open = v),
            resourceType: 'Zone',
            resourceName: 'example.com',
            errorMessage: error,
            onDelete: () {},
          );
        },
      ),
    );
    set(() => open = true);
    await tester.pumpAndSettle();
    final copy = find.textContaining('This action cannot be undone', findRichText: true);
    final before = tester.getRect(copy).top;
    set(() => error = 'Could not delete example.com. Try again in a minute.');
    // The dialog picks up new props on the frame after the parent rebuilds.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final mid = tester.getRect(copy).top;
    await tester.pumpAndSettle();
    final after = tester.getRect(copy).top;
    expect(after, greaterThan(before));
    expect(mid, inExclusiveRange(before, after));
    expect(find.byType(KumoBanner), findsOneWidget);
  });

  testWidgets('reduced motion: the error banner appears in one frame', (tester) async {
    await pumpKumo(tester, const _Host(), disableAnimations: true);
    await _open(tester);
    await tester.pumpWidget(
      kumoHarness(const _Host(errorMessage: 'Could not delete example.com.'), disableAnimations: true),
    );
    await tester.pump();
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}

/// Combined opacity of everything between the delete button's label and the dialog.
double _buttonOpacity(WidgetTester tester) {
  var opacity = 1.0;
  final label = find.text('Delete Zone');
  for (final o in tester.widgetList<Opacity>(find.ancestor(of: label, matching: find.byType(Opacity)))) {
    opacity *= o.opacity;
  }
  for (final f in tester.widgetList<FadeTransition>(find.ancestor(of: label, matching: find.byType(FadeTransition)))) {
    opacity *= f.opacity.value;
  }
  return opacity;
}
