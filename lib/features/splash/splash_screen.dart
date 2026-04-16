import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/ambient_blob.dart';

/// Mboa Health Splash Screen — full Phase 2 implementation.
///
/// Layout (Clinical Sanctuary design system):
/// - Ambient tonal blobs (top-right secondary-container, bottom-left primary-container)
/// - Central brand block: icon card + "Mboa Health" + tagline
/// - Bottom: animated loading bar + "PRECISION CARE • CAMEROON" footnote
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingCtrl;
  late final Animation<double> _thumbAnim;

  @override
  void initState() {
    super.initState();
    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _thumbAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingCtrl, curve: Curves.easeInOut),
    );
    Future<void>.delayed(const Duration(milliseconds: 2800)).then((_) async {
      if (!mounted) return;
      // Attempt to restore a stored session before routing.
      // ignore: use_build_context_synchronously
      final auth = context.read<AuthProvider>();
      final restored = await auth.tryRestoreSession();
      if (!mounted) return;
      if (restored) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    });
  }

  @override
  void dispose() {
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient tonal blobs ─────────────────────────────────────────
          const AmbientBlob(
            color: AppColors.secondaryContainer,
            size: 320,
            offset: Offset(80, -80),
          ),
          const AmbientBlob(
            color: AppColors.primaryContainer,
            opacity: 0.05,
            size: 260,
            sigma: 50,
            alignment: Alignment.bottomLeft,
            offset: Offset(-48, 48),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                _BrandBlock(),
                const Spacer(),
                _LoadingSection(thumbAnim: _thumbAnim),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Brand block widget ─────────────────────────────────────────────────────

class _BrandBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon card — white, 96×96, radius 40, subtle ambient shadow
        Container(
          width: AppSpacing.avatarLg, // 96
          height: AppSpacing.avatarLg,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxxl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(
              color: AppColors.primary.withAlpha(13), // 5%
            ),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            size: AppSpacing.iconXl, // 48
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl2), // 32

        // "Mboa Health" — Manrope ExtraBold 32 primary
        Text(
          'Mboa Health',
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md), // 12

        // Tagline — Inter Medium onSurfaceVariant 80%
        Text(
          'Your Smart Health Guide',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant.withAlpha(204), // 80%
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ── Loading section widget ─────────────────────────────────────────────────

class _LoadingSection extends StatelessWidget {
  const _LoadingSection({required this.thumbAnim});
  final Animation<double> thumbAnim;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl4), // 48
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated gradient loading bar — 140×4 px
          SizedBox(
            width: 140,
            height: 4,
            child: AnimatedBuilder(
              animation: thumbAnim,
              builder: (context, _) => CustomPaint(
                painter: _LoadingBarPainter(progress: thumbAnim.value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2), // 32

          // Footnote — 10px uppercase tracking label
          Text(
            'PRECISION CARE  •  CAMEROON',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.5,
              color: AppColors.outline.withAlpha(153), // 60%
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading bar custom painter ─────────────────────────────────────────────

class _LoadingBarPainter extends CustomPainter {
  const _LoadingBarPainter({required this.progress});
  final double progress; // 0.0 → 1.0 (AnimationController oscillates)

  @override
  void paint(Canvas canvas, Size size) {
    const r = Radius.circular(AppSpacing.radiusFull);

    // Track
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, r),
      Paint()..color = AppColors.surfaceContainerLow,
    );

    // Thumb: 40% wide, slides within the remaining 60%
    final thumbW = size.width * 0.40;
    final maxLeft = size.width - thumbW;
    const centerBias = 0.3; // keep thumb in visual center zone
    final left = (progress * maxLeft * (1 - centerBias)) + (maxLeft * centerBias * 0.5);
    final thumbRect = Rect.fromLTWH(left, 0, thumbW, size.height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, r),
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer],
        ).createShader(thumbRect),
    );
  }

  @override
  bool shouldRepaint(_LoadingBarPainter old) => old.progress != progress;
}
