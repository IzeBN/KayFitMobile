import 'package:freezed_annotation/freezed_annotation.dart';

part 'nutrients_v2.freezed.dart';
part 'nutrients_v2.g.dart';

@freezed
class NutrientsV2 with _$NutrientsV2 {
  const factory NutrientsV2({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    double? fiber,
    double? sugar,
    @JsonKey(name: 'sugar_alcohols') double? sugarAlcohols,
    @JsonKey(name: 'net_carbs') double? netCarbs,
    @JsonKey(name: 'saturated_fat') double? saturatedFat,
    @JsonKey(name: 'monounsaturated_fat') double? monounsaturatedFat,
    @JsonKey(name: 'polyunsaturated_fat') double? polyunsaturatedFat,
    @JsonKey(name: 'sodium_mg') double? sodiumMg,
    @JsonKey(name: 'cholesterol_mg') double? cholesterolMg,
    @JsonKey(name: 'potassium_mg') double? potassiumMg,
    @JsonKey(name: 'calcium_mg') double? calciumMg,
    @JsonKey(name: 'iron_mg') double? ironMg,
    @JsonKey(name: 'vitamin_a_mcg') double? vitaminAMcg,
    @JsonKey(name: 'vitamin_c_mg') double? vitaminCMg,
    @JsonKey(name: 'vitamin_d_mcg') double? vitaminDMcg,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,
    @JsonKey(name: 'glycemic_index_category') String? glycemicIndexCategory,
  }) = _NutrientsV2;

  factory NutrientsV2.fromJson(Map<String, dynamic> json) =>
      _$NutrientsV2FromJson(json);

  /// Zero-calorie placeholder used by the frontend whitelist guard.
  /// All required macros are set to 0; optional fields are left null.
  factory NutrientsV2.zero() => const NutrientsV2(
        calories: 0,
        protein: 0,
        fat: 0,
        carbs: 0,
      );
}
