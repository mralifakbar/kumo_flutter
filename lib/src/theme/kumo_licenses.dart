import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

/// Adds the licenses of the bundled fonts (Inter and JetBrains Mono, SIL OFL)
/// and Phosphor Icons (MIT) to Flutter's license registry, so they appear on
/// `showLicensePage`. Both licenses require their text to travel with the
/// assets.
///
/// [KumoThemeProvider] calls this once; call it yourself only when you use
/// the fonts without the provider.
void registerKumoLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final (package, file) in const [
      ('Inter', 'Inter-OFL.txt'),
      ('JetBrains Mono', 'JetBrainsMono-OFL.txt'),
      ('Phosphor Icons', 'Phosphor-MIT.txt'),
    ]) {
      final text = await rootBundle.loadString('packages/kumo_flutter/assets/licenses/$file');
      yield LicenseEntryWithLineBreaks([package], text);
    }
  });
}
