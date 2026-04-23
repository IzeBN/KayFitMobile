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
  netCarbs: (json['net_carbs'] as num?)?.toDouble(),
  fiber: (json['fiber'] as num?)?.toDouble(),
  sugar: (json['sugar'] as num?)?.toDouble(),
  sugarAlcohols: (json['sugar_alcohols'] as num?)?.toDouble(),
  glycemicIndex: (json['glycemic_index'] as num?)?.toInt(),
  saturatedFat: (json['saturated_fat'] as num?)?.toDouble(),
  unsaturatedFat: (json['unsaturated_fat'] as num?)?.toDouble(),
  sodium: (json['sodium_mg'] as num?)?.toDouble(),
  cholesterol: (json['cholesterol_mg'] as num?)?.toDouble(),
  iron: (json['iron_mg'] as num?)?.toDouble(),
  calcium: (json['calcium_mg'] as num?)?.toDouble(),
  potassium: (json['potassium_mg'] as num?)?.toDouble(),
  vitaminA: (json['vitamin_a_mcg'] as num?)?.toDouble(),
  vitaminC: (json['vitamin_c_mg'] as num?)?.toDouble(),
  vitaminD: (json['vitamin_d_mcg'] as num?)?.toDouble(),
  vitaminB12: (json['vitamin_b12_mcg'] as num?)?.toDouble(),
  source: json['source'] as String?,
  sourceUrl: json['source_url'] as String?,
  mealType: json['meal_type'] as String?,
  dishName: json['dish_name'] as String?,
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
      'net_carbs': instance.netCarbs,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'sugar_alcohols': instance.sugarAlcohols,
      'glycemic_index': instance.glycemicIndex,
      'saturated_fat': instance.saturatedFat,
      'unsaturated_fat': instance.unsaturatedFat,
      'sodium_mg': instance.sodium,
      'cholesterol_mg': instance.cholesterol,
      'iron_mg': instance.iron,
      'calcium_mg': instance.calcium,
      'potassium_mg': instance.potassium,
      'vitamin_a_mcg': instance.vitaminA,
      'vitamin_c_mg': instance.vitaminC,
      'vitamin_d_mcg': instance.vitaminD,
      'vitamin_b12_mcg': instance.vitaminB12,
      'source': instance.source,
      'source_url': instance.sourceUrl,
      'meal_type': instance.mealType,
      'dish_name': instance.dishName,
    };
