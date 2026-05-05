import 'package:flutter/material.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

/// Primary CTA button for onboarding screens.
///
/// When [onTap] is null the button renders in a disabled (grey) state but
/// remains visible — satisfying the requirement that the user always sees
/// the button even when the field is empty.
class ObGradientButton extends StatelessWidget {
  const ObGradientButton({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  bool get _disabled => onTap == null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: _disabled ? null : OBColors.gradient,
          color: _disabled ? AppColors.border : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: _disabled ? const [] : OBColors.buttonShadow,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _disabled ? AppColors.textMuted : Colors.white,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
