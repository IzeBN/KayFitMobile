import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';
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
  // Discount timer
  Timer? _timer;
  DateTime? _saleEndsAt;
  Duration _timeLeft = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(DateTime endsAt) {
    if (_saleEndsAt == endsAt) return;
    _saleEndsAt = endsAt;
    _timeLeft = endsAt.difference(DateTime.now());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = endsAt.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _timeLeft = left.isNegative ? Duration.zero : left);
      if (left.isNegative) _timer?.cancel();
    });
  }

  Future<void> _cancelAutoRenew(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.subscription_cancel_auto_renew_title),
        content: Text(l10n.subscription_cancel_auto_renew_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.subscription_cancel_auto_renew_action,
                style: const TextStyle(color: AppColors.accentOver)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await apiDio.post('/api/payments/auto-renew/cancel', data: {});
      ref.invalidate(settingsSubscriptionProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscription_auto_renew_cancelled)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.accentOver),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authNotifierProvider).value;
    final subAsync = ref.watch(settingsSubscriptionProvider);
    final paywallAsync = ref.watch(settingsTariffsPaywallProvider);
    final isRu = Localizations.localeOf(context).languageCode == 'ru';

    // Start timer if paywall data has one
    paywallAsync.whenData((d) {
      if (d == null) return;
      final show = d['show_discount_timer'] as bool? ?? false;
      final expiresStr = d['discount_timer_expires_at'] as String?;
      if (show && expiresStr != null) {
        final endsAt = DateTime.tryParse(expiresStr);
        if (endsAt != null && endsAt.isAfter(DateTime.now())) {
          _startTimer(endsAt);
        }
      }
    });

    final showTimer = _saleEndsAt != null && _timeLeft > Duration.zero;

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

          // ── Subscription block ───────────────────────────────────────────
          subAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: LoadingIndicator()),
            ),
            error: (error, _) => const SizedBox.shrink(),
            data: (sub) => sub != null
                ? _ActiveSubCard(
                    data: sub,
                    l10n: l10n,
                    onCancelAutoRenew: () => _cancelAutoRenew(context, l10n),
                  )
                : _NoSubCard(
                    l10n: l10n,
                    showTimer: showTimer,
                    timeLeft: _timeLeft,
                    onGoTariffs: () => context.push('/tariffs'),
                  ),
          ),

          const SizedBox(height: 12),

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
                onTap: () => ref.read(authNotifierProvider.notifier).logout(),
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
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇬🇧', label: 'English', selected: !isRu,
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ───────────────────────────────────────────────────────────────

class _ActiveSubCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AppLocalizations l10n;
  final VoidCallback onCancelAutoRenew;

  const _ActiveSubCard({required this.data, required this.l10n, required this.onCancelAutoRenew});

  @override
  Widget build(BuildContext context) {
    final title = data['tariff_title'] as String? ?? '';
    final autoRenew = data['auto_renew'] as bool? ?? false;
    final expiresAt = data['expires_at'] as String?;
    final amount = data['amount'];
    final currency = data['currency'] as String? ?? '₽';

    String formattedDate = '';
    if (expiresAt != null) {
      final d = DateTime.tryParse(expiresAt);
      if (d != null) formattedDate = DateFormat('dd.MM.yyyy').format(d.toLocal());
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: OBColors.gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: OBColors.buttonShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l10n.settings_sub_active_badge,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const Spacer(),
              if (amount != null)
                Text('$amount $currency',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('${l10n.subscription_expires}: $formattedDate',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
          ],
          const SizedBox(height: 4),
          Text(
            autoRenew ? l10n.subscription_auto_renew_on : l10n.subscription_auto_renew_off,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
          ),
          if (autoRenew) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onCancelAutoRenew,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                alignment: Alignment.center,
                child: Text(l10n.subscription_cancel_auto_renew,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoSubCard extends StatelessWidget {
  final AppLocalizations l10n;
  final bool showTimer;
  final Duration timeLeft;
  final VoidCallback onGoTariffs;

  const _NoSubCard({
    required this.l10n, required this.showTimer,
    required this.timeLeft, required this.onGoTariffs,
  });

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(l10n.subscription_none,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settings_sub_promo,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.4),
          ),
          if (showTimer) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OBColors.pinkSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.settings_sale_ends,
                      style: const TextStyle(color: OBColors.pink, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${_pad(timeLeft.inHours)}:${_pad(timeLeft.inMinutes % 60)}:${_pad(timeLeft.inSeconds % 60)}',
                    style: const TextStyle(
                      color: OBColors.pink, fontWeight: FontWeight.w800, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onGoTariffs,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: OBColors.gradient,
                borderRadius: BorderRadius.circular(999),
                boxShadow: OBColors.buttonShadow,
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.subscription_view_tariffs,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
