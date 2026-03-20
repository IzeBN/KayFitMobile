import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../shared/models/stats.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StatsCard — animated circular calorie ring + animated macro bars
// ─────────────────────────────────────────────────────────────────────────────

class StatsCard extends StatefulWidget {
  final MacroStats stats;
  const StatsCard({super.key, required this.stats});

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _updateAnimation();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(StatsCard old) {
    super.didUpdateWidget(old);
    if (old.stats != widget.stats) {
      _updateAnimation();
      _ctrl
        ..reset()
        ..forward();
    }
  }

  void _updateAnimation() {
    final ratio = widget.stats.caloriesGoal > 0
        ? (widget.stats.caloriesEaten / widget.stats.caloriesGoal).clamp(0.0, 1.2)
        : 0.0;
    _progress = Tween<double>(begin: 0, end: ratio).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = widget.stats;
    final isOver = s.caloriesGoal > 0 && s.caloriesEaten > s.caloriesGoal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.md,
      ),
      child: Column(
        children: [
          // ── Top: ring + numbers ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isOver
                    ? [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)]
                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                // Circular ring
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) => _CalorieRing(
                    progress: _progress.value,
                    isOver: isOver,
                    eaten: s.caloriesEaten,
                    goal: s.caloriesGoal,
                    animValue: _ctrl.value,
                    l10n: l10n,
                  ),
                ),
                const SizedBox(width: 20),
                // Right side stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: l10n.macro_eaten,
                        value: '${s.caloriesEaten.toStringAsFixed(0)} ${l10n.macro_kcal}',
                        color: isOver ? AppColors.accentOver : AppColors.accent,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: isOver ? l10n.dashboard_remaining_over : l10n.macro_remaining,
                        value: '${(s.caloriesGoal - s.caloriesEaten).abs().toStringAsFixed(0)} ${l10n.macro_kcal}',
                        color: isOver ? AppColors.accentOver : AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: l10n.macro_goal,
                        value: '${s.caloriesGoal.toStringAsFixed(0)} ${l10n.macro_kcal}',
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom: macros ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              children: [
                _AnimatedMacro(
                  label: l10n.macro_protein,
                  eaten: s.proteinEaten,
                  goal: s.proteinGoal,
                  color: AppColors.accent,
                  softColor: AppColors.accentSoft,
                  unit: l10n.macro_g,
                  parentCtrl: _ctrl,
                ),
                const SizedBox(width: 8),
                _AnimatedMacro(
                  label: l10n.macro_fat,
                  eaten: s.fatEaten,
                  goal: s.fatGoal,
                  color: AppColors.warm,
                  softColor: AppColors.warmSoft,
                  unit: l10n.macro_g,
                  parentCtrl: _ctrl,
                ),
                const SizedBox(width: 8),
                _AnimatedMacro(
                  label: l10n.macro_carbs,
                  eaten: s.carbsEaten,
                  goal: s.carbsGoal,
                  color: AppColors.support,
                  softColor: AppColors.supportSoft,
                  unit: l10n.macro_g,
                  parentCtrl: _ctrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular ring painter
// ─────────────────────────────────────────────────────────────────────────────

class _CalorieRing extends StatelessWidget {
  final double progress;
  final bool isOver;
  final double eaten;
  final double goal;
  final double animValue;
  final AppLocalizations l10n;

  const _CalorieRing({
    required this.progress,
    required this.isOver,
    required this.eaten,
    required this.goal,
    required this.animValue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final ringColor = isOver ? AppColors.accentOver : AppColors.accent;
    final displayedEaten = (eaten * animValue).toStringAsFixed(0);

    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          trackColor: isOver ? AppColors.accentOverSoft : AppColors.accentSoft,
          fillColor: ringColor,
          overFill: isOver,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayedEaten,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isOver ? AppColors.accentOver : AppColors.text,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.macro_kcal,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final bool overFill;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.overFill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Fill
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row on the right side of the ring
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated macro bar
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedMacro extends StatelessWidget {
  final String label;
  final double eaten;
  final double goal;
  final Color color;
  final Color softColor;
  final String unit;
  final AnimationController parentCtrl;

  const _AnimatedMacro({
    required this.label,
    required this.eaten,
    required this.goal,
    required this.color,
    required this.softColor,
    required this.unit,
    required this.parentCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;
    final widthAnim = Tween<double>(begin: 0, end: ratio).animate(
      CurvedAnimation(parent: parentCtrl, curve: Curves.easeOutCubic),
    );

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: softColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${eaten.toStringAsFixed(0)}/${ goal.toStringAsFixed(0)}$unit',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1,
              ),
            ),
            const SizedBox(height: 7),
            // Animated bar
            LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: [
                  // Track
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: softColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  // Fill
                  AnimatedBuilder(
                    animation: widthAnim,
                    builder: (context, _) => FractionallySizedBox(
                      widthFactor: widthAnim.value,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
