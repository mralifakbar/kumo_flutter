import 'package:flutter/services.dart';

/// Haptic feedback a control fires on its causal event (commit, snap,
/// selection change). Kumo is a pointer-first system, so controls default
/// to [none]; touch-first components opt in.
enum KumoHaptic { none, light, medium, heavy, selection }

/// Fires [haptic] through the platform haptics engine.
void kumoHaptic(KumoHaptic haptic) {
  switch (haptic) {
    case KumoHaptic.none:
      return;
    case KumoHaptic.light:
      HapticFeedback.lightImpact();
    case KumoHaptic.medium:
      HapticFeedback.mediumImpact();
    case KumoHaptic.heavy:
      HapticFeedback.heavyImpact();
    case KumoHaptic.selection:
      HapticFeedback.selectionClick();
  }
}
