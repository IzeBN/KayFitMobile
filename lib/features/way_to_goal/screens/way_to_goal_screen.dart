import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/way_to_goal_provider.dart';

class WayToGoalScreen extends ConsumerWidget {
  const WayToGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Clear the redirect flag so the router doesn't keep sending the user here
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(showWayToGoalProvider)) {
        ref.read(showWayToGoalProvider.notifier).state = false;
      }
    });

    final result = ref.watch(calculationResultProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: OBColors.bg,
      body: result.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(calculationResultProvider),
          l10n: l10n,
        ),
        data: (calc) => _ResultView(calc: calc, l10n: l10n),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final dynamic calc;
  final AppLocalizations l10n;
  const _ResultView({required this.calc, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          const SizedBox(height: 24),
          // Hero gradient card
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
                const Text(
                  '🎯',
                  style: TextStyle(fontSize: 40),
                ),
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
                  l10n.wg_personal_calc,
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
                        '${calc.targetCalories.toStringAsFixed(0)}',
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

          // Macros card
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
                    _MacroChip(label: l10n.macro_protein, value: calc.protein, color: AppColors.accent, bgColor: AppColors.accentSoft),
                    const SizedBox(width: 8),
                    _MacroChip(label: l10n.macro_fat, value: calc.fat, color: AppColors.warm, bgColor: AppColors.warmSoft),
                    const SizedBox(width: 8),
                    _MacroChip(label: l10n.macro_carbs, value: calc.carbs, color: AppColors.support, bgColor: AppColors.supportSoft),
                  ],
                ),
              ],
            ),
          ),

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
                      text: l10n.wg_target_weight_val((calc.targetWeight as double).toStringAsFixed(1)),
                    ),
                ],
              ),
            ),
          ],

          // Weight progress chart (always attempt — widget hides itself if no data)
          const SizedBox(height: 12),
          _WeightChart(calc: calc, l10n: l10n),

          const SizedBox(height: 12),

          // How it works card
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 14),
                _FeatureRow(emoji: '📸', title: l10n.wg_feature_photo_title, desc: l10n.wg_feature_photo_desc),
                const SizedBox(height: 12),
                _FeatureRow(emoji: '🎤', title: l10n.wg_feature_voice_title, desc: l10n.wg_feature_voice_desc),
                const SizedBox(height: 12),
                _FeatureRow(emoji: '📊', title: l10n.wg_feature_track_title, desc: l10n.wg_feature_track_desc),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // CTA button
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: OBColors.gradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: OBColors.buttonShadow,
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.wg_start_diary,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color bgColor;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
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
              '${value.toStringAsFixed(0)}г',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

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
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

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

class _WeightChart extends StatelessWidget {
  final dynamic calc;
  final AppLocalizations l10n;
  const _WeightChart({required this.calc, required this.l10n});

  List<FlSpot> _buildSpots() {
    // If API provides chartData, use it: [{day, weight}]
    if (calc.chartData != null && (calc.chartData as List).isNotEmpty) {
      final list = calc.chartData as List;
      final spots = <FlSpot>[];
      for (final item in list) {
        if (item is Map) {
          final day = (item['day'] as num?)?.toDouble();
          final weight = (item['weight'] as num?)?.toDouble();
          if (day != null && weight != null) {
            spots.add(FlSpot(day, weight));
          }
        }
      }
      if (spots.isNotEmpty) return spots;
    }

    final targetW = calc.targetWeight as double?;
    final deficit = (calc.tdee as double) - (calc.targetCalories as double);

    // If we have daysToGoal and targetWeight, do a precise projection
    if (calc.daysToGoal != null && targetW != null) {
      final days = (calc.daysToGoal as int).toDouble();
      final totalKgLoss = deficit > 0 ? (deficit * days / 7700.0) : 0.0;
      final startW = targetW + totalKgLoss;
      const steps = 6;
      final spots = <FlSpot>[];
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        spots.add(FlSpot(days * t, startW - totalKgLoss * t));
      }
      return spots;
    }

    // Fallback: estimate projection from targetWeight alone
    if (targetW != null && deficit > 0) {
      const projDays = 90.0;
      final totalKgLoss = deficit * projDays / 7700.0;
      final startW = targetW + totalKgLoss;
      const steps = 6;
      final spots = <FlSpot>[];
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        spots.add(FlSpot(projDays * t, startW - totalKgLoss * t));
      }
      return spots;
    }

    // No weight data available — hide chart
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
              l10n.wg_weight_forecast,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
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
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, meta) => Text(
                        v.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (v, meta) {
                        final day = v.toInt();
                        if (day == 0) return Text(l10n.wg_now, style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
                        final maxDay = spots.last.x.toInt();
                        if (day == maxDay) {
                          return Text('${day}d', style: const TextStyle(fontSize: 9, color: AppColors.textMuted));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final AppLocalizations l10n;
  const _ErrorView({required this.message, required this.onRetry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.accentOver),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: OBColors.gradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(l10n.common_retry, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
