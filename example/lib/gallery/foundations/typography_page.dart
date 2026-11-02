import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../page_frame.dart';

/// The Kumo type scale rendered with the bundled fonts.
class TypographyPage extends StatelessWidget {
  const TypographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final rows = <(String, String, TextStyle)>[
      (
        'Page title',
        'heading, size lg, 20/28 semibold',
        kumo.heading(size: KumoHeadingSize.lg),
      ),
      ('Section heading', 'heading, 16/24 semibold', kumo.heading()),
      (
        'Content text for body, buttons and data',
        'body, 14/21 regular',
        kumo.text(),
      ),
      (
        'Emphasis inside content',
        'body bold, 14/21 medium',
        kumo.text(weight: KumoTypography.medium),
      ),
      (
        'Secondary rows and metadata',
        'secondary, 13 regular',
        kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle),
      ),
      (
        'Captions',
        'xs, 12 regular',
        kumo.text(size: KumoTextSize.xs, color: KumoColor.textSubtle),
      ),
      ('image-resizer.workers.dev', 'mono, 13 regular', kumo.code()),
    ];
    return PageFrame(
      title: 'Typography',
      description:
          'Inter for text, JetBrains Mono for code. Content is 14px; 16px and up is for headings.',
      children: [
        KumoLayerCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  SizedBox(
                    height: 1,
                    child: ColoredBox(color: kumo.colors.hairline),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KumoSpace.s5,
                    vertical: KumoSpace.s4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: KumoSpace.s1,
                    children: [
                      Text(rows[i].$1, style: rows[i].$3),
                      KumoText(
                        rows[i].$2,
                        variant: KumoTextVariant.monoSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KumoSpace.s8),
        const KumoText(
          'Rules',
          variant: KumoTextVariant.heading,
          headingLevel: 2,
        ),
        const SizedBox(height: KumoSpace.s2),
        for (final rule in const [
          'Headings are sentence case and semibold. Kumo never uses bold (700).',
          'Letter spacing stays at the font default.',
          'Inline monospace is set about 1px smaller than the text around it.',
          'Related text sits closer together than the content it belongs to.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: KumoSpace.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s2,
              children: [
                const SizedBox(
                  height: 21,
                  child: Center(
                    child: KumoIcon(
                      KumoIcons.check,
                      size: 14,
                      color: KumoColor.textSubtle,
                    ),
                  ),
                ),
                Expanded(child: KumoText(rule)),
              ],
            ),
          ),
      ],
    );
  }
}
