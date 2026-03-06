// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealImpl _$$MealImplFromJson(Map<String, dynamic> json) => _$MealImpl(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  calories: (json['calories'] as num).toDouble(),
  protein: (json['protein'] as num).toDouble(),
  fat: (json['fat'] as num).toDouble(),
  carbs: (json['carbs'] as num).toDouble(),
  weight: (json['weight'] as num?)?.toDouble(),
  emotion: json['emotion'] as String?,
  createdAt: json['createdAt'] as String?,
);

Map<String, dynamic> _$$MealImplToJson(_$MealImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
      'weight': instance.weight,
      'emotion': instance.emotion,
      'createdAt': instance.createdAt,
    };
