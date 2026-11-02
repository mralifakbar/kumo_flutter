import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

const _steps = [
  KumoStepsItem(title: 'Add site', description: 'example.com'),
  KumoStepsItem(title: 'Review DNS records'),
  KumoStepsItem(title: 'Change nameservers'),
];

class _Stepper extends StatefulWidget {
  const _Stepper({this.linear = true, this.onComplete, this.errorOnSecond = false});

  final bool linear;
  final VoidCallback? onComplete;
  final bool errorOnSecond;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  int step = 0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: KumoStepper(
      value: step,
      linear: widget.linear,
      onValueChange: (v) => setState(() => step = v),
      completeLabel: 'Activate zone',
      onComplete: widget.onComplete,
      steps: [
        const KumoStepperStep(title: 'Add site', child: Text('Enter your domain')),
        KumoStepperStep(
          title: 'Review DNS records',
          state: widget.errorOnSecond ? KumoStepsState.error : null,
          canContinue: !widget.errorOnSecond,
          child: const Text('12 records found'),
        ),
        const KumoStepperStep(title: 'Change nameservers', child: Text('Update at your registrar')),
      ],
    ),
  );
}

void main() {
  for (final b in Brightness.values) {
    for (final o in KumoStepsOrientation.values) {
      testWidgets('KumoSteps $o renders in $b', (tester) async {
        await pumpKumo(
          tester,
          const KumoSteps(steps: _steps, current: 1),
          brightness: b,
          size: kumoDesktopSize,
        );
        await pumpKumo(
          tester,
          KumoSteps(steps: _steps, current: 1, orientation: o),
          brightness: b,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('states have distinct markers, not color alone', (tester) async {
    await pumpKumo(
      tester,
      const KumoSteps(
        current: 1,
        steps: [
          KumoStepsItem(title: 'Add site'),
          KumoStepsItem(title: 'Review DNS records'),
          KumoStepsItem(title: 'Change nameservers'),
          KumoStepsItem(title: 'Verify', state: KumoStepsState.error),
        ],
      ),
      size: kumoDesktopSize,
    );
    expect(find.byIcon(KumoIcons.check), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(KumoIcons.x), findsOneWidget);
  });

  testWidgets('auto: horizontal on desktop, vertical on phone', (tester) async {
    await pumpKumo(tester, const KumoSteps(steps: _steps, current: 0), size: kumoDesktopSize);
    final a = tester.getTopLeft(find.text('Add site'));
    final b = tester.getTopLeft(find.text('Review DNS records'));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));
    await pumpKumo(tester, const KumoSteps(steps: _steps, current: 0));
    final c = tester.getTopLeft(find.text('Add site'));
    final d = tester.getTopLeft(find.text('Review DNS records'));
    expect(d.dy, greaterThan(c.dy));
    expect(d.dx, c.dx);
  });

  testWidgets('semantics: step label carries state and position', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoSteps(steps: _steps, current: 1), size: kumoDesktopSize);
    expect(find.bySemanticsLabel('Add site, Completed'), findsOneWidget);
    expect(find.bySemanticsLabel('Review DNS records, Current step'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Change nameservers, Not started')),
      containsSemantics(value: 'Step 3 of 3'),
    );
    handle.dispose();
  });

  testWidgets('onStepPress makes steps pressable', (tester) async {
    final pressed = <int>[];
    await pumpKumo(
      tester,
      KumoSteps(steps: _steps, current: 2, onStepPress: pressed.add),
      size: kumoDesktopSize,
    );
    await tester.tap(find.text('Add site'));
    expect(pressed, [0]);
  });

  testWidgets('KumoStepper: continue, back, complete (horizontal)', (tester) async {
    var done = 0;
    await pumpKumo(tester, _Stepper(onComplete: () => done++), size: kumoDesktopSize);
    expect(find.text('Enter your domain'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('12 records found'), findsOneWidget);
    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your domain'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Activate zone'));
    expect(done, 1);
  });

  testWidgets('KumoStepper: linear blocks jumping ahead, allows going back', (tester) async {
    await pumpKumo(tester, const _Stepper(), size: kumoDesktopSize);
    await tester.tap(find.text('Change nameservers'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your domain'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add site'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your domain'), findsOneWidget);
  });

  testWidgets('KumoStepper: error step blocks Continue', (tester) async {
    await pumpKumo(tester, const _Stepper(errorOnSecond: true, linear: false), size: kumoDesktopSize);
    await tester.tap(find.text('Review DNS records'));
    await tester.pumpAndSettle();
    expect(find.byIcon(KumoIcons.x), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('12 records found'), findsOneWidget);
  });

  testWidgets('KumoStepper vertical on phone: content opens under the current step', (tester) async {
    await pumpKumo(tester, const _Stepper());
    expect(find.text('Enter your domain'), findsOneWidget);
    expect(find.text('12 records found'), findsNothing);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('12 records found'), findsOneWidget);
    expect(find.text('Enter your domain'), findsNothing);
    final title = tester.getTopLeft(find.text('Review DNS records'));
    final body = tester.getTopLeft(find.text('12 records found'));
    expect(body.dy, greaterThan(title.dy));
  });

  testWidgets('keyboard: Tab reaches buttons, Enter continues', (tester) async {
    await pumpKumo(tester, const _Stepper(), size: kumoDesktopSize);
    // Previous is disabled, so the first stop is Next.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('12 records found'), findsOneWidget);
  });

  testWidgets('reduced motion and text scale 2 at 390px', (tester) async {
    await pumpKumo(tester, const _Stepper(), disableAnimations: true, textScale: 2);
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(find.text('12 records found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advancing fills the connector from the start and lands the check', (tester) async {
    await pumpKumo(tester, const _Stepper(), size: kumoDesktopSize);
    expect(_fill(tester), 0);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final mid = _fill(tester);
    expect(mid, inExclusiveRange(0.05, 0.95));
    final fill = tester.getRect(find.byKey(const ValueKey('kumo-steps-connector-fill')).first);
    final track = tester.getRect(
      find
          .ancestor(of: find.byKey(const ValueKey('kumo-steps-connector-fill')).first, matching: find.byType(Align))
          .first,
    );
    expect(fill.left, track.left, reason: 'grows from the start');
    final scale = tester
        .widget<ScaleTransition>(
          find.ancestor(of: find.byIcon(KumoIcons.check), matching: find.byType(ScaleTransition)),
        )
        .scale
        .value;
    expect(scale, inExclusiveRange(0.5, 1.2));
    expect(scale, isNot(1));

    // Stepping back mid-flight drains it from where it is.
    await tester.tap(find.text('Previous'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final back = _fill(tester);
    expect(back, lessThan(mid + 0.15));
    expect(back, greaterThan(0));
    await tester.pumpAndSettle();
    expect(_fill(tester), 0);
    expect(find.byIcon(KumoIcons.check), findsNothing);
  });

  testWidgets('stepper content eases to the new height while it cross-fades', (tester) async {
    await pumpKumo(tester, StatefulBuilder(builder: (context, setState) => _TallStepper()), size: kumoDesktopSize);
    final before = tester.getTopLeft(find.text('Previous')).dy;
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final mid = tester.getTopLeft(find.text('Previous')).dy;
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Previous')).dy;
    expect(after, greaterThan(before + 50));
    expect(mid, inExclusiveRange(before, after));
  });

  testWidgets('reduced motion: connector, check and content land in one frame', (tester) async {
    await pumpKumo(tester, const _Stepper(), size: kumoDesktopSize, disableAnimations: true);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump();
    expect(_fill(tester), 1);
    expect(find.text('Enter your domain'), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });
}

class _TallStepper extends StatefulWidget {
  @override
  State<_TallStepper> createState() => _TallStepperState();
}

class _TallStepperState extends State<_TallStepper> {
  int step = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 900,
    child: KumoStepper(
      value: step,
      onValueChange: (v) => setState(() => step = v),
      orientation: KumoStepsOrientation.horizontal,
      steps: const [
        KumoStepperStep(
          title: 'Add site',
          child: SizedBox(height: 40, child: Text('Short')),
        ),
        KumoStepperStep(
          title: 'Review DNS records',
          child: SizedBox(height: 200, child: Text('Tall')),
        ),
      ],
    ),
  );
}

/// How far the first connector is filled, 0 to 1.
double _fill(WidgetTester tester) {
  final fill = find.byKey(const ValueKey('kumo-steps-connector-fill')).first;
  final track = find.ancestor(of: fill, matching: find.byType(Align)).first;
  return tester.getSize(fill).width / tester.getSize(track).width;
}
