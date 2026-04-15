import 'package:freezed_annotation/freezed_annotation.dart';
import 'ingredient.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@freezed
class Meal with _$Meal {
  const factory Meal({
    required int id,
    required String name,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    double? weight,
    String? emotion,
    String? createdAt,

    // ── New: dish-level fields ──
    @JsonKey(name: 'dish_name') String? dishName,
    @JsonKey(name: 'meal_type') String? mealType, // breakfast, lunch, dinner, snack

    // ── New: carb decomposition ──
    @JsonKey(name: 'total_carbs') double? totalCarbs,
    double? fiber,
    double? sugar,
    @JsonKey(name: 'sugar_alcohols') double? sugarAlcohols,
    @JsonKey(name: 'net_carbs') double? netCarbs,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,

    // ── New: fat breakdown ──
    @JsonKey(name: 'saturated_fat') double? saturatedFat,
    @JsonKey(name: 'unsaturated_fat') double? unsaturatedFat,

    // ── New: micronutrients ──
    double? sodium,
    double? cholesterol,
    double? iron,
    double? calcium,
    @JsonKey(name: 'vitamin_a') double? vitaminA,
    @JsonKey(name: 'vitamin_c') double? vitaminC,
    double? potassium,

    // ── New: ingredients (for dish recognition) ──
    List<Ingredient>? ingredients,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
