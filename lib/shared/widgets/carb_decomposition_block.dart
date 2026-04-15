import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows the carb decomposition formula + detail rows + net carbs highlight.
/// Total — Fiber — Sugar Alcohols = Net Carbs
class CarbDecompositionBlock extends StatelessWidget {
  final double totalCarbs;
  final double fiber;
  final double sugarAlcohols;
  final double sugar;
  final double netCarbs;
  final int? glycemicIndex;

  const CarbDecompositionBlock({
    super.key,
    required this.totalCarbs,
    required this.fiber,
    required this.sugarAlcohols,
    required this.sugar,
    required this.netCarbs,
    this.glycemicIndex,
  });

  @override
  Widget build(BuildContext context) {
    // GI color
    Color giColor;
    String giLabel;
    if (glycemicIndex == null) {
      giColor = NutrientColors.tertiary;
      giLabel = '—';
    } else if (glycemicIndex! <= 55) {
      giColor = NutrientColors.netCarbs;
      giLabel = 'low';
    } else if (glycemicIndex! <= 69) {
      giColor = const Color(0xFFB8860B);
      giLabel = 'medium';
    } else {
      giColor = const Color(0xFFC0392B);
      giLabel = 'high';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NutrientColors.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formula line
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: NutrientColors.secondary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Roboto',
              ),
              children: [
                const TextSpan(text: 'Total '),
                TextSpan(
                  text: '${totalCarbs.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
                const TextSpan(text: ' — Fiber '),
                TextSpan(
                  text: '${fiber.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
                const TextSpan(text: ' — Alcohols '),
                TextSpan(
                  text: '${sugarAlcohols.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A)),
                ),
                const TextSpan(text: ' = '),
                TextSpan(
                  text: 'Net ${netCarbs.toStringAsFixed(1)}g',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: NutrientColors.netCarbs,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Detail rows
          _Row('Total carbs', '${totalCarbs.toStringAsFixed(1)} g'),
          _Row('  Fiber', '${fiber.toStringAsFixed(1)} g'),
          _Row('  Sugar', '${sugar.toStringAsFixed(1)} g',
              valueColor: NutrientColors.sugar),
          _Row('  Sugar alcohols', '${sugarAlcohols.toStringAsFixed(1)} g'),

          // Net carbs highlight
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: NutrientColors.netCarbsSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Carbs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NutrientColors.netCarbs,
                  ),
                ),
                Text(
                  '${netCarbs.toStringAsFixed(1)} g',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: NutrientColors.netCarbs,
                  ),
                ),
              ],
            ),
          ),

          // GI scale
          if (glycemicIndex != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'GI $glycemicIndex',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: giColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: CustomPaint(
                        painter: _GiBarPainter(
                          value: glycemicIndex!,
                          markerColor: giColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  giLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: NutrientColors.tertiary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String name;
  final String value;
  final Color? valueColor;

  const _Row(this.name, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: TextStyle(
                  fontSize: 12, color: NutrientColors.secondary)),
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF1A1A1A),
              )),
        ],
      ),
    );
  }
}

class _GiBarPainter extends CustomPainter {
  final int value;
  final Color markerColor;

  _GiBarPainter({required this.value, required this.markerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;

    // Green zone (0-55)
    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, w * 0.55, h, Radius.circular(3)),
      Paint()..color = NutrientColors.netCarbs,
    );
    // Yellow zone (55-70)
    canvas.drawRect(
      Rect.fromLTRB(w * 0.55 + 1, 0, w * 0.70, h),
      Paint()..color = const Color(0xFFEAB308),
    );
    // Red zone (70-100)
    canvas.drawRRect(
      RRect.fromLTRBR(w * 0.70 + 1, 0, w, h, Radius.circular(3)),
      Paint()..color = const Color(0xFFDC2626),
    );

    // Marker
    final pos = (value / 100.0).clamp(0.0, 1.0) * w;
    canvas.drawCircle(
      Offset(pos, h / 2),
      6,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(pos, h / 2),
      5,
      Paint()..color = markerColor,
    );
  }

  @override
  bool shouldRepaint(covariant _GiBarPainter old) =>
      old.value != value || old.markerColor != markerColor;
}
