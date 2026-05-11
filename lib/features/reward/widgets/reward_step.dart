import 'package:flutter/material.dart';

import 'package:kayfit/features/reward/i18n/reward_strings.dart';
import 'package:kayfit/features/reward/reward_prefs.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

/// Onboarding step content widget — single-select reward picker.
///
/// Inline content (no Scaffold) — embedded inside [OnboardingScaffold] body
/// alongside the global header/footer. CTA in the scaffold footer is
/// enabled only when [value] is non-null.
class RewardStep extends StatelessWidget {
  const RewardStep({
    super.key,
    required this.value,
    required this.onChange,
    required this.isRu,
  });

  /// One of [RewardPrefs.options] or `null` while nothing is picked.
  final String? value;
  final ValueChanged<String> onChange;
  final bool isRu;

  static const _images = {
    'clothes': 'assets/onboarding/reward-1.png',
    'travel': 'assets/onboarding/reward-2.png',
    'event': 'assets/onboarding/reward-3.png',
    'gift': 'assets/onboarding/reward-4.png',
  };

  static const _fallbackIcons = {
    'clothes': Icons.checkroom_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'event': Icons.celebration_rounded,
    'gift': Icons.card_giftcard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RewardStrings.question(isRu),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RewardStrings.subtitle(isRu),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          for (final key in RewardPrefs.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RewardCard(
                isSelected: value == key,
                imageAsset: _images[key] ?? '',
                fallbackIcon: _fallbackIcons[key] ?? Icons.star_rounded,
                label: RewardStrings.optionLabel(key, isRu),
                onTap: () => onChange(key),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.isSelected,
    required this.imageAsset,
    required this.fallbackIcon,
    required this.label,
    required this.onTap,
  });

  final bool isSelected;
  final String imageAsset;
  final IconData fallbackIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? OBColors.pinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? OBColors.pink : OBColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imageAsset,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    fallbackIcon,
                    size: 24,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: OBColors.pink,
              ),
          ],
        ),
      ),
    );
  }
}
