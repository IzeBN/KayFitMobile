# ТЗ: Ось B — Локализация · Тикет P0-2.1
**Версия:** 1.0  
**Дата:** 2026-05-02  
**Статус:** готово к имплементации  
**Исполнитель:** frontend-dev

---

## 0. Допущения

1. `flutter gen-l10n` используется (подтверждено `l10n.yaml` и наличием `app_localizations.dart`).
2. `app_en.arb` считается мастер-файлом (так указано в `l10n.yaml`). Допущение: смена на `app_ru.arb` как мастер не требуется, оба файла поддерживаются паритетно.
3. Бэкенд принимает язык через query-параметр `language=ru|en` (подтверждено openapi.json). Заголовок `Accept-Language` бэк не читает — используем query-параметр в Dio interceptor.
4. Минимальные поддерживаемые локали: `ru`, `en`. Fallback — `en`.
5. `UserProfileRequest.language` (опциональное string поле) существует в openapi.json — синхронизация с бэком возможна через `POST /api/profile`.

---

## 1. Аудит текущего состояния

### 1.1 Инфраструктура l10n

| Компонент | Путь | Статус |
|-----------|------|--------|
| Конфиг генерации | `l10n.yaml` | Существует. `arb-dir: lib/core/i18n`, `template: app_ru.arb`, вывод в `lib/core/i18n/generated/` |
| arb RU | `lib/core/i18n/app_ru.arb` | Существует, 166 ключей |
| arb EN | `lib/core/i18n/app_en.arb` | Существует, 166 ключей — полный паритет с RU |
| Сгенерированный класс | `lib/core/i18n/generated/app_localizations.dart` | Существует |
| Locale provider | `lib/core/locale/locale_provider.dart` | Существует (`StateNotifierProvider`, SP-ключ `app_locale`) |

### 1.2 Корневая причина — три независимые ошибки

**Ошибка A (критическая):** в `lib/app.dart` строка 27:
```
locale: const Locale('en'),        // ХАРДКОД — игнорирует localeProvider
supportedLocales: const [Locale('en')],   // RU не объявлен как поддерживаемый
```
`LocaleNotifier` существует и даже читает SharedPreferences, но `MaterialApp.router` его не использует. Любая смена языка через provider не оказывает никакого эффекта — MaterialApp заблокирован на `en`.

**Ошибка B (средняя):** `_showLangSheet` в `settings_screen.dart` (строка 285) показывает только English, кнопка всегда `selected: true`, вызов `setLocale` отсутствует. Переключатель есть визуально, но не работает.

**Ошибка C (средняя):** несколько экранов читают текущий язык через `Localizations.localeOf(context).languageCode` (строки 65, 211, 615 в `settings_screen.dart`) вместо `localeProvider` — при гонке инициализации (до первого rebuild после async `_load()`) получают системную локаль вместо сохранённой.

### 1.3 Хардкод-строки в UI (найдены в settings_screen.dart)

Полный список по другим экранам — отдельный аудит-задание для frontend-dev. Вот подтверждённые хардкод-строки из одного файла `settings_screen.dart`:

| # | Файл (строка) | Хардкод-строка RU | Хардкод-строка EN | Предлагаемый arb-ключ |
|---|--------------|--------------------|--------------------|----------------------|
| 1 | `settings_screen.dart:212` | `'Удалить аккаунт?'` | `'Delete account?'` | `settings_delete_account_title` |
| 2 | `settings_screen.dart:217` | `'Все ваши данные будут удалены без возможности восстановления. Это действие необратимо.'` | `'All your data will be permanently deleted. This action cannot be undone.'` | `settings_delete_account_body` |
| 3 | `settings_screen.dart:228` | `'Отмена'` | `'Cancel'` | уже есть: `common_cancel` |
| 4 | `settings_screen.dart:237` | `'Удалить'` | `'Delete'` | уже есть: `common_delete` |
| 5 | `settings_screen.dart:647` | `'Удалить аккаунт'` | `'Delete account'` | `settings_delete_account_btn` |
| 6 | `settings_screen.dart:93` | `'🇬🇧 EN'` (trailing языкового пункта) | — | `settings_lang_current_en` / `settings_lang_current_ru` |

Дополнительные хардкод-строки в других файлах — см. раздел 4.

---

## 2. Решение

### 2.1 Исправление app.dart

Файл `lib/app.dart` содержит единственный блокирующий баг: `locale: const Locale('en')` и `supportedLocales: [Locale('en')]`.

**Требуемое состояние после правки:**

- `locale` читается из `localeProvider` через `ref.watch`
- `supportedLocales` содержит `[Locale('ru'), Locale('en')]`
- `localeResolutionCallback` реализует fallback: если системная локаль поддерживается — вернуть её; иначе — `Locale('en')`

`LocaleNotifier` уже существует и корректен (читает SP, дефолт `en`). Менять `locale_provider.dart` не нужно — только подключить в `app.dart`.

**Изменение дефолта в `locale_provider.dart`:**  
Текущий дефолт: `Locale('en')`. По требованию продукта (§2.1 ТЗ): при отсутствии SP-записи и при системной локали RU → должен быть `ru`. Правка `_load()`: добавить логику чтения `PlatformDispatcher.instance.locale` как промежуточного шага между SP и хардкодным fallback.

### 2.2 LocaleNotifier — финальная логика инициализации

Алгоритм `_load()` в `LocaleNotifier`:

```
1. Читать SharedPreferences ключ 'app_locale'
2. Если значение есть → state = Locale(code)  [уже реализовано]
3. Если значения нет → проверить PlatformDispatcher.instance.locale.languageCode
   3a. Если languageCode == 'ru' → state = Locale('ru')
   3b. Иначе → state остаётся Locale('en')  [дефолт]
```

Эта логика покрывает UC1 (первый запуск, RU система) и UC2 (первый запуск, FR/другой язык → EN fallback).

### 2.3 LocalePicker в Settings

**Файл:** `lib/core/locale/locale_picker.dart` — новый виджет.

**Поведение:**
- Отображает два варианта: 🇷🇺 Русский / 🇬🇧 English
- При выборе вызывает `ref.read(localeProvider.notifier).setLocale(newLocale)`
- После смены вызывает `ref.read(profileRepositoryProvider).updateLanguage(newLocale.languageCode)` (fire-and-forget, ошибка не блокирует смену языка)
- Мгновенный rebuild: `MaterialApp.locale` меняется через Riverpod → все виджеты получают новый `AppLocalizations`

**Интеграция в settings_screen.dart:**  
Существующий метод `_showLangSheet` (строка 256) показывает bottomSheet. Требуется:
1. Добавить `_LangOption` для RU (аналогично существующему EN)
2. В `onTap` каждой опции вызвать `ref.read(localeProvider.notifier).setLocale(...)` и `Navigator.pop`
3. Заменить `selected: true` на `selected: currentLocale.languageCode == 'en'` / `'ru'`
4. `trailing` в `_NavItem` языка должен отражать текущий язык динамически (читать из `localeProvider`), а не хардкодить `'🇬🇧 EN'`

### 2.4 Dio LocaleInterceptor

**Файл:** `lib/core/api/locale_interceptor.dart` — новый.

Interceptor добавляет query-параметр `language` к эндпоинтам, которые его принимают.

**Эндпоинты с параметром language (из openapi.json):**
- `POST /api/onboarding/recognize_photo` — `?language=ru|en`
- `POST /api/onboarding/transcribe` — `?language=ru|en`
- `POST /api/transcribe` — `?language=ru|en`
- `POST /api/recognize_photo` — `?language=ru|en`
- `POST /api/onboarding/parse_meal` — body field `language` (строка в JSON)
- `POST /api/parse_meal` — body field `language` (строка в JSON)

**Поведение interceptor:**
- В `onRequest`: читать текущий `languageCode` из SharedPreferences (ключ `app_locale`, fallback `'ru'`)
- Для путей из списка выше — добавлять `options.queryParameters['language'] = langCode`
- Для путей где язык в body (`parse_meal`) — дополнять `options.data['language'] = langCode` если поле не задано явно

**Допущение:** interceptor читает SP напрямую (не через Riverpod provider) чтобы избежать необходимости передавать `Ref` в Dio layer. Это допустимо так как SP уже инициализирован к моменту первого запроса.

**Интеграция:** добавить `apiDio.interceptors.add(LocaleInterceptor())` в `initApiClient()` в `lib/core/api/api_client.dart`.

---

## 3. Бэк-зависимость

### 3.1 Что бэк уже поддерживает (без изменений)

| Эндпоинт | Способ передачи языка | Значения |
|----------|----------------------|---------|
| `POST /api/onboarding/recognize_photo` | query `language` | `ru`, `en` |
| `POST /api/onboarding/transcribe` | query `language` | `ru`, `en` |
| `POST /api/transcribe` | query `language` | `ru`, `en` |
| `POST /api/recognize_photo` | query `language` | `ru`, `en` |
| `POST /api/onboarding/parse_meal` | body field `language` | строка |
| `POST /api/parse_meal` | body field `language` | строка |
| `POST /api/profile` | body field `language` | строка (nullable) |

### 3.2 Что бэк НЕ поддерживает

Эндпоинты `GET /api/meals`, `GET /api/stats`, `GET /api/goals`, `GET /api/profile` — не принимают параметр языка. Они возвращают числовые данные или внутренние строки (названия блюд — вводятся пользователем). Локализации UI для этих данных на фронте не требуется: отображаются строки пользователя как есть.

`SubscriptionResponse.tariff_title` (строка от бэка) — видна пользователю. Если бэк не возвращает локализованный заголовок, frontend-dev должен создать словарь маппинга `tariff_title` → arb-ключ. Это задача постhotfix, не блокирует P0.

### 3.3 Вывод

Бэк готов. Изменений на бэкенде для P0-2.1 не требуется. Весь фикс — на фронте.

---

## 4. Полный аудит хардкод-строк

### Инструкция для frontend-dev

Выполнить grep по репозиторию перед началом работы:

```bash
# Кириллица в widget-коде (потенциальные хардкод RU-строки)
grep -rn '[А-Яа-яЁё]' lib/ --include="*.dart" | grep -v "//.*[А-Яа-я]" | grep -v ".arb"

# Англ. строки в Text() вызовах
grep -rn "Text('" lib/ --include="*.dart" | grep -v "//.*Text"
```

### Подтверждённые хардкод-строки (из прочитанных файлов)

| # | Файл | Строка | Текст | arb-ключ (предлагаемый) |
|---|------|--------|-------|------------------------|
| 1 | `settings_screen.dart` | 212 | `'Удалить аккаунт?'` / `'Delete account?'` | `settings_delete_account_title` |
| 2 | `settings_screen.dart` | 217 | `'Все ваши данные будут удалены...'` / `'All your data will be...'` | `settings_delete_account_body` |
| 3 | `settings_screen.dart` | 228 | `'Отмена'` / `'Cancel'` | дублирует `common_cancel` — использовать существующий ключ |
| 4 | `settings_screen.dart` | 237 | `'Удалить'` / `'Delete'` | дублирует `common_delete` |
| 5 | `settings_screen.dart` | 647 | `'Удалить аккаунт'` / `'Delete account'` | `settings_delete_account_btn` |
| 6 | `settings_screen.dart` | 93 | `'🇬🇧 EN'` (trailing) | динамически из `localeProvider` |
| 7 | `settings_screen.dart` | 65 | `Localizations.localeOf(context).languageCode` | заменить на `ref.watch(localeProvider).languageCode` |
| 8 | `settings_screen.dart` | 211 | `Localizations.localeOf(context).languageCode` (в `_confirmDeleteAccount`) | передавать `isRu` из build через параметр или читать из provider |
| 9 | `settings_screen.dart` | 615 | `Localizations.localeOf(context).languageCode` (в `_DeleteAccountCard.build`) | заменить на `ref.watch(localeProvider).languageCode` |

**Ожидаемый объём после полного grep:** 40–70 строк по всему проекту (онбординг, чат, add_meal, recognition экраны). Frontend-dev обязан провести полный grep и добавить найденные ключи в arb до PR.

### Новые arb-ключи для добавления в оба файла

| Ключ | RU | EN |
|------|----|----|
| `settings_delete_account_title` | `Удалить аккаунт?` | `Delete account?` |
| `settings_delete_account_body` | `Все ваши данные будут удалены без возможности восстановления. Это действие необратимо.` | `All your data will be permanently deleted. This action cannot be undone.` |
| `settings_delete_account_btn` | `Удалить аккаунт` | `Delete account` |
| `settings_lang_current` | `🇷🇺 RU` / `🇬🇧 EN` (динамически) | — |

---

## 5. Структура arb-файлов

### 5.1 Расположение

- `lib/core/i18n/app_ru.arb` — 166 ключей (мастер-шаблон по `l10n.yaml`)
- `lib/core/i18n/app_en.arb` — 166 ключей (перевод)
- После фикса: +3 новых ключа в каждом файле (из раздела 4)

### 5.2 Конвенция именования ключей

Формат: `<feature>_<element>_<modifier>`

| Префикс | Фича |
|---------|------|
| `common_` | общие глаголы/слова |
| `nav_` | нижняя навигация |
| `ob_` | онбординг |
| `auth_` | авторизация |
| `dashboard_` | главный экран |
| `addMeal_` | добавление блюда |
| `settings_` | настройки |
| `chat_` | AI-чат |
| `macro_` | макронутриенты |
| `error_` | ошибки |
| `wg_` | weight goals |

### 5.3 Правила placeholders

- Placeholder-имена в camelCase: `{kcal}`, `{count}`, `{days}`, `{msg}`
- Тип указывать явно в `@key` блоке
- Для кириллических единиц в EN-версии заменять на латиницу: `ккал` → `kcal`, `г` → `g`

---

## 6. Файлы для правки/создания

| Файл | Действие | Приоритет |
|------|----------|-----------|
| `lib/app.dart` | Правка: убрать `const Locale('en')`, подключить `localeProvider`, добавить RU в `supportedLocales` | КРИТИЧЕСКИЙ |
| `lib/core/locale/locale_provider.dart` | Правка: в `_load()` добавить чтение `PlatformDispatcher.instance.locale` как промежуточный шаг | КРИТИЧЕСКИЙ |
| `lib/core/api/locale_interceptor.dart` | Создать новый Dio interceptor | ВЫСОКИЙ |
| `lib/core/api/api_client.dart` | Правка: добавить `LocaleInterceptor` в `initApiClient()` | ВЫСОКИЙ |
| `lib/core/locale/locale_picker.dart` | Создать новый виджет для Settings | ВЫСОКИЙ |
| `lib/features/settings/screens/settings_screen.dart` | Правка: исправить `_showLangSheet`, убрать хардкод-строки, исправить чтение локали | ВЫСОКИЙ |
| `lib/core/i18n/app_ru.arb` | Добавить 3 новых ключа (раздел 4) | ВЫСОКИЙ |
| `lib/core/i18n/app_en.arb` | Добавить 3 новых ключа (раздел 4) | ВЫСОКИЙ |
| Все экраны с grep-найденными хардкодами | Правка: заменить хардкод на `AppLocalizations.of(context)!.key` | СРЕДНИЙ |
| `test/unit/locale_notifier_test.dart` | Создать unit-тесты | ОБЯЗАТЕЛЬНО |
| `test/widget/settings_lang_picker_test.dart` | Создать widget-тест | ОБЯЗАТЕЛЬНО |

**После правки `app.dart` обязательно запустить:**
```bash
flutter gen-l10n
flutter analyze
```

---

## 7. Сценарии использования (UC)

### UC1: Первый запуск, системная локаль RU

1. Пользователь устанавливает приложение. SharedPreferences пуст.
2. `LocaleNotifier._load()`: SP → нет записи → читает `PlatformDispatcher.instance.locale` → `ru`.
3. `state = Locale('ru')`.
4. `MaterialApp.locale = Locale('ru')`.
5. Все экраны отображают RU-строки.
6. Ожидаемый результат: 100% RU без каких-либо действий пользователя.

### UC2: Первый запуск, системная локаль FR (или любая не-RU)

1. SP пуст, `PlatformDispatcher.instance.locale` = `fr`.
2. `LocaleNotifier._load()`: FR не в списке `['ru', 'en']` → fallback `Locale('en')`.
3. Все экраны на EN.
4. Ожидаемый результат: EN fallback без ошибок.

### UC3: Пользователь меняет язык в Settings

1. Открывает Settings → пункт «Язык».
2. Видит bottomSheet с двумя опциями: 🇷🇺 Русский (возможно active) и 🇬🇧 English.
3. Тапает на другую опцию.
4. `localeProvider.notifier.setLocale(Locale('ru'))` → записывает в SP → меняет `state`.
5. `MaterialApp.locale` обновляется через `ref.watch` → Riverpod триггерит rebuild.
6. Все видимые виджеты перестраиваются с новым `AppLocalizations`.
7. BottomSheet закрывается.
8. Пользователь видит экран Settings на новом языке без перезапуска.
9. Fire-and-forget: `POST /api/profile { language: 'ru' }`.

### UC4: Kill + restart, язык сохранён

1. Пользователь выбрал RU в UC3.
2. Закрывает приложение (kill process).
3. Открывает снова.
4. `LocaleNotifier._load()`: SP → `'ru'` → `state = Locale('ru')`.
5. Приложение стартует на RU.

### UC5: API-запрос с языком пользователя

1. Пользователь выбрал `ru`, фотографирует еду.
2. `POST /api/recognize_photo` → `LocaleInterceptor.onRequest` добавляет `?language=ru`.
3. Бэк возвращает названия блюд на RU.
4. Аналогично для `POST /api/transcribe`, `/api/parse_meal`.

### UC6: Возврат с экрана не сбрасывает язык

1. Пользователь на RU → переходит на экран добавления блюда → возвращается назад.
2. `localeProvider` — Riverpod `StateNotifierProvider`, не зависит от навигации.
3. Язык сохранён. MaterialApp не перестраивается при pop.
4. Ожидаемый результат: язык не меняется.

---

## 8. Acceptance criteria (из ТЗ продукта §2.1 + §2.2)

- [ ] При системной локали RU — все экраны онбординга на RU без исключений при первом запуске
- [ ] Возврат назад в навигации не меняет язык
- [ ] После онбординга выбранный язык сохраняется при kill + restart
- [ ] В Settings есть переключатель RU/EN, визуально показывает активный язык
- [ ] Тап на переключатель мгновенно перестраивает все видимые экраны (≤ 1 кадр)
- [ ] Нет ни одного экрана со смешанной локализацией (RU+EN одновременно)
- [ ] `flutter analyze` не содержит ошибок после правок
- [ ] `flutter gen-l10n` не выдаёт предупреждений о недостающих ключах
- [ ] Все новые arb-ключи присутствуют в обоих файлах (RU и EN)
- [ ] Все запросы к AI-эндпоинтам содержат корректный параметр `language`
- [ ] Хардкод-строки из раздела 4 (минимум строки 1–6 из settings_screen.dart) убраны
- [ ] Unit-тест `LocaleNotifier`: init из SP, init из system locale, init fallback EN, setLocale сохраняет в SP
- [ ] Widget-тест `SettingsScreen`: тап на RU → текст заголовка меняется на RU

---

## 9. Тесты

### 9.1 Unit: LocaleNotifier

Файл: `test/unit/locale_notifier_test.dart`

| Тест | Arrange | Act | Assert |
|------|---------|-----|--------|
| init_from_sp_ru | SP содержит `'ru'` | `LocaleNotifier()` | `state == Locale('ru')` |
| init_from_sp_en | SP содержит `'en'` | `LocaleNotifier()` | `state == Locale('en')` |
| init_system_ru_no_sp | SP пуст, system locale `ru` | `LocaleNotifier()` | `state == Locale('ru')` |
| init_fallback_en | SP пуст, system locale `fr` | `LocaleNotifier()` | `state == Locale('en')` |
| setLocale_saves_to_sp | Пустой SP | `setLocale(Locale('ru'))` | SP содержит `'ru'`, `state == Locale('ru')` |
| setLocale_triggers_rebuild | `ProviderContainer` с listener | `setLocale(Locale('en'))` | listener вызван 1 раз |

### 9.2 Widget: LocalePicker / SettingsLangSheet

Файл: `test/widget/settings_lang_picker_test.dart`

| Тест | Сценарий |
|------|----------|
| shows_both_options | BottomSheet содержит `find.text('Русский')` и `find.text('English')` |
| active_option_highlighted | При `localeProvider = Locale('ru')` — опция RU имеет `selected: true` |
| tap_ru_calls_setLocale | Тап на RU → `localeProvider.state == Locale('ru')` |
| tap_en_calls_setLocale | Тап на EN → `localeProvider.state == Locale('en')` |

### 9.3 Widget: MaterialApp locale propagation

| Тест | Сценарий |
|------|----------|
| app_uses_locale_provider | При `localeProvider = Locale('ru')` — `AppLocalizations.of(context).nav_today` == `'Сегодня'` |
| app_rebuilds_on_locale_change | setLocale('en') → `AppLocalizations.of(context).nav_today` == `'Today'` |

---

## 10. Open questions

1. **Дефолтный язык при первом запуске.** Текущий `LocaleNotifier` дефолтит в EN. По пользовательской базе приложение ориентировано на RU-аудиторию. Если продукт хочет RU как дефолт безусловно (а не только при system locale RU) — `LocaleNotifier` нужно изменить: `super(const Locale('ru'))` без условия `PlatformDispatcher`. Ждём подтверждения от продукта.

2. **`tariff_title` от бэка.** `SubscriptionResponse.tariff_title` приходит строкой от сервера и отображается пользователю. Бэк не имеет механизма локализации этого поля (нет `Accept-Language` и нет двуязычных полей в schema). Нужно решение продукта: (a) бэк добавляет `tariff_title_en`/`tariff_title_ru`, (b) фронт ведёт словарь `tariff_code → arb_key`, (c) таргет только RU и это не проблема.

3. **iOS Info.plist.** При добавлении `Locale('ru')` в `supportedLocales` необходимо добавить `ru` в `CFBundleLocalizations` в `ios/Runner/Info.plist`. Без этого iOS может не передавать RU-строки системным виджетам (`DatePicker`, `CupertinoAlertDialog`). Это должен сделать developer при имплементации — зафиксируем как обязательный шаг в PR checklist.

---

## Резюме
