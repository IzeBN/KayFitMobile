import 'package:flutter/material.dart';
import 'package:kayfit/shared/theme/app_theme.dart';

/// Beautiful bottom sheet that explains notification value to the user before
/// requesting the actual OS permission.
///
/// Usage:
/// ```dart
/// await showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => NotificationPromoSheet(
///     onAllow: () => NotificationService._requestPermissions(),
///   ),
/// );
/// ```
class NotificationPromoSheet extends StatefulWidget {
  final VoidCallback onAllow;
  final VoidCallback? onDismiss;

  const NotificationPromoSheet({
    super.key,
    required this.onAllow,
    this.onDismiss,
  });

  @override
  State<NotificationPromoSheet> createState() => _NotificationPromoSheetState();
}

class _NotificationPromoSheetState extends State<NotificationPromoSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    final title = isRu
        ? 'Напоминания помогают достигать целей'
        : 'Stay on track with reminders';
    final allowBtn = isRu ? 'Разрешить уведомления' : 'Allow notifications';
    final notNow = isRu ? 'Не сейчас' : 'Not now';

    final benefits = isRu
        ? [
            (Icons.restaurant_rounded, 'Напоминание внести приём пищи'),
            (Icons.local_fire_department_rounded, 'Уведомления о ваших успехах'),
            (Icons.lightbulb_outline_rounded, 'Советы по питанию от ИИ'),
          ]
        : [
            (Icons.restaurant_rounded, 'Meal logging reminders'),
            (Icons.local_fire_department_rounded, 'Notifications about your achievements'),
            (Icons.lightbulb_outline_rounded, 'AI nutrition tips'),
          ];

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: child,
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),

            // Bell icon in green gradient circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accentDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.4,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 28),

            // Benefit rows
            ...benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(b.$1, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        b.$2,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Allow button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAllow();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(allowBtn),
              ),
            ),

            const SizedBox(height: 12),

            // Not now link
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                widget.onDismiss?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  notNow,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
