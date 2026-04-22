import '../models/meal.dart';

enum MealGroup { breakfast, lunch, snack, dinner, other }

extension MealGroupLabel on MealGroup {
  String get apiKey => switch (this) {
        MealGroup.breakfast => 'breakfast',
        MealGroup.lunch => 'lunch',
        MealGroup.snack => 'snack',
        MealGroup.dinner => 'dinner',
        MealGroup.other => 'other',
      };

  String get displayLabel => switch (this) {
        MealGroup.breakfast => 'Breakfast',
        MealGroup.lunch => 'Lunch',
        MealGroup.snack => 'Snack',
        MealGroup.dinner => 'Dinner',
        MealGroup.other => 'Other',
      };

  String get emoji => switch (this) {
        MealGroup.breakfast => '🍳',
        MealGroup.lunch => '🥗',
        MealGroup.snack => '🍎',
        MealGroup.dinner => '🍽️',
        MealGroup.other => '🍴',
      };
}

MealGroup mealGroupFromMeal(Meal m) {
  return switch (m.mealType?.toLowerCase()) {
    'breakfast' => MealGroup.breakfast,
    'lunch' => MealGroup.lunch,
    'snack' => MealGroup.snack,
    'dinner' => MealGroup.dinner,
    _ => MealGroup.other,
  };
}

extension MealGrouping on List<Meal> {
  /// Returns ordered groups [breakfast, lunch, snack, dinner, other] — skips empty.
  List<(MealGroup, List<Meal>)> grouped() {
    final map = <MealGroup, List<Meal>>{};
    for (final m in this) {
      map.putIfAbsent(mealGroupFromMeal(m), () => []).add(m);
    }
    const order = [
      MealGroup.breakfast,
      MealGroup.lunch,
      MealGroup.snack,
      MealGroup.dinner,
      MealGroup.other,
    ];
    return [
      for (final g in order)
        if (map[g]?.isNotEmpty ?? false) (g, map[g]!),
    ];
  }
}
