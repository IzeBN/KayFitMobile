import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences wrapper for the post-goal Reward step.
///
/// Stores one of: `'clothes' | 'travel' | 'event' | 'gift'`.
abstract final class RewardPrefs {
  static const String _kKey = 'onboarding_reward';

  static const List<String> options = ['clothes', 'travel', 'event', 'gift'];

  static Future<void> save(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, value);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKey);
  }
}
