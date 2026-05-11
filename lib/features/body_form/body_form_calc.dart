/// Pure calculation helpers for the BodyForm feature.
///
/// Exposes the body-fat % mapping (0-based indices 0..6) and a target-weight
/// calculator used by both [BodyFormScreen] and onboarding.
library;

/// Body-fat % per slider index (0-based).
///
/// Source: FitKeep `way_to_goal_screen.dart::_bodyFatMap` (1-based there,
/// shifted to 0-based here).
const Map<int, double> kBodyFatByIndex = {
  0: 5.0,
  1: 8.5,
  2: 13.0,
  3: 19.5,
  4: 27.0,
  5: 35.5,
  6: 45.0,
};

/// Computes the target weight that corresponds to moving from
/// [currentIndex] (current body shape) to [desiredIndex] (desired body
/// shape) given the user's [currentWeight] in kg.
///
/// Returns `null` when:
///   * either index is outside 0..6
///   * desiredIndex >= currentIndex (no slimming target)
///
/// Formula:
///   leanMass     = currentWeight * (1 - currentFat / 100)
///   targetWeight = leanMass / (1 - desiredFat / 100)
/// Result is clamped to `[30.0, currentWeight - 0.5]` to avoid float-equal
/// edge cases and absurdly low values.
double? calcTargetWeight({
  required double currentWeight,
  required int currentIndex,
  required int desiredIndex,
}) {
  final currentFat = kBodyFatByIndex[currentIndex];
  final desiredFat = kBodyFatByIndex[desiredIndex];
  if (currentFat == null || desiredFat == null) return null;
  if (desiredIndex >= currentIndex) return null;
  if (currentWeight <= 0) return null;

  final leanMass = currentWeight * (1 - currentFat / 100);
  final raw = leanMass / (1 - desiredFat / 100);
  final upper = currentWeight - 0.5;
  if (upper < 30.0) return null;
  return raw.clamp(30.0, upper);
}

/// Male body-shape image paths (slider index 0..6).
const List<String> kBodyImagesMale = [
  'assets/onboarding/body-form-1.jpg',
  'assets/onboarding/body-form-2.jpg',
  'assets/onboarding/body-form-3.jpg',
  'assets/onboarding/body-form-4.jpg',
  'assets/onboarding/body-form-5.jpg',
  'assets/onboarding/body-form-6.jpg',
  'assets/onboarding/body-form-7.jpg',
];

/// Female body-shape image paths (slider index 0..6).
const List<String> kBodyImagesFemale = [
  'assets/onboarding/body-form-girl-1.jpg',
  'assets/onboarding/body-form-girl-2.jpg',
  'assets/onboarding/body-form-girl-3.jpg',
  'assets/onboarding/body-form-girl-4.jpg',
  'assets/onboarding/body-form-girl-5.jpg',
  'assets/onboarding/body-form-girl-6.jpg',
  'assets/onboarding/body-form-girl-7.jpg',
];
