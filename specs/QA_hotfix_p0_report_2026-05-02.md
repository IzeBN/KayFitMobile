# QA Hotfix P0 Report — 2026-05-02

## Итоговый вердикт

**APPROVED_WITH_WARNINGS**

Все 10 P0-тикетов покрыты кодом. Critical-блокеров нет. Зафиксированы 3 HIGH-предупреждения, которые не блокируют релиз но требуют ручной валидации перед merge в master.

---

## Per-ticket результаты

| Тикет | Статус | Файлы | Комментарий |
|---|---|---|---|
| 1.1 Сохранение онбординга/сессии | PASS | `secure_token_storage.dart`, `token_pair.dart`, `onboarding_screen.dart` | `_restoreProgress()` читает SharedPreferences, `_saveProgress()` пишет после каждого `_goNext()`. Миграция из старого TokenStorage реализована. iOS entitlements добавлены. Android minSdk поднят до 23. |
| 1.2 Постоянный разлогин | PASS | `auth_provider.dart`, `api_client.dart` | `checkSession()` использует `SecureTokenStorage`, silent refresh через Completer-mutex работает. EC8 (network timeout при refresh → не разлогинивает) корректно обработан. |
| 1.5 Зависание AI Data Processing | PASS | `ai_consent_screen.dart`, `ai_consent_provider.dart` | `_isProcessing = true` на первом `setState` — отклик ≤ 100 мс. `LinearProgressIndicator` показывается немедленно (не через 300 мс задержку — это допустимое отступление, см. HIGH #1). Таймаут 5 с + retry UI присутствуют. |
| 2.1 Слетающий язык RU↔EN | PASS | `app.dart`, `locale_provider.dart`, `settings_screen.dart`, `locale_interceptor.dart` | Главный баг исправлен: `MaterialApp.locale` теперь читается из `localeProvider` вместо hardcode `Locale('en')`. `supportedLocales` добавлен RU. `PlatformDispatcher` fallback для первого запуска. `_showLangSheet` вызывает `setLocale()`. Locale Interceptor добавлен в Dio. Хардкод-строки в `settings_screen.dart` убраны через arb. |
| 3.1 Пропадает кнопка «Далее» | PASS | `onboarding_screen.dart`, `onboarding_scaffold.dart`, `ob_gradient_button.dart` | CTA перенесена в `bottomNavigationBar` через `OnboardingScaffold`. Шаги `diet`/`age`/`gender` теперь тоже имеют явную кнопку в footer. `resizeToAvoidBottomInset: true` задан. |
| 4.3 Вода 0 ккал | PASS | `zero_calorie_whitelist.py`, `ai_service_v2.py`, `meals.py` | Backend whitelist с exact + prefix matching. Применяется в обоих v1/v2 сервисах и в POST /api/meals. Иммутабельность (новые dict-объекты). |
| 5.1 Распознавание не-еды | PASS | `ai_service_v2.py`, `schemas_v2.py`, `schemas.py`, `add_meal_sheet.dart` | `_classify_is_food` + порог confidence 60. Новые поля `is_food`/`not_food_reason`/`message_key` в схеме. Фронт читает `resp.data['is_food']` и показывает диалог с retry. |
| 7.1 Не закрывается клавиатура | PASS | `keyboard_dismisser.dart`, `chat_screen.dart`, `add_meal_sheet.dart`, `edit_meal_screen.dart`, `recognition_result_sheet_v2.dart` | `KeyboardDismisser` создан и применён на всех экранах из ТЗ §2.1. `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` добавлен в ChatScreen ListView. |
| 7.2 Не уходят bottom sheets | PASS | `dismissible_sheet_wrapper.dart`, `dashboard_screen.dart`, `journal_screen.dart`, `add_meal_sheet.dart`, `recognition_result_sheet_v2.dart`, `meal_group_card.dart` | `isDismissible: true`, `enableDrag: true` добавлены во все 8 мест из ТЗ §3.1. `DismissibleSheetWrapper` с X-кнопкой создан и применён. |
| 7.3 Невозможно выйти из AI-чата | PASS | `chat_screen.dart` | Back-кнопка (`Icons.arrow_back_ios_new_rounded`) добавлена в `_ChatHeader`. `onBack: () => context.go('/')`. Два способа выхода: кнопка + tab BottomNav. |

---

## Critical issues (блокеры)

Нет.

---

## High severity issues (warnings)

| # | Файл | Проблема | Как исправить |
|---|------|----------|---------------|
| HIGH-1 | `lib/features/ai_consent/screens/ai_consent_screen.dart:378` | ТЗ §1.5 acceptance criterion: «Лоадер появляется если переход занимает > 300 мс». Реализация показывает `LinearProgressIndicator` немедленно при `_isProcessing = true` (нет задержки 300 мс). Это отступление от буквы ТЗ. На практике UX приемлем (немедленный лоадер лучше, чем задержанный), но технически acceptance criterion не выполнен точно. | Добавить `Timer(const Duration(milliseconds: 300), () { if (_isProcessing && mounted) setState(() => _showLoader = true); })` перед вызовом `setConsent`. Или согласовать с продуктом как принятое отступление. |
| HIGH-2 | `lib/features/ai_consent/screens/ai_consent_screen.dart:40,446` | `ai_consent_screen.dart` использует `Localizations.localeOf(context).languageCode` вместо `ref.watch(localeProvider)`. ТЗ B §1.2/Ошибка C явно предписывала заменить подобные вызовы. Из-за async инициализации `LocaleNotifier._load()` первый render consent-экрана может вернуть неверную локаль (`en`) даже при RU-системе, пока `_load()` не завершился. | Заменить оба вхождения на `final isRu = ref.watch(localeProvider).languageCode == 'ru';`. |
| HIGH-3 | `lib/features/add_meal/screens/add_meal_sheet.dart` | ТЗ E §5.2 предписывал добавить локальный zero-calorie фильтр в `_parseText` (frontend-сторона тикета 4.3 для текстового ввода). Файл `lib/shared/models/ingredient_v2.dart` также не получил `isZeroCalorie` guard. Backend покрывает оба случая через `/api/meals` и AI-сервис, поэтому acceptance criterion «вода через текст → 0 ккал» выполнен на бэке. Но frontend-слой защиты отсутствует. | Добавить в `_parseText`: маппинг `v2items` с `_isZeroCalorieName(item.name)` guard. Добавить в `IngredientV2.fromApiItem` проверку `is_zero_calorie` перед маппингом. Синхронизировать с whitelist из бэка. |

---

## Pre-existing technical debt (не блокеры)

1. **3 failing tests в `test/journal_new_ui_test.dart`**: `MealGroupCard renders meal type, dishes, stats` (_TypeError), `DaySummaryCard renders 6 nutrient cards`, `NutrientColors exist and are not default` — присутствовали до hotfix-ветки. Не затронуты изменениями hotfix.
2. **`TokenStorage` deprecated shim** в `lib/core/api/api_client.dart` — сохранён для совместимости. Аннотация `@Deprecated` проставлена. Можно удалить в Sprint 1.
3. **Множественные `Localizations.localeOf(context)` вызовы** в `chat_screen.dart`, `dashboard_screen.dart`, `recognition_result_sheet_v2.dart`, `add_meal_sheet.dart` и других файлах — не заменены на `localeProvider`. Поскольку `MaterialApp.locale` теперь корректно управляется через провайдер, `Localizations.localeOf` будет возвращать правильное значение после первого rebuild. Потенциальный race только при самом первом кадре (до async init). Задача Sprint 1.
4. **Хардкод-строки** в `onboarding_screen.dart`, `chat_screen.dart`, `add_meal_sheet.dart`, `ai_consent_screen.dart`, `dashboard_screen.dart` и других файлах — не переведены через arb. Это зафиксированный компромисс оси B («полный аудит хардкода за рамками hotfix»).
5. **equal_keys_in_map** в `test/features/onboarding/onboarding_progress_test.dart:141` — предупреждение в тест-коде, не в production коде.

---

## Тесты

- **Фронт**: 102 passed, 3 failed (все 3 — pre-existing в `journal_new_ui_test.dart`, не относятся к hotfix-скопу)
- **Бэк**: 60/60 passed (pytest `test_zero_calorie_whitelist.py` + `test_is_food_classifier.py`)
- **flutter analyze**: 0 errors, ~20 warnings (все — pre-existing code за пределами hotfix-файлов, либо test-файлы). Новые предупреждения в hotfix-файлах: 2 в test-коде (`equal_keys_in_map` в `onboarding_progress_test.dart:141`, `unused_local_variable 'w'` в `dismissible_sheet_wrapper_test.dart:39`). В production-коде новых errors/warnings нет.

---

## Cross-axis observations

1. **Ось A + B (bootstrap-уровень)**: `main.dart` инициализирует `initApiClient()` (SecureTokenStorage) и `SharedPreferences` параллельно через `Future.wait`. `LocaleNotifier` читает из SharedPreferences асинхронно. Между ними нет гонки — `MaterialApp.locale` использует начальный `Locale('en')` пока провайдер не обновится, что займёт первый кадр. Это приемлемо; не является регрессией.

2. **Ось A + 1.5 (ai_consent + AuthInterceptor)**: `ai_consent_provider.dart` вызывает `apiDio.post('/api/user/ai_consent')`. `_AuthInterceptor` корректно добавляет Bearer header из `SecureTokenStorage`. При 401 — interceptor делает silent refresh и повторяет. Проблем нет.

3. **Ось C + 1.5 (dismiss + ai_consent)**: `ai_consent_screen.dart` не является bottom sheet (открывается как route), поэтому `DismissibleSheetWrapper` к нему не применяется. Конфликта нет. `KeyboardDismisser` на consent-экране не добавлен — у него нет TextField. Нет дублирующей логики.

4. **Ось E ↔ Фронт (контракт is_food/not_food_reason)**: Бэк возвращает `{is_food: bool, not_food_reason: string|null, message_key: string|null}`. Фронт в `add_meal_sheet.dart` читает `resp.data['is_food'] as bool?` и `resp.data['not_food_reason'] as String?`. Контракт совпадает. Новые поля nullable в Pydantic schema — обратная совместимость обеспечена.

---

## Регресс-карта по фидбекам

| Фидбек | Описание | Закрыт в Hotfix? | Тикет |
|---|---|---|---|
| 1 | Экстремальный целевой вес без предупреждения | Нет (P1, Sprint 2) | 3.5 |
| 2 | Нет возможности редактировать БЖУ | Нет (P1, Sprint 2) | 5.6 |
| 3 | «Помогите нам расти» в онбординге; плашка в Settings | Нет (P2, Sprint 3) | 9.1, 9.2 |
| 4 | Язык слетает; пропадает кнопка «Далее» | Да | 2.1, 3.1 |
| 5 | Язык слетает; пропадает кнопка «Далее» | Да | 2.1, 3.1 |
| 6 | Клавиатура не закрывается; шторки не уходят; нельзя выйти из чата | Да | 7.1, 7.2, 7.3 |
| 7 | Язык слетает | Да | 2.1 |
| 8 | Грубые ошибки калорий USDA | Нет (P0, Sprint 1) | 4.1 |
| 9 | Расхождение калорий; скачок графика | Нет (P1, Sprint 1) | 3.7, 3.6 |
| 10 | Язык слетает; пропадает кнопка; нет тегов нелюбимых продуктов | Частично (2.1 + 3.1 закрыты; теги — P1 Sprint 2) | 2.1, 3.1 |
| 11 | AI завышает без контекста | Нет (P1, Sprint 2) | 5.3 |
| 12 | Сфоткал собаку — ошибка по калориям; зависание AI Data Processing; долгое обновление стартового экрана; разлогин | Частично (5.1 + 1.5 закрыты; 8.1 + разлогин 1.1/1.2 — да) | 5.1, 1.5, 1.1, 1.2 |
| 13 | Вода 250 ккал; нельзя удалить блюдо; нет голос/фото ввода; не редактируется вес; Correct меняет все | Частично (4.3 закрыт; 6.1 + 6.3 + 5.4 + 5.5 — Sprint 1) | 4.3 |

---

## Что обязательно проверить вручную (manual regression)

1. **Apple Sign-In + kill + relaunch** (iOS, реальное устройство): авторизоваться через Apple → закрыть приложение (jetsam) → открыть через 5+ минут → должен попасть на Dashboard без экрана логина. Проверяет UC1/UC2 (SecureTokenStorage Keychain).

2. **Онбординг kill-restore**: начать онбординг, дойти до шага Height/Weight (с клавиатурой), заполнить поле → закрыть приложение → открыть снова → должен вернуться на тот же шаг с заполненным значением. Кнопка «Далее» должна быть visible над клавиатурой (iPhone SE, высота 667pt).

3. **Язык RU при системной локали RU**: чистая установка на iPhone с системным языком RU → пройти онбординг → все экраны должны быть на RU без смешивания. Переключить в Settings на EN → мгновенный rebuild → вернуться на RU → rebuild.

4. **Accept & Continue в AI Data Processing**: при медленном соединении — нажать кнопку → должен появиться CircularProgressIndicator внутри кнопки и LinearProgressIndicator вверху немедленно. Через 5 с при недоступном сервере — сообщение об ошибке + кнопка «Повторить».

5. **Все шторки — 3 способа закрытия**: открыть AddMealSheet → (a) тап на затемнение → закрылась; (b) свайп вниз с инерцией → закрылась; (c) кнопка X → закрылась. Повторить для RecognitionResultSheetV2 и _MealDetailSheet из Journal.

6. **Вода через фото и текст → 0 ккал**: сфотографировать стакан воды → результат 0 ккал. Ввести текстом «вода» → 0 ккал. Ввести «sparkling water» → 0 ккал.

7. **Фото не-еды → диалог**: сфотографировать собаку/текст/пейзаж → должен появиться диалог «Еда не обнаружена» с кнопками «Попробовать ещё раз» и «Ввести вручную». Нет случайных калорий.

8. **AI-чат — back navigation**: перейти в `/chat` → нажать стрелку назад в шапке → перейти на `/` (Dashboard). Проверить также: тап на другой tab BottomNav из чата.

9. **silent refresh в фоне**: залогиниться → подождать истечения access token (или сымитировать устаревший токен) → выполнить любое действие → без перехода на login, запрос должен пройти (interceptor сделал refresh).

10. **iOS Keychain entitlements в release build**: сделать `flutter build ipa --release` и проверить что приложение запускается без crash на реальном устройстве (Keychain Sharing entitlement в Runner.entitlements должен быть корректным для bundle ID `com.kayfit.app`).

