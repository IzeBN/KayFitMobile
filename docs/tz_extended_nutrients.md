# ТЗ: Расширенные нутриенты в API

## Контекст

Клиент (Flutter-приложение KayFit) уже поддерживает отображение расширенных нутриентов:
- Net Carbs (чистые углеводы)
- Fiber (клетчатка)
- Sugar (сахар)
- Sugar Alcohols (сахарные спирты)
- Saturated Fat (насыщенные жиры)
- Unsaturated Fat (ненасыщенные жиры)
- Glycemic Index (гликемический индекс)

**Проблема:** API возвращает только 4 базовых макроса (calories, protein, fat, carbs). Клиент вынужден использовать грубые оценки (fiber = carbs × 3%, saturated_fat = fat × 35%), что даёт неточные данные пользователю.

**Цель:** Добавить расширенные нутриенты во все затронутые эндпоинты API.

---

## Затронутые эндпоинты

### 1. `POST /api/recognize_photo`

**Текущий ответ (на ингредиент):**
```json
{
  "name": "Запечённый батат",
  "weight_grams": 200.0,
  "suggestions": [{
    "calories_per_100g": 113.0,
    "protein_per_100g": 1.9,
    "fat_per_100g": 3.2,
    "carbs_per_100g": 19.8,
    "source": "fatsecret"
  }]
}
```

**Требуемый ответ — добавить поля:**
```json
{
  "name": "Запечённый батат",
  "weight_grams": 200.0,
  "suggestions": [{
    "calories_per_100g": 113.0,
    "protein_per_100g": 1.9,
    "fat_per_100g": 3.2,
    "carbs_per_100g": 19.8,
    "fiber_per_100g": 3.0,           // НОВОЕ
    "sugar_per_100g": 4.2,           // НОВОЕ
    "sugar_alcohols_per_100g": 0.0,  // НОВОЕ
    "saturated_fat_per_100g": 1.4,   // НОВОЕ
    "unsaturated_fat_per_100g": 1.8, // НОВОЕ
    "glycemic_index": 70,            // НОВОЕ (целое число, nullable)
    "source": "fatsecret"
  }]
}
```

**Новые поля (все `float`, единицы — граммы на 100 г):**

| Поле | Тип | Обязательность | Описание |
|---|---|---|---|
| `fiber_per_100g` | float | обязательное | Клетчатка на 100 г |
| `sugar_per_100g` | float | обязательное | Сахар на 100 г |
| `sugar_alcohols_per_100g` | float | обязательное | Сахарные спирты на 100 г (обычно 0) |
| `saturated_fat_per_100g` | float | обязательное | Насыщенные жиры на 100 г |
| `unsaturated_fat_per_100g` | float | обязательное | Ненасыщенные жиры на 100 г |
| `glycemic_index` | int \| null | опциональное | ГИ продукта (0-100), null если неизвестен |

---

### 2. `POST /api/parse_meal_suggestions`

Тот же формат ответа, что и `recognize_photo`. Добавить те же 6 полей в каждый элемент `suggestions`.

**Вход:** `{"text": "куриная грудка 150г", "language": "ru"}`

**Выход:** такой же формат items/suggestions — дополнить новыми полями.

---

### 3. `POST /api/meals/add_selected`

**Текущий формат элемента в `items`:**
```json
{
  "name": "Батат",
  "calories": 226,
  "protein": 3.8,
  "fat": 6.4,
  "carbs": 39.6,
  "weight": 200
}
```

**Новый формат — клиент уже отправляет эти поля (после обновления):**
```json
{
  "name": "Батат",
  "calories": 226,
  "protein": 3.8,
  "fat": 6.4,
  "carbs": 39.6,
  "weight": 200,
  "fiber": 6.0,
  "sugar": 8.4,
  "sugar_alcohols": 0.0,
  "net_carbs": 33.6,
  "saturated_fat": 2.8,
  "unsaturated_fat": 3.6,
  "glycemic_index": 70
}
```

**Требование:** Бэкенд должен принимать и сохранять эти поля в БД. Если поле не передано — сохранять `null`.

---

### 4. `GET /api/stats`

**Текущий ответ:**
```json
{
  "calories": {"current": 1200, "goal": 2000},
  "protein": {"current": 80, "goal": 120},
  "fat": {"current": 50, "goal": 70},
  "carbs": {"current": 150, "goal": 200},
  "compulsive_count": 0
}
```

**Требуемый ответ — добавить:**
```json
{
  "calories": {"current": 1200, "goal": 2000},
  "protein": {"current": 80, "goal": 120},
  "fat": {"current": 50, "goal": 70},
  "carbs": {"current": 150, "goal": 200},
  "net_carbs": {"current": 120, "goal": 150},
  "fiber": {"current": 30, "goal": 25},
  "sugar": {"current": 40, "goal": 50},
  "saturated_fat": {"current": 15, "goal": 20},
  "unsaturated_fat": {"current": 35, "goal": 50},
  "compulsive_count": 0
}
```

`current` — сумма за сегодня по сохранённым приёмам пищи.
`goal` — из настроек пользователя (см. раздел "Цели" ниже).

---

### 5. `GET /api/meals` и `GET /api/meals/history`

Каждый объект meal должен возвращать расширенные нутриенты:

```json
{
  "id": 123,
  "name": "Батат запечённый",
  "calories": 226,
  "protein": 3.8,
  "fat": 6.4,
  "carbs": 39.6,
  "weight": 200,
  "fiber": 6.0,
  "sugar": 8.4,
  "sugar_alcohols": 0.0,
  "net_carbs": 33.6,
  "saturated_fat": 2.8,
  "unsaturated_fat": 3.6,
  "glycemic_index": 70,
  "dish_name": "...",
  "meal_type": "lunch",
  "created_at": "2026-04-14T12:30:00Z"
}
```

---

### 6. `PATCH /api/meals/{id}`

Должен принимать и обновлять расширенные нутриенты (аналогично `add_selected`).

---

## Изменения в БД

### Таблица `meals` — добавить колонки:

| Колонка | Тип | Default | Описание |
|---|---|---|---|
| `fiber` | FLOAT | NULL | Клетчатка, г |
| `sugar` | FLOAT | NULL | Сахар, г |
| `sugar_alcohols` | FLOAT | NULL | Сахарные спирты, г |
| `net_carbs` | FLOAT | NULL | Чистые углеводы, г |
| `saturated_fat` | FLOAT | NULL | Насыщенные жиры, г |
| `unsaturated_fat` | FLOAT | NULL | Ненасыщенные жиры, г |
| `glycemic_index` | INT | NULL | Гликемический индекс |

**Миграция:** `ALTER TABLE` с `DEFAULT NULL` — обратно совместимо, старые записи получат NULL.

### Цели пользователя — расширить настройки:

Добавить возможность хранить цели по расширенным нутриентам. Дефолтные значения (если пользователь не задал):

| Нутриент | Дефолтная цель | Источник |
|---|---|---|
| net_carbs | `carbs_goal × 0.85` | Расчёт от целей по углеводам |
| fiber | 25 г | Рекомендация ВОЗ |
| sugar | 50 г | Рекомендация ВОЗ (max) |
| saturated_fat | `fat_goal × 0.33` | ~1/3 от общего жира |
| unsaturated_fat | `fat_goal × 0.67` | ~2/3 от общего жира |

---

## Источники данных для расширенных нутриентов

### Приоритет:

1. **FatSecret API** — если используется, у них есть поля `fiber`, `sugar`, `saturated_fat` в Nutrition API (метод `food.get.v4`). Сейчас, судя по ответам, эти поля **не запрашиваются или не пробрасываются** — нужно добавить.

2. **Claude (AI-распознавание)** — при генерации данных через LLM добавить в промпт требование возвращать все 6 полей. Пример промпта:
   ```
   Для каждого ингредиента верни JSON с полями:
   calories_per_100g, protein_per_100g, fat_per_100g, carbs_per_100g,
   fiber_per_100g, sugar_per_100g, sugar_alcohols_per_100g,
   saturated_fat_per_100g, unsaturated_fat_per_100g, glycemic_index
   ```

3. **Fallback:** если источник не содержит данных — вернуть `null` (не 0). Клиент сам подставит оценку.

---

## Обратная совместимость

- Все новые поля **nullable** — старые клиенты их игнорируют
- `add_selected` принимает старый формат (без новых полей) — сохраняет NULL
- Существующие записи в БД — NULL в новых колонках

---

## Критерии приёмки

1. `POST /api/recognize_photo` — возвращает `fiber_per_100g`, `sugar_per_100g`, `sugar_alcohols_per_100g`, `saturated_fat_per_100g`, `unsaturated_fat_per_100g`, `glycemic_index` для каждого ингредиента
2. `POST /api/parse_meal_suggestions` — аналогично
3. `POST /api/meals/add_selected` — принимает и сохраняет все расширенные поля
4. `GET /api/stats` — возвращает `net_carbs`, `fiber`, `sugar`, `saturated_fat`, `unsaturated_fat` с current/goal
5. `GET /api/meals` и `/api/meals/history` — возвращают расширенные поля для каждого meal
6. `PATCH /api/meals/{id}` — обновляет расширенные поля
7. Миграция БД не ломает существующие данные

---

## Приоритет реализации

| Приоритет | Эндпоинт | Причина |
|---|---|---|
| P0 | `recognize_photo`, `parse_meal_suggestions` | Без этого клиент показывает оценки вместо реальных данных |
| P0 | `meals/add_selected` | Без этого данные теряются при сохранении |
| P1 | `GET /api/stats` | Дашборд показывает нули по расширенным нутриентам |
| P1 | `GET /api/meals`, `/api/meals/history` | Журнал не показывает детализацию |
| P2 | `PATCH /api/meals/{id}` | Редактирование — вторичный flow |
| P2 | Цели пользователя | Можно начать с дефолтных |
