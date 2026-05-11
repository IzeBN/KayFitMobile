import 'package:flutter/material.dart';

import 'package:kayfit/features/body_form/body_form_calc.dart';
import 'package:kayfit/features/body_form/body_form_prefs.dart';
import 'package:kayfit/features/body_form/i18n/body_form_strings.dart';
import 'package:kayfit/features/onboarding/widgets/ob_gradient_button.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

/// Two-step body-shape picker: current → desired form, 7 photos each.
///
/// Reads/writes selection to [SharedPreferences] via [BodyFormPrefs].
/// Calls [onCompleted] when the user finishes the second step.
///
/// When [isOnboarding] is `true` the screen renders without its own header
/// (the onboarding scaffold provides the global progress indicator). When
/// `false` (Settings entry point) it draws its own back button.
class BodyFormScreen extends StatefulWidget {
  const BodyFormScreen({
    super.key,
    required this.gender,
    this.isOnboarding = true,
    this.initialCurrent = 0,
    this.initialDesired = 0,
    this.currentWeight,
    this.onCompleted,
  });

  /// `'male'` | `'female'` | `''` (empty falls back to male assets).
  final String gender;

  /// `true` when the screen is embedded as an onboarding step.
  final bool isOnboarding;

  /// Pre-selected slider position for step 0 (0..6).
  final int initialCurrent;

  /// Pre-selected slider position for step 1 (0..6).
  final int initialDesired;

  /// Current weight in kg — used to derive a target weight.
  /// Pass `null` if unknown; [onCompleted] will receive `null` for the
  /// computed target.
  final double? currentWeight;

  /// Fired on the final step's "Done" button.
  ///
  /// [currentIndex] / [desiredIndex] are 0-based slider positions.
  /// [targetWeight] is `null` when the user did not pick a slimming goal
  /// (same form, fatter form, or [currentWeight] is unknown).
  final void Function(int currentIndex, int desiredIndex, double? targetWeight)?
  onCompleted;

  @override
  State<BodyFormScreen> createState() => _BodyFormScreenState();
}

class _BodyFormScreenState extends State<BodyFormScreen> {
  late int _currentSelected = widget.initialCurrent.clamp(0, 6);
  late int _desiredSelected = widget.initialDesired.clamp(0, 6);
  int _step = 0;

  bool get _isFemale => widget.gender == 'female' || widget.gender == 'Ж';

  List<String> get _images => _isFemale ? kBodyImagesFemale : kBodyImagesMale;

  int get _selected => _step == 0 ? _currentSelected : _desiredSelected;

  void _setSelected(int v) {
    setState(() {
      if (_step == 0) {
        _currentSelected = v;
      } else {
        _desiredSelected = v;
      }
    });
  }

  Future<void> _handleNext() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    await BodyFormPrefs.save(
      current: _currentSelected,
      desired: _desiredSelected,
    );
    final tw = widget.currentWeight == null
        ? null
        : calcTargetWeight(
            currentWeight: widget.currentWeight!,
            currentIndex: _currentSelected,
            desiredIndex: _desiredSelected,
          );
    if (!mounted) return;
    final cb = widget.onCompleted;
    if (cb != null) {
      cb(_currentSelected, _desiredSelected, tw);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _handleBack() {
    if (_step == 1) {
      setState(() => _step = 0);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final bg = widget.isOnboarding ? OBColors.bg : AppColors.bg;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isOnboarding) _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: _buildContent(isRu),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.text,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: OBColors.pink,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildContent(bool isRu) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _step == 0
              ? BodyFormStrings.currentQuestion(isRu)
              : BodyFormStrings.desiredQuestion(isRu),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          BodyFormStrings.subtitle(isRu),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Image.asset(
              _images[_selected],
              key: ValueKey('body-form-${_isFemale ? 'f' : 'm'}-$_selected'),
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Container(
                height: 220,
                color: AppColors.border,
                child: const Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 80,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(child: _buildSlider(isRu)),
        const SizedBox(height: 36),
        _buildGoalCard(isRu),
        const SizedBox(height: 20),
        ObGradientButton(
          label: _step == 0
              ? BodyFormStrings.nextButton(isRu)
              : BodyFormStrings.finishButton(isRu),
          onTap: _handleNext,
        ),
      ],
    );
  }

  Widget _buildSlider(bool isRu) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 320.0);
        const count = 7;
        final filledWidth = (_selected / (count - 1)) * width;
        final thumbLeft = (_selected / (count - 1)) * (width - 32);

        return SizedBox(
          width: width,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 13,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: OBColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 13,
                width: filledWidth,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: OBColors.pink.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                left: thumbLeft,
                top: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: OBColors.pink,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: OBColors.pink.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              for (int i = 0; i < count; i++)
                Positioned(
                  left: (i / (count - 1)) * (width - 24),
                  top: 4,
                  child: GestureDetector(
                    key: ValueKey('body-form-dot-$i'),
                    onTap: () => _setSelected(i),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _selected ? OBColors.pink : Colors.white,
                        border: Border.all(
                          color: i == _selected
                              ? OBColors.pink
                              : OBColors.border,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        BodyFormStrings.sliderLean(isRu),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        BodyFormStrings.sliderCurvy(isRu),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(bool isRu) {
    final selected = _selected;
    final isSafe = BodyFormStrings.goalIsSafe(selected);
    final title = BodyFormStrings.goalTitle(selected, isRu);
    final desc = BodyFormStrings.goalDesc(selected, isRu);
    final range = BodyFormStrings.goalRange(selected);
    final infoLabel = _step == 0
        ? BodyFormStrings.currentLabel(isRu)
        : BodyFormStrings.goalLabel(isRu);
    final infoIcon = _step == 0
        ? Icons.person_outline_rounded
        : Icons.smart_toy_outlined;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: OBColors.pinkSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: OBColors.pink.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(infoIcon, size: 18, color: OBColors.pink),
              const SizedBox(width: 8),
              Text(
                infoLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: OBColors.pink,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$range · $title',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isSafe ? const Color(0xFF16A34A) : AppColors.warm,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
