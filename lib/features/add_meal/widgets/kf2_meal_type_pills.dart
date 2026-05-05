import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/theme/kayfit2_theme.dart';

/// Horizontal row of pill tabs for selecting the meal type.
///
/// Active pill: bg = [K2Colors.accent], text = white.
/// Inactive pill: border 1 px [K2Theme.border], text = [K2Theme.fg].
class KF2MealTypePills extends StatelessWidget {
  const KF2MealTypePills({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final K2Theme theme;

  static const _options = [
    ('breakfast', 'Breakfast'),
    ('lunch', 'Lunch'),
    ('dinner', 'Dinner'),
    ('snack', 'Snack'),
    ('other', 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          for (final (value, label) in _options) ...[
            _Pill(
              label: label,
              isActive: selected == value,
              theme: theme,
              onTap: () {
                if (selected != value) {
                  HapticFeedback.selectionClick();
                  onChanged(value);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final K2Theme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? K2Colors.accent : Colors.transparent,
          border: Border.all(
            color: isActive ? K2Colors.accent : theme.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: K2Fonts.sans,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : theme.fg,
          ),
        ),
      ),
    );
  }
}
