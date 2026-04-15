import 'package:freezed_annotation/freezed_annotation.dart';

part 'calculation_result.freezed.dart';
part 'calculation_result.g.dart';

@freezed
class CalculationResult with _$CalculationResult {
  // ignore: invalid_annotation_target
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CalculationResult({
    required double bmr,
    required double tdee,
    required double targetCalories,
    required double protein,
    required double fat,
    required double carbs,
    int? daysToGoal,
    double? targetWeight,
    double? currentWeight,
    List<dynamic>? chartData,
  }) = _CalculationResult;

  factory CalculationResult.fromJson(Map<String, dynamic> json) =>
      _$CalculationResultFromJson(json);
}
