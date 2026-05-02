import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/keyboard_dismisser.dart';
import '../../../shared/widgets/loading_indicator.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────

class EditMealScreen extends StatefulWidget {
  final int mealId;
  const EditMealScreen({super.key, required this.mealId});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  late final AnimationController _enterCtrl;
  late final AnimationController _macroCtrl;

  // Live macro state for preview ring
  double _protein = 0;
  double _fat = 0;
  double _carbs = 0;
  double _calories = 0;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _macroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    for (final ctrl in [_proteinCtrl, _fatCtrl, _carbsCtrl, _caloriesCtrl]) {
      ctrl.addListener(_onMacroChanged);
    }

    AnalyticsService.editMealOpened(widget.mealId);
    _loadMeal();
  }

  void _onMacroChanged() {
    setState(() {
      _protein = double.tryParse(_proteinCtrl.text) ?? 0;
      _fat = double.tryParse(_fatCtrl.text) ?? 0;
      _carbs = double.tryParse(_carbsCtrl.text) ?? 0;
      _calories = double.tryParse(_caloriesCtrl.text) ?? 0;
    });
  }

  Future<void> _loadMeal() async {
    try {
      final resp = await apiDio.get('/api/meals');
      final list = resp.data as List<dynamic>;
      final meal = list
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['id'] == widget.mealId);
      _nameCtrl.text = meal['name'] as String? ?? '';
      _caloriesCtrl.text = (meal['calories'] as num).toStringAsFixed(1);
      _proteinCtrl.text = (meal['protein'] as num).toStringAsFixed(1);
      _fatCtrl.text = (meal['fat'] as num).toStringAsFixed(1);
      _carbsCtrl.text = (meal['carbs'] as num).toStringAsFixed(1);
    } catch (_) {
      // leave fields empty
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _enterCtrl.forward().then((_) => _macroCtrl.forward());
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await apiDio.patch('/api/meals/${widget.mealId}', data: {
        'name': _nameCtrl.text.trim(),
        'calories': double.parse(_caloriesCtrl.text),
        'protein': double.parse(_proteinCtrl.text),
        'fat': double.parse(_fatCtrl.text),
        'carbs': double.parse(_carbsCtrl.text),
      });
      AnalyticsService.editMealSaved(widget.mealId);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(l10n.edit_meal_saved),
              ],
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.edit_meal_error(e.toString())),
            backgroundColor: AppColors.accentOver,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _macroCtrl.dispose();
    _nameCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _fatCtrl.dispose();
    _carbsCtrl.dispose();
    super.dispose();
  }

  Animation<double> _fadeFor(int i) => CurvedAnimation(
        parent: _enterCtrl,
        curve: Interval(
          (i * 0.1).clamp(0.0, 0.7),
          ((i * 0.1) + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

  Animation<Offset> _slideFor(int i) =>
      Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _enterCtrl,
          curve: Interval(
            (i * 0.1).clamp(0.0, 0.7),
            ((i * 0.1) + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KeyboardDismisser(
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: CustomScrollView(
                slivers: [
                  // ── Gradient AppBar ───────────────────────────────
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    expandedHeight: 110,
                    pinned: true,
                    leading: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.text),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding:
                          const EdgeInsets.fromLTRB(56, 0, 16, 14),
                      title: Text(
                        l10n.edit_meal_title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFDCFCE7), Color(0xFFF4F6F8)],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Content ───────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Macro ring card
                        _buildFade(0, _MacroRingCard(
                          protein: _protein,
                          fat: _fat,
                          carbs: _carbs,
                          calories: _calories,
                          macroCtrl: _macroCtrl,
                          l10n: l10n,
                        )),
                        const SizedBox(height: 16),

                        // Name field
                        _buildFade(1, _StyledField(
                          controller: _nameCtrl,
                          label: l10n.edit_meal_name_label,
                          icon: Icons.restaurant_rounded,
                          iconColor: AppColors.accent,
                          iconBg: AppColors.accentSoft,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? l10n.edit_meal_name_error
                              : null,
                        )),
                        const SizedBox(height: 10),

                        // Calories
                        _buildFade(2, _StyledNumField(
                          controller: _caloriesCtrl,
                          label: l10n.macro_calories,
                          suffix: l10n.macro_kcal,
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.accent,
                          iconBg: AppColors.accentSoft,
                          errEnterValue: l10n.edit_meal_err_enter_value,
                          errInvalidNumber: l10n.edit_meal_err_invalid_number,
                        )),
                        const SizedBox(height: 10),

                        // Protein
                        _buildFade(3, _StyledNumField(
                          controller: _proteinCtrl,
                          label: l10n.macro_protein,
                          suffix: l10n.macro_g,
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.accent,
                          iconBg: AppColors.accentSoft,
                          errEnterValue: l10n.edit_meal_err_enter_value,
                          errInvalidNumber: l10n.edit_meal_err_invalid_number,
                        )),
                        const SizedBox(height: 10),

                        // Fat
                        _buildFade(4, _StyledNumField(
                          controller: _fatCtrl,
                          label: l10n.macro_fat,
                          suffix: l10n.macro_g,
                          icon: Icons.water_drop_rounded,
                          iconColor: AppColors.warm,
                          iconBg: AppColors.warmSoft,
                          errEnterValue: l10n.edit_meal_err_enter_value,
                          errInvalidNumber: l10n.edit_meal_err_invalid_number,
                        )),
                        const SizedBox(height: 10),

                        // Carbs
                        _buildFade(5, _StyledNumField(
                          controller: _carbsCtrl,
                          label: l10n.macro_carbs,
                          suffix: l10n.macro_g,
                          icon: Icons.grain_rounded,
                          iconColor: AppColors.support,
                          iconBg: AppColors.supportSoft,
                          errEnterValue: l10n.edit_meal_err_enter_value,
                          errInvalidNumber: l10n.edit_meal_err_invalid_number,
                        )),
                        const SizedBox(height: 24),

                        // Save button
                        _buildFade(6, _SaveButton(
                          saving: _saving,
                          label: l10n.common_save,
                          onTap: _save,
                        )),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildFade(int i, Widget child) {
    return FadeTransition(
      opacity: _fadeFor(i),
      child: SlideTransition(position: _slideFor(i), child: child),
    );
  }
}

// ─── Macro ring card ──────────────────────────────────────────────────────────

class _MacroRingCard extends StatelessWidget {
  final double protein;
  final double fat;
  final double carbs;
  final double calories;
  final AnimationController macroCtrl;
  final AppLocalizations l10n;

  const _MacroRingCard({
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calories,
    required this.macroCtrl,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + fat + carbs;
    final proteinFrac = total > 0 ? protein / total : 0.0;
    final fatFrac = total > 0 ? fat / total : 0.0;
    final carbsFrac = total > 0 ? carbs / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E1F), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 100,
            height: 100,
            child: AnimatedBuilder(
              animation: macroCtrl,
              builder: (_, __) => CustomPaint(
                painter: _MacroRingPainter(
                  proteinFrac: proteinFrac,
                  fatFrac: fatFrac,
                  carbsFrac: carbsFrac,
                  progress: macroCtrl.value,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        calories > 0
                            ? calories.toStringAsFixed(0)
                            : '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        l10n.macro_kcal,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Macro list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RingLegendRow(
                  color: AppColors.accent,
                  label: l10n.macro_protein,
                  value: '${protein.toStringAsFixed(1)} ${l10n.macro_g}',
                  pct: proteinFrac,
                  ctrl: macroCtrl,
                  delay: 0.1,
                ),
                const SizedBox(height: 10),
                _RingLegendRow(
                  color: AppColors.warm,
                  label: l10n.macro_fat,
                  value: '${fat.toStringAsFixed(1)} ${l10n.macro_g}',
                  pct: fatFrac,
                  ctrl: macroCtrl,
                  delay: 0.25,
                ),
                const SizedBox(height: 10),
                _RingLegendRow(
                  color: AppColors.support,
                  label: l10n.macro_carbs,
                  value: '${carbs.toStringAsFixed(1)} ${l10n.macro_g}',
                  pct: carbsFrac,
                  ctrl: macroCtrl,
                  delay: 0.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double pct;
  final AnimationController ctrl;
  final double delay;

  const _RingLegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.pct,
    required this.ctrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final widthAnim = Tween<double>(begin: 0, end: pct).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(delay, math.min(delay + 0.6, 1.0),
            curve: Curves.easeOutCubic),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 4,
            color: Colors.white.withValues(alpha: 0.15),
            child: AnimatedBuilder(
              animation: widthAnim,
              builder: (_, __) => FractionallySizedBox(
                widthFactor: (pct > 0 ? widthAnim.value / pct : 0.0).clamp(0.0, 1.0),
                alignment: Alignment.centerLeft,
                child: Container(color: color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────

class _MacroRingPainter extends CustomPainter {
  final double proteinFrac;
  final double fatFrac;
  final double carbsFrac;
  final double progress;

  _MacroRingPainter({
    required this.proteinFrac,
    required this.fatFrac,
    required this.carbsFrac,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    if (proteinFrac + fatFrac + carbsFrac == 0) return;

    final segments = [
      (proteinFrac, AppColors.accent),
      (fatFrac, AppColors.warm),
      (carbsFrac, AppColors.support),
    ];

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final (frac, color) in segments) {
      if (frac <= 0) continue;
      final sweep = frac * 2 * math.pi * progress - gap;
      if (sweep <= 0) {
        startAngle += frac * 2 * math.pi * progress;
        continue;
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
      startAngle += frac * 2 * math.pi * progress;
    }
  }

  @override
  bool shouldRepaint(_MacroRingPainter old) =>
      old.proteinFrac != proteinFrac ||
      old.fatFrac != fatFrac ||
      old.carbsFrac != carbsFrac ||
      old.progress != progress;
}

// ─── Styled text field ────────────────────────────────────────────────────────

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          // Icon badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledNumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String errEnterValue;
  final String errInvalidNumber;

  const _StyledNumField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.errEnterValue,
    required this.errInvalidNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 0),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                suffixText: suffix,
                suffixStyle: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return errEnterValue;
                final n = double.tryParse(v);
                if (n == null || n < 0) return errInvalidNumber;
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Save button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool saving;
  final String label;
  final VoidCallback onTap;

  const _SaveButton({
    required this.saving,
    required this.label,
    required this.onTap,
  });

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: widget.saving ? null : (_) => _ctrl.forward(),
        onTapUp: widget.saving
            ? null
            : (_) {
                _ctrl.reverse();
                widget.onTap();
              },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.saving
                ? const LinearGradient(
                    colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)])
                : const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.saving
                ? []
                : [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
