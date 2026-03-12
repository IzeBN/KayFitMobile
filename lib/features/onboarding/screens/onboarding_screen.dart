import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kayfit/core/analytics/analytics_service.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api/api_client.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../core/storage/onboarding_pending_storage.dart';
import '../../../router.dart';
import '../../../shared/models/calculation_result.dart';
import '../../../shared/theme/app_theme.dart';
import '../../way_to_goal/widgets/plan_result_view.dart';

// ─── Step definitions ──────────────────────────────────────────────────────────
enum _Step {
  landing,   // 1
  age,       // 2
  height,    // 3
  gender,    // 4
  weight,    // 5
  training,  // 6
  method,    // 7
  result,    // 8
  auth,      // 9 → navigates to /login
}

const _ageOptions = [
  ('18–24', 21),
  ('25–34', 30),
  ('35–44', 40),
  ('45+', 50),
];

// ─── Calculation helpers ───────────────────────────────────────────────────────
double _getActivityCoef(String trainingDays) {
  if (trainingDays.isEmpty || trainingDays == 'none') return 1.2;
  final cnt = trainingDays.split(',').where((d) => d.trim().isNotEmpty && d.trim() != 'none').length;
  if (cnt >= 6) return 1.725;
  if (cnt >= 3) return 1.55;
  if (cnt >= 1) return 1.375;
  return 1.2;
}

CalculationResult _calcPreview({
  required int age,
  required double weight,
  required double height,
  required String gender,
  required String trainingDays,
  double? targetWeight,
}) {
  final offset = gender == 'male' ? 5.0 : -161.0;
  final bmr = 10 * weight + 6.25 * height - 5 * age + offset;
  final tdee = bmr * _getActivityCoef(trainingDays);
  final target = (tdee - 500).clamp(1200.0, 9999.0);
  final protein = (weight * 1.6);
  final fat = (weight * 0.9);
  final carbs = ((target - protein * 4 - fat * 9) / 4).clamp(0.0, 9999.0);
  int? daysToGoal;
  if (targetWeight != null && targetWeight < weight) {
    final deficit = tdee - target;
    if (deficit > 0) {
      daysToGoal = ((weight - targetWeight) * 7700 / deficit).round();
    }
  }
  return CalculationResult(
    bmr: bmr,
    tdee: tdee,
    targetCalories: target,
    protein: protein,
    fat: fat,
    carbs: carbs,
    daysToGoal: daysToGoal,
    targetWeight: targetWeight,
  );
}

// ─── Main screen ───────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.landing;

  // Data
  int? _age;
  double? _height;
  String _gender = '';
  double? _weight;
  double? _targetWeight;
  final Set<String> _trainingDays = {};

  // Controllers
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  String? _error;
  bool _showSkipDialog = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.onboardingStepViewed(_Step.landing.name);
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────
  void _goNext() {
    AnalyticsService.onboardingStepCompleted(_step.name);
    setState(() {
      _error = null;
      _showSkipDialog = false;
      final steps = _Step.values;
      final idx = steps.indexOf(_step);
      if (idx < steps.length - 1) {
        _step = steps[idx + 1];
        AnalyticsService.onboardingStepViewed(_step.name);
      }
    });
  }

  void _goBack() {
    setState(() {
      _error = null;
      _showSkipDialog = false;
      final steps = _Step.values;
      final idx = steps.indexOf(_step);
      if (idx > 0) {
        _step = steps[idx - 1];
      }
    });
  }

  void _savePending() {
    final td = _trainingDays.isEmpty ? '' : _trainingDays.join(',');
    OnboardingPendingStorage.save(OnboardingPendingData(
      age: _age,
      height: _height,
      gender: _gender.isEmpty ? null : _gender,
      weight: _weight,
      targetWeight: _targetWeight,
      trainingDays: td,
    ));
  }

  // ── Step handlers ───────────────────────────────────────────────────────────
  void _handleAgeSelect(int age) {
    _age = age;
    _savePending();
    _goNext();
  }

  void _handleHeightNext(AppLocalizations l10n) {
    final h = double.tryParse(_heightCtrl.text);
    if (h == null || h < 100 || h > 250) {
      setState(() => _error = l10n.ob_err_height);
      return;
    }
    _height = h;
    _savePending();
    _goNext();
  }

  void _handleGenderSelect(String g) {
    _gender = g;
    _savePending();
    _goNext();
  }

  void _handleWeightNext(AppLocalizations l10n) {
    final w = double.tryParse(_weightCtrl.text);
    if (w == null || w < 30 || w > 300) {
      setState(() => _error = l10n.ob_err_weight);
      return;
    }
    _weight = w;
    final tw = double.tryParse(_targetWeightCtrl.text);
    if (tw == null || tw < 30 || tw > 300) {
      setState(() => _error = l10n.ob_err_target_weight);
      return;
    }
    _targetWeight = tw;
    _savePending();
    _goNext();
  }

  void _handleTrainingNext(AppLocalizations l10n) {
    if (_trainingDays.isEmpty) {
      setState(() => _error = l10n.ob_err_training);
      return;
    }
    _savePending();
    _goNext();
  }

  void _handleTrainingToggle(String value) {
    setState(() {
      if (value == 'none') {
        if (_trainingDays.contains('none')) {
          _trainingDays.clear();
        } else {
          _trainingDays
            ..clear()
            ..add('none');
        }
      } else {
        _trainingDays.remove('none');
        if (_trainingDays.contains(value)) {
          _trainingDays.remove(value);
        } else {
          _trainingDays.add(value);
        }
      }
    });
  }

  Future<void> _navigateToLogin() async {
    // Explicit await-save with all collected data before leaving onboarding.
    // _savePending() calls are fire-and-forget; this final save guarantees
    // the most complete data is persisted before registration/login.
    final td = _trainingDays.isEmpty ? '' : _trainingDays.join(',');
    await OnboardingPendingStorage.save(OnboardingPendingData(
      age: _age,
      height: _height,
      gender: _gender.isEmpty ? null : _gender,
      weight: _weight,
      targetWeight: _targetWeight,
      trainingDays: td,
    ));
    AnalyticsService.onboardingCompleted();
    AnalyticsService.setUserProfile(
      gender: _gender.isNotEmpty ? _gender : null,
      age: _age,
    );
    if (mounted) context.go('/login');
  }

  // ── Result calculation ──────────────────────────────────────────────────────
  CalculationResult get _preview => _calcPreview(
        age: _age ?? 30,
        weight: _weight ?? 65,
        height: _height ?? 165,
        gender: _gender.isEmpty ? 'female' : _gender,
        trainingDays: _trainingDays.join(','),
        targetWeight: _targetWeight,
      );

  // ── Progress ────────────────────────────────────────────────────────────────
  int get _stepIndex => _Step.values.indexOf(_step);
  int get _total => _Step.values.length;
  bool get _canSkip => _stepIndex >= 1 && _stepIndex <= 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLanding = _step == _Step.landing;

    return Scaffold(
      backgroundColor: OBColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              if (!isLanding) _buildHeader(l10n),
              Expanded(
                child: _buildStepContent(l10n),
              ),
              if (!isLanding) _buildFooter(l10n),
            ],
          ),
          if (_showSkipDialog) _buildSkipDialog(l10n),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n) {
    final progress = (_stepIndex + 1) / _total;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppShadow.sm,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.text),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  color: OBColors.pink,
                  backgroundColor: OBColors.border,
                  minHeight: 5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_canSkip)
              GestureDetector(
                onTap: () => setState(() => _showSkipDialog = true),
                child: Text(
                  l10n.ob_skip_btn,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              )
            else
              const SizedBox(width: 50),
          ],
        ),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────────────────────
  Widget _buildFooter(AppLocalizations l10n) {
    VoidCallback? action;
    String label = l10n.common_next;
    bool disabled = false;

    switch (_step) {
      case _Step.landing:
        return const SizedBox.shrink();
      case _Step.age:
        return const SizedBox.shrink(); // tap-to-select
      case _Step.height:
        action = () => _handleHeightNext(l10n);
        label = l10n.common_next;
        disabled = _heightCtrl.text.isEmpty;
      case _Step.gender:
        return const SizedBox.shrink(); // tap-to-select
      case _Step.weight:
        action = () => _handleWeightNext(l10n);
        label = l10n.ob_footer_calc;
        disabled = _weightCtrl.text.isEmpty;
      case _Step.training:
        action = () => _handleTrainingNext(l10n);
        label = l10n.common_next;
        disabled = _trainingDays.isEmpty;
      case _Step.method:
        action = _goNext;
        label = l10n.common_next;
      case _Step.result:
        action = _goNext;
        label = l10n.ob_footer_login;
      case _Step.auth:
        return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _GradientButton(label: label, onTap: disabled ? null : action),
      ),
    );
  }

  // ── Step content ─────────────────────────────────────────────────────────────
  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_step) {
      case _Step.landing:
        return _LandingStep(
          l10n: l10n,
          onNext: _goNext,
          onLogin: () => context.go('/login'),
          locale: ref.watch(localeProvider),
          onLocaleChange: (loc) => ref.read(localeProvider.notifier).setLocale(loc),
          onboardingDone: ref.watch(onboardingDoneProvider),
        );
      case _Step.age:
        return _AgeStep(l10n: l10n, selected: _age, onSelect: _handleAgeSelect);
      case _Step.height:
        return _HeightStep(l10n: l10n, controller: _heightCtrl, error: _error,
            onChanged: (_) => setState(() => _error = null));
      case _Step.gender:
        return _GenderStep(l10n: l10n, selected: _gender, onSelect: _handleGenderSelect);
      case _Step.weight:
        return _WeightStep(
          l10n: l10n,
          weightCtrl: _weightCtrl,
          targetCtrl: _targetWeightCtrl,
          error: _error,
          onChanged: (_) => setState(() => _error = null),
        );
      case _Step.training:
        return _TrainingStep(
          l10n: l10n,
          selected: _trainingDays,
          onToggle: _handleTrainingToggle,
          error: _error,
        );
      case _Step.method:
        return _MethodStep(l10n: l10n);
      case _Step.result:
        return _ResultStep(l10n: l10n, preview: _preview);
      case _Step.auth:
        // Auto-navigate to login
        WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToLogin());
        return const Center(child: CircularProgressIndicator(color: OBColors.pink));
    }
  }

  // ── Skip dialog ─────────────────────────────────────────────────────────────
  Widget _buildSkipDialog(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => setState(() => _showSkipDialog = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.ob_skip_title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(l10n.ob_skip_sub,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _showSkipDialog = false);
                      _goNext();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: OBColors.pink),
                    child: Text(l10n.ob_skip_continue),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => setState(() => _showSkipDialog = false),
                  child: Text(l10n.ob_skip_back,
                      style: const TextStyle(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Landing ───────────────────────────────────────────────────────────
class _LandingStep extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onNext;
  final VoidCallback onLogin;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChange;
  final bool onboardingDone;

  const _LandingStep({
    required this.l10n,
    required this.onNext,
    required this.onLogin,
    required this.locale,
    required this.onLocaleChange,
    required this.onboardingDone,
  });

  @override
  Widget build(BuildContext context) {
    final isRu = locale.languageCode == 'ru';

    return Column(
      children: [
        // Pink-orange header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF597D), Color(0xFFFE7650)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language toggle
                  Align(
                    alignment: Alignment.centerRight,
                    child: _LangToggle(isRu: isRu, onToggle: onLocaleChange),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${l10n.ob_landing_title1} ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        TextSpan(
                          text: l10n.ob_landing_title2,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -1,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.ob_landing_sub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Features
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                _FeatureTile(icon: '📸', text: l10n.ob_demo_perk1),
                const SizedBox(height: 16),
                _FeatureTile(icon: '🎤', text: l10n.ob_demo_perk2),
                const SizedBox(height: 16),
                _FeatureTile(icon: '📊', text: l10n.ob_demo_perk3),
                const SizedBox(height: 16),
                _FeatureTile(icon: '🤖', text: l10n.ob_demo_perk4),
              ],
            ),
          ),
        ),
        // CTA
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                _GradientButton(label: l10n.ob_landing_cta, onTap: onNext),
                if (onboardingDone) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: onLogin,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: OBColors.border, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        AppLocalizations.of(context)!.ob_already_account,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: OBColors.pink,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.ob_landing_cta_sub1} — ${l10n.ob_landing_cta_sub2}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool isRu;
  final ValueChanged<Locale> onToggle;

  const _LangToggle({required this.isRu, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(label: 'RU', active: isRu, onTap: () => onToggle(const Locale('ru'))),
          _Chip(label: 'EN', active: !isRu, onTap: () => onToggle(const Locale('en'))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OBColors.pink : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final String icon;
  final String text;

  const _FeatureTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: OBColors.pinkSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: AppColors.text, height: 1.3),
          ),
        ),
      ],
    );
  }
}

// ─── Step 2: Age ───────────────────────────────────────────────────────────────
class _AgeStep extends StatelessWidget {
  final AppLocalizations l10n;
  final int? selected;
  final ValueChanged<int> onSelect;

  const _AgeStep({required this.l10n, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.ob_step_age_title,
      hint: l10n.ob_step_age_hint,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        physics: const NeverScrollableScrollPhysics(),
        children: _ageOptions.map((opt) {
          final isSelected = selected == opt.$2;
          return _OptionButton(
            label: opt.$1,
            selected: isSelected,
            onTap: () => onSelect(opt.$2),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Step 3: Height ────────────────────────────────────────────────────────────
class _HeightStep extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  const _HeightStep({
    required this.l10n,
    required this.controller,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.ob_step_height_title,
      hint: l10n.ob_step_height_hint,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.text),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    hintText: '170',
                    hintStyle: TextStyle(fontSize: 48, color: AppColors.border),
                  ),
                  onChanged: onChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.ob_step_height_unit,
                  style: const TextStyle(fontSize: 18, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: AppColors.accentOver, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ─── Step 4: Gender ────────────────────────────────────────────────────────────
class _GenderStep extends StatelessWidget {
  final AppLocalizations l10n;
  final String selected;
  final ValueChanged<String> onSelect;

  const _GenderStep({required this.l10n, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.ob_step_gender_title,
      hint: l10n.ob_step_gender_hint,
      child: Row(
        children: [
          Expanded(
            child: _OptionButton(
              label: '👩  ${l10n.ob_step_gender_female}',
              selected: selected == 'female',
              onTap: () => onSelect('female'),
              height: 80,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _OptionButton(
              label: '👨  ${l10n.ob_step_gender_male}',
              selected: selected == 'male',
              onTap: () => onSelect('male'),
              height: 80,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 5: Weight ────────────────────────────────────────────────────────────
class _WeightStep extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController weightCtrl;
  final TextEditingController targetCtrl;
  final String? error;
  final ValueChanged<String> onChanged;

  const _WeightStep({
    required this.l10n,
    required this.weightCtrl,
    required this.targetCtrl,
    this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: l10n.ob_step_weight_title,
      hint: l10n.ob_step_weight_hint,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _WeightCard(
                  label: l10n.ob_step_weight_now,
                  controller: weightCtrl,
                  autofocus: true,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeightCard(
                  label: l10n.ob_step_weight_goal,
                  controller: targetCtrl,
                  autofocus: false,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: AppColors.accentOver, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  const _WeightCard({
    required this.label,
    required this.controller,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: autofocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: '70',
              hintStyle: const TextStyle(fontSize: 32, color: AppColors.border),
              suffixText: AppLocalizations.of(context)!.ob_weight_unit,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Step 6: Training days ─────────────────────────────────────────────────────
class _TrainingStep extends StatelessWidget {
  final AppLocalizations l10n;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String? error;

  const _TrainingStep({
    required this.l10n,
    required this.selected,
    required this.onToggle,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('none', l10n.ob_training_none),
      ('monday', l10n.ob_training_monday),
      ('tuesday', l10n.ob_training_tuesday),
      ('wednesday', l10n.ob_training_wednesday),
      ('thursday', l10n.ob_training_thursday),
      ('friday', l10n.ob_training_friday),
      ('saturday', l10n.ob_training_saturday),
      ('sunday', l10n.ob_training_sunday),
    ];

    return _StepScaffold(
      title: l10n.ob_step_training_title,
      hint: l10n.ob_step_training_sub,
      child: Column(
        children: [
          ...options.map((opt) {
            final isSelected = selected.contains(opt.$1);
            final isDisabled = opt.$1 != 'none' && selected.contains('none');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: isDisabled ? null : () => onToggle(opt.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? OBColors.pinkSoft : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isSelected ? OBColors.pink : OBColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt.$2,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isDisabled
                                ? AppColors.textMuted
                                : isSelected
                                    ? OBColors.pink
                                    : AppColors.text,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: OBColors.pink, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (error != null)
            Text(error!, style: const TextStyle(color: AppColors.accentOver, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Step 7: Method demo ───────────────────────────────────────────────────────
enum _DemoMode { none, text, voice, photo }

class _MethodStep extends StatefulWidget {
  final AppLocalizations l10n;
  const _MethodStep({required this.l10n});

  @override
  State<_MethodStep> createState() => _MethodStepState();
}

enum _DemoLoadingType { none, voice, photo, text }

class _MethodStepState extends State<_MethodStep> with SingleTickerProviderStateMixin {
  _DemoMode _active = _DemoMode.none;
  _DemoLoadingType _loadingType = _DemoLoadingType.none;
  bool get _loading => _loadingType != _DemoLoadingType.none;

  // Text demo
  final _textCtrl = TextEditingController();

  // Voice demo
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordPath;

  // Results
  List<Map<String, dynamic>> _items = [];
  String? _error;

  @override
  void dispose() {
    _textCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode == 'ru' ? 'ru' : 'en';

  Future<void> _parseText(String text) async {
    if (text.trim().isEmpty) return;
    setState(() { _loadingType = _DemoLoadingType.text; _error = null; _items = []; });
    try {
      final resp = await apiDio.post('/api/onboarding/parse_meal', data: {
        'text': text,
        'language': _lang,
      });
      final list = (resp.data['items'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingType = _DemoLoadingType.none);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() { _active = _DemoMode.photo; _items = []; _error = null; });
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file == null) { setState(() => _active = _DemoMode.none); return; }
    setState(() => _loadingType = _DemoLoadingType.photo);
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: 'photo.jpg'),
      });
      final resp = await apiDio.post('/api/onboarding/recognize_photo?language=$_lang', data: form);
      final error = resp.data['error'] as String?;
      final rawItems = resp.data['items'] as List<dynamic>?;
      if (error != null && error.isNotEmpty) {
        setState(() => _error = error);
      } else if (rawItems != null && rawItems.isNotEmpty) {
        setState(() => _items = rawItems.map((e) => e as Map<String, dynamic>).toList());
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingType = _DemoLoadingType.none);
    }
  }

  Future<void> _startVoice() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _error = widget.l10n.ob_method_mic_denied);
      if (status.isPermanentlyDenied) openAppSettings();
      return;
    }
    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/ob_voice.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    if (mounted) setState(() => _isRecording = true);
  }

  Future<void> _stopVoice() async {
    await _recorder.stop();
    setState(() { _isRecording = false; _loadingType = _DemoLoadingType.voice; _items = []; _error = null; });
    try {
      final form = FormData.fromMap({
        'audio': await MultipartFile.fromFile(_recordPath!, filename: 'voice.m4a'),
      });
      final resp = await apiDio.post('/api/onboarding/transcribe', data: form);
      final text = resp.data['text'] as String? ?? '';
      if (text.isNotEmpty) {
        _textCtrl.text = text;
        await _parseText(text);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loadingType = _DemoLoadingType.none);
    }
  }

  void _reset() {
    setState(() {
      _active = _DemoMode.none;
      _items = [];
      _error = null;
      _textCtrl.clear();
    });
  }

  Future<void> _showPhotoSourcePicker() async {
    final l10n = widget.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.addMeal_photo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _OBSourceOption(
              icon: Icons.camera_alt_rounded,
              label: l10n.addMeal_takePhoto,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            _OBSourceOption(
              icon: Icons.photo_library_rounded,
              label: l10n.addMeal_choosePhoto,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel,
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    _pickPhoto(source);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.ob_method_title,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(l10n.ob_method_sub,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),

              // Method tiles
              _MethodTile(
                icon: '📸',
                title: l10n.ob_method_photo_title,
                desc: l10n.ob_method_photo_desc,
                active: _active == _DemoMode.photo,
                onTap: _loading ? null : () {
                  setState(() { _active = _DemoMode.photo; _items = []; _error = null; });
                  _showPhotoSourcePicker();
                },
              ),
              const SizedBox(height: 10),
              _MethodTile(
                icon: '🎤',
                title: l10n.ob_method_voice_title,
                desc: _active == _DemoMode.voice && _isRecording
                    ? l10n.ob_method_recording
                    : l10n.ob_method_voice_desc,
                active: _active == _DemoMode.voice,
                recording: _isRecording,
                onTap: _loading ? null : () {
                  if (_active != _DemoMode.voice) {
                    setState(() { _active = _DemoMode.voice; _items = []; _error = null; });
                    _startVoice();
                  } else if (_isRecording) {
                    _stopVoice();
                  } else {
                    _startVoice();
                  }
                },
              ),
              const SizedBox(height: 10),
              _MethodTile(
                icon: '⌨️',
                title: l10n.ob_method_text_title,
                desc: l10n.ob_method_text_desc,
                active: _active == _DemoMode.text,
                onTap: _loading ? null : () => setState(() {
                  _active = _DemoMode.text;
                  _items = [];
                  _error = null;
                }),
              ),

              // Text input area
              if (_active == _DemoMode.text) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _textCtrl,
                  autofocus: true,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: l10n.ob_method_text_hint,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: OBColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: OBColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: OBColors.pink, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _loadingType == _DemoLoadingType.text ? null : () => _parseText(_textCtrl.text),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: OBColors.gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _loadingType == _DemoLoadingType.text
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(l10n.ob_method_recognize,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],

              // Error
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentOverSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.accentOver, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.accentOver))),
                      GestureDetector(onTap: _reset, child: const Icon(Icons.close, size: 16, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],

              // Results
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OBColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(l10n.ob_method_recognized,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _reset,
                            child: Text(l10n.ob_method_reset,
                                style: const TextStyle(color: OBColors.pink, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._items.map((item) {
                        final sug = item['suggestions'] as List<dynamic>?;
                        final first = (sug != null && sug.isNotEmpty)
                            ? sug[0] as Map<String, dynamic>
                            : item;
                        final name = first['name'] as String? ?? item['name'] as String? ?? '';
                        final cal = (first['calories'] as num?)?.toStringAsFixed(0) ?? '?';
                        final protein = (first['protein'] as num?)?.toStringAsFixed(0);
                        final fat = (first['fat'] as num?)?.toStringAsFixed(0);
                        final carbs = (first['carbs'] as num?)?.toStringAsFixed(0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(color: OBColors.pink, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                              Text(l10n.ob_method_kcal(cal),
                                  style: const TextStyle(fontSize: 13, color: OBColors.pink, fontWeight: FontWeight.w700)),
                              if (protein != null) ...[
                                const SizedBox(width: 6),
                                Text(l10n.ob_method_macros(protein, fat ?? '0', carbs ?? '0'),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: OBColors.pinkSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.ob_method_ai_success,
                          style: const TextStyle(color: OBColors.pink, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Animated recognition overlay for voice/photo
        if (_loadingType == _DemoLoadingType.voice || _loadingType == _DemoLoadingType.photo)
          _OBRecognizingOverlay(
            type: _loadingType,
            l10n: widget.l10n,
          ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String icon;
  final String title;
  final String desc;
  final bool active;
  final bool recording;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.active = false,
    this.recording = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? OBColors.pinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: active ? OBColors.pink : OBColors.border,
            width: active ? 2 : 1,
          ),
          boxShadow: active ? OBColors.buttonShadow : AppShadow.sm,
        ),
        child: Row(
          children: [
            recording
                ? _PulsingDot()
                : Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: active ? OBColors.pink : AppColors.text,
                      )),
                  const SizedBox(height: 2),
                  Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(
              active ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: active ? OBColors.pink : AppColors.textMuted,
              size: active ? 22 : 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.5, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.accentOver.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Step 8: Result ────────────────────────────────────────────────────────────
class _ResultStep extends StatelessWidget {
  final AppLocalizations l10n;
  final CalculationResult preview;

  const _ResultStep({required this.l10n, required this.preview});

  @override
  Widget build(BuildContext context) {
    return PlanResultView(calc: preview, l10n: l10n);
  }
}

// ─── Shared scaffold ───────────────────────────────────────────────────────────
class _StepScaffold extends StatelessWidget {
  final String title;
  final String hint;
  final Widget child;

  const _StepScaffold({required this.title, required this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: OBColors.pinkSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(hint,
                      style: const TextStyle(color: OBColors.pink, fontSize: 13, height: 1.4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ─── Gradient button ───────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _GradientButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: disabled
              ? null
              : OBColors.gradient,
          color: disabled ? AppColors.border : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled ? [] : OBColors.buttonShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: disabled ? AppColors.textMuted : Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─── Option button ─────────────────────────────────────────────────────────────
class _OptionButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? OBColors.pinkSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: selected ? OBColors.pink : OBColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [] : AppShadow.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? OBColors.pink : AppColors.text,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Onboarding recognition overlay ───────────────────────────────────────────

class _OBRecognizingOverlay extends StatefulWidget {
  final _DemoLoadingType type;
  final AppLocalizations l10n;
  const _OBRecognizingOverlay({required this.type, required this.l10n});

  @override
  State<_OBRecognizingOverlay> createState() => _OBRecognizingOverlayState();
}

class _OBRecognizingOverlayState extends State<_OBRecognizingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVoice = widget.type == _DemoLoadingType.voice;
    final label = isVoice
        ? widget.l10n.ob_recognizing_voice
        : widget.l10n.ob_recognizing_photo;

    return Container(
      color: OBColors.bg.withValues(alpha: 0.97),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVoice)
            _OBWaveAnimation(controller: _ctrl)
          else
            _OBScanAnimation(controller: _ctrl),
          const SizedBox(height: 28),
          Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          _OBDotLoading(controller: _ctrl),
        ],
      ),
    );
  }
}

class _OBWaveAnimation extends StatelessWidget {
  final AnimationController controller;
  const _OBWaveAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    const barCount = 7;
    const barWidth = 7.0;
    const maxH = 50.0;
    const minH = 8.0;
    const gap = 6.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: OBColors.pinkSoft, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final phase = (i / barCount) * 6.2832;
              final v = t * 6.2832 + phase;
              final sine = 0.5 + 0.5 * _approxSin(v);
              final h = minH + (maxH - minH) * sine;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: gap / 2),
                child: Container(
                  width: barWidth,
                  height: h,
                  decoration: BoxDecoration(
                    color: OBColors.pink,
                    borderRadius: BorderRadius.circular(barWidth / 2),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double _approxSin(double x) {
    final v = (x / 6.2832) - (x / 6.2832).floorToDouble();
    return v < 0.5 ? 4 * v * (1 - 2 * v) : -1 + 4 * v * (1 - v);
  }
}

class _OBScanAnimation extends StatelessWidget {
  final AnimationController controller;
  const _OBScanAnimation({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pulse = 0.4 + 0.3 * (0.5 + 0.5 * _approxCos(controller.value * 6.2832));
        return SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: pulse,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: OBColors.pinkSoft, shape: BoxShape.circle),
                ),
              ),
              Transform.rotate(
                angle: controller.value * 6.2832,
                child: CustomPaint(size: const Size(88, 88), painter: _OBArcPainter()),
              ),
              const Icon(Icons.camera_alt_rounded, color: OBColors.pink, size: 32),
            ],
          ),
        );
      },
    );
  }

  double _approxCos(double x) {
    final v = (x / 6.2832) - (x / 6.2832).floorToDouble();
    return 1 - 8 * v * (1 - v);
  }
}

class _OBArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OBColors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), 0, 1.8, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _OBDotLoading extends StatelessWidget {
  final AnimationController controller;
  const _OBDotLoading({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final count = ((controller.value * 3).floor() % 4);
        return Text(
          '●' * count + '○' * (3 - count),
          style: const TextStyle(fontSize: 12, color: OBColors.pink, letterSpacing: 4),
        );
      },
    );
  }
}

class _OBSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OBSourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: OBColors.border),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, color: OBColors.pink),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
