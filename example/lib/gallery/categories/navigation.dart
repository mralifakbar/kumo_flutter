import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Tabs, breadcrumbs, pagination, links, table of contents, collapsibles,
/// accordions, steps and a phone tab bar. Every Worker, zone and count here
/// is sample data.
final KumoDemoCategory navigationCategory = KumoDemoCategory(
  title: 'Navigation',
  description:
      'Tabs, breadcrumbs, pagination, links, table of contents, disclosure, steps and a phone tab bar.',
  icon: KumoIcons.compass,
  demos: [
    KumoDemo(
      title: 'KumoTabs',
      description:
          'Segmented and underline tabs in two sizes, with icons, a disabled tab, overflow and swipeable panels.',
      docPath: 'doc/components/KumoTabs.md',
      builder: (_) => const _TabsDemo(),
    ),
    KumoDemo(
      title: 'KumoBreadcrumbs',
      description:
          'A trail that collapses into a More menu when tight, a back link on phones, loading and copy.',
      docPath: 'doc/components/KumoBreadcrumbs.md',
      builder: (_) => const _BreadcrumbsDemo(),
    ),
    KumoDemo(
      title: 'KumoPagination',
      description:
          'Full and simple controls, typed or picked page numbers, a page size select and unknown totals.',
      docPath: 'doc/components/KumoPagination.md',
      builder: (_) => const _PaginationDemo(),
    ),
    KumoDemo(
      title: 'KumoLink',
      description:
          'Inline, current and plain links, an external link and a link inside running text.',
      docPath: 'doc/components/KumoLink.md',
      builder: (_) => const _LinkDemo(),
    ),
    KumoDemo(
      title: 'KumoTableOfContents',
      description:
          'Section links that follow the scroll position and scroll to a section on tap.',
      docPath: 'doc/components/KumoTableOfContents.md',
      builder: (_) => const _TocDemo(),
    ),
    KumoDemo(
      title: 'KumoCollapsible',
      description:
          'The default trigger and accent panel, a custom trigger, and a panel that keeps form state.',
      docPath: 'doc/components/KumoCollapsible.md',
      builder: (_) => const _CollapsibleDemo(),
    ),
    KumoDemo(
      title: 'KumoAccordion',
      description:
          'Single and multiple open sections with descriptions, icons and a disabled item.',
      docPath: 'doc/components/KumoAccordion.md',
      builder: (_) => const _AccordionDemo(),
    ),
    KumoDemo(
      title: 'KumoSteps',
      description:
          'Upcoming, current, complete and error markers, horizontal and vertical.',
      docPath: 'doc/components/KumoSteps.md',
      builder: (_) => const _StepsDemo(),
    ),
    KumoDemo(
      title: 'KumoStepper',
      description:
          'A zone onboarding flow with Back and Continue, validation and a named final action.',
      docPath: 'doc/components/KumoStepper.md',
      builder: (_) => const _StepperDemo(),
    ),
    KumoDemo(
      title: 'KumoBottomNavigation',
      description:
          'A phone tab bar with fill icons for the active destination and an unread count.',
      docPath: 'doc/components/KumoBottomNavigation.md',
      builder: (_) => const _BottomNavigationDemo(),
    ),
  ],
);

Widget _secondary(String text) =>
    KumoText(text, variant: KumoTextVariant.secondary, size: KumoTextSize.sm);

const _workerTabs = [
  KumoTab(value: 'overview', label: 'Overview'),
  KumoTab(value: 'metrics', label: 'Metrics'),
  KumoTab(value: 'settings', label: 'Settings'),
];

const _manyTabs = [
  KumoTab(value: 'overview', label: 'Overview'),
  KumoTab(value: 'metrics', label: 'Metrics'),
  KumoTab(value: 'deployments', label: 'Deployments'),
  KumoTab(value: 'observability', label: 'Observability'),
  KumoTab(value: 'domains', label: 'Domains & Routes'),
  KumoTab(value: 'bindings', label: 'Bindings'),
  KumoTab(value: 'settings', label: 'Settings'),
];

class _TabsDemo extends StatefulWidget {
  const _TabsDemo();

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  final Map<String, String> _values = {};
  final PageController _pages = PageController();
  String _panel = 'overview';

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _tabs(
    String id, {
    KumoTabsVariant variant = KumoTabsVariant.segmented,
    KumoTabsSize size = KumoTabsSize.base,
    List<KumoTab> tabs = _workerTabs,
  }) {
    return KumoTabs(
      tabs: tabs,
      variant: variant,
      size: size,
      value: _values[id] ?? tabs.first.value,
      onValueChange: (v) => setState(() => _values[id] = v),
      semanticLabel: 'Worker sections',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Segmented',
          caption: 'On touch, grab the pill and drag it to another tab.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              _tabs('seg'),
              _tabs('seg-sm', size: KumoTabsSize.sm),
            ],
          ),
        ),
        DemoSection(
          title: 'Underline',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              _tabs('under', variant: KumoTabsVariant.underline),
              _tabs(
                'under-sm',
                variant: KumoTabsVariant.underline,
                size: KumoTabsSize.sm,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Icons and a disabled tab',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              _tabs(
                'icons',
                tabs: const [
                  KumoTab(
                    value: 'logs',
                    label: 'Logs',
                    icon: KumoIcons.listBullets,
                  ),
                  KumoTab(
                    value: 'metrics',
                    label: 'Metrics',
                    icon: KumoIcons.chartBar,
                  ),
                  KumoTab(
                    value: 'traces',
                    label: 'Traces',
                    icon: KumoIcons.lightning,
                    disabled: true,
                  ),
                ],
              ),
              _secondary('Active tab: ${_values['icons'] ?? 'logs'}'),
            ],
          ),
        ),
        DemoSection(
          title: 'Overflow',
          caption:
              'Seven tabs in a narrow box: the row scrolls, the edges fade and chevrons page through.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              SizedBox(width: 300, child: _tabs('many', tabs: _manyTabs)),
              _tabs(
                'many-under',
                variant: KumoTabsVariant.underline,
                tabs: _manyTabs,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Swipeable panels',
          caption: 'Swipe the panel on touch; the indicator follows the page.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s3,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KumoTabs(
                  tabs: _workerTabs,
                  value: _panel,
                  pageController: _pages,
                  onValueChange: (v) => setState(() => _panel = v),
                ),
              ),
              SizedBox(
                height: MediaQuery.textScalerOf(context).scale(140),
                child: KumoTabPanels(
                  controller: _pages,
                  value: _panel,
                  onValueChange: (v) => setState(() => _panel = v),
                  panels: [
                    _panelOf(
                      'overview',
                      'image-resizer',
                      'Deployed from main, 2 routes on example.com (sample data).',
                    ),
                    _panelOf(
                      'metrics',
                      'Requests',
                      'Median CPU time and request counts appear here (sample data).',
                    ),
                    _panelOf(
                      'settings',
                      'Settings',
                      'Compatibility date, usage model and placement.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  KumoTabPanel _panelOf(String value, String title, String body) =>
      KumoTabPanel(
        value: value,
        child: KumoLayerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s1,
            children: [
              KumoText(title, variant: KumoTextVariant.heading),
              _secondary(body),
            ],
          ),
        ),
      );
}

class _BreadcrumbsDemo extends StatefulWidget {
  const _BreadcrumbsDemo();

  @override
  State<_BreadcrumbsDemo> createState() => _BreadcrumbsDemoState();
}

class _BreadcrumbsDemoState extends State<_BreadcrumbsDemo> {
  String _last = 'nothing yet';
  bool _loading = true;

  List<KumoBreadcrumbsItem> get _trail => [
    KumoBreadcrumbsItem(
      label: 'Account home',
      icon: KumoIcons.house,
      onPress: () => setState(() => _last = 'Account home'),
    ),
    KumoBreadcrumbsItem(
      label: 'example.com',
      onPress: () => setState(() => _last = 'example.com'),
    ),
    KumoBreadcrumbsItem(
      label: 'DNS',
      onPress: () => setState(() => _last = 'DNS'),
    ),
    KumoBreadcrumbsItem(
      label: 'Records',
      onPress: () => setState(() => _last = 'Records'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Trail',
          caption:
              'Below 640px this becomes a back link to the parent. Last opened: $_last.',
          child: KumoBreadcrumbs(items: _trail, current: 'api.example.com'),
        ),
        DemoSection(
          title: 'Kumo mobile trail and full trail',
          caption:
              'The narrow layouts Kumo itself uses; the dots open the earlier pages.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KumoBreadcrumbs(
                items: _trail,
                current: 'api.example.com',
                narrowLayout: KumoBreadcrumbsNarrowLayout.trail,
              ),
              KumoBreadcrumbs(
                items: _trail,
                current: 'api.example.com',
                size: KumoBreadcrumbsSize.sm,
                narrowLayout: KumoBreadcrumbsNarrowLayout.full,
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Collapsing when tight',
          caption: 'In 320px the middle pages move into the More menu.',
          child: SizedBox(
            width: 320,
            child: KumoBreadcrumbs(
              items: _trail,
              current: 'api.example.com',
              narrowLayout: KumoBreadcrumbsNarrowLayout.full,
            ),
          ),
        ),
        DemoSection(
          title: 'Loading, root and copy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: KumoBreadcrumbs(
                      items: _trail.take(2).toList(),
                      current: 'Analytics',
                      loading: _loading,
                      narrowLayout: KumoBreadcrumbsNarrowLayout.full,
                    ),
                  ),
                  KumoButton(
                    label: _loading ? 'Finish loading' : 'Reload title',
                    size: KumoButtonSize.sm,
                    onPress: () => setState(() => _loading = !_loading),
                  ),
                ],
              ),
              const KumoBreadcrumbs(
                current: 'Worker analytics',
                currentIcon: KumoIcons.chartBar,
              ),
              KumoBreadcrumbs(
                items: _trail.take(1).toList(),
                current: 'image-resizer',
                copyText: 'https://dash.example.com/workers/image-resizer',
                narrowLayout: KumoBreadcrumbsNarrowLayout.full,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaginationDemo extends StatefulWidget {
  const _PaginationDemo();

  @override
  State<_PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<_PaginationDemo> {
  int _full = 1;
  int _simple = 1;
  int _dropdown = 3;
  int _sized = 1;
  int _perPage = 25;
  int _unknown = 1;
  int _empty = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Full controls',
          caption:
              '42 sample DNS records, 10 per page. Type a page number and press Enter.',
          child: KumoPagination(
            page: _full,
            onPageChange: (p) => setState(() => _full = p),
            perPage: 10,
            totalCount: 42,
          ),
        ),
        DemoSection(
          title: 'Simple controls',
          child: KumoPagination(
            page: _simple,
            onPageChange: (p) => setState(() => _simple = p),
            perPage: 10,
            totalCount: 100,
            controls: KumoPaginationControls.simple,
          ),
        ),
        DemoSection(
          title: 'Page menu',
          caption: 'For a handful of pages, pick the page from a list.',
          child: KumoPagination(
            page: _dropdown,
            onPageChange: (p) => setState(() => _dropdown = p),
            perPage: 20,
            totalCount: 120,
            pageSelector: KumoPaginationPageSelector.dropdown,
          ),
        ),
        DemoSection(
          title: 'Page size',
          caption:
              '500 sample Worker logs. Changing the size returns to page 1.',
          child: KumoPagination(
            page: _sized,
            onPageChange: (p) => setState(() => _sized = p),
            perPage: _perPage,
            totalCount: 500,
            onPerPageChange: (v) => setState(() {
              _perPage = v;
              _sized = 1;
            }),
          ),
        ),
        DemoSection(
          title: 'Unknown total',
          caption:
              'An API that only says whether another page exists (three sample pages).',
          child: KumoPagination(
            page: _unknown,
            onPageChange: (p) => setState(() => _unknown = p),
            hasNextPage: _unknown < 3,
            infoBuilder: (context, info) => _secondary('Page ${info.page}'),
          ),
        ),
        DemoSection(
          title: 'No results',
          caption:
              'The table shows the empty state; pagination stays on one disabled page.',
          child: KumoPagination(
            page: _empty,
            onPageChange: (p) => setState(() => _empty = p),
            perPage: 10,
            totalCount: 0,
          ),
        ),
      ],
    );
  }
}

class _LinkDemo extends StatefulWidget {
  const _LinkDemo();

  @override
  State<_LinkDemo> createState() => _LinkDemoState();
}

class _LinkDemoState extends State<_LinkDemo> {
  String _opened = 'nothing yet';

  void _open(String what) => setState(() => _opened = what);

  @override
  Widget build(BuildContext context) {
    final danger = context.kumo.text(color: KumoColor.textDanger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Variants',
          caption: 'Last opened: $_opened.',
          child: Wrap(
            spacing: KumoSpace.s6,
            runSpacing: KumoSpace.s2,
            children: [
              KumoLink(
                label: 'View deployment logs',
                onPress: () => _open('deployment logs'),
              ),
              DefaultTextStyle.merge(
                style: context.kumo.text(color: KumoColor.textSubtle),
                child: KumoLink(
                  label: 'Current color',
                  variant: KumoLinkVariant.current,
                  onPress: () => _open('current color'),
                ),
              ),
              KumoLink(
                label: 'Plain link',
                variant: KumoLinkVariant.plain,
                onPress: () => _open('plain link'),
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'External',
          caption: 'Screen readers hear that it opens a new window.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoLink(
              label: 'Workers documentation',
              external: true,
              onPress: () => _open('documentation'),
            ),
          ),
        ),
        DemoSection(
          title: 'In running text',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Read the '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: KumoLink(
                        label: 'routing guide',
                        padTapTarget: false,
                        onPress: () => _open('routing guide'),
                      ),
                    ),
                    const TextSpan(
                      text: ' before you add a custom domain to example.com.',
                    ),
                  ],
                ),
                style: context.kumo.text(),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'The API token expired. '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: DefaultTextStyle(
                        style: danger,
                        child: KumoLink(
                          label: 'Create a new token',
                          variant: KumoLinkVariant.current,
                          padTapTarget: false,
                          onPress: () => _open('new token'),
                        ),
                      ),
                    ),
                    const TextSpan(text: ' to keep deploying.'),
                  ],
                ),
                style: danger,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TocDemo extends StatefulWidget {
  const _TocDemo();

  @override
  State<_TocDemo> createState() => _TocDemoState();
}

class _TocDemoState extends State<_TocDemo> {
  static const _sections = [
    ('overview', 'Overview'),
    ('routes', 'Routes'),
    ('domains', 'Custom domains'),
    ('bindings', 'Bindings'),
    ('limits', 'Limits'),
  ];

  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _anchors = {
    for (final s in _sections) s.$1: GlobalKey(),
  };
  String? _manual = 'routes';

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toc = KumoTableOfContents(
      title: 'On this page',
      scrollController: _scroll,
      anchors: _anchors,
      items: const [
        KumoTableOfContentsItem(id: 'overview', label: 'Overview'),
        KumoTableOfContentsItem(
          id: 'routes',
          label: 'Routes',
          children: [
            KumoTableOfContentsItem(id: 'domains', label: 'Custom domains'),
          ],
        ),
        KumoTableOfContentsItem(id: 'bindings', label: 'Bindings'),
        KumoTableOfContentsItem(id: 'limits', label: 'Limits'),
      ],
    );
    final page = KumoLayerCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(
          horizontal: KumoSpace.s5,
          vertical: KumoSpace.s4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final s in _sections) ...[
              KumoText(
                s.$2,
                key: _anchors[s.$1],
                variant: KumoTextVariant.heading,
              ),
              const SizedBox(height: KumoSpace.s2),
              _secondary(
                'Sample settings for the image-resizer Worker: ${s.$2.toLowerCase()}.',
              ),
              SizedBox(height: s.$1 == 'limits' ? 60 : 220),
            ],
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Scroll tracking',
          caption:
              'Scroll the page or tap a section. Short sections stay highlighted after a tap.',
          child: SizedBox(
            height: 320,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s4,
              children: [
                SizedBox(width: 140, child: toc),
                Expanded(child: page),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Driven by the app',
          caption:
              'Without a scroll controller, activeId and onSelect are yours.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 220,
              child: KumoTableOfContents(
                activeId: _manual,
                onSelect: (id) => setState(() => _manual = id),
                items: const [
                  KumoTableOfContentsItem(id: 'intro', label: 'Introduction'),
                  KumoTableOfContentsItem(id: 'routes', label: 'Routes'),
                  KumoTableOfContentsItem(
                    id: 'api',
                    label: 'API reference',
                    selectable: false,
                    children: [
                      KumoTableOfContentsItem(
                        id: 'fetch',
                        label: 'fetch handler',
                      ),
                      KumoTableOfContentsItem(
                        id: 'scheduled',
                        label: 'scheduled handler',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CollapsibleDemo extends StatefulWidget {
  const _CollapsibleDemo();

  @override
  State<_CollapsibleDemo> createState() => _CollapsibleDemoState();
}

class _CollapsibleDemoState extends State<_CollapsibleDemo> {
  bool _basic = true;
  bool _custom = false;
  bool _form = false;
  final TextEditingController _date = TextEditingController(text: '2026-10-01');

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Default trigger and panel',
          child: KumoCollapsible(
            open: _basic,
            onOpenChange: (v) => setState(() => _basic = v),
            label: 'What does a route do?',
            child: const KumoText(
              'A route sends requests that match a pattern, such as example.com/api/*, to a Worker.',
            ),
          ),
        ),
        DemoSection(
          title: 'Custom trigger',
          child: KumoCollapsible(
            open: _custom,
            onOpenChange: (v) => setState(() => _custom = v),
            panelStyle: KumoCollapsiblePanelStyle.plain,
            triggerBuilder: (context, open, toggle) => KumoButton(
              label: open ? 'Hide bindings' : 'Show bindings',
              size: KumoButtonSize.sm,
              // Turns in step with the panel, reversible mid-flight.
              iconWidget: KumoDisclosureCaret(open: open, size: 14),
              onPress: toggle,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: KumoSpace.s3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.kumo.colors.tint,
                  borderRadius: BorderRadius.circular(KumoRadius.lg),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(KumoSpace.s4),
                  child: KumoText(
                    'R2 bucket assets, KV namespace sessions, D1 database analytics (sample data).',
                  ),
                ),
              ),
            ),
          ),
        ),
        DemoSection(
          title: 'Keeps form state',
          caption: 'Edit the date, close and reopen: the text stays.',
          child: KumoCollapsible(
            open: _form,
            keepMounted: true,
            onOpenChange: (v) => setState(() => _form = v),
            label: 'Advanced settings',
            child: KumoField(
              label: 'Compatibility date',
              child: KumoFieldBox(
                child: KumoEditable(
                  controller: _date,
                  placeholder: 'YYYY-MM-DD',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccordionDemo extends StatefulWidget {
  const _AccordionDemo();

  @override
  State<_AccordionDemo> createState() => _AccordionDemoState();
}

class _AccordionDemoState extends State<_AccordionDemo> {
  Set<String> _single = {'routes'};
  Set<String> _multiple = {};

  static const _items = [
    KumoAccordionItem(
      value: 'routes',
      title: 'Which requests reach this Worker?',
      child: Text(
        'Requests to example.com/api/* and to image-resizer.example.workers.dev.',
      ),
    ),
    KumoAccordionItem(
      value: 'limits',
      title: 'What are the CPU limits?',
      description: 'Standard usage model',
      child: Text('Each request can use up to 30 seconds of CPU time.'),
    ),
    KumoAccordionItem(
      value: 'legacy',
      title: 'Service bindings (legacy)',
      description: 'Not available on this account',
      disabled: true,
      child: Text('Migrate to the new bindings format.'),
    ),
    KumoAccordionItem(
      value: 'logs',
      title: 'Where do logs go?',
      icon: KumoIcons.listBullets,
      child: Text('Workers Logs keeps 3 days of sample request logs.'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Single',
          caption:
              'Opening one section closes the other. Up and Down move between headers.',
          child: KumoAccordion(
            items: _items,
            value: _single,
            onValueChange: (v) => setState(() => _single = v),
          ),
        ),
        DemoSection(
          title: 'Multiple',
          child: KumoAccordion(
            items: _items,
            type: KumoAccordionType.multiple,
            value: _multiple,
            onValueChange: (v) => setState(() => _multiple = v),
          ),
        ),
      ],
    );
  }
}

class _StepsDemo extends StatefulWidget {
  const _StepsDemo();

  @override
  State<_StepsDemo> createState() => _StepsDemoState();
}

class _StepsDemoState extends State<_StepsDemo> {
  int _current = 1;

  static const _steps = [
    KumoStepsItem(title: 'Add site', description: 'example.com'),
    KumoStepsItem(title: 'Review DNS', description: '12 records'),
    KumoStepsItem(title: 'Nameservers', description: 'At your registrar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        DemoSection(
          title: 'Automatic layout',
          caption:
              'Horizontal when there is room, vertical on phones. Tap an earlier step to go back.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s4,
            children: [
              KumoSteps(
                steps: _steps,
                current: _current,
                onStepPress: (i) {
                  if (i < _current) setState(() => _current = i);
                },
              ),
              Row(
                spacing: KumoSpace.s2,
                children: [
                  KumoButton(
                    label: 'Back',
                    size: KumoButtonSize.sm,
                    onPress: _current > 0
                        ? () => setState(() => _current--)
                        : null,
                  ),
                  KumoButton(
                    label: 'Advance',
                    size: KumoButtonSize.sm,
                    onPress: _current < _steps.length
                        ? () => setState(() => _current++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Every state, vertical',
          caption:
              'Each state has its own marker: number outline, filled number, check, cross.',
          child: KumoSteps(
            orientation: KumoStepsOrientation.vertical,
            current: 2,
            steps: [
              KumoStepsItem(title: 'Create R2 bucket', description: 'assets'),
              KumoStepsItem(title: 'Upload files', description: '48 files'),
              KumoStepsItem(
                title: 'Connect domain',
                description: 'cdn.example.com',
              ),
              KumoStepsItem(
                title: 'Verify certificate',
                description: 'DNS record not found',
                state: KumoStepsState.error,
              ),
            ],
          ),
        ),
        const DemoSection(
          title: 'Horizontal',
          child: KumoSteps(
            orientation: KumoStepsOrientation.horizontal,
            current: 0,
            steps: [
              KumoStepsItem(title: 'Plan'),
              KumoStepsItem(title: 'DNS'),
              KumoStepsItem(title: 'Done'),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperDemo extends StatefulWidget {
  const _StepperDemo();

  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  int _step = 0;
  bool _reviewed = false;
  bool _activated = false;

  @override
  Widget build(BuildContext context) {
    return DemoSection(
      title: 'Add a zone',
      caption: _activated
          ? 'example.com is active (sample flow).'
          : 'Check the review box to continue past step 2.',
      child: KumoStepper(
        value: _step,
        onValueChange: (v) => setState(() => _step = v),
        completeLabel: 'Activate zone',
        onComplete: () => setState(() => _activated = true),
        steps: [
          const KumoStepperStep(
            title: 'Add site',
            description: 'example.com',
            child: KumoText(
              'Cloudflare scans the existing DNS records for example.com.',
            ),
          ),
          KumoStepperStep(
            title: 'Review DNS records',
            description: '12 records found',
            canContinue: _reviewed,
            child: Row(
              spacing: KumoSpace.s2,
              children: [
                KumoButton(
                  label: _reviewed ? 'Reviewed' : 'Mark records as reviewed',
                  icon: _reviewed ? KumoIcons.check : null,
                  size: KumoButtonSize.sm,
                  onPress: () => setState(() => _reviewed = !_reviewed),
                ),
              ],
            ),
          ),
          const KumoStepperStep(
            title: 'Change nameservers',
            description: 'At your registrar',
            child: KumoText(
              'Replace the current nameservers with ada.ns.example.com and bob.ns.example.com.',
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationDemo extends StatefulWidget {
  const _BottomNavigationDemo();

  @override
  State<_BottomNavigationDemo> createState() => _BottomNavigationDemoState();
}

class _BottomNavigationDemoState extends State<_BottomNavigationDemo> {
  String _section = 'workers';
  int _alerts = 3;

  static const _titles = {
    'home': 'Account home',
    'workers': 'Workers',
    'alerts': 'Alerts',
    'account': 'Profile',
  };

  @override
  Widget build(BuildContext context) {
    return DemoSection(
      title: 'Phone tab bar',
      caption: 'Opening Alerts clears the sample unread count.',
      child: Center(
        child: SizedBox(
          width: 358,
          height: 360,
          child: KumoLayerCard(
            padding: EdgeInsets.zero,
            child: KumoBottomNavigation(
              value: _section,
              onValueChange: (v) => setState(() {
                _section = v;
                if (v == 'alerts') _alerts = 0;
              }),
              items: [
                const KumoBottomNavigationItem(
                  value: 'home',
                  label: 'Home',
                  icon: KumoIcons.house,
                  activeIcon: KumoIcons.houseFill,
                ),
                const KumoBottomNavigationItem(
                  value: 'workers',
                  label: 'Workers',
                  icon: KumoIcons.code,
                  activeIcon: KumoIcons.codeFill,
                ),
                KumoBottomNavigationItem(
                  value: 'alerts',
                  label: 'Alerts',
                  icon: KumoIcons.bell,
                  activeIcon: KumoIcons.bellFill,
                  badgeCount: _alerts,
                ),
                const KumoBottomNavigationItem(
                  value: 'account',
                  label: 'Profile',
                  icon: KumoIcons.user,
                  activeIcon: KumoIcons.userFill,
                ),
              ],
              body: ListView(
                padding: const EdgeInsets.all(KumoSpace.s4),
                children: [
                  KumoText(
                    _titles[_section]!,
                    variant: KumoTextVariant.heading,
                  ),
                  const SizedBox(height: KumoSpace.s2),
                  for (final name in const [
                    'image-resizer',
                    'auth-gateway',
                    'cron-cleanup',
                    'og-images',
                    'redirects',
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: KumoSpace.s2,
                      ),
                      child: KumoText(name, variant: KumoTextVariant.mono),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
