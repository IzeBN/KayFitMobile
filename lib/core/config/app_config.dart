/// Application-wide configuration constants.
///
/// [googleClientId] must be replaced with the real Web Client ID
/// from Google Cloud Console → APIs & Services → Credentials.
class AppConfig {
  AppConfig._();

  /// Google Sign-In Web Client ID.
  /// Replace with real value from Google Cloud Console.
  static const googleClientId =
      'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';

  static const telegramBotUrl = 'https://t.me/kayfit_bot?start=1';
  static const baseUrl = 'https://app.kayfit.ru';
  static const deepLinkScheme = 'kayfit';
}
