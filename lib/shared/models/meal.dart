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
    double? sodium,
    double? cholesterol,
    double? iron,
    double? calcium,
    double? potassium,
    @JsonKey(name: 'vitamin_a') double? vitaminA,
    @JsonKey(name: 'vitamin_c') double? vitaminC,
    @JsonKey(name: 'vitamin_d') double? vitaminD,
    @JsonKey(name: 'vitamin_b12') double? vitaminB12,
    String? source,
    @JsonKey(name: 'source_url') String? sourceUrl,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
