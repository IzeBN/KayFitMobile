// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Meal _$MealFromJson(Map<String, dynamic> json) {
  return _Meal.fromJson(json);
}

/// @nodoc
mixin _$Meal {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get calories => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError;
  String? get emotion => throw _privateConstructorUsedError;
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'net_carbs')
  double? get netCarbs => throw _privateConstructorUsedError;
  double? get fiber => throw _privateConstructorUsedError;
  double? get sugar => throw _privateConstructorUsedError;
  @JsonKey(name: 'sugar_alcohols')
  double? get sugarAlcohols => throw _privateConstructorUsedError;
  @JsonKey(name: 'glycemic_index')
  int? get glycemicIndex => throw _privateConstructorUsedError;
  @JsonKey(name: 'saturated_fat')
  double? get saturatedFat => throw _privateConstructorUsedError;
  @JsonKey(name: 'unsaturated_fat')
  double? get unsaturatedFat => throw _privateConstructorUsedError;
  double? get sodium => throw _privateConstructorUsedError;
  double? get cholesterol => throw _privateConstructorUsedError;
  double? get iron => throw _privateConstructorUsedError;
  double? get calcium => throw _privateConstructorUsedError;
  double? get potassium => throw _privateConstructorUsedError;
  @JsonKey(name: 'vitamin_a')
  double? get vitaminA => throw _privateConstructorUsedError;
  @JsonKey(name: 'vitamin_c')
  double? get vitaminC => throw _privateConstructorUsedError;
  @JsonKey(name: 'vitamin_d')
  double? get vitaminD => throw _privateConstructorUsedError;
  @JsonKey(name: 'vitamin_b12')
  double? get vitaminB12 => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_url')
  String? get sourceUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'meal_type')
  String? get mealType => throw _privateConstructorUsedError;
  @JsonKey(name: 'dish_name')
  String? get dishName => throw _privateConstructorUsedError;

  /// Serializes this Meal to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealCopyWith<Meal> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealCopyWith<$Res> {
  factory $MealCopyWith(Meal value, $Res Function(Meal) then) =
      _$MealCopyWithImpl<$Res, Meal>;
  @useResult
  $Res call({
    int id,
    String name,
    double calories,
    double protein,
    double fat,
    double carbs,
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
    @JsonKey(name: 'meal_type') String? mealType,
    @JsonKey(name: 'dish_name') String? dishName,
  });
}

/// @nodoc
class _$MealCopyWithImpl<$Res, $Val extends Meal>
    implements $MealCopyWith<$Res> {
  _$MealCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? weight = freezed,
    Object? emotion = freezed,
    Object? createdAt = freezed,
    Object? netCarbs = freezed,
    Object? fiber = freezed,
    Object? sugar = freezed,
    Object? sugarAlcohols = freezed,
    Object? glycemicIndex = freezed,
    Object? saturatedFat = freezed,
    Object? unsaturatedFat = freezed,
    Object? sodium = freezed,
    Object? cholesterol = freezed,
    Object? iron = freezed,
    Object? calcium = freezed,
    Object? potassium = freezed,
    Object? vitaminA = freezed,
    Object? vitaminC = freezed,
    Object? vitaminD = freezed,
    Object? vitaminB12 = freezed,
    Object? source = freezed,
    Object? sourceUrl = freezed,
    Object? mealType = freezed,
    Object? dishName = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
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
            weight: freezed == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double?,
            emotion: freezed == emotion
                ? _value.emotion
                : emotion // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            netCarbs: freezed == netCarbs
                ? _value.netCarbs
                : netCarbs // ignore: cast_nullable_to_non_nullable
                      as double?,
            fiber: freezed == fiber
                ? _value.fiber
                : fiber // ignore: cast_nullable_to_non_nullable
                      as double?,
            sugar: freezed == sugar
                ? _value.sugar
                : sugar // ignore: cast_nullable_to_non_nullable
                      as double?,
            sugarAlcohols: freezed == sugarAlcohols
                ? _value.sugarAlcohols
                : sugarAlcohols // ignore: cast_nullable_to_non_nullable
                      as double?,
            glycemicIndex: freezed == glycemicIndex
                ? _value.glycemicIndex
                : glycemicIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
            saturatedFat: freezed == saturatedFat
                ? _value.saturatedFat
                : saturatedFat // ignore: cast_nullable_to_non_nullable
                      as double?,
            unsaturatedFat: freezed == unsaturatedFat
                ? _value.unsaturatedFat
                : unsaturatedFat // ignore: cast_nullable_to_non_nullable
                      as double?,
            sodium: freezed == sodium
                ? _value.sodium
                : sodium // ignore: cast_nullable_to_non_nullable
                      as double?,
            cholesterol: freezed == cholesterol
                ? _value.cholesterol
                : cholesterol // ignore: cast_nullable_to_non_nullable
                      as double?,
            iron: freezed == iron
                ? _value.iron
                : iron // ignore: cast_nullable_to_non_nullable
                      as double?,
            calcium: freezed == calcium
                ? _value.calcium
                : calcium // ignore: cast_nullable_to_non_nullable
                      as double?,
            potassium: freezed == potassium
                ? _value.potassium
                : potassium // ignore: cast_nullable_to_non_nullable
                      as double?,
            vitaminA: freezed == vitaminA
                ? _value.vitaminA
                : vitaminA // ignore: cast_nullable_to_non_nullable
                      as double?,
            vitaminC: freezed == vitaminC
                ? _value.vitaminC
                : vitaminC // ignore: cast_nullable_to_non_nullable
                      as double?,
            vitaminD: freezed == vitaminD
                ? _value.vitaminD
                : vitaminD // ignore: cast_nullable_to_non_nullable
                      as double?,
            vitaminB12: freezed == vitaminB12
                ? _value.vitaminB12
                : vitaminB12 // ignore: cast_nullable_to_non_nullable
                      as double?,
            source: freezed == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String?,
            sourceUrl: freezed == sourceUrl
                ? _value.sourceUrl
                : sourceUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            mealType: freezed == mealType
                ? _value.mealType
                : mealType // ignore: cast_nullable_to_non_nullable
                      as String?,
            dishName: freezed == dishName
                ? _value.dishName
                : dishName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealImplCopyWith<$Res> implements $MealCopyWith<$Res> {
  factory _$$MealImplCopyWith(
    _$MealImpl value,
    $Res Function(_$MealImpl) then,
  ) = __$$MealImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    double calories,
    double protein,
    double fat,
    double carbs,
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
    @JsonKey(name: 'meal_type') String? mealType,
    @JsonKey(name: 'dish_name') String? dishName,
  });
}

/// @nodoc
class __$$MealImplCopyWithImpl<$Res>
    extends _$MealCopyWithImpl<$Res, _$MealImpl>
    implements _$$MealImplCopyWith<$Res> {
  __$$MealImplCopyWithImpl(_$MealImpl _value, $Res Function(_$MealImpl) _then)
    : super(_value, _then);

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? weight = freezed,
    Object? emotion = freezed,
    Object? createdAt = freezed,
    Object? netCarbs = freezed,
    Object? fiber = freezed,
    Object? sugar = freezed,
    Object? sugarAlcohols = freezed,
    Object? glycemicIndex = freezed,
    Object? saturatedFat = freezed,
    Object? unsaturatedFat = freezed,
    Object? sodium = freezed,
    Object? cholesterol = freezed,
    Object? iron = freezed,
    Object? calcium = freezed,
    Object? potassium = freezed,
    Object? vitaminA = freezed,
    Object? vitaminC = freezed,
    Object? vitaminD = freezed,
    Object? vitaminB12 = freezed,
    Object? source = freezed,
    Object? sourceUrl = freezed,
    Object? mealType = freezed,
    Object? dishName = freezed,
  }) {
    return _then(
      _$MealImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
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
        weight: freezed == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double?,
        emotion: freezed == emotion
            ? _value.emotion
            : emotion // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        netCarbs: freezed == netCarbs
            ? _value.netCarbs
            : netCarbs // ignore: cast_nullable_to_non_nullable
                  as double?,
        fiber: freezed == fiber
            ? _value.fiber
            : fiber // ignore: cast_nullable_to_non_nullable
                  as double?,
        sugar: freezed == sugar
            ? _value.sugar
            : sugar // ignore: cast_nullable_to_non_nullable
                  as double?,
        sugarAlcohols: freezed == sugarAlcohols
            ? _value.sugarAlcohols
            : sugarAlcohols // ignore: cast_nullable_to_non_nullable
                  as double?,
        glycemicIndex: freezed == glycemicIndex
            ? _value.glycemicIndex
            : glycemicIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
        saturatedFat: freezed == saturatedFat
            ? _value.saturatedFat
            : saturatedFat // ignore: cast_nullable_to_non_nullable
                  as double?,
        unsaturatedFat: freezed == unsaturatedFat
            ? _value.unsaturatedFat
            : unsaturatedFat // ignore: cast_nullable_to_non_nullable
                  as double?,
        sodium: freezed == sodium
            ? _value.sodium
            : sodium // ignore: cast_nullable_to_non_nullable
                  as double?,
        cholesterol: freezed == cholesterol
            ? _value.cholesterol
            : cholesterol // ignore: cast_nullable_to_non_nullable
                  as double?,
        iron: freezed == iron
            ? _value.iron
            : iron // ignore: cast_nullable_to_non_nullable
                  as double?,
        calcium: freezed == calcium
            ? _value.calcium
            : calcium // ignore: cast_nullable_to_non_nullable
                  as double?,
        potassium: freezed == potassium
            ? _value.potassium
            : potassium // ignore: cast_nullable_to_non_nullable
                  as double?,
        vitaminA: freezed == vitaminA
            ? _value.vitaminA
            : vitaminA // ignore: cast_nullable_to_non_nullable
                  as double?,
        vitaminC: freezed == vitaminC
            ? _value.vitaminC
            : vitaminC // ignore: cast_nullable_to_non_nullable
                  as double?,
        vitaminD: freezed == vitaminD
            ? _value.vitaminD
            : vitaminD // ignore: cast_nullable_to_non_nullable
                  as double?,
        vitaminB12: freezed == vitaminB12
            ? _value.vitaminB12
            : vitaminB12 // ignore: cast_nullable_to_non_nullable
                  as double?,
        source: freezed == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String?,
        sourceUrl: freezed == sourceUrl
            ? _value.sourceUrl
            : sourceUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        mealType: freezed == mealType
            ? _value.mealType
            : mealType // ignore: cast_nullable_to_non_nullable
                  as String?,
        dishName: freezed == dishName
            ? _value.dishName
            : dishName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealImpl implements _Meal {
  const _$MealImpl({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.weight,
    this.emotion,
    this.createdAt,
    @JsonKey(name: 'net_carbs') this.netCarbs,
    this.fiber,
    this.sugar,
    @JsonKey(name: 'sugar_alcohols') this.sugarAlcohols,
    @JsonKey(name: 'glycemic_index') this.glycemicIndex,
    @JsonKey(name: 'saturated_fat') this.saturatedFat,
    @JsonKey(name: 'unsaturated_fat') this.unsaturatedFat,
    this.sodium,
    this.cholesterol,
    this.iron,
    this.calcium,
    this.potassium,
    @JsonKey(name: 'vitamin_a') this.vitaminA,
    @JsonKey(name: 'vitamin_c') this.vitaminC,
    @JsonKey(name: 'vitamin_d') this.vitaminD,
    @JsonKey(name: 'vitamin_b12') this.vitaminB12,
    this.source,
    @JsonKey(name: 'source_url') this.sourceUrl,
    @JsonKey(name: 'meal_type') this.mealType,
    @JsonKey(name: 'dish_name') this.dishName,
  });

  factory _$MealImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final double calories;
  @override
  final double protein;
  @override
  final double fat;
  @override
  final double carbs;
  @override
  final double? weight;
  @override
  final String? emotion;
  @override
  final String? createdAt;
  @override
  @JsonKey(name: 'net_carbs')
  final double? netCarbs;
  @override
  final double? fiber;
  @override
  final double? sugar;
  @override
  @JsonKey(name: 'sugar_alcohols')
  final double? sugarAlcohols;
  @override
  @JsonKey(name: 'glycemic_index')
  final int? glycemicIndex;
  @override
  @JsonKey(name: 'saturated_fat')
  final double? saturatedFat;
  @override
  @JsonKey(name: 'unsaturated_fat')
  final double? unsaturatedFat;
  @override
  final double? sodium;
  @override
  final double? cholesterol;
  @override
  final double? iron;
  @override
  final double? calcium;
  @override
  final double? potassium;
  @override
  @JsonKey(name: 'vitamin_a')
  final double? vitaminA;
  @override
  @JsonKey(name: 'vitamin_c')
  final double? vitaminC;
  @override
  @JsonKey(name: 'vitamin_d')
  final double? vitaminD;
  @override
  @JsonKey(name: 'vitamin_b12')
  final double? vitaminB12;
  @override
  final String? source;
  @override
  @JsonKey(name: 'source_url')
  final String? sourceUrl;
  @override
  @JsonKey(name: 'meal_type')
  final String? mealType;
  @override
  @JsonKey(name: 'dish_name')
  final String? dishName;

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs, weight: $weight, emotion: $emotion, createdAt: $createdAt, netCarbs: $netCarbs, fiber: $fiber, sugar: $sugar, sugarAlcohols: $sugarAlcohols, glycemicIndex: $glycemicIndex, saturatedFat: $saturatedFat, unsaturatedFat: $unsaturatedFat, sodium: $sodium, cholesterol: $cholesterol, iron: $iron, calcium: $calcium, potassium: $potassium, vitaminA: $vitaminA, vitaminC: $vitaminC, vitaminD: $vitaminD, vitaminB12: $vitaminB12, source: $source, sourceUrl: $sourceUrl, mealType: $mealType, dishName: $dishName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.emotion, emotion) || other.emotion == emotion) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
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
            (identical(other.sodium, sodium) || other.sodium == sodium) &&
            (identical(other.cholesterol, cholesterol) ||
                other.cholesterol == cholesterol) &&
            (identical(other.iron, iron) || other.iron == iron) &&
            (identical(other.calcium, calcium) || other.calcium == calcium) &&
            (identical(other.potassium, potassium) ||
                other.potassium == potassium) &&
            (identical(other.vitaminA, vitaminA) ||
                other.vitaminA == vitaminA) &&
            (identical(other.vitaminC, vitaminC) ||
                other.vitaminC == vitaminC) &&
            (identical(other.vitaminD, vitaminD) ||
                other.vitaminD == vitaminD) &&
            (identical(other.vitaminB12, vitaminB12) ||
                other.vitaminB12 == vitaminB12) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.sourceUrl, sourceUrl) ||
                other.sourceUrl == sourceUrl) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            (identical(other.dishName, dishName) ||
                other.dishName == dishName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    name,
    calories,
    protein,
    fat,
    carbs,
    weight,
    emotion,
    createdAt,
    netCarbs,
    fiber,
    sugar,
    sugarAlcohols,
    glycemicIndex,
    saturatedFat,
    unsaturatedFat,
    sodium,
    cholesterol,
    iron,
    calcium,
    potassium,
    vitaminA,
    vitaminC,
    vitaminD,
    vitaminB12,
    source,
    sourceUrl,
    mealType,
    dishName,
  ]);

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      __$$MealImplCopyWithImpl<_$MealImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealImplToJson(this);
  }
}

abstract class _Meal implements Meal {
  const factory _Meal({
    required final int id,
    required final String name,
    required final double calories,
    required final double protein,
    required final double fat,
    required final double carbs,
    final double? weight,
    final String? emotion,
    final String? createdAt,
    @JsonKey(name: 'net_carbs') final double? netCarbs,
    final double? fiber,
    final double? sugar,
    @JsonKey(name: 'sugar_alcohols') final double? sugarAlcohols,
    @JsonKey(name: 'glycemic_index') final int? glycemicIndex,
    @JsonKey(name: 'saturated_fat') final double? saturatedFat,
    @JsonKey(name: 'unsaturated_fat') final double? unsaturatedFat,
    final double? sodium,
    final double? cholesterol,
    final double? iron,
    final double? calcium,
    final double? potassium,
    @JsonKey(name: 'vitamin_a') final double? vitaminA,
    @JsonKey(name: 'vitamin_c') final double? vitaminC,
    @JsonKey(name: 'vitamin_d') final double? vitaminD,
    @JsonKey(name: 'vitamin_b12') final double? vitaminB12,
    final String? source,
    @JsonKey(name: 'source_url') final String? sourceUrl,
    @JsonKey(name: 'meal_type') final String? mealType,
    @JsonKey(name: 'dish_name') final String? dishName,
  }) = _$MealImpl;

  factory _Meal.fromJson(Map<String, dynamic> json) = _$MealImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  double get calories;
  @override
  double get protein;
  @override
  double get fat;
  @override
  double get carbs;
  @override
  double? get weight;
  @override
  String? get emotion;
  @override
  String? get createdAt;
  @override
  @JsonKey(name: 'net_carbs')
  double? get netCarbs;
  @override
  double? get fiber;
  @override
  double? get sugar;
  @override
  @JsonKey(name: 'sugar_alcohols')
  double? get sugarAlcohols;
  @override
  @JsonKey(name: 'glycemic_index')
  int? get glycemicIndex;
  @override
  @JsonKey(name: 'saturated_fat')
  double? get saturatedFat;
  @override
  @JsonKey(name: 'unsaturated_fat')
  double? get unsaturatedFat;
  @override
  double? get sodium;
  @override
  double? get cholesterol;
  @override
  double? get iron;
  @override
  double? get calcium;
  @override
  double? get potassium;
  @override
  @JsonKey(name: 'vitamin_a')
  double? get vitaminA;
  @override
  @JsonKey(name: 'vitamin_c')
  double? get vitaminC;
  @override
  @JsonKey(name: 'vitamin_d')
  double? get vitaminD;
  @override
  @JsonKey(name: 'vitamin_b12')
  double? get vitaminB12;
  @override
  String? get source;
  @override
  @JsonKey(name: 'source_url')
  String? get sourceUrl;
  @override
  @JsonKey(name: 'meal_type')
  String? get mealType;
  @override
  @JsonKey(name: 'dish_name')
  String? get dishName;

  /// Create a copy of Meal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealImplCopyWith<_$MealImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
