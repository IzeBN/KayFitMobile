// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalculationResultImpl _$$CalculationResultImplFromJson(
  Map<String, dynamic> json,
) => _$CalculationResultImpl(
  bmr: (json['bmr'] as num).toDouble(),
  tdee: (json['tdee'] as num).toDouble(),
  targetCalories: (json['target_calories'] as num).toDouble(),
  protein: (json['protein'] as num).toDouble(),
  fat: (json['fat'] as num).toDouble(),
  carbs: (json['carbs'] as num).toDouble(),
  daysToGoal: (json['days_to_goal'] as num?)?.toInt(),
  targetWeight: (json['target_weight'] as num?)?.toDouble(),
  currentWeight: (json['current_weight'] as num?)?.toDouble(),
  chartData: json['chart_data'] as List<dynamic>?,
);

Map<String, dynamic> _$$CalculationResultImplToJson(
  _$CalculationResultImpl instance,
) => <String, dynamic>{
  'bmr': instance.bmr,
  'tdee': instance.tdee,
  'target_calories': instance.targetCalories,
  'protein': instance.protein,
  'fat': instance.fat,
  'carbs': instance.carbs,
  'days_to_goal': instance.daysToGoal,
  'target_weight': instance.targetWeight,
  'current_weight': instance.currentWeight,
  'chart_data': instance.chartData,
};
