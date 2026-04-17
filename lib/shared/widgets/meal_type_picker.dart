import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

const _mealTypeKeys = [
  ('breakfast', Icons.wb_sunny_outlined),
  ('lunch', Icons.restaurant_menu_rounded),
  ('dinner', Icons.dinner_dining_rounded),
  ('snack', Icons.cookie_outlined),
  ('other', Icons.more_horiz_rounded),
];

String _mealTypeLabel(BuildContext context, String key) {
  final isRu = Localizations.localeOf(context).languageCode == 'ru';
  return switch (key) {
    'breakfast' => isRu ? 'Завтрак' : 'Breakfast',
    'lunch'     => isRu ? 'Обед'    : 'Lunch',
    'dinner'    => isRu ? 'Ужин'    : 'Dinner',
    'snack'     => isRu ? 'Перекус' : 'Snack',
    _           => isRu ? 'Другое'  : 'Other',
  };
}

class MealTypePicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onChanged;

  const MealTypePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _mealTypeKeys.asMap().entries.map((e) {
        final i = e.key;
        final (key, icon) = e.value;
        final isActive = key == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(key);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < _mealTypeKeys.length - 1 ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? NutrientColors.netCarbsSoft : NutrientColors.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? NutrientColors.netCarbs : AppColors.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isActive ? NutrientColors.netCarbs : AppColors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mealTypeLabel(context, key),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isActive ? NutrientColors.netCarbs : NutrientColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
