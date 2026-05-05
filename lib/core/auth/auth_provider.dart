import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user_profile.dart';
import '../api/api_client.dart';
import '../notifications/notification_service.dart';
import '../ai_consent/ai_consent_provider.dart';
import 'onboarding_sync.dart';
import 'token_pair.dart';

part 'auth_provider.g.dart';

const _kCachedUserKey = 'cached_user';

// ── SecureTokenStorage Riverpod provider ────────────────────────────────────
// Returns the singleton instance created in initApiClient() so all parts of
// the app share the same storage object (and the same underlying Keychain).

// ignore: deprecated_member_use
final secureStorageProvider = Provider<SecureTokenStorage>(
  (_) => secureTokenStorage,
);

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserProfile?> build() {
    setLogoutCallback(() async {
      state = const AsyncValue.data(null);
    });
    return const AsyncValue.loading();
  }

  void restoreFromCache(UserProfile user) {
    state = AsyncValue.data(user);
  }

  Future<void> checkSession({bool backgroundRefresh = false}) async {
    if (!backgroundRefresh) state = const AsyncValue.loading();

    final storage = ref.read(secureStorageProvider);

    try {
      // Load the full token pair so we can inspect expiresAt locally and
      // avoid one unnecessary round-trip (EC3 / UC2 optimisation).
      final pair = await storage.loadTokens();

      if (pair == null) {
        // No tokens at all → not logged in.
        await _clearCache();
        if (!backgroundRefresh) state = const AsyncValue.data(null);
        return;
      }

      // If token not yet expired, try /me with it.
      if (!pair.isExpired) {
        final user = await _fetchMe(pair.accessToken);
        if (user != null) {
          await _saveCache(user);
          state = AsyncValue.data(user);
          _postLoginSideEffects();
          return;
        }
        // /me returned 401 despite non-expired token (clock skew, early revoke)
        // → fall through to refresh.
      }

      // Token is expired (or /me returned 401) → attempt silent refresh.
      try {
        final plain = Dio(BaseOptions(baseUrl: baseUrl));
        final resp = await plain.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': pair.refreshToken},
        );
        final data = resp.data as Map<String, dynamic>;
        final newPair = TokenPair.fromApiResponse(data);
        await storage.saveTokens(newPair);

        final refreshedUser = await _fetchMe(newPair.accessToken);
        if (refreshedUser != null) {
          await _saveCache(refreshedUser);
          state = AsyncValue.data(refreshedUser);
          _postLoginSideEffects();
          return;
        }
      } on DioException catch (e) {
        debugPrint('[auth] refresh failed: $e');
      }

      // Refresh failed or /me still returned null → clear and log out.
      await storage.clearTokens();
      await _clearCache();
      if (!backgroundRefresh) state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('[auth] checkSession error: $e');
      if (!backgroundRefresh) state = const AsyncValue.data(null);
    }
  }

  void _postLoginSideEffects() {
    syncOnboardingPending().catchError(
      (e) {
        debugPrint('[auth] onboarding retry error: $e');
        return false;
      },
    );
    NotificationService.registerTokenAfterLogin();
    ref.read(aiConsentProvider.notifier).load();
  }

  static Future<void> _saveCache(UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedUserKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  static Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedUserKey);
    } catch (_) {}
  }

  Future<UserProfile?> _fetchMe(String token) async {
    try {
      final plain = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Authorization': 'Bearer $token'},
      ));
      final resp = await plain.get('/api/v1/auth/me');
      return UserProfile.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> loginWithTokens(String access, String refresh) async {
    // Construct a TokenPair with unknown expiresAt → will refresh immediately.
    final pair = TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now(),
    );
    final storage = ref.read(secureStorageProvider);
    await storage.saveTokens(pair);
    await checkSession();
  }

  Future<void> loginWithTokenPair(TokenPair pair) async {
    final storage = ref.read(secureStorageProvider);
    await storage.saveTokens(pair);
    await checkSession();
  }

  Future<void> refreshUser() async {
    await checkSession();
  }

  Future<void> logout() async {
    await NotificationService.unregisterToken();

    final storage = ref.read(secureStorageProvider);

    try {
      final refreshToken = await storage.loadRefreshToken();
      if (refreshToken != null) {
        // Best-effort revocation — errors are swallowed intentionally (UC8).
        await apiDio.post(
          '/api/v1/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {}

    await storage.clearTokens();
    await _clearCacheAndProgress();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    try {
      await apiDio.delete('/api/v1/auth/account');
    } catch (_) {}
    final storage = ref.read(secureStorageProvider);
    await storage.clearTokens();
    await _clearCacheAndProgress();
    state = const AsyncValue.data(null);
  }

  /// Clears cached_user and onboarding progress keys on logout (UC8).
  /// onboarding_done is intentionally kept so the user is sent to /login
  /// instead of /onboarding on next cold start.
  static Future<void> _clearCacheAndProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kCachedUserKey),
        prefs.remove('onboarding_answers'),
        prefs.remove('onboarding_current_step'),
      ]);
    } catch (_) {}
  }
}
