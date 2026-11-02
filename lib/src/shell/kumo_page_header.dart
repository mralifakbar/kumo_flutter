import 'package:flutter/widgets.dart';

import '../navigation/kumo_tabs.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Gap between the header's sections.
enum KumoPageHeaderSpacing {
  /// 4px (`gap-1`).
  compact(4),

  /// 8px (`gap-2`), the default.
  base(8),

  /// 16px (`gap-4`), for more prominent headers.
  relaxed(16);

  const KumoPageHeaderSpacing(this.gap);
  final double gap;
}

/// One tab in [KumoPageHeader.tabs] (Kumo's `TabsItem`).
@immutable
class KumoPageHeaderTab {
  const KumoPageHeaderTab({required this.label, required this.value});

  final String label;
  final String value;
}

/// Kumo's `PageHeader` block: breadcrumbs above a page title and
/// description, then a row of tabs with the page actions.
///
/// Below 640px of width the actions move under the title (or under the
/// tabs) and wrap, and the tabs scroll sideways.
///
/// ```dart
/// KumoPageHeader(
///   breadcrumbs: myBreadcrumbs,
///   title: 'image-resizer',
///   description: 'Resizes and converts images at the edge.',
///   tabs: const [
///     KumoPageHeaderTab(label: 'Overview', value: 'overview'),
///     KumoPageHeaderTab(label: 'Settings', value: 'settings'),
///   ],
///   value: tab,
///   onValueChange: (v) => setState(() => tab = v),
///   actions: [KumoButton(label: 'Edit code', icon: KumoIcons.code, onPress: () {})],
/// )
/// ```
class KumoPageHeader extends StatelessWidget {
  const KumoPageHeader({
    super.key,
    this.breadcrumbs,
    this.title,
    this.description,
    this.tabs,
    this.value,
    this.onValueChange,
    this.actions = const [],
    this.spacing = KumoPageHeaderSpacing.base,
    this.narrowBreakpoint = KumoBreakpoints.sm,
  });

  /// Breadcrumb trail, drawn above a bottom border.
  final Widget? breadcrumbs;

  /// Page title: 30px semibold, announced as the level 1 heading.
  final String? title;

  /// One or two sentences on what the page is for.
  final String? description;

  /// Section tabs, drawn as a segmented [KumoTabs].
  final List<KumoPageHeaderTab>? tabs;

  /// Selected tab value. Defaults to the first tab.
  final String? value;
  final ValueChanged<String>? onValueChange;

  /// Page actions. They sit at the end of the tab row, or beside the title
  /// when there are no tabs.
  final List<Widget> actions;
  final KumoPageHeaderSpacing spacing;

  /// Widths below this stack the actions under the title or tabs.
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    final hasTabs = tabs != null && tabs!.isNotEmpty;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < narrowBreakpoint;
      Widget? actionBar;
      if (actions.isNotEmpty) {
        actionBar = Wrap(
          spacing: KumoSpace.s2,
          runSpacing: KumoSpace.s2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );
      }

      Widget? titleBlock;
      if (title != null || description != null) {
        titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s2,
          children: [
            if (title != null)
              Semantics(
                header: true,
                headingLevel: 1,
                child: Text(title!, style: kumo.heading(size: KumoHeadingSize.h1)),
              ),
            if (description != null)
              ConstrainedBox(
                // Tailwind's `max-w-prose` (65ch).
                constraints: const BoxConstraints(maxWidth: 560),
                child: Text(description!, style: kumo.text(color: KumoColor.textSubtle)),
              ),
          ],
        );
        if (actionBar != null && !hasTabs) {
          titleBlock = narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KumoSpace.s3,
                  children: [titleBlock, actionBar],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KumoSpace.s4,
                  children: [Expanded(child: titleBlock), actionBar],
                );
        }
        titleBlock = Padding(
          padding: const EdgeInsetsDirectional.only(start: KumoSpace.s3, top: KumoSpace.s3, bottom: KumoSpace.s3),
          child: titleBlock,
        );
      }

      Widget? tabRow;
      if (hasTabs) {
        final strip = KumoTabs(
          tabs: [for (final t in tabs!) KumoTab(value: t.value, label: t.label)],
          value: value ?? tabs!.first.value,
          // Read-only tabs still need a tap action for the tab role; without
          // a callback a press simply changes nothing.
          onValueChange: onValueChange ?? (_) {},
        );
        final Widget row;
        if (actionBar == null) {
          row = Align(alignment: AlignmentDirectional.centerStart, child: strip);
        } else if (narrow) {
          row = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [strip, actionBar],
          );
        } else {
          row = Row(
            spacing: KumoSpace.s4,
            children: [Flexible(child: strip), const Spacer(), actionBar],
          );
        }
        tabRow = Container(
          padding: const EdgeInsetsDirectional.only(start: KumoSpace.s3, top: KumoSpace.s1, bottom: KumoSpace.s3),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
          child: row,
        );
      } else if (actionBar != null && titleBlock == null) {
        tabRow = Padding(
          padding: const EdgeInsetsDirectional.only(start: KumoSpace.s3, top: KumoSpace.s1, bottom: KumoSpace.s3),
          child: actionBar,
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: spacing.gap,
        children: [
          if (breadcrumbs != null)
            DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
              child: breadcrumbs,
            ),
          ?titleBlock,
          ?tabRow,
        ],
      );
    });
  }
}
