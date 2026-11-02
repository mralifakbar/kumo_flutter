import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Dialogs, drawers, toasts and banners.
final KumoDemoCategory dialogsCategory = KumoDemoCategory(
  title: 'Dialogs and feedback',
  description: 'Modal dialogs, side drawers, toasts and inline banners.',
  icon: KumoIcons.chatCircle,
  demos: [
    KumoDemo(
      title: 'KumoDialog',
      description: 'A modal panel near the top of the screen, opened imperatively or kept mounted with KumoDialogRoot.',
      docPath: 'doc/components/KumoDialog.md',
      builder: (_) => const _DialogDemo(),
    ),
    KumoDemo(
      title: 'showKumoAlertDialog',
      description: 'A confirmation that returns true only when the user picks the confirm action.',
      docPath: 'doc/components/showKumoAlertDialog.md',
      builder: (_) => const _AlertDialogDemo(),
    ),
    KumoDemo(
      title: 'KumoLayerDialog',
      description: 'A strict responsive dialog: a centered panel on wide screens, a bottom sheet on phones.',
      docPath: 'doc/components/KumoLayerDialog.md',
      builder: (_) => const _LayerDialogDemo(),
    ),
    KumoDemo(
      title: 'KumoDrawer',
      description: 'A panel attached to a screen edge that follows the finger and flicks away.',
      docPath: 'doc/components/KumoDrawer.md',
      builder: (_) => const _DrawerDemo(),
    ),
    KumoDemo(
      title: 'KumoToast',
      description: 'Brief notifications that stack in a corner, pause on hover and swipe away.',
      docPath: 'doc/components/KumoToast.md',
      builder: (_) => const _ToastDemo(),
    ),
    KumoDemo(
      title: 'KumoBanner',
      description: 'Inline messages for information, warnings and errors, with accent-tinted actions.',
      docPath: 'doc/components/KumoBanner.md',
      builder: (_) => const _BannerDemo(),
    ),
  ],
);

class _DemoColumn extends StatelessWidget {
  const _DemoColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: KumoSpace.s8,
      children: children,
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: KumoSpace.s2, runSpacing: KumoSpace.s2, children: children);
}

class _ResultLine extends StatelessWidget {
  const _ResultLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: KumoSpace.s2),
        child: KumoText(text, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
      );
}

// KumoDialog

class _DialogDemo extends StatefulWidget {
  const _DialogDemo();

  @override
  State<_DialogDemo> createState() => _DialogDemoState();
}

class _DialogDemoState extends State<_DialogDemo> {
  String _renameResult = 'No choice yet';
  bool _editOpen = false;
  bool _saving = false;
  String _ttl = 'Auto';

  Future<void> _rename() async {
    final result = await showKumoDialog<String>(
      context,
      builder: (context) => KumoDialog(
        title: 'Rename Worker',
        description: 'image-resizer keeps its routes. Its workers.dev URL changes to the new name.',
        actions: const [
          KumoDialogClose(label: 'Cancel'),
          KumoDialogClose(label: 'Rename to thumbnailer', variant: KumoButtonVariant.primary, result: 'thumbnailer'),
        ],
      ),
    );
    if (mounted) setState(() => _renameResult = result == null ? 'Dismissed' : 'Renamed to $result');
  }

  void _openSize(KumoDialogSize size) {
    showKumoDialog<void>(
      context,
      builder: (context) => KumoDialog(
        size: size,
        title: 'Dialog ${size.name}',
        description: 'This panel is ${size.width.toInt()}px wide on desktop and full width minus 16px gutters on phones.',
        actions: const [KumoDialogClose(label: 'Close')],
      ),
    );
  }

  void _openAlertRole() {
    showKumoDialog<void>(
      context,
      role: KumoDialogRole.alertDialog,
      builder: (context) => const KumoDialog(
        title: 'Revoke API token?',
        description: 'Scripts using the token "ci-deploy" stop authenticating right away.',
        actions: [
          KumoDialogClose(label: 'Keep token'),
          KumoDialogClose(label: 'Revoke token', variant: KumoButtonVariant.destructive),
        ],
      ),
    );
  }

  void _openLong() {
    showKumoDialog<void>(
      context,
      builder: (context) => KumoDialog(
        size: KumoDialogSize.lg,
        title: 'Review DNS records',
        description: 'Sample records for example.com. The header and footer stay put while the list scrolls.',
        actions: const [
          KumoDialogClose(label: 'Cancel'),
          KumoDialogClose(label: 'Import 24 records', variant: KumoButtonVariant.primary),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s2,
          children: [
            for (var i = 1; i <= 24; i++)
              Row(
                spacing: KumoSpace.s3,
                children: [
                  const KumoText('A', variant: KumoTextVariant.mono),
                  Expanded(child: KumoText('app$i.example.com', truncate: true)),
                  KumoText('192.0.2.$i', variant: KumoTextVariant.monoSecondary),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DemoColumn(children: [
      DemoSection(
        title: 'Basic',
        caption: 'Title, description, a close X and two choices. The result comes back from showKumoDialog.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KumoButton(label: 'Rename Worker', onPress: _rename),
            _ResultLine(_renameResult),
          ],
        ),
      ),
      DemoSection(
        title: 'Sizes',
        child: _Buttons(children: [
          for (final size in KumoDialogSize.values) KumoButton(label: 'Open ${size.name}', onPress: () => _openSize(size)),
        ]),
      ),
      DemoSection(
        title: 'Alert dialog role',
        caption: 'The backdrop does not close it and there is no X. Escape still cancels.',
        child: _Buttons(children: [
          KumoButton(label: 'Revoke token', variant: KumoButtonVariant.secondaryDestructive, onPress: _openAlertRole),
        ]),
      ),
      DemoSection(
        title: 'Long content',
        caption: 'The body scrolls inside the panel; hairlines appear under the header and above the footer.',
        child: _Buttons(children: [KumoButton(label: 'Review DNS records', onPress: _openLong)]),
      ),
      DemoSection(
        title: 'Kept mounted with KumoDialogRoot',
        caption: 'The dialog reads live state: pick a TTL, then save. It closes when the save finishes.',
        child: KumoDialogRoot(
          open: _editOpen,
          onOpenChange: (open) => setState(() => _editOpen = open),
          dialog: KumoDialog(
            title: 'Edit DNS record',
            description: 'api.example.com, type CNAME',
            actions: [
              KumoDialogClose(label: 'Cancel', disabled: _saving),
              KumoButton(
                label: 'Save record',
                variant: KumoButtonVariant.primary,
                loading: _saving,
                onPress: _save,
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KumoSpace.s2,
              children: [
                const KumoText('TTL', bold: true),
                _Buttons(children: [
                  for (final ttl in ['Auto', '5 min', '1 hr'])
                    KumoButton(
                      label: ttl,
                      size: KumoButtonSize.sm,
                      variant: ttl == _ttl ? KumoButtonVariant.primary : KumoButtonVariant.secondary,
                      onPress: () => setState(() => _ttl = ttl),
                    ),
                ]),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KumoButton(label: 'Edit record', icon: KumoIcons.pencilSimple, onPress: () => setState(() => _editOpen = true)),
              _ResultLine('TTL: $_ttl'),
            ],
          ),
        ),
      ),
    ]);
  }
}

// showKumoAlertDialog

class _AlertDialogDemo extends StatefulWidget {
  const _AlertDialogDemo();

  @override
  State<_AlertDialogDemo> createState() => _AlertDialogDemoState();
}

class _AlertDialogDemoState extends State<_AlertDialogDemo> {
  String _last = 'No choice yet';

  Future<void> _confirm({required bool destructive}) async {
    final Future<bool> request = destructive
        ? showKumoAlertDialog(
            context,
            title: 'Delete R2 bucket "assets"?',
            description: 'Every object in the bucket is removed. This cannot be undone.',
            confirmLabel: 'Delete bucket',
            destructive: true,
          )
        : showKumoAlertDialog(
            context,
            title: 'Purge everything for example.com?',
            description: 'Visitors get uncached responses until the cache warms up again.',
            confirmLabel: 'Purge cache',
          );
    final confirmed = await request;
    if (mounted) setState(() => _last = confirmed ? 'Confirmed' : 'Cancelled');
  }

  @override
  Widget build(BuildContext context) {
    return _DemoColumn(children: [
      DemoSection(
        title: 'Destructive and standard',
        caption: 'Destructive confirmations get a warning badge, a red button and focus on Cancel.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Buttons(children: [
              KumoButton(label: 'Delete bucket', variant: KumoButtonVariant.destructive, onPress: () => _confirm(destructive: true)),
              KumoButton(label: 'Purge cache', onPress: () => _confirm(destructive: false)),
            ]),
            _ResultLine(_last),
          ],
        ),
      ),
    ]);
  }
}

// KumoLayerDialog

class _LayerDialogDemo extends StatefulWidget {
  const _LayerDialogDemo();

  @override
  State<_LayerDialogDemo> createState() => _LayerDialogDemoState();
}

class _LayerDialogDemoState extends State<_LayerDialogDemo> {
  bool _pendingOpen = false;
  bool _deploying = false;
  String _status = 'Nothing deployed yet';

  static const _workers = ['production-api', 'staging-api', 'image-resizer', 'auth-gateway', 'email-router'];

  void _informational() {
    showKumoLayerDialog<void>(
      context,
      builder: (context) => KumoLayerDialog(
        title: 'Keyboard shortcuts',
        description: 'Browse the shortcuts available on the Workers page.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            for (final (keys, action) in const [
              ('/', 'Search Workers'),
              ('G then W', 'Go to Workers'),
              ('G then R', 'Go to R2'),
              ('N', 'Create a Worker'),
              ('Shift + D', 'Deploy the selected Worker'),
              ('?', 'Show this list'),
            ])
              Row(
                children: [
                  Expanded(child: KumoText(action)),
                  KumoText(keys, variant: KumoTextVariant.monoSecondary),
                ],
              ),
            const KumoLayerDialogSeparator(),
            const KumoText('Shortcuts are off while a text field has focus.', variant: KumoTextVariant.secondary),
          ],
        ),
      ),
    );
  }

  void _standard() {
    showKumoLayerDialog<void>(
      context,
      builder: (context) => KumoLayerDialog(
        title: 'Choose a Worker',
        description: 'Select the Worker that handles requests for api.example.com/*.',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in _workers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: KumoSpace.s2),
                child: KumoText(w, variant: KumoTextVariant.mono),
              ),
          ],
        ),
        action: KumoLayerDialogAction(
          label: 'Save route',
          onPress: () => KumoDialog.closeFrom(context),
        ),
      ),
    );
  }

  void _alert() {
    showKumoLayerDialog<void>(
      context,
      builder: (context) => KumoLayerDialog.alert(
        title: 'Delete production-api?',
        description: 'Requests to its routes fail until another Worker is deployed.',
        body: const KumoText('3 routes and 2 cron triggers point at this Worker.', variant: KumoTextVariant.secondary),
        action: KumoLayerDialogAction(
          label: 'Delete Worker',
          variant: KumoLayerDialogActionVariant.destructive,
          onPress: () => KumoDialog.closeFrom(context),
        ),
      ),
    );
  }

  void _split() {
    showKumoLayerDialog<void>(
      context,
      builder: (context) => KumoLayerDialog(
        title: 'Deploy changes',
        description: 'image-resizer, 2 changed files',
        size: KumoLayerDialogSize.sm,
        body: const KumoText('Deploying publishes the new version to every route.', variant: KumoTextVariant.secondary),
        action: KumoLayerDialogAction(
          label: 'Save and deploy',
          onPress: () => KumoDialog.closeFrom(context),
          menu: [
            KumoLayerDialogMenuItem(
              label: 'Save as draft',
              icon: KumoIcons.floppyDisk,
              onPress: () => KumoDialog.closeFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deploy() async {
    setState(() => _deploying = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _deploying = false;
      _pendingOpen = false;
      _status = 'Deployed staging-api';
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DemoColumn(children: [
      DemoSection(
        title: 'Informational',
        caption: 'No action: an X in the title frame. The description folds away once the list scrolls.',
        child: _Buttons(children: [KumoButton(label: 'Keyboard shortcuts', icon: KumoIcons.keyboard, onPress: _informational)]),
      ),
      DemoSection(
        title: 'Standard action',
        caption: 'One primary action plus an automatic Close button.',
        child: _Buttons(children: [KumoButton(label: 'Choose a Worker', onPress: _standard)]),
      ),
      DemoSection(
        title: 'Alert',
        caption: 'Cancel instead of Close, no X, and no backdrop or swipe dismissal.',
        child: _Buttons(children: [
          KumoButton(label: 'Delete Worker', variant: KumoButtonVariant.secondaryDestructive, onPress: _alert),
        ]),
      ),
      DemoSection(
        title: 'Split action',
        caption: 'Related actions live behind the caret next to the primary action.',
        child: _Buttons(children: [KumoButton(label: 'Deploy changes', onPress: _split)]),
      ),
      DemoSection(
        title: 'Pending work',
        caption: 'While deploying, every user dismissal is blocked; the dialog closes itself when done.',
        child: KumoDialogRoot(
          open: _pendingOpen,
          onOpenChange: (open) => setState(() => _pendingOpen = open),
          dialog: KumoLayerDialog(
            title: 'Deploy staging-api',
            description: 'Compatibility date 2026-10-26',
            dismissDisabled: _deploying,
            body: const KumoText('The deploy takes about two seconds in this sample.', variant: KumoTextVariant.secondary),
            action: KumoLayerDialogAction(label: 'Deploy Worker', loading: _deploying, onPress: _deploy),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KumoButton(label: 'Deploy staging-api', onPress: () => setState(() => _pendingOpen = true)),
              _ResultLine(_status),
            ],
          ),
        ),
      ),
    ]);
  }
}

// KumoDrawer

class _DrawerDemo extends StatefulWidget {
  const _DrawerDemo();

  @override
  State<_DrawerDemo> createState() => _DrawerDemoState();
}

class _DrawerDemoState extends State<_DrawerDemo> {
  String _filter = 'All zones';

  void _settings(KumoSheetEdge side) {
    showKumoDrawer<void>(
      context,
      builder: (context) => KumoDrawer(
        side: side,
        title: 'image-resizer',
        description: 'Worker settings',
        actions: [
          const KumoDialogClose(label: 'Cancel'),
          KumoButton(
            label: 'Save settings',
            variant: KumoButtonVariant.primary,
            onPress: () => KumoDialog.closeFrom(context),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s4,
          children: [
            for (final (label, value) in const [
              ('Compatibility date', '2026-10-26'),
              ('Usage model', 'Standard'),
              ('Placement', 'Smart'),
              ('Logpush', 'Off'),
              ('Routes', 'images.example.com/*'),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KumoSpace.s1,
                children: [
                  KumoText(label, variant: KumoTextVariant.secondary, size: KumoTextSize.sm),
                  KumoText(value, variant: KumoTextVariant.mono),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _filters() async {
    final picked = await showKumoDrawer<String>(
      context,
      builder: (context) => KumoDrawer(
        side: KumoSheetEdge.bottom,
        title: 'Filter zones',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s2,
          children: [
            for (final option in const ['All zones', 'Active zones', 'Pending nameservers', 'Paused zones'])
              KumoButton(label: option, block: true, onPress: () => KumoDialog.closeFrom(context, option)),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _filter = picked);
  }

  void _locked() {
    showKumoDrawer<void>(
      context,
      builder: (context) => KumoDrawer(
        dismissible: false,
        title: 'Rotating API token',
        description: 'Copy the new token before closing.',
        actions: [
          KumoButton(label: 'I copied it', variant: KumoButtonVariant.primary, onPress: () => KumoDialog.closeFrom(context)),
        ],
        child: const KumoText('cf_sample_8f3a91c2', variant: KumoTextVariant.mono),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DemoColumn(children: [
      DemoSection(
        title: 'Side panels',
        caption: 'Drag toward the edge or flick to dismiss; a short drag springs back.',
        child: _Buttons(children: [
          KumoButton(label: 'Open from end', onPress: () => _settings(KumoSheetEdge.end)),
          KumoButton(label: 'Open from start', onPress: () => _settings(KumoSheetEdge.start)),
        ]),
      ),
      DemoSection(
        title: 'Bottom drawer',
        caption: 'Returns the option picked.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KumoButton(label: 'Filter zones', icon: KumoIcons.funnel, onPress: _filters),
            _ResultLine('Showing: $_filter'),
          ],
        ),
      ),
      DemoSection(
        title: 'Not dismissible',
        caption: 'Backdrop taps and drags do nothing; the footer button closes it.',
        child: _Buttons(children: [KumoButton(label: 'Rotate token', onPress: _locked)]),
      ),
    ]);
  }
}

// KumoToast

class _ToastDemo extends StatelessWidget {
  const _ToastDemo();

  @override
  Widget build(BuildContext context) {
    // The gallery may already host a toaster at its root; otherwise this demo
    // brings its own.
    const content = _ToastDemoContent();
    return KumoToast.maybeOf(context) == null ? const KumoToaster(child: content) : content;
  }
}

class _ToastDemoContent extends StatelessWidget {
  const _ToastDemoContent();

  @override
  Widget build(BuildContext context) {
    Future<String> deploy() => Future<String>.delayed(const Duration(milliseconds: 1500), () => 'image-resizer');

    return _DemoColumn(children: [
      DemoSection(
        title: 'Variants',
        child: _Buttons(children: [
          KumoButton(
            label: 'Neutral',
            onPress: () => showKumoToast(context, title: 'Settings saved', description: 'Changes apply to new requests.'),
          ),
          KumoButton(
            label: 'Success',
            onPress: () => showKumoToast(
              context,
              title: 'Worker deployed',
              description: 'image-resizer is live on 3 routes.',
              variant: KumoToastVariant.success,
            ),
          ),
          KumoButton(
            label: 'Error',
            onPress: () => showKumoToast(
              context,
              title: 'Deployment failed',
              description: 'image-resizer exceeded its startup CPU limit.',
              variant: KumoToastVariant.error,
            ),
          ),
          KumoButton(
            label: 'Warning',
            onPress: () => showKumoToast(
              context,
              title: 'Certificate expires soon',
              description: 'example.com renews in 6 days.',
              variant: KumoToastVariant.warning,
            ),
          ),
          KumoButton(
            label: 'Info',
            onPress: () => showKumoToast(
              context,
              title: 'Maintenance window',
              description: 'Dashboard analytics may lag for 10 minutes.',
              variant: KumoToastVariant.info,
            ),
          ),
        ]),
      ),
      DemoSection(
        title: 'Title only and description only',
        child: _Buttons(children: [
          KumoButton(label: 'Title only', onPress: () => showKumoToast(context, title: 'Cache purged')),
          KumoButton(
            label: 'Description only',
            onPress: () => showKumoToast(context, description: 'example.com now serves fresh content from the origin.'),
          ),
        ]),
      ),
      DemoSection(
        title: 'Actions',
        child: _Buttons(children: [
          KumoButton(
            label: 'Delete DNS record',
            variant: KumoButtonVariant.secondaryDestructive,
            onPress: () => showKumoToast(
              context,
              title: 'DNS record deleted',
              description: 'api.example.com, type CNAME',
              actions: [
                KumoToastAction(
                  label: 'Undo',
                  variant: KumoButtonVariant.primary,
                  closesToast: true,
                  onPress: () => showKumoToast(context, title: 'DNS record restored', variant: KumoToastVariant.success),
                ),
              ],
            ),
          ),
        ]),
      ),
      DemoSection(
        title: 'Stacking and repeats',
        caption: 'Several toasts stack; hover or touch the stack to fan it out. A repeated id bumps the toast instead.',
        child: _Buttons(children: [
          KumoButton(
            label: 'Show three',
            onPress: () {
              final toasts = KumoToast.of(context);
              toasts.add(title: 'Zone example.com activated');
              toasts.add(title: 'R2 bucket "assets" created');
              toasts.add(title: 'API token "ci-deploy" created');
            },
          ),
          KumoButton(
            label: 'Copy account ID',
            icon: KumoIcons.copy,
            onPress: () => showKumoToast(context, id: 'copied', title: 'Account ID copied'),
          ),
        ]),
      ),
      DemoSection(
        title: 'Promise',
        caption: 'One toast follows the work from loading to its result.',
        child: _Buttons(children: [
          KumoButton(
            label: 'Deploy Worker',
            variant: KumoButtonVariant.primary,
            onPress: () => KumoToast.of(context).promise<String>(
              deploy(),
              loading: const KumoToastData(title: 'Deploying image-resizer', variant: KumoToastVariant.info),
              success: (name) => KumoToastData(title: '$name deployed', variant: KumoToastVariant.success),
              error: (e) => KumoToastData(title: 'Deployment failed', description: '$e', variant: KumoToastVariant.error),
            ),
          ),
        ]),
      ),
      const DemoSection(
        title: 'Surfaces',
        caption: 'The toast surface on its own, for previews.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoToast(title: 'Settings saved', description: 'Changes apply to new requests.'),
            KumoToast(title: 'Worker deployed', description: 'image-resizer is live.', variant: KumoToastVariant.success),
            KumoToast(title: 'Upload failed', description: 'The object is larger than 5 GB.', variant: KumoToastVariant.error),
          ],
        ),
      ),
    ]);
  }
}

// KumoBanner

class _BannerDemo extends StatefulWidget {
  const _BannerDemo();

  @override
  State<_BannerDemo> createState() => _BannerDemoState();
}

class _BannerDemoState extends State<_BannerDemo> {
  bool _showUpdate = true;
  int _retries = 0;

  @override
  Widget build(BuildContext context) {
    return _DemoColumn(children: [
      const DemoSection(
        title: 'Variants',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            KumoBanner(icon: KumoIcons.infoFill, title: 'Update available', description: 'Wrangler 4.2 is ready to install.'),
            KumoBanner(
              icon: KumoIcons.warningFill,
              variant: KumoBannerVariant.alert,
              title: 'Session expiring',
              description: 'You will be signed out in 5 minutes.',
            ),
            KumoBanner(
              icon: KumoIcons.warningCircleFill,
              variant: KumoBannerVariant.error,
              title: 'Save failed',
              description: 'The DNS record could not be saved. Check the record name and try again.',
            ),
            KumoBanner(
              icon: KumoIcons.infoFill,
              variant: KumoBannerVariant.secondary,
              title: 'Maintenance scheduled',
              description: 'Analytics will be unavailable for 10 minutes on Sunday.',
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Actions and dismiss',
        caption: 'Actions take the banner accent. The X collapses the banner until you restore it, and restoring '
            'expands it again.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KumoBanner(
                  open: _showUpdate,
                  icon: KumoIcons.infoFill,
                  title: 'Update available',
                  description: 'Wrangler 4.2 is ready to install.',
                  actions: [KumoBannerAction(label: 'Update', onPress: () => setState(() => _showUpdate = false))],
                  onDismiss: () => setState(() => _showUpdate = false),
                ),
                if (!_showUpdate)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: KumoButton(label: 'Restore banner', onPress: () => setState(() => _showUpdate = true)),
                  ),
              ],
            ),
            KumoBanner(
              icon: KumoIcons.warningCircleFill,
              variant: KumoBannerVariant.error,
              title: 'Payment failed',
              description: _retries == 0 ? 'Update your card to avoid interruption.' : 'Retried $_retries times in this sample.',
              actions: [
                KumoBannerAction(label: 'Retry', onPress: () => setState(() => _retries++)),
                KumoBannerAction(label: 'Go to billing', variant: KumoBannerActionVariant.secondary, onPress: () {}),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        title: 'Compact',
        caption: 'For dialogs and tight spaces: one line of text and extra-small actions.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KumoSpace.s3,
          children: [
            const KumoBanner(
              size: KumoBannerSize.sm,
              icon: KumoIcons.infoFill,
              title: 'Read only.',
              description: 'Ask an admin for edit access.',
            ),
            KumoBanner(
              size: KumoBannerSize.sm,
              variant: KumoBannerVariant.alert,
              icon: KumoIcons.warningFill,
              title: 'Unsaved changes.',
              actions: [KumoBannerAction(label: 'Save', onPress: () {})],
            ),
          ],
        ),
      ),
    ]);
  }
}
