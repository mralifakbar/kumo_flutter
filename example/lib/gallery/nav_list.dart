import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

/// One destination in a [NavList].
class NavEntry {
  const NavEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.onPress,
    this.count,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onPress;

  /// Number of demos behind the row, shown as subtle trailing text.
  final int? count;
}

/// A grouped list of destinations inside one layer card, rows separated by
/// hairlines.
class NavList extends StatelessWidget {
  const NavList({super.key, required this.entries});

  final List<NavEntry> entries;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) {
        rows.add(
          SizedBox(height: 1, child: ColoredBox(color: kumo.colors.hairline)),
        );
      }
      rows.add(_NavRow(entry: entries[i]));
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kumo.colors.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(kumo.colors.line),
        boxShadow: KumoShadow.xs.boxShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.entry});

  final NavEntry entry;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    return KumoPressable(
      onPress: entry.onPress,
      scaleOnPress: false,
      semanticLabel: entry.title,
      semanticHint: entry.description,
      excludeChildSemantics: true,
      builder: (context, state) => Container(
        color: state.active ? kumo.colors.tint : null,
        padding: const EdgeInsets.symmetric(
          horizontal: KumoSpace.s4,
          vertical: KumoSpace.s3,
        ),
        child: Row(
          spacing: KumoSpace.s3,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kumo.colors.recessed,
                borderRadius: BorderRadius.circular(KumoRadius.md),
              ),
              child: Center(
                child: KumoIcon(entry.icon, color: KumoColor.textSubtle),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s0_5,
                children: [
                  KumoText(entry.title, bold: true),
                  KumoText(
                    entry.description,
                    variant: KumoTextVariant.secondary,
                    size: KumoTextSize.sm,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            if (entry.count != null)
              KumoText(
                '${entry.count}',
                variant: KumoTextVariant.secondary,
                size: KumoTextSize.sm,
                tabularNumbers: true,
              ),
            const KumoIcon(KumoIcons.caretRight, color: KumoColor.textSubtle),
          ],
        ),
      ),
    );
  }
}
