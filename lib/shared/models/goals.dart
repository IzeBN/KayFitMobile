import 'package:freezed_annotation/freezed_annotation.dart';

part 'goals.freezed.dart';
part 'goals.g.dart';

@freezed
class Goals with _$Goals {
  const factory Goals({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
  }) = _Goals;

  factory Goals.fromJson(Map<String, dynamic> json) => _$GoalsFromJson(json);
}
