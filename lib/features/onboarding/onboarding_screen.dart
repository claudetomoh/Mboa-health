import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/ambient_blob.dart';
import '../../shared/widgets/gradient_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding data model
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  const _OnboardingPage({
    required this.headlineBuilder,
    required this.body,
    required this.illustrationBuilder,
  });

  final WidgetBuilder headlineBuilder;
  final String body;
  final WidgetBuilder illustrationBuilder;
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Three-page onboarding flow implementing the Mboa Health Clinical Sanctuary
/// design. Each page shows a bento-style illustration panel on top and a white
/// bottom sheet with headline, body copy, pagination dots, and navigation CTAs.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;
  static const int _total = 3;

  // ── Navigation helpers ───────────────────────────────────────────────────

  void _next() {
    if (_current < _total - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 370),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
    }
  }

  void _back() {
    if (_current > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 370),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() =>
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);

  void _toLogin() =>
      Navigator.pushReplacementNamed(context, AppRoutes.login);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Page definitions ─────────────────────────────────────────────────────

  List<_OnboardingPage> get _pages => [
        _OnboardingPage(
          headlineBuilder: (_) => RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.8,
                height: 1.2,
              ),
              children: const [
                TextSpan(text: 'Find the Right '),
                TextSpan(
                  text: 'Care',
                  style: TextStyle(color: AppColors.secondary),
                ),
                TextSpan(text: ' Faster'),
              ],
            ),
          ),
          body:
              'Connect with top-rated specialists and manage your medical records in one secure, clinical sanctuary.',
          illustrationBuilder: (_) => const _Illustration1(),
        ),
        _OnboardingPage(
          headlineBuilder: (_) => Text(
            'Emergency Help\nin Seconds',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          body:
              'One-tap alerts to nearby responders and your emergency contacts when you need it most.',
          illustrationBuilder: (_) => const _Illustration2(),
        ),
        _OnboardingPage(
          headlineBuilder: (_) => Text(
            'Your Health,\nAnywhere',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          body:
              'Access your medical records and timely reminders in one clinical sanctuary designed for your peace of mind.',
          illustrationBuilder: (_) => const _Illustration3(),
        ),
      ];

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mesh/radial gradient backgrounds
          const _MeshBackground(),

          // Ambient blobs
          const AmbientBlob(
            color: AppColors.secondaryContainer,
            opacity: 0.15,
            size: 260,
            sigma: 50,
            alignment: Alignment.topLeft,
            offset: Offset(-64, -64),
          ),
          const AmbientBlob(
            color: AppColors.secondary,
            opacity: 0.05,
            size: 200,
            sigma: 40,
            alignment: Alignment.centerRight,
            offset: Offset(64, 0),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Skip / spacer header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.base,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _current < _total - 1 ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Illustration area — swipeable
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemCount: _total,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                        ),
                        child: pages[i].illustrationBuilder(context),
                      );
                    },
                  ),
                ),

                // Bottom content card (stays fixed, animates text)
                _ContentSheet(
                  page: pages[_current],
                  currentIndex: _current,
                  total: _total,
                  onNext: _next,
                  onBack: _back,
                  onLogin: _toLogin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom content card
// ─────────────────────────────────────────────────────────────────────────────

class _ContentSheet extends StatelessWidget {
  const _ContentSheet({
    required this.page,
    required this.currentIndex,
    required this.total,
    required this.onNext,
    required this.onBack,
    required this.onLogin,
  });

  final _OnboardingPage page;
  final int currentIndex;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isLast = currentIndex == total - 1;
    final isFirst = currentIndex == 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(48),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl2, // 32
        AppSpacing.xl2,
        AppSpacing.xl2,
        AppSpacing.xl2 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dots
          _PaginationDots(current: currentIndex, total: total),
          const SizedBox(height: AppSpacing.xl2),

          // Headline (animated switch on page change)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey<int>(currentIndex),
              width: double.infinity,
              child: page.headlineBuilder(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Body copy
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Text(
              page.body,
              key: ValueKey<String>(page.body),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
                height: 1.6,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),

          // Primary button
          GradientButton(
            label: isLast ? 'Get Started' : (isFirst ? 'Next' : 'Continue'),
            onPressed: onNext,
            icon: Icons.arrow_forward_rounded,
          ),

          // Secondary row
          if (!isFirst) ...[
            const SizedBox(height: AppSpacing.sm),
            _BackButton(onBack: onBack),
          ],

          if (isLast) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onLogin,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
              ),
              child: Text(
                'Already have an account? Log In',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination dots
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationDots extends StatelessWidget {
  const _PaginationDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 270),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button (used on pages 2 and 3)
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onBack,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mesh gradient background
// ─────────────────────────────────────────────────────────────────────────────

class _MeshBackground extends StatelessWidget {
  const _MeshBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.8, -0.8),
          radius: 1.2,
          colors: [
            Color(0x2691D78A), // secondary-container tint ~15%
            AppColors.surface,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Illustration panels — native Flutter (no network images)
// ─────────────────────────────────────────────────────────────────────────────

/// Page 1 — "Find the Right Care Faster"
/// Asymmetric bento canvas: care card + floating chips
class _Illustration1 extends StatelessWidget {
  const _Illustration1();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXxxl + 8), // 48
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1400450D),
                      blurRadius: 64,
                      offset: Offset(0, 32),
                    ),
                  ],
                ),
              ),
            ),

            // Center: primary-container icon block (slightly left)
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2000450D),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.onPrimaryContainer,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: 32,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              AppColors.onPrimaryContainer.withAlpha(100),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top-right float: "Verified Care" chip
            Positioned(
              top: 24,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.outlineVariant.withAlpha(26),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'VERIFIED CARE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Certified Specialist',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-right float: "Real-time Matching" glass card
            Positioned(
              bottom: 24,
              right: -4,
              left: 40,
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXxl),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color:
                        AppColors.surfaceContainerLowest.withAlpha(230),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withAlpha(128),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'REAL-TIME MATCHING',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _SkeletonBar(
                          width: double.infinity, color: AppColors.surfaceContainer),
                      const SizedBox(height: AppSpacing.xs),
                      const _SkeletonBar(
                          width: 80, color: AppColors.surfaceContainerHigh),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 2 — "Emergency Help in Seconds"
class _Illustration2 extends StatelessWidget {
  const _Illustration2();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card — slightly rotated
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.06, // ~-3.4 degrees
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxxl + 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 32,
                        offset: Offset(0, 16),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.outlineVariant.withAlpha(26),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxxl + 8),
                    child: Container(
                      color: AppColors.surfaceContainerLow,
                      child: const Center(
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: 64,
                          color: Color(0x2000450D),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top-right: emergency_share in tertiary-container — rotated
            Positioned(
              top: -16,
              right: -16,
              child: Transform.rotate(
                angle: 0.22, // ~12 degrees
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxl + 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.surface,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),

            // Bottom-left: GPS chip
            Positioned(
              bottom: -16,
              left: -16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withAlpha(100),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'REAL-TIME TRACKING',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'GPS Active',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page 3 — "Your Health, Anywhere"
class _Illustration3 extends StatelessWidget {
  const _Illustration3();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main record card — slightly rotated
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.035,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxxl + 8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 48,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXxl),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      const _SkeletonBar(
                          width: 140, color: AppColors.surfaceContainer),
                      const SizedBox(height: AppSpacing.sm),
                      const _SkeletonBar(
                          width: 100, color: AppColors.surfaceContainerHigh),
                      const SizedBox(height: AppSpacing.sm),
                      const _SkeletonBar(
                          width: 120, color: AppColors.surfaceContainer),
                    ],
                  ),
                ),
              ),
            ),

            // Top-right: reminder notification chip — rotated
            Positioned(
              top: -8,
              right: -20,
              child: Transform.rotate(
                angle: 0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXxl),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REMINDER',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.tertiaryContainer,
                            ),
                          ),
                          Text(
                            'Insulin • 8:00 AM',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom-left: health score progress circle
            Positioned(
              bottom: -12,
              left: -12,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2900450D),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CustomPaint(
                    painter: const _HealthScorePainter(score: 0.92),
                    child: Center(
                      child: Text(
                        '92%',
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared utility widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health score arc painter
// ─────────────────────────────────────────────────────────────────────────────

class _HealthScorePainter extends CustomPainter {
  const _HealthScorePainter({required this.score});
  final double score; // 0.0 → 1.0

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -1.5708; // -90° (12 o'clock)
    final sweepAngle = score * 2 * 3.14159;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 6) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc
    canvas.drawArc(
      rect,
      startAngle,
      2 * 3.14159,
      false,
      Paint()
        ..color = AppColors.onPrimaryContainer.withAlpha(50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.onPrimaryContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HealthScorePainter old) => old.score != score;
}

