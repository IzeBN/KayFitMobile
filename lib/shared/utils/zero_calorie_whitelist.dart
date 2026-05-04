// Frontend mirror of the backend zero-calorie whitelist.
//
// Backend source of truth: `zero_calorie_whitelist.py` (POST /api/meals applies
// it server-side). This list is the local guard that runs on the result of
// `/api/v2/parse_meal_suggestions` — covers the case where the AI returns
// nutrients > 0 for a known zero-calorie item (e.g. plain water).
//
// Only exact-name + simple-prefix matches; intentionally narrow to avoid
// false positives.

const _kZeroCalorieExact = <String>{
  // English
  'water', 'plain water', 'still water', 'tap water', 'mineral water',
  'sparkling water', 'soda water', 'club soda', 'seltzer',
  'ice', 'ice cube', 'ice cubes',
  'black coffee', 'coffee black',
  'tea', 'green tea', 'black tea', 'herbal tea',
  // Russian
  'вода', 'минералка', 'минеральная вода', 'газировка', 'газированная вода',
  'кипячёная вода', 'кипяченая вода', 'тёплая вода', 'теплая вода',
  'лёд', 'лед',
  'чёрный кофе', 'черный кофе',
  'чай', 'зелёный чай', 'зеленый чай', 'чёрный чай', 'черный чай',
  'травяной чай',
};

const _kZeroCaloriePrefixes = <String>[
  'water ', 'sparkling water ',
  'вода ', 'минеральная вода ',
];

/// Returns true if [name] is on the zero-calorie list (case-insensitive,
/// trimmed). Used as a guard before mapping API results to model.
bool isZeroCalorieName(String? name) {
  if (name == null) return false;
  final n = name.trim().toLowerCase();
  if (n.isEmpty) return false;
  if (_kZeroCalorieExact.contains(n)) return true;
  for (final p in _kZeroCaloriePrefixes) {
    if (n.startsWith(p)) return true;
  }
  return false;
}
