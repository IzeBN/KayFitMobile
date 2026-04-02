import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';

const _kLocalConsentKey = 'ai_consent_local';

/// null = not yet fetched / never answered
/// true = accepted
/// false = declined
class AiConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() {
    // Auto-load from local storage on first access (for unauthenticated users).
    Future.microtask(_loadLocal);
    return null;
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getBool(_kLocalConsentKey);
    if (local != null && state == null) state = local;
  }

  /// Called after login — syncs from server (overrides local value).
  Future<void> load() async {
    try {
      final resp = await apiDio.get('/api/user/ai_consent');
      state = resp.data['consent'] as bool?;
    } catch (_) {
      // Server unavailable — keep local value.
      await _loadLocal();
    }
  }

  Future<void> setConsent(bool value) async {
    // Persist locally first so unauthenticated users are covered.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocalConsentKey, value);
    // Sync with server (best-effort; may fail if not logged in).
    try {
      await apiDio.post('/api/user/ai_consent', data: {'consent': value});
    } catch (_) {}
    state = value;
  }
}

final aiConsentProvider =
    NotifierProvider<AiConsentNotifier, bool?>(AiConsentNotifier.new);
