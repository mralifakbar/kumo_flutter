import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../helpers/harness.dart';

void main() {
  test('initials come from the first and last words', () {
    expect(KumoAvatar.initialsOf('Ada Lovelace'), 'AL');
    expect(KumoAvatar.initialsOf('Grace Brewster Hopper'), 'GH');
    expect(KumoAvatar.initialsOf('image-resizer'), 'IR');
    expect(KumoAvatar.initialsOf('ada'), 'A');
    expect(KumoAvatar.initialsOf('  '), '');
    expect(KumoAvatar.initialsOf('ops@example.com'), 'O');
    expect(KumoAvatar.initialsOf('ada.lovelace@example.com'), 'AL');
  });

  testWidgets('sizes, shapes and statuses render in light and dark', (tester) async {
    for (final b in Brightness.values) {
      await pumpKumo(
        tester,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in KumoAvatarSize.values)
              for (final shape in KumoAvatarShape.values) ...[
                KumoAvatar(name: 'Ada Lovelace', size: s, shape: shape),
                for (final st in KumoAvatarStatus.values)
                  KumoAvatar(name: 'Ada Lovelace', size: s, shape: shape, status: st),
                KumoAvatar(size: s, shape: shape),
              ],
          ],
        ),
        brightness: b,
      );
      expect(tester.takeException(), isNull);
    }
    for (final s in KumoAvatarSize.values) {
      await pumpKumo(tester, KumoAvatar(name: 'Ada', size: s));
      expect(tester.getSize(find.byType(KumoAvatar)), Size.square(s.dimension));
    }
  });

  testWidgets('no name shows a person glyph, never a generated face', (tester) async {
    await pumpKumo(tester, const KumoAvatar());
    expect(find.byIcon(KumoIcons.user), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an image that fails to load falls back to the initials', (tester) async {
    await pumpKumo(tester, KumoAvatar(name: 'Grace Hopper', image: MemoryImage(Uint8List.fromList([0, 1, 2, 3]))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('GH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reads as the name plus the status', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoAvatar(name: 'Ada Lovelace', status: KumoAvatarStatus.away));
    expect(tester.getSemantics(find.byType(KumoAvatar)), matchesSemantics(label: 'Ada Lovelace, Away'));
    await pumpKumo(
      tester,
      const KumoAvatar(name: 'Ada Lovelace', status: KumoAvatarStatus.away, statusLabel: 'Ausente'),
    );
    expect(tester.getSemantics(find.byType(KumoAvatar)), matchesSemantics(label: 'Ada Lovelace, Ausente'));
    handle.dispose();
  });

  const team = [
    KumoAvatar(name: 'Ada Lovelace'),
    KumoAvatar(name: 'Grace Hopper'),
    KumoAvatar(name: 'Alan Turing'),
    KumoAvatar(name: 'Katherine Johnson'),
    KumoAvatar(name: 'Edsger Dijkstra'),
  ];

  testWidgets('group shows max avatars and a +N chip, overlapping by a quarter', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpKumo(tester, const KumoAvatarGroup(avatars: team, max: 3));
    expect(find.text('AL'), findsOneWidget);
    expect(find.text('AT'), findsOneWidget);
    expect(find.text('KJ'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    // 32 + 3 * 24
    expect(tester.getSize(find.byType(KumoAvatarGroup)).width, 104);
    expect(
      tester.getSemantics(find.byType(KumoAvatarGroup)),
      matchesSemantics(label: 'Ada Lovelace, Grace Hopper, Alan Turing and 2 more'),
    );
    await pumpKumo(tester, const KumoAvatarGroup(avatars: team));
    expect(find.textContaining('+'), findsNothing);
    handle.dispose();
  });

  testWidgets('RTL overlaps toward the left', (tester) async {
    await pumpKumo(tester, const KumoAvatarGroup(avatars: team, max: 2), textDirection: TextDirection.rtl);
    expect(tester.getCenter(find.text('AL')).dx, greaterThan(tester.getCenter(find.text('GH')).dx));
  });

  testWidgets('a pressable overflow chip fires and has a 44px touch target', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpKumo(tester, KumoAvatarGroup(avatars: team, max: 2, onOverflowPress: () => taps++));
    expect(tester.getSize(find.byType(KumoPressable)), const Size(44, 44));
    await tester.tap(find.text('+3'));
    expect(taps, 1);
    expect(find.bySemanticsLabel('Show 3 more'), findsOneWidget);
    expect(find.bySemanticsLabel('Ada Lovelace'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('2x text keeps initials inside the avatar', (tester) async {
    await pumpKumo(tester, const KumoAvatarGroup(avatars: team, max: 3, size: KumoAvatarSize.sm), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(KumoAvatar).first), const Size(24, 24));
  });
}
