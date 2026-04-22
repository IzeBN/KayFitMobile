import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:kayfit/core/notifications/notification_service.dart';
import 'package:kayfit/core/review/app_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/ai_consent/ai_consent_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stats_card.dart';
import '../../journal/widgets/meal_group_card.dart';
import '../../add_meal/screens/add_meal_sheet.dart';
import '../../../shared/utils/meal_grouping.dart';
import '../../way_to_goal/providers/way_to_goal_provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/meal.dart';

// SharedPreferences key tracking how many times way-to-goal was opened
const _kWayToGoalOpenedKey = 'way_to_goal_opened_count';

// ---------------------------------------------------------------------------
// DashboardScreen — ConsumerStatefulWidget for animation + side-effects
// ---------------------------------------------------------------------------

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  // Stagger animation controller for sliver list items
  late final AnimationController _listCtrl;
  // Stats card slide-from-top + fade
  late final AnimationController _statsCtrl;
  // FAB pulse when meals empty
  late final AnimationController _fabPulseCtrl;

  // Tracks whether stats have already been animated in
  bool _statsAnimated = false;

  @override
  void initState() {
    super.initState();

    _listCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // _listCtrl is triggered via ref.listen in build() once data arrives,
    // so that groups are actually visible when the animation runs.

    AnalyticsService.dashboardOpened();

    // Deferred side-effects after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowNotificationPromo();
      _maybeCheckDayStreakReview();
    });
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _statsCtrl.dispose();
    _fabPulseCtrl.dispose();
    super.dispose();
  }

  // ── Side-effect helpers ───────────────────────────────────────────────────

  Future<void> _maybeShowNotificationPromo() async {
    if (!mounted) return;
    final already = await NotificationService.wasPermissionRequested();
    if (already) return;
    if (!mounted) return;
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      await NotificationService.showPromoAndRequest(context);
    } catch (_) {}
  }

  Future<void> _maybeCheckDayStreakReview() async {
    final first = await AppReviewService.firstLaunchDate();
    if (first == null) return;
    final daysSince = DateTime.now().difference(first).inDays;
    if (daysSince >= 7) {
      await AppReviewService.markPositiveMoment();
    }
  }

  Future<void> _onWayToGoalTap(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_kWayToGoalOpenedKey) ?? 0) + 1;
    await prefs.setInt(_kWayToGoalOpenedKey, count);
    if (!context.mounted) return;
    context.push('/way-to-goal');
    if (count == 2) {
      await AppReviewService.markPositiveMoment();
    }
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
    // Block if AI consent was declined
    final consent = ref.read(aiConsentProvider);
    if (consent == false) {
      final isRu = Localizations.localeOf(context).languageCode == 'ru';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isRu
            ? 'Добавление блюд недоступно: вы отклонили использование ИИ'
            : 'Meal adding is unavailable: AI consent was declined'),
        backgroundColor: AppColors.accentOver,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMealSheet(),
    );
    ref.invalidate(todayMealsProvider);
    ref.invalidate(todayStatsProvider);

    // Check if user has logged 5th meal — review trigger
    final meals = ref.read(todayMealsProvider).valueOrNull;
    if (meals != null && meals.length >= 5) {
      await AppReviewService.markPositiveMoment();
    }
  }

  // ── Animation helpers ─────────────────────────────────────────────────────

  Animation<double> _fadeFor(int index) => Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(
        parent: _listCtrl,
        curve: Interval(
          (index * 0.1).clamp(0.0, 0.7),
          ((index * 0.1) + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ));

  Animation<Offset> _slideFor(int index) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _listCtrl,
          curve: Interval(
            (index * 0.1).clamp(0.0, 0.7),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );

  // Animate stats card once data is available
  void _animateStatsIfNeeded() {
    if (!_statsAnimated) {
      _statsAnimated = true;
      _statsCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(todayStatsProvider);
    final meals = ref.watch(todayMealsProvider);
    final calc = ref.watch(calculationResultProvider);

    // Trigger stagger animation when meal data first arrives so groups are
    // already in the tree when the animation plays.
    ref.listen<AsyncValue<List<Meal>>>(todayMealsProvider, (previous, next) {
      if (next.hasValue && _listCtrl.status != AnimationStatus.completed) {
        _listCtrl.forward(from: 0);
      }
    });

    final hasMeals = meals.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          AnalyticsService.dashboardRefreshed();
          ref.invalidate(todayStatsProvider);
          ref.invalidate(todayMealsProvider);
          ref.invalidate(calculationResultProvider);
        },
        child: CustomScrollView(
          slivers: [
            _DashboardAppBar(l10n: l10n),

            // ── Stats card (animated from top) ────────────────────────────
            SliverToBoxAdapter(
              child: stats.when(
                data: (s) {
                  if (s.caloriesGoal > 0) {
                    _animateStatsIfNeeded();
                    return AnimatedBuilder(
                      animation: _statsCtrl,
                      builder: (context, child) => FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _statsCtrl,
                          curve: Curves.easeOutCubic,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, -0.2),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _statsCtrl,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      ),
                      child: StatsCard(stats: s, meals: meals.valueOrNull),
                    );
                  }
                  if (calc.valueOrNull != null) return const SizedBox.shrink();
                  return _AnimatedListItem(
                    fade: _fadeFor(0),
                    slide: _slideFor(0),
                    child: _NoGoalsBanner(l10n: l10n),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: LoadingIndicator(),
                ),
                error: (e, _) {
                  if (calc.valueOrNull != null) return const SizedBox.shrink();
                  return _AnimatedListItem(
                    fade: _fadeFor(0),
                    slide: _slideFor(0),
                    child: _NoGoalsBanner(l10n: l10n),
                  );
                },
              ),
            ),

            // ── Personal plan card ────────────────────────────────────────
            if (calc.valueOrNull != null)
              SliverToBoxAdapter(
                child: _AnimatedListItem(
                  fade: _fadeFor(1),
                  slide: _slideFor(1),
                  child: _PersonalPlanCard(
                    l10n: l10n,
                    kcal: calc.valueOrNull!.targetCalories.toInt(),
                    onTap: () {
                      AnalyticsService.dashboardPersonalPlanTapped();
                      _onWayToGoalTap(context);
                    },
                  ),
                ),
              ),

            // ── Section title ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AnimatedListItem(
                fade: _fadeFor(2),
                slide: _slideFor(2),
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
            ),

            // ── Meals list (grouped by meal type) ────────────────────────
            meals.when(
              data: (list) {
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _AnimatedListItem(
                      fade: _fadeFor(3),
                      slide: _slideFor(3),
                      child: _FloatingEmptyMeals(l10n: l10n),
                    ),
                  );
                }
                final groups = list.grouped();
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final (group, items) = groups[index];
                      return _AnimatedListItem(
                        fade: _fadeFor(index + 3),
                        slide: _slideFor(index + 3),
                        child: MealGroupCard(
                          mealType: group.apiKey,
                          time: '',
                          meals: items,
                          onDeleteMeal: (id) =>
                              _deleteMeal(context, ref, id),
                          onEditMeal: (id) =>
                              context.push('/meals/$id/edit'),
                        ),
                      );
                    },
                    childCount: groups.length,
                  ),
                );
              },
              loading: () =>
                  const SliverToBoxAdapter(child: LoadingIndicator()),
              error: (e, _) => SliverToBoxAdapter(
                child: _AnimatedListItem(
                  fade: _fadeFor(3),
                  slide: _slideFor(3),
                  child: _FloatingEmptyMeals(l10n: l10n),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: _PulseButton(
        controller: _fabPulseCtrl,
        pulse: !hasMeals,
        child: FloatingActionButton.extended(
          onPressed: () {
            AnalyticsService.dashboardAddMealTapped();
            _showAddMeal(context, ref);
          },
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.dashboard_addMeal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AnimatedListItem — fade + slide wrapper for stagger
// ---------------------------------------------------------------------------

class _AnimatedListItem extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  const _AnimatedListItem({
    required this.fade,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// _PulseButton — wraps FAB with a pulse scale when empty
// ---------------------------------------------------------------------------

class _PulseButton extends StatelessWidget {
  final AnimationController controller;
  final bool pulse;
  final Widget child;

  const _PulseButton({
    required this.controller,
    required this.pulse,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!pulse) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, c) {
        final scale = 1.0 + 0.03 * math.sin(controller.value * math.pi);
        return Transform.scale(scale: scale, child: c);
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// _DashboardAppBar
// ---------------------------------------------------------------------------

class _DashboardAppBar extends StatelessWidget {
  final AppLocalizations l10n;
  const _DashboardAppBar({required this.l10n});

  String _greeting(String lang) {
    final h = DateTime.now().hour;
    if (lang == 'ru') {
      if (h < 12) return 'Доброе утро ☀️';
      if (h < 18) return 'Добрый день 🌤';
      return 'Добрый вечер 🌙';
    }
    if (h < 12) return 'Good morning ☀️';
    if (h < 18) return 'Good afternoon 🌤';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).languageCode;
    final dateStr = DateFormat('d MMMM, EEEE', locale).format(now);
    final greeting = _greeting(locale);

    return SliverAppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FloatingEmptyMeals — empty state with floating icon animation
// ---------------------------------------------------------------------------

class _FloatingEmptyMeals extends StatefulWidget {
  final AppLocalizations l10n;
  const _FloatingEmptyMeals({required this.l10n});

  @override
  State<_FloatingEmptyMeals> createState() => _FloatingEmptyMealsState();
}

class _FloatingEmptyMealsState extends State<_FloatingEmptyMeals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (context, child) {
              final offset = 4.0 * math.sin(_floatCtrl.value * math.pi);
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                color: AppColors.accent,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.l10n.dashboard_noMeals,
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

// ---------------------------------------------------------------------------
// _PersonalPlanCard — with tap micro-interaction
// ---------------------------------------------------------------------------

class _PersonalPlanCard extends StatefulWidget {
  final AppLocalizations l10n;
  final int kcal;
  final VoidCallback onTap;

  const _PersonalPlanCard({
    required this.l10n,
    required this.kcal,
    required this.onTap,
  });

  @override
  State<_PersonalPlanCard> createState() => _PersonalPlanCardState();
}

class _PersonalPlanCardState extends State<_PersonalPlanCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _scale, end: _scale),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
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
                      widget.l10n.dashboard_personal_plan_title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      widget.l10n.dashboard_personal_plan_sub(widget.kcal),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NoGoalsBanner
// ---------------------------------------------------------------------------

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
            child: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboard_no_goals_title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.dashboard_no_goals_sub,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
