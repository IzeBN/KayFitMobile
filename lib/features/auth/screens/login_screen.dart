import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/onboarding_sync.dart';
import '../../../core/auth/social_auth_service.dart';
import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../router.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../way_to_goal/providers/way_to_goal_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.loginPageOpened();
  }

  // ---------------------------------------------------------------------------
  // Auth actions
  // ---------------------------------------------------------------------------

  Future<void> _afterLogin(Map<String, dynamic> tokens) async {
    await ref.read(authNotifierProvider.notifier).loginWithTokens(
          tokens['access_token'] as String,
          tokens['refresh_token'] as String,
        );
    if (!mounted) return;
    final hadPending = await syncOnboardingPending();
    await markOnboardingDone(ref);
    if (!mounted) return;
    if (hadPending) {
      ref.read(showWayToGoalProvider.notifier).state = true;
      ref.invalidate(calculationResultProvider);
      ref.invalidate(todayStatsProvider);
    }
  }

  Future<void> _signInApple() async {
    AnalyticsService.loginMethodSelected('apple');
    setState(() => _loading = true);
    try {
      final tokens = await SocialAuthService.signInWithApple();
      await _afterLogin(tokens);
    } on SignInCancelledException {
      // user cancelled — no error shown
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isRu = locale.languageCode == 'ru';

    return Stack(
      children: [
        Scaffold(
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
                      _buildAppleButton(isRu),
                      const SizedBox(height: 12),
                      _SocialButton(
                        icon: Icons.mail_outline_rounded,
                        label: isRu ? 'Войти по email' : 'Sign in with Email',
                        iconColor: AppColors.textMuted,
                        borderColor: OBColors.border,
                        onTap: _loading
                            ? null
                            : () {
                                AnalyticsService.loginMethodSelected('email');
                                context.push('/email-auth');
                              },
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
        ),
        if (_loading)
          const ColoredBox(
            color: Color(0x66000000),
            child: Center(child: LoadingIndicator()),
          ),
      ],
    );
  }

  /// Apple button — native [SignInWithAppleButton] on iOS (required by Apple HIG),
  /// custom [_SocialButton] on Android (where the web flow is used).
  Widget _buildAppleButton(bool isRu) {
    if (Platform.isIOS) {
      return SignInWithAppleButton(
        onPressed: _loading ? () {} : _signInApple,
        text: isRu ? 'Войти через Apple' : 'Sign in with Apple',
        height: 54,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        style: SignInWithAppleButtonStyle.black,
      );
    }
    return _SocialButton(
      icon: Icons.apple,
      label: isRu ? 'Войти через Apple' : 'Sign in with Apple',
      iconColor: Colors.black87,
      borderColor: OBColors.border,
      onTap: _loading ? null : _signInApple,
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.white.withValues(alpha: 0.85),
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

// ---------------------------------------------------------------------------
// _LangToggle / _LangChip
// ---------------------------------------------------------------------------

class _LangToggle extends StatelessWidget {
  final bool isRu;
  final ValueChanged<Locale> onToggle;

  const _LangToggle({required this.isRu, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangChip(
            label: 'RU',
            active: isRu,
            onTap: () {
              AnalyticsService.langSelected('ru', 'login');
              onToggle(const Locale('ru'));
            },
          ),
          _LangChip(
            label: 'EN',
            active: !isRu,
            onTap: () {
              AnalyticsService.langSelected('en', 'login');
              onToggle(const Locale('en'));
            },
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

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

// ---------------------------------------------------------------------------
// _SocialButton
// ---------------------------------------------------------------------------

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Material(
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
      ),
    );
  }
}
