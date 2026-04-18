import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/gradient_button.dart';
import 'providers/symptom_checker_provider.dart';

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
  String _searchQuery = '';

  // Full symptom catalogue (shown as suggestion cards)
  static const _allSuggestions = [
    _Symptom(Icons.thermostat_rounded,       'Fever',                'High body temperature'),
    _Symptom(Icons.thermostat_auto_rounded,  'High Fever',           'Temperature above 39 °C'),
    _Symptom(Icons.air_rounded,              'Shortness of breath',  'Difficulty breathing'),
    _Symptom(Icons.sick_rounded,             'Stomach pain',         'Abdominal cramps'),
    _Symptom(Icons.psychology_rounded,       'Dizziness',            'Feeling faint or lightheaded'),
    _Symptom(Icons.monitor_heart_rounded,    'Palpitations',         'Irregular or fast heartbeat'),
    _Symptom(Icons.visibility_off_rounded,   'Blurred Vision',       'Sight changes'),
    _Symptom(Icons.sentiment_very_dissatisfied_rounded, 'Nausea',   'Feeling like vomiting'),
    _Symptom(Icons.water_drop_rounded,       'Diarrhea',             'Loose, watery stools'),
    _Symptom(Icons.medical_services_rounded, 'Vomiting',             'Expelling stomach contents'),
    _Symptom(Icons.thunderstorm_rounded,     'Headache',             'Head pain or pressure'),
    _Symptom(Icons.blur_on_rounded,           'Migraine',             'Severe throbbing headache'),
    _Symptom(Icons.ac_unit_rounded,           'Chills',               'Shivering with fever'),
    _Symptom(Icons.airline_seat_flat_rounded,'Fatigue',              'Extreme tiredness'),
    _Symptom(Icons.fireplace_rounded,        'Body ache',            'Generalized muscle pain'),
    _Symptom(Icons.healing_rounded,          'Cough',                'Persistent coughing'),
    _Symptom(Icons.face_rounded,             'Sore throat',          'Throat pain or irritation'),
    _Symptom(Icons.water_rounded,            'Runny nose',           'Nasal discharge'),
    _Symptom(Icons.monitor_outlined,         'Chest pain',           'Chest tightness or pain'),
    _Symptom(Icons.back_hand_rounded,        'Back pain',            'Lower or upper back pain'),
    _Symptom(Icons.directions_run_rounded,   'Joint pain',           'Pain in joints'),
    _Symptom(Icons.opacity_rounded,          'Sweating',             'Excessive sweating'),
    _Symptom(Icons.local_drink_rounded,      'Excessive thirst',     'Always feeling thirsty'),
    _Symptom(Icons.wc_rounded,               'Frequent urination',   'Urinating more than usual'),
    _Symptom(Icons.sentiment_dissatisfied_rounded, 'Loss of appetite','Not feeling hungry'),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<_Symptom> get _filteredSuggestions {
    if (_searchQuery.isEmpty) return _allSuggestions;
    return _allSuggestions
        .where((s) =>
            s.name.toLowerCase().contains(_searchQuery) ||
            s.sub.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _onAnalyze() {
    final provider = context.read<SymptomCheckerProvider>();
    if (provider.selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one symptom first.'),
        ),
      );
      return;
    }
    provider.analyze();
    Navigator.pushNamed(context, AppRoutes.analysisResult);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SymptomCheckerProvider>();
    final selected = provider.selectedSymptoms;
    final filtered = _filteredSuggestions;

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
                  _SearchField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isNotEmpty) {
                        context.read<SymptomCheckerProvider>().addSymptom(trimmed);
                        _searchCtrl.clear();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Selected chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('CURRENTLY SELECTED',
                          style: AppTypography.labelSm.copyWith(letterSpacing: 1.5)),
                      if (selected.isNotEmpty)
                        GestureDetector(
                          onTap: () => context.read<SymptomCheckerProvider>().clearAll(),
                          child: Text('Clear all',
                              style: AppTypography.labelSm.copyWith(
                                  color: AppColors.error,
                                  letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SelectedChips(
                    selected: selected,
                    onRemove: (s) =>
                        context.read<SymptomCheckerProvider>().removeSymptom(s),
                    onAddMore: () => _searchFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // Suggestions
                  Text(
                    _searchQuery.isEmpty ? 'COMMON SYMPTOMS' : 'SEARCH RESULTS',
                    style: AppTypography.labelSm.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No symptoms found for "$_searchQuery".\nPress Enter to add it manually.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    _SuggestionsGrid(
                      items: filtered,
                      selectedNames: selected,
                      onTap: (name) =>
                          context.read<SymptomCheckerProvider>().addSymptom(name),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  // Validated card
                  const _ValidatedCard(),
                  const SizedBox(height: AppSpacing.xl),
                  // CTA
                  GradientButton(
                    label: selected.isEmpty
                        ? 'Select symptoms above'
                        : 'Analyze My Symptoms (${selected.length})',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _onAnalyze,
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
      actions: const [],
    );
  }
}

// ─── Search Field ─────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    this.focusNode,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: AppTypography.bodyMdOnSurface,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: 'Search or type a symptom...',
        hintStyle: AppTypography.bodyMd,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.outline),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, color: AppColors.outline, size: 20),
                onPressed: () => controller.clear(),
              )
            : null,
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
  const _SuggestionsGrid({
    required this.items,
    required this.onTap,
    required this.selectedNames,
  });
  final List<_Symptom> items;
  final ValueChanged<String> onTap;
  final List<String> selectedNames;

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
        final isSelected = selectedNames.contains(s.name);
        return GestureDetector(
          onTap: () => onTap(s.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(s.icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.secondary,
                        size: 26),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 18),
                  ],
                ),
                const Spacer(),
                Text(s.name,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurface)),
                const SizedBox(height: AppSpacing.xs2),
                Text(s.sub,
                    style: AppTypography.labelSm.copyWith(
                        color: isSelected
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant)),
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
