import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/widgets.dart';

const _apiKey = '4e13da23-16bb-416c-9e35-1522113d5ff0';

/// Central AppMetrica analytics service.
/// Call [AnalyticsService.init] once at startup, then use static helpers.
class AnalyticsService {
  AnalyticsService._();

  // ─── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    await AppMetrica.activate(
      const AppMetricaConfig(
        _apiKey,
        sessionTimeout: 30,
        crashReporting: true,
        nativeCrashReporting: true,
        flutterCrashReporting: true,
        logs: false,
        sessionsAutoTrackingEnabled: true,
      ),
    );
  }

  // ─── Navigator observer for automatic screen tracking ────────────────────────

  static AppMetricaRouteObserver get routeObserver =>
      AppMetricaRouteObserver();

  // ─── User identity & profile ─────────────────────────────────────────────────

  static Future<void> setUserId(String email) async {
    await AppMetrica.reportUserProfile(
      AppMetricaUserProfile([
        AppMetricaStringAttribute.withValue('user_email', email),
      ]),
    );
  }

  static Future<void> setUserProfile({
    String? name,
    String? email,
    String? language,
    int? age,
    String? gender,
    bool? hasSubscription,
  }) async {
    if (name != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([AppMetricaNameAttribute.withValue(name)]),
      );
    }
    if (email != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([AppMetricaStringAttribute.withValue('user_email', email)]),
      );
    }
    if (language != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([AppMetricaStringAttribute.withValue('language', language)]),
      );
    }
    if (age != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([AppMetricaBirthDateAttribute.withAge(age)]),
      );
    }
    if (gender != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([
          AppMetricaGenderAttribute.withValue(
            gender.toLowerCase() == 'female'
                ? AppMetricaGender.female
                : AppMetricaGender.male,
          ),
        ]),
      );
    }
    if (hasSubscription != null) {
      await AppMetrica.reportUserProfile(
        AppMetricaUserProfile([
          AppMetricaBooleanAttribute.withValue('has_subscription', hasSubscription),
        ]),
      );
    }
  }

  // ─── Onboarding ──────────────────────────────────────────────────────────────

  static void onboardingStepViewed(String stepName) {
    _event('onboarding_step_viewed', {'step': stepName});
  }

  static void onboardingStepCompleted(String stepName, [Map<String, Object>? params]) {
    _event('onboarding_step_completed', {'step': stepName, ...?params});
  }

  static void onboardingCompleted() {
    _event('onboarding_completed');
  }

  // ─── Authentication ───────────────────────────────────────────────────────────

  static void loginAttempted(String method) {
    _event('login_attempted', {'method': method});
  }

  static void loginSuccess(String method) {
    _event('login_success', {'method': method});
  }

  static void loginFailed(String method, String reason) {
    _event('login_failed', {'method': method, 'reason': reason});
  }

  static void registerAttempted() {
    _event('register_attempted');
  }

  static void registerSuccess() {
    _event('register_success');
  }

  static void registerFailed(String reason) {
    _event('register_failed', {'reason': reason});
  }

  static void loggedOut() {
    _event('logged_out');
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────────

  static void dashboardRefreshed() {
    _event('dashboard_refreshed');
  }

  // ─── Meal logging ─────────────────────────────────────────────────────────────

  static void mealAddOpened() {
    _event('meal_add_sheet_opened');
  }

  static void mealInputModeSelected(String mode) {
    _event('meal_input_mode_selected', {'mode': mode});
  }

  static void mealVoiceRecordStarted() {
    _event('meal_voice_record_started');
  }

  static void mealVoiceRecordStopped(int durationSeconds) {
    _event('meal_voice_record_stopped', {'duration_s': durationSeconds});
  }

  static void mealPhotoTaken() {
    _event('meal_photo_taken');
  }

  static void mealParsed(int itemCount, String mode) {
    _event('meal_parsed', {'item_count': itemCount, 'mode': mode});
  }

  static void mealSaved({
    required int itemCount,
    required String mode,
    String? emotion,
    int? totalCalories,
  }) {
    _event('meal_saved', {
      'item_count': itemCount,
      'mode': mode,
      'emotion': emotion ?? '',
      'total_calories': totalCalories ?? 0,
    });
  }

  static void mealSaveFailed(String reason) {
    _event('meal_save_failed', {'reason': reason});
  }

  static void emotionSelected(String emotion) {
    _event('emotion_selected', {'emotion': emotion});
  }

  // ─── Chat / AI ────────────────────────────────────────────────────────────────

  static void chatMessageSent(int messageIndex) {
    _event('chat_message_sent', {'message_index': messageIndex});
  }

  static void chatResponseReceived(int responseIndex) {
    _event('chat_response_received', {'response_index': responseIndex});
  }

  // ─── Tariffs / Subscription ───────────────────────────────────────────────────

  static void tariffsViewed() {
    _event('tariffs_viewed');
  }

  static void tariffSelected(String tariffCode, double price) {
    _event('tariff_selected', {'tariff_code': tariffCode, 'price': price});
  }

  static void subscriptionPurchaseStarted(String tariffCode, double price) {
    _event('subscription_purchase_started', {
      'tariff_code': tariffCode,
      'price': price,
    });
    _reportRevenue(tariffCode, price);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────────

  static void languageChanged(String languageCode) {
    _event('language_changed', {'language': languageCode});
    AppMetrica.reportUserProfile(
      AppMetricaUserProfile([
        AppMetricaStringAttribute.withValue('language', languageCode),
      ]),
    );
  }

  // ─── Onboarding profile enrichment ───────────────────────────────────────────

  static void onboardingStepCompletedWithData(
      String step, Map<String, Object> data) {
    _event('onboarding_step_completed', {'step': step, ...data});
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  static void _event(String name, [Map<String, Object>? params]) {
    if (params == null || params.isEmpty) {
      AppMetrica.reportEvent(name);
    } else {
      AppMetrica.reportEventWithMap(name, params);
    }
  }

  static void _reportRevenue(String tariffCode, double price) {
    AppMetrica.reportRevenue(
      AppMetricaRevenue(
        Decimal.parse(price.toString()),
        'RUB',
        productId: tariffCode,
        quantity: 1,
      ),
    );
  }
}

/// GoRouter-compatible navigator observer that reports screen names to AppMetrica.
class AppMetricaRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _reportScreen(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _reportScreen(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _reportScreen(previousRoute);
  }

  void _reportScreen(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      AppMetrica.reportEventWithMap('screen_view', {'screen': name});
    }
  }
}
