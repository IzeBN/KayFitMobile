import 'package:freezed_annotation/freezed_annotation.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

@freezed
class Ingredient with _$Ingredient {
  const factory Ingredient({
    required String name,
    @JsonKey(name: 'weight_grams') required double weightGrams,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    @JsonKey(name: 'net_carbs') @Default(0) double netCarbs,
    @Default(0) double fiber,
    @Default(0) double sugar,
    @JsonKey(name: 'sugar_alcohols') @Default(0) double sugarAlcohols,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') @Default(0) double saturatedFat,
    @JsonKey(name: 'unsaturated_fat') @Default(0) double unsaturatedFat,
    @Default(true) bool selected,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
