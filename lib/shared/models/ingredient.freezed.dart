// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Ingredient _$IngredientFromJson(Map<String, dynamic> json) {
  return _Ingredient.fromJson(json);
}

/// @nodoc
mixin _$Ingredient {
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'weight_grams')
  double get weightGrams => throw _privateConstructorUsedError;
  double get calories => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  @JsonKey(name: 'net_carbs')
  double get netCarbs => throw _privateConstructorUsedError;
  double get fiber => throw _privateConstructorUsedError;
  double get sugar => throw _privateConstructorUsedError;
  @JsonKey(name: 'sugar_alcohols')
  double get sugarAlcohols => throw _privateConstructorUsedError;
  @JsonKey(name: 'glycemic_index')
  int? get glycemicIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'saturated_fat')
  double get saturatedFat => throw _privateConstructorUsedError;
  @JsonKey(name: 'unsaturated_fat')
  double get unsaturatedFat => throw _privateConstructorUsedError;
  bool get selected => throw _privateConstructorUsedError;

  /// Serializes this Ingredient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IngredientCopyWith<Ingredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientCopyWith<$Res> {
  factory $IngredientCopyWith(
    Ingredient value,
    $Res Function(Ingredient) then,
  ) = _$IngredientCopyWithImpl<$Res, Ingredient>;
  @useResult
  $Res call({
    String name,
    @JsonKey(name: 'weight_grams') double weightGrams,
    double calories,
    double protein,
    double fat,
    double carbs,
    @JsonKey(name: 'net_carbs') double netCarbs,
    double fiber,
    double sugar,
    @JsonKey(name: 'sugar_alcohols') double sugarAlcohols,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') double saturatedFat,
    @JsonKey(name: 'unsaturated_fat') double unsaturatedFat,
    bool selected,
  });
}

/// @nodoc
class _$IngredientCopyWithImpl<$Res, $Val extends Ingredient>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? weightGrams = null,
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? netCarbs = null,
    Object? fiber = null,
    Object? sugar = null,
    Object? sugarAlcohols = null,
    Object? glycemicIndex = freezed,
    Object? saturatedFat = null,
    Object? unsaturatedFat = null,
    Object? selected = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            weightGrams: null == weightGrams
                ? _value.weightGrams
                : weightGrams // ignore: cast_nullable_to_non_nullable
                      as double,
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
            netCarbs: null == netCarbs
                ? _value.netCarbs
                : netCarbs // ignore: cast_nullable_to_non_nullable
                      as double,
            fiber: null == fiber
                ? _value.fiber
                : fiber // ignore: cast_nullable_to_non_nullable
                      as double,
            sugar: null == sugar
                ? _value.sugar
                : sugar // ignore: cast_nullable_to_non_nullable
                      as double,
            sugarAlcohols: null == sugarAlcohols
                ? _value.sugarAlcohols
                : sugarAlcohols // ignore: cast_nullable_to_non_nullable
                      as double,
            glycemicIndex: freezed == glycemicIndex
                ? _value.glycemicIndex
                : glycemicIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            saturatedFat: null == saturatedFat
                ? _value.saturatedFat
                : saturatedFat // ignore: cast_nullable_to_non_nullable
                      as double,
            unsaturatedFat: null == unsaturatedFat
                ? _value.unsaturatedFat
                : unsaturatedFat // ignore: cast_nullable_to_non_nullable
                      as double,
            selected: null == selected
                ? _value.selected
                : selected // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$IngredientImplCopyWith<$Res>
    implements $IngredientCopyWith<$Res> {
  factory _$$IngredientImplCopyWith(
    _$IngredientImpl value,
    $Res Function(_$IngredientImpl) then,
  ) = __$$IngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    @JsonKey(name: 'weight_grams') double weightGrams,
    double calories,
    double protein,
    double fat,
    double carbs,
    @JsonKey(name: 'net_carbs') double netCarbs,
    double fiber,
    double sugar,
    @JsonKey(name: 'sugar_alcohols') double sugarAlcohols,
    @JsonKey(name: 'glycemic_index') int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') double saturatedFat,
    @JsonKey(name: 'unsaturated_fat') double unsaturatedFat,
    bool selected,
  });
}

/// @nodoc
class __$$IngredientImplCopyWithImpl<$Res>
    extends _$IngredientCopyWithImpl<$Res, _$IngredientImpl>
    implements _$$IngredientImplCopyWith<$Res> {
  __$$IngredientImplCopyWithImpl(
    _$IngredientImpl _value,
    $Res Function(_$IngredientImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? weightGrams = null,
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? netCarbs = null,
    Object? fiber = null,
    Object? sugar = null,
    Object? sugarAlcohols = null,
    Object? glycemicIndex = freezed,
    Object? saturatedFat = null,
    Object? unsaturatedFat = null,
    Object? selected = null,
  }) {
    return _then(
      _$IngredientImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        weightGrams: null == weightGrams
            ? _value.weightGrams
            : weightGrams // ignore: cast_nullable_to_non_nullable
                  as double,
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
        netCarbs: null == netCarbs
            ? _value.netCarbs
            : netCarbs // ignore: cast_nullable_to_non_nullable
                  as double,
        fiber: null == fiber
            ? _value.fiber
            : fiber // ignore: cast_nullable_to_non_nullable
                  as double,
        sugar: null == sugar
            ? _value.sugar
            : sugar // ignore: cast_nullable_to_non_nullable
                  as double,
        sugarAlcohols: null == sugarAlcohols
            ? _value.sugarAlcohols
            : sugarAlcohols // ignore: cast_nullable_to_non_nullable
                  as double,
        glycemicIndex: freezed == glycemicIndex
            ? _value.glycemicIndex
            : glycemicIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        saturatedFat: null == saturatedFat
            ? _value.saturatedFat
            : saturatedFat // ignore: cast_nullable_to_non_nullable
                  as double,
        unsaturatedFat: null == unsaturatedFat
            ? _value.unsaturatedFat
            : unsaturatedFat // ignore: cast_nullable_to_non_nullable
                  as double,
        selected: null == selected
            ? _value.selected
            : selected // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientImpl implements _Ingredient {
  const _$IngredientImpl({
    required this.name,
    @JsonKey(name: 'weight_grams') required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    @JsonKey(name: 'net_carbs') this.netCarbs = 0,
    this.fiber = 0,
    this.sugar = 0,
    @JsonKey(name: 'sugar_alcohols') this.sugarAlcohols = 0,
    @JsonKey(name: 'glycemic_index') this.glycemicIndex,
    @JsonKey(name: 'saturated_fat') this.saturatedFat = 0,
    @JsonKey(name: 'unsaturated_fat') this.unsaturatedFat = 0,
    this.selected = true,
  });

  factory _$IngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientImplFromJson(json);

  @override
  final String name;
  @override
  @JsonKey(name: 'weight_grams')
  final double weightGrams;
  @override
  final double calories;
  @override
  final double protein;
  @override
  final double fat;
  @override
  final double carbs;
  @override
  @JsonKey(name: 'net_carbs')
  final double netCarbs;
  @override
  @JsonKey()
  final double fiber;
  @override
  @JsonKey()
  final double sugar;
  @override
  @JsonKey(name: 'sugar_alcohols')
  final double sugarAlcohols;
  @override
  @JsonKey(name: 'glycemic_index')
  final int? glycemicIndex;
  @override
  @JsonKey(name: 'saturated_fat')
  final double saturatedFat;
  @override
  @JsonKey(name: 'unsaturated_fat')
  final double unsaturatedFat;
  @override
  @JsonKey()
  final bool selected;

  @override
  String toString() {
    return 'Ingredient(name: $name, weightGrams: $weightGrams, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs, netCarbs: $netCarbs, fiber: $fiber, sugar: $sugar, sugarAlcohols: $sugarAlcohols, glycemicIndex: $glycemicIndex, saturatedFat: $saturatedFat, unsaturatedFat: $unsaturatedFat, selected: $selected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.weightGrams, weightGrams) ||
                other.weightGrams == weightGrams) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.netCarbs, netCarbs) ||
                other.netCarbs == netCarbs) &&
            (identical(other.fiber, fiber) || other.fiber == fiber) &&
            (identical(other.sugar, sugar) || other.sugar == sugar) &&
            (identical(other.sugarAlcohols, sugarAlcohols) ||
                other.sugarAlcohols == sugarAlcohols) &&
            (identical(other.glycemicIndex, glycemicIndex) ||
                other.glycemicIndex == glycemicIndex) &&
            (identical(other.saturatedFat, saturatedFat) ||
                other.saturatedFat == saturatedFat) &&
            (identical(other.unsaturatedFat, unsaturatedFat) ||
                other.unsaturatedFat == unsaturatedFat) &&
            (identical(other.selected, selected) ||
                other.selected == selected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    weightGrams,
    calories,
    protein,
    fat,
    carbs,
    netCarbs,
    fiber,
    sugar,
    sugarAlcohols,
    glycemicIndex,
    saturatedFat,
    unsaturatedFat,
    selected,
  );

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      __$$IngredientImplCopyWithImpl<_$IngredientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientImplToJson(this);
  }
}

abstract class _Ingredient implements Ingredient {
  const factory _Ingredient({
    required final String name,
    @JsonKey(name: 'weight_grams') required final double weightGrams,
    required final double calories,
    required final double protein,
    required final double fat,
    required final double carbs,
    @JsonKey(name: 'net_carbs') final double netCarbs,
    final double fiber,
    final double sugar,
    @JsonKey(name: 'sugar_alcohols') final double sugarAlcohols,
    @JsonKey(name: 'glycemic_index') final int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') final double saturatedFat,
    @JsonKey(name: 'unsaturated_fat') final double unsaturatedFat,
    final bool selected,
  }) = _$IngredientImpl;

  factory _Ingredient.fromJson(Map<String, dynamic> json) =
      _$IngredientImpl.fromJson;

  @override
  String get name;
  @override
  @JsonKey(name: 'weight_grams')
  double get weightGrams;
  @override
  double get calories;
  @override
  double get protein;
  @override
  double get fat;
  @override
  double get carbs;
  @override
  @JsonKey(name: 'net_carbs')
  double get netCarbs;
  @override
  double get fiber;
  @override
  double get sugar;
  @override
  @JsonKey(name: 'sugar_alcohols')
  double get sugarAlcohols;
  @override
  @JsonKey(name: 'glycemic_index')
  int? get glycemicIndex;
  @override
  @JsonKey(name: 'saturated_fat')
  double get saturatedFat;
  @override
  @JsonKey(name: 'unsaturated_fat')
  double get unsaturatedFat;
  @override
  bool get selected;

  /// Create a copy of Ingredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
