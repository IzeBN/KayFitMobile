// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      name: json['name'] as String,
      weightGrams: (json['weight_grams'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      netCarbs: (json['net_carbs'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
      sugarAlcohols: (json['sugar_alcohols'] as num?)?.toDouble() ?? 0,
      glycemicIndex: (json['glycemic_index'] as num?)?.toInt(),
      saturatedFat: (json['saturated_fat'] as num?)?.toDouble() ?? 0,
      unsaturatedFat: (json['unsaturated_fat'] as num?)?.toDouble() ?? 0,
      selected: json['selected'] as bool? ?? true,
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'weight_grams': instance.weightGrams,
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
      'net_carbs': instance.netCarbs,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'sugar_alcohols': instance.sugarAlcohols,
      'glycemic_index': instance.glycemicIndex,
      'saturated_fat': instance.saturatedFat,
      'unsaturated_fat': instance.unsaturatedFat,
      'selected': instance.selected,
    };
