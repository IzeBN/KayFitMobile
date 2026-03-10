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

    // Backend returns nested: {calories: {current, goal}, protein: {current, goal}, ...}
    double cur(String key) {
      final m = data[key];
      if (m is Map) return (m['current'] as num?)?.toDouble() ?? 0;
      return (data['${key}_eaten'] as num?)?.toDouble() ?? 0;
    }
    double gol(String key) {
      final m = data[key];
      if (m is Map) return (m['goal'] as num?)?.toDouble() ?? 0;
      return (data['${key}_goal'] as num?)?.toDouble() ?? 0;
    }

    return MacroStats(
      caloriesEaten: cur('calories'),
      caloriesGoal: gol('calories'),
      proteinEaten: cur('protein'),
      proteinGoal: gol('protein'),
      fatEaten: cur('fat'),
      fatGoal: gol('fat'),
      carbsEaten: cur('carbs'),
      carbsGoal: gol('carbs'),
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
