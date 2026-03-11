import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stats_card.dart';
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

