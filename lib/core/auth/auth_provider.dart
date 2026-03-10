import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/models/user_profile.dart';
import '../api/api_client.dart';
import '../notifications/notification_service.dart';
import 'onboarding_sync.dart';

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

  /// Called on app start — checks stored token, fetches profile if valid.
  /// Uses a plain Dio (no interceptor) to avoid interfering with the
  /// refresh/logout cycle used by normal API calls.
  Future<void> checkSession() async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenStorage.getAccess();
      if (token == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _fetchMe(token);
      if (user != null) {
        state = AsyncValue.data(user);
        syncOnboardingPending().catchError(
          (e) => debugPrint('[auth] onboarding retry error: $e'),
        );
        NotificationService.registerTokenAfterLogin();
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
            state = AsyncValue.data(refreshedUser);
            syncOnboardingPending().catchError(
              (e) => debugPrint('[auth] onboarding retry error: $e'),
            );
            NotificationService.registerTokenAfterLogin();
            return;
          }
        } catch (e) {
          debugPrint('[auth] refresh failed: $e');
        }
      }

      // All attempts failed
      await TokenStorage.clear();
      state = const AsyncValue.data(null);
    } catch (e) {
      debugPrint('[auth] checkSession error: $e');
      state = const AsyncValue.data(null);
    }
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
    state = const AsyncValue.data(null);
  }
}
