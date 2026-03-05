import 'package:flutter/widgets.dart';

/// Design tokens for consistent spacing throughout the app.
///
/// Usage:
/// ```dart
/// Padding(padding: AppSpacing.paddingM)
/// SizedBox(height: AppSpacing.md)
/// EdgeInsets.symmetric(horizontal: AppSpacing.lg)
/// ```
///
/// Scale follows 4pt grid system:
/// xxxs=2, xxs=4, xs=6, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32, huge=40, massive=48
class AppSpacing {
  AppSpacing._();

  // ─── Raw values (4pt grid) ───
  static const double xxxs = 2;
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  // ─── Common SizedBox gaps ───
  static const SizedBox gapXXXS = SizedBox(height: xxxs);
  static const SizedBox gapXXS = SizedBox(height: xxs);
  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapSM = SizedBox(height: sm);
  static const SizedBox gapMD = SizedBox(height: md);
  static const SizedBox gapLG = SizedBox(height: lg);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);
  static const SizedBox gapXXXL = SizedBox(height: xxxl);

  // Horizontal gaps
  static const SizedBox hGapXXS = SizedBox(width: xxs);
  static const SizedBox hGapXS = SizedBox(width: xs);
  static const SizedBox hGapSM = SizedBox(width: sm);
  static const SizedBox hGapMD = SizedBox(width: md);
  static const SizedBox hGapLG = SizedBox(width: lg);
  static const SizedBox hGapXL = SizedBox(width: xl);
  static const SizedBox hGapXXL = SizedBox(width: xxl);

  // ─── Common EdgeInsets ───
  /// All sides equal
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXXL = EdgeInsets.all(xxl);

  /// Horizontal only
  static const EdgeInsets paddingHSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets paddingHMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHXL = EdgeInsets.symmetric(horizontal: xl);

  /// Vertical only
  static const EdgeInsets paddingVSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVLG = EdgeInsets.symmetric(vertical: lg);

  /// Page-level padding (horizontal: 16, vertical: 24)
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: xxl);

  /// Card content padding
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// List item padding
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);

  // ─── Border radius ───
  static const double radiusXS = 4;
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;
  static const double radiusFull = 999;

  static final BorderRadius borderRadiusXS = BorderRadius.circular(radiusXS);
  static final BorderRadius borderRadiusSM = BorderRadius.circular(radiusSM);
  static final BorderRadius borderRadiusMD = BorderRadius.circular(radiusMD);
  static final BorderRadius borderRadiusLG = BorderRadius.circular(radiusLG);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusFull =
      BorderRadius.circular(radiusFull);
}
