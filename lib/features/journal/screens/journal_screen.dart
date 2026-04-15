import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../widgets/meal_item.dart';
import '../widgets/day_summary_card.dart';
import '../widgets/meal_group_card.dart';
import '../../add_meal/screens/add_meal_sheet.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/meal.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../way_to_goal/providers/way_to_goal_provider.dart';

part 'journal_screen.g.dart';

@riverpod
Future<List<Meal>> journalDayMeals(JournalDayMealsRef ref, String date) async {
  final resp = await apiDio.get('/api/meals/history', queryParameters: {'limit': 500});
  final list = resp.data as List<dynamic>;
  final all = list.map((e) {
    final map = Map<String, dynamic>.from(e as Map);
    if (!map.containsKey('createdAt') && map.containsKey('time')) {
      map['createdAt'] = map['time'];
    }
    return Meal.fromJson(map);
  }).toList();
  return all.where((m) {
    final raw = m.createdAt;
    if (raw == null) return false;
    final mDate = DateTime.tryParse(raw)?.toLocal();
    if (mDate == null) return false;
    final dayStr = '${mDate.year.toString().padLeft(4, '0')}-'
        '${mDate.month.toString().padLeft(2, '0')}-'
        '${mDate.day.toString().padLeft(2, '0')}';
    return dayStr == date;
  }).toList();
}

// ---------------------------------------------------------------------------
// JournalScreen
// ---------------------------------------------------------------------------

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = _today();
  // Tracks whether the last navigation was forward (true) or backward (false)
  bool _navigatedForward = false;

  // Chevron button scale controllers
  late final AnimationController _leftChevCtrl;
  late final AnimationController _rightChevCtrl;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday => _selectedDate == _today();

  @override
  void initState() {
    super.initState();
    AnalyticsService.journalOpened();
    _leftChevCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
    _rightChevCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.85,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _leftChevCtrl.dispose();
    _rightChevCtrl.dispose();
    super.dispose();
  }

  void _prevDay() {
    AnalyticsService.journalDateChanged('prev');
    _leftChevCtrl.reverse().then((_) => _leftChevCtrl.forward());
    setState(() {
      _navigatedForward = false;
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    if (_isToday) return;
    AnalyticsService.journalDateChanged('next');
    _rightChevCtrl.reverse().then((_) => _rightChevCtrl.forward());
    setState(() {
      _navigatedForward = true;
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _goToDate(DateTime date) {
    if (date == _selectedDate) return;
    AnalyticsService.journalDaySelected(date.toIso8601String().substring(0, 10));
    setState(() {
      _navigatedForward = date.isAfter(_selectedDate);
      _selectedDate = date;
    });
  }

  Future<void> _deleteMeal(BuildContext context, int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.journal_delete_title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18)),
        content: Text(l10n.journal_delete_body,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.common_delete,
                style: const TextStyle(
                    color: AppColors.accentOver,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await apiDio.delete('/api/meals/$id');
      ref.invalidate(journalDayMealsProvider(_dateKey));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.accentOver,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showAddMeal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _isToday
          ? const AddMealSheet()
          : AddMealSheet(mealDate: _selectedDate),
    );
    ref.invalidate(journalDayMealsProvider(_dateKey));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final meals = ref.watch(journalDayMealsProvider(_dateKey));

    final dateLabel = _isToday
        ? l10n.dashboard_title
        : DateFormat('d MMMM', locale).format(_selectedDate);

    return Scaffold(
      backgroundColor: NutrientColors.bg,
      appBar: AppBar(
        backgroundColor: NutrientColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Text(
              l10n.journal_title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AnalyticsService.journalAddMealTapped();
          _showAddMeal(context);
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.dashboard_addMeal),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      body: Column(
        children: [
          // ── Week strip ────────────────────────────────────────────────
          _WeekStrip(
            selectedDate: _selectedDate,
            today: _today(),
            onDateTap: _goToDate,
          ),

          // ── Date navigation bar ───────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left chevron with bounce
                ScaleTransition(
                  scale: _leftChevCtrl,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevDay,
                    color: AppColors.text,
                  ),
                ),

                // Animated date label — slides based on direction
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) {
                    final inFromRight = child.key == ValueKey(_dateKey);
                    final beginOffset = inFromRight
                        ? (_navigatedForward
                            ? const Offset(0.3, 0)
                            : const Offset(-0.3, 0))
                        : (_navigatedForward
                            ? const Offset(-0.3, 0)
                            : const Offset(0.3, 0));
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: beginOffset,
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: Text(
                    dateLabel,
                    key: ValueKey(_dateKey),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),

                // Right chevron with bounce
                ScaleTransition(
                  scale: _rightChevCtrl,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _isToday ? null : _nextDay,
                    color: _isToday ? AppColors.border : AppColors.text,
                  ),
                ),
              ],
            ),
          ),

          // ── Meals content ─────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_dateKey),
                child: meals.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Column(
                      children: [
                        _AiNutritionistBanner(onTap: () {
                          AnalyticsService.journalAiBannerTapped();
                          context.go('/chat');
                        }),
                        Expanded(
                          child: Center(
                            child: Text(l10n.journal_empty,
                                style: const TextStyle(
                                    color: AppColors.textMuted)),
                          ),
                        ),
                      ],
                    );
                  }
                  final calcAsync = ref.watch(calculationResultProvider);
                  final calGoal = calcAsync.valueOrNull?.targetCalories ?? 2000.0;
                  final proteinGoal = calcAsync.valueOrNull?.protein ?? 130.0;
                  final fatGoal = calcAsync.valueOrNull?.fat ?? 67.0;
                  final carbsGoal = calcAsync.valueOrNull?.carbs ?? 200.0;

                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async =>
                        ref.invalidate(journalDayMealsProvider(_dateKey)),
                    child: _MealGroupedList(
                      meals: list,
                      calGoal: calGoal,
                      proteinGoal: proteinGoal,
                      fatGoal: fatGoal,
                      carbsGoal: carbsGoal,
                      onDeleteMeal: (id) => _deleteMeal(context, id),
                      onEditMeal: (id) => context.push('/meals/$id/edit'),
                      onChatTap: () {
                        AnalyticsService.journalAiBannerTapped();
                        context.go('/chat');
                      },
                    ),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Center(child: Text('$e')),
              ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WeekStrip — 7-day horizontal scrollable strip
// ---------------------------------------------------------------------------

class _WeekStrip extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateTap;

  const _WeekStrip({
    required this.selectedDate,
    required this.today,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    // Build a 7-day window ending on today
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSelected = day == selectedDate;
          final isToday = day == today;
          final dayName = DateFormat('E', locale)
              .format(day)
              .substring(0, 1)
              .toUpperCase();
          final dayNum = day.day.toString();

          return GestureDetector(
            onTap: () => onDateTap(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 42,
              height: 62,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : isToday
                        ? AppColors.accentSoft
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : isToday
                              ? AppColors.accent
                              : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    dayNum,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.accent
                              : AppColors.text,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AiNutritionistBanner
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// _MealGroupedList — groups meals by mealType and shows day summary + groups
// ---------------------------------------------------------------------------

class _MealGroupedList extends StatelessWidget {
  final List<Meal> meals;
  final double calGoal;
  final double proteinGoal;
  final double fatGoal;
  final double carbsGoal;
  final void Function(int id) onDeleteMeal;
  final void Function(int id) onEditMeal;
  final VoidCallback onChatTap;

  const _MealGroupedList({
    required this.meals,
    required this.calGoal,
    required this.proteinGoal,
    required this.fatGoal,
    required this.carbsGoal,
    required this.onDeleteMeal,
    required this.onEditMeal,
    required this.onChatTap,
  });

  String _inferMealType(Meal m) {
    if (m.mealType != null && m.mealType!.isNotEmpty) return m.mealType!;
    final raw = m.createdAt;
    if (raw == null) return 'snack';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return 'snack';
    if (dt.hour < 11) return 'breakfast';
    if (dt.hour < 15) return 'lunch';
    if (dt.hour < 18) return 'snack';
    return 'dinner';
  }

  String _timeStr(Meal m) {
    final raw = m.createdAt;
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Group by meal type
    final groups = <String, List<Meal>>{};
    for (final m in meals) {
      final type = _inferMealType(m);
      groups.putIfAbsent(type, () => []).add(m);
    }

    // Compute day totals
    final totalCal = meals.fold<double>(0, (s, m) => s + m.calories);
    final totalProtein = meals.fold<double>(0, (s, m) => s + m.protein);
    final totalFat = meals.fold<double>(0, (s, m) => s + m.fat);
    final totalNetCarbs = meals.fold<double>(0, (s, m) => s + (m.netCarbs ?? m.carbs));
    final totalSugar = meals.fold<double>(0, (s, m) => s + (m.sugar ?? 0));
    final totalFiber = meals.fold<double>(0, (s, m) => s + (m.fiber ?? 0));
    final totalSatFat = meals.fold<double>(0, (s, m) => s + (m.saturatedFat ?? 0));
    final totalUnsatFat = meals.fold<double>(0, (s, m) => s + (m.unsaturatedFat ?? 0));

    // Order: breakfast, lunch, snack, dinner
    const order = ['breakfast', 'lunch', 'snack', 'dinner'];

    return ListView(
      padding: const EdgeInsets.only(top: 0, bottom: 100),
      children: [
        _AiNutritionistBanner(onTap: onChatTap),

        // Day summary
        DaySummaryCard(
          netCarbs: totalNetCarbs, netCarbsGoal: carbsGoal,
          sugar: totalSugar, sugarGoal: 50,
          fiber: totalFiber, fiberGoal: 25,
          protein: totalProtein, proteinGoal: proteinGoal,
          goodFat: totalUnsatFat, goodFatGoal: fatGoal * 0.7,
          satFat: totalSatFat, satFatGoal: fatGoal * 0.3,
          calories: totalCal, caloriesGoal: calGoal,
        ),

        // Meal groups
        ...order.where((t) => groups.containsKey(t)).map((type) {
          final groupMeals = groups[type]!;
          final firstTime = _timeStr(groupMeals.first);
          return MealGroupCard(
            mealType: type,
            time: firstTime,
            meals: groupMeals,
            onDeleteMeal: onDeleteMeal,
            onEditMeal: onEditMeal,
          );
        }),

        // Ungrouped meals (fallback for meals without mealType)
        ...groups.entries
            .where((e) => !order.contains(e.key))
            .map((e) => MealGroupCard(
                  mealType: e.key,
                  time: _timeStr(e.value.first),
                  meals: e.value,
                  onDeleteMeal: onDeleteMeal,
                  onEditMeal: onEditMeal,
                )),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _AiNutritionistBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _AiNutritionistBanner({required this.onTap});

  @override
  State<_AiNutritionistBanner> createState() => _AiNutritionistBannerState();
}

class _AiNutritionistBannerState extends State<_AiNutritionistBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14532D), Color(0xFF16A34A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value;
                  return Positioned(
                    right: -20 + 8 * math.sin(t * 2 * math.pi),
                    top: -20 + 6 * math.cos(t * 2 * math.pi),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 30,
                bottom: -15,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.journal_ai_banner_title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.journal_ai_banner_sub,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.journal_ai_banner_btn,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
