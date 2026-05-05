import 'package:flutter/material.dart';

import '../../../shared/models/nutrients_v2.dart';
import '../../../shared/theme/kayfit2_theme.dart';

/// Hero section that displays the total kcal in a large JetBrains Mono
/// typeface, followed by a P·F·C summary line.
class KF2HeroTotal extends StatelessWidget {
  const KF2HeroTotal({
    super.key,
    required this.totals,
    required this.theme,
  });

  final NutrientsV2 totals;
  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    final kcal = totals.calories.toStringAsFixed(0);
    final p = totals.protein.toStringAsFixed(0);
    final f = totals.fat.toStringAsFixed(0);
    final c = totals.carbs.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL',
            style: TextStyle(
              fontFamily: K2Fonts.sans,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.fgMute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$kcal kcal',
            style: TextStyle(
              fontFamily: K2Fonts.mono,
              fontSize: 56,
              fontWeight: FontWeight.w500,
              letterSpacing: -2.5,
              height: 1,
              color: theme.fg,
            ),
          ),
          const SizedBox(height: 6),
          _MacroSubline(p: p, f: f, c: c, theme: theme),
        ],
      ),
    );
  }
}

class _MacroSubline extends StatelessWidget {
  const _MacroSubline({
    required this.p,
    required this.f,
    required this.c,
    required this.theme,
  });

  final String p;
  final String f;
  final String c;
  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Macro(label: 'P', value: p, theme: theme),
        _Dot(theme: theme),
        _Macro(label: 'F', value: f, theme: theme),
        _Dot(theme: theme),
        _Macro(label: 'C', value: c, theme: theme),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label ${value}g',
      style: TextStyle(
        fontFamily: K2Fonts.mono,
        fontSize: 13,
        color: theme.fgDim,
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.theme});

  final K2Theme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontFamily: K2Fonts.mono,
          fontSize: 13,
          color: theme.fgMute,
        ),
      ),
    );
  }
}
