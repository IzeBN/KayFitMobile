# Техническое задание — Flutter-приложение Kayfit

> Дата: 2026-03-05
> Версия: 1.0
> Основание: flutter-architecture.md + реальный backend (FastAPI) + React-фронтенд

---

## Содержание

1. [Допущения и ограничения](#1-допущения)
2. [Схема базы данных](#2-схема-бд)
3. [API-контракты](#3-api-контракты)
4. [Dart/Freezed модели](#4-dartfreeezed-модели)
5. [Riverpod провайдеры](#5-riverpod-провайдеры)
6. [Навигация go_router](#6-навигация-go_router)
7. [Экраны — детальная спецификация](#7-экраны)
8. [Виджеты (shared + feature)](#8-виджеты)
9. [i18n — ключи локализации](#9-i18n)
10. [Нативные модули](#10-нативные-модули)
11. [Edge Cases и Error Handling](#11-edge-cases)
12. [Локальное хранилище](#12-локальное-хранилище)

---

## 1. Допущения

- Аутентификация — session cookie (Starlette SessionMiddleware, max_age=7 дней). Flutter хранит cookie через `PersistCookieJar`.
- Базовый URL: `https://app.kayfit.ru`.
- Онбординг в существующем бэкенде содержит 6 шагов (не 10, как в HLD). Шаги 7–10 в HLD соответствуют экранам WayToGoal и TelegramAuth, которые являются отдельными экранами.
- Фактический онбординг из `Onboarding.tsx` содержит 6 шагов: (1) как вести дневник, (2) эмоции и голод, (3) если переели, (4) похудение с Kaifit, (5) дни тренировок, (6) награда.
- Экран WayToGoal — отдельный экран с расчётом КБЖУ (возраст/вес/рост/режим дефицита).
- Telegram OAuth: бот по адресу `https://t.me/Formavkaif_bot?start=1`, deep link схема `kayfit://auth?token=xxx`.
- Эмодзи эмоций (11 штук): 😊 😌 😔 😰 😴 🤤 😑 😠 😟 😐 💬.
- Компульсивные (заедания) — эмоции из множества: 😰 😔 😑 😠 😟 😐 💬.
- Формула расчёта BMR — вариант без пола (из backend): `10*вес + 6.25*рост - 5*возраст - 161`. HLD показывает формулу с полом, но backend её не использует. Реализовать согласно backend.
- В i18n-файлах (`ru.ts`, `en.ts`) в данном репозитории нет — только базовый React-фронтенд без них. Ключи локализации формируются на основе HLD-документа и реальных текстов из React-компонентов.

---

## 2. Схема БД

Таблицы создаются backend автоматически. Flutter читает их через API — прямого доступа к БД нет. Приведены для понимания структуры данных.

### users
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| telegram_id | BIGINT | UNIQUE NOT NULL |
| username | TEXT | nullable |
| created_at | TIMESTAMP | DEFAULT NOW() |

### auth_tokens
| Поле | Тип | Constraints |
|------|-----|-------------|
| token | TEXT | PK |
| user_id | INTEGER | FK → users.id CASCADE |
| expires_at | TIMESTAMPTZ | NOT NULL |

### user_profile
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| user_id | INTEGER | UNIQUE FK → users.id CASCADE |
| age | INTEGER | nullable |
| weight | REAL | nullable |
| height | REAL | nullable |
| training_days | TEXT | nullable (формат: "monday,tuesday,...") |
| reward | TEXT | nullable (формат: "clothes,travel,...") |
| current_weight | REAL | nullable |
| target_weight | REAL | nullable |
| onboarding_completed | BOOLEAN | DEFAULT FALSE |
| created_at | TIMESTAMP | DEFAULT NOW() |
| updated_at | TIMESTAMP | DEFAULT NOW() |

### meals
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| user_id | INTEGER | FK → users.id CASCADE |
| name | TEXT | nullable |
| calories | REAL | nullable |
| protein | REAL | nullable |
| fat | REAL | nullable |
| carbs | REAL | nullable |
| emotion | TEXT | nullable (emoji-строка) |
| created_at | TIMESTAMP | DEFAULT NOW() |

**Индексы:** `idx_meals_user_date(user_id, created_at)`, `idx_meals_user_id(user_id)`, `idx_meals_user_emotion(user_id, emotion)`

### user_goals
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| user_id | INTEGER | FK → users.id CASCADE |
| calories | INTEGER | nullable |
| protein | INTEGER | nullable |
| fat | INTEGER | nullable |
| carbs | INTEGER | nullable |
| created_at | TIMESTAMP | DEFAULT NOW() |

**Индекс:** `idx_user_goals_user_created(user_id, created_at DESC)`

### onboarding_answers
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| user_id | INTEGER | FK → users.id CASCADE |
| question_id | INTEGER | NOT NULL |
| answer | TEXT | NOT NULL |
| created_at | TIMESTAMP | DEFAULT NOW() |
| UNIQUE | (user_id, question_id) | |

### foods
| Поле | Тип | Constraints |
|------|-----|-------------|
| id | SERIAL | PK |
| code | TEXT | UNIQUE NOT NULL |
| name | TEXT | NOT NULL |
| brand | TEXT | nullable |
| calories | REAL | NOT NULL |
| protein | REAL | NOT NULL |
| fat | REAL | NOT NULL |
| carbs | REAL | NOT NULL |

---

## 3. API-контракты

### Общие правила

- Base URL: `https://api.kayfit.ru`
- Авторизация: session cookie (автоматически через CookieJar Dio)
- Content-Type запроса: `application/json` (кроме multipart/form-data для файлов)
- При статусе 401 → Dio interceptor очищает cookie и направляет на `/onboarding` (шаг 1)
- Все числовые поля КБЖУ — `double` (float в Python, REAL в PostgreSQL)

---

### 3.1 GET /api/stats

**Описание:** Статистика за сегодня (съедено, цель, процент).

**Заголовки:** Cookie: session (автоматически)

**Request body:** отсутствует

**Response 200:**
```json
{
  "calories": { "current": 1245.5, "goal": 1800, "percent": 69.2 },
  "protein":  { "current": 87.3,   "goal": 120,  "percent": 72.8 },
  "fat":      { "current": 42.1,   "goal": 60,   "percent": 70.2 },
  "carbs":    { "current": 130.0,  "goal": 180,  "percent": 72.2 },
  "compulsive_count": 3
}
```

**Response 401:** `{"detail": "Войдите через бота"}`

**Response 500:** `{"detail": "Internal Server Error"}`

**Бизнес-правила:**
- `current` — сумма КБЖУ всех meals за сегодня (created_at::date = CURRENT_DATE по часовому поясу сервера)
- `goal` — последняя запись из user_goals; дефолт (2000, 180, 60, 180) если записей нет
- `percent` = round(current / goal * 100, 1); если goal = 0, percent = 0
- `compulsive_count` — количество meals за всё время где emotion входит в множество {😰,😔,😑,😠,😟,😐,💬}

**Edge cases:**
- Нет еды за сегодня → все current = 0, percent = 0
- Нет настроенных целей → goal = дефолтные значения

---

### 3.2 GET /api/goals

**Описание:** Текущие цели по КБЖУ.

**Response 200:**
```json
{ "calories": 1800, "protein": 120, "fat": 60, "carbs": 180 }
```
Все поля — `int`.

**Response 401:** `{"detail": "Войдите через бота"}`

**Бизнес-правила:** Возвращает последнюю запись из user_goals. Если записей нет → дефолт `{2000, 180, 60, 180}`.

---

### 3.3 POST /api/goals

**Описание:** Сохранить цели по КБЖУ.

**Request body:**
```json
{
  "calories": 1800,  // int, обязательный
  "protein":  120,   // int, обязательный
  "fat":      60,    // int, обязательный
  "carbs":    180    // int, обязательный
}
```

**Response 200:** `{"success": true}`

**Response 401:** `{"detail": "Войдите через бота"}`

**Response 422:** Ошибка валидации Pydantic (неверные типы)

**Бизнес-правила:**
- Создаёт новую запись в user_goals (не обновляет существующую — история хранится)
- После сохранения инвалидировать провайдеры: `dailyGoalsProvider`, `todayStatsProvider`

---

### 3.4 GET /api/meals

**Описание:** Список приёмов пищи за сегодня.

**Response 200:**
```json
[
  {
    "id": 42,
    "name": "Куриная грудка (200 г)",
    "calories": 220.0,
    "protein": 46.4,
    "fat": 2.4,
    "carbs": 0.0,
    "emotion": "😊",
    "time": "2026-03-05T13:45:22.123456"
  }
]
```

**Поля:**
- `id`: int — идентификатор записи в БД
- `name`: string — название блюда
- `calories`, `protein`, `fat`, `carbs`: double — округлены до 1 знака
- `emotion`: string — emoji или пустая строка ""
- `time`: string — ISO 8601 datetime (без timezone)

**Response 401, 500** — стандартные.

**Edge cases:** Нет блюд за сегодня → пустой массив `[]`.

---

### 3.5 POST /api/meals

**Описание:** Добавить приём пищи (простое добавление по названию или с явным КБЖУ).

**Request body — вариант А (по названию, поиск в БД):**
```json
{
  "name": "курица",           // string, обязательный, непустой
  "weight": 200,              // double, опциональный (дефолт 100г)
  "emotion": "😊"             // string, опциональный, дефолт ""
}
```

**Request body — вариант Б (с явным КБЖУ):**
```json
{
  "name": "Мой салат",        // string, обязательный, непустой
  "calories": 350.0,          // double, обязательный (в варианте Б)
  "protein": 12.5,            // double, обязательный (в варианте Б)
  "fat": 18.0,                // double, обязательный (в варианте Б)
  "carbs": 30.0,              // double, обязательный (в варианте Б)
  "emotion": "😌"             // string, опциональный
}
```

**Логика выбора варианта:** Если переданы все четыре поля calories/protein/fat/carbs — используется вариант Б. Иначе — поиск в БД по name.

**Response 200:**
```json
{
  "id": 0,
  "name": "курица",
  "calories": 220.0,
  "protein": 46.4,
  "fat": 2.4,
  "carbs": 0.0,
  "emotion": "😊",
  "time": "2026-03-05T13:45:22.123456"
}
```

Внимание: `id` всегда возвращается как `0` в текущей реализации backend (не реальный ID). Для последующего редактирования/удаления использовать GET /api/meals для получения реального ID.

**Response 400:** `{"detail": "Укажите название блюда"}` или `{"detail": "Продукт не найден в базе"}`

**Response 401:** стандартный

**После успешного добавления** инвалидировать: `todayMealsProvider`, `todayStatsProvider`.

---

### 3.6 PATCH /api/meals/{meal_id}

**Описание:** Редактировать приём пищи (частичное обновление).

**Path param:** `meal_id` — int, ID записи из GET /api/meals

**Request body (все поля опциональны):**
```json
{
  "name": "Новое название",   // string, опциональный
  "calories": 300.0,          // double, опциональный
  "protein": 25.0,            // double, опциональный
  "fat": 15.0,                // double, опциональный
  "carbs": 20.0,              // double, опциональный
  "emotion": "😔",            // string, опциональный
  "date": "2026-03-04"        // string YYYY-MM-DD, опциональный (перенос на другой день)
}
```

**Response 200:** `{"success": true}`

**Response 401:** стандартный

**Бизнес-правила:**
- Обновляются только переданные поля
- Поле `date` при обновлении меняет дату created_at, сохраняя время: `created_at = date::date + (created_at - created_at::date)`
- Проверка владельца: `WHERE id = meal_id AND user_id = текущий_пользователь`

**После успешного обновления** инвалидировать: `todayMealsProvider`, `mealsHistoryProvider`, `todayStatsProvider`.

---

### 3.7 DELETE /api/meals/{meal_id}

**Описание:** Удалить приём пищи.

**Path param:** `meal_id` — int

**Request body:** отсутствует

**Response 200:** `{"success": true}`

**Response 401:** стандартный

**Бизнес-правила:** `DELETE FROM meals WHERE id = meal_id AND user_id = текущий_пользователь`

**После успешного удаления** инвалидировать: `todayMealsProvider`, `mealsHistoryProvider`, `todayStatsProvider`.

---

### 3.8 GET /api/meals/history

**Описание:** История всех приёмов пищи.

**Query params:** `limit` — int, опциональный, дефолт 200, максимум 500

**Response 200:** Массив объектов MealResponse (аналогично GET /api/meals, но за всё время, отсортировано по created_at DESC).

**Edge cases:** Нет записей → `[]`.

---

### 3.9 GET /api/profile

**Описание:** Профиль пользователя.

**Response 200:**
```json
{
  "age": 28,
  "weight": 82.5,
  "height": 178.0,
  "training_days": "monday,wednesday,friday",
  "reward": "travel,gift",
  "current_weight": 82.5,
  "target_weight": 72.0,
  "onboarding_completed": true
}
```

Все поля опциональны (могут быть `null`). `onboarding_completed` — bool, дефолт false.

**Response 401:** стандартный

**Edge cases:** Профиль не существует → все поля null, `onboarding_completed: false`. Это НЕ ошибка, HTTP 200.

---

### 3.10 POST /api/profile

**Описание:** Сохранить/обновить профиль (частичный UPSERT).

**Request body (все поля опциональны):**
```json
{
  "age": 28,                          // int, опциональный
  "weight": 82.5,                     // double, опциональный
  "height": 178.0,                    // double, опциональный
  "training_days": "monday,wednesday",// string, опциональный
  "reward": "travel",                 // string, опциональный
  "current_weight": 82.5,             // double, опциональный
  "target_weight": 72.0,              // double, опциональный
  "onboarding_completed": true        // bool, опциональный
}
```

**Response 200:**
```json
{
  "age": 28,
  "weight": 82.5,
  "height": 178.0,
  "training_days": "monday,wednesday",
  "reward": "travel",
  "current_weight": 82.5,
  "target_weight": 72.0,
  "onboarding_completed": true
}
```

**Бизнес-правила:** Обновляются только переданные non-null поля. Если профиля нет — создаётся.

**После сохранения** инвалидировать: `userProfileProvider`.

---

### 3.11 POST /api/onboarding/answer

**Описание:** Сохранить ответ на вопрос онбординга.

**Request body:**
```json
{
  "question_id": 1,          // int, обязательный
  "answer": "monday,tuesday" // string, обязательный
}
```

**Question IDs в системе:**
- `question_id = 1` — дни тренировок (значение: "monday,tuesday,...")
- `question_id = 2` — награда (значение: "clothes,travel,...")

**Response 200:** `{"success": true}`

**Response 401:** стандартный

**Бизнес-правила:** UPSERT по (user_id, question_id). Если ответ уже существует — перезаписывается.

---

### 3.12 GET /api/onboarding/answers

**Описание:** Получить все ответы пользователя на вопросы онбординга.

**Response 200:**
```json
{ "answers": { "1": "monday,tuesday", "2": "travel" } }
```

Ключи — строковые представления question_id (особенность JSON-сериализации Python dict с int-ключами).

---

### 3.13 POST /api/onboarding/complete

**Описание:** Пометить онбординг как завершённый.

**Request body:** отсутствует (POST без тела)

**Response 200:** `{"success": true, "onboarding_completed": true}`

**Response 401:** стандартный

---

### 3.14 POST /api/calculate

**Описание:** Рассчитать КБЖУ и сохранить профиль. Используется на экране WayToGoal.

**Request body:**
```json
{
  "age": 28,                   // int, обязательный (16–100)
  "weight": 82.5,              // double, обязательный (30–300)
  "height": 178.0,             // double, обязательный (120–250)
  "training_days": "monday,wednesday,friday", // string, обязательный
  "deficit_mode": "active"     // string, опциональный, "active"|"gentle", дефолт "active"
}
```

**Response 200:**
```json
{
  "bmr": 1820.0,
  "tdee": 2821.0,
  "target_calories": 2221.0,
  "protein": 132.0,
  "fat": 74.3,
  "carbs": 276.5,
  "days_to_goal": 128,
  "target_weight": 72.0,
  "chart_data": [
    { "date": "Сегодня", "weight": 82.5 },
    { "date": "2026-04-15T00:00:00", "weight": 80.0 },
    { "date": "2026-06-01T00:00:00", "weight": 77.3 },
    { "date": "2026-07-15T00:00:00", "weight": 74.5 },
    { "date": "Цель", "weight": 72.0 }
  ]
}
```

`days_to_goal` и `target_weight` — null если target_weight не задан в профиле. `chart_data` — null если нет target_weight.

**Response 400:** `{"detail": "Заполните все обязательные поля"}`

**Response 401:** стандартный

**Бизнес-правила (расчёт):**
- `BMR = 10 * weight + 6.25 * height - 5 * age - 161` (формула без пола, только женский вариант из backend)
- `TDEE = BMR * k`, где k по дням тренировок: 0 дней→1.2, 1-2→1.375, 3-5→1.55, 6-7→1.725
- `deficit`: "active"=600 ккал, "gentle"=300 ккал
- `target_calories = max(TDEE - deficit, 1200)`
- `protein = weight * 1.6 г`
- `fat = weight * 0.9 г`
- `carbs = (target_calories - protein*4 - fat*9) / 4 г`
- Побочный эффект: сохраняет профиль и помечает `onboarding_completed = true`
- Побочный эффект: цели НЕ сохраняются автоматически — нужен отдельный вызов `POST /api/goals`

**После успешного расчёта** выполнить: `POST /api/goals` с округлёнными значениями, затем `POST /api/onboarding/complete`. Инвалидировать: `userProfileProvider`, `dailyGoalsProvider`, `todayStatsProvider`.

---

### 3.15 GET /api/calculation/result

**Описание:** Получить последний результат расчёта (для Dashboard).

**Response 200:** Аналогично POST /api/calculate response.

**Response 404:** `{"detail": "Профиль не заполнен"}` — если нет age/weight/height/training_days.

**Response 401:** стандартный.

---

### 3.16 POST /api/parse_meal_suggestions

**Описание:** Распознать текст приёма пищи → список продуктов с вариантами.

**Request body:**
```json
{ "text": "200г курицы и 100г риса, яблоко" }
```

`text` — string, обязательный, непустой.

**Response 200:**
```json
{
  "items": [
    {
      "name": "курица",
      "weight_grams": 200.0,
      "suggestions": [
        {
          "id": 0,
          "name": "Курица варёная",
          "calories": 170.0,
          "protein": 30.0,
          "fat": 4.2,
          "carbs": 0.0,
          "per_piece": null
        }
      ]
    }
  ]
}
```

`per_piece` — объект `{calories, protein, fat, carbs}` или null. Присутствует для штучных продуктов (фрукт, яйцо, батончик).

**Response 400:** `{"detail": "Введите описание приёма пищи"}`

**Response 401, 500:** стандартные

---

### 3.17 POST /api/meals/add_selected

**Описание:** Добавить выбранные продукты в дневник (после parse_meal_suggestions).

**Request body:**
```json
{
  "emotion": "😊",
  "items": [
    {
      "name": "Курица варёная",
      "weight_grams": 200,
      "calories": 340.0,
      "protein": 60.0,
      "fat": 8.4,
      "carbs": 0.0
    }
  ]
}
```

`emotion` — string, обязательный (может быть пустой строкой). `items` — массив, обязательный, непустой.

**Response 200:** `{"added": 1}`

`added` — количество фактически добавленных записей.

**Response 400:** `{"detail": "Выберите хотя бы один продукт"}`

**Response 401:** стандартный

**Бизнес-правила:** Имя в БД сохраняется как `"{name} ({weight_grams} г)"`. КБЖУ — уже финальные (пересчитанные на вес), не на 100г.

**После успешного добавления** инвалидировать: `todayMealsProvider`, `todayStatsProvider`, `mealsHistoryProvider`.

---

### 3.18 POST /api/transcribe

**Описание:** Транскрипция голосового файла → текст (Whisper).

**Request:** multipart/form-data, поле `audio` — файл.

Форматы: `.mp3`, `.wav`, `.m4a` (напрямую), `.webm`, `.ogg`, `.opus` (конвертируются через ffmpeg). Flutter пишет через пакет `record` в формат `.m4a` (iOS/Android).

**Response 200:** `{"text": "200 граммов курицы и стакан риса"}`

**Response 400:** `{"detail": "Отправьте аудиофайл"}`

**Response 401:** стандартный

**Edge cases:** Пустая запись (blob.size == 0) → 400. Тихая запись → Whisper вернёт пустую строку, backend вернёт `{"text": ""}`. Flutter должен показать предупреждение.

---

### 3.19 POST /api/recognize_photo

**Описание:** Распознать еду на фото → текстовое описание (GPT-4o-mini Vision).

**Request:** multipart/form-data, поле `image` — файл JPEG/PNG.

**Response 200:**
```json
{ "text": "На тарелке: куриная грудка (примерно 200г), гречка (150г), огурец" }
```

Если еды нет на фото: `{"text": "На изображении нет еды."}`

**Response 400:** `{"detail": "Отправьте изображение"}`

**Response 401:** стандартный

**Edge cases:**
- Фото без еды → text содержит подстроку "На изображении нет еды" → Flutter показывает предупреждение и не идёт дальше к emotion-шагу.
- Слишком большое фото → image_picker автоматически сжимает до maxWidth=1200.

---

### 3.20 POST /api/auth/google (НОВЫЙ)

**Описание:** Авторизация через Google OAuth.

**Request body:**
```json
{ "id_token": "eyJhb..." }  // string JWT от Google Sign-In
```

**Response 200:** `{"user_id": 123}`

Сервер устанавливает session cookie.

**Response 400:** `{"detail": "Invalid Google token"}`

**Response 500:** `{"detail": "Google auth failed"}`

**Бизнес-правила:**
- Backend верифицирует id_token через `google.oauth2.id_token.verify_oauth2_token`
- UPSERT пользователя по email: если email уже есть в таблице users (через другой метод) — связываем; иначе создаём новую запись

---

### 3.21 POST /api/auth/apple (НОВЫЙ)

**Описание:** Авторизация через Apple Sign-In.

**Request body:**
```json
{
  "identity_token": "eyJhb...",  // string JWT от Apple
  "user_id": "001234.abc...",    // string Apple user sub (обязательный)
  "name": "Иван Иванов"          // string, опциональный (только при первом входе)
}
```

**Response 200:** `{"user_id": 123}`

Сервер устанавливает session cookie.

**Response 400:** `{"detail": "Invalid Apple token"}`

**Бизнес-правила:**
- Backend декодирует identity_token через PyJWT с Apple JWKs
- Уникальный идентификатор — `payload["sub"]` (apple_id)
- Apple передаёт name только при первом входе — сохранять в username

---

### 3.22 GET /auth?token=xxx (Telegram OAuth)

**Описание:** Обратный вызов Telegram-бота. Бот генерирует одноразовый токен и передаёт его как query-параметр.

**Не JSON API.** Backend устанавливает session cookie и редиректит на `/`.

**Flutter flow:**
1. Открыть URL `https://t.me/WorkFlowTestNetBot?start` через `url_launcher`
2. Пользователь нажимает кнопку в боте
3. Бот отправляет deep link `kayfit://auth?token=TOKEN`
4. Приложение через `app_links` перехватывает deep link
5. Выполнить `GET https://api.kayfit.ru/auth?token=TOKEN` через Dio (с CookieJar) — это установит session cookie
6. Инвалидировать `currentUserProvider`

**Edge cases:**
- Токен просрочен или недействителен → backend редиректит на `/login?error=invalid` → Flutter получает redirect без cookie → показать ошибку

---

### 3.23 GET /logout

**Описание:** Выход из системы.

**Не JSON API.** Backend очищает сессию и редиректит на `/login`.

**Flutter flow:** Выполнить GET `/logout` через Dio, затем очистить CookieJar, инвалидировать `currentUserProvider`, перейти на `/onboarding`.

---

## 4. Dart/Freezed модели

Все модели — в `shared/models/` или `features/*/models/`. Генерируются `freezed` + `json_serializable`.

### 4.1 Meal

Файл: `shared/models/meal.dart`

```dart
@freezed
class Meal with _$Meal {
  const factory Meal({
    required int id,
    required String name,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    @Default('') String emotion,
    required String time,  // ISO 8601 string
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
```

**JSON-маппинг:** прямое соответствие полям из API (snake_case совпадает). `time` — строка, парсится в `DateTime` при отображении через `DateTime.parse(meal.time)`.

---

### 4.2 Goals

Файл: `shared/models/goals.dart`

```dart
@freezed
class Goals with _$Goals {
  const factory Goals({
    required int calories,
    required int protein,
    required int fat,
    required int carbs,
  }) = _Goals;

  factory Goals.fromJson(Map<String, dynamic> json) => _$GoalsFromJson(json);
  Map<String, dynamic> toJson() => _$GoalsToJson(this);
}
```

---

### 4.3 MacroStat

Файл: `shared/models/stats.dart` (вспомогательный класс)

```dart
@freezed
class MacroStat with _$MacroStat {
  const factory MacroStat({
    required double current,
    required double goal,
    required double percent,
  }) = _MacroStat;

  factory MacroStat.fromJson(Map<String, dynamic> json) => _$MacroStatFromJson(json);
}

@freezed
class Stats with _$Stats {
  const factory Stats({
    required MacroStat calories,
    required MacroStat protein,
    required MacroStat fat,
    required MacroStat carbs,
    required int compulsiveCount,
  }) = _Stats;

  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);
}
```

**JSON-маппинг:** `compulsive_count` → `compulsiveCount` (через `@JsonKey(name: 'compulsive_count')`).

---

### 4.4 UserProfile

Файл: `shared/models/user_profile.dart`

```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    int? age,
    double? weight,
    double? height,
    String? trainingDays,     // @JsonKey(name: 'training_days')
    String? reward,
    double? currentWeight,    // @JsonKey(name: 'current_weight')
    double? targetWeight,     // @JsonKey(name: 'target_weight')
    @Default(false) bool onboardingCompleted, // @JsonKey(name: 'onboarding_completed')
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

---

### 4.5 CalculationResult

Файл: `shared/models/calculation_result.dart`

```dart
@freezed
class ChartPoint with _$ChartPoint {
  const factory ChartPoint({
    required String date,    // "Сегодня", ISO string, или "Цель"
    required double weight,
  }) = _ChartPoint;

  factory ChartPoint.fromJson(Map<String, dynamic> json) => _$ChartPointFromJson(json);
}

@freezed
class CalculationResult with _$CalculationResult {
  const factory CalculationResult({
    required double bmr,
    required double tdee,
    required double targetCalories,   // @JsonKey(name: 'target_calories')
    required double protein,
    required double fat,
    required double carbs,
    int? daysToGoal,                  // @JsonKey(name: 'days_to_goal')
    double? targetWeight,             // @JsonKey(name: 'target_weight')
    List<ChartPoint>? chartData,      // @JsonKey(name: 'chart_data')
  }) = _CalculationResult;

  factory CalculationResult.fromJson(Map<String, dynamic> json) => _$CalculationResultFromJson(json);
}
```

---

### 4.6 MealSuggestion

Файл: `features/add_meal/models/meal_suggestion.dart`

```dart
@freezed
class PerPiece with _$PerPiece {
  const factory PerPiece({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
  }) = _PerPiece;

  factory PerPiece.fromJson(Map<String, dynamic> json) => _$PerPieceFromJson(json);
}

@freezed
class MealSuggestion with _$MealSuggestion {
  const factory MealSuggestion({
    required int id,
    required String name,
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    PerPiece? perPiece,   // @JsonKey(name: 'per_piece')
  }) = _MealSuggestion;

  factory MealSuggestion.fromJson(Map<String, dynamic> json) => _$MealSuggestionFromJson(json);
}

@freezed
class ParsedItem with _$ParsedItem {
  const factory ParsedItem({
    required String name,
    required double weightGrams,        // @JsonKey(name: 'weight_grams')
    required List<MealSuggestion> suggestions,
  }) = _ParsedItem;

  factory ParsedItem.fromJson(Map<String, dynamic> json) => _$ParsedItemFromJson(json);
}
```

---

### 4.7 OnboardingState

Файл: `features/onboarding/models/onboarding_state.dart`

```dart
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(1) int currentStep,       // 1–6
    @Default([]) List<String> trainingDays,  // ["monday","wednesday",...]
    @Default([]) List<String> rewards,       // ["clothes","travel",...]
  }) = _OnboardingState;
}
```

Хранится только в памяти (Riverpod Notifier). Не персистируется — при прерывании онбординга данные сохраняются в SharedPreferences ключ `onboarding_pending` (JSON).

---

## 5. Riverpod провайдеры

Все провайдеры используют `riverpod_generator` (аннотация `@riverpod`).

### 5.1 apiClientProvider

```
Тип: Provider<ApiClient>
Зависимости: нет
Инвалидация: никогда (singleton)
```

Создаёт `Dio` с `BaseOptions(baseUrl: 'https://api.kayfit.ru')`, подключает `CookieManager(PersistCookieJar)` и `AuthInterceptor` (обработка 401).

---

### 5.2 currentUserProvider

```
Тип: FutureProvider<UserProfile?>
Зависит от: apiClientProvider
Инвалидация: после login/logout, после POST /api/onboarding/complete
```

Выполняет `GET /api/profile`. При 401 возвращает `null` (без выброса исключения). Используется в `SessionGuard` для redirect-логики.

**Логика:**
```
try {
  response = GET /api/profile
  return UserProfile.fromJson(response.data)
} on DioException(401) {
  return null
}
```

---

### 5.3 dailyGoalsProvider

```
Тип: FutureProvider<Goals>
Зависит от: apiClientProvider
Инвалидация: после POST /api/goals
```

Выполняет `GET /api/goals`. При ошибке сети возвращает дефолт `Goals(calories: 2000, protein: 180, fat: 60, carbs: 180)`.

---

### 5.4 todayStatsProvider

```
Тип: FutureProvider<Stats>
Зависит от: apiClientProvider
Инвалидация: после добавления/удаления/редактирования meal, после POST /api/goals
```

Выполняет `GET /api/stats`.

---

### 5.5 todayMealsProvider

```
Тип: FutureProvider<List<Meal>>
Зависит от: apiClientProvider
Инвалидация: после POST /api/meals, DELETE /api/meals/{id}, PATCH /api/meals/{id}
```

Выполняет `GET /api/meals`. При ошибке возвращает `[]`.

---

### 5.6 mealsHistoryProvider

```
Тип: FutureProvider<List<Meal>>
Зависит от: apiClientProvider
Параметры: limit: int = 200
Инвалидация: после любой мутации с meals
```

Выполняет `GET /api/meals/history?limit=200`.

---

### 5.7 userProfileProvider

```
Тип: FutureProvider<UserProfile>
Зависит от: apiClientProvider
Инвалидация: после POST /api/profile, POST /api/calculate, POST /api/onboarding/complete
```

Выполняет `GET /api/profile`. При ответе без тела (профиль не создан) возвращает `UserProfile()` (все поля null).

---

### 5.8 calculationResultProvider

```
Тип: FutureProvider<CalculationResult?>
Зависит от: apiClientProvider
Инвалидация: после POST /api/calculate
```

Выполняет `GET /api/calculation/result`. При 404 возвращает `null`.

---

### 5.9 languageNotifierProvider

```
Тип: NotifierProvider<LanguageNotifier, Locale>
Зависит от: SharedPreferences
Инвалидация: при смене языка пользователем
```

Читает `user_language` из SharedPreferences. Сохраняет при изменении. Начальное значение: 'ru'.

```
State: Locale('ru') | Locale('en')
Methods:
  setLanguage(String langCode) — сохраняет в prefs, меняет state
```

---

### 5.10 onboardingNotifierProvider

```
Тип: NotifierProvider<OnboardingNotifier, OnboardingState>
Зависит от: нет (чистый локальный state)
Инвалидация: сбрасывается при navigate away
```

```
State: OnboardingState
Methods:
  nextStep()           — currentStep++
  prevStep()           — currentStep--
  setTrainingDays(List<String>)
  setRewards(List<String>)
  reset()
```

---

### 5.11 addMealNotifierProvider

```
Тип: NotifierProvider<AddMealNotifier, AddMealState>
Зависит от: apiClientProvider
```

Управляет всем флоу добавления блюда (метод → текст/голос/фото → эмоция → выбор продукта → подтверждение).

```dart
enum AddMealStep { method, input, recording, transcribing, emotion, choose, simple }

@freezed
class AddMealState with _$AddMealState {
  const factory AddMealState({
    @Default(AddMealStep.method) AddMealStep step,
    @Default('') String pendingText,
    @Default('') String emotion,
    @Default([]) List<ParsedItem> parsedItems,
    @Default([]) List<int> selections,  // индекс выбранного suggestion для каждого item (-1 = не выбрано)
    @Default(false) bool isLoading,
    String? error,
    AddMealStep? stepBeforeEmotion,
  }) = _AddMealState;
}
```

---

## 6. Навигация go_router

Файл: `lib/router.dart`

### Полная конфигурация маршрутов

```dart
final router = GoRouter(
  refreshListenable: ...,  // слушает currentUserProvider
  redirect: (context, state) {
    final user = ref.read(currentUserProvider).valueOrNull;
    final isAuth = user != null;
    final path = state.matchedLocation;

    // Пути, доступные без авторизации
    final publicPaths = ['/onboarding', '/way-to-goal'];
    final isPublic = publicPaths.any((p) => path.startsWith(p));

    if (!isAuth && !isPublic) return '/onboarding';
    if (isAuth && path == '/onboarding') return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/journal',
      builder: (_, __) => const JournalScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, __) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, state) {
        final step = int.tryParse(state.uri.queryParameters['step'] ?? '1') ?? 1;
        return OnboardingScreen(initialStep: step.clamp(1, 6));
      },
    ),
    GoRoute(
      path: '/way-to-goal',
      builder: (_, __) => const WayToGoalScreen(),
    ),
    GoRoute(
      path: '/tariffs',
      builder: (_, __) => const TariffsScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
  ],
);
```

### Guard-логика (SessionGuard)

| Условие | Redirect |
|---------|----------|
| Не авторизован + путь не в publicPaths | `/onboarding` |
| Авторизован + `onboarding_completed = false` + путь `/` | `/way-to-goal` |
| Авторизован + `path == '/onboarding'` | `/` |
| Авторизован + `path == '/login'` | `/` |
| Все остальные случаи | null (не редиректим) |

### Deep link (Telegram Auth)

Схема `kayfit://auth` регистрируется в:
- `android/app/src/main/AndroidManifest.xml` — intent-filter
- `ios/Runner/Info.plist` — CFBundleURLSchemes

`app_links` перехватывает URI и вызывает `handleTelegramDeepLink(uri)`.

---

## 7. Экраны

### 7.1 LoginScreen

**Файл:** `features/auth/screens/login_screen.dart`
**Путь навигации:** `/login`
**Доступность:** без авторизации

#### Layout (сверху вниз)

```
SafeArea
  Column(mainAxisAlignment: center)
    Image.asset('assets/logo.png')   // логотип Kayfit
    SizedBox(h: 24)
    Text(l10n.auth_title)            // "Войдите в Kayfit"
    SizedBox(h: 8)
    Text(l10n.auth_subtitle)         // "Отслеживайте питание и достигайте целей"
    SizedBox(h: 48)
    AppleSignInButton                // только на iOS
    SizedBox(h: 12)
    GoogleSignInButton
    SizedBox(h: 12)
    TelegramSignInButton
    SizedBox(h: 24)
    Text(l10n.auth_terms)            // "Продолжая, вы соглашаетесь с условиями"
```

#### Состояния

| Состояние | Поведение |
|-----------|-----------|
| loading | Кнопки заменяются `CircularProgressIndicator` по центру |
| error | SnackBar с текстом ошибки |
| success | Автоматический redirect через GoRouter |
| idle | Показаны все три кнопки |

#### Действия пользователя

**Нажатие "Войти с Apple" (только iOS):**
1. `SignInWithApple.getAppleIDCredential(scopes: [name, email])`
2. Извлечь `identityToken`, `userIdentifier`, `givenName + familyName`
3. `POST /api/auth/apple { identity_token, user_id, name? }`
4. При успехе → CookieJar сохраняет cookie → `ref.invalidate(currentUserProvider)` → GoRouter редиректит
5. При ошибке → показать SnackBar

**Нажатие "Войти с Google":**
1. `GoogleSignIn(scopes: ['email','profile']).signIn()`
2. Получить `auth.idToken`
3. `POST /api/auth/google { id_token }`
4. При успехе → аналогично Apple
5. При ошибке → SnackBar

**Нажатие "Войти через Telegram":**
1. Открыть URL `https://t.me/WorkFlowTestNetBot?start` через `launchUrl(mode: LaunchMode.externalApplication)`
2. Подписаться на `AppLinks().uriLinkStream`
3. При получении URI `kayfit://auth?token=XXX`: выполнить `GET /api/auth/token=XXX`
4. При успехе — аналогично

**Edge cases:**
- Apple Sign-In: iOS < 13 → скрыть кнопку (подписка на `SignInWithApple.isAvailable()`)
- Google Sign-In отменён пользователем (`account == null`) → ничего не делать
- Telegram deep link получен пока экран закрыт → обработать в `main.dart` через `AppLinks`

---

### 7.2 OnboardingScreen

**Файл:** `features/onboarding/screens/onboarding_screen.dart`
**Путь навигации:** `/onboarding?step=N`
**Доступность:** без авторизации
**Шагов:** 6 (как в реальном Onboarding.tsx)

#### Layout общий (все шаги)

```
Scaffold
  SafeArea
    Column
      LinearProgressIndicator (step / 6)  // шаг 1 = 1/6 заполнено
      SizedBox(h: 24)
      Expanded
        SingleChildScrollView
          Padding(h: 20)
            [Контент шага]
```

#### Шаг 1 — "Как вести дневник"

**Контент:**
```
Text("Как вы будете вести дневник", style: heading)
Text("Сначала сфотографируйте...", style: body_muted)
Row([
  CardChip("Фото"),
  CardChip("Голос"),
  CardChip("Эмоции"),
])
PrimaryButton("Далее") → goNext(2)
```

**Действия:** Кнопка "Далее" → `onboardingNotifier.nextStep()` → навигация `context.go('/onboarding?step=2')`.

#### Шаг 2 — "Эмоции и голод"

**Контент:**
```
Text("Эмоции и голод", style: heading)
Text("Если перед едой вы отмечаете злость...", style: body_muted)
BreathingWidget()     // кнопка "Попробовать 3 вдоха" + анимация
PrimaryButton("Понятно") → goNext(3)
```

**BreathingWidget:** Кнопка переключает фазы: idle → inhale (4 сек) → exhale (4 сек) → inhale ... (3 цикла). Текст меняется: "Попробовать 3 вдоха" / "Вдох..." / "Выдох...". Счётчик цикла отображается под кнопкой.

#### Шаг 3 — "Если переели"

**Контент:**
```
Container(decoration: pinkSoft)
  Text("Если вы переели", style: heading)
  Text("Бывают периоды...", style: body_muted)
  PrimaryButton("Далее") → goNext(4)
```

#### Шаг 4 — "Похудение с Kaifit"

**Контент:**
```
Text("Похудение с Kaifit", style: heading)
Text("Без дневника вес часто скачет...", style: body_muted)
WeightComparisonChart()  // SVG-подобный виджет: хаотичная линия vs плавная вниз
PrimaryButton("Далее") → goNext(5)
```

**WeightComparisonChart:** Два CustomPaint виджета (или fl_chart). Первый — хаотичная ломаная линия (серый цвет). Второй — плавная линия вниз (accent цвет). Подписи: "Без Kaifit — вес скачет" и "С Kaifit — медленно вниз".

#### Шаг 5 — "Дни тренировок"

**Контент:**
```
Text("По каким дням вы тренируетесь?", style: heading)
Text("Это поможет рассчитать вашу активность", style: body_muted)
Column(
  TrainingDayCard("Понедельник", "monday"),
  TrainingDayCard("Вторник", "tuesday"),
  TrainingDayCard("Среда", "wednesday"),
  TrainingDayCard("Четверг", "thursday"),
  TrainingDayCard("Пятница", "friday"),
  TrainingDayCard("Суббота", "saturday"),
  TrainingDayCard("Воскресенье", "sunday"),
)
[errorText если saveError != null]
PrimaryButton("Далее", disabled: selectedDays.isEmpty || isLoading)
```

**Действие "Далее":**
1. Если `selectedDays.isEmpty` → показать SnackBar "Выберите хотя бы один день"
2. Проверить авторизацию: `currentUser != null`
3. Если не авторизован — сохранить в `onboarding_pending` (SharedPreferences), перейти к шагу 6
4. Если авторизован: `POST /api/onboarding/answer {question_id: 1, answer: "monday,tuesday,..."}`, затем `POST /api/profile {training_days: "monday,..."}`, затем перейти к шагу 6

**Состояния:** loading (isPending) — кнопка показывает CircularProgressIndicator.

#### Шаг 6 — "Награда"

**Контент:**
```
Text("Как планируете себя наградить?", style: heading)
Text("Мотивация поможет идти к цели", style: body_muted)
Column(
  RewardCard("Новую одежду", "clothes"),
  RewardCard("Путешествие", "travel"),
  RewardCard("Подарок себе", "gift"),
  RewardCard("Другое", "other"),
)
[errorText если saveError != null]
PrimaryButton("Далее", disabled: selectedRewards.isEmpty || isLoading)
```

**Действие "Далее":**
1. Если не авторизован → сохранить в `onboarding_pending` → `context.go('/way-to-goal')`
2. Если авторизован → `POST /api/onboarding/answer {question_id: 2, answer: "clothes,..."}`, `POST /api/profile {reward: "clothes,..."}` → `context.go('/way-to-goal')`

#### Edge cases (онбординг)

| Ситуация | Поведение |
|----------|-----------|
| Прямой переход на `/onboarding?step=5` без выбранных дней | Guard проверяет и при необходимости редиректит на шаг 1 |
| Пользователь уже авторизован | GoRouter redirect → `/` |
| Ошибка сохранения | Показать текст ошибки под кнопкой, не переходить дальше |
| Потеря сети | Сохранить данные в `onboarding_pending`, продолжить навигацию без API |

---

### 7.3 WayToGoalScreen

**Файл:** `features/way_to_goal/screens/way_to_goal_screen.dart`
**Путь навигации:** `/way-to-goal`
**Доступность:** без авторизации (данные могут не сохраниться), с авторизацией (данные сохраняются)

#### Режим А — форма ввода (`showForm = true`)

```
SafeArea
  SingleChildScrollView
    Padding(h: 24)
      Text("Рассчитаем ваш путь к цели", style: label_muted)
      Text("Введите ваши данные...", style: body_muted)
      NumberTextField("Возраст (лет)", min: 16, max: 100)
      NumberTextField("Текущий вес (кг)", min: 30, max: 300, step: 0.1)
      NumberTextField("Рост (см)", min: 120, max: 250)
      NumberTextField("Целевой вес (кг, опционально)", min: 30, max: 300, step: 0.1)
      DeficitModeSelector("Активный -600 ккал" | "Бережный -300 ккал")
      [Если !isAuth] PrimaryButton("Получить план") → handleGetPlan()
      [Если isAuth]  PrimaryButton("Рассчитать", loading: isPending) → handleCalculate()
```

**handleGetPlan() (не авторизован):**
1. Валидация: все три поля заполнены, значения в диапазоне
2. Читать `onboarding_pending` из SharedPreferences
3. Сохранить `{...pending, age, weight, height}` в SharedPreferences
4. Открыть `https://t.me/WorkFlowTestNetBot?start` через `url_launcher`

**handleCalculate() (авторизован):**
1. Валидация полей
2. Проверить `profile.trainingDays != null` — если null → `context.go('/onboarding?step=5')`
3. `POST /api/profile {age, weight, height, current_weight: weight, target_weight?: targetWeight}`
4. `POST /api/calculate {age, weight, height, training_days, deficit_mode}`
5. При успехе: `POST /api/goals {calories, protein, fat, carbs}` (с rounded значениями)
6. `POST /api/onboarding/complete`
7. `setShowForm(false)` → переход в режим Б

#### Режим Б — результат расчёта (`showForm = false`)

```
SafeArea
  SingleChildScrollView
    Padding(h: 24)
      Text("Ваш путь к цели", style: label_muted)
      [Если daysToGoal != null]
        AccentCard
          Text("Вы достигнете цели")
          Text("${targetDate}", style: big_accent)  // дата через дни
      [Если targetWeight != null]
        SurfaceCard
          Text("Целевой вес")
          Text("${targetWeight} кг", style: big_accent)
      Row(
        Column("Без дневника — вес скачет", WeightChaosChart())
        Column("С Kaifit — ваш путь", WeightGoalChart(chartData))
      )
      MacroResultCard(calories, protein, fat, carbs)
      CalculationDetailsCard(bmr, tdee, daysToGoal)
      PrimaryButton("Начать отслеживание") → context.go('/')
```

**WeightGoalChart:** Компонент `WeightChart` на базе `fl_chart` (LineChart). Данные из `chartData`. Ось X — даты (строки), ось Y — вес. 5 точек. Первая точка — текущий вес ("Сегодня"), последняя — целевой ("Цель").

**WeightChaosChart:** Декоративный CustomPaint с хаотичной ломаной линией (8–9 точек, цвет `--border`/grey).

#### Состояния

| Состояние | Поведение |
|-----------|-----------|
| loading (calculate) | PrimaryButton показывает CircularProgressIndicator, остальные поля задисейблены |
| error | SnackBar с текстом ошибки |
| empty (нет training_days) | Редирект на `/onboarding?step=5` |
| success | Переход в режим Б |

---

### 7.4 DashboardScreen

**Файл:** `features/dashboard/screens/dashboard_screen.dart`
**Путь навигации:** `/`
**Доступность:** только авторизованным

#### Layout

```
Scaffold
  AppBar(title: Text("Сегодня"))
  body: RefreshIndicator(onRefresh: _refresh)
    SingleChildScrollView
      Padding(h: 16)
        [Если calculationResult != null] RecommendationsSection
        StatsSection
        TodayMealsSection
  floatingActionButton: AddMealFab()
  bottomNavigationBar: BottomNav(currentIndex: 0)
```

#### RecommendationsSection

Показывается если `calculationResultProvider` вернул данные (не null, без 404).

```
Text("Рекомендации по питанию", style: label_muted)
MacroGoalsCard(targetCalories, protein, fat, carbs)
[Если chartData != null && chartData.isNotEmpty] WeightChart(chartData)
[Если daysToGoal != null]
  AccentCard
    Text("Вы достигнете цели через")
    Text("${daysToGoal} дней", style: big_accent)
```

#### StatsSection

```
Text("Съедено и осталось", style: label_muted)
Column(
  StatsCard(label: "Калории", emoji: "🔥", ...stats.calories),
  StatsCard(label: "Белки",   emoji: "🥩", ...stats.protein),
  StatsCard(label: "Жиры",    emoji: "🥑", ...stats.fat),
  StatsCard(label: "Углеводы",emoji: "🍞", ...stats.carbs),
)
CompulsiveCard(compulsiveCount)
```

**CompulsiveCard:** Отдельная карточка с подписью "Заедания (за всё время)" и числом `compulsive_count` крупным шрифтом.

#### TodayMealsSection

```
Text("Сегодня", style: label_muted)
[loading] → CircularProgressIndicator
[empty]   → Text("Пока нет записей за сегодня", style: muted)
[data]    → ListView(meals.map(MealItem))
```

#### Состояния экрана

| Состояние | Поведение |
|-----------|-----------|
| statsLoading | CircularProgressIndicator на месте StatsSection |
| statsError | ErrorCard с кнопкой retry |
| mealsLoading | CircularProgressIndicator в TodayMealsSection |
| pull-to-refresh | Перезапросить stats + meals + calculationResult |

#### Действия

- **Свайп вниз** → `ref.invalidate(todayStatsProvider)`, `ref.invalidate(todayMealsProvider)`, `ref.invalidate(calculationResultProvider)`
- **Удаление meal** → `DELETE /api/meals/{id}` → инвалидировать stats + meals

---

### 7.5 JournalScreen

**Файл:** `features/journal/screens/journal_screen.dart`
**Путь навигации:** `/journal`
**Доступность:** только авторизованным

#### Layout

```
Scaffold
  AppBar(title: Text("Журнал"))
  body: RefreshIndicator
    [loading] CircularProgressIndicator
    [empty]   Text("Пока нет записей")
    [data]    ListView.builder(
                itemCount: groupedByDate.length,
                itemBuilder: (i) → DateSection(date, meals)
              )
  floatingActionButton: AddMealFab()
  bottomNavigationBar: BottomNav(currentIndex: 1)
```

**Группировка по дате:** Список meals сортирован по `created_at DESC`. Перед первой записью каждого нового дня отображается DateHeader.

**DateHeader формат:**
- Сегодня → "Сегодня"
- Вчера → "Вчера"
- Остальные → "DD MMMM" (например "3 марта")

#### Действия

- **Tap на MealItem** → открыть MealEditBottomSheet (редактирование)
- **Свайп влево на MealItem** → показать DismissibleAction "Удалить" (красный фон)
- **Подтверждение удаления** → `DELETE /api/meals/{id}`

#### Состояния

| Состояние | Поведение |
|-----------|-----------|
| loading | CircularProgressIndicator по центру |
| empty | Text + иконка |
| error | ErrorRetryWidget |
| data | ListView с группировкой |

---

### 7.6 AddMeal (bottom sheet / модальный экран)

**Файл:** `features/add_meal/screens/add_meal_fab.dart`
**Trigger:** FAB на DashboardScreen и JournalScreen
**Реализация:** `showModalBottomSheet` с `isScrollControlled: true`

#### Шаги флоу

```
method → [voice/text/photo/simple] → emotion → choose → (add) → close
                                      ↑ recording (голос)
```

**Шаг "method"** — выбор способа:
```
Text("Добавить приём пищи")
PrimaryButton("🎤 Голосом")    → handleVoice()
PrimaryButton("✏️ Текстом")   → setStep(input)
PrimaryButton("📷 Фото")      → handlePhoto()
PrimaryButton("➕ Простое")   → setStep(simple)
TextButton("Отмена")          → close()
```

**Шаг "recording"** — идёт запись:
```
Text("Запись")
Text("Говорите…", style: muted)
RedButton("Стоп") → handleStopRecording()
```
Кнопка "Стоп" должна быть `pointerEvents: auto` даже когда overlay имеет `pointerEvents: none`.

**Шаг "transcribing"** — загрузка после стопа:
```
CircularProgressIndicator
Text("Расшифровка голоса…")
```

**Шаг "input"** — ввод текста:
```
Text("Текстом")
TextField(
  hint: "Например: 200г курицы, 100г риса, яблоко",
  maxLines: 3,
)
Row[BackButton, NextButton("Далее") → setPendingText + setStep(emotion)]
```

**Шаг "emotion"** — подтверждение + выбор эмоции:
```
Text("Проверьте описание и выберите эмоцию")
TextField(value: pendingText, editable: true)  // исправить распознавание
Text("Эмоция до приёма пищи:", style: muted)
EmotionPicker(selected: emotion, onSelect: setEmotion)
[Если pendingText содержит "На изображении нет еды"]
  WarningText("На фото нет еды. Загрузите другое фото.")
[errorText]
Row[BackButton, FindProductsButton("Найти продукты", disabled: !emotion || !pendingText)]
```

**Действие "Найти продукты":**
1. `POST /api/parse_meal_suggestions {text: pendingText}`
2. Установить `parsedItems` и `selections` (дефолт: 0 для каждого item у которого есть suggestions)
3. `setStep(choose)`

**Шаг "choose"** — выбор вариантов продуктов:
```
Text("Выберите продукт для каждой позиции")
Text("Нажмите на вариант — он подставится.", style: hint)
ListView(maxHeight: 320,
  parsedItems.map(item →
    Card
      Text("${item.name} (${item.weightGrams} г)", bold)
      [Если suggestions empty] Text("Вариантов не найдено")
      [Иначе] Wrap(
        suggestions.map(s →
          SuggestionChip(
            selected: selections[i] == j,
            label: "${s.name}\n${cal} ккал Б${prot} Ж${fat} У${carbs}",
            onTap: toggle,
          )
        )
      )
  )
)
[errorText]
Row[BackButton, AddButton("Добавить в дневник", disabled: все selections == -1)]
```

**Действие "Добавить в дневник":**
1. Собрать `toAdd`: для каждого item где `selections[i] >= 0` — взять `suggestions[selections[i]]`, пересчитать КБЖУ: `value = suggestion.value * (item.weightGrams / 100)`
2. `POST /api/meals/add_selected {emotion, items: toAdd}`
3. Инвалидировать providers
4. Закрыть bottom sheet

**Шаг "simple"** — простое добавление (AddMealSimpleWidget):
```
Text("Добавить приём пищи")
TextField("Название продукта")
[Если !useManual] NumberField("Вес (г)", default: 100)
Toggle("Указать КБЖУ вручную")
[Если useManual] 4 NumberField(ккал, белки, жиры, углеводы)
EmotionPicker(опциональный)
Row[CancelButton, AddButton]
```

**Действие добавления (simple):**
- Без ручного КБЖУ: `POST /api/meals {name, weight, emotion}` → backend ищет в БД
- С ручным КБЖУ: `POST /api/meals {name, calories, protein, fat, carbs, emotion}`

#### Состояния

| Состояние | Поведение |
|-----------|-----------|
| handlePhoto loading | Overlay показывает "Распознавание фото…" |
| handleVoice recording | Шаг "recording" с кнопкой Стоп |
| transcribing | Шаг "transcribing" с индикатором |
| findProducts loading | Кнопка "Найти продукты" = CircularProgressIndicator |
| addSelected loading | Кнопка "Добавить" = CircularProgressIndicator |
| error | Текст ошибки над кнопками действия |

---

### 7.7 SettingsScreen

**Файл:** `features/settings/screens/settings_screen.dart`
**Путь навигации:** `/settings`
**Доступность:** только авторизованным

#### Layout

```
Scaffold
  AppBar(title: Text("Настройки"))
  body: SingleChildScrollView
    Padding(h: 16)
      Text("Цели на день", style: label_muted)
      NumberField("Калории", value: calories)
      NumberField("Белки (г)", value: protein)
      NumberField("Жиры (г)", value: fat)
      NumberField("Углеводы (г)", value: carbs)
      PrimaryButton("Сохранить", loading: isPending, onTap: handleSave)
      [Если isSuccess] Text("Цели сохранены", style: accent)
      Divider()
      Text("Аккаунт", style: label_muted)
      ListTile("Выйти", icon: Icons.logout, onTap: handleLogout)
  bottomNavigationBar: BottomNav(currentIndex: 2)
```

#### Начальные значения

При загрузке экрана: `GET /api/goals` → заполнить поля. Дефолт если нет данных: (2000, 180, 60, 180).

#### Действия

**handleSave:**
1. Валидация: все поля > 0
2. `POST /api/goals {calories, protein, fat, carbs}`
3. Инвалидировать `dailyGoalsProvider`, `todayStatsProvider`
4. Показать "Цели сохранены" на 2 секунды

**handleLogout:**
1. `GET /logout` (Dio, с cookies)
2. Очистить `CookieJar`
3. `ref.invalidate(currentUserProvider)`
4. `context.go('/onboarding')`

#### Состояния

| Состояние | Поведение |
|-----------|-----------|
| loading goals | NumberField показывает placeholder, кнопка задисейблена |
| saving | Кнопка = CircularProgressIndicator |
| success | Зелёный текст под кнопкой |
| error save | SnackBar с ошибкой |

---

### 7.8 TariffsScreen

**Файл:** `features/tariffs/screens/tariffs_screen.dart`
**Путь навигации:** `/tariffs`
**Доступность:** только авторизованным

**Допущение:** Endpoints `/api/tariffs`, `/api/payments/create`, `/api/subscription` отсутствуют в текущем backend. Экран реализуется как заглушка с возможностью расширения.

#### Layout

```
Scaffold
  AppBar(title: Text("Тарифы"))
  body: Center
    Column
      Text("Выберите тариф", style: heading)
      Text("Функция будет доступна скоро", style: muted)
      // Placeholder для будущих карточек тарифов
```

#### Расширенная реализация (когда backend готов)

```
ListView(
  TariffCard("Базовый", price: "0₽", features: [...]),
  TariffCard("Премиум", price: "299₽/мес", features: [...]),
)
PrimaryButton("Оформить подписку") → handleSubscribe()
```

**handleSubscribe:**
1. `POST /api/payments/create {tariff_id}` → получить `confirmation_url`
2. `Navigator.push(WebViewScreen(url: confirmation_url))`
3. WebView отслеживает redirect на success/fail URL
4. При успехе → инвалидировать `subscriptionProvider`

---

## 8. Виджеты

### 8.1 BottomNav (shared)

**Файл:** `shared/widgets/bottom_nav.dart`

**Параметры:**
```dart
class BottomNav extends StatelessWidget {
  final int currentIndex; // 0=dashboard, 1=journal, 2=settings
}
```

**Внешний вид:** `BottomNavigationBar` с тремя пунктами:
- 0: иконка `home`, label "Сегодня" → `context.go('/')`
- 1: иконка `book`, label "Журнал" → `context.go('/journal')`
- 2: иконка `settings`, label "Настройки" → `context.go('/settings')`

**Поведение:** Пункт с `currentIndex` выделен accent-цветом. При нажатии — навигация без push в стек (`context.go`, не `push`).

---

### 8.2 StatsCard (dashboard)

**Файл:** `features/dashboard/widgets/stats_card.dart`

**Параметры:**
```dart
class StatsCard extends StatelessWidget {
  final String label;    // "Калории"
  final String emoji;    // "🔥"
  final double current;
  final double goal;
  final double percent;
}
```

**Внешний вид:**
```
Container(border, borderRadius: 12)
  Row(mainAxis: spaceBetween)
    Text("${emoji} ${label}", bold)
    [Если current > goal] Text("Переели", style: red)
    [Иначе]               Text("осталось ${remaining}", style: muted)
  Text("${current} / ${goal} (${percent}%)", style: small_muted)
  LinearProgressBar(value: min(percent/100, 1.0),
    color: current > goal ? red : accent)
```

**Поведение:** При `current > goal` — контейнер получает `backgroundColor: redSoft`, прогресс-бар — красный. Иначе — стандартный.

**Вычисления:**
- `remaining = max(0, goal - current)`
- `displayCurrent = (current * 10).round() / 10`

---

### 8.3 EmotionPicker (shared)

**Файл:** `shared/widgets/emotion_picker.dart`

**Параметры:**
```dart
class EmotionPicker extends StatelessWidget {
  final String selectedEmotion; // текущая выбранная emoji-строка или ""
  final ValueChanged<String> onSelect; // вызывается с новым emoji (или "" для сброса)
}
```

**Внешний вид:** `Wrap` с 11 кнопками. Каждая кнопка — `OutlinedButton` с emoji + label.

**Список эмоций (фиксированный порядок):**
```
😊 Радость, 😌 Спокойствие, 😔 Грусть, 😰 Стресс, 😴 Усталость,
🤤 Голод, 😑 Безразличие, 😠 Гнев, 😟 Тревога, 😐 Скука, 💬 Общение
```

**Поведение:** При повторном tap на уже выбранную эмоцию → сброс (вызов `onSelect("")`).

---

### 8.4 MealItem (journal/dashboard)

**Файл:** `features/journal/widgets/meal_item.dart`

**Параметры:**
```dart
class MealItem extends StatelessWidget {
  final Meal meal;
  final VoidCallback onDelete;
  final VoidCallback? onTap; // опциональный, для открытия редактора
}
```

**Внешний вид:**
```
ListTile
  leading: Text(meal.emotion, style: emoji_large)  // если emotion не пустой
  title: Text(meal.name, bold)
  subtitle: Column
    Text("${calories} ккал · Б ${protein} Ж ${fat} У ${carbs}", style: small_muted)
    Text(formattedTime, style: tiny_muted)  // "HH:mm" или "dd.MM HH:mm" если не сегодня
  trailing: IconButton(Icons.delete, onPressed: onDelete)
```

**Поведение:** `onTap` (если задан) — открывает `MealEditBottomSheet`.

---

### 8.5 LoadingIndicator (shared)

**Файл:** `shared/widgets/loading_indicator.dart`

**Параметры:** нет (или опциональный `String? label`)

**Внешний вид:** `Center(CircularProgressIndicator(color: accentColor))` + опциональный текст ниже.

---

### 8.6 WeightChart (dashboard/way_to_goal)

**Файл:** `features/dashboard/widgets/weight_chart.dart`

**Параметры:**
```dart
class WeightChart extends StatelessWidget {
  final List<ChartPoint> data;
  final double height; // default: 240
}
```

**Реализация:** `fl_chart` `LineChart`. Данные: ось X — индекс (0..4), ось Y — weight. Под линией — gradient fill (accent с 30% opacity → 5%). Точки — круги с белым ободком. Подписи X: строки из `data[i].date` с форматированием:
- "Сегодня" → "Сегодня"
- "Цель" → "Цель"
- ISO string → "дд.мм"

---

### 8.7 MealEditBottomSheet (journal)

**Файл:** `features/journal/widgets/meal_edit_bottom_sheet.dart`

**Параметры:**
```dart
class MealEditBottomSheet extends StatefulWidget {
  final Meal meal;
}
```

**Внешний вид:**
```
BottomSheet(isScrollControlled: true, maxHeight: 85vh)
  Text("Редактировать приём пищи")
  TextField("Название")
  DateField("Дата", format: YYYY-MM-DD)  // перенос записи
  Row(2 columns)
    NumberField("Ккал")
    NumberField("Белки (г)")
    NumberField("Жиры (г)")
    NumberField("Углеводы (г)")
  EmotionPicker(selected, onSelect)
  Row[CancelButton, SaveButton]
```

**Действие "Сохранить":** `PATCH /api/meals/{id} {name, calories, protein, fat, carbs, emotion, date}`

---

## 9. i18n

### Файлы

- `lib/core/i18n/app_ru.arb` — русский (основной)
- `lib/core/i18n/app_en.arb` — английский

### Формат ARB

```json
{
  "@@locale": "ru",
  "keyName": "Текст строки",
  "@keyName": { "description": "Описание" }
}
```

Для строк с плейсхолдерами:
```json
{
  "ob_demo_portion": "Порция {weight}",
  "@ob_demo_portion": {
    "description": "Демо порция",
    "placeholders": {
      "weight": { "type": "String", "example": "580г" }
    }
  }
}
```

### Полный список ключей

#### Группа nav_* (навигация)
```
nav_appName         = "Calories" / "Calories"
nav_today           = "Сегодня" / "Today"
nav_journal         = "Журнал" / "Journal"
nav_settings        = "Настройки" / "Settings"
nav_wayToGoal       = "Путь к цели" / "Way to Goal"
nav_tariffs         = "Тарифы" / "Tariffs"
```

#### Группа common_* (общие)
```
common_save         = "Сохранить" / "Save"
common_cancel       = "Отмена" / "Cancel"
common_back         = "Назад" / "Back"
common_next         = "Далее" / "Next"
common_loading      = "Загрузка…" / "Loading…"
common_error        = "Ошибка" / "Error"
common_retry        = "Повторить" / "Retry"
common_delete       = "Удалить" / "Delete"
```

#### Группа auth_* (авторизация)
```
auth_title          = "Войдите в Kayfit" / "Sign in to Kayfit"
auth_subtitle       = "Отслеживайте питание и достигайте целей" / "Track nutrition and reach your goals"
auth_google         = "Войти с Google" / "Sign in with Google"
auth_apple          = "Войти с Apple" / "Sign in with Apple"
auth_telegram       = "Войти через Telegram" / "Sign in with Telegram"
auth_terms          = "Продолжая, вы соглашаетесь с условиями" / "By continuing, you agree to the terms"
```

#### Группа macro_* (макронутриенты)
```
macro_calories      = "Калории" / "Calories"
macro_protein       = "Белки" / "Protein"
macro_fat           = "Жиры" / "Fat"
macro_carbs         = "Углеводы" / "Carbs"
macro_kcal          = "ккал" / "kcal"
macro_grams         = "г" / "g"
macro_remaining     = "осталось {value}" / "remaining {value}"
macro_overeat       = "Переели" / "Over goal"
macro_goal          = "Цель" / "Goal"
macro_eaten         = "Съедено" / "Eaten"
macro_bmr           = "BMR (базовый обмен)" / "BMR (base metabolic rate)"
macro_tdee          = "TDEE (суточный расход)" / "TDEE (daily expenditure)"
```

#### Группа dashboard_*
```
dashboard_today           = "Сегодня" / "Today"
dashboard_noMeals         = "Пока нет записей за сегодня" / "No meals recorded today"
dashboard_recommendations = "Рекомендации по питанию" / "Nutrition recommendations"
dashboard_goalsToday      = "Ваши цели на день" / "Your daily goals"
dashboard_daysToGoal      = "Вы достигнете цели через" / "You'll reach your goal in"
dashboard_daysCount       = "{count} дней" / "{count} days"
dashboard_compulsive      = "Заедания (за всё время)" / "Compulsive eating (all time)"
```

#### Группа journal_*
```
journal_title       = "История приёмов еды" / "Meal history"
journal_noMeals     = "Пока нет записей" / "No records yet"
journal_today       = "Сегодня" / "Today"
journal_yesterday   = "Вчера" / "Yesterday"
```

#### Группа settings_*
```
settings_title            = "Настройки" / "Settings"
settings_goalsSection     = "Цели на день" / "Daily goals"
settings_caloriesLabel    = "Калории" / "Calories"
settings_proteinLabel     = "Белки (г)" / "Protein (g)"
settings_fatLabel         = "Жиры (г)" / "Fat (g)"
settings_carbsLabel       = "Углеводы (г)" / "Carbs (g)"
settings_saveSuccess      = "Цели сохранены" / "Goals saved"
settings_accountSection   = "Аккаунт" / "Account"
settings_logout           = "Выйти" / "Sign out"
settings_language         = "Язык" / "Language"
settings_languageRu       = "Русский" / "Russian"
settings_languageEn       = "Английский" / "English"
```

#### Группа addMeal_*
```
addMeal_title            = "Добавить приём пищи" / "Add meal"
addMeal_voice            = "Голосом" / "Voice"
addMeal_text             = "Текстом" / "Text"
addMeal_photo            = "Фото" / "Photo"
addMeal_simple           = "Простое добавление" / "Simple add"
addMeal_recording        = "Запись" / "Recording"
addMeal_speaking         = "Говорите…" / "Speak…"
addMeal_stop             = "Стоп" / "Stop"
addMeal_transcribing     = "Расшифровка голоса…" / "Transcribing voice…"
addMeal_recognizing      = "Распознавание фото…" / "Recognizing photo…"
addMeal_textHint         = "Например: 200г курицы, 100г риса, яблоко" / "E.g.: 200g chicken, 100g rice, apple"
addMeal_emotionStep      = "Проверьте описание и выберите эмоцию" / "Check description and choose emotion"
addMeal_emotionLabel     = "Эмоция до приёма пищи:" / "Emotion before eating:"
addMeal_description      = "Расшифровка (можно исправить)" / "Description (can be corrected)"
addMeal_findProducts     = "Найти продукты" / "Find products"
addMeal_findingProducts  = "Найти продукты…" / "Finding products…"
addMeal_chooseStep       = "Выберите продукт для каждой позиции" / "Choose product for each item"
addMeal_chooseHint       = "Нажмите на вариант — он подставится." / "Tap a variant to select it."
addMeal_noSuggestions    = "Вариантов не найдено" / "No variants found"
addMeal_addToDiary       = "Добавить в дневник" / "Add to diary"
addMeal_adding           = "Добавляем…" / "Adding…"
addMeal_noFoodInPhoto    = "На фото нет еды. Загрузите другое фото." / "No food in photo. Upload another."
```

#### Группа simple_* (простое добавление)
```
simple_title       = "Добавить приём пищи" / "Add meal"
simple_nameLabel   = "Название продукта" / "Product name"
simple_nameHint    = "Например: курица" / "E.g.: chicken"
simple_weightLabel = "Вес (г)" / "Weight (g)"
simple_manualKbju  = "Указать КБЖУ вручную" / "Enter nutrition manually"
simple_caloriesLabel = "Калории" / "Calories"
simple_proteinLabel  = "Белки (г)" / "Protein (g)"
simple_fatLabel      = "Жиры (г)" / "Fat (g)"
simple_carbsLabel    = "Углеводы (г)" / "Carbs (g)"
```

#### Группа meal_* (элемент блюда)
```
meal_edit          = "Редактировать приём пищи" / "Edit meal"
meal_nameLabel     = "Название" / "Name"
meal_dateLabel     = "Дата" / "Date"
meal_emotionLabel  = "Эмоция" / "Emotion"
meal_saving        = "Сохранение…" / "Saving…"
```

#### Группа emotion_*
```
emotion_joy        = "Радость" / "Joy"
emotion_calm       = "Спокойствие" / "Calm"
emotion_sadness    = "Грусть" / "Sadness"
emotion_stress     = "Стресс" / "Stress"
emotion_tired      = "Усталость" / "Tired"
emotion_hunger     = "Голод" / "Hunger"
emotion_apathy     = "Безразличие" / "Apathy"
emotion_anger      = "Гнев" / "Anger"
emotion_anxiety    = "Тревога" / "Anxiety"
emotion_boredom    = "Скука" / "Boredom"
emotion_social     = "Общение" / "Social"
```

#### Группа ob_* (онбординг)
```
ob_step1_title     = "Как вы будете вести дневник" / "How you'll keep a diary"
ob_step1_body      = "Сначала сфотографируйте то, что хотите съесть..." / "First, photograph what you want to eat..."
ob_step2_title     = "Эмоции и голод" / "Emotions and hunger"
ob_step2_body1     = "Если перед едой вы отмечаете злость..." / "If before eating you feel anger..."
ob_step2_body2     = "Мы подскажем короткую практику..." / "We'll suggest a short practice..."
ob_step2_btn       = "Попробовать 3 вдоха" / "Try 3 breaths"
ob_step2_inhale    = "Вдох..." / "Inhale..."
ob_step2_exhale    = "Выдох..." / "Exhale..."
ob_step2_cycle     = "Цикл {current} из {total}" / "Cycle {current} of {total}"
ob_step2_next      = "Понятно" / "Got it"
ob_step3_title     = "Если вы переели" / "If you overate"
ob_step3_body      = "Бывают периоды, когда тяжело..." / "There are hard times..."
ob_step4_title     = "Похудение с Kaifit" / "Weight loss with Kaifit"
ob_step4_body      = "Без дневника вес часто скачет..." / "Without a diary, weight fluctuates..."
ob_step4_chaos     = "Без Kaifit — вес скачет" / "Without Kaifit — weight fluctuates"
ob_step4_goal      = "С Kaifit — медленно вниз" / "With Kaifit — slowly down"
ob_step5_title     = "По каким дням вы тренируетесь?" / "Which days do you train?"
ob_step5_subtitle  = "Это поможет рассчитать вашу активность" / "This will help calculate your activity"
ob_step6_title     = "Как планируете себя наградить?" / "How will you reward yourself?"
ob_step6_subtitle  = "Мотивация поможет идти к цели" / "Motivation will help you reach the goal"
ob_reward_clothes  = "Новую одежду" / "New clothes"
ob_reward_travel   = "Путешествие" / "Travel"
ob_reward_gift     = "Подарок себе" / "Gift to yourself"
ob_reward_other    = "Другое" / "Other"
ob_day_monday      = "Понедельник" / "Monday"
ob_day_tuesday     = "Вторник" / "Tuesday"
ob_day_wednesday   = "Среда" / "Wednesday"
ob_day_thursday    = "Четверг" / "Thursday"
ob_day_friday      = "Пятница" / "Friday"
ob_day_saturday    = "Суббота" / "Saturday"
ob_day_sunday      = "Воскресенье" / "Sunday"
ob_error_training  = "Выберите хотя бы один день" / "Select at least one day"
ob_error_reward    = "Выберите хотя бы одну награду" / "Select at least one reward"
```

#### Группа wg_* (путь к цели)
```
wg_title           = "Рассчитаем ваш путь к цели" / "Let's calculate your path to the goal"
wg_subtitle        = "Введите ваши данные для расчета калорий и БЖУ" / "Enter your data to calculate calories and macros"
wg_ageLabel        = "Возраст (лет)" / "Age (years)"
wg_weightLabel     = "Текущий вес (кг)" / "Current weight (kg)"
wg_heightLabel     = "Рост (см)" / "Height (cm)"
wg_targetLabel     = "Целевой вес (кг, опционально)" / "Target weight (kg, optional)"
wg_deficitTitle    = "Режим дефицита" / "Deficit mode"
wg_deficitActive   = "Активный (-600 ккал)" / "Active (-600 kcal)"
wg_deficitGentle   = "Бережный (-300 ккал)" / "Gentle (-300 kcal)"
wg_getPlan         = "Получить план" / "Get plan"
wg_calculate       = "Рассчитать" / "Calculate"
wg_calculating     = "Расчет..." / "Calculating..."
wg_resultTitle     = "Ваш путь к цели" / "Your path to the goal"
wg_goalDate        = "Вы достигнете цели" / "You'll reach the goal"
wg_goalWeight      = "Целевой вес" / "Target weight"
wg_howWeightChanges = "Как меняется вес" / "How weight changes"
wg_chaosChart      = "Без дневника — вес скачет" / "Without diary — weight fluctuates"
wg_goalChart       = "С Kaifit — ваш путь" / "With Kaifit — your path"
wg_startTracking   = "Начать отслеживание" / "Start tracking"
wg_calculations    = "Расчеты:" / "Calculations:"
wg_daysToGoal      = "Дней до цели: {days}" / "Days to goal: {days}"
wg_noTraining      = "Сначала пройдите онбординг" / "Complete onboarding first"
wg_error_data      = "Заполните все поля" / "Fill in all fields"
wg_error_range     = "Проверьте корректность данных" / "Check the validity of the data"
```

---

## 10. Нативные модули

### 10.1 Камера и галерея (image_picker)

**Пакет:** `image_picker: ^1.1.0`

**Пошаговый флоу:**

1. Пользователь нажимает "📷 Фото" в AddMealFab
2. `final picker = ImagePicker()`
3. `final file = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85)`
   - На iOS → показывает стандартный UIImagePickerController
   - На Android → камера или галерея (в зависимости от `source`)
4. Если `file == null` (пользователь отменил) → ничего не делать, вернуться к шагу "method"
5. `final bytes = await file.readAsBytes()`
6. Создать `MultipartFile` из bytes: `MultipartFile.fromBytes(bytes, filename: 'photo.jpg', contentType: MediaType('image', 'jpeg'))`
7. `POST /api/recognize_photo` с FormData `{'image': multipartFile}`
8. При успехе → `setPendingText(response['text'])` → `setStep(emotion)`
9. При `text.contains('На изображении нет еды')` → показать предупреждение и НЕ идти на emotion-шаг

**Разрешения:**
- iOS: в `Info.plist` добавить `NSCameraUsageDescription` и `NSPhotoLibraryUsageDescription`
- Android: в `AndroidManifest.xml` добавить `android.permission.CAMERA`
- Не требуют runtime-запроса (image_picker запрашивает сам)

**Edge cases:**
- Файл > 10 МБ → вероятна ошибка от backend (нет ограничения на уровне Flutter, backend ограничен nginx)
- Нет доступа к камере → `image_picker` показывает системный запрос; при отказе → PlatformException → показать SnackBar "Нет доступа к камере"

---

### 10.2 Микрофон (record)

**Пакет:** `record: ^5.1.0`

**Пошаговый флоу:**

1. Пользователь нажимает "🎤 Голосом" в AddMealFab
2. Проверить разрешение: `await AudioRecorder().hasPermission()`
   - Если нет → `await AudioRecorder().hasPermission()` запрашивает разрешение
   - Если отказ → показать диалог с объяснением и кнопкой "Открыть настройки"
3. Создать временный файл: `final path = '${tempDir.path}/voice_${timestamp}.m4a'`
4. Начать запись: `await recorder.start(RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000), path: path)`
5. `setStep(recording)` — показать экран с кнопкой "Стоп"
6. Пользователь нажимает "Стоп": `final path = await recorder.stop()`
7. `setStep(transcribing)` — показать индикатор
8. Читать файл: `final bytes = await File(path).readAsBytes()`
9. Создать `MultipartFile.fromBytes(bytes, filename: 'voice.m4a', contentType: MediaType('audio', 'm4a'))`
10. `POST /api/transcribe` с FormData `{'audio': multipartFile}`
11. При успехе → `setPendingText(response['text'])` → `setStep(emotion)`
12. При `text == ''` → показать SnackBar "Запись пустая. Говорите дольше и нажмите «Стоп»."
13. Удалить временный файл: `await File(path).delete()`

**Разрешения:**
- iOS: `Info.plist` → `NSMicrophoneUsageDescription`
- Android: `AndroidManifest.xml` → `android.permission.RECORD_AUDIO`
- `permission_handler` используется для показа диалога при отказе

**Edge cases:**
- Пользователь закрыл bottom sheet во время записи → `recorder.stop()` + `recorder.dispose()` в `dispose()`
- Телефонный звонок во время записи → платформа прерывает запись → поймать через `recorder.onStateChanged` → `setStep(method)` + SnackBar "Запись прервана"

---

### 10.3 Разрешения (permission_handler)

**Пакет:** `permission_handler: ^11.3.0`

**Обрабатываемые разрешения:**

| Разрешение | Когда запрашивается | При отказе |
|------------|---------------------|------------|
| `Permission.microphone` | Перед началом записи голоса | Диалог "Нужен доступ к микрофону" + кнопка "Открыть настройки" |
| `Permission.camera` | image_picker запрашивает сам | SnackBar "Нет доступа к камере" |

**Универсальный helper:**
```dart
Future<bool> requestPermissionWithDialog(
  BuildContext context,
  Permission permission,
  String title,
  String message,
) async {
  final status = await permission.request();
  if (status.isGranted) return true;
  if (status.isPermanentlyDenied) {
    // Показать AlertDialog с кнопкой "Открыть настройки"
    // openAppSettings() при нажатии
    return false;
  }
  return false;
}
```

---

## 11. Edge Cases и Error Handling

### 11.1 Потеря сети

| Ситуация | Поведение |
|----------|-----------|
| GET запрос при offline | FutureProvider → AsyncError → виджет показывает `ErrorRetryWidget` |
| POST запрос при offline | SnackBar "Нет подключения к интернету. Проверьте сеть." |
| Потеря сети во время записи голоса | Запись продолжается; ошибка возникнет при отправке → SnackBar |
| Потеря сети во время фото-распознавания | `DioException(type: connectionError)` → SnackBar |

**Проверка типа ошибки Dio:**
```dart
if (e is DioException) {
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
      return 'Нет подключения к интернету';
    case DioExceptionType.receiveTimeout:
      return 'Сервер не отвечает';
    default:
      return e.response?.data['detail'] ?? 'Ошибка сервера';
  }
}
```

---

### 11.2 401 Unauthorized

**Обработка в `AuthInterceptor` (Dio interceptor):**
1. Получен ответ со статусом 401
2. Очистить `PersistCookieJar`: `await cookieJar.deleteAll()`
3. `ref.invalidate(currentUserProvider)` → провайдер вернёт null
4. GoRouter redirect-логика перенаправит на `/onboarding`
5. Показать SnackBar "Сессия истекла. Войдите снова."

**Исключение:** При `GET /api/profile` с 401 возвращать null без редиректа (используется для определения авторизации).

---

### 11.3 Пустые данные

| Экран | Поле | Поведение при пустых данных |
|-------|------|-----------------------------|
| DashboardScreen | meals = [] | Text "Пока нет записей за сегодня" |
| JournalScreen | meals = [] | Text "Пока нет записей" + иконка |
| StatsCard | goal = 0 | percent = 0, прогресс-бар пустой |
| WeightChart | chartData = [] | Text "Нет данных для графика" |
| RecommendationsSection | calculationResult = null | Секция скрыта |

---

### 11.4 Лимиты и валидация

| Поле | Минимум | Максимум | Действие при нарушении |
|------|---------|----------|------------------------|
| Возраст | 16 | 100 | SnackBar "Проверьте корректность данных" |
| Вес | 30 кг | 300 кг | SnackBar |
| Рост | 120 см | 250 см | SnackBar |
| История meals (limit) | 1 | 500 | Clamp на стороне backend |
| Calories goal | 1 | без ограничений | Валидация: > 0 |
| Аудиофайл пустой | - | - | SnackBar "Запись пустая" |
| Текст приёма пищи | 1 символ | - | Кнопка "Далее" задисейблена |

---

### 11.5 Конкурентный доступ

- Двойной tap на "Найти продукты" → кнопка disabled во время `isLoading`
- Двойной tap на "Добавить в дневник" → кнопка disabled во время `isLoading`
- Двойной tap на "Сохранить" (Settings) → кнопка disabled во время `isPending`

---

### 11.6 Telegram Deep Link

| Сценарий | Поведение |
|----------|-----------|
| Приложение закрыто, получен deep link | `app_links` запустит приложение, `main.dart` обработает URI |
| Приложение в фоне, получен deep link | `uriLinkStream` обработает URI |
| Токен истёк (backend вернул redirect на /login?error=invalid) | SnackBar "Ссылка недействительна. Попробуйте ещё раз." |
| Повторный использование токена | Токен удаляется из БД при первом использовании → backend вернёт redirect → SnackBar |

---

## 12. Локальное хранилище

**Пакет:** `shared_preferences: ^2.2.0`

### Ключи SharedPreferences

| Ключ | Тип | Описание |
|------|-----|----------|
| `user_language` | String | Язык интерфейса: `'ru'` или `'en'`. Дефолт: `'ru'` |
| `onboarding_pending` | String (JSON) | Данные онбординга до авторизации |

### Формат `onboarding_pending`

```json
{
  "training_days": "monday,wednesday,friday",
  "reward": "travel,gift",
  "age": 28,
  "weight": 82.5,
  "height": 178.0
}
```

**Когда записывается:** На шаге 6 онбординга при нажатии "Далее", если пользователь не авторизован.

**Когда читается:** В `WayToGoalScreen` при загрузке (предзаполнение полей age/weight/height).

**Когда удаляется:** После успешной синхронизации с backend (после авторизации через Telegram deep link и отправки всех данных).

**Класс-обёртка:**
```dart
class OnboardingPendingStorage {
  static const _key = 'onboarding_pending';

  // Сохранить
  static Future<void> save(OnboardingPending data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  // Прочитать (null если нет или невалидный JSON)
  static Future<OnboardingPending?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return OnboardingPending.fromJson(jsonDecode(raw));
    } catch {
      return null;
    }
  }

  // Удалить
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

### Синхронизация после Telegram-авторизации

После получения deep link `kayfit://auth?token=XXX` и успешного входа:

1. Прочитать `onboarding_pending`
2. Если данные есть:
   a. `POST /api/onboarding/answer {question_id: 1, answer: training_days}`
   b. `POST /api/profile {training_days}`
   c. `POST /api/onboarding/answer {question_id: 2, answer: reward}`
   d. `POST /api/profile {reward}`
   e. Если age > 0: `POST /api/profile {age, weight, height, current_weight: weight}`
   f. Удалить `onboarding_pending`
3. Инвалидировать `userProfileProvider`
4. Перейти на `/way-to-goal`

При ошибке на любом шаге — НЕ удалять `onboarding_pending`, попробовать позже (при следующем запуске).

---

## Покрытие компонентов из HLD

| Компонент HLD | Статус | Секция ТЗ |
|---------------|--------|-----------|
| LoginScreen (Apple+Google+Telegram) | Покрыт | 7.1 |
| Onboarding (10 шагов → фактически 6) | Покрыт | 7.2 (с допущением) |
| DashboardScreen | Покрыт | 7.4 |
| JournalScreen | Покрыт | 7.5 |
| AddMeal (голос/текст/фото/ручной) | Покрыт | 7.6 |
| SettingsScreen | Покрыт | 7.7 |
| WayToGoalScreen | Покрыт | 7.3 |
| TariffsScreen | Покрыт (заглушка) | 7.8 |
| BottomNav | Покрыт | 8.1 |
| StatsCard | Покрыт | 8.2 |
| EmotionPicker | Покрыт | 8.3 |
| MealItem | Покрыт | 8.4 |
| LoadingIndicator | Покрыт | 8.5 |
| WeightChart (fl_chart) | Покрыт | 8.6 |
| MealEditBottomSheet | Покрыт | 8.7 |
| API-контракты (18 эндпоинтов) | Покрыт | 3.1–3.23 |
| Freezed-модели | Покрыт | 4.1–4.7 |
| Riverpod провайдеры | Покрыт | 5.1–5.11 |
| go_router навигация | Покрыт | 6 |
| i18n ARB ключи | Покрыт | 9 |
| Камера (image_picker) | Покрыт | 10.1 |
| Микрофон (record) | Покрыт | 10.2 |
| Разрешения (permission_handler) | Покрыт | 10.3 |
| Edge Cases | Покрыт | 11 |
| SharedPreferences | Покрыт | 12 |
