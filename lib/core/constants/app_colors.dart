import 'package:flutter/material.dart';

/// Mboa Health — Complete color token system.
/// Based on the "Clinical Sanctuary" design system.
/// Sourced directly from the HTML design files / DESIGN.md.
///
/// RULE: Never use pure black (#000000). Always use [AppColors.onSurface].
/// RULE: Boundaries are defined by tonal shifts, NOT 1px borders.
abstract final class AppColors {
  // ─── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF00450D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B5E20);
  static const Color onPrimaryContainer = Color(0xFF90D689);
  static const Color primaryFixed = Color(0xFFACF4A4);
  static const Color primaryFixedDim = Color(0xFF91D78A);
  static const Color onPrimaryFixed = Color(0xFF002203);
  static const Color onPrimaryFixedVariant = Color(0xFF0C5216);
  static const Color inversePrimary = Color(0xFF91D78A);
  static const Color surfaceTint = Color(0xFF2A6B2C);

  // ─── Secondary ────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF006E1C);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF98F994);
  static const Color onSecondaryContainer = Color(0xFF0C7521);
  static const Color secondaryFixed = Color(0xFF98F994);
  static const Color secondaryFixedDim = Color(0xFF7DDC7A);
  static const Color onSecondaryFixed = Color(0xFF002204);
  static const Color onSecondaryFixedVariant = Color(0xFF005313);

  // ─── Tertiary (Urgency / Error-adjacent) ─────────────────────────────────
  static const Color tertiary = Color(0xFF7C000B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFA70515);
  static const Color onTertiaryContainer = Color(0xFFFFB2AA);
  static const Color tertiaryFixed = Color(0xFFFFDAD6);
  static const Color tertiaryFixedDim = Color(0xFFFFB3AC);
  static const Color onTertiaryFixed = Color(0xFF410003);
  static const Color onTertiaryFixedVariant = Color(0xFF930010);

  // ─── Surface Hierarchy ────────────────────────────────────────────────────
  // Treat as layers of "Fine Paper". Lowest = brightest (most elevated).
  static const Color surface = Color(0xFFF9F9F9);           // Base layer
  static const Color surfaceBright = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Elevated cards
  static const Color surfaceContainerLow = Color(0xFFF3F3F3);    // Grouping
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);  // Secondary interactive
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2); // Emphasis
  static const Color surfaceVariant = Color(0xFFE2E2E2);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF1F1F1);

  // ─── On-Surface ───────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1A1C1C);         // "Soft ink", not #000
  static const Color onSurfaceVariant = Color(0xFF41493E);  // Secondary text
  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);

  // ─── Outline ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF717A6D);
  static const Color outlineVariant = Color(0xFFC0C9BB);

  // ─── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Gradient Helpers ─────────────────────────────────────────────────────
  /// Primary CTA gradient: 135° from [primary] → [primaryContainer].
  /// Per design system: "Do not use a flat hex for primary CTAs."
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    transform: GradientRotation(135 * 3.14159 / 180),
    colors: [primary, primaryContainer],
  );

  /// Ambient blob gradient for decorative backgrounds.
  static const LinearGradient ambientGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1A91D78A), // secondaryContainer at ~10%
      Color(0x0D006E1C), // secondary at ~5%
    ],
  );
}
