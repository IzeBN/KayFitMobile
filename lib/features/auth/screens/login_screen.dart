import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // TODO: enable when configured
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // TODO: enable when configured
import 'package:go_router/go_router.dart';
// TODO: restore when Google/Apple re-enabled:
// import '../../../core/api/api_client.dart';
// import '../../../core/auth/auth_provider.dart';
// import '../../../core/auth/onboarding_sync.dart';
// import '../../../router.dart';
// import '../../../shared/widgets/loading_indicator.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // TODO: re-add _loading, _afterLogin, _saveTokens, _showError when Google/Apple re-enabled

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isRu = locale.languageCode == 'ru';

    return Scaffold(
      backgroundColor: OBColors.bg,
      body: Column(
          children: [
            _buildHeader(context, isRu),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.auth_subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // TODO: enable Google/Apple when configured
                    // _SocialButton(
                    //   icon: Icons.g_mobiledata_rounded,
                    //   label: l10n.auth_google,
                    //   iconColor: const Color(0xFF4285F4),
                    //   borderColor: OBColors.border,
                    //   onTap: _signInGoogle,
                    // ),
                    // const SizedBox(height: 12),
                    // _SocialButton(
                    //   icon: Icons.apple,
                    //   label: l10n.auth_apple,
                    //   iconColor: Colors.black,
                    //   borderColor: OBColors.border,
                    //   onTap: _signInApple,
                    // ),
                    // const SizedBox(height: 12),
                    _SocialButton(
                      icon: Icons.mail_outline_rounded,
                      label: isRu ? 'Войти по email' : 'Sign in with Email',
                      iconColor: AppColors.textMuted,
                      borderColor: OBColors.border,
                      onTap: () => context.push('/email-auth'),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.auth_terms,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isRu) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF597D), Color(0xFFFE7650)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _LangToggle(
                  isRu: isRu,
                  onToggle: (locale) =>
                      ref.read(localeProvider.notifier).setLocale(locale),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kayfit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isRu ? 'Ваш трекер питания' : 'Your nutrition tracker',
                style: TextStyle(
                  color: Colors.white.withValues(alpha:0.85),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final bool isRu;
  final ValueChanged<Locale> onToggle;

  const _LangToggle({required this.isRu, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(label: 'RU', active: isRu, onTap: () => onToggle(const Locale('ru'))),
          _LangChip(label: 'EN', active: !isRu, onTap: () => onToggle(const Locale('en'))),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LangChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? OBColors.pink : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
