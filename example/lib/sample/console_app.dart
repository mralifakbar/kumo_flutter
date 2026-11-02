import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../gallery/settings_scope.dart';
import 'sample_data.dart';
import 'worker_page.dart';

/// Which console section is showing.
enum ConsoleSection { workers, dns }

/// A small edge-platform console built only from kumo_flutter components:
/// a responsive shell, a resource list, a Worker detail page with a chart,
/// deployment history and settings, a DNS table and a command palette.
/// Every name, route and number in it is sample data.
class ConsoleApp extends StatefulWidget {
  const ConsoleApp({super.key, this.initialSection = ConsoleSection.workers, this.simulateLoading = true});

  final ConsoleSection initialSection;

  /// Show the loading state briefly on first open, as a real console would.
  final bool simulateLoading;

  @override
  State<ConsoleApp> createState() => _ConsoleAppState();
}

class _ConsoleAppState extends State<ConsoleApp> {
  late ConsoleSection _section = widget.initialSection;
  final List<SampleWorker> _workers = sampleWorkers();
  final List<SampleDnsRecord> _records = sampleDnsRecords();
  late bool _loading = widget.simulateLoading;
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    if (_loading) _loadTimer = Timer(const Duration(milliseconds: 700), () => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  void _openWorker(SampleWorker w) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkerPage(
          worker: w,
          onChanged: () => setState(() {}),
          onDeleted: () => setState(() => _workers.remove(w)),
        ),
      ),
    );
  }

  void _openPalette() {
    showKumoCommandPalette(
      context: context,
      placeholder: 'Search Workers or run a command',
      groups: [
        KumoCommandGroup(
          label: 'Workers',
          items: [
            for (final w in _workers)
              KumoCommandItem(
                title: w.name,
                description: w.route,
                icon: KumoIcons.code,
                onSelect: () => _openWorker(w),
              ),
          ],
        ),
        KumoCommandGroup(
          label: 'Go to',
          items: [
            KumoCommandItem(
              title: 'Workers',
              icon: KumoIcons.code,
              onSelect: () => setState(() => _section = ConsoleSection.workers),
            ),
            KumoCommandItem(
              title: 'DNS records',
              icon: KumoIcons.globe,
              onSelect: () => setState(() => _section = ConsoleSection.dns),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final narrow = context.kumoIsNarrow;
    final title = switch (_section) {
      ConsoleSection.workers => 'Workers',
      ConsoleSection.dns => 'DNS records',
    };
    final body = switch (_section) {
      ConsoleSection.workers => _WorkersList(workers: _workers, loading: _loading, onOpen: _openWorker),
      ConsoleSection.dns => _DnsPage(records: _records, onChanged: () => setState(() {})),
    };

    return KumoCommandPaletteShortcut(
      onTrigger: _openPalette,
      child: KumoAppShell(
        sidebar: KumoSidebar(
          header: const KumoSidebarHeader(
            children: [
              KumoIcon(KumoIcons.cloud, color: KumoColor.brand),
              Expanded(child: KumoText('Sample account', bold: true, truncate: true)),
              KumoSidebarClose(),
            ],
          ),
          footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(
                label: 'Build',
                children: [
                  KumoSidebarMenuButton(
                    icon: KumoIcons.code,
                    label: 'Workers',
                    active: _section == ConsoleSection.workers,
                    onPress: () => setState(() => _section = ConsoleSection.workers),
                  ),
                  KumoSidebarMenuButton(
                    icon: KumoIcons.globe,
                    label: 'DNS records',
                    active: _section == ConsoleSection.dns,
                    onPress: () => setState(() => _section = ConsoleSection.dns),
                  ),
                ],
              ),
            ],
          ),
        ),
        topBar: Row(
          children: [
            Expanded(child: KumoText(title, variant: KumoTextVariant.heading, truncate: true)),
            KumoButton(
              icon: KumoIcons.magnifyingGlass,
              label: narrow ? null : 'Search',
              shape: narrow ? KumoButtonShape.square : KumoButtonShape.base,
              title: narrow ? 'Search' : null,
              variant: KumoButtonVariant.ghost,
              size: KumoButtonSize.sm,
              onPress: _openPalette,
            ),
            const ThemeModeButton(),
          ],
        ),
        bottomNavigation: narrow
            ? KumoBottomNavigation(
                value: _section.name,
                onValueChange: (v) => setState(() => _section = ConsoleSection.values.byName(v)),
                items: const [
                  KumoBottomNavigationItem(
                    value: 'workers',
                    label: 'Workers',
                    icon: KumoIcons.code,
                    activeIcon: KumoIcons.codeFill,
                  ),
                  KumoBottomNavigationItem(
                    value: 'dns',
                    label: 'DNS',
                    icon: KumoIcons.globe,
                    activeIcon: KumoIcons.globeFill,
                  ),
                ],
              )
            : null,
        body: body,
      ),
    );
  }
}

KumoResourceListStatus workerStatus(WorkerHealth h) => switch (h) {
  WorkerHealth.healthy => const KumoResourceListStatus(label: 'Healthy', tone: KumoResourceListStatusTone.success),
  WorkerHealth.degraded => const KumoResourceListStatus(label: 'Degraded', tone: KumoResourceListStatusTone.warning),
  WorkerHealth.failing => const KumoResourceListStatus(label: 'Failing', tone: KumoResourceListStatusTone.danger),
  WorkerHealth.paused => const KumoResourceListStatus(label: 'Paused', tone: KumoResourceListStatusTone.neutral),
};

class _WorkersList extends StatefulWidget {
  const _WorkersList({required this.workers, required this.loading, required this.onOpen});

  final List<SampleWorker> workers;
  final bool loading;
  final ValueChanged<SampleWorker> onOpen;

  @override
  State<_WorkersList> createState() => _WorkersListState();
}

class _WorkersListState extends State<_WorkersList> {
  String _query = '';
  WorkerHealth? _filter;

  @override
  Widget build(BuildContext context) {
    final visible = widget.workers
        .where((w) => _filter == null || w.health == _filter)
        .where((w) => w.name.contains(_query.trim().toLowerCase()))
        .toList();
    final filtered = _query.isNotEmpty || _filter != null;
    return KumoResourceList(
      title: 'Workers',
      description: 'Code that runs on every request to your routes. Sample data.',
      icon: KumoIcons.code,
      loading: widget.loading,
      actions: [
        KumoButton(
          label: 'Create Worker',
          icon: KumoIcons.plus,
          variant: KumoButtonVariant.primary,
          onPress: () => showKumoToast(
            context,
            title: 'Creating Workers is not part of this sample',
            description: 'This console only edits the sample data on this device.',
          ),
        ),
      ],
      usage: Wrap(
        spacing: KumoSpace.s2,
        runSpacing: KumoSpace.s2,
        children: [
          SizedBox(
            width: 240,
            child: KumoInput(
              placeholder: 'Filter by name',
              semanticLabel: 'Filter Workers by name',
              leading: const KumoIcon(KumoIcons.magnifyingGlass),
              value: _query,
              onValueChange: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            width: 180,
            child: KumoSelect<WorkerHealth?>(
              semanticLabel: 'Filter by status',
              placeholder: 'All statuses',
              value: _filter,
              onValueChange: (v) => setState(() => _filter = v),
              options: const [
                KumoSelectOption(value: null, label: 'All statuses'),
                KumoSelectOption(value: WorkerHealth.healthy, label: 'Healthy'),
                KumoSelectOption(value: WorkerHealth.degraded, label: 'Degraded'),
                KumoSelectOption(value: WorkerHealth.failing, label: 'Failing'),
                KumoSelectOption(value: WorkerHealth.paused, label: 'Paused'),
              ],
            ),
          ),
        ],
      ),
      empty: filtered
          ? KumoResourceListEmpty(
              title: 'No Workers match these filters',
              description: 'Clear the filters to see all Workers.',
              action: KumoButton(
                label: 'Clear filters',
                onPress: () => setState(() {
                  _query = '';
                  _filter = null;
                }),
              ),
            )
          : const KumoResourceListEmpty(
              title: 'No Workers yet',
              description: 'Create a Worker to run code on your routes.',
            ),
      children: [
        for (final w in visible)
          KumoResourceListItem(
            title: w.name,
            mono: true,
            metadata: [w.route, 'Deployed ${w.lastDeploy}'],
            status: workerStatus(w.health),
            onPress: () => widget.onOpen(w),
            semanticLabel: 'Open ${w.name}',
          ),
      ],
    );
  }
}

class _DnsPage extends StatefulWidget {
  const _DnsPage({required this.records, required this.onChanged});

  final List<SampleDnsRecord> records;
  final VoidCallback onChanged;

  @override
  State<_DnsPage> createState() => _DnsPageState();
}

class _DnsPageState extends State<_DnsPage> {
  KumoTableSort _sort = const KumoTableSort('type', KumoTableSortDirection.ascending);

  List<SampleDnsRecord> get _sorted {
    final rows = [...widget.records];
    int compare(SampleDnsRecord a, SampleDnsRecord b) => switch (_sort.columnId) {
      'name' => a.name.compareTo(b.name),
      _ => a.type.compareTo(b.type),
    };
    rows.sort(_sort.direction == KumoTableSortDirection.ascending ? compare : (a, b) => compare(b, a));
    return rows;
  }

  Future<void> _addRecord() async {
    final record = await showKumoDialog<SampleDnsRecord>(context, builder: (_) => const _AddRecordDialog());
    if (record == null || !mounted) return;
    setState(() => widget.records.add(record));
    widget.onChanged();
    showKumoToast(
      context,
      title: 'Record added',
      description: '${record.type} ${record.name}',
      variant: KumoToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.kumoIsNarrow ? KumoSpace.s4 : KumoSpace.s8;
    return ListView(
      padding: EdgeInsets.fromLTRB(gutter, KumoSpace.s6, gutter, KumoSpace.s8),
      children: [
        KumoPageHeader(
          title: 'DNS records',
          description: 'Records for example.com. Sample data using documentation address ranges.',
          actions: [
            KumoButton(
              label: 'Add record',
              icon: KumoIcons.plus,
              variant: KumoButtonVariant.primary,
              onPress: _addRecord,
            ),
          ],
        ),
        const SizedBox(height: KumoSpace.s4),
        KumoTable<SampleDnsRecord>(
          semanticLabel: 'DNS records',
          rows: _sorted,
          layout: KumoTableLayout.auto,
          sort: _sort,
          onSortChange: (s) => setState(() => _sort = s),
          rowLabel: (r) => '${r.type} ${r.name}',
          empty: KumoTablePlaceholder(
            title: 'No DNS records',
            description: 'Add a record so visitors can reach example.com.',
            icon: KumoIcons.globe,
            action: KumoButton(label: 'Add record', onPress: _addRecord),
          ),
          columns: [
            KumoTableColumn(
              id: 'type',
              label: 'Type',
              sortable: true,
              width: const KumoTableColumnWidth.fixed(88),
              cell: (_, r) => KumoText(r.type, variant: KumoTextVariant.mono),
            ),
            KumoTableColumn(
              id: 'name',
              label: 'Name',
              sortable: true,
              cell: (_, r) => KumoText(r.name, variant: KumoTextVariant.mono),
            ),
            KumoTableColumn(
              id: 'content',
              label: 'Content',
              width: const KumoTableColumnWidth.flex(2, 160),
              cell: (_, r) => KumoText(r.content, variant: KumoTextVariant.mono),
            ),
            KumoTableColumn(
              id: 'proxy',
              label: 'Proxy',
              width: const KumoTableColumnWidth.fixed(140),
              cell: (_, r) => KumoSwitch(
                label: r.proxied ? 'Proxied' : 'DNS only',
                size: KumoSwitchSize.sm,
                checked: r.proxied,
                onCheckedChange: r.type == 'MX' || r.type == 'TXT' ? null : (v) => setState(() => r.proxied = v),
              ),
            ),
            KumoTableColumn(
              id: 'ttl',
              label: 'TTL',
              width: const KumoTableColumnWidth.fixed(72),
              cell: (_, r) => KumoText(r.ttl, variant: KumoTextVariant.secondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  const _AddRecordDialog();

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  String _type = 'A';
  String _name = '';
  String _content = '';
  bool _proxied = true;
  bool _submitted = false;

  String? get _nameError => _submitted && _name.trim().isEmpty ? 'Enter a name, or @ for the root.' : null;

  String? get _contentError {
    if (!_submitted) return null;
    if (_content.trim().isEmpty) return 'Enter the value this record points to.';
    if (_type == 'A' && !RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(_content.trim())) {
      return 'An A record needs an IPv4 address, such as 192.0.2.1.';
    }
    return null;
  }

  void _save() {
    setState(() => _submitted = true);
    if (_nameError != null || _contentError != null) return;
    Navigator.of(context).pop(
      SampleDnsRecord(
        type: _type,
        name: _name.trim() == '@' ? 'example.com' : _name.trim(),
        content: _content.trim(),
        proxied: _proxied && (_type == 'A' || _type == 'AAAA' || _type == 'CNAME'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxiable = _type == 'A' || _type == 'AAAA' || _type == 'CNAME';
    return KumoDialog(
      title: 'Add DNS record',
      description: 'Changes apply to the sample data only.',
      actions: [
        const KumoDialogClose(label: 'Cancel'),
        KumoButton(label: 'Save record', variant: KumoButtonVariant.primary, onPress: _save),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s4,
        children: [
          KumoSelect<String>(
            label: 'Type',
            value: _type,
            onValueChange: (v) => setState(() => _type = v ?? 'A'),
            options: const [
              KumoSelectOption(value: 'A', label: 'A'),
              KumoSelectOption(value: 'AAAA', label: 'AAAA'),
              KumoSelectOption(value: 'CNAME', label: 'CNAME'),
              KumoSelectOption(value: 'TXT', label: 'TXT'),
            ],
          ),
          KumoInput(
            label: 'Name',
            placeholder: '@ or www',
            mono: true,
            value: _name,
            error: _nameError,
            onValueChange: (v) => setState(() => _name = v),
          ),
          KumoInput(
            label: _type == 'CNAME' ? 'Target' : (_type == 'TXT' ? 'Content' : 'IPv${_type == 'AAAA' ? 6 : 4} address'),
            placeholder: _type == 'A' ? '192.0.2.1' : null,
            mono: true,
            value: _content,
            error: _contentError,
            onValueChange: (v) => setState(() => _content = v),
          ),
          if (proxiable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s1,
              children: [
                KumoSwitch(
                  label: 'Proxy through the edge',
                  checked: _proxied,
                  onCheckedChange: (v) => setState(() => _proxied = v),
                ),
                const KumoText(
                  'Hides the origin address and enables caching.',
                  variant: KumoTextVariant.secondary,
                  size: KumoTextSize.sm,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Today in UTC, from the test-aware clock.
DateTime consoleNow() => clock.now().toUtc();
