import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Mboa Health — Editorial typography system.
///
/// Display / Headline: **Manrope** — geometric precision for high-impact text.
/// Body / Label: **Inter** — functional clarity for clinical data.
///
/// Per design system: "Always maintain at least a 2-step jump in scale
/// between headlines and body text to ensure a clear scan-path."
abstract final class AppTypography {
  // ─── Base font definitions ────────────────────────────────────────────────
  static TextStyle get _manrope => GoogleFonts.manrope();
  static TextStyle get _inter => GoogleFonts.inter();

  // ─── Display (Manrope) ────────────────────────────────────────────────────
  /// 3.5rem (56px) — used sparingly for health scores / bold welcomes.
  /// Per design: "Creates an immediate high-end editorial feel."
  static TextStyle get displayLg => _manrope.copyWith(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        letterSpacing: -1.5,
        height: 1.1,
      );

  /// 2.5rem (40px)
  static TextStyle get displayMd => _manrope.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurface,
        letterSpacing: -1.0,
        height: 1.15,
      );

  /// 2rem (32px)
  static TextStyle get displaySm => _manrope.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.8,
        height: 1.2,
      );

  // ─── Headline (Manrope) ───────────────────────────────────────────────────
  /// 1.75rem (28px)
  static TextStyle get headlineLg => _manrope.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.5,
        height: 1.25,
      );

  /// 1.5rem (24px) — section titles per design system mandate.
  static TextStyle get headlineMd => _manrope.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.3,
        height: 1.3,
      );

  /// 1.25rem (20px)
  static TextStyle get headlineSm => _manrope.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        letterSpacing: -0.2,
        height: 1.35,
      );

  // ─── Title (Manrope) ──────────────────────────────────────────────────────
  static TextStyle get titleLg => _manrope.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
        letterSpacing: -0.1,
      );

  static TextStyle get titleMd => _manrope.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  static TextStyle get titleSm => _manrope.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      );

  // ─── Body (Inter) ─────────────────────────────────────────────────────────
  /// 1rem (16px) — primary reading text.
  static TextStyle get bodyLg => _inter.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
        height: 1.6,
      );

  /// 0.875rem (14px) — workhorse body text.
  /// Per design: "Use on_surface_variant for secondary body to reduce visual noise."
  static TextStyle get bodyMd => _inter.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.6,
      );

  static TextStyle get bodyMdOnSurface => bodyMd.copyWith(
        color: AppColors.onSurface,
      );

  /// 0.75rem (12px) — captions and helper text.
  static TextStyle get bodySm => _inter.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
        height: 1.5,
      );

  // ─── Label (Inter) ────────────────────────────────────────────────────────
  static TextStyle get labelLg => _inter.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMd => _inter.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
        letterSpacing: 0.5,
      );

  /// Uppercase tracking label — used for section micro-labels.
  static TextStyle get labelSm => _inter.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.5,
      );

  // ─── Convenience builders ─────────────────────────────────────────────────
  /// Applies [AppColors.primary] color while preserving the style.
  static TextStyle primaryColor(TextStyle base) =>
      base.copyWith(color: AppColors.primary);

  /// Applies [AppColors.secondary] while preserving the style.
  static TextStyle secondaryColor(TextStyle base) =>
      base.copyWith(color: AppColors.secondary);

  // ─── Material TextTheme factory ───────────────────────────────────────────
  /// Returns a [TextTheme] for use inside [ThemeData].
  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLg,
        displayMedium: displayMd,
        displaySmall: displaySm,
        headlineLarge: headlineLg,
        headlineMedium: headlineMd,
        headlineSmall: headlineSm,
        titleLarge: titleLg,
        titleMedium: titleMd,
        titleSmall: titleSm,
        bodyLarge: bodyLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelLarge: labelLg,
        labelMedium: labelMd,
        labelSmall: labelSm,
      );
}
