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

const _kCachedUserKey = 'cached_user';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserProfile?> build() {
    // Register logout callback so token expiry auto-clears state
    setLogoutCallback(() async {
      state = const AsyncValue.data(null);
    });
    return const AsyncValue.loading();
  }

  /// Instantly restores a cached user profile so the router shows the app
  /// without waiting for the network. Call before [checkSession].
  void restoreFromCache(UserProfile user) {
    state = AsyncValue.data(user);
  }

  /// Called on app start — checks stored token, fetches profile if valid.
  ///
  /// When [backgroundRefresh] is true (cached user already shown) the state
  /// is NOT set to loading, so the UI stays visible during the silent refresh.
  /// Uses a plain Dio (no interceptor) to avoid interfering with the
  /// refresh/logout cycle used by normal API calls.
  Future<void> checkSession({bool backgroundRefresh = false}) async {
    if (!backgroundRefresh) state = const AsyncValue.loading();
    try {
      final token = await TokenStorage.getAccess();
      if (token == null) {
        await _clearCache();
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _fetchMe(token);
      if (user != null) {
        await _saveCache(user);
        state = AsyncValue.data(user);
        syncOnboardingPending().catchError(
          (e) { debugPrint('[auth] onboarding retry error: $e'); return false; },
        );
        NotificationService.registerTokenAfterLogin();
        // Load AI consent status from server
        ref.read(aiConsentProvider.notifier).load();
        return;
      }

      // Access token rejected — try refresh
      final refreshToken = await TokenStorage.getRefresh();
      if (refreshToken != null) {
        try {
          final plain = Dio(BaseOptions(baseUrl: baseUrl));
          final resp = await plain.post(
            '/api/v1/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
          final data = resp.data as Map<String, dynamic>;
          final newAccess = data['access_token'] as String;
          final newRefresh = data['refresh_token'] as String;
          await TokenStorage.save(newAccess, newRefresh);
          final refreshedUser = await _fetchMe(newAccess);
          if (refreshedUser != null) {
            await _saveCache(refreshedUser);
            state = AsyncValue.data(refreshedUser);
            syncOnboardingPending().catchError(
              (e) { debugPrint('[auth] onboarding retry error: $e'); return false; },
            );
            NotificationService.registerTokenAfterLogin();
            // Load AI consent status from server
            ref.read(aiConsentProvider.notifier).load();
            return;
          }
        } catch (e) {
          debugPrint('[auth] refresh failed: $e');
        }
      }

      // All attempts failed
      await TokenStorage.clear();
      await _clearCache();
      state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('[auth] checkSession error: $e');
      if (!backgroundRefresh) state = const AsyncValue.data(null);
    }
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

  /// Fetches /api/v1/auth/me using a plain Dio (no interceptor).
  /// Returns null on 401/error without throwing.
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

  /// Called after any successful sign-in to refresh the user state.
  Future<void> refreshUser() async {
    await checkSession();
  }

  /// Sign out: invalidate refresh token on server, clear local storage,
  /// unregister FCM push token.
  Future<void> logout() async {
    // Unregister FCM token before clearing auth — the request needs the
    // Bearer token that is still valid at this point.
    await NotificationService.unregisterToken();

    try {
      final refreshToken = await TokenStorage.getRefresh();
      if (refreshToken != null) {
        await apiDio.post(
          '/api/v1/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {}
    await TokenStorage.clear();
    await _clearCache();
    state = const AsyncValue.data(null);
  }

  /// Permanently delete the user account and all associated data.
  Future<void> deleteAccount() async {
    try {
      await apiDio.delete('/api/v1/auth/account');
    } catch (_) {}
    await TokenStorage.clear();
    await _clearCache();
    state = const AsyncValue.data(null);
  }
}
