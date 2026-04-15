import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's selected goals and weights independently of
/// OnboardingPendingStorage (which gets cleared after sync).
/// Never cleared — survives login/logout cycles.
class UserGoalData {
  final List<String> goals;
  final double? currentWeight;
  final double? targetWeight;

  const UserGoalData({
    this.goals = const [],
    this.currentWeight,
    this.targetWeight,
  });

  Map<String, dynamic> toJson() => {
        'goals': goals,
        if (currentWeight != null) 'current_weight': currentWeight,
        if (targetWeight != null) 'target_weight': targetWeight,
      };

  factory UserGoalData.fromJson(Map<String, dynamic> json) => UserGoalData(
        goals: (json['goals'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        currentWeight: (json['current_weight'] as num?)?.toDouble(),
        targetWeight: (json['target_weight'] as num?)?.toDouble(),
      );
}

class UserGoalStorage {
  static const _key = 'user_goal_data';

  static Future<void> save(UserGoalData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(data.toJson()));
      debugPrint('[UserGoalStorage] saved: goals=${data.goals} '
          'cw=${data.currentWeight} tw=${data.targetWeight}');
    } catch (e) {
      debugPrint('[UserGoalStorage] save failed: $e');
    }
  }

  static Future<UserGoalData?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return UserGoalData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[UserGoalStorage] read failed: $e');
      return null;
    }
  }
}
