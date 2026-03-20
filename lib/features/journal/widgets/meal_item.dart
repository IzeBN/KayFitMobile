import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/models/meal.dart';
import '../../../shared/theme/app_theme.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';

const _emotionEmojis = {
  'happy': '😊',
  'calm': '😌',
  'sad': '😔',
  'anxious': '😰',
  'tired': '😴',
  'hungry': '🤤',
  'bored': '😑',
  'angry': '😠',
  'worried': '😟',
  'neutral': '😐',
  'other': '💬',
};

const _compulsiveEmotions = {
  'anxious', 'sad', 'bored', 'angry', 'worried', 'neutral', 'other'
};

Color _accentColor(String? emotion) {
  if (emotion == null) return AppColors.accent;
  if (_compulsiveEmotions.contains(emotion)) return AppColors.accentOver;
  if (emotion == 'happy' || emotion == 'calm') return AppColors.accent;
  return AppColors.warm;
}

// ─── Meal Item ──────────────────────────────────────────────────────────────

class MealItem extends StatefulWidget {
  final Meal meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MealItem({
    super.key,
    required this.meal,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<MealItem> createState() => _MealItemState();
}

class _MealItemState extends State<MealItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _showActions(BuildContext context) {
    HapticFeedback.lightImpact();
    _MealActionsSheet.show(
      context,
      meal: widget.meal,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emotion = widget.meal.emotion;
    final emoji = emotion != null ? _emotionEmojis[emotion] : null;
    final isCompulsive =
        emotion != null && _compulsiveEmotions.contains(emotion);
    final accentColor = _accentColor(emotion);

    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.reverse(),
        onTapUp: (_) {
          _pressCtrl.forward();
          widget.onEdit?.call();
        },
        onTapCancel: () => _pressCtrl.forward(),
        onLongPress: () => _showActions(context),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadow.sm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Emoji/icon badge
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isCompulsive
                                  ? AppColors.accentOverSoft
                                  : emoji != null
                                      ? AppColors.accentSoft
                                      : AppColors.bg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: emoji != null
                                ? Text(emoji,
                                    style: const TextStyle(fontSize: 20))
                                : const Icon(Icons.restaurant_rounded,
                                    size: 20, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          // Name + macros
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.meal.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.text,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    _CalChip(
                                      value: widget.meal.calories
                                          .toStringAsFixed(0),
                                      kcal: l10n.macro_kcal,
                                      isOver: isCompulsive,
                                    ),
                                    const SizedBox(width: 8),
                                    _MacroText(
                                      '${l10n.macro_protein[0]} ${widget.meal.protein.toStringAsFixed(0)}${l10n.macro_g}',
                                      AppColors.accent,
                                    ),
                                    const SizedBox(width: 5),
                                    _MacroText(
                                      '${l10n.macro_fat[0]} ${widget.meal.fat.toStringAsFixed(0)}${l10n.macro_g}',
                                      AppColors.warm,
                                    ),
                                    const SizedBox(width: 5),
                                    _MacroText(
                                      '${l10n.macro_carbs[0]} ${widget.meal.carbs.toStringAsFixed(0)}${l10n.macro_g}',
                                      AppColors.support,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Actions button — beautiful dots
                          _DotsButton(onTap: () => _showActions(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Dots button ─────────────────────────────────────────────────────────────

class _DotsButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DotsButton({required this.onTap});

  @override
  State<_DotsButton> createState() => _DotsButtonState();
}

class _DotsButtonState extends State<_DotsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: AppColors.textMuted,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Actions bottom sheet ─────────────────────────────────────────────────────

class _MealActionsSheet extends StatefulWidget {
  final Meal meal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MealActionsSheet({
    required this.meal,
    this.onEdit,
    this.onDelete,
  });

  static void show(
    BuildContext context, {
    required Meal meal,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MealActionsSheet(
        meal: meal,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<_MealActionsSheet> createState() => _MealActionsSheetState();
}

class _MealActionsSheetState extends State<_MealActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _macroCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _macroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);

    _enterCtrl.forward().then((_) => _macroCtrl.forward());
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _macroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final meal = widget.meal;
    final isCompulsive = meal.emotion != null &&
        _compulsiveEmotions.contains(meal.emotion);
    final emoji = meal.emotion != null ? _emotionEmojis[meal.emotion] : null;

    // Macro percentages for visualization
    final total = meal.protein + meal.fat + meal.carbs;
    final proteinPct = total > 0 ? meal.protein / total : 0.0;
    final fatPct = total > 0 ? meal.fat / total : 0.0;
    final carbsPct = total > 0 ? meal.carbs / total : 0.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCompulsive
                              ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                              : [const Color(0xFF16A34A), const Color(0xFF4ADE80)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: (isCompulsive
                                    ? AppColors.accentOver
                                    : AppColors.accent)
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: emoji != null
                          ? Text(emoji, style: const TextStyle(fontSize: 24))
                          : const Icon(Icons.restaurant_rounded,
                              color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meal.calories.toStringAsFixed(0)} ${l10n.macro_kcal}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isCompulsive
                                  ? AppColors.accentOver
                                  : AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Macro visualization ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            _AnimatedBar(
                              fraction: proteinPct,
                              color: AppColors.accent,
                              ctrl: _macroCtrl,
                              delay: 0.0,
                            ),
                            const SizedBox(width: 2),
                            _AnimatedBar(
                              fraction: fatPct,
                              color: AppColors.warm,
                              ctrl: _macroCtrl,
                              delay: 0.15,
                            ),
                            const SizedBox(width: 2),
                            _AnimatedBar(
                              fraction: carbsPct,
                              color: AppColors.support,
                              ctrl: _macroCtrl,
                              delay: 0.30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Macro labels
                    Row(
                      children: [
                        _MacroChip(
                          label: l10n.macro_protein,
                          value:
                              '${meal.protein.toStringAsFixed(1)}${l10n.macro_g}',
                          color: AppColors.accent,
                          bg: AppColors.accentSoft,
                        ),
                        const SizedBox(width: 8),
                        _MacroChip(
                          label: l10n.macro_fat,
                          value:
                              '${meal.fat.toStringAsFixed(1)}${l10n.macro_g}',
                          color: AppColors.warm,
                          bg: AppColors.warmSoft,
                        ),
                        const SizedBox(width: 8),
                        _MacroChip(
                          label: l10n.macro_carbs,
                          value:
                              '${meal.carbs.toStringAsFixed(1)}${l10n.macro_g}',
                          color: AppColors.support,
                          bg: AppColors.supportSoft,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Divider ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Divider(
                    height: 1, color: AppColors.border.withValues(alpha: 0.6)),
              ),

              // ── Action buttons ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Edit button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_rounded,
                        label: l10n.common_edit,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shadowColor: AppColors.accent,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onEdit?.call();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete button
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_rounded,
                        label: l10n.common_delete,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFF87171)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shadowColor: AppColors.accentOver,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDelete?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Safe area padding
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated macro bar ───────────────────────────────────────────────────────

class _AnimatedBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final AnimationController ctrl;
  final double delay;

  const _AnimatedBar({
    required this.fraction,
    required this.color,
    required this.ctrl,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final anim = Tween<double>(begin: 0, end: fraction).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(delay, math.min(delay + 0.6, 1.0),
            curve: Curves.easeOutCubic),
      ),
    );
    return Expanded(
      flex: (fraction * 100).round().clamp(1, 100),
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, __) => FractionallySizedBox(
          widthFactor: anim.value / fraction.clamp(0.001, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Macro chip ───────────────────────────────────────────────────────────────

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
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

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _ctrl.forward();
        },
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _CalChip extends StatelessWidget {
  final String value;
  final String kcal;
  final bool isOver;

  const _CalChip({
    required this.value,
    required this.kcal,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isOver ? AppColors.accentOverSoft : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$value $kcal',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOver ? AppColors.accentOver : AppColors.accent,
        ),
      ),
    );
  }
}

class _MacroText extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroText(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
