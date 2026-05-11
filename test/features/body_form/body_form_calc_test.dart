import 'package:flutter_test/flutter_test.dart';
import 'package:kayfit/features/body_form/body_form_calc.dart';

void main() {
  group('kBodyFatByIndex', () {
    test('covers indices 0..6 with the expected fat percentages', () {
      const expected = {
        0: 5.0,
        1: 8.5,
        2: 13.0,
        3: 19.5,
        4: 27.0,
        5: 35.5,
        6: 45.0,
      };
      expect(kBodyFatByIndex.length, 7);
      for (final entry in expected.entries) {
        expect(
          kBodyFatByIndex[entry.key],
          entry.value,
          reason: 'fat for index ${entry.key}',
        );
      }
    });
  });

  group('kBodyImagesMale / kBodyImagesFemale', () {
    test('each list contains exactly 7 unique asset paths', () {
      expect(kBodyImagesMale.length, 7);
      expect(kBodyImagesFemale.length, 7);
      expect(kBodyImagesMale.toSet().length, 7);
      expect(kBodyImagesFemale.toSet().length, 7);
    });

    test('male and female sets do not overlap', () {
      final overlap = kBodyImagesMale.toSet().intersection(
        kBodyImagesFemale.toSet(),
      );
      expect(overlap, isEmpty);
    });
  });

  group('calcTargetWeight — slimming goal (desired < current)', () {
    test('80 kg, current=4 (27%), desired=0 (5%) → ≈ leanMass / 0.95', () {
      const cw = 80.0;
      const cf = 27.0;
      const df = 5.0;
      final leanMass = cw * (1 - cf / 100);
      final raw = leanMass / (1 - df / 100);
      final expected = raw.clamp(30.0, cw - 0.5);
      final result = calcTargetWeight(
        currentWeight: cw,
        currentIndex: 4,
        desiredIndex: 0,
      );
      expect(result, isNotNull);
      expect(result, closeTo(expected, 0.01));
    });

    for (var i = 0; i < 6; i++) {
      test('returns a value when current=6 (45%), desired=$i', () {
        final result = calcTargetWeight(
          currentWeight: 90.0,
          currentIndex: 6,
          desiredIndex: i,
        );
        expect(result, isNotNull);
        expect(result, lessThan(90.0));
      });
    }

    test('result is clamped below currentWeight - 0.5', () {
      final result = calcTargetWeight(
        currentWeight: 70.0,
        currentIndex: 5,
        desiredIndex: 4,
      );
      expect(result, isNotNull);
      expect(result, lessThanOrEqualTo(69.5));
    });

    test('result never goes below 30 kg', () {
      final result = calcTargetWeight(
        currentWeight: 80.0,
        currentIndex: 6,
        desiredIndex: 0,
      );
      if (result != null) {
        expect(result, greaterThanOrEqualTo(30.0));
      }
    });
  });

  group('calcTargetWeight — non-slimming inputs return null', () {
    test('null when desired equals current', () {
      expect(
        calcTargetWeight(currentWeight: 70.0, currentIndex: 2, desiredIndex: 2),
        isNull,
      );
    });

    test('null when desired is heavier than current (gain)', () {
      expect(
        calcTargetWeight(currentWeight: 70.0, currentIndex: 2, desiredIndex: 5),
        isNull,
      );
    });

    test('null when an index is out of range', () {
      expect(
        calcTargetWeight(
          currentWeight: 70.0,
          currentIndex: -1,
          desiredIndex: 0,
        ),
        isNull,
      );
      expect(
        calcTargetWeight(currentWeight: 70.0, currentIndex: 0, desiredIndex: 7),
        isNull,
      );
    });

    test('null when current weight is non-positive', () {
      expect(
        calcTargetWeight(currentWeight: 0, currentIndex: 6, desiredIndex: 0),
        isNull,
      );
    });

    test('null when currentWeight too low to be clamp-safe', () {
      // Upper clamp bound becomes 30.0 - 0.5 = 29.5 < 30 → null.
      expect(
        calcTargetWeight(currentWeight: 30.0, currentIndex: 6, desiredIndex: 0),
        isNull,
      );
    });
  });
}
