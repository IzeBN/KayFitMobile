# Kayfit — Flutter App Architecture

> Документ для разработки Flutter-приложения на основе существующего React/TypeScript фронтенда.
> Дата: 2026-03-04

---

## Стек и ключевые пакеты

```yaml
dependencies:
  # Navigation
  go_router: ^14.0.0

  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # HTTP + Cookies (session auth)
  dio: ^5.4.0
  dio_cookie_manager: ^3.1.0
  cookie_jar: ^4.0.0

  # Auth
  google_sign_in: ^6.2.0
  sign_in_with_apple: ^6.1.0
  app_links: ^6.1.0          # Telegram OAuth deep links

  # Models
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # i18n
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

  # Payments (WebView)
  webview_flutter: ^4.7.0

  # Media
  image_picker: ^1.1.0
  record: ^5.1.0             # Voice recording
  permission_handler: ^11.3.0

  # Storage
  shared_preferences: ^2.2.0

  # Charts (weight progress)
  fl_chart: ^0.68.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

---

## Структура проекта

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router + ProviderScope
├── router.dart                 # go_router конфиг
│
├── core/
│   ├── api/
│   │   ├── api_client.dart     # Dio + CookieJar + interceptors
│   │   └── api_endpoints.dart  # URL константы
│   ├── auth/
│   │   ├── auth_provider.dart  # Riverpod: текущий пользователь
│   │   └── session_guard.dart  # redirect логика go_router
│   └── i18n/
│       ├── app_ru.arb
│       ├── app_en.arb
│       └── l10n.dart           # AppLocalizations alias
│
├── features/
│   ├── onboarding/
│   │   ├── screens/
│   │   │   ├── landing_screen.dart
│   │   │   ├── age_screen.dart
│   │   │   ├── height_screen.dart
│   │   │   ├── gender_screen.dart
│   │   │   ├── weight_screen.dart
│   │   │   ├── training_screen.dart
│   │   │   ├── method_selection_screen.dart
│   │   │   ├── food_demo_screen.dart
│   │   │   ├── result_screen.dart
│   │   │   └── telegram_screen.dart
│   │   ├── providers/
│   │   │   └── onboarding_provider.dart
│   │   └── models/
│   │       └── onboarding_state.dart
│   │
│   ├── dashboard/
│   │   ├── screens/dashboard_screen.dart
│   │   ├── widgets/
│   │   │   ├── stats_card.dart
│   │   │   ├── macro_ring.dart
│   │   │   └── meal_list.dart
│   │   └── providers/dashboard_provider.dart
│   │
│   ├── journal/
│   │   ├── screens/journal_screen.dart
│   │   ├── widgets/meal_item.dart
│   │   └── providers/journal_provider.dart
│   │
│   ├── add_meal/
│   │   ├── screens/
│   │   │   ├── add_meal_fab.dart       # Bottom sheet / modal
│   │   │   ├── add_meal_simple.dart
│   │   │   ├── voice_input_screen.dart
│   │   │   ├── text_input_screen.dart
│   │   │   └── photo_input_screen.dart
│   │   └── providers/add_meal_provider.dart
│   │
│   ├── settings/
│   │   ├── screens/settings_screen.dart
│   │   └── providers/settings_provider.dart
│   │
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── telegram_auth_screen.dart
│   │   └── providers/auth_provider.dart
│   │
│   ├── tariffs/
│   │   ├── screens/tariffs_screen.dart
│   │   └── providers/tariffs_provider.dart
│   │
│   └── way_to_goal/
│       ├── screens/way_to_goal_screen.dart
│       └── providers/way_to_goal_provider.dart
│
└── shared/
    ├── widgets/
    │   ├── bottom_nav.dart
    │   ├── emotion_picker.dart
    │   └── loading_indicator.dart
    └── models/
        ├── meal.dart
        ├── goals.dart
        └── user_profile.dart
```

---

## API — эндпоинты (backend не меняется, кроме OAuth)

### Существующие (без изменений)

| Метод | URL | Описание |
|-------|-----|----------|
| GET | `/api/auth/me` | Текущий пользователь |
| GET | `/api/auth/logout` | Выход |
| GET | `/api/meals` | Список блюд (today + journal) |
| POST | `/api/meals` | Добавить блюдо |
| PUT | `/api/meals/{id}` | Редактировать |
| DELETE | `/api/meals/{id}` | Удалить |
| GET | `/api/stats` | Статистика (kcal eaten, remaining, compulsive) |
| GET | `/api/goals` | Цели БЖУ |
| POST | `/api/goals` | Сохранить цели |
| GET | `/api/profile` | Профиль (возраст, рост, вес, язык) |
| POST | `/api/profile` | Сохранить профиль |
| GET/POST | `/api/onboarding` | Ответы онбординга |
| POST | `/api/ai/parse_meal` | Распознать текст → КБЖУ |
| POST | `/api/ai/recognize_photo` | Фото → КБЖУ (Claude Vision) |
| POST | `/api/ai/transcribe` | Аудио → текст (Whisper) |
| POST | `/api/ai/chat` | AI-чат помощник |
| GET | `/api/tariffs` | Список тарифов |
| POST | `/api/payments/create` | Создать платёж YooKassa |
| GET | `/api/subscription` | Статус подписки |

### Новые (минимальные изменения backend)

| Метод | URL | Body | Описание |
|-------|-----|------|----------|
| POST | `/api/auth/google` | `{ id_token: str }` | Google OAuth |
| POST | `/api/auth/apple` | `{ identity_token: str, user_id: str, name?: str }` | Apple Sign-In |

---

## Auth — три метода

### 1. Google OAuth
```
Flutter                          Backend
  │                                │
  ├─ google_sign_in.signIn()        │
  ├─ получить idToken               │
  ├─ POST /api/auth/google ─────────┤
  │    { id_token }                 ├─ google-auth-library verify idToken
  │                                 ├─ создать/найти user по email
  │                                 ├─ SET session cookie
  │◄────────────── { user_id } ─────┤
  └─ сохранить сессию (CookieJar)   │
```

**Flutter код:**
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

Future<void> signInWithGoogle() async {
  final account = await _googleSignIn.signIn();
  final auth = await account!.authentication;
  await apiClient.post('/api/auth/google', data: {'id_token': auth.idToken});
}
```

**Backend (новый endpoint, ~30 строк):**
```python
# pip install google-auth
from google.oauth2 import id_token
from google.auth.transport import requests as grequests

@router.post("/auth/google")
async def auth_google(body: GoogleAuthRequest, request: Request):
    info = id_token.verify_oauth2_token(body.id_token, grequests.Request(), GOOGLE_CLIENT_ID)
    email = info["email"]
    # UPSERT user, создать сессию
```

### 2. Apple Sign-In
```
Flutter                          Backend
  │                                │
  ├─ SignInWithApple.getAppleIDCredential()
  ├─ получить identityToken         │
  ├─ POST /api/auth/apple ──────────┤
  │    { identity_token, user_id }  ├─ PyJWT decode (RS256, Apple JWKs)
  │                                 ├─ создать/найти user по sub (apple_id)
  │                                 ├─ SET session cookie
  │◄────────────── { user_id } ─────┤
  └─ сохранить сессию               │
```

**Backend (новый endpoint, ~40 строк):**
```python
# pip install PyJWT requests
import jwt, requests

def get_apple_public_keys():
    return requests.get("https://appleid.apple.com/auth/keys").json()["keys"]

@router.post("/auth/apple")
async def auth_apple(body: AppleAuthRequest, request: Request):
    header = jwt.get_unverified_header(body.identity_token)
    keys = get_apple_public_keys()
    # найти нужный ключ по kid, verify
    payload = jwt.decode(body.identity_token, public_key, algorithms=["RS256"], ...)
    apple_id = payload["sub"]  # уникальный id пользователя
    # UPSERT user, создать сессию
```

### 3. Telegram OAuth (существующий)
```
Flutter → открыть bot URL → Telegram → deep link → Flutter
deep link: kayfit://auth?token=xxx
→ GET /api/auth/telegram?token=xxx
→ SET session cookie
```

**Настройка:**
```dart
// AndroidManifest.xml / Info.plist: custom scheme "kayfit"
// app_links пакет перехватывает deep links
final _appLinks = AppLinks();
_appLinks.uriLinkStream.listen((uri) {
  if (uri.scheme == 'kayfit' && uri.host == 'auth') {
    final token = uri.queryParameters['token'];
    // GET /api/auth/telegram?token=token
  }
});
```

---

## i18n — миграция TypeScript → Flutter ARB

### Источник: `frontend/src/i18n/ru.ts` (341 ключ)

**Формат ARB:**
```json
// lib/core/i18n/app_ru.arb
{
  "@@locale": "ru",
  "nav_appName": "Calories",
  "nav_today": "Сегодня",
  "macro_calories": "Калории",
  "ob_landing_title1": "Худей",
  "ob_landing_title2": "просто",
  "@ob_demo_portion": {
    "placeholders": {
      "weight": { "type": "String" }
    }
  },
  "ob_demo_portion": "Порция {weight}"
}
```

**Использование:**
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// В виджете:
final l10n = AppLocalizations.of(context)!;
Text(l10n.nav_appName)
Text(l10n.ob_demo_portion(weight: "580г"))
```

**Группы ключей (по префиксу):**
- `nav_*` — навигация (6 ключей)
- `common_*` — общие (8)
- `macro_*` — макронутриенты (12)
- `dashboard_*` — главный экран (8)
- `journal_*` — журнал (2)
- `settings_*` — настройки (18)
- `addMeal_*` — добавить блюдо (30+)
- `simple_*` — быстрое добавление (9)
- `meal_*` — элемент блюда (5)
- `edit_*` — редактирование (6)
- `ob_*` — онбординг (50+)
- `wg_*` — путь к цели (30+)
- `tariffs_*` — тарифы (20+)
- `emotion_*` — эмоции (11)

---

## State Management — Riverpod провайдеры

```dart
// Текущий пользователь
@riverpod
Future<User?> currentUser(CurrentUserRef ref) async { ... }

// Цели дня (kcal, protein, fat, carbs)
@riverpod
Future<Goals> dailyGoals(DailyGoalsRef ref) async { ... }

// Блюда сегодня
@riverpod
Future<List<Meal>> todayMeals(TodayMealsRef ref) async { ... }

// Статистика (eaten, remaining)
@riverpod
Future<Stats> todayStats(TodayStatsRef ref) async { ... }

// Язык
@riverpod
class LanguageNotifier extends _$LanguageNotifier {
  // RU/EN, sync с backend /api/profile
}

// Статус подписки
@riverpod
Future<Subscription?> subscription(SubscriptionRef ref) async { ... }
```

---

## Navigation — go_router

```dart
final router = GoRouter(
  redirect: (context, state) {
    final user = ref.read(currentUserProvider).value;
    final isAuth = user != null;
    final isOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (!isAuth && !isOnboarding) return '/onboarding';
    if (isAuth && isOnboarding) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/tariffs', builder: (_, __) => const TariffsScreen()),
    GoRoute(path: '/way-to-goal', builder: (_, __) => const WayToGoalScreen()),
  ],
);
```

---

## Session — Dio + CookieJar

```dart
// core/api/api_client.dart
final cookieJar = PersistCookieJar(
  ignoreExpires: false,
  storage: FileStorage('${appDir}/cookies'),
);

final dio = Dio(BaseOptions(baseUrl: 'https://api.kayfit.ru'));
dio.interceptors.add(CookieManager(cookieJar));
dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) {
    if (error.response?.statusCode == 401) {
      // redirect to login
    }
    handler.next(error);
  },
));
```

---

## Онбординг — 10 шагов (аналог React)

| # | Экран | Данные | Backend |
|---|-------|--------|---------|
| 1 | Landing | — | — |
| 2 | Возраст | `profile.age` | POST /api/profile |
| 3 | Рост | `profile.height` | POST /api/profile |
| 4 | Пол | `answer q_id=3` | POST /api/onboarding |
| 5 | Вес (current+goal) | `profile.weight/target` | POST /api/profile |
| 6 | Тренировки | `answer q_id=1` | POST /api/onboarding |
| 7 | Выбор метода | — | — |
| 8 | Демо результата | — | — |
| 9 | Результат (КБЖУ) | локальный расчёт | POST /api/goals |
| 10 | Telegram / auth | — | — |

**Формула Миффлина-Сан Жеора (как в React):**
```dart
double calculateBMR(double weight, double height, int age, String gender) {
  if (gender == 'male') {
    return 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    return 10 * weight + 6.25 * height - 5 * age - 161;
  }
}

double calculateTDEE(double bmr, int trainingDaysCount) {
  const factors = [1.2, 1.375, 1.55, 1.725];
  final idx = (trainingDaysCount / 2).floor().clamp(0, 3);
  return bmr * factors[idx];
}
```

---

## Payments — YooKassa WebView

```dart
// После POST /api/payments/create → получить confirmation_url
// Открыть WebView, ждать redirect на success/fail URL

Navigator.push(context, MaterialPageRoute(
  builder: (_) => WebViewScreen(
    url: confirmationUrl,
    onSuccess: () { /* обновить подписку */ },
    onFail: () { /* показать ошибку */ },
  ),
));
```

---

## Локальное хранилище

| Ключ | Тип | Описание |
|------|-----|----------|
| `user_language` | String | `'ru'` / `'en'` |
| `onboarding_pending` | JSON String | `{age, height, gender, weight, target_weight, training_days}` |
| `onboarding_completed` | bool | флаг прохождения онбординга |

```dart
// SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('user_language', 'en');
final lang = prefs.getString('user_language') ?? 'ru';
```

---

## Что НЕ меняется на backend

- Все существующие API endpoints (meals, stats, goals, profile, onboarding, ai, tariffs, payments)
- Аутентификация через Telegram (существующий flow)
- Формат session cookie (starlette SessionMiddleware)
- База данных (PostgreSQL + asyncpg)
- AI интеграция (Claude Sonnet, Whisper)
- Платежи (YooKassa)

---

## Минимальные изменения backend

1. **`POST /api/auth/google`** — новый endpoint (~30 строк, `pip install google-auth`)
2. **`POST /api/auth/apple`** — новый endpoint (~40 строк, `pip install PyJWT requests`)
3. **`GET /api/ai/transcribe`** — уже принимает `?language=` ✅
4. **`POST /api/ai/recognize_photo`** — уже принимает `?language=` ✅
5. Настройка CORS для Flutter (добавить `allowed_origins` для mobile deep links)

---

## Frontend → Flutter: соответствие файлов

| React файл | Flutter файл |
|-----------|--------------|
| `pages/Onboarding.tsx` | `features/onboarding/screens/*.dart` |
| `pages/Dashboard.tsx` | `features/dashboard/screens/dashboard_screen.dart` |
| `pages/Journal.tsx` | `features/journal/screens/journal_screen.dart` |
| `pages/Settings.tsx` | `features/settings/screens/settings_screen.dart` |
| `pages/Tariffs.tsx` | `features/tariffs/screens/tariffs_screen.dart` |
| `pages/WayToGoal.tsx` | `features/way_to_goal/screens/way_to_goal_screen.dart` |
| `components/AddMealFab.tsx` | `features/add_meal/screens/add_meal_fab.dart` |
| `components/MealItem.tsx` | `features/journal/widgets/meal_item.dart` |
| `components/StatsCard.tsx` | `features/dashboard/widgets/stats_card.dart` |
| `api.ts` | `core/api/api_client.dart` (Dio) |
| `i18n/ru.ts` + `i18n/en.ts` | `core/i18n/app_ru.arb` + `app_en.arb` |
| `i18n/index.tsx` | `flutter_gen/gen_l10n/app_localizations.dart` (auto) |
| `App.tsx` | `app.dart` + `router.dart` |
