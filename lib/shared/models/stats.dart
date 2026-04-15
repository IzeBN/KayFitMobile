import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

@freezed
class MacroStats with _$MacroStats {
  const factory MacroStats({
    required double caloriesEaten,
    required double caloriesGoal,
    required double proteinEaten,
    required double proteinGoal,
    required double fatEaten,
    required double fatGoal,
    required double carbsEaten,
    required double carbsGoal,
    @Default(0) int compulsiveCount,

    // ── New: extended nutrients ──
    @Default(0) double netCarbsEaten,
    @Default(0) double netCarbsGoal,
    @Default(0) double sugarEaten,
    @Default(0) double sugarGoal,
    @Default(0) double fiberEaten,
    @Default(0) double fiberGoal,
    @Default(0) double saturatedFatEaten,
    @Default(0) double saturatedFatGoal,
    @Default(0) double unsaturatedFatEaten,
    @Default(0) double unsaturatedFatGoal,
  }) = _MacroStats;

  factory MacroStats.fromJson(Map<String, dynamic> json) =>
      _$MacroStatsFromJson(json);
}
