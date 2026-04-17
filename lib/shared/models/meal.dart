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
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
