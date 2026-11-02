import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// The app frame and page blocks: sidebar, responsive shell, page header,
/// resource list and delete confirmation. Every Worker, zone and namespace
/// here is sample data.
final KumoDemoCategory shellCategory = KumoDemoCategory(
  title: 'App shell and blocks',
  description:
      'Sidebar navigation, the responsive app frame and page-level blocks. Resources shown are sample data.',
  icon: KumoIcons.sidebar,
  demos: [
    KumoDemo(
      title: 'KumoSidebar',
      description:
          'Groups, nested sections, badges, sliding views, the icon rail, loading and resizing.',
      docPath: 'doc/components/KumoSidebar.md',
      builder: (_) => const _SidebarDemo(),
    ),
    KumoDemo(
      title: 'KumoAppShell',
      description:
          'The same app in narrow, medium and wide layouts, with a swipeable drawer and bottom bar.',
      docPath: 'doc/components/KumoAppShell.md',
      builder: (_) => const _AppShellDemo(),
    ),
    KumoDemo(
      title: 'KumoPageHeader',
      description:
          'Breadcrumbs, a title and description, segmented tabs and actions that wrap on phones.',
      docPath: 'doc/components/KumoPageHeader.md',
      builder: (_) => const _PageHeaderDemo(),
    ),
    KumoDemo(
      title: 'KumoResourceList',
      description:
          'A resource page with status, actions, an aside, and loading, empty and error states.',
      docPath: 'doc/components/KumoResourceList.md',
      builder: (_) => const _ResourceListDemo(),
    ),
    KumoDemo(
      title: 'KumoDeleteResource',
      description:
          'Type-to-confirm deletion with copy, progress and a failed attempt.',
      docPath: 'doc/components/KumoDeleteResource.md',
      builder: (_) => const _DeleteResourceDemo(),
    ),
  ],
);

Widget _column(List<Widget> children) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: KumoSpace.s8,
  children: children,
);

/// A bordered box that holds a full-height frame inside the gallery page.
class _Frame extends StatelessWidget {
  const _Frame({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: c.base,
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        border: KumoRing.border(c.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(KumoRadius.lg),
        // The device's notch and home indicator belong to the gallery, not
        // to this preview.
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          removeLeft: true,
          removeRight: true,
          child: child,
        ),
      ),
    );
  }
}

/// One of a few labeled options, as a single-select [KumoToggleGroup].
Widget _choice<T>({
  required String label,
  required Map<T, String> options,
  required T value,
  required ValueChanged<T> onChange,
}) => Align(
  alignment: AlignmentDirectional.centerStart,
  child: KumoToggleGroup<T>(
    semanticLabel: label,
    size: KumoToggleSize.sm,
    allowDeselect: false,
    value: value,
    onValueChange: (v) {
      if (v != null) onChange(v);
    },
    items: [
      for (final e in options.entries)
        KumoToggleGroupItem(value: e.key, label: e.value),
    ],
  ),
);

class _Brand extends StatelessWidget {
  const _Brand();

  static const String name = 'Acme Inc';

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
        child: Row(
          spacing: KumoSpace.s2,
          children: [
            const KumoIcon(KumoIcons.cubeFill, color: KumoColor.brand),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.kumo.text(
                  size: KumoTextSize.sm,
                  weight: KumoTypography.semibold,
                  color: KumoColor.textStrong,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Account and zone navigation used by the sidebar and shell demos.
class _DemoNav extends StatelessWidget {
  const _DemoNav({
    required this.current,
    required this.onSelect,
    required this.surface,
    required this.onSurface,
  });

  final String current;
  final ValueChanged<String> onSelect;
  final String surface;
  final ValueChanged<String> onSurface;

  @override
  Widget build(BuildContext context) {
    KumoSidebarMenuButton row(IconData icon, String label, {String? badge}) =>
        KumoSidebarMenuButton(
          icon: icon,
          label: label,
          badge: badge,
          active: current == label,
          onPress: () => onSelect(label),
        );
    KumoSidebarMenuSubButton sub(String label, {String? badge}) =>
        KumoSidebarMenuSubButton(
          label: label,
          badge: badge,
          active: current == label,
          onPress: () => onSelect(label),
        );
    return KumoSidebarSlidingViews(
      activeKey: surface,
      children: [
        KumoSidebarSlidingView(
          value: 'account',
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(
                children: [
                  row(KumoIcons.house, 'Account home'),
                  row(KumoIcons.chartBar, 'Analytics and logs'),
                  KumoSidebarMenuButton(
                    icon: KumoIcons.globe,
                    label: 'Domains',
                    trailing: const KumoIcon(KumoIcons.caretRight, size: 12),
                    onPress: () => onSurface('zone'),
                  ),
                ],
              ),
              KumoSidebarGroup(
                label: 'Build',
                children: [
                  KumoSidebarCollapsible(
                    icon: KumoIcons.code,
                    label: 'Compute',
                    initialOpen: true,
                    children: [
                      KumoSidebarCollapsible(
                        label: 'Workers and Pages',
                        children: [
                          sub('Overview'),
                          sub('Workers'),
                          sub('Pages'),
                        ],
                      ),
                      sub('Durable Objects'),
                      sub('Containers', badge: 'Beta'),
                    ],
                  ),
                  KumoSidebarCollapsible(
                    icon: KumoIcons.database,
                    label: 'Storage',
                    children: [
                      sub('R2 buckets'),
                      sub('KV namespaces'),
                      sub('D1 databases'),
                    ],
                  ),
                ],
              ),
              KumoSidebarGroup(
                label: 'Protect and connect',
                children: [
                  row(KumoIcons.shieldCheck, 'Security'),
                  row(KumoIcons.lock, 'Zero Trust', badge: 'Beta'),
                ],
              ),
            ],
          ),
        ),
        KumoSidebarSlidingView(
          value: 'zone',
          child: KumoSidebarContent(
            children: [
              KumoSidebarGroup(
                children: [
                  KumoSidebarMenuButton(
                    icon: KumoIcons.arrowLeft,
                    label: 'All domains',
                    onPress: () => onSurface('account'),
                  ),
                ],
              ),
              KumoSidebarGroup(
                label: 'example.com',
                children: [
                  row(KumoIcons.globe, 'Overview'),
                  row(KumoIcons.listBullets, 'DNS records'),
                  row(KumoIcons.lock, 'SSL/TLS'),
                  row(KumoIcons.lightning, 'Caching'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarDemo extends StatefulWidget {
  const _SidebarDemo();

  @override
  State<_SidebarDemo> createState() => _SidebarDemoState();
}

class _SidebarDemoState extends State<_SidebarDemo> {
  bool open = true;
  String current = 'Workers';
  String surface = 'account';
  bool loading = false;
  bool resizableOpen = true;
  double width = 240;

  @override
  Widget build(BuildContext context) {
    Widget page(String text) => Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(KumoSpace.s4),
          child: KumoText(
            text,
            variant: KumoTextVariant.secondary,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
    return _column([
      DemoSection(
        title: 'Full sidebar',
        caption:
            'Press the panel button in the footer to collapse to the icon rail; hover or long-press an icon '
            'for its label. "Domains" slides to the zone view.',
        child: _Frame(
          height: 560,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KumoSidebar(
                open: open,
                onOpenChange: (v) => setState(() => open = v),
                header: const KumoSidebarHeader(children: [_Brand()]),
                footer: const KumoSidebarFooter(
                  children: [KumoSidebarTrigger()],
                ),
                child: _DemoNav(
                  current: current,
                  onSelect: (v) => setState(() => current = v),
                  surface: surface,
                  onSurface: (v) => setState(() => surface = v),
                ),
              ),
              page('Current page: $current'),
            ],
          ),
        ),
      ),
      DemoSection(
        title: 'Loading',
        caption:
            'Still placeholder rows while routes load. They keep the rail shape when collapsed.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            KumoButton(
              label: loading ? 'Show navigation' : 'Show loading state',
              size: KumoButtonSize.sm,
              onPress: () => setState(() => loading = !loading),
            ),
            _Frame(
              height: 360,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KumoSidebar(
                    loading: loading,
                    loadingLabel: 'Loading navigation',
                    header: const KumoSidebarHeader(children: [_Brand()]),
                    footer: const KumoSidebarFooter(
                      children: [KumoSidebarTrigger()],
                    ),
                    child: KumoSidebarContent(
                      children: [
                        KumoSidebarGroup(
                          children: [
                            KumoSidebarMenuButton(
                              icon: KumoIcons.house,
                              label: 'Account home',
                              active: true,
                              onPress: () {},
                            ),
                            KumoSidebarMenuButton(
                              icon: KumoIcons.code,
                              label: 'Workers',
                              onPress: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  page(loading ? 'Loading navigation' : 'Navigation loaded'),
                ],
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Resizable and small rows',
        caption:
            'Drag the inner edge, or focus it and use the arrow keys. Dragging past 200px collapses it.',
        child: _Frame(
          height: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = (constraints.maxWidth - 80).clamp(200.0, 480.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KumoSidebar(
                    open: resizableOpen,
                    onOpenChange: (v) => setState(() => resizableOpen = v),
                    width: width.clamp(200.0, maxWidth),
                    maxWidth: maxWidth,
                    onWidthChange: (w) => setState(() => width = w),
                    footer: const KumoSidebarFooter(
                      children: [KumoSidebarTrigger()],
                    ),
                    child: KumoSidebarContent(
                      children: [
                        KumoSidebarGroup(
                          label: 'API tokens',
                          children: [
                            for (final t in [
                              'Deploy Workers',
                              'Edit DNS',
                              'Read analytics',
                            ])
                              KumoSidebarMenuButton(
                                icon: KumoIcons.key,
                                label: t,
                                size: KumoSidebarMenuButtonSize.sm,
                                onPress: () {},
                              ),
                            const KumoSidebarSeparator(),
                            KumoSidebarMenuButton(
                              icon: KumoIcons.plus,
                              label: 'Create token',
                              size: KumoSidebarMenuButtonSize.sm,
                              onPress: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  page('${width.round()} px'),
                ],
              );
            },
          ),
        ),
      ),
    ]);
  }
}

class _AppShellDemo extends StatefulWidget {
  const _AppShellDemo();

  @override
  State<_AppShellDemo> createState() => _AppShellDemoState();
}

class _AppShellDemoState extends State<_AppShellDemo> {
  KumoAppShellLayout layout = KumoAppShellLayout.narrow;
  String current = 'Workers';
  String surface = 'account';
  bool bottomBar = true;

  @override
  Widget build(BuildContext context) {
    final sidebar = KumoSidebar(
      header: const KumoSidebarHeader(children: [_Brand(), KumoSidebarClose()]),
      footer: const KumoSidebarFooter(children: [KumoSidebarTrigger()]),
      child: _DemoNav(
        current: current,
        onSelect: (v) => setState(() => current = v),
        surface: surface,
        onSurface: (v) => setState(() => surface = v),
      ),
    );
    return _column([
      DemoSection(
        title: 'Responsive frame',
        caption:
            'Narrow: tap Menu or swipe from the left edge; flick or tap outside to close. '
            'Medium starts as the rail; wide keeps the sidebar open. Apps pick the layout from the width.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            _choice<KumoAppShellLayout>(
              label: 'Layout',
              options: const {
                KumoAppShellLayout.narrow: 'Narrow',
                KumoAppShellLayout.medium: 'Medium',
                KumoAppShellLayout.wide: 'Wide',
              },
              value: layout,
              onChange: (v) => setState(() => layout = v),
            ),
            KumoSwitch(
              label: 'Bottom navigation',
              checked: bottomBar,
              onCheckedChange: (v) => setState(() => bottomBar = v),
            ),
            _Frame(
              height: 620,
              child: KumoAppShell(
                layout: layout,
                sidebar: sidebar,
                topBar: Row(
                  spacing: KumoSpace.s2,
                  children: [
                    Expanded(
                      child: KumoText(
                        current,
                        variant: KumoTextVariant.heading,
                        truncate: true,
                      ),
                    ),
                    KumoButton(
                      icon: KumoIcons.bell,
                      shape: KumoButtonShape.square,
                      variant: KumoButtonVariant.ghost,
                      size: KumoButtonSize.sm,
                      semanticLabel: 'Notifications',
                      onPress: () {},
                    ),
                  ],
                ),
                bottomNavigation: bottomBar
                    ? KumoBottomNavigation(
                        value: _bottomItems.any((i) => i.value == current)
                            ? current
                            : _bottomItems.first.value,
                        onValueChange: (v) => setState(() => current = v),
                        items: _bottomItems,
                      )
                    : null,
                body: ListView(
                  padding: const EdgeInsets.all(KumoSpace.s4),
                  children: [
                    for (final w in [
                      'image-resizer',
                      'auth-gateway',
                      'cron-cleanup',
                      'webhook-relay',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: KumoSpace.s3),
                        child: KumoResourceListItem(
                          title: w,
                          mono: true,
                          metadata: const ['Sample Worker'],
                          onPress: () {},
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

const List<KumoBottomNavigationItem> _bottomItems = [
  KumoBottomNavigationItem(
    value: 'Account home',
    label: 'Home',
    icon: KumoIcons.house,
    activeIcon: KumoIcons.houseFill,
  ),
  KumoBottomNavigationItem(
    value: 'Workers',
    label: 'Workers',
    icon: KumoIcons.code,
    activeIcon: KumoIcons.codeFill,
  ),
  KumoBottomNavigationItem(
    value: 'Security',
    label: 'Security',
    icon: KumoIcons.shieldCheck,
    activeIcon: KumoIcons.shieldCheckFill,
  ),
];

/// A breadcrumb trail for the page header demos: every crumb but the last
/// is a link (to nowhere, in this sample).
Widget _crumbs(List<String> trail) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s3),
  child: KumoBreadcrumbs(
    items: [
      for (var i = 0; i < trail.length - 1; i++)
        KumoBreadcrumbsItem(
          label: trail[i],
          icon: i == 0 ? KumoIcons.house : null,
          onPress: () {},
        ),
    ],
    current: trail.last,
  ),
);

class _PageHeaderDemo extends StatefulWidget {
  const _PageHeaderDemo();

  @override
  State<_PageHeaderDemo> createState() => _PageHeaderDemoState();
}

class _PageHeaderDemoState extends State<_PageHeaderDemo> {
  String tab = 'overview';
  String settingsTab = 'general';

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Breadcrumbs only',
        child: KumoPageHeader(
          breadcrumbs: _crumbs(['Account home', 'Workers and Pages']),
        ),
      ),
      DemoSection(
        title: 'Title and description',
        child: KumoPageHeader(
          breadcrumbs: _crumbs(['Account home', 'R2', 'assets']),
          title: 'assets',
          description:
              'Object storage for the images and fonts your sites serve. Upload with the dashboard or the S3 API.',
        ),
      ),
      DemoSection(
        title: 'Tabs and actions',
        caption:
            'On phones the actions move under the tabs and the tabs scroll sideways.',
        child: KumoPageHeader(
          breadcrumbs: _crumbs([
            'Account home',
            'Workers and Pages',
            'image-resizer',
          ]),
          tabs: const [
            KumoPageHeaderTab(label: 'Overview', value: 'overview'),
            KumoPageHeaderTab(label: 'Metrics', value: 'metrics'),
            KumoPageHeaderTab(label: 'Deployments', value: 'deployments'),
            KumoPageHeaderTab(label: 'Bindings', value: 'bindings'),
            KumoPageHeaderTab(label: 'Settings', value: 'settings'),
          ],
          value: tab,
          onValueChange: (v) => setState(() => tab = v),
          actions: [
            KumoButton(
              label: 'Edit code',
              icon: KumoIcons.code,
              size: KumoButtonSize.sm,
              onPress: () {},
            ),
            KumoButton(
              label: 'Visit',
              icon: KumoIcons.globe,
              size: KumoButtonSize.sm,
              variant: KumoButtonVariant.primary,
              onPress: () {},
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Complete, relaxed spacing',
        child: KumoPageHeader(
          spacing: KumoPageHeaderSpacing.relaxed,
          breadcrumbs: _crumbs([
            'Account home',
            'Manage account',
            'API tokens',
          ]),
          title: 'API tokens',
          description:
              'Create tokens that let scripts and CI call the API with only the permissions they need.',
          tabs: const [
            KumoPageHeaderTab(label: 'General', value: 'general'),
            KumoPageHeaderTab(label: 'Audit log', value: 'audit'),
          ],
          value: settingsTab,
          onValueChange: (v) => setState(() => settingsTab = v),
          actions: [
            KumoButton(
              label: 'Export',
              variant: KumoButtonVariant.outline,
              size: KumoButtonSize.sm,
              onPress: () {},
            ),
            KumoButton(
              label: 'Create token',
              icon: KumoIcons.plus,
              variant: KumoButtonVariant.primary,
              size: KumoButtonSize.sm,
              onPress: () {},
            ),
          ],
        ),
      ),
    ]);
  }
}

enum _ListState { ready, loading, empty, error }

class _ResourceListDemo extends StatefulWidget {
  const _ResourceListDemo();

  @override
  State<_ResourceListDemo> createState() => _ResourceListDemoState();
}

class _ResourceListDemoState extends State<_ResourceListDemo> {
  _ListState state = _ListState.ready;
  bool legacyArchived = false;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final usage = KumoLayerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: KumoSpace.s2,
        children: [
          Text('Read and write from a Worker', style: kumo.heading()),
          Text(
            "const value = await env.CACHE.get('greeting');\nawait env.CACHE.put('greeting', 'hello');",
            style: kumo.code(),
          ),
        ],
      ),
    );
    return _column([
      DemoSection(
        title: 'States',
        caption:
            'Switch between the list, its loading placeholders, the empty state and a failed load; '
            'they cross-fade. Archive legacy-sessions to watch its card collapse out.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            _choice<_ListState>(
              label: 'List state',
              options: const {
                _ListState.ready: 'List',
                _ListState.loading: 'Loading',
                _ListState.empty: 'Empty',
                _ListState.error: 'Error',
              },
              value: state,
              onChange: (v) => setState(() => state = v),
            ),
            if (legacyArchived)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: KumoButton(
                  label: 'Restore legacy-sessions',
                  size: KumoButtonSize.sm,
                  onPress: () => setState(() => legacyArchived = false),
                ),
              ),
            _Frame(
              height: 720,
              child: KumoResourceList(
                title: 'KV namespaces',
                description:
                    'Store key-value data globally with low-latency reads.',
                icon: KumoIcons.database,
                actions: [
                  KumoButton(
                    label: 'Create namespace',
                    icon: KumoIcons.plus,
                    variant: KumoButtonVariant.primary,
                    onPress: () {},
                  ),
                ],
                usage: usage,
                loading: state == _ListState.loading,
                loadingLabel: 'Loading KV namespaces',
                error: state == _ListState.error
                    ? 'Could not load KV namespaces. Check your connection and try again.'
                    : null,
                onRetry: () => setState(() => state = _ListState.ready),
                empty: KumoResourceListEmpty(
                  title: 'No KV namespaces yet',
                  description:
                      'Create a namespace, then bind it to a Worker to read and write keys.',
                  icon: KumoIcons.database,
                  action: KumoButton(
                    label: 'Create namespace',
                    variant: KumoButtonVariant.primary,
                    onPress: () => setState(() => state = _ListState.ready),
                  ),
                ),
                children: state == _ListState.empty
                    ? const []
                    : [
                        KumoResourceListItem(
                          key: const ValueKey('production-cache'),
                          title: 'production-cache',
                          mono: true,
                          metadata: const [
                            'Created 2 days ago',
                            'Bound to 3 Workers',
                          ],
                          status: const KumoResourceListStatus(
                            label: 'Active',
                            tone: KumoResourceListStatusTone.success,
                          ),
                          actions: [
                            KumoButton(
                              label: 'View keys',
                              size: KumoButtonSize.sm,
                              onPress: () {},
                            ),
                          ],
                          onPress: () {},
                        ),
                        KumoResourceListItem(
                          key: const ValueKey('staging-cache'),
                          title: 'staging-cache',
                          mono: true,
                          metadata: const [
                            'Created 1 week ago',
                            'Bound to 1 Worker',
                          ],
                          status: const KumoResourceListStatus(
                            label: 'Read only',
                            tone: KumoResourceListStatusTone.warning,
                          ),
                          actions: [
                            KumoButton(
                              label: 'View keys',
                              size: KumoButtonSize.sm,
                              onPress: () {},
                            ),
                          ],
                          onPress: () {},
                        ),
                        if (!legacyArchived)
                          KumoResourceListItem(
                            key: const ValueKey('legacy-sessions'),
                            title: 'legacy-sessions',
                            mono: true,
                            metadata: const ['Created 1 year ago', 'Not bound'],
                            status: const KumoResourceListStatus(
                              label: 'Unused',
                              tone: KumoResourceListStatusTone.neutral,
                            ),
                            actions: [
                              KumoButton(
                                label: 'Archive',
                                size: KumoButtonSize.sm,
                                onPress: () =>
                                    setState(() => legacyArchived = true),
                              ),
                            ],
                            onPress: () {},
                          ),
                      ],
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

class _DeleteResourceDemo extends StatefulWidget {
  const _DeleteResourceDemo();

  @override
  State<_DeleteResourceDemo> createState() => _DeleteResourceDemoState();
}

class _DeleteResourceDemoState extends State<_DeleteResourceDemo> {
  String? openFor;
  bool deleting = false;
  String? error;
  String? result;

  Future<void> _delete(String name, {bool fail = false}) async {
    setState(() {
      deleting = true;
      error = null;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      deleting = false;
      if (fail) {
        error =
            'Could not delete $name. It still has active DNS records; remove them and try again.';
      } else {
        openFor = null;
        result = 'Deleted $name (sample data, nothing was removed).';
      }
    });
  }

  Widget _flow({
    required String type,
    required String name,
    required String button,
    bool fail = false,
  }) {
    return KumoDeleteResource(
      open: openFor == name,
      onOpenChange: (v) => setState(() {
        openFor = v ? name : null;
        if (!v) error = null;
      }),
      resourceType: type,
      resourceName: name,
      isDeleting: deleting && openFor == name,
      errorMessage: openFor == name ? error : null,
      onDelete: () => _delete(name, fail: fail),
      child: KumoButton(
        label: button,
        variant: KumoButtonVariant.destructive,
        icon: KumoIcons.trash,
        onPress: () => setState(() {
          result = null;
          openFor = name;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _column([
      DemoSection(
        title: 'Type to confirm',
        caption:
            'Delete stays disabled until the name matches. Tap the name to copy it.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KumoSpace.s3,
          children: [
            Wrap(
              spacing: KumoSpace.s2,
              runSpacing: KumoSpace.s2,
              children: [
                _flow(type: 'Zone', name: 'example.com', button: 'Delete zone'),
                _flow(
                  type: 'Worker',
                  name: 'image-resizer',
                  button: 'Delete Worker',
                ),
              ],
            ),
            if (result != null)
              KumoText(result!, variant: KumoTextVariant.secondary),
          ],
        ),
      ),
      DemoSection(
        title: 'Failed delete',
        caption:
            'The attempt fails after two seconds and the error appears in the dialog.',
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: _flow(
            type: 'Zone',
            name: 'staging.example.com',
            button: 'Delete zone',
            fail: true,
          ),
        ),
      ),
    ]);
  }
}
