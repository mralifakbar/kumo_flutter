import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Reveals [child] from the top as [sizeFactor] goes from 0 to 1, keeping the
/// child at its full size and clipping it, like a vertical [SizeTransition]
/// pinned to the top edge.
///
/// Kept in house because SizeTransition's alignment parameter changed name
/// across the Flutter versions this package supports.
class KumoSizeReveal extends AnimatedWidget {
  const KumoSizeReveal({super.key, required Animation<double> sizeFactor, required this.child})
    : super(listenable: sizeFactor);

  final Widget child;

  Animation<double> get sizeFactor => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final factor = sizeFactor.value;
    return ClipRect(
      child: Align(alignment: AlignmentDirectional.topStart, heightFactor: math.max(factor, 0), child: child),
    );
  }
}
