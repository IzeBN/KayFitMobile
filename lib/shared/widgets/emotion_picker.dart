import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

const _emotions = [
  ('😊', 'happy'),
  ('😌', 'calm'),
  ('😔', 'sad'),
  ('😰', 'anxious'),
  ('😴', 'tired'),
  ('🤤', 'hungry'),
  ('😑', 'bored'),
  ('😠', 'angry'),
  ('😟', 'worried'),
  ('😐', 'neutral'),
  ('💬', 'other'),
];

class EmotionPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const EmotionPicker({super.key, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _emotions.map((e) {
        final isSelected = selected == e.$2;
        return GestureDetector(
          onTap: () => onSelect(e.$2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentSoft : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(e.$1, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }
}
