import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays extended nutrient values as chips in a Wrap layout.
/// Only shows nutrients with non-null, non-zero values.
///
/// Units:
/// - fiber, sugar, sugarAlcohols, netCarbs, saturatedFat, unsaturatedFat → grams
/// - sodiumMg, cholesterolMg, potassiumMg → milligrams (pass raw mg values)
/// - glycemicIndex → number + low/med/high badge
class ExtendedNutrientsGrid extends StatelessWidget {
  final double? fiber;
  final double? sugar;
  final double? sugarAlcohols;
  final double? netCarbs;
  final double? saturatedFat;
  final double? unsaturatedFat;
  final double? sodiumMg;
  final double? cholesterolMg;
  final double? potassiumMg;
  final int? glycemicIndex;
  final String? glycemicIndexCategory;

  const ExtendedNutrientsGrid({
    super.key,
    this.fiber,
    this.sugar,
    this.sugarAlcohols,
    this.netCarbs,
    this.saturatedFat,
    this.unsaturatedFat,
    this.sodiumMg,
    this.cholesterolMg,
    this.potassiumMg,
    this.glycemicIndex,
    this.glycemicIndexCategory,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (fiber != null && fiber! > 0)
        _NutrientChip(
          label: 'Fiber',
          value: fiber!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.fiber,
          bg: NutrientColors.fiberSoft,
        ),
      if (netCarbs != null && netCarbs! > 0)
        _NutrientChip(
          label: 'Net carbs',
          value: netCarbs!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.netCarbs,
          bg: NutrientColors.netCarbsSoft,
        ),
      if (sugar != null && sugar! > 0)
        _NutrientChip(
          label: 'Sugar',
          value: sugar!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.sugar,
          bg: NutrientColors.sugarSoft,
        ),
      if (sugarAlcohols != null && sugarAlcohols! > 0)
        _NutrientChip(
          label: 'Sugar alc.',
          value: sugarAlcohols!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.sugar,
          bg: NutrientColors.sugarSoft,
        ),
      if (saturatedFat != null && saturatedFat! > 0)
        _NutrientChip(
          label: 'Sat. fat',
          value: saturatedFat!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.fatBad,
          bg: NutrientColors.fatBadSoft,
        ),
      if (unsaturatedFat != null && unsaturatedFat! > 0)
        _NutrientChip(
          label: 'Unsat. fat',
          value: unsaturatedFat!.toStringAsFixed(1),
          unit: 'g',
          color: NutrientColors.fatGood,
          bg: NutrientColors.fatGoodSoft,
        ),
      if (sodiumMg != null && sodiumMg! > 0)
        _NutrientChip(
          label: 'Sodium',
          value: sodiumMg!.toStringAsFixed(0),
          unit: 'mg',
          color: AppColors.textMuted,
          bg: NutrientColors.bg,
        ),
      if (cholesterolMg != null && cholesterolMg! > 0)
        _NutrientChip(
          label: 'Cholesterol',
          value: cholesterolMg!.toStringAsFixed(0),
          unit: 'mg',
          color: AppColors.textMuted,
          bg: NutrientColors.bg,
        ),
      if (potassiumMg != null && potassiumMg! > 0)
        _NutrientChip(
          label: 'Potassium',
          value: potassiumMg!.toStringAsFixed(0),
          unit: 'mg',
          color: AppColors.textMuted,
          bg: NutrientColors.bg,
        ),
      if (glycemicIndex != null) _GiBadgeChip(gi: glycemicIndex!),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _NutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bg;

  const _NutrientChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '$value $unit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiBadgeChip extends StatelessWidget {
  final int gi;
  const _GiBadgeChip({required this.gi});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (gi < 55) {
      color = AppColors.accent;
      label = 'Low GI';
    } else if (gi < 70) {
      color = AppColors.warm;
      label = 'Med GI';
    } else {
      color = AppColors.accentOver;
      label = 'High GI';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label $gi',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
