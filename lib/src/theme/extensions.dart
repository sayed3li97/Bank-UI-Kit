import 'package:flutter/material.dart';

import 'presets/bloom.dart';
import 'presets/studio.dart';
import 'presets/voltage.dart';

/// The three first-party design presets shipped with Bank UI Kit.
///
/// Pass a value to [BankPresetApply.apply] to merge the preset into an
/// existing [ThemeData]:
///
/// ```dart
/// MaterialApp(
///   theme: BankPreset.studio.apply(ThemeData.light(useMaterial3: true)),
/// );
/// ```
enum BankPreset {
  /// Electric dark-native preset with violet/cyan gradient and glow effects.
  voltage,

  /// Restrained editorial preset with petrol-green primary and rectangular UI.
  studio,

  /// Warm consumer-friendly preset with coral primary and pill-shaped UI.
  bloom,
}

/// Convenience extension that applies a [BankPreset] to a [ThemeData].
extension BankPresetApply on BankPreset {
  /// Merges this preset's [BankThemeData] extension and [ColorScheme] into
  /// [base], returning the resulting [ThemeData].
  ThemeData apply(ThemeData base) => switch (this) {
        BankPreset.voltage => BankVoltageTheme.applyTo(base),
        BankPreset.studio => BankStudioTheme.applyTo(base),
        BankPreset.bloom => BankBloomTheme.applyTo(base),
      };
}
