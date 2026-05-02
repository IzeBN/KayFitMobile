import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injects the current app language into API requests that support
/// language-specific responses.
///
/// Endpoints that accept `language` as a **query parameter**:
///   POST /api/onboarding/recognize_photo
///   POST /api/onboarding/transcribe
///   POST /api/transcribe
///   POST /api/recognize_photo
///
/// Endpoints that accept `language` as a **body field**:
///   POST /api/onboarding/parse_meal
///   POST /api/parse_meal
///
/// Reads the language code directly from SharedPreferences (key `app_locale`)
/// to avoid circular dependencies with the Riverpod layer. SharedPreferences
/// is guaranteed to be initialised before any API request is made.
class LocaleInterceptor extends Interceptor {
  static const _spKey = 'app_locale';
  static const _fallback = 'ru';

  static const _queryParamPaths = {
    '/api/onboarding/recognize_photo',
    '/api/onboarding/transcribe',
    '/api/transcribe',
    '/api/recognize_photo',
  };

  static const _bodyFieldPaths = {
    '/api/onboarding/parse_meal',
    '/api/parse_meal',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = _normalisePath(options.path);

    if (_queryParamPaths.contains(path) || _bodyFieldPaths.contains(path)) {
      final langCode = await _readLangCode();

      if (_queryParamPaths.contains(path)) {
        options.queryParameters['language'] = langCode;
      } else {
        // Body-field paths — only inject if the caller has not already set it.
        final data = options.data;
        if (data is Map<String, dynamic> &&
            !data.containsKey('language')) {
          options.data = {...data, 'language': langCode};
        }
      }
    }

    handler.next(options);
  }

  /// Strips query string and normalises to lowercase for reliable matching.
  String _normalisePath(String path) {
    final withoutQuery = path.split('?').first;
    return withoutQuery.toLowerCase();
  }

  Future<String> _readLangCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_spKey);
      return (code != null && (code == 'ru' || code == 'en'))
          ? code
          : _fallback;
    } on Exception {
      return _fallback;
    }
  }
}
