import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Text fields and the parts around them. Every name, token and value here
/// is sample data.
final KumoDemoCategory formsCategory = KumoDemoCategory(
  title: 'Forms',
  description: 'Text inputs, textareas, input groups, secrets, numbers, one-time codes, labels and fields.',
  icon: KumoIcons.textbox,
  demos: [
    KumoDemo(
      title: 'KumoInput',
      description: 'Sizes, label, description, error, optional and tooltip labels, icons and keyboard types.',
      docPath: 'doc/components/KumoInput.md',
      builder: (_) => const _InputDemo(),
    ),
    KumoDemo(
      title: 'KumoInputArea',
      description: 'Fixed rows, a textarea that grows with its content, errors and monospace.',
      docPath: 'doc/components/KumoInputArea.md',
      builder: (_) => const _InputAreaDemo(),
    ),
    KumoDemo(
      title: 'KumoInputGroup',
      description: 'Icon and text addons, an inline suffix, compact buttons and an attached action button.',
      docPath: 'doc/components/KumoInputGroup.md',
      builder: (_) => const _InputGroupDemo(),
    ),
    KumoDemo(
      title: 'KumoSensitiveInput',
      description: 'A masked token that reveals on tap, hides on blur or Escape, and copies.',
      docPath: 'doc/components/KumoSensitiveInput.md',
      builder: (_) => const _SensitiveInputDemo(),
    ),
    KumoDemo(
      title: 'KumoNumberInput',
      description: 'Steppers that repeat while held, arrow keys, bounds, decimals and invalid input.',
      docPath: 'doc/components/KumoNumberInput.md',
      builder: (_) => const _NumberInputDemo(),
    ),
    KumoDemo(
      title: 'KumoInputOtp',
      description: 'One-time codes: grouped cells, paste to fill, a masked PIN and letter codes.',
      docPath: 'doc/components/KumoInputOtp.md',
      builder: (_) => const _InputOtpDemo(),
    ),
    KumoDemo(
      title: 'KumoLabel',
      description: 'Plain, optional, tooltip and translated labels.',
      docPath: 'doc/components/KumoLabel.md',
      builder: (_) => const _LabelDemo(),
    ),
    KumoDemo(
      title: 'KumoField',
      description: 'A label, description and error around any control.',
      docPath: 'doc/components/KumoField.md',
      builder: (_) => const _FieldDemo(),
    ),
  ],
);

class _Stack extends StatelessWidget {
  const _Stack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s4, children: children);
}

class _Sections extends StatelessWidget {
  const _Sections({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: KumoSpace.s8, children: children);
}

final _workerName = RegExp(r'^[a-z0-9-]*$');
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _InputDemo extends StatefulWidget {
  const _InputDemo();

  @override
  State<_InputDemo> createState() => _InputDemoState();
}

class _InputDemoState extends State<_InputDemo> {
  String _name = 'image-resizer';
  String _email = 'billing@example';
  String _query = '';
  String _password = '';
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final nameError = _workerName.hasMatch(_name) ? null : 'Use lowercase letters, numbers and dashes only.';
    final emailError = _email.isEmpty || _emailPattern.hasMatch(_email)
        ? null
        : 'Enter an email address like you@example.com.';
    return _Sections(
      children: [
        DemoSection(
          title: 'Label and description',
          caption: 'Controlled: the description shows the value the parent holds.',
          child: KumoInput(
            label: 'Worker name',
            description: nameError == null ? 'Deploys to $_name.example.workers.dev' : null,
            error: nameError,
            placeholder: 'image-resizer',
            mono: true,
            value: _name,
            onValueChange: (v) => setState(() => _name = v),
          ),
        ),
        DemoSection(
          title: 'Sizes',
          child: _Stack(
            children: [
              for (final s in KumoFieldSize.values)
                KumoInput(size: s, label: '${s.name} (${s.height.toInt()}px)', placeholder: 'example.com'),
            ],
          ),
        ),
        DemoSection(
          title: 'Error',
          caption: 'The error replaces the description, turns the ring red and is announced.',
          child: KumoInput(
            label: 'Billing email',
            description: 'Invoices for this account go here.',
            error: emailError,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            value: _email,
            onValueChange: (v) => setState(() => _email = v),
          ),
        ),
        const DemoSection(
          title: 'Optional and tooltip',
          child: _Stack(
            children: [
              KumoInput(label: 'Phone number', showOptional: true, placeholder: '+1 555 0100'),
              KumoInput(
                label: 'Account ID',
                labelTooltip: 'Find it in the dashboard URL after /accounts/',
                placeholder: '023e105f4ecef8ad9ca31a8372d0c353',
                mono: true,
              ),
              KumoInput(label: 'Zone name', required: true, placeholder: 'example.com'),
            ],
          ),
        ),
        DemoSection(
          title: 'Icons and keyboard types',
          child: _Stack(
            children: [
              KumoInput(
                semanticLabel: 'Search Workers',
                placeholder: 'Search Workers',
                leadingIcon: KumoIcons.magnifyingGlass,
                value: _query,
                onValueChange: (v) => setState(() => _query = v),
                trailing: _query.isEmpty
                    ? null
                    : KumoButton(
                        icon: KumoIcons.x,
                        shape: KumoButtonShape.square,
                        size: KumoButtonSize.xs,
                        variant: KumoButtonVariant.ghost,
                        semanticLabel: 'Clear search',
                        onPress: () => setState(() => _query = ''),
                      ),
              ),
              KumoInput(
                label: 'Password',
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.password],
                value: _password,
                onValueChange: (v) => setState(() => _password = v),
                trailing: KumoButton(
                  icon: _showPassword ? KumoIcons.eyeSlash : KumoIcons.eye,
                  shape: KumoButtonShape.square,
                  size: KumoButtonSize.xs,
                  variant: KumoButtonVariant.ghost,
                  semanticLabel: _showPassword ? 'Hide password' : 'Show password',
                  onPress: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const KumoInput(
                label: 'Origin URL',
                keyboardType: TextInputType.url,
                placeholder: 'https://origin.example.com',
              ),
              const KumoInput(label: 'TTL in seconds', keyboardType: TextInputType.number, placeholder: '3600'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Password managers',
          caption: 'passwordManagerIgnore keeps autofill away from a field that is not a login.',
          child: KumoInput(
            label: 'Webhook secret',
            obscureText: true,
            passwordManagerIgnore: true,
            placeholder: 'whsec_...',
          ),
        ),
        const DemoSection(
          title: 'Disabled and read-only',
          child: _Stack(
            children: [
              KumoInput(label: 'Account', disabled: true, value: 'Sample account'),
              KumoInput(label: 'Zone ID', readOnly: true, mono: true, value: '9a7806061c88ada191ed06f989cc3dac'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputAreaDemo extends StatefulWidget {
  const _InputAreaDemo();

  @override
  State<_InputAreaDemo> createState() => _InputAreaDemoState();
}

class _InputAreaDemoState extends State<_InputAreaDemo> {
  String _notes = 'Resize images on the fly.\n\nRoll back if p99 latency rises.';
  String _message = 'Hi';

  @override
  Widget build(BuildContext context) {
    return _Sections(
      children: [
        DemoSection(
          title: 'Grows with its content',
          caption: 'autoResize from 2 to 8 rows, then it scrolls.',
          child: KumoInputArea(
            label: 'Deployment notes',
            description: '${_notes.length} characters',
            autoResize: true,
            minRows: 2,
            maxRows: 8,
            value: _notes,
            onValueChange: (v) => setState(() => _notes = v),
          ),
        ),
        const DemoSection(
          title: 'Fixed rows',
          child: _Stack(
            children: [
              KumoInputArea(label: '2 rows', rows: 2, placeholder: 'A short note'),
              KumoInputArea(label: '4 rows', rows: 4, placeholder: 'A longer description'),
            ],
          ),
        ),
        DemoSection(
          title: 'Error',
          child: KumoInputArea(
            label: 'Support message',
            error: _message.trim().length < 10 ? 'Write at least 10 characters so support can help.' : null,
            description: 'Describe what you expected and what happened.',
            value: _message,
            onValueChange: (v) => setState(() => _message = v),
          ),
        ),
        const DemoSection(
          title: 'Sizes, monospace, optional',
          child: _Stack(
            children: [
              KumoInputArea(size: KumoFieldSize.sm, label: 'Small', placeholder: 'Small text'),
              KumoInputArea(
                label: 'Worker script',
                labelTooltip: 'An ES module with a default fetch handler',
                mono: true,
                rows: 4,
                placeholder: 'export default {\n  async fetch(request) {\n    return new Response("ok");\n  },\n};',
              ),
              KumoInputArea(label: 'Reviewer notes', showOptional: true, placeholder: 'Anything to flag'),
            ],
          ),
        ),
        const DemoSection(
          title: 'Disabled',
          child: KumoInputArea(label: 'Archived notes', disabled: true, value: 'This Worker was retired.'),
        ),
      ],
    );
  }
}

enum _Availability { idle, checking, available, taken }

class _InputGroupDemo extends StatefulWidget {
  const _InputGroupDemo();

  @override
  State<_InputGroupDemo> createState() => _InputGroupDemoState();
}

class _InputGroupDemoState extends State<_InputGroupDemo> {
  String _subdomain = 'image-resizer';
  _Availability _availability = _Availability.available;
  Timer? _timer;
  String _search = 'cache';
  bool _showPassword = false;
  String _lastSearch = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _check(String v) {
    _timer?.cancel();
    setState(() {
      _subdomain = v;
      _availability = v.isEmpty ? _Availability.idle : _Availability.checking;
    });
    if (v.isEmpty) return;
    // Sample rule: names starting with "api" are taken.
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _availability = v.startsWith('api') ? _Availability.taken : _Availability.available);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = switch (_availability) {
      _Availability.idle => null,
      _Availability.checking => const KumoLoader(size: KumoLoaderSize.sm, semanticLabel: 'Checking availability'),
      _Availability.available => const KumoIcon(
        KumoIcons.checkCircleFill,
        color: KumoColor.textSuccess,
        semanticLabel: 'Available',
      ),
      _Availability.taken => const KumoIcon(KumoIcons.xCircleFill, color: KumoColor.textDanger, semanticLabel: 'Taken'),
    };
    return _Sections(
      children: [
        DemoSection(
          title: 'Inline suffix with status',
          caption: 'The suffix follows the typed value. Sample rule: names starting with "api" are taken.',
          child: KumoInputGroup(
            label: 'Subdomain',
            description: _availability == _Availability.available ? '$_subdomain.workers.dev is available.' : null,
            error: _availability == _Availability.taken ? '$_subdomain.workers.dev is taken. Try another name.' : null,
            children: [
              KumoInputGroupInput(value: _subdomain, maxLength: 40, onValueChange: _check),
              const KumoInputGroupSuffix('.workers.dev'),
              if (status != null) KumoInputGroupAddon(align: KumoInputGroupAlign.end, child: status),
            ],
          ),
        ),
        const DemoSection(
          title: 'Icon and text addons',
          child: _Stack(
            children: [
              KumoInputGroup(
                children: [
                  KumoInputGroupAddon(icon: KumoIcons.link),
                  KumoInputGroupInput(semanticLabel: 'Link', placeholder: 'Paste a link'),
                ],
              ),
              KumoInputGroup(
                children: [
                  KumoInputGroupAddon(text: '/api/'),
                  KumoInputGroupInput(semanticLabel: 'API path', placeholder: 'endpoint'),
                  KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '.json'),
                ],
              ),
              KumoInputGroup(
                children: [
                  KumoInputGroupInput(semanticLabel: 'Email local part', placeholder: 'alerts'),
                  KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '@example.com'),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Buttons',
          caption: 'Ghost buttons sit inside an addon; a solid button attaches to the end.',
          child: _Stack(
            children: [
              KumoInputGroup(
                label: 'Database password',
                children: [
                  KumoInputGroupInput(obscureText: !_showPassword, value: 'sample-password'),
                  KumoInputGroupAddon(
                    align: KumoInputGroupAlign.end,
                    child: KumoInputGroupButton(
                      icon: _showPassword ? KumoIcons.eyeSlash : KumoIcons.eye,
                      semanticLabel: _showPassword ? 'Hide password' : 'Show password',
                      onPress: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ],
              ),
              KumoInputGroup(
                description: _lastSearch.isEmpty ? null : 'Searched for "$_lastSearch" (sample, no results loaded).',
                children: [
                  const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                  KumoInputGroupInput(
                    semanticLabel: 'Search rules',
                    placeholder: 'Search rules',
                    value: _search,
                    onValueChange: (v) => setState(() => _search = v),
                    onSubmitted: (v) => setState(() => _lastSearch = v),
                  ),
                  if (_search.isNotEmpty)
                    KumoInputGroupAddon(
                      align: KumoInputGroupAlign.end,
                      child: KumoInputGroupButton(
                        icon: KumoIcons.x,
                        semanticLabel: 'Clear search',
                        onPress: () => setState(() => _search = ''),
                      ),
                    ),
                  KumoInputGroupButton(
                    label: 'Search',
                    variant: KumoButtonVariant.secondary,
                    onPress: () => setState(() => _lastSearch = _search),
                  ),
                ],
              ),
              KumoInputGroup(
                children: [
                  const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                  const KumoInputGroupInput(semanticLabel: 'Query', placeholder: 'status:500 AND path:/api/*'),
                  KumoInputGroupAddon(
                    align: KumoInputGroupAlign.end,
                    child: KumoInputGroupButton(
                      icon: KumoIcons.question,
                      tooltip: 'Query language help',
                      onPress: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Sizes',
          child: _Stack(
            children: [
              for (final s in KumoFieldSize.values)
                KumoInputGroup(
                  size: s,
                  label: s.name,
                  children: [
                    const KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                    const KumoInputGroupInput(placeholder: 'Search zones'),
                    KumoInputGroupAddon(
                      align: KumoInputGroupAlign.end,
                      child: KumoInputGroupButton(icon: KumoIcons.question, tooltip: 'Search help', onPress: () {}),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const DemoSection(
          title: 'States',
          child: _Stack(
            children: [
              KumoInputGroup(
                label: 'Notification email',
                error: 'Enter a valid address.',
                children: [
                  KumoInputGroupInput(value: 'alerts@'),
                  KumoInputGroupAddon(align: KumoInputGroupAlign.end, text: '@example.com'),
                ],
              ),
              KumoInputGroup(
                label: 'Disabled',
                disabled: true,
                children: [
                  KumoInputGroupAddon(icon: KumoIcons.magnifyingGlass),
                  KumoInputGroupInput(placeholder: 'Search'),
                ],
              ),
              KumoInputGroup(
                label: 'Monthly budget',
                showOptional: true,
                children: [
                  KumoInputGroupAddon(text: r'$'),
                  KumoInputGroupInput(placeholder: '0.00'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SensitiveInputDemo extends StatefulWidget {
  const _SensitiveInputDemo();

  @override
  State<_SensitiveInputDemo> createState() => _SensitiveInputDemoState();
}

class _SensitiveInputDemoState extends State<_SensitiveInputDemo> {
  String _token = 'sample_token_8f2b91c4d7e6a05b';
  int _rotations = 0;
  int _copies = 0;

  @override
  Widget build(BuildContext context) {
    return _Sections(
      children: [
        DemoSection(
          title: 'API token',
          caption: 'Tap to reveal. Moving focus away or pressing Escape masks it again.',
          child: _Stack(
            children: [
              KumoSensitiveInput(
                label: 'API token',
                description: _copies == 0 ? 'Sample token. Copy it into your secret store.' : 'Copied $_copies times.',
                value: _token,
                mono: true,
                onValueChange: (v) => setState(() => _token = v),
                onCopy: () => setState(() => _copies++),
              ),
              Wrap(
                spacing: KumoSpace.s2,
                runSpacing: KumoSpace.s2,
                children: [
                  KumoButton(
                    label: 'Roll token',
                    icon: KumoIcons.arrowsClockwise,
                    size: KumoButtonSize.sm,
                    onPress: () => setState(() => _token = 'sample_token_rolled_${++_rotations}'),
                  ),
                  KumoButton(
                    label: 'Clear',
                    size: KumoButtonSize.sm,
                    variant: KumoButtonVariant.ghost,
                    onPress: () => setState(() => _token = ''),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Sizes',
          child: _Stack(
            children: [
              for (final s in KumoFieldSize.values)
                KumoSensitiveInput(size: s, label: '${s.name} size', value: 'sample-secret-${s.name}'),
            ],
          ),
        ),
        const DemoSection(
          title: 'States',
          child: _Stack(
            children: [
              KumoSensitiveInput(
                label: 'Signing key',
                value: 'invalid-key',
                error: 'This key is not valid for the zone.',
              ),
              KumoSensitiveInput(label: 'Disabled', value: 'cannot-edit', disabled: true),
              KumoSensitiveInput(label: 'Read-only', value: 'view-only-sample-secret', readOnly: true),
              KumoSensitiveInput(label: 'Webhook secret', placeholder: 'Paste the secret from your provider'),
            ],
          ),
        ),
      ],
    );
  }
}

class _NumberInputDemo extends StatefulWidget {
  const _NumberInputDemo();

  @override
  State<_NumberInputDemo> createState() => _NumberInputDemoState();
}

class _NumberInputDemoState extends State<_NumberInputDemo> {
  double? _retries = 3;
  double? _rate = 0.25;
  double? _port = 8080;
  double? _ttl;

  @override
  Widget build(BuildContext context) {
    final portError = _port == null ? 'Enter a port.' : null;
    return _Sections(
      children: [
        DemoSection(
          title: 'Bounded integer',
          caption: 'Hold a stepper to repeat. ArrowUp and ArrowDown step; PageUp and PageDown take ten.',
          child: KumoNumberInput(
            label: 'Max retries',
            description: 'From 0 to 10. Current value: ${_retries?.toInt() ?? 'none'}',
            value: _retries,
            min: 0,
            max: 10,
            onValueChange: (v) => setState(() => _retries = v),
          ),
        ),
        DemoSection(
          title: 'Decimals',
          child: KumoNumberInput(
            label: 'Sample rate',
            labelTooltip: 'Share of requests that are logged',
            description: 'Logs ${((_rate ?? 0) * 100).round()}% of requests.',
            value: _rate,
            min: 0,
            max: 1,
            step: 0.05,
            fractionDigits: 2,
            onValueChange: (v) => setState(() => _rate = v),
          ),
        ),
        DemoSection(
          title: 'Required, with an error',
          caption: 'Out-of-range text shows the error ring and is clamped on blur.',
          child: KumoNumberInput(
            label: 'Origin port',
            required: true,
            error: portError,
            value: _port,
            min: 1,
            max: 65535,
            onValueChange: (v) => setState(() => _port = v),
          ),
        ),
        DemoSection(
          title: 'Empty, optional, large steps',
          child: KumoNumberInput(
            label: 'Cache TTL in seconds',
            showOptional: true,
            placeholder: 'Respect origin',
            value: _ttl,
            min: 0,
            step: 60,
            largeStep: 3600,
            onValueChange: (v) => setState(() => _ttl = v),
          ),
        ),
        DemoSection(
          title: 'Sizes and states',
          child: _Stack(
            children: [
              for (final s in KumoFieldSize.values)
                KumoNumberInput(
                  size: s,
                  semanticLabel: 'Replicas, ${s.name}',
                  value: 2,
                  min: 1,
                  max: 9,
                  onValueChange: (_) {},
                ),
              const KumoNumberInput(label: 'Disabled', value: 5, disabled: true),
              const KumoNumberInput(label: 'Read-only', value: 5, readOnly: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputOtpDemo extends StatefulWidget {
  const _InputOtpDemo();

  @override
  State<_InputOtpDemo> createState() => _InputOtpDemoState();
}

class _InputOtpDemoState extends State<_InputOtpDemo> {
  String _code = '';
  String? _result;
  bool _resultOk = false;
  String _pin = '';
  String _recovery = '';

  void _verify(String code) {
    // Sample rule: 123456 is the accepted code.
    setState(() {
      _resultOk = code == '123456';
      _result = _resultOk ? null : 'That code is not valid. Sample code: 123456.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Sections(
      children: [
        DemoSection(
          title: 'Verification code',
          caption: 'Paste "123 456" or type it. Sample rule: only 123456 is accepted.',
          child: KumoInputOtp(
            label: 'Verification code',
            description: _resultOk ? 'Code accepted.' : 'Enter the 6-digit code from your authenticator app.',
            error: _result,
            groups: const [3, 3],
            value: _code,
            onValueChange: (v) => setState(() {
              _code = v;
              if (v.length < 6) {
                _result = null;
                _resultOk = false;
              }
            }),
            onComplete: _verify,
          ),
        ),
        DemoSection(
          title: 'Masked PIN',
          child: KumoInputOtp(
            label: 'Device PIN',
            length: 4,
            obscureText: true,
            size: KumoFieldSize.base,
            value: _pin,
            onValueChange: (v) => setState(() => _pin = v),
          ),
        ),
        DemoSection(
          title: 'Letters and digits',
          child: KumoInputOtp(
            label: 'Recovery code',
            length: 8,
            groups: const [4, 4],
            alphanumeric: true,
            value: _recovery,
            onValueChange: (v) => setState(() => _recovery = v),
          ),
        ),
        DemoSection(
          title: 'Sizes and disabled',
          child: _Stack(
            children: [
              for (final s in KumoFieldSize.values)
                KumoInputOtp(size: s, semanticLabel: 'Code, ${s.name}', value: '42'),
              const KumoInputOtp(label: 'Disabled', disabled: true, value: '12'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelDemo extends StatelessWidget {
  const _LabelDemo();

  @override
  Widget build(BuildContext context) {
    return const _Sections(
      children: [
        DemoSection(
          title: 'Variants',
          child: _Stack(
            children: [
              KumoLabel('Zone name'),
              KumoLabel('Phone number', showOptional: true),
              KumoLabel('API token', tooltip: 'Create one under My Profile, API Tokens'),
              KumoLabel('Billing email', required: true),
            ],
          ),
        ),
        DemoSection(
          title: 'Translated',
          caption: 'KumoLocale replaces "(optional)" and the tooltip name.',
          child: KumoLocale(
            strings: KumoStrings(optional: '(opcional)', moreInformation: 'Mais informações'),
            child: _Stack(
              children: [
                KumoLabel('Telefone', showOptional: true),
                KumoLabel('Token de API', tooltip: 'Crie um em Meu perfil'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldDemo extends StatefulWidget {
  const _FieldDemo();

  @override
  State<_FieldDemo> createState() => _FieldDemoState();
}

class _FieldDemoState extends State<_FieldDemo> {
  String _hostname = 'shop.example';

  @override
  Widget build(BuildContext context) {
    final valid = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+\.[a-z]{2,}$').hasMatch(_hostname);
    return _Sections(
      children: [
        DemoSection(
          title: 'Around a custom control',
          caption: 'Field supplies the label, description and error; the control stays bare.',
          child: KumoField(
            label: 'Custom hostname',
            labelTooltip: 'Point a CNAME at your fallback origin first',
            description: 'A hostname under a domain you own, like shop.example.com.',
            error: valid ? null : 'Add a top-level domain, like shop.example.com.',
            child: KumoInputGroup(
              children: [
                const KumoInputGroupAddon(text: 'https://'),
                KumoInputGroupInput(
                  semanticLabel: 'Custom hostname',
                  value: _hostname,
                  keyboardType: TextInputType.url,
                  onValueChange: (v) => setState(() => _hostname = v),
                ),
              ],
            ),
          ),
        ),
        const DemoSection(
          title: 'Optional, hidden label',
          child: _Stack(
            children: [
              KumoField(
                label: 'Company',
                showOptional: true,
                child: KumoInput(semanticLabel: 'Company'),
              ),
              KumoField(
                label: 'Search zones',
                hideLabel: true,
                child: KumoInput(
                  semanticLabel: 'Search zones',
                  placeholder: 'Search zones',
                  leadingIcon: KumoIcons.magnifyingGlass,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
