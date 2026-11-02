import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

late KumoToastManager _toasts;

/// A toaster over a page with one button that grabs the manager.
class _Host extends StatelessWidget {
  const _Host({this.limit = 3, this.manager});

  final int limit;
  final KumoToastManager? manager;

  @override
  Widget build(BuildContext context) {
    return KumoToaster(
      limit: limit,
      manager: manager,
      child: Builder(
        builder: (context) {
          _toasts = KumoToast.of(context);
          return const Center(child: Text('Dashboard'));
        },
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  Size size = kumoPhoneSize,
  int limit = 3,
  bool reduce = false,
  Brightness brightness = Brightness.light,
}) => pumpKumo(
  tester,
  _Host(limit: limit),
  center: false,
  size: size,
  disableAnimations: reduce,
  brightness: brightness,
);

Finder _surfaceOf(String title) => find.ancestor(of: find.text(title), matching: find.byType(DecoratedBox)).last;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('renders every variant in ${brightness.name} mode', (tester) async {
      await _pumpHost(tester, brightness: brightness, limit: 5);
      for (final v in KumoToastVariant.values) {
        _toasts.add(title: 'Toast ${v.name}', description: 'Sample description', variant: v);
      }
      await tester.pumpAndSettle();
      expect(find.text('Toast info'), findsOneWidget);
      expect(find.byIcon(KumoIcons.checkCircleFill), findsOneWidget);
      expect(find.byIcon(KumoIcons.warningOctagonFill), findsOneWidget);
      expect(find.byIcon(KumoIcons.warningFill), findsOneWidget);
      expect(find.byIcon(KumoIcons.infoFill), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('enters from the bottom edge and closes after 5 seconds', (tester) async {
    await _pumpHost(tester);
    _toasts.add(title: 'Cache purged', description: 'example.com serves fresh content.');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final entering = tester.getTopLeft(find.text('Cache purged')).dy;
    await tester.pumpAndSettle();
    final rest = tester.getTopLeft(find.text('Cache purged')).dy;
    expect(entering, greaterThan(rest));

    await tester.pump(const Duration(milliseconds: 4800));
    expect(find.text('Cache purged'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 30));
    expect(tester.getTopLeft(find.text('Cache purged')).dy, greaterThan(rest), reason: 'leaves the way it came');
    await tester.pumpAndSettle();
    expect(find.text('Cache purged'), findsNothing);
  });

  testWidgets('a zero timeout keeps the toast until it is closed', (tester) async {
    await _pumpHost(tester);
    final id = _toasts.add(title: 'Deploying image-resizer', timeout: Duration.zero);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Deploying image-resizer'), findsOneWidget);
    _toasts.close(id);
    await tester.pumpAndSettle();
    expect(find.text('Deploying image-resizer'), findsNothing);
  });

  testWidgets('the close button closes it and fires onClose once', (tester) async {
    var closed = 0;
    await _pumpHost(tester);
    _toasts.add(title: 'Token created', onClose: () => closed++);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Token created'), findsNothing);
    expect(closed, 1);
  });

  testWidgets('actions run, and closesToast closes the toast', (tester) async {
    var undone = 0;
    var support = 0;
    await _pumpHost(tester);
    _toasts.add(
      title: 'DNS record deleted',
      actions: [
        KumoToastAction(label: 'Contact support', onPress: () => support++),
        KumoToastAction(label: 'Undo', onPress: () => undone++, closesToast: true, variant: KumoButtonVariant.primary),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contact support'));
    await tester.pumpAndSettle();
    expect(support, 1);
    expect(find.text('DNS record deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('DNS record deleted'), findsNothing);
  });

  testWidgets('hovering pauses the timer and leaving resumes it', (tester) async {
    await _pumpHost(tester, size: kumoDesktopSize);
    _toasts.add(title: 'Settings saved');
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Settings saved')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Settings saved'), findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Settings saved'), findsNothing);
  });

  testWidgets('the same id bumps the toast instead of stacking a copy', (tester) async {
    await _pumpHost(tester);
    _toasts.add(id: 'copied', title: 'Copied to clipboard');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    _toasts.add(id: 'copied', title: 'Copied to clipboard');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final bump = tester
        .widgetList<Transform>(find.ancestor(of: find.text('Copied to clipboard'), matching: find.byType(Transform)))
        .map((t) => t.transform.getMaxScaleOnAxis())
        .reduce((a, b) => a > b ? a : b);
    expect(bump, greaterThan(1.01));
    expect(bump, lessThan(1.03));
    await tester.pumpAndSettle();
    expect(find.text('Copied to clipboard'), findsOneWidget);
    expect(_toasts.ids, hasLength(1));
    // The repeat restarted the timer.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('stacks newest in front and hides toasts past the limit', (tester) async {
    await _pumpHost(tester, size: kumoDesktopSize);
    for (var i = 1; i <= 4; i++) {
      _toasts.add(title: 'Toast $i', timeout: Duration.zero);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final front = tester.getRect(_surfaceOf('Toast 4'));
    final second = tester.getRect(_surfaceOf('Toast 3'));
    expect(second.top, closeTo(front.top - 12, 1), reason: 'peeks 12px above the front toast');
    expect(second.width, lessThan(front.width));
    Opacity outer(String title) =>
        tester.widget<Opacity>(find.ancestor(of: find.text(title), matching: find.byType(Opacity)).last);
    expect(outer('Toast 1').opacity, 0, reason: 'over the limit of 3');

    _toasts.close(_toasts.ids.last);
    await tester.pumpAndSettle();
    expect(outer('Toast 1').opacity, 1, reason: 'a slot freed up');
  });

  testWidgets('hovering the stack fans the toasts out', (tester) async {
    await _pumpHost(tester, size: kumoDesktopSize);
    _toasts.add(title: 'First toast', timeout: Duration.zero);
    _toasts.add(title: 'Second toast', timeout: Duration.zero);
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Second toast')));
    await tester.pumpAndSettle();
    final front = tester.getRect(_surfaceOf('Second toast'));
    final back = tester.getRect(_surfaceOf('First toast'));
    expect(back.bottom, closeTo(front.top - 12, 1));
    expect(back.width, front.width);
  });

  testWidgets('a downward flick dismisses; a short drag springs back', (tester) async {
    await _pumpHost(tester);
    _toasts.add(title: 'Worker deployed', timeout: Duration.zero);
    await tester.pumpAndSettle();
    final rest = tester.getTopLeft(find.text('Worker deployed'));
    await tester.drag(find.text('Worker deployed'), const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Worker deployed')), rest);

    final gesture = await tester.startGesture(tester.getCenter(find.text('Worker deployed')));
    await gesture.moveBy(const Offset(0, 10));
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Worker deployed')).dy, closeTo(rest.dy + 25, 11), reason: 'follows the finger');
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.fling(find.text('Worker deployed'), const Offset(0, 60), 1200);
    await tester.pumpAndSettle();
    expect(find.text('Worker deployed'), findsNothing);
  });

  testWidgets('a flick toward the end edge dismisses', (tester) async {
    await _pumpHost(tester);
    _toasts.add(title: 'Zone paused', timeout: Duration.zero);
    await tester.pumpAndSettle();
    await tester.fling(find.text('Zone paused'), const Offset(120, 0), 1500);
    await tester.pumpAndSettle();
    expect(find.text('Zone paused'), findsNothing);
  });

  testWidgets('swiping up resists and returns', (tester) async {
    await _pumpHost(tester);
    _toasts.add(title: 'Zone paused', timeout: Duration.zero);
    await tester.pumpAndSettle();
    final rest = tester.getTopLeft(find.text('Zone paused')).dy;
    final gesture = await tester.startGesture(tester.getCenter(find.text('Zone paused')));
    await gesture.moveBy(const Offset(0, -10));
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    expect(rest - tester.getTopLeft(find.text('Zone paused')).dy, lessThan(100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Zone paused')).dy, rest);
  });

  testWidgets('update and promise change a toast in place', (tester) async {
    await _pumpHost(tester);
    final id = _toasts.add(title: 'Deploying image-resizer', variant: KumoToastVariant.info, timeout: Duration.zero);
    await tester.pumpAndSettle();
    _toasts.update(id, (toast) => toast.copyWith(title: 'image-resizer deployed', variant: KumoToastVariant.success));
    await tester.pumpAndSettle();
    expect(find.text('image-resizer deployed'), findsOneWidget);
    expect(find.byIcon(KumoIcons.checkCircleFill), findsOneWidget);
    _toasts.closeAll();
    await tester.pumpAndSettle();

    final done = _toasts.promise<String>(
      Future<String>.delayed(const Duration(seconds: 2), () => 'image-resizer'),
      loading: const KumoToastData(title: 'Deploying'),
      success: (name) => KumoToastData(title: '$name is live', variant: KumoToastVariant.success),
      error: (e) => const KumoToastData(title: 'Deployment failed', variant: KumoToastVariant.error),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deploying'), findsOneWidget);
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Deploying'), findsNothing);
    expect(find.text('image-resizer is live'), findsOneWidget);
    expect(await done, 'image-resizer');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('image-resizer is live'), findsNothing, reason: 'the success toast times out normally');
  });

  testWidgets('a failed promise shows the error toast', (tester) async {
    await _pumpHost(tester);
    Object? caught;
    final pending = _toasts
        .promise<void>(
          Future<void>.delayed(const Duration(seconds: 1), () => throw StateError('quota exceeded')),
          loading: const KumoToastData(title: 'Uploading assets'),
          success: (_) => const KumoToastData(title: 'Uploaded'),
          error: (e) => const KumoToastData(title: 'Upload failed', variant: KumoToastVariant.error),
        )
        .catchError((Object e) => caught = e);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await pending;
    expect(find.text('Upload failed'), findsOneWidget);
    expect(caught, isA<StateError>());
  });

  group('layout', () {
    testWidgets('spans the bottom with 16px gutters on a phone', (tester) async {
      await _pumpHost(tester);
      _toasts.add(title: 'Cache purged', timeout: Duration.zero);
      await tester.pumpAndSettle();
      final rect = tester.getRect(_surfaceOf('Cache purged'));
      expect(rect.left, 16);
      expect(rect.width, kumoPhoneSize.width - 32);
      expect(rect.bottom, kumoPhoneSize.height - 16);
    });

    testWidgets('sits 340px wide in the bottom right corner on desktop', (tester) async {
      await _pumpHost(tester, size: kumoDesktopSize);
      _toasts.add(title: 'Cache purged', timeout: Duration.zero);
      await tester.pumpAndSettle();
      final rect = tester.getRect(_surfaceOf('Cache purged'));
      expect(rect.width, 340);
      expect(rect.right, kumoDesktopSize.width - 32);
      expect(rect.bottom, kumoDesktopSize.height - 32);
    });

    testWidgets('mirrors to the bottom left in RTL', (tester) async {
      await pumpKumo(tester, const _Host(), center: false, size: kumoDesktopSize, textDirection: TextDirection.rtl);
      _toasts.add(title: 'Cache purged', timeout: Duration.zero);
      await tester.pumpAndSettle();
      expect(tester.getRect(_surfaceOf('Cache purged')).left, 32);
    });

    testWidgets('rises above the keyboard', (tester) async {
      tester.view.viewInsets = FakeViewPadding(bottom: 300 * tester.view.devicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await _pumpHost(tester);
      _toasts.add(title: 'Cache purged', timeout: Duration.zero);
      await tester.pumpAndSettle();
      final insets = MediaQuery.viewInsetsOf(tester.element(find.text('Dashboard')));
      expect(tester.getRect(_surfaceOf('Cache purged')).bottom, kumoPhoneSize.height - insets.bottom - 16);
    });

    testWidgets('2x text at 390px does not overflow', (tester) async {
      await pumpKumo(tester, const _Host(), center: false, textScale: 2);
      _toasts.add(
        title: 'Deployment failed',
        description: 'image-resizer exceeded its CPU limit during startup.',
        variant: KumoToastVariant.error,
        actions: [KumoToastAction(label: 'View logs', onPress: () {})],
        timeout: Duration.zero,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('each toast is a live region with a labeled close button', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpHost(tester);
    _toasts.add(title: 'Token created', timeout: Duration.zero);
    await tester.pumpAndSettle();
    final region = find.ancestor(
      of: find.text('Token created'),
      matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true),
    );
    final node = tester.getSemantics(region);
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('reduced motion fades without sliding', (tester) async {
    await _pumpHost(tester, reduce: true);
    _toasts.add(title: 'Cache purged', timeout: Duration.zero);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final entering = tester.getTopLeft(find.text('Cache purged')).dy;
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Cache purged')).dy, entering);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a manager made outside the tree can raise toasts', (tester) async {
    final manager = KumoToastManager();
    addTearDown(manager.dispose);
    await pumpKumo(tester, _Host(manager: manager), center: false);
    manager.add(title: 'Raised from a repository', timeout: Duration.zero);
    await tester.pumpAndSettle();
    expect(find.text('Raised from a repository'), findsOneWidget);
  });

  testWidgets('KumoToast.of explains a missing toaster', (tester) async {
    late BuildContext captured;
    await pumpKumo(
      tester,
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );
    expect(() => KumoToast.of(captured), throwsA(isA<FlutterError>()));
    expect(KumoToast.maybeOf(captured), isNull);
  });

  testWidgets('KumoToast renders a standalone surface', (tester) async {
    var closed = false;
    await pumpKumo(
      tester,
      SizedBox(
        width: 340,
        child: KumoToast(title: 'Worker deployed', variant: KumoToastVariant.success, onClose: () => closed = true),
      ),
    );
    await tester.tap(find.byIcon(KumoIcons.x));
    expect(closed, isTrue);
  });

  group('motion', () {
    // The toast behind slides and grows into the front slot from where it
    // is; it used to lose its state and re-enter from the bottom edge.
    testWidgets('the stack closes up when a toast leaves', (tester) async {
      await _pumpHost(tester, size: kumoDesktopSize);
      _toasts.add(title: 'Older toast', timeout: Duration.zero);
      _toasts.add(title: 'Newer toast', timeout: Duration.zero);
      await tester.pumpAndSettle();
      final behind = tester.getRect(_surfaceOf('Older toast'));
      _toasts.close(_toasts.ids.last);
      await tester.pumpAndSettle();
      final front = tester.getRect(_surfaceOf('Older toast'));
      // Bring the stack back and close the front one again, sampling mid-flight.
      _toasts.add(title: 'Newer toast', timeout: Duration.zero);
      await tester.pumpAndSettle();
      _toasts.close(_toasts.ids.last);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final moving = tester.getRect(_surfaceOf('Older toast'));
      expect(moving.top, greaterThan(behind.top));
      expect(moving.top, lessThan(front.top));
      expect(moving.width, greaterThan(behind.width));
      expect(moving.width, lessThan(front.width));
      await tester.pumpAndSettle();
      expect(tester.getRect(_surfaceOf('Older toast')).top, closeTo(front.top, 0.5));
    });

    testWidgets('an update in place cross-fades the message', (tester) async {
      await _pumpHost(tester);
      final id = _toasts.add(title: 'Deploying image-resizer', timeout: Duration.zero);
      await tester.pumpAndSettle();
      _toasts.update(id, (toast) => toast.copyWith(title: 'image-resizer deployed', variant: KumoToastVariant.success));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      double fade(String text) => tester
          .widget<FadeTransition>(find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first)
          .opacity
          .value;
      final incoming = fade('image-resizer deployed');
      final outgoing = fade('Deploying image-resizer');
      expect(incoming, greaterThan(0));
      expect(incoming, lessThan(1));
      expect(outgoing, greaterThan(0));
      expect(outgoing, lessThan(1));
      await tester.pumpAndSettle();
      expect(find.text('Deploying image-resizer'), findsNothing);
    });

    testWidgets('reduced motion: an update swaps at once', (tester) async {
      await _pumpHost(tester, reduce: true);
      final id = _toasts.add(title: 'Deploying image-resizer', timeout: Duration.zero);
      await tester.pumpAndSettle();
      _toasts.update(id, (toast) => toast.copyWith(title: 'image-resizer deployed'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Deploying image-resizer'), findsNothing);
      expect(find.text('image-resizer deployed'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
