import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/loading_indicator.dart';

part 'tariffs_screen.g.dart';

// ─── Provider ──────────────────────────────────────────────────────────────────

@riverpod
Future<Map<String, dynamic>> tariffsData(TariffsDataRef ref) async {
  final resp = await apiDio.get('/api/payments/tariffs');
  return resp.data as Map<String, dynamic>;
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

bool _isTrial(Map<String, dynamic> t) =>
    (t['is_trial'] as bool? ?? false) || t['code'] == 'trial';

String _label(Map<String, dynamic> t, bool isRu) {
  if (_isTrial(t)) return isRu ? 'Пробный период' : 'Free trial';
  final code = t['code'] as String? ?? '';
  if (code == 'monthly') return isRu ? 'Месяц' : 'Monthly';
  if (code == 'yearly') return isRu ? 'Год' : 'Yearly';
  if (code == 'quarterly') return isRu ? 'Квартал' : 'Quarterly';
  return t['title'] as String? ?? code;
}

/// Returns days in the billing period (for price/day calculation).
int _periodDays(Map<String, dynamic> t) {
  final code = t['code'] as String? ?? '';
  if (code == 'monthly') return 30;
  if (code == 'quarterly') return 90;
  if (code == 'yearly') return 365;
  return 1;
}

/// Discount percentage, 0 if none.
int _discountPct(Map<String, dynamic> t) {
  final price = (t['price'] as num?)?.toDouble() ?? 0;
  final fullPrice = (t['full_price'] as num?)?.toDouble() ?? price;
  if (fullPrice <= price || fullPrice == 0) return 0;
  return ((fullPrice - price) / fullPrice * 100).round();
}

String _rub(num value) {
  final s = value.toInt().toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '\u00a0');
  return '$s ₽';
}

String _rubDouble(double value) {
  if (value == value.truncateToDouble()) return _rub(value.toInt());
  return '${value.toStringAsFixed(1)} ₽';
}

int _order(Map<String, dynamic> t) {
  final code = t['code'] as String? ?? '';
  if (_isTrial(t)) return 0;
  if (code == 'monthly') return 1;
  if (code == 'yearly') return 2;
  if (code == 'quarterly') return 3;
  return 10;
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class TariffsScreen extends ConsumerStatefulWidget {
  const TariffsScreen({super.key});

  @override
  ConsumerState<TariffsScreen> createState() => _TariffsScreenState();
}

class _TariffsScreenState extends ConsumerState<TariffsScreen> {
  int? _selectedId;
  final _emailCtrl = TextEditingController();
  bool _paying = false;
  String? _emailError;

  // Discount timer
  Timer? _timer;
  DateTime? _saleEndsAt;
  Duration _timeLeft = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _startTimer(DateTime endsAt) {
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

  void _onData(Map<String, dynamic> d) {
    final tariffs = _sorted(d);
    if (_selectedId == null && tariffs.isNotEmpty) {
      final def = tariffs.firstWhere(
        (t) => t['code'] == 'yearly',
        orElse: () => tariffs.firstWhere(
          (t) => t['code'] == 'monthly',
          orElse: () => tariffs.first,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) setState(() => _selectedId = def['id'] as int?); },
      );
    }

    final showTimer = d['show_discount_timer'] as bool? ?? false;
    final expiresStr = d['discount_timer_expires_at'] as String?;
    if (showTimer && expiresStr != null && _saleEndsAt == null) {
      final endsAt = DateTime.tryParse(expiresStr);
      if (endsAt != null && endsAt.isAfter(DateTime.now())) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) { if (mounted) _startTimer(endsAt); },
        );
      }
    }
  }

  List<Map<String, dynamic>> _sorted(Map<String, dynamic> d) {
    final list = ((d['tariffs'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList()
      ..sort((a, b) => _order(a).compareTo(_order(b)));
    return list;
  }

  Future<void> _pay(BuildContext context) async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _emailError = 'Введите корректный email');
      return;
    }
    if (_selectedId == null) return;
    setState(() { _paying = true; _emailError = null; });
    try {
      final resp = await apiDio.post('/api/payments/create', data: {
        'tariff_id': _selectedId,
        'email': email,
      });
      final url = (resp.data as Map<String, dynamic>)['confirmation_url'] as String?;
      if (url != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _PaymentWebView(url: url)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.accentOver),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRu = Localizations.localeOf(context).languageCode == 'ru';
    final data = ref.watch(tariffsDataProvider);

    return Scaffold(
      backgroundColor: OBColors.bg,
      body: data.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (d) {
          _onData(d);
          final tariffs = _sorted(d);
          final showTimer = _saleEndsAt != null && _timeLeft > Duration.zero;

          return CustomScrollView(
            slivers: [
              // ── Pink header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        color: OBColors.pink,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 77,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                alignment: Alignment.center,
                                child: const Text('← Назад',
                                    style: TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Title ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 28, 22, 8),
                      child: Text(
                        isRu ? 'Подписка Kayfit' : 'Kayfit Subscription',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),

                    // ── Feature tags ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                      child: _FeatureTags(isRu: isRu),
                    ),

                    // ── Discount timer ───────────────────────────────────
                    if (showTimer) ...[
                      _DiscountTimer(timeLeft: _timeLeft, isRu: isRu),
                      const SizedBox(height: 8),
                    ],

                    // ── Tariff cards ─────────────────────────────────────
                    ...tariffs.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TariffCard(
                        tariff: t,
                        isRu: isRu,
                        selected: t['id'] == _selectedId,
                        onTap: () => setState(() => _selectedId = t['id'] as int?),
                      ),
                    )),

                    const SizedBox(height: 8),

                    // ── Hint ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        isRu
                            ? 'Отменить можно в любой момент в настройках.'
                            : 'Cancel anytime in settings.',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Email ─────────────────────────────────────────────
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 15),
                      onChanged: (_) => setState(() => _emailError = null),
                      decoration: InputDecoration(
                        hintText: isRu ? 'Email для чека' : 'Email for receipt',
                        filled: true,
                        fillColor: Colors.white,
                        errorText: _emailError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: OBColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: OBColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: OBColors.pink, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Pay button ────────────────────────────────────────
                    GestureDetector(
                      onTap: _paying ? null : () => _pay(context),
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: _paying ? null : OBColors.gradient,
                          color: _paying ? AppColors.border : null,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: _paying ? [] : OBColors.buttonShadow,
                        ),
                        alignment: Alignment.center,
                        child: _paying
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isRu ? 'Оформить подписку' : 'Subscribe',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Feature tags ──────────────────────────────────────────────────────────────

class _FeatureTags extends StatelessWidget {
  final bool isRu;
  const _FeatureTags({required this.isRu});

  @override
  Widget build(BuildContext context) {
    final tags = isRu
        ? ['📸 Распознавание фото', '🎤 Голосовой ввод', '📊 КБЖУ аналитика', '🤖 ИИ-помощник']
        : ['📸 Photo recognition', '🎤 Voice input', '📊 Macro analytics', '🤖 AI assistant'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.asMap().entries.map((e) {
          final isFirst = e.key == 0;
          return Container(
            width: isFirst ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(512),
            ),
            child: Text(
              e.value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Discount timer ────────────────────────────────────────────────────────────

class _DiscountTimer extends StatelessWidget {
  final Duration timeLeft;
  final bool isRu;
  const _DiscountTimer({required this.timeLeft, required this.isRu});

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h = timeLeft.inHours;
    final m = timeLeft.inMinutes % 60;
    final s = timeLeft.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        border: Border.all(color: OBColors.pink, width: 2),
        borderRadius: BorderRadius.circular(24),
        color: OBColors.pink.withValues(alpha: 0.08),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: OBColors.pink,
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            child: Text(
              isRu ? 'СКИДКА ЗАКАНЧИВАЕТСЯ' : 'SALE ENDS IN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimerBox(_pad(h)),
                const _TimerSep(),
                _TimerBox(_pad(m)),
                const _TimerSep(),
                _TimerBox(_pad(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerBox extends StatelessWidget {
  final String value;
  const _TimerBox(this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64, height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OBColors.border),
      ),
      alignment: Alignment.center,
      child: Text(value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }
}

class _TimerSep extends StatelessWidget {
  const _TimerSep();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
    );
  }
}

// ─── Tariff card ───────────────────────────────────────────────────────────────

class _TariffCard extends StatelessWidget {
  final Map<String, dynamic> tariff;
  final bool isRu;
  final bool selected;
  final VoidCallback onTap;

  const _TariffCard({
    required this.tariff,
    required this.isRu,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trial = _isTrial(tariff);
    final price = (tariff['price'] as num?)?.toInt() ?? 0;
    final discountPct = _discountPct(tariff);
    final days = _periodDays(tariff);
    final pricePerDay = days > 0 ? price / days : 0.0;

    // Period label for total price line
    final code = tariff['code'] as String? ?? '';
    final periodSuffix = isRu
        ? (code == 'monthly' ? '/ мес' : code == 'yearly' ? '/ год' : code == 'quarterly' ? '/ 3 мес' : '')
        : (code == 'monthly' ? '/ mo' : code == 'yearly' ? '/ yr' : code == 'quarterly' ? '/ 3 mo' : '');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: selected ? OBColors.pink.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? OBColors.pink : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: trial
            ? _TrialContent(tariff: tariff, isRu: isRu, selected: selected, price: price)
            : _PaidContent(
                tariff: tariff,
                isRu: isRu,
                selected: selected,
                price: price,
                discountPct: discountPct,
                pricePerDay: pricePerDay,
                periodSuffix: periodSuffix,
              ),
      ),
    );
  }
}

class _TrialContent extends StatelessWidget {
  final Map<String, dynamic> tariff;
  final bool isRu;
  final bool selected;
  final int price;
  const _TrialContent({
    required this.tariff, required this.isRu, required this.selected, required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(tariff, isRu),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 2),
              Text(
                isRu ? 'Потом 499 ₽/мес' : 'Then 499 ₽/mo',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          '${_rub(price)} ${isRu ? "за 3 дня" : "for 3 days"}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: selected ? OBColors.pink : AppColors.text,
          ),
        ),
      ],
    );
  }
}

class _PaidContent extends StatelessWidget {
  final Map<String, dynamic> tariff;
  final bool isRu;
  final bool selected;
  final int price;
  final int discountPct;
  final double pricePerDay;
  final String periodSuffix;

  const _PaidContent({
    required this.tariff,
    required this.isRu,
    required this.selected,
    required this.price,
    required this.discountPct,
    required this.pricePerDay,
    required this.periodSuffix,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? OBColors.pink : AppColors.text;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: label + total price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _label(tariff, isRu),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 4),
              Text(
                '${_rub(price)} $periodSuffix',
                style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Right: discount badge + price per day
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (discountPct > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OBColors.pink,
                  borderRadius: BorderRadius.circular(256),
                ),
                child: Text(
                  '-$discountPct%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '${_rubDouble(pricePerDay)} ${isRu ? "/ день" : "/ day"}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: accent),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Payment WebView ───────────────────────────────────────────────────────────

class _PaymentWebView extends StatefulWidget {
  final String url;
  const _PaymentWebView({required this.url});

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
