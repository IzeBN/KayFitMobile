import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

part 'subscription_screen.g.dart';

@riverpod
Future<Map<String, dynamic>?> subscription(SubscriptionRef ref) async {
  try {
    final resp = await apiDio.get('/api/payments/subscription');
    return resp.data as Map<String, dynamic>;
  } on DioException catch (e) {
    if (e.response?.statusCode == 404) return null;
    rethrow;
  }
}

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncSub = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscription_title)),
      body: asyncSub.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.error_unknown,
              style: const TextStyle(color: AppColors.accentOver),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (sub) => sub == null
            ? _NoSubscription(l10n: l10n)
            : _ActiveSubscription(data: sub, l10n: l10n, ref: ref),
      ),
    );
  }
}

class _NoSubscription extends StatelessWidget {
  const _NoSubscription({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.subscription_none,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.tariffs_free,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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
}

class _ActiveSubscription extends StatelessWidget {
  const _ActiveSubscription({
    required this.data,
    required this.l10n,
    required this.ref,
  });

  final Map<String, dynamic> data;
  final AppLocalizations l10n;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final title = data['tariff_title'] as String? ?? '';
    final amount = data['amount'];
    final currency = data['currency'] as String? ?? '';
    final autoRenew = data['auto_renew'] as bool? ?? false;
    final expiresAt = data['expires_at'] as String?;

    String formattedDate = '';
    if (expiresAt != null) {
      final date = DateTime.tryParse(expiresAt);
      if (date != null) {
        formattedDate = DateFormat('dd.MM.yyyy').format(date.toLocal());
      }
    }

    final amountStr = amount != null ? '$amount $currency' : '';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.accent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.subscription_active,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  if (formattedDate.isNotEmpty)
                    _InfoRow(
                      label: l10n.subscription_expires,
                      value: formattedDate,
                    ),
                  if (amountStr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: l10n.subscription_amount,
                      value: amountStr,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: l10n.subscription_auto_renew,
                    value: autoRenew
                        ? l10n.subscription_auto_renew_on
                        : l10n.subscription_auto_renew_off,
                  ),
                  if (autoRenew) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          _confirmCancelAutoRenew(context, ref, l10n),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentOver,
                        side: const BorderSide(color: AppColors.accentOver),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(l10n.subscription_cancel_auto_renew),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelAutoRenew(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
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
            child: Text(
              l10n.subscription_cancel_auto_renew_action,
              style: const TextStyle(color: AppColors.accentOver),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiDio.post('/api/payments/auto-renew/cancel');
      ref.invalidate(subscriptionProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.subscription_auto_renew_cancelled)),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? l10n.error_unknown),
            backgroundColor: AppColors.accentOver,
          ),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
