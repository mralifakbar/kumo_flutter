import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../theme/kumo_motion.dart';

/// Result of the most recent copy attempt.
enum DataCopyStatus { idle, copied, failed }

/// Shared copy behavior for the data components: writes to the clipboard,
/// shows "Copied" (or the failure copy) for [copyFeedbackDuration], announces
/// it, and bumps a spring on every repeat so a second press still visibly
/// lands. Not exported.
mixin DataCopyFeedback<T extends StatefulWidget> on State<T>, TickerProvider {
  DataCopyStatus copyStatus = DataCopyStatus.idle;
  Timer? _reset;
  int _attempt = 0;

  /// Scale of the feedback element. Rests at 1; each copy kicks it with
  /// velocity so it swells about 4% and settles, from wherever it is.
  late final AnimationController copyBump;

  Duration get copyFeedbackDuration;

  @override
  void initState() {
    super.initState();
    copyBump = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _reset?.cancel();
    copyBump.dispose();
    super.dispose();
  }

  /// Copies [text]; returns true on success. [copied] and [failed] are
  /// announced to screen readers.
  Future<bool> copyText(String text, {required String copied, required String failed}) async {
    final attempt = ++_attempt;
    _reset?.cancel();
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (_) {
      ok = false;
    }
    // A newer attempt started while this one awaited the platform.
    if (!mounted || attempt != _attempt) return ok;
    setState(() => copyStatus = ok ? DataCopyStatus.copied : DataCopyStatus.failed);
    didChangeCopyStatus();
    _bump();
    _announce(ok ? copied : failed);
    _reset = Timer(copyFeedbackDuration, () {
      if (!mounted || attempt != _attempt) return;
      setState(() => copyStatus = DataCopyStatus.idle);
      didChangeCopyStatus();
    });
    return ok;
  }

  /// Called after [copyStatus] changes, outside build.
  void didChangeCopyStatus() {}

  void _bump() {
    if (KumoMotion.reduceMotion(context)) return;
    // Kumo's clipboard-toast-bump peaks at 1.04. An underdamped spring kicked
    // with velocity reaches about that and settles back to 1.
    KumoMotion.springTo(
      copyBump,
      1,
      spring: KumoSprings.of(dampingRatio: 0.5, response: 0.3),
      velocity: copyBump.velocity + 1.5,
    );
  }

  void _announce(String message) {
    final view = View.maybeOf(context);
    if (view == null) return;
    unawaited(SemanticsService.sendAnnouncement(view, message, Directionality.maybeOf(context) ?? TextDirection.ltr));
  }
}
