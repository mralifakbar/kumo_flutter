import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Selects, comboboxes, autocomplete, tag inputs and the command palette.
/// Every zone, Worker, bucket and address below is sample data.
final KumoDemoCategory pickersCategory = KumoDemoCategory(
  title: 'Selection',
  description:
      'Pick from lists, search options as you type, collect tags and run commands from a palette.',
  icon: KumoIcons.caretUpDown,
  demos: [
    KumoDemo(
      title: 'KumoSelect',
      description:
          'A field-styled trigger that opens a list of options, or a bottom sheet on phones.',
      docPath: 'doc/components/KumoSelect.md',
      builder: (context) => const _SelectDemo(),
    ),
    KumoDemo(
      title: 'KumoCombobox',
      description:
          'A text field that filters options as you type, for one value or several as chips.',
      docPath: 'doc/components/KumoCombobox.md',
      builder: (context) => const _ComboboxDemo(),
    ),
    KumoDemo(
      title: 'KumoAutocomplete',
      description:
          'Free text with suggestions; whatever is typed is the value.',
      docPath: 'doc/components/KumoAutocomplete.md',
      builder: (context) => const _AutocompleteDemo(),
    ),
    KumoDemo(
      title: 'KumoTagInput',
      description:
          'Type and press Enter or comma to add tags, with validation and a limit.',
      docPath: 'doc/components/KumoTagInput.md',
      builder: (context) => const _TagInputDemo(),
    ),
    KumoDemo(
      title: 'KumoCommandPalette',
      description: 'A searchable list of commands opened with Cmd+K or Ctrl+K.',
      docPath: 'doc/components/KumoCommandPalette.md',
      builder: (context) => const _CommandPaletteDemo(),
    ),
  ],
);

class _Demo extends StatelessWidget {
  const _Demo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: KumoSpace.s8,
    children: [
      const KumoText(
        'All resources shown are sample data.',
        variant: KumoTextVariant.secondary,
        size: KumoTextSize.sm,
      ),
      ...children,
    ],
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KumoSpace.s2),
    child: KumoText(
      text,
      variant: KumoTextVariant.secondary,
      size: KumoTextSize.sm,
    ),
  );
}

/// Caps a field at a dashboard-like width while still fitting 390px.
class _Width extends StatelessWidget {
  const _Width(this.width, {required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

const _regions = <KumoSelectItem<String>>[
  KumoSelectGroup(
    label: 'Americas',
    options: [
      KumoSelectOption(
        value: 'enam',
        label: 'Eastern North America',
        icon: KumoIcons.globeHemisphereWest,
      ),
      KumoSelectOption(
        value: 'wnam',
        label: 'Western North America',
        icon: KumoIcons.globeHemisphereWest,
      ),
      KumoSelectOption(
        value: 'sam',
        label: 'South America',
        icon: KumoIcons.globeHemisphereWest,
        disabled: true,
      ),
    ],
  ),
  KumoSelectSeparator(),
  KumoSelectGroup(
    label: 'Europe and Asia',
    options: [
      KumoSelectOption(
        value: 'weur',
        label: 'Western Europe',
        icon: KumoIcons.globe,
      ),
      KumoSelectOption(
        value: 'eeur',
        label: 'Eastern Europe',
        icon: KumoIcons.globe,
      ),
      KumoSelectOption(
        value: 'apac',
        label: 'Asia Pacific',
        icon: KumoIcons.globe,
      ),
    ],
  ),
];

const _plans = <KumoSelectItem<String>>[
  KumoSelectOption(
    value: 'free',
    label: 'Free',
    description: 'Up to 100,000 requests a day',
  ),
  KumoSelectOption(
    value: 'paid',
    label: 'Workers Paid',
    description: 'Billed by requests and CPU time',
  ),
  KumoSelectOption(
    value: 'enterprise',
    label: 'Enterprise',
    description: 'Contact your account team',
    disabled: true,
  ),
];

class _SelectDemo extends StatefulWidget {
  const _SelectDemo();

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  String? region = 'enam';
  String? plan;
  String? environment;
  String? zone;
  String? worker = 'worker-1200';
  bool loadingZones = true;
  List<String> columns = ['Name', 'Route', 'Status'];
  final Map<KumoFieldSize, String?> sized = {};

  static final _workers = [
    for (var i = 0; i < 2000; i++)
      KumoSelectOption(value: 'worker-$i', label: 'worker-$i'),
  ];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  void _loadZones() {
    setState(() => loadingZones = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => loadingZones = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Basic',
          caption:
              'Groups, a separator, icons and a disabled region. On phones the list opens in a sheet.',
          child: _Width(
            320,
            child: KumoSelect<String>(
              label: 'Region',
              options: _regions,
              value: region,
              onValueChange: (v) => setState(() => region = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Sizes',
          caption: 'xs, sm, base and lg match button and input heights.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              for (final s in KumoFieldSize.values)
                _Width(
                  240,
                  child: KumoSelect<String>(
                    size: s,
                    semanticLabel: 'Environment, ${s.name}',
                    placeholder: 'Environment (${s.name})',
                    options: KumoSelectOption.fromLabels([
                      'production',
                      'staging',
                      'preview',
                    ]),
                    value: sized[s],
                    onValueChange: (v) => setState(() => sized[s] = v),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Description, tooltip and error',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s4,
            children: [
              _Width(
                320,
                child: KumoSelect<String>(
                  label: 'Plan',
                  labelTooltip: 'You can change plans at any time',
                  description:
                      'Billing changes at the start of the next cycle.',
                  placeholder: 'Choose a plan',
                  options: _plans,
                  value: plan,
                  onValueChange: (v) => setState(() => plan = v),
                ),
              ),
              _Width(
                320,
                child: KumoSelect<String>(
                  label: 'Environment',
                  showOptional: environment == null,
                  error: environment == null
                      ? 'Choose an environment to deploy to'
                      : null,
                  placeholder: 'Choose an environment',
                  options: KumoSelectOption.fromLabels([
                    'production',
                    'staging',
                    'preview',
                  ]),
                  value: environment,
                  onValueChange: (v) => setState(() => environment = v),
                ),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Loading',
          caption:
              'A skeleton holds the trigger while options load; it cannot open until they arrive.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              _Width(
                320,
                child: KumoSelect<String>(
                  label: 'Zone',
                  placeholder: 'Choose a zone',
                  loading: loadingZones,
                  options: KumoSelectOption.fromLabels([
                    'example.com',
                    'example.dev',
                    'shop.example.com',
                  ]),
                  value: zone,
                  onValueChange: (v) => setState(() => zone = v),
                ),
              ),
              KumoButton(
                label: 'Reload zones',
                size: KumoButtonSize.sm,
                onPress: loadingZones ? null : _loadZones,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Multiple',
          caption:
              'The list stays open while columns are toggled; the trigger summarizes the choice.',
          child: _Width(
            320,
            child: KumoSelect<String>.multiple(
              label: 'Visible columns',
              placeholder: 'No columns',
              options: KumoSelectOption.fromLabels([
                'Name',
                'Route',
                'Status',
                'Last deploy',
                'Requests',
                'Errors',
              ]),
              values: columns,
              onValuesChange: (v) => setState(() => columns = v),
              renderValue: (context, selected) => Text(
                selected.length > 3
                    ? '${selected.take(2).map((o) => o.label).join(', ')} and ${selected.length - 2} more'
                    : selected.map((o) => o.label).join(', '),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Long list',
          caption:
              '2,000 Workers, built lazily. The list opens on the current value; type to jump.',
          child: _Width(
            320,
            child: KumoSelect<String>(
              label: 'Worker',
              options: _workers,
              value: worker,
              onValueChange: (v) => setState(() => worker = v),
            ),
          ),
        ),
        const DemoSection(
          title: 'Disabled',
          child: _Width(
            320,
            child: KumoSelect<String>(
              label: 'Account',
              disabled: true,
              value: 'acme',
              options: [
                KumoSelectOption(value: 'acme', label: 'Acme Corp (sample)'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const _bindings = <KumoSelectItem<String>>[
  KumoSelectGroup(
    label: 'Storage',
    options: [
      KumoSelectOption(
        value: 'kv',
        label: 'Workers KV',
        icon: KumoIcons.database,
      ),
      KumoSelectOption(
        value: 'r2',
        label: 'R2 bucket',
        icon: KumoIcons.archive,
      ),
      KumoSelectOption(
        value: 'd1',
        label: 'D1 database',
        icon: KumoIcons.database,
      ),
    ],
  ),
  KumoSelectGroup(
    label: 'Compute',
    options: [
      KumoSelectOption(
        value: 'do',
        label: 'Durable Object',
        icon: KumoIcons.cube,
      ),
      KumoSelectOption(value: 'queue', label: 'Queue', icon: KumoIcons.stack),
      KumoSelectOption(
        value: 'ai',
        label: 'Workers AI',
        icon: KumoIcons.lightning,
        disabled: true,
      ),
    ],
  ),
];

final _bots = [
  for (final b in [
    ('googlebot', 'Googlebot'),
    ('bingbot', 'Bingbot'),
    ('applebot', 'Applebot'),
    ('duckduckbot', 'DuckDuckBot'),
    ('yandexbot', 'YandexBot'),
    ('ahrefsbot', 'AhrefsBot'),
    ('semrushbot', 'SemrushBot'),
  ])
    KumoSelectOption(value: b.$1, label: b.$2),
];

class _ComboboxDemo extends StatefulWidget {
  const _ComboboxDemo();

  @override
  State<_ComboboxDemo> createState() => _ComboboxDemoState();
}

class _ComboboxDemoState extends State<_ComboboxDemo> {
  String? binding;
  String? sized;
  List<String> bots = ['googlebot', 'bingbot'];
  List<String> topBots = ['applebot'];
  String? bucket;
  List<KumoSelectOption<String>> bucketResults = const [];
  bool searching = false;
  int _seq = 0;

  static const _allBuckets = [
    'assets',
    'assets-staging',
    'backups',
    'logs-2026',
    'media',
    'uploads',
  ];

  void _searchBuckets(String query) {
    final seq = ++_seq;
    setState(() => searching = true);
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || seq != _seq) return;
      setState(() {
        searching = false;
        bucketResults = KumoSelectOption.fromLabels(
          _allBuckets.where((b) => b.contains(query.toLowerCase())),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Basic',
          caption:
              'Type to filter. Enter picks the first match; arrows move while focus stays in the field.',
          child: _Width(
            320,
            child: KumoCombobox<String>(
              label: 'Binding type',
              placeholder: 'Search binding types',
              options: _bindings,
              value: binding,
              onValueChange: (v) => setState(() => binding = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Multiple',
          caption:
              'Chosen bots show as chips. Backspace in the empty input removes the last one.',
          child: _Width(
            400,
            child: KumoCombobox<String>.multiple(
              label: 'Allowed crawlers',
              placeholder: 'Add a crawler',
              options: _bots,
              values: bots,
              onValuesChange: (v) => setState(() => bots = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Input above the chips',
          child: _Width(
            400,
            child: KumoCombobox<String>.multiple(
              semanticLabel: 'Blocked crawlers',
              placeholder: 'Add a crawler to block',
              inputSide: KumoComboboxInputSide.top,
              options: _bots,
              values: topBots,
              onValuesChange: (v) => setState(() => topBots = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Server search',
          caption:
              'Results load as you type; the list shows a loading row, then results or "No results".',
          child: _Width(
            320,
            child: KumoCombobox<String>(
              label: 'R2 bucket',
              placeholder: 'Search buckets',
              options: bucketResults,
              filter: (option, query) => true,
              loading: searching,
              onInputValueChange: _searchBuckets,
              value: bucket,
              onValueChange: (v) => setState(() => bucket = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Sizes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              for (final s in KumoFieldSize.values)
                _Width(
                  240,
                  child: KumoCombobox<String>(
                    size: s,
                    semanticLabel: 'Binding type, ${s.name}',
                    placeholder: 'Binding (${s.name})',
                    options: _bindings,
                    value: sized,
                    onValueChange: (v) => setState(() => sized = v),
                  ),
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Error and disabled',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s4,
            children: [
              _Width(
                320,
                child: KumoCombobox<String>(
                  label: 'Database',
                  error: binding == 'd1'
                      ? null
                      : 'Choose the D1 database this Worker reads from',
                  placeholder: 'Search databases',
                  options: _bindings,
                  value: binding,
                  onValueChange: (v) => setState(() => binding = v),
                ),
              ),
              const _Width(
                320,
                child: KumoCombobox<String>(
                  label: 'Queue',
                  disabled: true,
                  value: 'queue',
                  options: _bindings,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final _routes = <KumoSelectItem<String>>[
  const KumoSelectGroup(
    label: 'Recent routes',
    options: [
      KumoSelectOption(value: 'example.com/*', label: 'example.com/*'),
      KumoSelectOption(value: 'api.example.com/*', label: 'api.example.com/*'),
    ],
  ),
  KumoSelectGroup(
    label: 'Suggested',
    options: KumoSelectOption.fromLabels([
      'example.com/images/*',
      'example.com/api/v1/*',
      '*.example.com/*',
    ]),
  ),
];

class _AutocompleteDemo extends StatefulWidget {
  const _AutocompleteDemo();

  @override
  State<_AutocompleteDemo> createState() => _AutocompleteDemoState();
}

class _AutocompleteDemoState extends State<_AutocompleteDemo> {
  String route = '';
  String hostname = '';
  String compatDate = '';

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Route pattern',
          caption: 'Suggestions help, but any pattern can be typed.',
          child: _Width(
            360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                KumoAutocomplete(
                  label: 'Route',
                  description: 'Requests matching this pattern run the Worker.',
                  placeholder: 'example.com/*',
                  mono: true,
                  options: _routes,
                  value: route,
                  onValueChange: (v) => setState(() => route = v),
                ),
                _Note(route.isEmpty ? 'No route yet' : 'Route: $route'),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'With an empty message',
          caption: 'Without emptyMessage the list hides when nothing matches.',
          child: _Width(
            360,
            child: KumoAutocomplete(
              label: 'Custom hostname',
              placeholder: 'shop.example.com',
              emptyMessage:
                  'No saved hostnames match. Press Enter to use what you typed.',
              options: KumoSelectOption.fromLabels([
                'shop.example.com',
                'docs.example.com',
                'status.example.com',
              ]),
              value: hostname,
              onValueChange: (v) => setState(() => hostname = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Small',
          child: _Width(
            240,
            child: KumoAutocomplete(
              size: KumoFieldSize.sm,
              semanticLabel: 'Compatibility date',
              placeholder: 'Compatibility date',
              options: KumoSelectOption.fromLabels([
                '2026-10-01',
                '2026-07-15',
                '2026-04-01',
              ]),
              value: compatDate,
              onValueChange: (v) => setState(() => compatDate = v),
            ),
          ),
        ),
      ],
    );
  }
}

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class _TagInputDemo extends StatefulWidget {
  const _TagInputDemo();

  @override
  State<_TagInputDemo> createState() => _TagInputDemoState();
}

class _TagInputDemoState extends State<_TagInputDemo> {
  List<String> recipients = ['ops@example.com'];
  List<String> labels = ['frontend', 'priority'];
  List<String> groups = ['billing'];
  List<String> etiquetas = ['uno'];

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Validated',
          caption:
              'Paste comma- or newline-separated addresses; invalid ones stay in the input.',
          child: _Width(
            420,
            child: KumoTagInput(
              label: 'Alert recipients',
              description:
                  'Notifications for failed deployments go to these addresses.',
              placeholder: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              value: recipients,
              onValueChange: (v) => setState(() => recipients = v),
              validateValue: (v, _) =>
                  _email.hasMatch(v) ? null : '"$v" is not an email address.',
            ),
          ),
        ),
        DemoSection(
          title: 'Unrestricted',
          child: _Width(
            420,
            child: KumoTagInput(
              label: 'Labels',
              description: 'Accepts any non-empty value.',
              placeholder: 'Add a label',
              value: labels,
              onValueChange: (v) => setState(() => labels = v),
            ),
          ),
        ),
        DemoSection(
          title: 'Limited',
          child: _Width(
            420,
            child: KumoTagInput(
              label: 'Access groups',
              description: 'Up to three groups.',
              placeholder: 'Type a group name',
              maxValues: 3,
              value: groups,
              onValueChange: (v) => setState(() => groups = v),
            ),
          ),
        ),
        const DemoSection(
          title: 'Read only',
          child: _Width(
            420,
            child: KumoTagInput(
              label: 'Assigned teams',
              description: 'Managed by your organization administrator.',
              readOnly: true,
              value: ['billing', 'dns', 'workers'],
            ),
          ),
        ),
        DemoSection(
          title: 'Localized labels',
          child: _Width(
            420,
            child: KumoTagInput(
              label: 'Etiquetas',
              placeholder: 'Agregar una etiqueta',
              maxValues: 3,
              labels: KumoTagInputLabels(
                input: 'Agregar etiqueta',
                removeValue: (v) => 'Eliminar $v',
                invalidValue: (v) => '$v no es valido.',
                maxValuesReached: (n) => 'Maximo de $n etiquetas.',
              ),
              value: etiquetas,
              onValueChange: (v) => setState(() => etiquetas = v),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommandPaletteDemo extends StatefulWidget {
  const _CommandPaletteDemo();

  @override
  State<_CommandPaletteDemo> createState() => _CommandPaletteDemoState();
}

class _CommandPaletteDemoState extends State<_CommandPaletteDemo> {
  String? lastRun;

  void _ran(String what) => setState(() => lastRun = what);

  List<KumoCommandGroup> get _groups => [
    KumoCommandGroup(
      label: 'Workers',
      items: [
        KumoCommandItem(
          title: 'Deploy image-resizer',
          icon: KumoIcons.rocket,
          keywords: const ['publish', 'release'],
          onSelect: () => _ran('Deploy image-resizer'),
        ),
        KumoCommandItem(
          title: 'Tail logs',
          icon: KumoIcons.terminal,
          breadcrumbs: const ['image-resizer'],
          onSelect: () => _ran('Tail logs'),
        ),
        KumoCommandItem(
          title: 'Create Worker',
          icon: KumoIcons.plus,
          shortcut: 'N',
          onSelect: () => _ran('Create Worker'),
        ),
      ],
    ),
    KumoCommandGroup(
      label: 'example.com',
      items: [
        KumoCommandItem(
          title: 'Purge everything',
          icon: KumoIcons.trash,
          description: 'Removes every cached file for the zone',
          breadcrumbs: const ['Caching'],
          onSelect: () => _ran('Purge everything'),
        ),
        KumoCommandItem(
          title: 'DNS records',
          icon: KumoIcons.globe,
          onSelect: () => _ran('Open DNS records'),
        ),
        const KumoCommandItem(
          title: 'Enable Argo Smart Routing',
          icon: KumoIcons.lightning,
          description: 'Not available on this sample plan',
          disabled: true,
        ),
      ],
    ),
    KumoCommandGroup(
      label: 'Help',
      items: [
        KumoCommandItem(
          title: 'Workers documentation',
          icon: KumoIcons.file,
          external: true,
          onSelect: () => _ran('Open documentation'),
        ),
      ],
    ),
  ];

  Future<List<KumoCommandGroup>> _searchBuckets(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final hits = [
      'assets',
      'backups',
      'media',
    ].where((b) => b.contains(query.toLowerCase()));
    return [
      KumoCommandGroup(
        label: 'R2 buckets',
        items: [
          for (final b in hits)
            KumoCommandItem(
              title: b,
              icon: KumoIcons.archive,
              breadcrumbs: const ['R2'],
              onSelect: () => _ran('Open bucket $b'),
            ),
        ],
      ),
    ];
  }

  Widget get _footer => const KumoCommandPaletteFooter(
    children: [
      KumoCommandPaletteKeyHint(
        label: 'Navigate',
        keys: ['Up', 'Down'],
        icons: [KumoIcons.arrowUp, KumoIcons.arrowDown],
      ),
      KumoCommandPaletteKeyHint(
        label: 'Run',
        keys: ['Enter'],
        icons: [KumoIcons.arrowElbowDownLeft],
      ),
      KumoCommandPaletteKeyHint(label: 'Close', keys: ['Esc']),
    ],
  );

  Future<void> _open({bool withSearch = false}) => showKumoCommandPalette(
    context: context,
    placeholder: withSearch
        ? 'Search commands and buckets'
        : 'Type a command or search',
    groups: _groups,
    onSearch: withSearch ? _searchBuckets : null,
    footer: _footer,
  );

  @override
  Widget build(BuildContext context) {
    return KumoCommandPaletteShortcut(
      onTrigger: _open,
      child: _Demo(
        children: [
          DemoSection(
            title: 'Dialog and sheet',
            caption:
                'Press ${KumoCommandPaletteShortcut.label()} or the button. Phones get a full-height sheet.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: KumoSpace.s2,
                  runSpacing: KumoSpace.s2,
                  children: [
                    KumoButton(
                      label: 'Open command palette',
                      icon: KumoIcons.command,
                      onPress: _open,
                    ),
                    KumoButton(
                      label: 'Open with bucket search',
                      icon: KumoIcons.magnifyingGlass,
                      variant: KumoButtonVariant.ghost,
                      onPress: () => _open(withSearch: true),
                    ),
                  ],
                ),
                _Note(
                  lastRun == null ? 'No command run yet' : 'Last run: $lastRun',
                ),
              ],
            ),
          ),
          DemoSection(
            title: 'Embedded panel',
            caption: 'The same panel inside a page, without the dialog.',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(KumoRadius.lg),
                  border: KumoRing.border(context.kumo.colors.line),
                ),
                child: KumoCommandPalette(
                  autofocus: false,
                  placeholder: 'Filter commands',
                  groups: _groups,
                  footer: _footer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
