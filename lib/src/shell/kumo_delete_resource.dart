import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../buttons/kumo_button.dart';
import '../dialogs/kumo_banner.dart';
import '../dialogs/kumo_dialog.dart';
import '../icons/kumo_icon.dart';
import '../icons/kumo_icons.g.dart';
import '../system/kumo_editable.dart';
import '../system/kumo_field_box.dart';
import '../system/kumo_pressable.dart';
import '../system/kumo_strings.dart';
import '../theme/generated/kumo_colors.g.dart';
import '../theme/kumo_motion.dart';
import '../theme/kumo_theme.dart';
import '../theme/kumo_tokens.dart';
import '../theme/kumo_typography.dart';

/// Dialog widths of [KumoDeleteResource], the same as [KumoDialogSize]'s.
/// Below 768px the dialog takes the full width minus 16px gutters.
enum KumoDeleteResourceSize {
  /// 288px (`sm:w-72`).
  sm(288, KumoDialogSize.sm),

  /// 384px (`sm:w-96`), the default.
  base(384, KumoDialogSize.base);

  const KumoDeleteResourceSize(this.width, this.dialogSize);
  final double width;

  /// The [KumoDialog] size the dialog is drawn with.
  final KumoDialogSize dialogSize;
}

/// Kumo's `DeleteResource` block: a confirmation dialog for deleting a
/// resource, where the destructive button stays disabled until the user
/// types the resource's name.
///
/// Keep it mounted and drive [open]; it pushes its dialog when [open]
/// turns true and animates it out when it turns false. Escape, the close
/// button, Cancel and a backdrop tap call [onOpenChange] with false, except
/// while [isDeleting]. The name chip copies the name to the clipboard.
///
/// ```dart
/// KumoDeleteResource(
///   open: open,
///   onOpenChange: (v) => setState(() => open = v),
///   resourceType: 'Zone',
///   resourceName: 'example.com',
///   isDeleting: deleting,
///   errorMessage: error,
///   onDelete: () async {
///     setState(() => deleting = true);
///     await deleteZone();
///     setState(() {
///       deleting = false;
///       open = false;
///     });
///   },
///   child: KumoButton(
///     label: 'Delete zone',
///     variant: KumoButtonVariant.destructive,
///     onPress: () => setState(() => open = true),
///   ),
/// )
/// ```
class KumoDeleteResource extends StatefulWidget {
  const KumoDeleteResource({
    super.key,
    required this.open,
    required this.onOpenChange,
    required this.resourceType,
    required this.resourceName,
    required this.onDelete,
    this.isDeleting = false,
    this.caseSensitive = true,
    this.deleteButtonText,
    this.errorMessage,
    this.size = KumoDeleteResourceSize.base,
    this.child,
  });

  final bool open;
  final ValueChanged<bool> onOpenChange;

  /// Kind of resource, such as "Zone", "Worker" or "KV namespace". Used in
  /// the copy and the default button text.
  final String resourceType;

  /// The exact name the user must type.
  final String resourceName;

  /// Called when the user confirms. Set [isDeleting] while it runs.
  final FutureOr<void> Function() onDelete;
  final bool isDeleting;

  /// Match the typed name exactly (default) or ignoring case.
  final bool caseSensitive;

  /// Defaults to "Delete {resourceType}".
  final String? deleteButtonText;

  /// Shown in an error banner above the copy when a delete fails.
  final String? errorMessage;
  final KumoDeleteResourceSize size;

  /// What renders in place, usually the button that opens the dialog.
  final Widget? child;

  @override
  State<KumoDeleteResource> createState() => _KumoDeleteResourceState();
}

class _KumoDeleteResourceState extends State<KumoDeleteResource> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode(debugLabel: 'KumoDeleteResource input');

  // Bumped by typing, focus and the copy check. The dialog lives in its own
  // route and listens to this directly, so a keystroke updates the delete
  // button in the same frame.
  final ValueNotifier<int> _revision = ValueNotifier(0);
  bool _copied = false;
  Timer? _copyTimer;

  @override
  void initState() {
    super.initState();
    _input.addListener(_bump);
    _inputFocus.addListener(_bump);
  }

  @override
  void didUpdateWidget(KumoDeleteResource oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cleared as the dialog opens rather than as it closes, so the field and
    // the delete button do not visibly reset while the dialog fades out.
    if (widget.open && !oldWidget.open) _reset();
    if (!widget.open && oldWidget.open) _copyTimer?.cancel();
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    final revision = _revision;
    final input = _input;
    final focus = _inputFocus;
    // The dialog route is removed after this frame; its field still holds
    // the controller and focus node until then.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        input.dispose();
        focus.dispose();
        revision.dispose();
      });
    });
    super.dispose();
  }

  void _bump() {
    if (mounted) _revision.value++;
  }

  bool get _confirmed {
    String norm(String s) => widget.caseSensitive ? s : s.toLowerCase();
    return norm(_input.text) == norm(widget.resourceName);
  }

  void _reset() {
    _copyTimer?.cancel();
    _copied = false;
    _input.clear();
  }

  Future<void> _delete() async {
    if (!_confirmed || widget.isDeleting) return;
    await widget.onDelete();
  }

  Future<void> _copy(BuildContext context) async {
    final copiedText = context.kumoStrings.copied;
    final view = View.of(context);
    final direction = Directionality.of(context);
    try {
      await Clipboard.setData(ClipboardData(text: widget.resourceName));
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _copyTimer?.cancel();
    _copied = true;
    _bump();
    unawaited(SemanticsService.sendAnnouncement(view, copiedText, direction));
    _copyTimer = Timer(const Duration(milliseconds: 1500), () {
      _copied = false;
      _bump();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KumoDialogRoot(
      open: widget.open,
      // Every dismissal (X, Cancel, Escape, backdrop, back gesture) arrives
      // here; while deleting, PopScope and the disabled buttons stop them.
      onOpenChange: widget.onOpenChange,
      semanticLabel: 'Delete ${widget.resourceName}',
      dialog: ValueListenableBuilder<int>(
        valueListenable: _revision,
        builder: (context, _, _) => _DeleteDialog(owner: this),
      ),
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}

/// Kumo's `DeleteResource` layout: a [KumoDialog] with no padding of its own,
/// holding a bordered header, the body and a bordered footer.
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.owner});

  final _KumoDeleteResourceState owner;

  @override
  Widget build(BuildContext context) {
    final widget = owner.widget;
    final kumo = context.kumo;
    final c = kumo.colors;
    final strings = context.kumoStrings;
    final deleting = widget.isDeleting;
    final name = widget.resourceName;
    final border = BorderSide(color: c.line);
    final error = widget.errorMessage;

    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s6, vertical: KumoSpace.s4),
      decoration: BoxDecoration(border: Border(bottom: border)),
      child: Row(
        spacing: KumoSpace.s3,
        children: [
          Expanded(
            child: Semantics(header: true, child: Text('Delete $name', style: kumo.heading())),
          ),
          KumoDialogClose(variant: KumoButtonVariant.ghost, size: KumoButtonSize.sm, disabled: deleting),
        ],
      ),
    );

    final subtle = kumo.text(color: KumoColor.textSubtle);
    final body = Padding(
      padding: const EdgeInsets.all(KumoSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KumoSpace.s4,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The banner grows in and out, so the copy below slides instead
              // of jumping when a delete fails or is retried.
              _GrowSize(
                child: AnimatedSwitcher(
                  duration: KumoMotion.duration(context, KumoDurations.quick),
                  switchInCurve: KumoCurves.enter,
                  switchOutCurve: KumoCurves.exit,
                  layoutBuilder: (current, previous) =>
                      Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
                  child: error == null || error.isEmpty
                      ? const SizedBox(key: ValueKey('no-error'), width: double.infinity)
                      : Padding(
                          key: ValueKey(error),
                          padding: const EdgeInsets.only(bottom: KumoSpace.s2),
                          child: KumoBanner(
                            variant: KumoBannerVariant.error,
                            icon: KumoIcons.warningCircle,
                            description: error,
                          ),
                        ),
                ),
              ),
              Text.rich(
                TextSpan(
                  style: subtle,
                  children: [
                    const TextSpan(text: 'This action cannot be undone. This will permanently delete the '),
                    TextSpan(
                      text: name,
                      style: kumo.text(weight: KumoTypography.medium),
                    ),
                    TextSpan(text: ' ${widget.resourceType.toLowerCase()}.'),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KumoSpace.s2,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: KumoSpace.s1_5,
                runSpacing: KumoSpace.s1,
                children: [
                  Text('Type', style: kumo.text()),
                  _CopyChip(name: name, copied: owner._copied, onPress: () => owner._copy(context)),
                  Text('to confirm:', style: kumo.text()),
                ],
              ),
              KumoFieldBox(
                focused: owner._inputFocus.hasFocus,
                disabled: deleting,
                child: KumoEditable(
                  controller: owner._input,
                  focusNode: owner._inputFocus,
                  placeholder: name,
                  enabled: !deleting,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  semanticLabel: 'Type $name to confirm deletion',
                  onSubmitted: (_) => owner._delete(),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final footer = Container(
      padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s6, vertical: KumoSpace.s4),
      decoration: BoxDecoration(border: Border(top: border)),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: KumoSpace.s3,
        runSpacing: KumoSpace.s2,
        children: [
          KumoDialogClose(label: strings.cancel, size: KumoButtonSize.base, disabled: deleting),
          // KumoButton eases between its disabled and enabled looks, so the
          // button lights up as the last letter of the name is typed.
          KumoButton(
            label: widget.deleteButtonText ?? 'Delete ${widget.resourceType}',
            variant: KumoButtonVariant.destructive,
            loading: deleting,
            disabled: !owner._confirmed,
            onPress: owner._delete,
          ),
        ],
      ),
    );

    return PopScope(
      canPop: !deleting,
      child: KumoDialog(
        size: widget.size.dialogSize,
        padding: EdgeInsets.zero,
        showCloseButton: false,
        semanticLabel: 'Delete $name',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, body, footer],
        ),
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.name, required this.copied, required this.onPress});

  final String name;
  final bool copied;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final kumo = context.kumo;
    final c = kumo.colors;
    return KumoPressable(
      onPress: onPress,
      semanticLabel: 'Copy $name to clipboard',
      excludeChildSemantics: true,
      borderRadius: BorderRadius.circular(KumoRadius.md),
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: KumoSpace.s2, vertical: KumoSpace.s1),
        decoration: BoxDecoration(
          color: state.active ? c.fill : c.tint,
          borderRadius: BorderRadius.circular(KumoRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: KumoSpace.s1_5,
          children: [
            Flexible(
              child: Text(name, style: kumo.code(weight: KumoTypography.medium)),
            ),
            KumoIcon(
              copied ? KumoIcons.check : KumoIcons.copy,
              size: 12,
              color: copied || state.active ? KumoColor.textDefault : KumoColor.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}

/// [AnimatedSize] with Kumo's expand timing, or a plain box under reduced
/// motion (a zero-duration AnimatedSize re-dirties itself during layout).
class _GrowSize extends StatelessWidget {
  const _GrowSize({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (KumoMotion.reduceMotion(context)) return child;
    return AnimatedSize(
      duration: KumoDurations.moderate,
      curve: KumoCurves.standard,
      alignment: AlignmentDirectional.topStart,
      child: child,
    );
  }
}
