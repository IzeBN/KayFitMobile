// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MacroStatsImpl _$$MacroStatsImplFromJson(Map<String, dynamic> json) =>
    _$MacroStatsImpl(
      caloriesEaten: (json['caloriesEaten'] as num).toDouble(),
      caloriesGoal: (json['caloriesGoal'] as num).toDouble(),
      proteinEaten: (json['proteinEaten'] as num).toDouble(),
      proteinGoal: (json['proteinGoal'] as num).toDouble(),
      fatEaten: (json['fatEaten'] as num).toDouble(),
      fatGoal: (json['fatGoal'] as num).toDouble(),
      carbsEaten: (json['carbsEaten'] as num).toDouble(),
      carbsGoal: (json['carbsGoal'] as num).toDouble(),
      compulsiveCount: (json['compulsiveCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MacroStatsImplToJson(_$MacroStatsImpl instance) =>
    <String, dynamic>{
      'caloriesEaten': instance.caloriesEaten,
      'caloriesGoal': instance.caloriesGoal,
      'proteinEaten': instance.proteinEaten,
      'proteinGoal': instance.proteinGoal,
      'fatEaten': instance.fatEaten,
      'fatGoal': instance.fatGoal,
      'carbsEaten': instance.carbsEaten,
      'carbsGoal': instance.carbsGoal,
      'compulsiveCount': instance.compulsiveCount,
    };
