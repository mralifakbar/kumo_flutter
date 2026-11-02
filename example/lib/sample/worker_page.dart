import 'package:flutter/material.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../gallery/settings_scope.dart';
import 'console_app.dart';
import 'sample_data.dart';

/// A Worker's detail page: overview with a sample request chart, deployment
/// history with rollback, and settings with a danger zone.
class WorkerPage extends StatefulWidget {
  const WorkerPage({
    super.key,
    required this.worker,
    required this.onChanged,
    required this.onDeleted,
  });

  final SampleWorker worker;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;

  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    final kumo = context.kumo;
    final gutter = context.kumoIsNarrow ? KumoSpace.s4 : KumoSpace.s8;
    final content = switch (_tab) {
      'deployments' => _Deployments(worker: w, onRolledBack: widget.onChanged),
      'settings' => _Settings(
        worker: w,
        onChanged: () {
          setState(() {});
          widget.onChanged();
        },
        onDeleted: () {
          widget.onDeleted();
          // The confirmation dialog may still be on top; close back to this
          // page, then leave it.
          final page = ModalRoute.of(context);
          final navigator = Navigator.of(context);
          navigator.popUntil((r) => r == page);
          navigator.pop();
          showKumoToast(
            context,
            title: '${w.name} deleted',
            variant: KumoToastVariant.success,
          );
        },
      ),
      _ => _Overview(worker: w),
    };
    return Scaffold(
      backgroundColor: kumo.colors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: kumo.colors.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: gutter - KumoSpace.s2,
                  vertical: KumoSpace.s1,
                ),
                child: Row(
                  children: [
                    KumoButton(
                      icon: KumoIcons.arrowLeft,
                      shape: KumoButtonShape.square,
                      variant: KumoButtonVariant.ghost,
                      semanticLabel: 'Back to Workers',
                      onPress: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const ThemeModeButton(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  KumoSpace.s6,
                  gutter,
                  MediaQuery.paddingOf(context).bottom + KumoSpace.s8,
                ),
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          KumoPageHeader(
                            // Phones already have the back arrow in the top bar.
                            breadcrumbs: context.kumoIsNarrow
                                ? null
                                : KumoBreadcrumbs(
                                    items: [
                                      KumoBreadcrumbsItem(
                                        label: 'Workers',
                                        onPress: () =>
                                            Navigator.of(context).maybePop(),
                                      ),
                                    ],
                                    current: w.name,
                                  ),
                            title: w.name,
                            description: w.description,
                            tabs: const [
                              KumoPageHeaderTab(
                                label: 'Overview',
                                value: 'overview',
                              ),
                              KumoPageHeaderTab(
                                label: 'Deployments',
                                value: 'deployments',
                              ),
                              KumoPageHeaderTab(
                                label: 'Settings',
                                value: 'settings',
                              ),
                            ],
                            value: _tab,
                            onValueChange: (v) => setState(() => _tab = v),
                          ),
                          const SizedBox(height: KumoSpace.s6),
                          content,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.worker});

  final SampleWorker worker;

  @override
  Widget build(BuildContext context) {
    final now = consoleNow();
    final colors = KumoChartColors.of(context);
    final status = workerStatus(worker.health);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        if (worker.health == WorkerHealth.failing)
          KumoBanner(
            variant: KumoBannerVariant.error,
            title: 'The latest deployment is failing',
            description:
                'Requests to ${worker.route} return errors. Roll back to the previous version from Deployments.',
          )
        else if (worker.health == WorkerHealth.degraded)
          const KumoBanner(
            variant: KumoBannerVariant.alert,
            title: 'Error rate is above normal',
            description: 'Check recent logs before the next deploy.',
          ),
        KumoLayerCard(
          child: Wrap(
            spacing: KumoSpace.s8,
            runSpacing: KumoSpace.s4,
            children: [
              _Fact(
                label: 'Status',
                child: KumoBadge(
                  status.label,
                  variant: switch (status.tone) {
                    KumoResourceListStatusTone.success =>
                      KumoBadgeVariant.success,
                    KumoResourceListStatusTone.warning =>
                      KumoBadgeVariant.warning,
                    KumoResourceListStatusTone.danger => KumoBadgeVariant.error,
                    _ => KumoBadgeVariant.secondary,
                  },
                ),
              ),
              _Fact(
                label: 'Route',
                child: KumoText(worker.route, variant: KumoTextVariant.mono),
              ),
              _Fact(label: 'Last deploy', child: KumoText(worker.lastDeploy)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            const KumoText(
              'Requests in the last 24 hours',
              variant: KumoTextVariant.heading,
              headingLevel: 2,
            ),
            const KumoText(
              'Sample data, generated for this demo.',
              variant: KumoTextVariant.secondary,
              size: KumoTextSize.sm,
            ),
            KumoLayerCard(
              padding: const EdgeInsets.all(KumoSpace.s4),
              child: KumoTimeseriesChart(
                semanticLabel:
                    'Requests and errors for ${worker.name}, sample data',
                yAxisName: 'Requests',
                gradient: true,
                data: [
                  KumoTimeseriesData(
                    name: 'Requests',
                    color: colors.semantic(KumoChartSemanticColor.neutral),
                    data: worker.requests(now),
                  ),
                  KumoTimeseriesData(
                    name: 'Errors',
                    color: colors.semantic(KumoChartSemanticColor.attention),
                    data: worker.errors(now),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: KumoSpace.s1,
    children: [
      KumoText(
        label,
        variant: KumoTextVariant.secondary,
        size: KumoTextSize.sm,
      ),
      child,
    ],
  );
}

class _Deployments extends StatefulWidget {
  const _Deployments({required this.worker, required this.onRolledBack});

  final SampleWorker worker;
  final VoidCallback onRolledBack;

  @override
  State<_Deployments> createState() => _DeploymentsState();
}

class _DeploymentsState extends State<_Deployments> {
  Future<void> _rollBack(SampleDeployment d) async {
    final confirmed = await showKumoAlertDialog(
      context,
      title: 'Roll back to ${d.version}?',
      description:
          '${widget.worker.name} will serve "${d.message}" again. You can redeploy the current version later.',
      confirmLabel: 'Roll back',
    );
    if (confirmed != true || !mounted) return;
    setState(() => widget.worker.health = WorkerHealth.healthy);
    widget.onRolledBack();
    showKumoToast(
      context,
      title: 'Rolled back to ${d.version}',
      description: 'Sample data updated.',
      variant: KumoToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.worker.deployments;
    return KumoLayerCard(
      child: KumoTimeline(
        items: [
          for (var i = 0; i < items.length; i++)
            KumoTimelineItem(
              title: '${items[i].version}: ${items[i].message}',
              time: items[i].ago,
              description: 'Deployed by ${items[i].author}',
              status: items[i].failed
                  ? KumoTimelineStatus.danger
                  : (i == 0
                        ? KumoTimelineStatus.success
                        : KumoTimelineStatus.neutral),
              statusLabel: items[i].failed
                  ? 'Failed'
                  : (i == 0 ? 'Current' : 'Previous'),
              trailing: i == 0 || items[i].failed
                  ? null
                  : KumoButton(
                      label: 'Roll back',
                      size: KumoButtonSize.sm,
                      onPress: () => _rollBack(items[i]),
                    ),
            ),
        ],
      ),
    );
  }
}

class _Settings extends StatefulWidget {
  const _Settings({
    required this.worker,
    required this.onChanged,
    required this.onDeleted,
  });

  final SampleWorker worker;
  final VoidCallback onChanged;
  final VoidCallback onDeleted;

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _deleteOpen = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KumoSpace.s6,
      children: [
        KumoLayerCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s5,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s1,
                children: [
                  KumoSwitch(
                    label: 'Workers Logs',
                    checked: w.logsEnabled,
                    onCheckedChange: (v) {
                      setState(() => w.logsEnabled = v);
                      widget.onChanged();
                    },
                  ),
                  const KumoText(
                    'Keeps request logs for 3 days.',
                    variant: KumoTextVariant.secondary,
                    size: KumoTextSize.sm,
                  ),
                ],
              ),
              KumoSelect<String>(
                label: 'Compatibility date',
                description: 'Runtime behavior is pinned to this date.',
                value: w.compatibilityDate,
                onValueChange: (v) {
                  if (v == null) return;
                  setState(() => w.compatibilityDate = v);
                  widget.onChanged();
                },
                options: const [
                  KumoSelectOption(value: '2026-09-01', label: '2026-09-01'),
                  KumoSelectOption(value: '2026-06-01', label: '2026-06-01'),
                  KumoSelectOption(value: '2026-01-15', label: '2026-01-15'),
                ],
              ),
            ],
          ),
        ),
        KumoLayerCard.layered(
          children: [
            const KumoLayerCardSecondary(child: Text('Danger zone')),
            KumoLayerCardPrimary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s3,
                children: [
                  const KumoText(
                    'Deleting a Worker removes its code and routes. Requests to its routes go to the origin.',
                  ),
                  KumoDeleteResource(
                    open: _deleteOpen,
                    onOpenChange: (v) => setState(() => _deleteOpen = v),
                    resourceType: 'Worker',
                    resourceName: w.name,
                    isDeleting: _deleting,
                    onDelete: () async {
                      setState(() => _deleting = true);
                      await Future<void>.delayed(
                        const Duration(milliseconds: 600),
                      );
                      if (!mounted) return;
                      setState(() {
                        _deleting = false;
                        _deleteOpen = false;
                      });
                      widget.onDeleted();
                    },
                    child: KumoButton(
                      label: 'Delete Worker',
                      variant: KumoButtonVariant.destructive,
                      onPress: () => setState(() => _deleteOpen = true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
