import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';
import 'document_screen.dart';

part 'settings_screen.g.dart';

// ─── Provider ──────────────────────────────────────────────────────────────────

@riverpod
Future<Map<String, dynamic>?> settingsSubscription(SettingsSubscriptionRef ref) async {
  try {
    final resp = await apiDio.get('/api/payments/subscription');
    if (resp.data == null) return null;
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404 || e.response?.statusCode == 204) return null;
    rethrow;
  }
}

@riverpod
Future<Map<String, dynamic>?> settingsTariffsPaywall(SettingsTariffsPaywallRef ref) async {
  try {
    final resp = await apiDio.get('/api/payments/tariffs');
    return resp.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authNotifierProvider).value;
    // final subAsync = ref.watch(settingsSubscriptionProvider);
    // final paywallAsync = ref.watch(settingsTariffsPaywallProvider);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    // TODO: SUBSCRIPTION_REQUIRED — timer block commented out
    // paywallAsync.whenData((d) { ... });
    // final showTimer = _saleEndsAt != null && _timeLeft > Duration.zero;
    // _startTimer(endsAt);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(l10n.settings_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User card ────────────────────────────────────────────────────
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: AppShadow.sm,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: OBColors.pinkSoft,
                    child: const Icon(Icons.person, color: OBColors.pink, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username ?? user.email ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        if (user.email != null)
                          Text(user.email!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // TODO: SUBSCRIPTION_REQUIRED — subscription block commented out

          // ── Navigation items ─────────────────────────────────────────────
          _SettingsCard(
            children: [
              _Item(
                icon: Icons.flag_outlined,
                label: l10n.settings_goals,
                onTap: () => context.push('/settings/goals'),
              ),
              _Divider(),
              _Item(
                icon: Icons.language,
                label: l10n.settings_language,
                onTap: () => _showLangDialog(context, l10n, isRu),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _SettingsCard(
            children: [
              _Item(
                icon: Icons.privacy_tip_outlined,
                label: l10n.settings_privacy_policy,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScreen(type: DocumentType.privacyPolicy),
                  ),
                ),
              ),
              _Divider(),
              _Item(
                icon: Icons.description_outlined,
                label: l10n.settings_terms,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DocumentScreen(type: DocumentType.termsOfService),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _SettingsCard(
            children: [
              _Item(
                icon: Icons.logout,
                label: l10n.settings_logout,
                color: AppColors.accentOver,
                onTap: () {
                AnalyticsService.loggedOut();
                ref.read(authNotifierProvider.notifier).logout();
              },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLangDialog(BuildContext context, AppLocalizations l10n, bool isRu) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.settings_language,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _LangOption(
              flag: '🇷🇺', label: 'Русский', selected: isRu,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('ru'));
                AnalyticsService.languageChanged('ru');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇬🇧', label: 'English', selected: !isRu,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                AnalyticsService.languageChanged('en');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: SUBSCRIPTION_REQUIRED — _ActiveSubCard and _NoSubCard removed

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadow.sm,
      ),
      child: Column(children: children),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _Item({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20) : null,
      onTap: onTap,
      minLeadingWidth: 24,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, color: AppColors.border);
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({required this.flag, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? OBColors.pinkSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? OBColors.pink : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: selected ? OBColors.pink : AppColors.text)),
            const Spacer(),
            if (selected) const Icon(Icons.check_circle_rounded, color: OBColors.pink, size: 20),
          ],
        ),
      ),
    );
  }
}
