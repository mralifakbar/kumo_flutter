import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

/// One live example in the gallery.
class KumoDemo {
  const KumoDemo({
    required this.title,
    required this.description,
    required this.builder,
    this.docPath,
  });

  /// Component name as it appears in code, such as `KumoButton`.
  final String title;

  /// One sentence on what the demo shows.
  final String description;
  final WidgetBuilder builder;

  /// Path of the matching reference page under `doc/components/`.
  final String? docPath;
}

/// A group of demos shown as one section of the gallery.
class KumoDemoCategory {
  const KumoDemoCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.demos,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<KumoDemo> demos;
}

/// Standard frame for one scenario inside a demo: a heading, an optional
/// caption and the live widget.
class DemoSection extends StatelessWidget {
  const DemoSection({super.key, required this.title, required this.child, this.caption});

  final String title;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        KumoText(title, variant: KumoTextVariant.heading),
        if (caption != null) ...[
          const SizedBox(height: KumoSpace.s1),
          KumoText(caption!, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
        ],
        const SizedBox(height: KumoSpace.s3),
        child,
      ],
    );
  }
}
