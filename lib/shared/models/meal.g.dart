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
  createdAt: json['time'] as String?,
  netCarbs: (json['net_carbs'] as num?)?.toDouble(),
  fiber: (json['fiber'] as num?)?.toDouble(),
  sugar: (json['sugar'] as num?)?.toDouble(),
  sugarAlcohols: (json['sugar_alcohols'] as num?)?.toDouble(),
  glycemicIndex: (json['glycemic_index'] as num?)?.toInt(),
  saturatedFat: (json['saturated_fat'] as num?)?.toDouble(),
  unsaturatedFat: (json['unsaturated_fat'] as num?)?.toDouble(),
  sodium: (json['sodium'] as num?)?.toDouble(),
  cholesterol: (json['cholesterol'] as num?)?.toDouble(),
  iron: (json['iron'] as num?)?.toDouble(),
  calcium: (json['calcium'] as num?)?.toDouble(),
  potassium: (json['potassium'] as num?)?.toDouble(),
  vitaminA: (json['vitamin_a'] as num?)?.toDouble(),
  vitaminC: (json['vitamin_c'] as num?)?.toDouble(),
  vitaminD: (json['vitamin_d'] as num?)?.toDouble(),
  vitaminB12: (json['vitamin_b12'] as num?)?.toDouble(),
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
      'time': instance.createdAt,
      'net_carbs': instance.netCarbs,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'sugar_alcohols': instance.sugarAlcohols,
      'glycemic_index': instance.glycemicIndex,
      'saturated_fat': instance.saturatedFat,
      'unsaturated_fat': instance.unsaturatedFat,
      'sodium': instance.sodium,
      'cholesterol': instance.cholesterol,
      'iron': instance.iron,
      'calcium': instance.calcium,
      'potassium': instance.potassium,
      'vitamin_a': instance.vitaminA,
      'vitamin_c': instance.vitaminC,
      'vitamin_d': instance.vitaminD,
      'vitamin_b12': instance.vitaminB12,
    };
