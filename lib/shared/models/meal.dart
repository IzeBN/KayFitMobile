import 'package:freezed_annotation/freezed_annotation.dart';

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
    @JsonKey(name: 'net_carbs') double? netCarbs,
    double? fiber,
    double? sugar,
    @JsonKey(name: 'sugar_alcohols') double? sugarAlcohols,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') double? saturatedFat,
    @JsonKey(name: 'unsaturated_fat') double? unsaturatedFat,
    @JsonKey(name: 'sodium_mg') double? sodium,
    @JsonKey(name: 'cholesterol_mg') double? cholesterol,
    @JsonKey(name: 'iron_mg') double? iron,
    @JsonKey(name: 'calcium_mg') double? calcium,
    @JsonKey(name: 'potassium_mg') double? potassium,
    @JsonKey(name: 'vitamin_a_mcg') double? vitaminA,
    @JsonKey(name: 'vitamin_c_mg') double? vitaminC,
    @JsonKey(name: 'vitamin_d_mcg') double? vitaminD,
    @JsonKey(name: 'vitamin_b12_mcg') double? vitaminB12,
    String? source,
    @JsonKey(name: 'source_url') String? sourceUrl,
    @JsonKey(name: 'meal_type') String? mealType,
    @JsonKey(name: 'dish_name') String? dishName,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
