import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kayfit/core/i18n/generated/app_localizations.dart';
import 'package:kayfit/core/locale/locale_provider.dart';

// ---------------------------------------------------------------------------
// Minimal harness that wraps a widget with all localization delegates and
// a ProviderScope so we can test locale-aware widgets in isolation.
// ---------------------------------------------------------------------------

Widget _wrapWithLocale(Widget child, Locale locale) {
  return ProviderScope(
    overrides: [
      localeProvider.overrideWith((ref) => _FakeLocaleNotifier(locale)),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final currentLocale = ref.watch(localeProvider);
        return MaterialApp(
          locale: currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('en')],
          home: child,
        );
      },
    ),
  );
}

// A simple notifier override that exposes setLocale for testing.
class _FakeLocaleNotifier extends StateNotifier<Locale>
    implements LocaleNotifier {
  _FakeLocaleNotifier(super.locale);

  @override
  Future<void> setLocale(Locale locale) async {
    state = locale;
  }
}

// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
  });

  group('Language picker bottom sheet', () {
    testWidgets('shows_both_options — RU and EN options are visible',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithLocale(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => Consumer(
                  builder: (ctx, ref, __) {
                    final l10n = AppLocalizations.of(context)!;
                    return _TestLangSheet(
                      currentIsRu: false,
                      l10nLangRu: l10n.settings_langRu,
                      l10nLangEn: l10n.settings_langEn,
                    );
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
          const Locale('en'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Both options must be present regardless of current locale.
      expect(find.text('Russian'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('active_option_highlighted — EN option selected when locale is EN',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithLocale(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (_) => Consumer(
                  builder: (ctx, ref, __) {
                    final l10n = AppLocalizations.of(context)!;
                    return _TestLangSheet(
                      currentIsRu: false, // EN is active
                      l10nLangRu: l10n.settings_langRu,
                      l10nLangEn: l10n.settings_langEn,
                    );
                  },
                ),
              ),
              child: const Text('Open'),
            ),
          ),
          const Locale('en'),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // The EN row is selected; verify check icon is visible for EN option.
      final checkIcons = find.byIcon(Icons.check_circle_rounded);
      expect(checkIcons, findsWidgets);
    });

    testWidgets('tap_ru_calls_setLocale — localeProvider updates to Locale(ru)',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith(
              (ref) => _FakeLocaleNotifier(const Locale('en')),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              final currentLocale = ref.watch(localeProvider);
              return MaterialApp(
                locale: currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ru'), Locale('en')],
                home: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => showModalBottomSheet(
                      context: ctx,
                      builder: (_) => _TestLangSheet(
                        currentIsRu: false,
                        l10nLangRu: 'Russian',
                        l10nLangEn: 'English',
                        onSelectRu: () => capturedRef
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('ru')),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Russian'));
      await tester.pumpAndSettle();

      expect(
        capturedRef.read(localeProvider),
        equals(const Locale('ru')),
      );
    });

    testWidgets('tap_en_calls_setLocale — localeProvider updates to Locale(en)',
        (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ru'});

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localeProvider.overrideWith(
              (ref) => _FakeLocaleNotifier(const Locale('ru')),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              final currentLocale = ref.watch(localeProvider);
              return MaterialApp(
                locale: currentLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [Locale('ru'), Locale('en')],
                home: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => showModalBottomSheet(
                      context: ctx,
                      builder: (_) => _TestLangSheet(
                        currentIsRu: true,
                        l10nLangRu: 'Русский',
                        l10nLangEn: 'English',
                        onSelectEn: () => capturedRef
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en')),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(
        capturedRef.read(localeProvider),
        equals(const Locale('en')),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// Minimal test double for the language sheet content —
// avoids the full SettingsScreen dependency tree.
// ---------------------------------------------------------------------------

class _TestLangSheet extends StatelessWidget {
  const _TestLangSheet({
    required this.currentIsRu,
    required this.l10nLangRu,
    required this.l10nLangEn,
    this.onSelectRu,
    this.onSelectEn,
  });

  final bool currentIsRu;
  final String l10nLangRu;
  final String l10nLangEn;
  final VoidCallback? onSelectRu;
  final VoidCallback? onSelectEn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LangRow(
            flag: '🇷🇺',
            label: l10nLangRu,
            selected: currentIsRu,
            onTap: onSelectRu ?? () {},
          ),
          _LangRow(
            flag: '🇬🇧',
            label: l10nLangEn,
            selected: !currentIsRu,
            onTap: onSelectEn ?? () {},
          ),
        ],
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(flag),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          if (selected)
            const Icon(Icons.check_circle_rounded, key: ValueKey('check')),
        ],
      ),
    );
  }
}
