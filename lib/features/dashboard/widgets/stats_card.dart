import 'package:flutter/material.dart';
import '../../../shared/models/stats.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';

class StatsCard extends StatelessWidget {
  final MacroStats stats;
  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calRatio = stats.caloriesGoal > 0 ? stats.caloriesEaten / stats.caloriesGoal : 0.0;
    final isOver = calRatio > 1.0;
    final remaining = (stats.caloriesGoal - stats.caloriesEaten).abs();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md,
      ),
      child: Column(
        children: [
          // Calories section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOver
                    ? [const Color(0xFFFEF2F2), const Color(0xFFFFE4E4)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.macro_calories,
                        style: TextStyle(
                          color: isOver
                              ? AppColors.accentOver.withValues(alpha:0.7)
                              : AppColors.accent.withValues(alpha:0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stats.caloriesEaten.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: isOver ? AppColors.accentOver : AppColors.text,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 6),
                            child: Text(
                              '/ ${stats.caloriesGoal.toStringAsFixed(0)} ${l10n.macro_kcal}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isOver
                            ? AppColors.accentOver.withValues(alpha:0.1)
                            : AppColors.accent.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Column(
                        children: [
                          Text(
                            remaining.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isOver ? AppColors.accentOver : AppColors.accent,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isOver ? 'перебор' : l10n.macro_remaining,
                            style: TextStyle(
                              fontSize: 11,
                              color: isOver ? AppColors.accentOver : AppColors.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar
          ClipRRect(
            child: LinearProgressIndicator(
              value: calRatio.clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              color: isOver ? AppColors.accentOver : AppColors.accent,
              minHeight: 4,
            ),
          ),
          // Macros section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MacroItem(
                  label: l10n.macro_protein,
                  eaten: stats.proteinEaten,
                  goal: stats.proteinGoal,
                  color: AppColors.accent,
                  softColor: AppColors.accentSoft,
                  unit: l10n.macro_g,
                ),
                const _Divider(),
                _MacroItem(
                  label: l10n.macro_fat,
                  eaten: stats.fatEaten,
                  goal: stats.fatGoal,
                  color: AppColors.warm,
                  softColor: AppColors.warmSoft,
                  unit: l10n.macro_g,
                ),
                const _Divider(),
                _MacroItem(
                  label: l10n.macro_carbs,
                  eaten: stats.carbsEaten,
                  goal: stats.carbsGoal,
                  color: AppColors.support,
                  softColor: AppColors.supportSoft,
                  unit: l10n.macro_g,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border, margin: const EdgeInsets.symmetric(horizontal: 8));
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final double eaten;
  final double goal;
  final Color color;
  final Color softColor;
  final String unit;

  const _MacroItem({
    required this.label,
    required this.eaten,
    required this.goal,
    required this.color,
    required this.softColor,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                eaten.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: color,
                  height: 1,
                ),
              ),
              Text(
                '/${goal.toStringAsFixed(0)}$unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: softColor,
              color: color,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
