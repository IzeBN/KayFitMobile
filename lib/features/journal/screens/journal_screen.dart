import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../widgets/meal_item.dart';
import '../../add_meal/screens/add_meal_sheet.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/models/meal.dart';
import '../../../core/api/api_client.dart';

part 'journal_screen.g.dart';

@riverpod
Future<List<Meal>> journalDayMeals(JournalDayMealsRef ref, String date) async {
  final resp = await apiDio.get('/api/meals/history', queryParameters: {'limit': 500});
  final list = resp.data as List<dynamic>;
  // API returns "time" field; remap to "createdAt" expected by Meal.fromJson
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

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  DateTime _selectedDate = _today();

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

  void _prevDay() =>
      setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));

  void _nextDay() {
    if (_isToday) return;
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _deleteMeal(BuildContext context, int id) async {
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
        ? l10n.dashboard_title // "Сегодня"
        : DateFormat('d MMMM', locale).format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(l10n.journal_title),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMeal(context),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.dashboard_addMeal),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      body: Column(
        children: [
          // Date navigation bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _prevDay,
                  color: AppColors.text,
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _isToday ? null : _nextDay,
                  color: _isToday ? AppColors.border : AppColors.text,
                ),
              ],
            ),
          ),
          Expanded(
            child: meals.when(
              data: (list) {
                if (list.isEmpty) {
                  return Column(
                    children: [
                      _AiNutritionistBanner(onTap: () => context.go('/chat')),
                      Expanded(
                        child: Center(
                          child: Text(l10n.journal_empty,
                              style: const TextStyle(color: AppColors.textMuted)),
                        ),
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () async =>
                      ref.invalidate(journalDayMealsProvider(_dateKey)),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: list.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        return _AiNutritionistBanner(
                            onTap: () => context.go('/chat'));
                      }
                      final meal = list[i - 1];
                      return MealItem(
                        meal: meal,
                        onDelete: () => _deleteMeal(ctx, meal.id),
                        onEdit: () => context.push('/meals/${meal.id}/edit'),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Nutritionist Banner ───────────────────────────────────────────────────

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
              // Animated decorative circles in background
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
              // Content
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
