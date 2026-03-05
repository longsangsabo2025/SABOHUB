import 'package:flutter/material.dart';

/// Extension on [ColorScheme] to provide convenience opacity variants.
///
/// These are commonly used throughout SABOHUB for text emphasis levels
/// and surface overlays, following Material Design opacity guidelines:
///
/// - `onSurface87`: High-emphasis text (87% opacity)
/// - `onSurface54`: Medium-emphasis text (54% opacity)
/// - `onSurface26`: Disabled text (26% opacity)
/// - `surface70`: Medium-emphasis secondary text (70% onSurface opacity)
/// - `surface60`: Lower emphasis text (60% onSurface opacity)
/// - `surface54`: Hint-level text (54% onSurface opacity)
/// - `surface38`: Very subtle text/icons (38% onSurface opacity)
/// - `surface24`: Barely visible / overlays (24% onSurface opacity)
extension SaboColorSchemeExtension on ColorScheme {
  // ─── onSurface variants (named with 'onSurface' prefix) ──────
  /// High-emphasis text — onSurface at 87% opacity
  Color get onSurface87 => onSurface.withValues(alpha: 0.87);

  /// Medium-emphasis text — onSurface at 54% opacity
  Color get onSurface54 => onSurface.withValues(alpha: 0.54);

  /// Disabled text — onSurface at 26% opacity
  Color get onSurface26 => onSurface.withValues(alpha: 0.26);

  // ─── surface* variants (actually onSurface at lower opacities) ─
  /// Secondary text — onSurface at 70% opacity
  Color get surface70 => onSurface.withValues(alpha: 0.70);

  /// Lower emphasis text — onSurface at 60% opacity
  Color get surface60 => onSurface.withValues(alpha: 0.60);

  /// Hint text — onSurface at 54% opacity
  Color get surface54 => onSurface.withValues(alpha: 0.54);

  /// Subtle icons/text — onSurface at 38% opacity
  Color get surface38 => onSurface.withValues(alpha: 0.38);

  /// Overlays — onSurface at 24% opacity
  Color get surface24 => onSurface.withValues(alpha: 0.24);
}
