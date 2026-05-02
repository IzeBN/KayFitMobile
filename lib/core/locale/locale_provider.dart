import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'app_locale';
  static const _supportedCodes = {'ru', 'en'};

  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);

    if (code != null && _supportedCodes.contains(code)) {
      state = Locale(code);
      return;
    }

    // No saved preference — derive from system locale.
    final systemCode =
        PlatformDispatcher.instance.locale.languageCode;
    if (_supportedCodes.contains(systemCode)) {
      state = Locale(systemCode);
    }
    // else: remain at default Locale('en')
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
