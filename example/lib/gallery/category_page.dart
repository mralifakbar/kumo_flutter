import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import 'demo.dart';
import 'page_frame.dart';

/// Every demo of one category, each under its component name.
class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});

  final KumoDemoCategory category;

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: category.title,
      description: category.description,
      children: [for (final demo in category.demos) _DemoBlock(demo: demo)],
    );
  }
}

/// One demo opened on its own page.
class DemoPage extends StatelessWidget {
  const DemoPage({super.key, required this.demo});

  final KumoDemo demo;

  @override
  Widget build(BuildContext context) => PageFrame(
    title: demo.title,
    description: demo.description,
    children: [Builder(builder: demo.builder)],
  );
}

class _DemoBlock extends StatelessWidget {
  const _DemoBlock({required this.demo});

  final KumoDemo demo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KumoSpace.s10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            demo.title,
            style: context.kumo.code(
              large: true,
              weight: KumoTypography.medium,
            ),
          ),
          const SizedBox(height: KumoSpace.s1),
          KumoText(demo.description, variant: KumoTextVariant.secondary),
          const SizedBox(height: KumoSpace.s4),
          Builder(builder: demo.builder),
        ],
      ),
    );
  }
}
