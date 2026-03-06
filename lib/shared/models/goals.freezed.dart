// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Goals _$GoalsFromJson(Map<String, dynamic> json) {
  return _Goals.fromJson(json);
}

/// @nodoc
mixin _$Goals {
  double get calories => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;

  /// Serializes this Goals to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Goals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoalsCopyWith<Goals> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalsCopyWith<$Res> {
  factory $GoalsCopyWith(Goals value, $Res Function(Goals) then) =
      _$GoalsCopyWithImpl<$Res, Goals>;
  @useResult
  $Res call({double calories, double protein, double fat, double carbs});
}

/// @nodoc
class _$GoalsCopyWithImpl<$Res, $Val extends Goals>
    implements $GoalsCopyWith<$Res> {
  _$GoalsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Goals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
  }) {
    return _then(
      _value.copyWith(
            calories: null == calories
                ? _value.calories
                : calories // ignore: cast_nullable_to_non_nullable
                      as double,
            protein: null == protein
                ? _value.protein
                : protein // ignore: cast_nullable_to_non_nullable
                      as double,
            fat: null == fat
                ? _value.fat
                : fat // ignore: cast_nullable_to_non_nullable
                      as double,
            carbs: null == carbs
                ? _value.carbs
                : carbs // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GoalsImplCopyWith<$Res> implements $GoalsCopyWith<$Res> {
  factory _$$GoalsImplCopyWith(
    _$GoalsImpl value,
    $Res Function(_$GoalsImpl) then,
  ) = __$$GoalsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double calories, double protein, double fat, double carbs});
}

/// @nodoc
class __$$GoalsImplCopyWithImpl<$Res>
    extends _$GoalsCopyWithImpl<$Res, _$GoalsImpl>
    implements _$$GoalsImplCopyWith<$Res> {
  __$$GoalsImplCopyWithImpl(
    _$GoalsImpl _value,
    $Res Function(_$GoalsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Goals
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
  }) {
    return _then(
      _$GoalsImpl(
        calories: null == calories
            ? _value.calories
            : calories // ignore: cast_nullable_to_non_nullable
                  as double,
        protein: null == protein
            ? _value.protein
            : protein // ignore: cast_nullable_to_non_nullable
                  as double,
        fat: null == fat
            ? _value.fat
            : fat // ignore: cast_nullable_to_non_nullable
                  as double,
        carbs: null == carbs
            ? _value.carbs
            : carbs // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalsImpl implements _Goals {
  const _$GoalsImpl({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  factory _$GoalsImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalsImplFromJson(json);

  @override
  final double calories;
  @override
  final double protein;
  @override
  final double fat;
  @override
  final double carbs;

  @override
  String toString() {
    return 'Goals(calories: $calories, protein: $protein, fat: $fat, carbs: $carbs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalsImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.carbs, carbs) || other.carbs == carbs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, calories, protein, fat, carbs);

  /// Create a copy of Goals
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalsImplCopyWith<_$GoalsImpl> get copyWith =>
      __$$GoalsImplCopyWithImpl<_$GoalsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalsImplToJson(this);
  }
}

abstract class _Goals implements Goals {
  const factory _Goals({
    required final double calories,
    required final double protein,
    required final double fat,
    required final double carbs,
  }) = _$GoalsImpl;

  factory _Goals.fromJson(Map<String, dynamic> json) = _$GoalsImpl.fromJson;

  @override
  double get calories;
  @override
  double get protein;
  @override
  double get fat;
  @override
  double get carbs;

  /// Create a copy of Goals
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoalsImplCopyWith<_$GoalsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
