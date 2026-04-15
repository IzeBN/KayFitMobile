import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/models/calculation_result.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/i18n/generated/app_localizations.dart';

enum _GoalMode { lose, gain, maintain }

_GoalMode _detectGoalMode(CalculationResult calc, List<String> goals) {
  // 1. Weight direction — most reliable, set by provider from actual data
  final cw = calc.currentWeight;
  final tw = calc.targetWeight;
  if (cw != null && tw != null) {
    if (tw - cw > 0.5) return _GoalMode.gain;
    if ((tw - cw).abs() <= 0.5) return _GoalMode.maintain;
    return _GoalMode.lose;
  }

  // 2. Explicit goals
  if (goals.contains('gain_muscle')) return _GoalMode.gain;
  if (goals.contains('maintain_weight')) return _GoalMode.maintain;

  // 3. Calorie diff (provider sets tdee+400 for gain)
  final diff = calc.targetCalories - calc.tdee;
  if (diff > 50) return _GoalMode.gain;
  if (diff.abs() <= 50) return _GoalMode.maintain;
  return _GoalMode.lose;
}

/// Shared plan-result view used by WayToGoalScreen and OnboardingScreen (_ResultStep).
/// Pass [footer] to inject a CTA button at the bottom.
/// Pass [goals] to adapt content based on selected onboarding goals.
class PlanResultView extends StatelessWidget {
  final CalculationResult calc;
  final AppLocalizations l10n;
  final Widget? footer;
  final List<String> goals;

  const PlanResultView({
    super.key,
    required this.calc,
    required this.l10n,
    this.footer,
    this.goals = const [],
  });

  @override
  Widget build(BuildContext context) {
    final mode = _detectGoalMode(calc, goals);
    final heroEmoji = switch (mode) {
      _GoalMode.gain => '💪',
      _GoalMode.maintain => '⚖️',
      _GoalMode.lose => '🎯',
    };
    final heroSubtitle = switch (mode) {
      _GoalMode.gain => l10n.wg_personal_calc_gain,
      _GoalMode.maintain => l10n.wg_personal_calc_maintain,
      _GoalMode.lose => l10n.wg_personal_calc,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        const SizedBox(height: 24),
        // ── Hero gradient card ───────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: OBColors.gradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: OBColors.buttonShadow,
          ),
          child: Column(
            children: [
              Text(heroEmoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                l10n.wg_plan_ready,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                heroSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      calc.targetCalories.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: OBColors.pink,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                    Text(
                      l10n.wg_kcal_day,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Macros card ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.wg_macronutrients,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MacroChip(
                    label: l10n.macro_protein,
                    value: calc.protein,
                    color: AppColors.accent,
                    bgColor: AppColors.accentSoft,
                    unit: l10n.macro_g,
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: l10n.macro_fat,
                    value: calc.fat,
                    color: AppColors.warm,
                    bgColor: AppColors.warmSoft,
                    unit: l10n.macro_g,
                  ),
                  const SizedBox(width: 8),
                  _MacroChip(
                    label: l10n.macro_carbs,
                    value: calc.carbs,
                    color: AppColors.support,
                    bgColor: AppColors.supportSoft,
                    unit: l10n.macro_g,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Scientific source citation (prominent placement) ─────────────
        _CitationCard(l10n: l10n),

        if (calc.daysToGoal != null || calc.targetWeight != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                if (calc.daysToGoal != null)
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: l10n.wg_days_to_goal(calc.daysToGoal as int),
                  ),
                if (calc.daysToGoal != null && calc.targetWeight != null)
                  const SizedBox(height: 10),
                if (calc.targetWeight != null)
                  _InfoRow(
                    icon: Icons.flag_outlined,
                    text: l10n.wg_target_weight_val(
                        (calc.targetWeight as double).toStringAsFixed(1)),
                  ),
              ],
            ),
          ),
        ],

        // ── Weight forecast chart ────────────────────────────────────────────
        const SizedBox(height: 12),
        _WeightChart(calc: calc, l10n: l10n, mode: mode),

        const SizedBox(height: 12),

        // ── How to reach card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.wg_how_to_reach,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                  emoji: '📸',
                  title: l10n.wg_feature_photo_title,
                  desc: l10n.wg_feature_photo_desc),
              const SizedBox(height: 12),
              _FeatureRow(
                  emoji: '🎤',
                  title: l10n.wg_feature_voice_title,
                  desc: l10n.wg_feature_voice_desc),
              const SizedBox(height: 12),
              _FeatureRow(
                  emoji: '📊',
                  title: l10n.wg_feature_track_title,
                  desc: l10n.wg_feature_track_desc),
            ],
          ),
        ),

        const SizedBox(height: 28),

        ?footer,
      ],
    );
  }
}

// ── Macro chip ──────────────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color bgColor;
  final String unit;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(0)}$unit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

// ── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OBColors.pink),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 15, color: AppColors.text)),
      ],
    );
  }
}

// ── Feature row ─────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FeatureRow({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OBColors.pinkSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Scientific source citation ───────────────────────────────────────────────

class _CitationCard extends StatefulWidget {
  final AppLocalizations l10n;
  const _CitationCard({required this.l10n});

  @override
  State<_CitationCard> createState() => _CitationCardState();
}

class _CitationCardState extends State<_CitationCard> {
  static const _pubmedUrl = 'https://pubmed.ncbi.nlm.nih.gov/2305711/';
  static const _whoUrl = 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet';

  late final TapGestureRecognizer _pubmedRecognizer;
  late final TapGestureRecognizer _whoRecognizer;

  @override
  void initState() {
    super.initState();
    _pubmedRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(_pubmedUrl), mode: LaunchMode.externalApplication);
    _whoRecognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(Uri.parse(_whoUrl), mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _pubmedRecognizer.dispose();
    _whoRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    final citationText = isRu
        ? 'Расчёт калорий основан на формуле Mifflin-St Jeor (Mifflin MD et al., The American Journal of Clinical Nutrition, 1990). Коэффициенты активности — ВОЗ/ФАО. Нормы макронутриентов — по рекомендациям ВОЗ.'
        : 'Calorie calculation is based on the Mifflin-St Jeor formula (Mifflin MD et al., The American Journal of Clinical Nutrition, 1990). Activity coefficients from WHO/FAO. Macronutrient ranges per WHO dietary guidelines.';
    final pubmedLabel = isRu ? 'PubMed' : 'PubMed';
    final whoLabel = isRu ? 'Рекомендации ВОЗ' : 'WHO Guidelines';
    final disclaimerText = isRu
        ? '\n\nЭто информационный расчёт. Проконсультируйтесь с врачом перед изменением рациона.'
        : '\n\nThis is an informational estimate. Consult a healthcare professional before changing your diet.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: '$citationText\n'),
                  TextSpan(
                    text: pubmedLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _pubmedRecognizer,
                  ),
                  const TextSpan(text: '  ·  '),
                  TextSpan(
                    text: whoLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3B82F6),
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _whoRecognizer,
                  ),
                  TextSpan(text: disclaimerText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weight forecast chart ────────────────────────────────────────────────────

class _WeightChart extends StatelessWidget {
  final CalculationResult calc;
  final AppLocalizations l10n;
  final _GoalMode mode;

  const _WeightChart({
    required this.calc,
    required this.l10n,
    required this.mode,
  });

  List<FlSpot> _buildSpots() {
    const steps = 6;
    final cw = calc.currentWeight;
    final tw = calc.targetWeight;

    if (mode == _GoalMode.gain) {
      // startW = current weight (e.g. 77), endW = target weight (e.g. 80)
      final startW = cw ?? (tw != null ? tw - 3.0 : 70.0);
      final endW = tw ?? (startW + 5.0);
      final kgGain = (endW - startW).abs().clamp(0.5, 50.0);
      final projDays = calc.daysToGoal?.toDouble() ??
          (kgGain * 7700 / 400).clamp(30.0, 365.0);
      return List.generate(steps + 1, (i) {
        final t = i / steps;
        return FlSpot(projDays * t, startW + kgGain * t);
      });
    }

    if (mode == _GoalMode.maintain) {
      final w = cw ?? tw ?? 70.0;
      return [
        FlSpot(0, w),
        FlSpot(30, w),
        FlSpot(60, w),
        FlSpot(90, w),
      ];
    }

    // Lose — build from actual weights, ignore backend chartData
    final startW = cw ?? (tw != null ? tw + 5.0 : null);
    final endW = tw;
    if (startW != null && endW != null) {
      final kgLoss = (startW - endW).abs().clamp(0.5, 50.0);
      final projDays = calc.daysToGoal?.toDouble() ??
          (kgLoss * 7700 / (calc.tdee - calc.targetCalories).clamp(100.0, 1000.0))
              .clamp(30.0, 365.0);
      return List.generate(steps + 1, (i) {
        final t = i / steps;
        return FlSpot(projDays * t, startW - kgLoss * t);
      });
    }

    // Last resort: backend chartData
    if (calc.chartData != null && (calc.chartData as List).isNotEmpty) {
      final spots = <FlSpot>[];
      for (final item in calc.chartData as List) {
        if (item is Map) {
          final day = (item['day'] as num?)?.toDouble();
          final weight = (item['weight'] as num?)?.toDouble();
          if (day != null && weight != null) spots.add(FlSpot(day, weight));
        }
      }
      if (spots.isNotEmpty) return spots;
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();
    if (spots.isEmpty) return const SizedBox.shrink();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPad = (maxY - minY).clamp(0.5, double.infinity) * 0.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              switch (mode) {
                _GoalMode.gain => l10n.wg_weight_forecast_gain,
                _GoalMode.maintain => l10n.wg_weight_forecast_maintain,
                _ => l10n.wg_weight_forecast,
              },
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
            ),
          ),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY - yPad,
                maxY: maxY + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, meta) {
                        final day = v.toInt();
                        if (day == 0) {
                          return Text(l10n.wg_now,
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textMuted));
                        }
                        final maxDay = spots.last.x.toInt();
                        if (day == maxDay) {
                          return Text('${day}d',
                              style: const TextStyle(
                                  fontSize: 9, color: AppColors.textMuted));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: OBColors.pink,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) =>
                          spot.x == spots.first.x || spot.x == spots.last.x,
                      getDotPainter: (a, b, c, d) => FlDotCirclePainter(
                        radius: 4,
                        color: OBColors.pink,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          OBColors.pink.withValues(alpha: 0.2),
                          OBColors.pink.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
