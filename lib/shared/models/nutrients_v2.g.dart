// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrients_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NutrientsV2Impl _$$NutrientsV2ImplFromJson(Map<String, dynamic> json) =>
    _$NutrientsV2Impl(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fiber: (json['fiber'] as num?)?.toDouble(),
      sugar: (json['sugar'] as num?)?.toDouble(),
      sugarAlcohols: (json['sugar_alcohols'] as num?)?.toDouble(),
      netCarbs: (json['net_carbs'] as num?)?.toDouble(),
      saturatedFat: (json['saturated_fat'] as num?)?.toDouble(),
      monounsaturatedFat: (json['monounsaturated_fat'] as num?)?.toDouble(),
      polyunsaturatedFat: (json['polyunsaturated_fat'] as num?)?.toDouble(),
      sodiumMg: (json['sodium_mg'] as num?)?.toDouble(),
      cholesterolMg: (json['cholesterol_mg'] as num?)?.toDouble(),
      potassiumMg: (json['potassium_mg'] as num?)?.toDouble(),
      calciumMg: (json['calcium_mg'] as num?)?.toDouble(),
      ironMg: (json['iron_mg'] as num?)?.toDouble(),
      vitaminAMcg: (json['vitamin_a_mcg'] as num?)?.toDouble(),
      vitaminCMg: (json['vitamin_c_mg'] as num?)?.toDouble(),
      vitaminDMcg: (json['vitamin_d_mcg'] as num?)?.toDouble(),
      glycemicIndex: (json['glycemic_index'] as num?)?.toInt(),
      glycemicIndexCategory: json['glycemic_index_category'] as String?,
    );

Map<String, dynamic> _$$NutrientsV2ImplToJson(_$NutrientsV2Impl instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'sugar_alcohols': instance.sugarAlcohols,
      'net_carbs': instance.netCarbs,
      'saturated_fat': instance.saturatedFat,
      'monounsaturated_fat': instance.monounsaturatedFat,
      'polyunsaturated_fat': instance.polyunsaturatedFat,
      'sodium_mg': instance.sodiumMg,
      'cholesterol_mg': instance.cholesterolMg,
      'potassium_mg': instance.potassiumMg,
      'calcium_mg': instance.calciumMg,
      'iron_mg': instance.ironMg,
      'vitamin_a_mcg': instance.vitaminAMcg,
      'vitamin_c_mg': instance.vitaminCMg,
      'vitamin_d_mcg': instance.vitaminDMcg,
      'glycemic_index': instance.glycemicIndex,
      'glycemic_index_category': instance.glycemicIndexCategory,
    };
