/// Mboa Health — 8pt spacing grid.
///
/// All spacing values are multiples of 8 (or 4 for tight sub-values).
/// Per design system: "Use extreme whitespace (8pt grid) to create a
/// sense of calm and room to breathe."
abstract final class AppSpacing {
  // ─── Base unit ────────────────────────────────────────────────────────────
  static const double unit = 8.0;

  // ─── Spacing scale ────────────────────────────────────────────────────────
  static const double xs2 = 2.0;   // 0.25 × unit  — hairline
  static const double xs = 4.0;    // 0.5 × unit   — tight
  static const double sm = 8.0;    // 1 × unit     — compact
  static const double md = 12.0;   // 1.5 × unit   — base
  static const double base = 16.0; // 2 × unit     — standard gap
  static const double lg = 20.0;   // 2.5 × unit
  static const double xl = 24.0;   // 3 × unit     — section padding
  static const double xl2 = 32.0;  // 4 × unit     — large sections
  static const double xl3 = 40.0;  // 5 × unit
  static const double xl4 = 48.0;  // 6 × unit
  static const double xl5 = 56.0;  // 7 × unit
  static const double xl6 = 64.0;  // 8 × unit     — hero spacing
  static const double xl8 = 80.0;  // 10 × unit
  static const double xl12 = 96.0; // 12 × unit

  // ─── Screen edge padding ─────────────────────────────────────────────────
  static const double screenHorizontal = 24.0; // 3 × unit — standard side padding
  static const double screenVertical = 32.0;   // 4 × unit

  // ─── Border radius ────────────────────────────────────────────────────────
  // Per design system border-radius tokens:
  static const double radiusSm = 4.0;   // DEFAULT (0.25rem)
  static const double radiusMd = 12.0;  // Input fields (0.75rem)
  static const double radiusLg = 16.0;  // Standard cards (1rem)
  static const double radiusXl = 24.0;  // Hero modules / buttons (1.5rem)
  static const double radiusXxl = 32.0; // Bottom sheets / large panels (2rem)
  static const double radiusXxxl = 40.0;// Illustration containers (2.5rem)
  static const double radiusFull = 9999.0; // Pills / circular

  // ─── Icon sizes ───────────────────────────────────────────────────────────
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ─── Component sizes ─────────────────────────────────────────────────────
  static const double buttonHeight = 56.0;    // Primary full-width button
  static const double inputHeight = 56.0;     // Input field height
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 80.0;
  static const double cardMinHeight = 80.0;
  static const double avatarSm = 40.0;
  static const double avatarMd = 64.0;
  static const double avatarLg = 96.0;
  static const double avatarXl = 128.0;
}
