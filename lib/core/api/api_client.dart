import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://app.kayfit.ru';

/// Public base URL — exposed so auth provider can create plain Dio instances.
const baseUrl = _baseUrl;

late final Dio apiDio;

// ---------------------------------------------------------------------------
// Token storage
// ---------------------------------------------------------------------------

class TokenStorage {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  static Future<void> save(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccess, access);
    await prefs.setString(_keyRefresh, refresh);
  }

  static Future<String?> getAccess() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccess);
  }

  static Future<String?> getRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefresh);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccess);
    await prefs.remove(_keyRefresh);
  }
}

// ---------------------------------------------------------------------------
// Logout callback — set by auth layer to react to token expiry
// ---------------------------------------------------------------------------

typedef LogoutCallback = Future<void> Function();
LogoutCallback? _onLogout;

void setLogoutCallback(LogoutCallback cb) => _onLogout = cb;

// ---------------------------------------------------------------------------
// Init
// ---------------------------------------------------------------------------

Future<void> initApiClient() async {
  apiDio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  apiDio.interceptors.add(_AuthInterceptor(apiDio));
  apiDio.interceptors.add(LogInterceptor(responseBody: false));
}

// ---------------------------------------------------------------------------
// Auth interceptor: inject Bearer + auto-refresh on 401
// ---------------------------------------------------------------------------

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header injection for auth endpoints themselves
    final path = options.path;
    final isAuthEndpoint = path.contains('/api/v1/auth/login') ||
        path.contains('/api/v1/auth/register') ||
        path.contains('/api/v1/auth/refresh') ||
        path.contains('/api/v1/auth/google') ||
        path.contains('/api/v1/auth/apple');

    if (!isAuthEndpoint) {
      final token = await TokenStorage.getAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 402) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const PaymentRequiredException(),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }

    if (err.response?.statusCode == 401 && !_isRefreshing) {
      // Auth and onboarding endpoints — don't trigger refresh/logout cycle
      final path = err.requestOptions.path;
      if (path.contains('/api/v1/auth/') || path.contains('/api/onboarding/')) {
        handler.next(err);
        return;
      }
      _isRefreshing = true;
      try {
        final refreshToken = await TokenStorage.getRefresh();
        if (refreshToken == null) {
          await _handleLogout();
          handler.next(err);
          return;
        }

        // Use a separate Dio instance to avoid infinite loop
        final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
        final resp = await refreshDio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final data = resp.data as Map<String, dynamic>;
        final newAccess = data['access_token'] as String;
        final newRefresh = data['refresh_token'] as String;
        await TokenStorage.save(newAccess, newRefresh);

        // Retry the original request with new token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        final retryResp = await _dio.fetch(opts);
        handler.resolve(retryResp);
      } catch (_) {
        await _handleLogout();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _handleLogout() async {
    await TokenStorage.clear();
    await _onLogout?.call();
  }
}

// ---------------------------------------------------------------------------
// ApiException
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when the server returns 402 Payment Required.
class PaymentRequiredException implements Exception {
  const PaymentRequiredException();
  @override
  String toString() => 'PaymentRequiredException';
}
