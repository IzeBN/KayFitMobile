import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../providers/way_to_goal_provider.dart';

class WayToGoalScreen extends ConsumerWidget {
  const WayToGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(calculationResultProvider);

    return Scaffold(
      backgroundColor: OBColors.bg,
      body: result.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(calculationResultProvider),
        ),
        data: (calc) => _ResultView(calc: calc),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final dynamic calc;
  const _ResultView({required this.calc});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          const SizedBox(height: 24),
          // Hero gradient card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: OBColors.gradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: OBColors.buttonShadow,
            ),
            child: Column(
              children: [
                const Text(
                  '🎯',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ваш план готов!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Персональный расчёт на основе ваших данных',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${calc.targetCalories.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: OBColors.pink,
                          height: 1,
                          letterSpacing: -2,
                        ),
                      ),
                      const Text(
                        'ккал / день',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Macros card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Макронутриенты',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MacroChip(label: 'Белки', value: calc.protein, color: AppColors.accent, bgColor: AppColors.accentSoft),
                    const SizedBox(width: 8),
                    _MacroChip(label: 'Жиры', value: calc.fat, color: AppColors.warm, bgColor: AppColors.warmSoft),
                    const SizedBox(width: 8),
                    _MacroChip(label: 'Углеводы', value: calc.carbs, color: AppColors.support, bgColor: AppColors.supportSoft),
                  ],
                ),
              ],
            ),
          ),

          if (calc.daysToGoal != null || calc.targetWeight != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  if (calc.daysToGoal != null)
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      text: 'До цели: ${calc.daysToGoal} дней',
                    ),
                  if (calc.daysToGoal != null && calc.targetWeight != null)
                    const SizedBox(height: 10),
                  if (calc.targetWeight != null)
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      text: 'Целевой вес: ${calc.targetWeight!.toStringAsFixed(1)} кг',
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // How it works card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Как достичь цели',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
                ),
                const SizedBox(height: 14),
                _FeatureRow(emoji: '📸', title: 'Фото блюда', desc: 'Сфотографируйте еду — ИИ распознает калории за секунды'),
                const SizedBox(height: 12),
                _FeatureRow(emoji: '🎤', title: 'Голосовой ввод', desc: 'Продиктуйте, что съели — приложение запишет'),
                const SizedBox(height: 12),
                _FeatureRow(emoji: '📊', title: 'Трекинг прогресса', desc: 'Следите за КБЖУ и видьте результат каждый день'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // CTA button
          GestureDetector(
            onTap: () => context.go('/'),
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                gradient: OBColors.gradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: OBColors.buttonShadow,
              ),
              alignment: Alignment.center,
              child: const Text(
                'Начать вести дневник',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final Color bgColor;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '${value.toStringAsFixed(0)}г',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;

  const _FeatureRow({required this.emoji, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: OBColors.pinkSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: OBColors.pink),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 15, color: AppColors.text)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.accentOver),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: OBColors.gradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Повторить', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
