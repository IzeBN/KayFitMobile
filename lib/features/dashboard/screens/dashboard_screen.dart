import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stats_card.dart';
import '../../../shared/models/stats.dart';
import '../../journal/widgets/meal_item.dart';
import '../../add_meal/screens/add_meal_sheet.dart';
import '../../way_to_goal/providers/way_to_goal_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/api/api_client.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(todayStatsProvider);
    final meals = ref.watch(todayMealsProvider);
    final calc = ref.watch(calculationResultProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.invalidate(todayStatsProvider);
          ref.invalidate(todayMealsProvider);
          ref.invalidate(calculationResultProvider);
        },
        child: CustomScrollView(
          slivers: [
            _DashboardAppBar(l10n: l10n),
            SliverToBoxAdapter(
              child: stats.when(
                data: (s) {
                  if (s.caloriesGoal > 0) return StatsCard(stats: s);
                  // Goals may exist but stats not yet loaded — hide banner if calc data present
                  if (calc.valueOrNull != null) return const SizedBox.shrink();
                  return _NoGoalsBanner(l10n: l10n);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingIndicator(),
                ),
                error: (e, _) {
                  if (calc.valueOrNull != null) return const SizedBox.shrink();
                  return _NoGoalsBanner(l10n: l10n);
                },
              ),
            ),
            // Personal plan banner — shows whenever calculation data is available
            if (calc.valueOrNull != null)
              SliverToBoxAdapter(
                child: _PersonalPlanCard(
                  l10n: l10n,
                  kcal: calc.valueOrNull!.targetCalories.toInt(),
                  onTap: () => context.push('/way-to-goal'),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.dashboard_title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
            meals.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyMeals(l10n: l10n),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => MealItem(
                      meal: list[index],
                      onDelete: () => _deleteMeal(context, ref, list[index].id),
                      onEdit: () => context.push('/meals/${list[index].id}/edit'),
                    ),
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: LoadingIndicator()),
              error: (e, _) => SliverToBoxAdapter(child: _EmptyMeals(l10n: l10n)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeal(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.dashboard_addMeal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Future<void> _deleteMeal(BuildContext context, WidgetRef ref, int id) async {
    try {
      await apiDio.delete('/api/meals/$id');
      ref.invalidate(todayMealsProvider);
      ref.invalidate(todayStatsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accentOver,
          ),
        );
      }
    }
  }

  Future<void> _showAddMeal(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMealSheet(),
    );
    ref.invalidate(todayMealsProvider);
    ref.invalidate(todayStatsProvider);
  }
}

class _DashboardAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  const _DashboardAppBar({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat('d MMMM, EEEE', locale).format(now);

    return SliverAppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboard_title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      toolbarHeight: 70,
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyMeals({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.dashboard_noMeals,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PersonalPlanCard extends StatelessWidget {
  final AppLocalizations l10n;
  final int kcal;
  final VoidCallback onTap;
  const _PersonalPlanCard({required this.l10n, required this.kcal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: OBColors.gradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: OBColors.buttonShadow,
        ),
        child: Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboard_personal_plan_title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    l10n.dashboard_personal_plan_sub(kcal),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _RemainingCard extends StatelessWidget {
  final AppLocalizations l10n;
  final MacroStats stats;
  const _RemainingCard({required this.l10n, required this.stats});

  @override
  Widget build(BuildContext context) {
    final calEaten = stats.caloriesEaten;
    final calGoal = stats.caloriesGoal;
    final calRemaining = calGoal - calEaten;
    final isOver = calRemaining < 0;
    final calColor = isOver ? AppColors.accentOver : AppColors.accent;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isOver ? AppColors.accentOverSoft : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOver ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
                  color: calColor,
                  size: 17,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                l10n.dashboard_remaining_title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Circles row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Calories — bigger circle
              _MacroCircle(
                label: l10n.macro_calories,
                eaten: calEaten,
                goal: calGoal,
                unit: l10n.macro_kcal,
                color: calColor,
                trackColor: isOver ? AppColors.accentOverSoft : AppColors.accentSoft,
                size: 88,
                strokeWidth: 8,
                fontSize: 16,
              ),
              // Protein
              _MacroCircle(
                label: l10n.macro_protein,
                eaten: stats.proteinEaten,
                goal: stats.proteinGoal,
                unit: l10n.macro_g,
                color: AppColors.accent,
                trackColor: AppColors.accentSoft,
                size: 70,
                strokeWidth: 6,
                fontSize: 13,
              ),
              // Fat
              _MacroCircle(
                label: l10n.macro_fat,
                eaten: stats.fatEaten,
                goal: stats.fatGoal,
                unit: l10n.macro_g,
                color: AppColors.warm,
                trackColor: AppColors.warmSoft,
                size: 70,
                strokeWidth: 6,
                fontSize: 13,
              ),
              // Carbs
              _MacroCircle(
                label: l10n.macro_carbs,
                eaten: stats.carbsEaten,
                goal: stats.carbsGoal,
                unit: l10n.macro_g,
                color: AppColors.support,
                trackColor: AppColors.supportSoft,
                size: 70,
                strokeWidth: 6,
                fontSize: 13,
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Remaining summary row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isOver
                    ? '${calRemaining.abs().toStringAsFixed(0)} ${l10n.macro_kcal} ${l10n.dashboard_remaining_over}'
                    : '${calRemaining.toStringAsFixed(0)} ${l10n.macro_kcal} ${l10n.macro_remaining}',
                style: TextStyle(
                  fontSize: 12,
                  color: calColor.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroCircle extends StatelessWidget {
  final String label;
  final double eaten;
  final double goal;
  final String unit;
  final Color color;
  final Color trackColor;
  final double size;
  final double strokeWidth;
  final double fontSize;

  const _MacroCircle({
    required this.label,
    required this.eaten,
    required this.goal,
    required this.unit,
    required this.color,
    required this.trackColor,
    required this.size,
    required this.strokeWidth,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;
    final isOver = goal > 0 && eaten > goal;
    final displayColor = isOver ? AppColors.accentOver : color;
    final displayTrack = isOver ? AppColors.accentOverSoft : trackColor;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ArcPainter(
              progress: progress,
              color: displayColor,
              trackColor: displayTrack,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    eaten.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: displayColor,
                      height: 1,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: fontSize - 4,
                      color: AppColors.textMuted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          '/ ${goal.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -1.5707963; // -π/2 (top)
    const fullSweep = 6.2831853;   // 2π

    // Track (background arc)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      trackPaint,
    );

    if (progress <= 0) return;

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

class _NoGoalsBanner extends StatelessWidget {
  final AppLocalizations l10n;
  const _NoGoalsBanner({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.dashboard_no_goals_title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(l10n.dashboard_no_goals_sub,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

