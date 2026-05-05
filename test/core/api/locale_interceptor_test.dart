import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kayfit/core/api/locale_interceptor.dart';

// ---------------------------------------------------------------------------
// Minimal stub that captures what handler.next() was called with.
// ---------------------------------------------------------------------------

class _CapturingHandler extends RequestInterceptorHandler {
  RequestOptions? captured;

  @override
  void next(RequestOptions options) {
    captured = options;
  }
}

void main() {
  group('LocaleInterceptor', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'app_locale': 'ru'});
    });

    Future<RequestOptions> runInterceptor(
      String path, {
      Map<String, dynamic>? queryParameters,
      Map<String, dynamic>? body,
    }) async {
      final interceptor = LocaleInterceptor();
      final options = RequestOptions(
        path: path,
        queryParameters: queryParameters ?? {},
        data: body,
      );
      final handler = _CapturingHandler();
      await interceptor.onRequest(options, handler);
      return handler.captured!;
    }

    // ── Query-parameter endpoints ──────────────────────────────────────────

    test('adds language query param to /api/recognize_photo', () async {
      final opts = await runInterceptor('/api/recognize_photo');
      expect(opts.queryParameters['language'], equals('ru'));
    });

    test('adds language query param to /api/transcribe', () async {
      final opts = await runInterceptor('/api/transcribe');
      expect(opts.queryParameters['language'], equals('ru'));
    });

    test('adds language query param to /api/onboarding/recognize_photo',
        () async {
      final opts =
          await runInterceptor('/api/onboarding/recognize_photo');
      expect(opts.queryParameters['language'], equals('ru'));
    });

    test('adds language query param to /api/onboarding/transcribe', () async {
      final opts = await runInterceptor('/api/onboarding/transcribe');
      expect(opts.queryParameters['language'], equals('ru'));
    });

    // ── Body-field endpoints ───────────────────────────────────────────────

    test('injects language body field to /api/parse_meal when absent',
        () async {
      final opts = await runInterceptor(
        '/api/parse_meal',
        body: {'text': 'гречка с курицей'},
      );
      final data = opts.data as Map<String, dynamic>;
      expect(data['language'], equals('ru'));
      expect(data['text'], equals('гречка с курицей'));
    });

    test('does NOT override explicit language in body for /api/parse_meal',
        () async {
      final opts = await runInterceptor(
        '/api/parse_meal',
        body: {'text': 'chicken salad', 'language': 'en'},
      );
      final data = opts.data as Map<String, dynamic>;
      expect(data['language'], equals('en')); // caller wins
    });

    test('injects language body field to /api/onboarding/parse_meal',
        () async {
      final opts = await runInterceptor(
        '/api/onboarding/parse_meal',
        body: {'text': 'завтрак'},
      );
      final data = opts.data as Map<String, dynamic>;
      expect(data['language'], equals('ru'));
    });

    // ── Non-targeted endpoints ─────────────────────────────────────────────

    test('does NOT touch query params for /api/meals', () async {
      final opts = await runInterceptor('/api/meals');
      expect(opts.queryParameters.containsKey('language'), isFalse);
    });

    test('does NOT touch query params for /api/profile', () async {
      final opts = await runInterceptor('/api/profile');
      expect(opts.queryParameters.containsKey('language'), isFalse);
    });

    // ── Locale source ──────────────────────────────────────────────────────

    test('uses EN when SP contains "en"', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      final opts = await runInterceptor('/api/recognize_photo');
      expect(opts.queryParameters['language'], equals('en'));
    });

    test('falls back to "ru" when SP is empty', () async {
      SharedPreferences.setMockInitialValues({});

      final opts = await runInterceptor('/api/recognize_photo');
      expect(opts.queryParameters['language'], equals('ru'));
    });

    test('falls back to "ru" when SP has unsupported code', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'fr'});

      final opts = await runInterceptor('/api/recognize_photo');
      expect(opts.queryParameters['language'], equals('ru'));
    });
  });
}
