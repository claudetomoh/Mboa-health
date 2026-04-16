import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/gradient_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Symptom Checker Screen
// Design ref: symptom_checker/code.html
// ─────────────────────────────────────────────────────────────────────────────

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final List<String> _selected = ['Migraine', 'Nausea'];

  static const _suggestions = [
    _Symptom(Icons.thermostat_rounded, 'Fever', 'High body temp'),
    _Symptom(Icons.air_rounded, 'Shortness of breath', 'Difficulty breathing'),
    _Symptom(Icons.sick_rounded, 'Stomach pain', 'Abdominal cramps'),
    _Symptom(Icons.psychology_rounded, 'Dizziness', 'Feeling faint'),
    _Symptom(Icons.monitor_heart_rounded, 'Palpitations', 'Irregular heartbeat'),
    _Symptom(Icons.visibility_off_rounded, 'Blurred Vision', 'Sight changes'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _AppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal, AppSpacing.xl,
                AppSpacing.screenHorizontal, AppSpacing.xl8,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero
                  Text('How are you\nfeeling?',
                      style: AppTypography.displayMd.copyWith(
                        color: AppColors.primary, letterSpacing: -1.2)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Describe your symptoms below for a clinical assessment.',
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xl),
                  // Search
                  _SearchField(controller: _searchCtrl, focusNode: _searchFocus),
                  const SizedBox(height: AppSpacing.xl),
                  // Selected chips
                  Text('CURRENTLY SELECTED',
                      style: AppTypography.labelSm.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  _SelectedChips(
                    selected: _selected,
                    onRemove: (s) => setState(() => _selected.remove(s)),
                    onAddMore: () => _searchFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // Suggestions
                  Text('COMMON SYMPTOMS',
                      style: AppTypography.labelSm.copyWith(letterSpacing: 1.5)),
                  const SizedBox(height: AppSpacing.md),
                  _SuggestionsGrid(
                    items: _suggestions,
                    onTap: (name) {
                      if (!_selected.contains(name)) {
                        setState(() => _selected.add(name));
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Validated card
                  const _ValidatedCard(),
                  const SizedBox(height: AppSpacing.xl),
                  // CTA
                  GradientButton(
                    label: 'Analyze My Symptoms',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.analysisResult),
                  ),
                  const SizedBox(height: AppSpacing.xl6),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
      ),
      title: Text('Mboa Health',
          style: AppTypography.titleLg.copyWith(
            color: AppColors.primary, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Options coming soon.')),
          ),
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, this.focusNode});
  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: AppTypography.bodyMdOnSurface,
      decoration: InputDecoration(
        hintText: 'Search symptoms (e.g. Headache, Fever...)',
        hintStyle: AppTypography.bodyMd,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.base),
      ),
    );
  }
}

// ─── Selected Chips ───────────────────────────────────────────────────────────

class _SelectedChips extends StatelessWidget {
  const _SelectedChips({
    required this.selected,
    required this.onRemove,
    this.onAddMore,
  });
  final List<String> selected;
  final ValueChanged<String> onRemove;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ...selected.map((s) => _Chip(
              label: s,
              active: true,
              onTap: () => onRemove(s),
            )),
        GestureDetector(
          onTap: onAddMore,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: AppColors.outlineVariant,
              ),
            ),
            child: Text('Add more...',
                style: AppTypography.bodyMd.copyWith(
                    fontStyle: FontStyle.italic, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppTypography.labelMd.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.close_rounded,
                size: 14, color: AppColors.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestions Grid ─────────────────────────────────────────────────────────

class _Symptom {
  const _Symptom(this.icon, this.name, this.sub);
  final IconData icon;
  final String name;
  final String sub;
}

class _SuggestionsGrid extends StatelessWidget {
  const _SuggestionsGrid({required this.items, required this.onTap});
  final List<_Symptom> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.3,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final s = items[i];
        return GestureDetector(
          onTap: () => onTap(s.name),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(s.icon, color: AppColors.secondary, size: 26),
                const Spacer(),
                Text(s.name,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(s.sub, style: AppTypography.labelSm),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Validated Card ───────────────────────────────────────────────────────────

class _ValidatedCard extends StatelessWidget {
  const _ValidatedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8)
              ],
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clinically Validated',
                    style: AppTypography.titleMd.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                    'Our AI assessment is based on peer-reviewed clinical protocols and diagnostic data.',
                    style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
