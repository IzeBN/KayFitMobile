import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

class AiConsentSheet {
  /// Returns true if consent was given (accepted), false if declined/dismissed.
  static Future<bool> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('ai_consent_given') == true) return true;

    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _AiConsentSheet(),
    );
    return result == true;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _AiConsentSheet extends StatefulWidget {
  const _AiConsentSheet();

  @override
  State<_AiConsentSheet> createState() => _AiConsentSheetState();
}

class _AiConsentSheetState extends State<_AiConsentSheet>
    with SingleTickerProviderStateMixin {
  bool _checked = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeAnim = CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: Curves.easeOutCubic,
    ));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAccept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_consent_given', true);
    if (mounted) Navigator.pop(context, true);
  }

  void _onDecline() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _DragHandle(),

              const SizedBox(height: 8),

              // Header icon badge
              _GradientIconBadge(),

              const SizedBox(height: 16),

              // Title
              Text(
                isRu ? 'Обработка данных ИИ' : 'AI Data Processing',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Body text
              Text(
                'For food recognition the app sends your food description (voice, photo, text) to Anthropic (Claude). Data is used for analysis only and is not stored for model training.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Checkbox row
              _CheckboxRow(
                checked: _checked,
                isRu: isRu,
                onChanged: (val) => setState(() => _checked = val),
              ),

              const SizedBox(height: 14),

              // Info row
              _InfoRow(),

              const SizedBox(height: 24),

              // Accept button
              _AcceptButton(
                enabled: _checked,
                isRu: isRu,
                onTap: _onAccept,
              ),

              const SizedBox(height: 10),

              // Decline link
              TextButton(
                onPressed: _onDecline,
                child: Text(
                  isRu ? 'Не сейчас' : 'Not now',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drag handle
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 4),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient icon badge
// ─────────────────────────────────────────────────────────────────────────────

class _GradientIconBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            blurRadius: 32,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: Colors.white,
        size: 36,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated checkbox row
// ─────────────────────────────────────────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  final bool checked;
  final bool isRu;
  final ValueChanged<bool> onChanged;

  const _CheckboxRow({
    required this.checked,
    required this.isRu,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated checkbox
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: checked
                  ? const Color(0xFF7C3AED)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: checked
                    ? const Color(0xFF7C3AED)
                    : AppColors.textMuted,
                width: 1.8,
              ),
              boxShadow: checked
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedOpacity(
              opacity: checked ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Label
          Expanded(
            child: Text(
              'I agree to send food data to Anthropic (Claude) for recognition',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.text,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 5),
        const Text(
          'Service: Anthropic API (Claude)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Accept button
// ─────────────────────────────────────────────────────────────────────────────

class _AcceptButton extends StatelessWidget {
  final bool enabled;
  final bool isRu;
  final VoidCallback onTap;

  const _AcceptButton({
    required this.enabled,
    required this.isRu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(
                child: Text(
                  isRu ? 'Продолжить' : 'Continue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
