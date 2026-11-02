import 'package:flutter/widgets.dart';
import 'package:kumo_flutter/kumo_flutter.dart';

import '../demo.dart';

/// Menus, popovers, hover cards, menu bars and toolbars. All names and
/// resources below are sample data.
final KumoDemoCategory menusCategory = KumoDemoCategory(
  title: 'Menus and popovers',
  description:
      'Anchored menus, popovers and toolbars that switch to bottom sheets on phones.',
  icon: KumoIcons.listBullets,
  demos: [
    KumoDemo(
      title: 'KumoDropdownMenu',
      description:
          'Actions, checkboxes, radio groups and submenus anchored to a trigger.',
      docPath: 'doc/components/KumoDropdownMenu.md',
      builder: (context) => const _DropdownDemo(),
    ),
    KumoDemo(
      title: 'KumoPopover',
      description:
          'Interactive content anchored to a trigger, with an arrow, title and close button.',
      docPath: 'doc/components/KumoPopover.md',
      builder: (context) => const _PopoverDemo(),
    ),
    KumoDemo(
      title: 'KumoContextMenu',
      description:
          'A menu at the pointer on right click, or on long press with touch.',
      docPath: 'doc/components/KumoContextMenu.md',
      builder: (context) => const _ContextMenuDemo(),
    ),
    KumoDemo(
      title: 'KumoHoverCard',
      description:
          'A preview card that opens while the pointer rests on a link.',
      docPath: 'doc/components/KumoHoverCard.md',
      builder: (context) => const _HoverCardDemo(),
    ),
    KumoDemo(
      title: 'KumoMenubar',
      description:
          'A bar of menus with arrow-key navigation and hover switching.',
      docPath: 'doc/components/KumoMenubar.md',
      builder: (context) => const _MenubarDemo(),
    ),
    KumoDemo(
      title: 'KumoToolbar',
      description:
          'Grouped controls with roving focus that overflow into a More menu.',
      docPath: 'doc/components/KumoToolbar.md',
      builder: (context) => const _ToolbarDemo(),
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
    children: children,
  );
}

class _LastAction extends StatelessWidget {
  const _LastAction(this.action);

  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: KumoSpace.s2),
    child: KumoText(
      action == null ? 'No action yet' : 'Last action: $action',
      variant: KumoTextVariant.secondary,
      size: KumoTextSize.sm,
    ),
  );
}

class _DropdownDemo extends StatefulWidget {
  const _DropdownDemo();

  @override
  State<_DropdownDemo> createState() => _DropdownDemoState();
}

class _DropdownDemoState extends State<_DropdownDemo> {
  String? _action;
  bool _sidebar = true;
  bool _lineNumbers = false;
  bool _wrap = true;
  String _region = 'wnam';
  KumoPresentation _presentation = KumoPresentation.auto;

  void _did(String action) => setState(() => _action = action);

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Actions',
          caption:
              'Items without an icon line up with the ones that have one. Delete uses danger text.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KumoDropdownMenu(
                semanticLabel: 'Worker actions',
                triggerBuilder: (context, menu) => KumoButton(
                  onPress: menu.toggle,
                  expanded: menu.isOpen,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: KumoSpace.s1_5,
                    children: [
                      const Text('image-resizer'),
                      KumoDropdownCaret(open: menu.isOpen),
                    ],
                  ),
                ),
                items: [
                  KumoDropdownItem(
                    label: 'Rename',
                    icon: KumoIcons.pencilSimple,
                    onPress: () => _did('Renamed'),
                  ),
                  KumoDropdownItem(
                    label: 'Duplicate',
                    icon: KumoIcons.copy,
                    shortcut: '⌘D',
                    onPress: () => _did('Duplicated'),
                  ),
                  const KumoDropdownSeparator(),
                  KumoDropdownItem(
                    label: 'Move to account',
                    onPress: () => _did('Moved'),
                  ),
                  const KumoDropdownItem(
                    label: 'Transfer ownership',
                    disabled: true,
                  ),
                  const KumoDropdownSeparator(),
                  KumoDropdownItem(
                    label: 'Delete Worker',
                    icon: KumoIcons.trash,
                    destructive: true,
                    onPress: () => _did('Deleted'),
                  ),
                ],
              ),
              _LastAction(_action),
            ],
          ),
        ),
        DemoSection(
          title: 'Checkbox items',
          caption: 'The menu stays open while you toggle settings.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoDropdownMenu(
              triggerBuilder: (context, menu) =>
                  KumoButton(label: 'View options', onPress: menu.toggle),
              items: [
                KumoDropdownGroup(
                  label: 'Display',
                  children: [
                    KumoDropdownCheckboxItem(
                      label: 'Show sidebar',
                      checked: _sidebar,
                      onCheckedChange: (v) => setState(() => _sidebar = v),
                    ),
                    KumoDropdownCheckboxItem(
                      label: 'Show line numbers',
                      checked: _lineNumbers,
                      onCheckedChange: (v) => setState(() => _lineNumbers = v),
                    ),
                    KumoDropdownCheckboxItem(
                      label: 'Word wrap',
                      checked: _wrap,
                      onCheckedChange: (v) => setState(() => _wrap = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Submenus and radio groups',
          caption:
              'Hover, tap or press ArrowRight on Region. In the sheet it pushes in place with a back row.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoDropdownMenu(
              sheetTitle: 'Account',
              triggerBuilder: (context, menu) => KumoButton(
                label: 'Account',
                icon: KumoIcons.user,
                onPress: menu.toggle,
              ),
              items: [
                KumoDropdownItem(
                  label: 'Profile',
                  icon: KumoIcons.user,
                  onPress: () => _did('Opened profile'),
                ),
                KumoDropdownItem(
                  label: 'Billing',
                  icon: KumoIcons.creditCard,
                  onPress: () => _did('Opened billing'),
                ),
                KumoDropdownSubmenu(
                  label: 'Region',
                  icon: KumoIcons.globe,
                  children: [
                    KumoDropdownRadioGroup<String>(
                      value: _region,
                      label: 'Region',
                      onValueChange: (v) => setState(() => _region = v),
                      children: const [
                        KumoDropdownRadioItem(
                          value: 'wnam',
                          label: 'Western North America',
                        ),
                        KumoDropdownRadioItem(
                          value: 'enam',
                          label: 'Eastern North America',
                        ),
                        KumoDropdownRadioItem(
                          value: 'weur',
                          label: 'Western Europe',
                        ),
                        KumoDropdownRadioItem(
                          value: 'apac',
                          label: 'Asia Pacific',
                        ),
                      ],
                    ),
                  ],
                ),
                KumoDropdownLinkItem(
                  label: 'Developer docs',
                  icon: KumoIcons.arrowSquareOut,
                  onPress: () => _did('Opened docs'),
                ),
                const KumoDropdownSeparator(),
                KumoDropdownItem(
                  label: 'Log out',
                  icon: KumoIcons.signOut,
                  destructive: true,
                  onPress: () => _did('Logged out'),
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Presentation',
          caption:
              'Auto uses a bottom sheet below 768px. Force either one here.',
          child: Wrap(
            spacing: KumoSpace.s2,
            runSpacing: KumoSpace.s2,
            children: [
              for (final p in KumoPresentation.values)
                KumoButton(
                  label: p.name,
                  size: KumoButtonSize.sm,
                  variant: p == _presentation
                      ? KumoButtonVariant.primary
                      : KumoButtonVariant.secondary,
                  onPress: () => setState(() => _presentation = p),
                ),
              KumoDropdownMenu(
                presentation: _presentation,
                triggerBuilder: (context, menu) => KumoButton(
                  label: 'Add',
                  icon: KumoIcons.plus,
                  onPress: menu.toggle,
                ),
                items: [
                  KumoDropdownItem(
                    label: 'Worker',
                    onPress: () => _did('Added Worker'),
                  ),
                  KumoDropdownItem(
                    label: 'Pages project',
                    onPress: () => _did('Added Pages project'),
                  ),
                  KumoDropdownItem(
                    label: 'KV namespace',
                    onPress: () => _did('Added KV namespace'),
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          title: 'Custom trigger and long list',
          caption:
              'Any widget can be the trigger. Long menus scroll inside the room they have.',
          child: Row(
            spacing: KumoSpace.s3,
            children: [
              KumoDropdownMenu(
                semanticLabel: 'Signed in as MR',
                trigger: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.kumo.colors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const KumoText(
                    'MR',
                    dangerouslySetColor: Color(0xFFFFFFFF),
                    size: KumoTextSize.sm,
                  ),
                ),
                items: [
                  KumoDropdownItem(
                    label: 'Profile',
                    icon: KumoIcons.user,
                    onPress: () => _did('Opened profile'),
                  ),
                  KumoDropdownItem(
                    label: 'Settings',
                    icon: KumoIcons.gear,
                    onPress: () => _did('Opened settings'),
                  ),
                ],
              ),
              KumoDropdownMenu(
                triggerBuilder: (context, menu) =>
                    KumoButton(label: 'Pick a zone', onPress: menu.toggle),
                items: [
                  for (var i = 1; i <= 30; i++)
                    KumoDropdownItem(
                      label: 'zone-$i.example.com',
                      onPress: () => _did('Picked zone-$i.example.com'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
  bool _open = false;
  int _unread = 3;

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Basic',
          caption:
              'Focus moves into the popover; Escape or a tap outside closes it.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoPopover(
              triggerBuilder: (context, popover) => KumoButton(
                icon: KumoIcons.bell,
                shape: KumoButtonShape.square,
                semanticLabel: 'Notifications',
                onPress: popover.toggle,
              ),
              children: [
                const KumoPopoverTitle('Notifications'),
                KumoPopoverDescription(
                  _unread == 0
                      ? 'No new alerts for example.com.'
                      : '$_unread new alerts for example.com.',
                ),
                const SizedBox(height: KumoSpace.s3),
                KumoPopoverClose(
                  label: 'Mark all read',
                  onPress: () => setState(() => _unread = 0),
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Sides',
          caption: 'Each side flips when there is no room.',
          child: Wrap(
            spacing: KumoSpace.s2,
            runSpacing: KumoSpace.s2,
            children: [
              for (final side in KumoSide.values)
                KumoPopover(
                  side: side,
                  triggerBuilder: (context, popover) =>
                      KumoButton(label: side.name, onPress: popover.toggle),
                  children: [
                    KumoPopoverTitle('Opens ${side.name}'),
                    const KumoPopoverDescription('Popover placement.'),
                  ],
                ),
            ],
          ),
        ),
        DemoSection(
          title: 'Controlled with a form',
          caption: 'The parent owns open; Save closes it from inside.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoPopover(
              open: _open,
              onOpenChange: (v) => setState(() => _open = v),
              width: 288,
              triggerBuilder: (context, popover) => KumoButton(
                label: 'Cache settings',
                icon: KumoIcons.gearSix,
                onPress: popover.toggle,
              ),
              children: [
                const KumoPopoverTitle('Browser cache TTL'),
                const KumoPopoverDescription(
                  'How long browsers keep cached files from example.com.',
                ),
                const SizedBox(height: KumoSpace.s3),
                Row(
                  spacing: KumoSpace.s2,
                  children: [
                    KumoButton(
                      label: 'Save',
                      size: KumoButtonSize.sm,
                      variant: KumoButtonVariant.primary,
                      onPress: () => setState(() => _open = false),
                    ),
                    const KumoPopoverClose(label: 'Cancel'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuDemo extends StatefulWidget {
  const _ContextMenuDemo();

  @override
  State<_ContextMenuDemo> createState() => _ContextMenuDemoState();
}

class _ContextMenuDemoState extends State<_ContextMenuDemo> {
  String? _action;

  @override
  Widget build(BuildContext context) {
    final c = context.kumo.colors;
    return _Demo(
      children: [
        DemoSection(
          title: 'DNS record',
          caption:
              'Right-click the record, long-press it on touch, or focus it and press Shift+F10.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KumoContextMenu(
                semanticLabel: 'Record actions',
                items: [
                  KumoDropdownItem(
                    label: 'Copy record ID',
                    icon: KumoIcons.copy,
                    onPress: () => setState(() => _action = 'Copied ID'),
                  ),
                  KumoDropdownItem(
                    label: 'Edit record',
                    icon: KumoIcons.pencilSimple,
                    onPress: () => setState(() => _action = 'Editing'),
                  ),
                  KumoDropdownSubmenu(
                    label: 'Change TTL',
                    icon: KumoIcons.clock,
                    children: [
                      for (final ttl in [
                        'Auto',
                        '5 minutes',
                        '1 hour',
                        '1 day',
                      ])
                        KumoDropdownItem(
                          label: ttl,
                          onPress: () =>
                              setState(() => _action = 'TTL set to $ttl'),
                        ),
                    ],
                  ),
                  const KumoDropdownSeparator(),
                  KumoDropdownItem(
                    label: 'Delete record',
                    icon: KumoIcons.trash,
                    destructive: true,
                    onPress: () => setState(() => _action = 'Deleted'),
                  ),
                ],
                child: KumoPressable(
                  onPress: () => setState(() => _action = 'Opened record'),
                  semanticLabel: 'A record, example.com, 192.0.2.1',
                  borderRadius: BorderRadius.circular(KumoRadius.lg),
                  builder: (context, state) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KumoSpace.s4,
                      vertical: KumoSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: state.active ? c.tint : c.base,
                      borderRadius: BorderRadius.circular(KumoRadius.lg),
                      border: KumoRing.border(c.line),
                    ),
                    child: const Row(
                      spacing: KumoSpace.s3,
                      children: [
                        KumoText('A', bold: true),
                        Expanded(
                          child: KumoText('example.com', truncate: true),
                        ),
                        KumoText(
                          '192.0.2.1',
                          variant: KumoTextVariant.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _LastAction(_action),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoverCardDemo extends StatelessWidget {
  const _HoverCardDemo();

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Worker preview',
          caption:
              'Hover the name, focus it with Tab, or long-press it on touch. The link still opens the Worker.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoHoverCard(
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: KumoSpace.s1,
                children: [
                  KumoText('image-resizer', bold: true),
                  KumoText(
                    'Last deployed 2 hours ago from main. Sample data.',
                    variant: KumoTextVariant.secondary,
                  ),
                  SizedBox(height: KumoSpace.s1),
                  Row(
                    spacing: KumoSpace.s1_5,
                    children: [
                      KumoIcon(
                        KumoIcons.checkCircle,
                        color: KumoColor.textSuccess,
                      ),
                      KumoText('Healthy', size: KumoTextSize.sm),
                    ],
                  ),
                ],
              ),
              child: KumoButton(
                label: 'image-resizer',
                variant: KumoButtonVariant.ghost,
                isLink: true,
                onPress: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenubarDemo extends StatefulWidget {
  const _MenubarDemo();

  @override
  State<_MenubarDemo> createState() => _MenubarDemoState();
}

class _MenubarDemoState extends State<_MenubarDemo> {
  String? _action;
  bool _logs = true;
  bool _minimap = false;
  String _env = 'production';

  void _did(String a) => setState(() => _action = a);

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Worker editor',
          caption:
              'Open a menu, then hover or use Left and Right to move between menus.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KumoMenubar(
                semanticLabel: 'Worker editor',
                menus: [
                  KumoMenubarMenu(
                    label: 'File',
                    items: [
                      KumoDropdownItem(
                        label: 'New Worker',
                        icon: KumoIcons.plus,
                        shortcut: '⌘N',
                        onPress: () => _did('New Worker'),
                      ),
                      KumoDropdownItem(
                        label: 'Save',
                        shortcut: '⌘S',
                        onPress: () => _did('Saved'),
                      ),
                      KumoDropdownSubmenu(
                        label: 'Export',
                        children: [
                          KumoDropdownItem(
                            label: 'wrangler.toml',
                            onPress: () => _did('Exported wrangler.toml'),
                          ),
                          KumoDropdownItem(
                            label: 'Bundle',
                            onPress: () => _did('Exported bundle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  KumoMenubarMenu(
                    label: 'View',
                    items: [
                      KumoDropdownCheckboxItem(
                        label: 'Live logs',
                        checked: _logs,
                        onCheckedChange: (v) => setState(() => _logs = v),
                      ),
                      KumoDropdownCheckboxItem(
                        label: 'Minimap',
                        checked: _minimap,
                        onCheckedChange: (v) => setState(() => _minimap = v),
                      ),
                    ],
                  ),
                  KumoMenubarMenu(
                    label: 'Deploy',
                    items: [
                      KumoDropdownRadioGroup<String>(
                        value: _env,
                        label: 'Environment',
                        onValueChange: (v) => setState(() => _env = v),
                        children: const [
                          KumoDropdownRadioItem(
                            value: 'production',
                            label: 'Production',
                          ),
                          KumoDropdownRadioItem(
                            value: 'staging',
                            label: 'Staging',
                          ),
                        ],
                      ),
                      const KumoDropdownSeparator(),
                      KumoDropdownItem(
                        label: 'Deploy to $_env',
                        icon: KumoIcons.rocketLaunch,
                        onPress: () => _did('Deployed to $_env'),
                      ),
                    ],
                  ),
                  KumoMenubarMenu(
                    label: 'Settings',
                    icon: KumoIcons.gearSix,
                    items: [
                      KumoDropdownItem(
                        label: 'Variables',
                        onPress: () => _did('Opened variables'),
                      ),
                      KumoDropdownItem(
                        label: 'Triggers',
                        onPress: () => _did('Opened triggers'),
                      ),
                    ],
                  ),
                ],
              ),
              _LastAction(_action),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarDemo extends StatefulWidget {
  const _ToolbarDemo();

  @override
  State<_ToolbarDemo> createState() => _ToolbarDemoState();
}

class _ToolbarDemoState extends State<_ToolbarDemo> {
  String? _action;
  bool _bold = false;
  bool _italic = false;
  bool _exporting = false;
  double _width = 1;

  void _did(String a) => setState(() => _action = a);

  @override
  Widget build(BuildContext context) {
    return _Demo(
      children: [
        DemoSection(
          title: 'Actions',
          caption: 'One Tab stop; Left and Right move between buttons.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KumoToolbar(
                semanticLabel: 'DNS records',
                children: [
                  KumoToolbarButton(
                    icon: KumoIcons.uploadSimple,
                    label: 'Import',
                    onPress: () => _did('Import started'),
                  ),
                  KumoToolbarButton(
                    icon: KumoIcons.downloadSimple,
                    label: 'Export',
                    loading: _exporting,
                    onPress: () {
                      setState(() => _exporting = true);
                      Future<void>.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _exporting = false);
                      });
                    },
                  ),
                  KumoToolbarButton(
                    icon: KumoIcons.gearSix,
                    semanticLabel: 'Settings',
                    tooltip: 'Settings',
                    onPress: () => _did('Opened settings'),
                  ),
                ],
              ),
              _LastAction(_action),
            ],
          ),
        ),
        DemoSection(
          title: 'Groups and toggles',
          caption:
              'Bold and italic are toggles; they sit in one group with no divider between them.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: KumoToolbar(
              semanticLabel: 'Editor',
              children: [
                KumoToolbarGroup(
                  semanticLabel: 'Text formatting',
                  children: [
                    KumoToolbarButton(
                      icon: KumoIcons.textB,
                      semanticLabel: 'Bold',
                      toggled: _bold,
                      onPress: () => setState(() => _bold = !_bold),
                    ),
                    KumoToolbarButton(
                      icon: KumoIcons.textItalic,
                      semanticLabel: 'Italic',
                      toggled: _italic,
                      onPress: () => setState(() => _italic = !_italic),
                    ),
                  ],
                ),
                KumoToolbarGroup(
                  semanticLabel: 'Alignment',
                  children: [
                    KumoToolbarButton(
                      icon: KumoIcons.textAlignLeft,
                      semanticLabel: 'Align left',
                      onPress: () => _did('Aligned left'),
                    ),
                    KumoToolbarButton(
                      icon: KumoIcons.textAlignCenter,
                      semanticLabel: 'Center',
                      onPress: () => _did('Centered'),
                    ),
                  ],
                ),
                KumoToolbarButton(
                  icon: KumoIcons.linkSimple,
                  semanticLabel: 'Insert link',
                  onPress: () => _did('Link inserted'),
                ),
              ],
            ),
          ),
        ),
        DemoSection(
          title: 'Overflow',
          caption:
              'Narrow the toolbar: items at the end move into More instead of overflowing.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KumoSpace.s3,
            children: [
              Wrap(
                spacing: KumoSpace.s2,
                children: [
                  for (final w in const [1.0, 0.7, 0.45])
                    KumoButton(
                      label: '${(w * 100).round()}%',
                      size: KumoButtonSize.sm,
                      variant: w == _width
                          ? KumoButtonVariant.primary
                          : KumoButtonVariant.secondary,
                      onPress: () => setState(() => _width = w),
                    ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth * _width,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: KumoToolbar(
                      semanticLabel: 'R2 bucket assets',
                      children: [
                        KumoToolbarButton(
                          icon: KumoIcons.uploadSimple,
                          label: 'Upload',
                          onPress: () => _did('Upload started'),
                        ),
                        KumoToolbarButton(
                          icon: KumoIcons.folder,
                          label: 'New folder',
                          onPress: () => _did('Folder created'),
                        ),
                        KumoToolbarButton(
                          icon: KumoIcons.shareNetwork,
                          label: 'Share',
                          onPress: () => _did('Share link copied'),
                        ),
                        KumoToolbarButton(
                          icon: KumoIcons.trash,
                          label: 'Delete',
                          onPress: () => _did('Deleted'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
