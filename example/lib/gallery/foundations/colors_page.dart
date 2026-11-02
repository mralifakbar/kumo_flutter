import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../page_frame.dart';

/// Every semantic color token with its value and, for text tokens, the
/// contrast against the base surface.
class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  static const _groups = <(String, String, List<KumoColor>)>[
    ('Text', 'Contrast shown against the base surface.', [
      KumoColor.textDefault, KumoColor.textStrong, KumoColor.textSubtle, KumoColor.textPlaceholder, //
      KumoColor.textInactive, KumoColor.textLink, KumoColor.textSuccess, KumoColor.textDanger, KumoColor.textWarning,
    ]),
    ('Surfaces', 'From the app canvas up to floating overlays.', [
      KumoColor.canvas, KumoColor.elevated, KumoColor.recessed, KumoColor.base, KumoColor.tint, //
      KumoColor.control, KumoColor.fill, KumoColor.overlay, KumoColor.contrast,
    ]),
    ('Lines and focus', 'Rings, dividers and focus.', [
      KumoColor.line, KumoColor.hairline, KumoColor.interact, KumoColor.focus,
    ]),
    ('Brand and status', 'Primary action blue and status accents with their tints.', [
      KumoColor.brand, KumoColor.brandHover, KumoColor.info, KumoColor.infoTint, KumoColor.success, //
      KumoColor.successTint, KumoColor.warning, KumoColor.warningTint, KumoColor.danger, KumoColor.dangerTint,
    ]),
    ('Badges', 'Badge backgrounds.', [
      KumoColor.badgeNeutral, KumoColor.badgeBlue, KumoColor.badgeGreen, KumoColor.badgeOrange, //
      KumoColor.badgeRed, KumoColor.badgePurple, KumoColor.badgeTeal, KumoColor.badgeInverted,
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Colors',
      description: 'Kumo defines these tokens in OKLCH; the values below are the sRGB colors this theme renders.',
      children: [
        for (final (title, caption, tokens) in _groups) ...[
          KumoText(title, variant: KumoTextVariant.heading, headingLevel: 2),
          const SizedBox(height: KumoSpace.s1),
          KumoText(caption, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
          const SizedBox(height: KumoSpace.s3),
          KumoLayerCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < tokens.length; i++) ...[
                  if (i > 0) SizedBox(height: 1, child: ColoredBox(color: context.kumo.colors.hairline)),
                  _TokenRow(token: tokens[i], isText: title == 'Text'),
                ],
              ],
            ),
          ),
          const SizedBox(height: KumoSpace.s8),
        ],
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.token, required this.isText});

  final KumoColor token;
  final bool isText;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final color = kumo.color(token);
    final hex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    final alpha = (color.a * 100).round();
    final ratio = isText
        ? KumoColorUtils.contrastRatio(KumoColorUtils.over(color, kumo.colors.base), kumo.colors.base)
        : null;
    return Semantics(
      label: '${token.name}, $hex${alpha < 100 ? ', $alpha percent opacity' : ''}'
          '${ratio != null ? ', contrast ${ratio.toStringAsFixed(1)} to 1' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s4, vertical: KumoSpace.s2_5),
        child: Row(
          spacing: KumoSpace.s3,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isText ? kumo.colors.base : color,
                borderRadius: BorderRadius.circular(KumoRadius.md),
                border: KumoRing.inset(kumo.colors.line),
              ),
              alignment: Alignment.center,
              child: isText ? Text('Aa', style: kumo.text(weight: KumoTypography.medium).copyWith(color: color)) : null,
            ),
            Expanded(child: Text(token.name, style: kumo.code())),
            Text(alpha < 100 ? '$hex  $alpha%' : hex, style: kumo.code(color: KumoColor.textSubtle)),
            if (ratio != null)
              SizedBox(
                width: 52,
                child: Text(
                  '${ratio.toStringAsFixed(1)}:1',
                  textAlign: TextAlign.end,
                  style: kumo.text(size: KumoTextSize.sm, color: KumoColor.textSubtle).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
