import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

const _mealTypes = [
  ('breakfast', '🌅', 'Breakfast'),
  ('lunch', '☀️', 'Lunch'),
  ('dinner', '🌙', 'Dinner'),
  ('snack', '🍎', 'Snack'),
];

class MealTypePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const MealTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _mealTypes.map((t) {
        final isActive = t.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(t.$1);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                  right: t.$1 != _mealTypes.last.$1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? NutrientColors.netCarbsSoft
                    : NutrientColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? NutrientColors.netCarbs
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(t.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text(
                    t.$3,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? NutrientColors.netCarbs
                          : NutrientColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
