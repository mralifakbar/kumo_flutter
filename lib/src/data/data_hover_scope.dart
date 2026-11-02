import 'package:flutter/widgets.dart';

/// Tells descendants that their row is hovered or holds focus, the way
/// Kumo's Tailwind `group` lets a table row reveal a [KumoInlineCopyText]
/// icon. Table and tree rows provide it. Not exported.
class DataHoverScope extends InheritedWidget {
  const DataHoverScope({super.key, required this.active, required super.child});

  final bool active;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<DataHoverScope>()?.active ?? false;

  @override
  bool updateShouldNotify(DataHoverScope oldWidget) => active != oldWidget.active;
}
