import 'package:flutter/widgets.dart';

/// One entry in the option list of a [KumoSelect], [KumoCombobox] or
/// [KumoAutocomplete]: a [KumoSelectOption], a [KumoSelectGroup] of options
/// under a heading, or a [KumoSelectSeparator].
///
/// ```dart
/// const options = <KumoSelectItem<String>>[
///   KumoSelectOption(value: 'enam', label: 'Eastern North America'),
///   KumoSelectSeparator(),
///   KumoSelectGroup(label: 'Europe', options: [
///     KumoSelectOption(value: 'weur', label: 'Western Europe'),
///   ]),
/// ];
/// ```
@immutable
sealed class KumoSelectItem<T> {
  const KumoSelectItem();
}

/// A choosable option (Kumo's `Select.Option`, `Combobox.Item`).
///
/// [value] is what the field reports; [label] is what it shows. Values are
/// compared with `==`, so use values with value equality (strings, enums,
/// records, or classes that override `==`).
///
/// ```dart
/// const KumoSelectOption(
///   value: 'wnam',
///   label: 'Western North America',
///   description: 'Los Angeles, Seattle',
///   icon: KumoIcons.globeHemisphereWest,
/// )
/// ```
class KumoSelectOption<T> extends KumoSelectItem<T> {
  const KumoSelectOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
    this.disabled = false,
    this.keywords = const [],
  });

  final T value;
  final String label;

  /// Secondary line under the label.
  final String? description;
  final IconData? icon;

  /// Shown but not choosable. Keyboard highlight skips it.
  final bool disabled;

  /// Extra terms the default filter matches, such as a region code.
  final List<String> keywords;

  /// Options whose value and label are the same string.
  ///
  /// ```dart
  /// KumoSelectOption.fromLabels(['production', 'staging', 'preview'])
  /// ```
  static List<KumoSelectOption<String>> fromLabels(Iterable<String> labels) =>
      [for (final l in labels) KumoSelectOption<String>(value: l, label: l)];
}

/// Options under a heading (Kumo's `Select.Group` + `Select.GroupLabel`).
///
/// ```dart
/// const KumoSelectGroup(label: 'Asia Pacific', options: [
///   KumoSelectOption(value: 'apac', label: 'Asia Pacific'),
///   KumoSelectOption(value: 'oc', label: 'Oceania'),
/// ])
/// ```
class KumoSelectGroup<T> extends KumoSelectItem<T> {
  const KumoSelectGroup({required this.label, required this.options});

  final String label;
  final List<KumoSelectOption<T>> options;
}

/// A hairline between options (Kumo's `Select.Separator`).
class KumoSelectSeparator<T> extends KumoSelectItem<T> {
  const KumoSelectSeparator();
}

/// Decides whether [option] matches what the user typed. [query] is the raw
/// input text and is never empty when the filter runs.
typedef KumoOptionFilter<T> = bool Function(KumoSelectOption<T> option, String query);

/// The filter Kumo's combobox and autocomplete use by default: a case
/// insensitive substring match on the label and keywords.
bool kumoContainsFilter<T>(KumoSelectOption<T> option, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (option.label.toLowerCase().contains(q)) return true;
  for (final k in option.keywords) {
    if (k.toLowerCase().contains(q)) return true;
  }
  return false;
}
