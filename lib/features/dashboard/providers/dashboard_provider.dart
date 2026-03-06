import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/meal.dart';
import '../../../shared/models/stats.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<MacroStats> todayStats(TodayStatsRef ref) async {
  try {
    final resp = await apiDio.get('/api/stats');
    final data = resp.data as Map<String, dynamic>;
    return MacroStats(
      caloriesEaten: (data['calories_eaten'] as num?)?.toDouble() ?? 0,
      caloriesGoal: (data['calories_goal'] as num?)?.toDouble() ?? 0,
      proteinEaten: (data['protein_eaten'] as num?)?.toDouble() ?? 0,
      proteinGoal: (data['protein_goal'] as num?)?.toDouble() ?? 0,
      fatEaten: (data['fat_eaten'] as num?)?.toDouble() ?? 0,
      fatGoal: (data['fat_goal'] as num?)?.toDouble() ?? 0,
      carbsEaten: (data['carbs_eaten'] as num?)?.toDouble() ?? 0,
      carbsGoal: (data['carbs_goal'] as num?)?.toDouble() ?? 0,
      compulsiveCount: (data['compulsive_count'] as num?)?.toInt() ?? 0,
    );
  } catch (_) {
    return const MacroStats(
      caloriesEaten: 0, caloriesGoal: 0,
      proteinEaten: 0, proteinGoal: 0,
      fatEaten: 0, fatGoal: 0,
      carbsEaten: 0, carbsGoal: 0,
    );
  }
}

@riverpod
Future<List<Meal>> todayMeals(TodayMealsRef ref) async {
  final resp = await apiDio.get('/api/meals');
  final list = resp.data as List<dynamic>;
  return list.map((e) => Meal.fromJson(e as Map<String, dynamic>)).toList();
}
