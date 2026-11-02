import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import 'settings_scope.dart';

/// Frame for gallery pages: a compact top bar with a back button and the
/// theme switch, a page title, and content capped at a readable width.
class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.maxWidth = 760,
  });

  final String title;
  final String? description;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final canPop = Navigator.of(context).canPop();
    final narrow = context.kumoIsNarrow;
    final gutter = narrow ? KumoSpace.s4 : KumoSpace.s8;
    return Scaffold(
      backgroundColor: kumo.colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sticky top bar, separated from scrolling content by a border.
            DecoratedBox(
              decoration: BoxDecoration(
                color: kumo.colors.canvas,
                border: Border(bottom: BorderSide(color: kumo.colors.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter - KumoSpace.s2, vertical: KumoSpace.s1),
                child: Row(
                  children: [
                    if (canPop)
                      KumoButton(
                        icon: KumoIcons.arrowLeft,
                        shape: KumoButtonShape.square,
                        variant: KumoButtonVariant.ghost,
                        semanticLabel: 'Back',
                        onPress: () => Navigator.of(context).maybePop(),
                      )
                    else
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2),
                          child: Text(
                            'kumo_flutter',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: kumo.code(large: true, weight: KumoTypography.medium),
                          ),
                        ),
                      ),
                    const Spacer(),
                    const ThemeModeButton(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Constrained(
                      maxWidth: maxWidth,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, KumoSpace.s6, gutter, KumoSpace.s6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: KumoSpace.s1_5,
                          children: [
                            KumoText(title, variant: KumoTextVariant.heading, size: KumoTextSize.lg, headingLevel: 1),
                            if (description != null) KumoText(description!, variant: KumoTextVariant.secondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + KumoSpace.s8),
                    sliver: SliverList.list(
                      children: [
                        for (final c in children)
                          _Constrained(
                            maxWidth: maxWidth,
                            child: Padding(padding: EdgeInsets.symmetric(horizontal: gutter), child: c),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child, required this.maxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      );
}
