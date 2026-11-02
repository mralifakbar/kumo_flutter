import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import 'categories.dart';
import 'category_page.dart';
import 'foundations/colors_page.dart';
import 'foundations/icons_page.dart';
import 'foundations/typography_page.dart';
import 'nav_list.dart';
import 'page_frame.dart';
import '../sample/console_app.dart';

/// Gallery start page: foundations, then every component category.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final demoCount = galleryCategories.fold<int>(0, (n, c) => n + c.demos.length);
    return PageFrame(
      title: 'Kumo for Flutter',
      description: 'An unofficial port of Cloudflare\'s Kumo design system. $demoCount live demos, light and dark.',
      children: [
        const _SectionTitle('Sample app'),
        NavList(entries: [
          NavEntry(
            title: 'Edge console',
            description: 'Workers, deployments and DNS built from kumo_flutter. Sample data.',
            icon: KumoIcons.browser,
            onPress: () => _push(context, const ConsoleApp()),
          ),
        ]),
        const SizedBox(height: KumoSpace.s8),
        const _SectionTitle('Foundations'),
        NavList(entries: [
          NavEntry(
            title: 'Colors',
            description: 'The 54 semantic tokens in light and dark, with contrast ratios.',
            icon: KumoIcons.palette,
            onPress: () => _push(context, const ColorsPage()),
          ),
          NavEntry(
            title: 'Typography',
            description: 'Inter and JetBrains Mono on the Kumo scale.',
            icon: KumoIcons.textAa,
            onPress: () => _push(context, const TypographyPage()),
          ),
          NavEntry(
            title: 'Icons',
            description: '1,530 Phosphor icons in regular and fill, searchable.',
            icon: KumoIcons.shapes,
            onPress: () => _push(context, const IconsPage()),
          ),
        ]),
        const SizedBox(height: KumoSpace.s8),
        const _SectionTitle('Components'),
        NavList(entries: [
          for (final c in galleryCategories)
            NavEntry(
              title: c.title,
              description: c.description,
              icon: c.icon,
              count: c.demos.length,
              onPress: () => _push(context, CategoryPage(category: c)),
            ),
        ]),
        const SizedBox(height: KumoSpace.s8),
        const KumoText(
          'Not affiliated with or endorsed by Cloudflare. All resource names and numbers in this app are sample data.',
          variant: KumoTextVariant.secondary,
          size: KumoTextSize.sm,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: KumoSpace.s3),
        child: KumoText(text, variant: KumoTextVariant.heading, headingLevel: 2),
      );
}
