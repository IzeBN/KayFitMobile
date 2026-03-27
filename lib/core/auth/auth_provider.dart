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

part 'auth_provider.g.dart';

const _kCachedUserKey = 'cached_user';

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
        ref.read(aiConsentProvider.notifier).load();
        return;
      }

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
            ref.read(aiConsentProvider.notifier).load();
            return;
          }
        } catch (e) {
          debugPrint('[auth] refresh failed: $e');
        }
      }

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
    await TokenStorage.save(access, refresh);
    await checkSession();
  }

  Future<void> refreshUser() async {
    await checkSession();
  }

  Future<void> logout() async {
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

  Future<void> deleteAccount() async {
    try {
      await apiDio.delete('/api/v1/auth/account');
    } catch (_) {}
    await TokenStorage.clear();
    await _clearCache();
    state = const AsyncValue.data(null);
  }
}
