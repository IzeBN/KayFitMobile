import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/onboarding_pending_storage.dart';
import '../../../core/storage/user_goal_storage.dart';
import '../../../shared/models/calculation_result.dart';

part 'way_to_goal_provider.g.dart';

const _cacheKey = 'calculation_result_cache';

/// Increment this to force calculationResultProvider to re-fetch.
/// Called from onboarding after goals/weights are saved.
final goalRevisionProvider = StateProvider<int>((ref) => 0);

@riverpod
Future<List<String>> onboardingGoals(OnboardingGoalsRef ref) async {
  final goal = await UserGoalStorage.read();
  if (goal != null && goal.goals.isNotEmpty) return goal.goals;
  final pending = await OnboardingPendingStorage.read();
  return pending?.goals ?? const [];
}

@riverpod
Future<double?> onboardingCurrentWeight(OnboardingCurrentWeightRef ref) async {
  final goal = await UserGoalStorage.read();
  if (goal?.currentWeight != null) return goal!.currentWeight;
  final pending = await OnboardingPendingStorage.read();
  return pending?.weight;
}

// ── Cache ────────────────────────────────────────────────────────────────────

Future<void> _saveCache(CalculationResult result) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
  } catch (e) {
    debugPrint('[way_to_goal] cache save failed: $e');
  }
}

Future<CalculationResult?> _loadCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    return CalculationResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('[way_to_goal] cache load failed: $e');
    return null;
  }
}

// ── Goal overrides ───────────────────────────────────────────────────────────

CalculationResult _applyGoalOverrides(
  CalculationResult raw,
  List<String> goals,
  double? currentWeight,
  double? targetWeight,
) {
  final cw = currentWeight ?? raw.currentWeight;
  final tw = targetWeight ?? raw.targetWeight;

  final isGain = goals.contains('gain_muscle') ||
      (cw != null && tw != null && tw - cw > 0.5);
  final isMaintain = !isGain &&
      (goals.contains('maintain_weight') ||
          (cw != null && tw != null && (tw - cw).abs() <= 0.5));

  debugPrint('[way_to_goal] overrides: goals=$goals cw=$cw tw=$tw '
      'isGain=$isGain isMaintain=$isMaintain');

  if (isGain) {
    const surplus = 400.0;
    final targetCals = raw.tdee + surplus;
    int? days;
    if (cw != null && tw != null && tw > cw) {
      days = ((tw - cw) * 7700 / surplus).round();
    }
    return raw.copyWith(
      targetCalories: targetCals,
      daysToGoal: days,
      currentWeight: cw,
      targetWeight: tw,
    );
  }

  if (isMaintain) {
    return raw.copyWith(
      targetCalories: raw.tdee,
      daysToGoal: null,
      currentWeight: cw,
      targetWeight: tw,
    );
  }

  return raw.copyWith(
    currentWeight: cw,
    targetWeight: tw ?? raw.targetWeight,
  );
}

// ── Reads goal context from persistent storage (survives onboarding sync) ────

Future<({List<String> goals, double? cw, double? tw})> _readGoalContext() async {
  // UserGoalStorage is the primary source — never cleared after onboarding sync
  final goal = await UserGoalStorage.read();
  if (goal != null && (goal.goals.isNotEmpty || goal.currentWeight != null)) {
    debugPrint('[way_to_goal] UserGoalStorage: goals=${goal.goals} '
        'cw=${goal.currentWeight} tw=${goal.targetWeight}');
    return (goals: goal.goals, cw: goal.currentWeight, tw: goal.targetWeight);
  }

  // Fallback: OnboardingPendingStorage (present before sync completes)
  final pending = await OnboardingPendingStorage.read();
  debugPrint('[way_to_goal] OnboardingPendingStorage: goals=${pending?.goals} '
      'cw=${pending?.weight} tw=${pending?.targetWeight}');
  return (
    goals: pending?.goals ?? const [],
    cw: pending?.weight,
    tw: pending?.targetWeight,
  );
}

// ── Main provider ────────────────────────────────────────────────────────────

@riverpod
Future<CalculationResult> calculationResult(CalculationResultRef ref) async {
  // Watch goalRevision so the provider re-runs when onboarding saves new goals
  ref.watch(goalRevisionProvider);

  final ctx = await _readGoalContext();

  CalculationResult? raw;
  double? cwFromProfile;

  // 1. Try server calculation result
  try {
    final resp = await apiDio.get('/api/calculation/result');
    if (resp.data != null) {
      raw = CalculationResult.fromJson(resp.data as Map<String, dynamic>);
    }
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    if (status != 404) {
      // Network/auth error — apply overrides to cache if available
      final cached = await _loadCache();
      if (cached != null) {
        return _applyGoalOverrides(cached, ctx.goals, ctx.cw, ctx.tw);
      }
      rethrow;
    }
  }

  // 2. Fallback: fetch profile + calculate
  if (raw == null) {
    try {
      final profileResp = await apiDio.get('/api/profile');
      final profile = profileResp.data as Map<String, dynamic>;

      if (profile['age'] == null || profile['weight'] == null ||
          profile['height'] == null || profile['training_days'] == null) {
        final cached = await _loadCache();
        if (cached != null) {
          return _applyGoalOverrides(cached, ctx.goals, ctx.cw, ctx.tw);
        }
        throw Exception('Профиль не заполнен. Пройдите онбординг повторно.');
      }

      cwFromProfile = (profile['weight'] as num?)?.toDouble();

      final calcResp = await apiDio.post('/api/calculate', data: {
        'age': profile['age'],
        'weight': profile['weight'],
        'height': profile['height'],
        'training_days': profile['training_days'],
        if (profile['deficit_mode'] != null)
          'deficit_mode': profile['deficit_mode'],
      });
      raw = CalculationResult.fromJson(calcResp.data as Map<String, dynamic>);
    } catch (e) {
      final cached = await _loadCache();
      if (cached != null) {
        return _applyGoalOverrides(cached, ctx.goals, ctx.cw, ctx.tw);
      }
      rethrow;
    }
  }

  final cw = ctx.cw ?? cwFromProfile;
  final result = _applyGoalOverrides(raw, ctx.goals, cw, ctx.tw);
  await _saveCache(result);
  return result;
}
