import 'package:flutter/material.dart';
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

const _compulsiveEmotions = {'anxious', 'sad', 'bored', 'angry', 'worried', 'neutral', 'other'};

class MealItem extends StatelessWidget {
  final Meal meal;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const MealItem({super.key, required this.meal, this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final emotion = meal.emotion;
    final emoji = emotion != null ? _emotionEmojis[emotion] : null;
    final isCompulsive = emotion != null && _compulsiveEmotions.contains(emotion);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
        border: isCompulsive
            ? Border.all(color: AppColors.accentOver.withValues(alpha:0.3), width: 1)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                if (emoji != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompulsive ? AppColors.accentOverSoft : AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.restaurant_rounded, size: 20, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _MacroPill(
                            value: meal.calories.toStringAsFixed(0),
                            suffix: ' ${l10n.macro_kcal}',
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          _MacroPill(value: '${l10n.macro_protein[0]} ${meal.protein.toStringAsFixed(0)}${l10n.macro_g}', color: AppColors.accent),
                          const SizedBox(width: 4),
                          _MacroPill(value: '${l10n.macro_fat[0]} ${meal.fat.toStringAsFixed(0)}${l10n.macro_g}', color: AppColors.warm),
                          const SizedBox(width: 4),
                          _MacroPill(value: '${l10n.macro_carbs[0]} ${meal.carbs.toStringAsFixed(0)}${l10n.macro_g}', color: AppColors.support),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.common_edit)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.common_delete,
                          style: const TextStyle(color: AppColors.accentOver)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String value;
  final String suffix;
  final Color color;

  const _MacroPill({required this.value, this.suffix = '', required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value$suffix',
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
