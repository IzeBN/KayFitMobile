// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GoalsImpl _$$GoalsImplFromJson(Map<String, dynamic> json) => _$GoalsImpl(
  calories: (json['calories'] as num).toDouble(),
  protein: (json['protein'] as num).toDouble(),
  fat: (json['fat'] as num).toDouble(),
  carbs: (json['carbs'] as num).toDouble(),
);

Map<String, dynamic> _$$GoalsImplToJson(_$GoalsImpl instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
    };
