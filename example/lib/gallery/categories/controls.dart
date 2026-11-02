import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Checkboxes, radios, switches, sliders, button groups and toggles. Every
/// zone, Worker and setting here is sample data.
final KumoDemoCategory controlsCategory = KumoDemoCategory(
  title: 'Controls',
  description: 'Checkboxes, radios, switches, sliders, button groups and toggles. Settings shown are sample data.',
  icon: KumoIcons.toggleRight,
  demos: [
    KumoDemo(
      title: 'KumoCheckbox',
      description: 'Checked, indeterminate select-all, label first, disabled, error and card checkboxes.',
      docPath: 'doc/components/KumoCheckbox.md',
      builder: (_) => const _CheckboxDemo(),
    ),
    KumoDemo(
      title: 'KumoCheckboxGroup',
      description: 'A legend over checkboxes with live validation, horizontal layout and joined cards.',
      docPath: 'doc/components/KumoCheckboxGroup.md',
      builder: (_) => const _CheckboxGroupDemo(),
    ),
    KumoDemo(
      title: 'KumoRadioGroup',
      description: 'Vertical, horizontal, segmented and card radio groups with arrow-key selection.',
      docPath: 'doc/components/KumoRadioGroup.md',
      builder: (_) => const _RadioDemo(),
    ),
    KumoDemo(
      title: 'KumoSwitch',
      description: 'Draggable switches in three sizes, neutral, disabled, saving and grouped.',
      docPath: 'doc/components/KumoSwitch.md',
      builder: (_) => const _SwitchDemo(),
    ),
    KumoDemo(
      title: 'KumoSlider',
      description: 'Single and range sliders with steps, formatted values, sizes and a disabled state.',
      docPath: 'doc/components/KumoSlider.md',
      builder: (_) => const _SliderDemo(),
    ),
    KumoDemo(
      title: 'KumoButtonGroup',
      description: 'Split buttons with a working menu, in primary and secondary styles and three sizes.',
      docPath: 'doc/components/KumoButtonGroup.md',
      builder: (_) => const _ButtonGroupDemo(),
    ),
    KumoDemo(
      title: 'KumoToggle',
      description: 'Pressed-state buttons for filters and formatting, ghost and outline.',
      docPath: 'doc/components/KumoToggle.md',
      builder: (_) => const _ToggleDemo(),
    ),
    KumoDemo(
      title: 'KumoToggleGroup',
      description: 'Single and multiple selection groups, segmented or ghost, in three sizes.',
      docPath: 'doc/components/KumoToggleGroup.md',
      builder: (_) => const _ToggleGroupDemo(),
    ),
  ],
);

Widget _column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: children,
    );

Widget _start(Widget child) => Align(alignment: AlignmentDirectional.centerStart, child: child);

class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo();

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _purge = true;
  bool _remember = false;
  bool _terms = false;
  bool _card = true;
  final Set<String> _routes = {'api.example.com/*'};
  static const _allRoutes = ['api.example.com/*', 'example.com/images/*', 'example.com/blog/*'];

  @override
  Widget build(BuildContext context) {
    final all = _routes.length == _allRoutes.length;
    return _column([
      DemoSection(
        title: 'Basic',
        child: _start(KumoCheckbox(
          label: 'Purge cache after deploy',
          checked: _purge,
          onCheckedChange: (v) => setState(() => _purge = v),
        )),
      ),
      DemoSection(
        title: 'Indeterminate',
        caption: 'The parent shows a dash while some routes are selected.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KumoCheckbox(
              label: 'All routes',
              checked: all,
              indeterminate: _routes.isNotEmpty && !all,
              onCheckedChange: (v) => setState(() {
                _routes.clear();
                if (v) _routes.addAll(_allRoutes);
              }),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: KumoSpace.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final route in _allRoutes)
                    KumoCheckbox(
                      label: route,
                      checked: _routes.contains(route),
                      onCheckedChange: (v) => setState(() => v ? _routes.add(route) : _routes.remove(route)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Label first',
        child: _start(KumoCheckbox(
          label: 'Remember this device',
          controlFirst: false,
          checked: _remember,
          onCheckedChange: (v) => setState(() => _remember = v),
        )),
      ),
      DemoSection(
        title: 'Description, optional and tooltip',
        child: _start(KumoCheckbox(
          label: 'Email me a weekly usage report',
          description: 'Sent every Monday to the account owner.',
          required: false,
          labelTooltip: 'You can unsubscribe from the email itself',
          checked: _remember,
          onCheckedChange: (v) => setState(() => _remember = v),
        )),
      ),
      DemoSection(
        title: 'Error',
        caption: 'Check the box to clear the error.',
        child: _start(KumoCheckbox(
          label: 'I understand this deletes the R2 bucket assets',
          error: _terms ? null : 'Confirm to continue.',
          checked: _terms,
          onCheckedChange: (v) => setState(() => _terms = v),
        )),
      ),
      const DemoSection(
        title: 'Disabled',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KumoCheckbox(label: 'Managed by your organization', checked: true, disabled: true),
            KumoCheckbox(label: 'Unavailable on the Free plan', checked: false, disabled: true),
          ],
        ),
      ),
      DemoSection(
        title: 'Card',
        child: KumoCheckbox(
          appearance: KumoCheckboxAppearance.card,
          label: 'Bot Fight Mode',
          description: 'Challenge requests that match known bot patterns.',
          checked: _card,
          onCheckedChange: (v) => setState(() => _card = v),
        ),
      ),
    ]);
  }
}

class _CheckboxGroupDemo extends StatefulWidget {
  const _CheckboxGroupDemo();

  @override
  State<_CheckboxGroupDemo> createState() => _CheckboxGroupDemoState();
}

class _CheckboxGroupDemoState extends State<_CheckboxGroupDemo> {
  List<String> _alerts = const ['deploys'];
  List<String> _methods = const ['GET', 'HEAD'];
  List<String> _scan = const ['web'];
  List<String> _scanGrid = const ['web', 'mail'];

  static const _scanItems = [
    KumoCheckboxGroupItem(value: 'web', label: 'Web traffic', description: 'Uploads and downloads through Gateway HTTP policies.'),
    KumoCheckboxGroupItem(value: 'ai', label: 'AI prompts', description: 'Prompts sent to AI apps and their responses.'),
    KumoCheckboxGroupItem(value: 'saas', label: 'SaaS storage', description: 'Files in connected apps and cloud accounts.'),
    KumoCheckboxGroupItem(value: 'mail', label: 'Outbound email', description: 'Email leaving your organization.'),
  ];

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Legend, description and validation',
        caption: 'Uncheck every alert to see the error.',
        child: KumoCheckboxGroup<String>(
          legend: 'Email alerts',
          description: 'Sent to the account owner.',
          error: _alerts.isEmpty ? 'Choose at least one alert.' : null,
          value: _alerts,
          onValueChange: (v) => setState(() => _alerts = v),
          items: const [
            KumoCheckboxGroupItem(value: 'deploys', label: 'Failed Worker deployments'),
            KumoCheckboxGroupItem(value: 'usage', label: 'Usage above 80% of plan limits'),
            KumoCheckboxGroupItem(value: 'tokens', label: 'API tokens expiring this week'),
            KumoCheckboxGroupItem(value: 'billing', label: 'Billing changes', disabled: true),
          ],
        ),
      ),
      DemoSection(
        title: 'Horizontal',
        child: KumoCheckboxGroup<String>(
          legend: 'Cached methods',
          orientation: Axis.horizontal,
          value: _methods,
          onValueChange: (v) => setState(() => _methods = v),
          items: const [
            KumoCheckboxGroupItem(value: 'GET', label: 'GET'),
            KumoCheckboxGroupItem(value: 'HEAD', label: 'HEAD'),
            KumoCheckboxGroupItem(value: 'OPTIONS', label: 'OPTIONS'),
            KumoCheckboxGroupItem(value: 'POST', label: 'POST'),
          ],
        ),
      ),
      DemoSection(
        title: 'Cards',
        child: KumoCheckboxGroup<String>(
          legend: 'Where should this DLP profile scan?',
          appearance: KumoCheckboxAppearance.card,
          value: _scan,
          onValueChange: (v) => setState(() => _scan = v),
          items: _scanItems,
        ),
      ),
      DemoSection(
        title: 'Card grid',
        caption: 'Horizontal card groups use two columns.',
        child: KumoCheckboxGroup<String>(
          legend: 'Where should this DLP profile scan?',
          appearance: KumoCheckboxAppearance.card,
          orientation: Axis.horizontal,
          value: _scanGrid,
          onValueChange: (v) => setState(() => _scanGrid = v),
          items: _scanItems,
        ),
      ),
      DemoSection(
        title: 'Hidden legend',
        caption: 'The legend is still read by screen readers.',
        child: KumoCheckboxGroup<String>(
          legend: 'Cached methods',
          hideLegend: true,
          value: _methods,
          onValueChange: (v) => setState(() => _methods = v),
          items: const [
            KumoCheckboxGroupItem(value: 'GET', label: 'GET'),
            KumoCheckboxGroupItem(value: 'HEAD', label: 'HEAD'),
          ],
        ),
      ),
    ]);
  }
}

class _RadioDemo extends StatefulWidget {
  const _RadioDemo();

  @override
  State<_RadioDemo> createState() => _RadioDemoState();
}

class _RadioDemoState extends State<_RadioDemo> {
  String? _level = 'aggressive';
  String _ssl = 'full';
  String _window = '12';
  String _plan = 'pro';
  String? _region;
  String _position = 'eu';

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Vertical',
        caption: 'Tab into the group, then use the arrow keys.',
        child: KumoRadioGroup<String>(
          legend: 'Caching level',
          description: 'Applies to every route on example.com.',
          value: _level,
          onValueChange: (v) => setState(() => _level = v),
          items: const [
            KumoRadio(value: 'basic', label: 'No query string'),
            KumoRadio(value: 'simplified', label: 'Ignore query string'),
            KumoRadio(value: 'aggressive', label: 'Standard'),
          ],
        ),
      ),
      DemoSection(
        title: 'Horizontal',
        child: KumoRadioGroup<String>(
          legend: 'SSL/TLS mode',
          orientation: Axis.horizontal,
          value: _ssl,
          onValueChange: (v) => setState(() => _ssl = v),
          items: const [
            KumoRadio(value: 'off', label: 'Off'),
            KumoRadio(value: 'flexible', label: 'Flexible'),
            KumoRadio(value: 'full', label: 'Full'),
            KumoRadio(value: 'strict', label: 'Full (strict)'),
          ],
        ),
      ),
      DemoSection(
        title: 'Segmented',
        caption: 'For a few short options on one line.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s4,
          children: [
            KumoRadioGroup<String>(
              legend: 'Time range',
              appearance: KumoRadioAppearance.segmented,
              value: _window,
              onValueChange: (v) => setState(() => _window = v),
              items: const [
                KumoRadio(value: '1', label: '1h'),
                KumoRadio(value: '12', label: '12h'),
                KumoRadio(value: '24', label: '24h'),
                KumoRadio(value: '168', label: '7d'),
              ],
            ),
            KumoRadioGroup<String>(
              legend: 'Disabled item',
              appearance: KumoRadioAppearance.segmented,
              value: _window,
              onValueChange: (v) => setState(() => _window = v),
              items: const [
                KumoRadio(value: '1', label: '1h'),
                KumoRadio(value: '12', label: '12h'),
                KumoRadio(value: '24', label: '24h', disabled: true),
              ],
            ),
            const KumoRadioGroup<String>(
              legend: 'Disabled group',
              appearance: KumoRadioAppearance.segmented,
              disabled: true,
              value: '12',
              items: [
                KumoRadio(value: '1', label: '1h'),
                KumoRadio(value: '12', label: '12h'),
                KumoRadio(value: '24', label: '24h'),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Cards',
        child: KumoRadioGroup<String>(
          legend: 'Plan',
          appearance: KumoRadioAppearance.card,
          value: _plan,
          onValueChange: (v) => setState(() => _plan = v),
          items: const [
            KumoRadio(value: 'free', label: 'Free', description: 'For personal projects and testing.'),
            KumoRadio(value: 'pro', label: 'Pro', description: 'Image optimization and more page rules.'),
            KumoRadio(value: 'business', label: 'Business', description: 'Custom SSL and a 100% uptime SLA.', disabled: true),
          ],
        ),
      ),
      DemoSection(
        title: 'Error',
        caption: 'Pick a region to clear the error.',
        child: KumoRadioGroup<String>(
          legend: 'Data localization region',
          error: _region == null ? 'Choose where logs are stored.' : null,
          value: _region,
          onValueChange: (v) => setState(() => _region = v),
          items: const [
            KumoRadio(value: 'us', label: 'United States'),
            KumoRadio(value: 'eu', label: 'European Union'),
          ],
        ),
      ),
      DemoSection(
        title: 'Control at the end, with descriptions',
        child: KumoRadioGroup<String>(
          legend: 'Log retention',
          controlPosition: KumoRadioControlPosition.end,
          value: _position,
          onValueChange: (v) => setState(() => _position = v),
          items: const [
            KumoRadio(value: 'us', label: '7 days', description: 'Included in every plan.'),
            KumoRadio(value: 'eu', label: '30 days', description: 'Billed per GB stored.'),
          ],
        ),
      ),
    ]);
  }
}

class _SwitchDemo extends StatefulWidget {
  const _SwitchDemo();

  @override
  State<_SwitchDemo> createState() => _SwitchDemoState();
}

class _SwitchDemoState extends State<_SwitchDemo> {
  bool _https = true;
  final Map<KumoSwitchSize, bool> _sizes = {for (final s in KumoSwitchSize.values) s: true};
  bool _neutral = false;
  bool _labelFirst = true;
  bool _proxy = false;
  bool _saving = false;
  bool _failures = true;
  bool _report = false;
  bool _usage = true;

  Future<void> _saveProxy(bool next) async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _proxy = next;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Basic',
        caption: 'Tap, or drag the thumb.',
        child: _start(KumoSwitch(
          label: 'Always use HTTPS',
          checked: _https,
          onCheckedChange: (v) => setState(() => _https = v),
        )),
      ),
      DemoSection(
        title: 'Sizes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final size in KumoSwitchSize.values)
              KumoSwitch(
                label: switch (size) {
                  KumoSwitchSize.sm => 'Small',
                  KumoSwitchSize.base => 'Base (default)',
                  KumoSwitchSize.lg => 'Large',
                },
                size: size,
                checked: _sizes[size]!,
                onCheckedChange: (v) => setState(() => _sizes[size] = v),
              ),
          ],
        ),
      ),
      DemoSection(
        title: 'Neutral',
        caption: 'Monochrome, for settings that should not draw the eye.',
        child: _start(KumoSwitch(
          label: 'Compact table rows',
          variant: KumoSwitchVariant.neutral,
          checked: _neutral,
          onCheckedChange: (v) => setState(() => _neutral = v),
        )),
      ),
      DemoSection(
        title: 'Label first',
        child: _start(KumoSwitch(
          label: 'Development mode',
          controlFirst: false,
          checked: _labelFirst,
          onCheckedChange: (v) => setState(() => _labelFirst = v),
        )),
      ),
      DemoSection(
        title: 'Saving',
        caption: 'Input is ignored while the change is saved.',
        child: _start(KumoSwitch(
          label: _saving ? 'Proxy status (saving)' : 'Proxy status',
          checked: _proxy,
          transitioning: _saving,
          onCheckedChange: _saveProxy,
        )),
      ),
      const DemoSection(
        title: 'Disabled',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KumoSwitch(label: 'Enforced by policy', checked: true, disabled: true),
            KumoSwitch(label: 'Requires Enterprise', checked: false, disabled: true),
          ],
        ),
      ),
      DemoSection(
        title: 'Group',
        child: KumoSwitchGroup(
          legend: 'Notifications',
          description: 'Delivered to the account owner.',
          children: [
            KumoSwitch(label: 'Deploy failures', checked: _failures, onCheckedChange: (v) => setState(() => _failures = v)),
            KumoSwitch(label: 'Weekly usage report', checked: _report, onCheckedChange: (v) => setState(() => _report = v)),
            KumoSwitch(label: 'Usage limit warnings', checked: _usage, onCheckedChange: (v) => setState(() => _usage = v)),
          ],
        ),
      ),
    ]);
  }
}

class _SliderDemo extends StatefulWidget {
  const _SliderDemo();

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  double _ttl = 40;
  KumoSliderRange _latency = (start: 100, end: 400);
  double _retries = 2;
  double _sampling = 0.25;
  double _small = 30;
  double _base = 30;
  double? _committed;

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Basic',
        caption: _committed == null ? 'Drag the thumb or tap the track.' : 'Committed: ${_committed!.round()} minutes',
        child: KumoSlider(
          label: 'Edge cache TTL (minutes)',
          value: _ttl,
          onValueChange: (v) => setState(() => _ttl = v),
          onValueCommitted: (v) => setState(() => _committed = v),
        ),
      ),
      DemoSection(
        title: 'Range',
        child: KumoSlider.range(
          label: 'Response time (ms)',
          values: _latency,
          max: 1000,
          step: 10,
          largeStep: 100,
          thumbSemanticLabel: (i) => i == 0 ? 'Minimum response time' : 'Maximum response time',
          onValuesChange: (v) => setState(() => _latency = v),
        ),
      ),
      DemoSection(
        title: 'Custom range and step',
        child: KumoSlider(
          label: 'Retry attempts',
          value: _retries,
          max: 5,
          onValueChange: (v) => setState(() => _retries = v),
        ),
      ),
      DemoSection(
        title: 'Formatted values',
        child: KumoSlider(
          label: 'Log sampling rate',
          value: _sampling,
          min: 0,
          max: 1,
          step: 0.05,
          largeStep: 0.25,
          format: (v) => '${(v * 100).round()}%',
          onValueChange: (v) => setState(() => _sampling = v),
        ),
      ),
      DemoSection(
        title: 'Sizes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s6,
          children: [
            KumoSlider(label: 'Small', size: KumoSliderSize.sm, value: _small, onValueChange: (v) => setState(() => _small = v)),
            KumoSlider(label: 'Base', value: _base, onValueChange: (v) => setState(() => _base = v)),
          ],
        ),
      ),
      const DemoSection(
        title: 'Disabled',
        child: KumoSlider(label: 'Locked by plan', value: 70, disabled: true),
      ),
    ]);
  }
}

class _ButtonGroupDemo extends StatefulWidget {
  const _ButtonGroupDemo();

  @override
  State<_ButtonGroupDemo> createState() => _ButtonGroupDemoState();
}

class _ButtonGroupDemoState extends State<_ButtonGroupDemo> {
  String? _openMenu;
  String _last = 'Nothing run yet';

  void _run(String action) => setState(() {
        _openMenu = null;
        _last = action;
      });

  Widget _split({
    required String id,
    required String label,
    required List<String> actions,
    KumoButtonVariant variant = KumoButtonVariant.primary,
    KumoButtonSize size = KumoButtonSize.base,
  }) {
    return KumoButtonGroup(
      semanticLabel: label,
      variant: variant,
      size: size,
      children: [
        KumoButtonGroupButton(label: label, onPress: () => _run(label)),
        KumoAnchoredOverlay(
          open: _openMenu == id,
          align: KumoAlign.end,
          trapFocus: true,
          onDismiss: () => setState(() => _openMenu = null),
          overlayBuilder: (context, _) => KumoMenuPanel(
            children: [for (final a in actions) KumoMenuRow(label: a, onPress: () => _run(a))],
          ),
          child: KumoButtonGroupButton(
            icon: KumoIcons.caretDown,
            semanticLabel: 'More ${label.toLowerCase()} options',
            onPress: () => setState(() => _openMenu = _openMenu == id ? null : id),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _column([
      KumoText('Last action: $_last', variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
      DemoSection(
        title: 'Split button',
        child: _start(_split(
          id: 'deploy',
          label: 'Deploy',
          actions: const ['Deploy to staging', 'Deploy and tail logs', 'Schedule deploy'],
        )),
      ),
      DemoSection(
        title: 'Secondary',
        child: _start(_split(
          id: 'save',
          label: 'Save',
          variant: KumoButtonVariant.secondary,
          actions: const ['Save as draft', 'Save and publish', 'Save a copy'],
        )),
      ),
      DemoSection(
        title: 'Sizes',
        child: Wrap(
          spacing: KumoSpace.s4,
          runSpacing: KumoSpace.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final size in [KumoButtonSize.sm, KumoButtonSize.base, KumoButtonSize.lg])
              _split(
                id: 'size-${size.name}',
                label: 'Deploy',
                size: size,
                actions: const ['Deploy to staging', 'Schedule deploy'],
              ),
          ],
        ),
      ),
      DemoSection(
        title: 'Joined actions',
        child: _start(KumoButtonGroup(
          semanticLabel: 'Worker version',
          children: [
            KumoButtonGroupButton(label: 'Roll back', icon: KumoIcons.arrowCounterClockwise, onPress: () => _run('Roll back')),
            KumoButtonGroupButton(label: 'Promote', onPress: () => _run('Promote')),
            const KumoButtonGroupButton(label: 'Delete', variant: KumoButtonVariant.secondaryDestructive),
          ],
        )),
      ),
    ]);
  }
}

class _ToggleDemo extends StatefulWidget {
  const _ToggleDemo();

  @override
  State<_ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<_ToggleDemo> {
  bool _errorsOnly = false;
  bool _wrap = true;
  bool _bold = true;
  bool _italic = false;

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Toggle',
        child: Wrap(
          spacing: KumoSpace.s2,
          runSpacing: KumoSpace.s2,
          children: [
            KumoToggle(
              icon: KumoIcons.funnel,
              label: 'Errors only',
              variant: KumoToggleVariant.outline,
              pressed: _errorsOnly,
              onPressedChange: (v) => setState(() => _errorsOnly = v),
            ),
            KumoToggle(
              label: 'Wrap lines',
              pressed: _wrap,
              onPressedChange: (v) => setState(() => _wrap = v),
            ),
            KumoToggle(
              icon: KumoIcons.textB,
              semanticLabel: 'Bold',
              pressed: _bold,
              onPressedChange: (v) => setState(() => _bold = v),
            ),
            KumoToggle(
              icon: KumoIcons.textItalic,
              title: 'Italic',
              pressed: _italic,
              onPressedChange: (v) => setState(() => _italic = v),
            ),
            const KumoToggle(label: 'Disabled', pressed: false, disabled: true),
          ],
        ),
      ),
    ]);
  }
}

class _ToggleGroupDemo extends StatefulWidget {
  const _ToggleGroupDemo();

  @override
  State<_ToggleGroupDemo> createState() => _ToggleGroupDemoState();
}

class _ToggleGroupDemoState extends State<_ToggleGroupDemo> {
  String? _view = 'list';
  String? _level = 'all';
  List<String> _methods = const ['GET'];
  List<String> _format = const ['bold'];
  final Map<KumoToggleSize, String?> _sizes = {for (final s in KumoToggleSize.values) s: 'day'};

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Single selection',
        caption: 'Tab into the group, move with the arrow keys, press Space to choose.',
        child: _start(KumoToggleGroup<String>(
          semanticLabel: 'Layout',
          value: _view,
          allowDeselect: false,
          onValueChange: (v) => setState(() => _view = v),
          items: const [
            KumoToggleGroupItem(value: 'list', icon: KumoIcons.rows, semanticLabel: 'List view'),
            KumoToggleGroupItem(value: 'grid', icon: KumoIcons.squaresFour, semanticLabel: 'Grid view'),
            KumoToggleGroupItem(value: 'table', icon: KumoIcons.table, semanticLabel: 'Table view'),
          ],
        )),
      ),
      DemoSection(
        title: 'Optional single selection',
        caption: 'Press the selected level again to clear it.',
        child: _start(KumoToggleGroup<String>(
          semanticLabel: 'Log level',
          value: _level,
          onValueChange: (v) => setState(() => _level = v),
          items: const [
            KumoToggleGroupItem(value: 'all', label: 'All'),
            KumoToggleGroupItem(value: 'warn', label: 'Warnings'),
            KumoToggleGroupItem(value: 'error', label: 'Errors'),
          ],
        )),
      ),
      DemoSection(
        title: 'Multiple selection',
        child: _start(KumoToggleGroup<String>.multiple(
          semanticLabel: 'HTTP methods',
          values: _methods,
          onValuesChange: (v) => setState(() => _methods = v),
          items: const [
            KumoToggleGroupItem(value: 'GET', label: 'GET'),
            KumoToggleGroupItem(value: 'POST', label: 'POST'),
            KumoToggleGroupItem(value: 'PUT', label: 'PUT'),
            KumoToggleGroupItem(value: 'DELETE', label: 'DELETE'),
          ],
        )),
      ),
      DemoSection(
        title: 'Ghost group',
        caption: 'Separate toggles, for toolbars.',
        child: _start(KumoToggleGroup<String>.multiple(
          semanticLabel: 'Text formatting',
          variant: KumoToggleVariant.ghost,
          values: _format,
          onValuesChange: (v) => setState(() => _format = v),
          items: const [
            KumoToggleGroupItem(value: 'bold', icon: KumoIcons.textB, title: 'Bold'),
            KumoToggleGroupItem(value: 'italic', icon: KumoIcons.textItalic, title: 'Italic'),
            KumoToggleGroupItem(value: 'underline', icon: KumoIcons.textUnderline, title: 'Underline'),
            KumoToggleGroupItem(value: 'code', icon: KumoIcons.code, title: 'Code', disabled: true),
          ],
        )),
      ),
      DemoSection(
        title: 'Sizes',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            for (final size in KumoToggleSize.values)
              KumoToggleGroup<String>(
                semanticLabel: 'Chart interval, ${size.name}',
                size: size,
                value: _sizes[size],
                onValueChange: (v) => setState(() => _sizes[size] = v),
                items: const [
                  KumoToggleGroupItem(value: 'hour', label: 'Hour'),
                  KumoToggleGroupItem(value: 'day', label: 'Day'),
                  KumoToggleGroupItem(value: 'week', label: 'Week'),
                ],
              ),
          ],
        ),
      ),
    ]);
  }
}
