import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

/// null = not yet fetched / never answered
/// true = accepted
/// false = declined
class AiConsentNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  Future<void> load() async {
    try {
      final resp = await apiDio.get('/api/user/ai_consent');
      state = resp.data['consent'] as bool?;
    } catch (_) {
      // If endpoint not available, treat as null (needs to ask)
      state = null;
    }
  }

  Future<void> setConsent(bool value) async {
    try {
      await apiDio.post('/api/user/ai_consent', data: {'consent': value});
    } catch (_) {}
    state = value;
  }
}

final aiConsentProvider =
    NotifierProvider<AiConsentNotifier, bool?>(AiConsentNotifier.new);
