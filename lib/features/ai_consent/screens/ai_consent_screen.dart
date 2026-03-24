import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/ai_consent/ai_consent_provider.dart';
import '../../../core/analytics/analytics_service.dart';

class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.aiConsentScreenOpened();
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    final title = isRu ? 'Обработка данных ИИ' : 'AI Data Processing';
    final subtitle = isRu
        ? 'Для работы функций распознавания еды'
        : 'Required for food recognition features';
    final row1 = isRu ? 'Голосовые описания и фото блюд' : 'Voice descriptions and meal photos';
    final row2 = isRu ? 'Данные отправляются в Anthropic (Claude)' : 'Data is sent to Anthropic (Claude)';
    final row3 = isRu ? 'Не используются для обучения модели' : 'Never used for model training';
    final checkboxLabel = isRu ? 'Я согласен(а) с передачей данных' : 'I agree to the data transfer';
    final acceptLabel = isRu ? 'Принять и продолжить' : 'Accept & Continue';
    final declineLabel = isRu
        ? 'Отказаться (ИИ-функции будут недоступны)'
        : 'Decline (AI features will be unavailable)';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Hero icon ────────────────────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),

              const SizedBox(height: 24),

              // ── Title & subtitle ─────────────────────────────────────────
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── Info card ────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadow.sm,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _BenefitRow(
                      icon: Icons.mic_rounded,
                      color: const Color(0xFF7C3AED),
                      text: row1,
                    ),
                    const SizedBox(height: 16),
                    _BenefitRow(
                      icon: Icons.send_rounded,
                      color: const Color(0xFF3B82F6),
                      text: row2,
                    ),
                    const SizedBox(height: 16),
                    _BenefitRow(
                      icon: Icons.shield_rounded,
                      color: const Color(0xFF16A34A),
                      text: row3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Checkbox row ─────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  final next = !_checked;
                  AnalyticsService.aiConsentCheckboxToggled(next);
                  setState(() => _checked = next);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _checked
                            ? const Color(0xFF7C3AED)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _checked
                              ? const Color(0xFF7C3AED)
                              : AppColors.textMuted,
                          width: 1.5,
                        ),
                      ),
                      child: _checked
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        checkboxLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Accept button ────────────────────────────────────────────
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _checked ? 1.0 : 0.4,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: _checked
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.35),
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
                        onTap: _checked ? _onAccept : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Center(
                          child: Text(
                            acceptLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Decline button ───────────────────────────────────────────
              TextButton(
                onPressed: _onDecline,
                child: Text(
                  declineLabel,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAccept() async {
    AnalyticsService.aiConsentAccepted();
    await ref.read(aiConsentProvider.notifier).setConsent(true);
    if (mounted) context.go('/');
  }

  Future<void> _onDecline() async {
    AnalyticsService.aiConsentDeclined();
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(isRu ? 'Вы уверены?' : 'Are you sure?'),
        content: Text(
          isRu
              ? 'Без согласия вы не сможете использовать добавление блюд и чат с ИИ.'
              : 'Without consent you won\'t be able to use meal adding or AI chat.',
          style: const TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isRu ? 'Отмена' : 'Cancel',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              isRu ? 'Отказаться' : 'Decline anyway',
              style: const TextStyle(color: AppColors.accentOver),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      AnalyticsService.aiConsentDeclineConfirmed();
      await ref.read(aiConsentProvider.notifier).setConsent(false);
      if (mounted) context.go('/');
    }
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.text,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
