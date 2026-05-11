import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] keys used by the BodyForm feature.
///
/// Keeping keys in one place avoids string drift across screens/tests and
/// makes it cheap to migrate later when the values move into [UserProfile]
/// or the backend.
abstract final class BodyFormPrefs {
  static const String _kCurrent = 'body_form_current';
  static const String _kDesired = 'body_form_desired';

  /// Persist the user's selection. Both indices are 0-based (0..6).
  static Future<void> save({required int current, required int desired}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrent, current);
    await prefs.setInt(_kDesired, desired);
  }

  /// Load the previously saved selection, if any.
  static Future<({int current, int desired})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getInt(_kCurrent);
    final d = prefs.getInt(_kDesired);
    if (c == null || d == null) return null;
    return (current: c, desired: d);
  }

  /// Remove the saved selection (used by dev-logout / reset flows).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCurrent);
    await prefs.remove(_kDesired);
  }
}
