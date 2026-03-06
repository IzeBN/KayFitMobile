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
  }) = _MacroStats;

  factory MacroStats.fromJson(Map<String, dynamic> json) => _$MacroStatsFromJson(json);
}
