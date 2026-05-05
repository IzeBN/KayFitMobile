# ТЗ: Ось E — Бэкенд-правки (тикеты P0-4.3 и P0-5.1)

> Версия: 1.0  
> Дата: 2026-05-02  
> Автор: system-analyst agent  
> Основание: HLD_hotfix_p0_2026-05-02.md §Ось E; ТЗ_исправления_первый_запуск.md §4.3, §5.1  
> Бэк-репо: `https://github.com/IzeBN/CaloriesApp` (подпапка `backend/`)  
> Фронт-репо: мобильный клон (`mobileKayfit/`)

---

## Допущения (зафиксированы из-за отсутствия доступа к бэк-репо)

- A1. Бэкенд написан на Python (FastAPI/Pydantic), исходя из openapi.json и структуры эндпоинтов.
- A2. Фронт использует `/api/v2/recognize_photo` (подтверждено кодом `add_meal_sheet.dart:311`), а не `/api/recognize_photo` из openapi.json. В openapi.json v2-эндпоинты не задокументированы. Все требования применяются к v2-версии эндпоинта.
- A3. Онбординг-экран вызывает `/api/onboarding/recognize_photo` (задокументирован в openapi.json с той же схемой `RecognizePhotoResponse`).
- A4. Промпты к AI встроены непосредственно в сервисный слой (`ai_service.py` / `ai_service_v2.py`) или в отдельный `prompts/` каталог.
- A5. AI-модель — неизвестна (см. Open Questions #1). Требования написаны нейтрально к провайдеру (OpenAI / Anthropic / другая vision-модель).
- A6. Backwards compatibility с предыдущим форматом ответа не нужна: hotfix 1.0.1 — синхронный выкат бэка и фронта.
- A7. Тесты пишутся через pytest; fixtures для фото — через mocker/mock объекты vision-модели.

---

## 1. Тикет P0-4.3 — Вода 0 ккал

### 1.1 Текущее поведение (вывод по коду фронта и openapi)

- Эндпоинты `/api/v2/recognize_photo` и `/api/onboarding/recognize_photo` передают изображение в AI-модель.
- AI возвращает массив `items`, каждый из которых содержит `nutrients_per_100g.calories` и `nutrients_total.calories`.
- Для «вода в стакане» AI может вернуть ненулевое значение, если выбирает неверную запись из USDA (например, «витаминизированная вода» или «кокосовая вода»).
- Нет никакой post-processing логики на бэке, которая принудительно обнуляла бы калории для воды.
- Фронт принимает значения как есть и показывает 170–250 ккал для воды (подтверждено фидбеком пользователя).

### 1.2 Требуемое изменение — Water Whitelist Override

#### Константа whitelist

Файл для создания: `backend/app/services/zero_calorie_whitelist.py`

```
ZERO_CALORIE_NAMES: frozenset[str] — нижний регистр, строки:
  'water', 'вода', 'water in glass', 'вода в стакане',
  'sparkling water', 'газированная вода', 'mineral water',
  'минеральная вода', 'still water', 'тихая вода',
  'tea', 'чай', 'green tea', 'зеленый чай', 'black tea',
  'черный чай', 'herbal tea', 'травяной чай',
  'black coffee', 'черный кофе', 'coffee black', 'americano',
  'americano coffee', 'эспрессо', 'espresso'

Правило совпадения: item_name.lower().strip() in ZERO_CALORIE_NAMES
  ИЛИ any(keyword in item_name.lower() for keyword in ZERO_CALORIE_PREFIXES)

ZERO_CALORIE_PREFIXES: frozenset[str]:
  'water', 'вода', 'sparkling water', 'газированная вода'
```

Допущение A8: список составлен консервативно — только то, что гарантированно 0 ккал. «Чай с молоком», «кофе с сахаром», «тоник» — НЕ входят в whitelist.

#### Функция override

Файл: `backend/app/services/zero_calorie_whitelist.py`

```
def apply_zero_calorie_override(items: list[dict]) -> list[dict]:
  """
  Для каждого item в items:
  если is_zero_calorie(item['name']):
    установить calories=0, protein=0, fat=0, carbs=0
    в обоих sub-объектах: nutrients_per_100g и nutrients_total
  Вернуть модифицированный список (новые объекты, не мутация).
  """
```

#### Точка вызова

Функция `apply_zero_calorie_override` вызывается в сервисном слое ПОСЛЕ получения ответа от AI-модели, ДО сериализации в response schema.

Файлы для правки:
- `backend/app/services/ai_service_v2.py` — добавить вызов после разбора ответа AI
- `backend/app/services/ai_service.py` — то же для v1-пути (онбординг)

#### Валидация response

Если в `RecognizePhotoResponse.items` есть поле `calories` на уровне item — добавить Pydantic `@model_validator(mode='after')`, который проверяет: если `is_zero_calorie(item.name)` и `item.calories > 0` → принудительно `item.calories = 0`. Это второй слой защиты.

#### POST /api/meals — дополнительная защита

Файл: `backend/app/api/meals.py`, обработчик `POST /api/meals`

Бизнес-правило: при сохранении блюда в БД, если `meal_name` проходит проверку `is_zero_calorie(meal_name)` → принудительно установить `calories=0`, `protein=0`, `fat=0`, `carbs=0` перед записью. Пользователь мог добавить воду через текстовый ввод, минуя AI.

### 1.3 Тест-кейсы P0-4.3

| # | Input | Expected response | Комментарий |
|---|-------|-------------------|-------------|
| TC-4.3.1 | AI вернул items=[{name: "вода в стакане", calories: 250}] | items=[{name: "вода в стакане", calories: 0, protein: 0, fat: 0, carbs: 0}] | Прямое совпадение |
| TC-4.3.2 | AI вернул items=[{name: "sparkling water", calories: 0}] | items=[{name: "sparkling water", calories: 0}] | Уже 0 — не трогаем |
| TC-4.3.3 | AI вернул items=[{name: "Coca-Cola", calories: 42}] | items=[{name: "Coca-Cola", calories: 42}] | Контроль: не входит в whitelist |
| TC-4.3.4 | POST /api/meals {name: "вода", calories: 170} | saved: {calories: 0} | Защита при ручном вводе |
| TC-4.3.5 | AI вернул items=[{name: "water in glass 250 ml", calories: 170}] | calories: 0 | Partial match на "water" |

---

## 2. Тикет P0-5.1 — is_food классификатор

### 2.1 Текущее поведение

- Эндпоинты `/api/v2/recognize_photo` и `/api/onboarding/recognize_photo` передают любое изображение в AI без предварительной проверки содержимого.
- Если AI не находит еду, он либо возвращает пустой `items: []` (лучший случай), либо галлюцинирует и возвращает случайные продукты (худший случай, подтверждён фидбеком «сфоткал собаку — выдало калории»).
- Поле `error` в `RecognizePhotoResponse` есть в openapi.json (`string | null`), но не используется для явной передачи причины «не еда».
- Фронт в `add_meal_sheet.dart:324–336` уже проверяет `error != null` и `rawItems.isEmpty`, но показывает общее «Could not recognize food» без структурированной причины.

### 2.2 Требуемое изменение — is_food pre-step

#### Изменение промпта AI

Файл: `backend/app/services/ai_service_v2.py` (и `ai_service.py` для онбординга)

Промпт к vision-модели должен включать **two-step structured output**:

```
Step 1 — Food Classification:
Is there any food or beverage in this image?
Return a JSON object:
{
  "is_food": true | false,
  "food_confidence": 0–100,
  "reason": "brief reason in English, max 20 words"
}
If is_food = false OR food_confidence < 60:
  Do NOT proceed to Step 2.
  Return the classification result only.

Step 2 — Nutrition Analysis (only if is_food=true and food_confidence >= 60):
  [существующий промпт нутриционного анализа]
```

Допущение A9: если vision-модель не поддерживает two-step в одном запросе — сделать два последовательных вызова: быстрый классификационный запрос (меньший контекст) → при is_food=true → полный нутриционный анализ. Выбор стратегии остаётся за бэкенд-разработчиком после уточнения Open Question #1.

#### Новая схема ответа

Файл: `backend/app/models/schemas_v2.py` (или `schemas.py` — где живёт `RecognizePhotoResponse`)

Текущая схема (из openapi.json):
```json
RecognizePhotoResponse:
  items: array (default: [])
  error: string | null
```

Новая схема (расширение, BC не требуется):
```json
RecognizePhotoResponse:
  items: array (default: [])
  error: string | null
  is_food: boolean | null  — новое поле, null если не применимо
  not_food_reason: string | null  — "not_food" | "low_confidence" | null
  message_key: string | null  — i18n ключ для фронта: "recognition_not_food"
```

Правило заполнения:
- Если is_food=false или confidence<60: `items=[]`, `error=null`, `is_food=false`, `not_food_reason="not_food"`, `message_key="recognition_not_food"`
- Если is_food=true и recognition прошла успешно: `items=[...]`, `error=null`, `is_food=true`, `not_food_reason=null`, `message_key=null`
- Если произошла ошибка AI (timeout, API error): `items=[]`, `error="<error_message>"`, `is_food=null`

#### Логика в сервисе

Файл: `backend/app/services/ai_service_v2.py`

```
async def recognize_photo_v2(image_bytes, language) -> RecognizePhotoResponse:
  1. Вызвать AI classification step (is_food check)
  2. Если NOT is_food OR confidence < 60:
       return RecognizePhotoResponse(
         items=[],
         error=None,
         is_food=False,
         not_food_reason="not_food",
         message_key="recognition_not_food"
       )
  3. Вызвать AI nutrition analysis step
  4. Применить apply_zero_calorie_override(items)
  5. return RecognizePhotoResponse(items=items, is_food=True, ...)
```

#### Эндпоинты для правки (бэк)

| Эндпоинт | Файл | Изменение |
|----------|------|-----------|
| `POST /api/v2/recognize_photo` | `backend/app/api/ai_v2.py` | Вызывать новый сервис; вернуть обновлённую схему |
| `POST /api/onboarding/recognize_photo` | `backend/app/api/onboarding.py` | То же |
| `POST /api/recognize_photo` (v1, если используется) | `backend/app/api/ai.py` | То же |

### 2.3 Тест-кейсы P0-5.1

| # | Input | AI mock: is_food | Expected response |
|---|-------|-----------------|-------------------|
| TC-5.1.1 | фото собаки | is_food=false, confidence=95 | `{items:[], is_food:false, not_food_reason:"not_food", message_key:"recognition_not_food"}` |
| TC-5.1.2 | фото пейзажа | is_food=false, confidence=99 | то же |
| TC-5.1.3 | фото текста/документа | is_food=false, confidence=80 | то же |
| TC-5.1.4 | фото тарелки с едой | is_food=true, confidence=92 | `{items:[...], is_food:true, ...}` нормальная работа |
| TC-5.1.5 | фото еды с confidence=55 | is_food=true, confidence=55 | `{items:[], is_food:false, not_food_reason:"not_food"}` — ниже порога |

---

## 3. Изменения OpenAPI — контракт

### 3.1 Эндпоинты, меняющие response shape

| Эндпоинт | Схема | Изменение |
|----------|-------|-----------|
| `POST /api/v2/recognize_photo` | `RecognizePhotoResponseV2` | Добавить поля `is_food`, `not_food_reason`, `message_key` |
| `POST /api/onboarding/recognize_photo` | `RecognizePhotoResponse` | Добавить те же поля (или сделать отдельную схему) |
| `POST /api/recognize_photo` (v1) | `RecognizePhotoResponse` | Добавить те же поля |
| `POST /api/meals` | `MealResponse` | Без изменений в схеме; изменение только в бизнес-логике |

### 3.2 Backwards compatibility

BC не требуется: hotfix 1.0.1 предполагает синхронный выкат бэка и фронта (мобильное приложение обновляется через App Store одновременно).

Все новые поля (`is_food`, `not_food_reason`, `message_key`) — nullable, поэтому старый фронт, не знающий о них, не сломается. Страховка на случай поэтапного выката.

---

## 4. Полный список файлов для правки

### Бэкенд (`CaloriesApp_backend/backend/`)

| # | Файл | Тип изменения | Тикет |
|---|------|---------------|-------|
| 1 | `app/services/zero_calorie_whitelist.py` | Создать новый | 4.3 |
| 2 | `app/services/ai_service_v2.py` | Добавить is_food pre-step; добавить вызов apply_zero_calorie_override | 4.3, 5.1 |
| 3 | `app/services/ai_service.py` | То же для v1-пути онбординга | 4.3, 5.1 |
| 4 | `app/models/schemas_v2.py` | Добавить поля is_food, not_food_reason, message_key | 5.1 |
| 5 | `app/models/schemas.py` | Добавить те же поля в RecognizePhotoResponse (если v1 и v2 разделены) | 5.1 |
| 6 | `app/api/ai_v2.py` | Подключить новую версию сервиса | 5.1 |
| 7 | `app/api/ai.py` | То же для v1 | 5.1 |
| 8 | `app/api/onboarding.py` | Обновить вызов recognize_photo; вернуть новую схему | 4.3, 5.1 |
| 9 | `app/api/meals.py` | Добавить zero_calorie override при POST | 4.3 |

Итого бэк: **9 файлов** (1 новый, 8 правок).

### Фронт (`mobileKayfit/lib/`)

| # | Файл | Тип изменения | Тикет |
|---|------|---------------|-------|
| 10 | `features/add_meal/screens/add_meal_sheet.dart` | Обработать `is_food=false` в `_pickAndRecognizePhoto` | 5.1 |
| 11 | `features/add_meal/screens/add_meal_sheet.dart` | Локальный whitelist-check для `_parseText` (вода через текст) | 4.3 |
| 12 | `shared/models/ingredient_v2.dart` | Добавить `isZeroCalorie` guard при `fromApiItem` | 4.3 |

Итого фронт: **3 файла** (все правки).

---

## 5. Фронт-сторона Оси E (для frontend-dev)

### 5.1 Обработка not_food ответа в `add_meal_sheet.dart`

Текущий код (`add_meal_sheet.dart:322–337`) проверяет `error != null` и `rawItems.isEmpty` раздельно.

**Новая логика** в методе `_pickAndRecognizePhoto`:

```
После получения resp:
  final isFoodDetected = resp.data['is_food'] as bool?;
  final notFoodReason = resp.data['not_food_reason'] as String?;

  if (isFoodDetected == false || notFoodReason == 'not_food') {
    // Показать диалог «не еда»
    _showNotFoodDialog(context);
    return;
  }
  // Существующая обработка items
```

Метод `_showNotFoodDialog`:
- Заголовок (локализованный): «Еда не обнаружена»
- Текст: «Не удалось распознать еду на фото. Поднесите камеру ближе к блюду.»
- Кнопка «Попробовать ещё раз» → вызвать `_pickAndRecognizePhoto(source)` снова
- Кнопка «Ввести вручную» → `_switchMode(_InputMode.text)`

Состояния компонента `AddMealSheet` при not_food:
- **loading**: стандартный `_LoadingType.photo` лоадер — не меняется
- **error**: не используется (not_food — не ошибка сервера)
- **empty**: диалог `_showNotFoodDialog` — новый кейс
- **success**: стандартный — не меняется

### 5.2 Локальная вода-проверка в `add_meal_sheet.dart` (тикет 4.3)

В методе `_parseText` перед отображением `RecognitionResultSheetV2` добавить локальный фильтр:

```
// После получения v2items:
final sanitized = v2items.map((item) {
  if (_isZeroCalorieName(item.name)) {
    return item.copyWith(
      nutrientsPer100g: item.nutrientsPer100g.copyWith(
        calories: 0, protein: 0, fat: 0, carbs: 0),
      nutrientsTotal: item.nutrientsTotal.copyWith(
        calories: 0, protein: 0, fat: 0, carbs: 0),
    );
  }
  return item;
}).toList();
```

Список `_isZeroCalorieName` совпадает с бэк-версией whitelist (синхронизировать вручную).

### 5.3 Локализация (l10n)

Добавить ключи в `lib/core/i18n/`:
- `recognition_not_food_title` — «Еда не обнаружена» / «Food Not Detected»
- `recognition_not_food_body` — «Не удалось распознать еду. Поднесите камеру ближе к блюду.»
- `recognition_try_again` — «Попробовать ещё раз» / «Try Again»
- `recognition_enter_manually` — «Ввести вручную» / «Enter Manually»

---

## 6. Тестовая стратегия (бэк, pytest)

### 6.1 Unit-тесты `zero_calorie_whitelist.py`

```
tests/unit/test_zero_calorie_whitelist.py:

test_water_variants_return_zero:
  inputs: ['water', 'вода', 'Water in Glass', 'SPARKLING WATER']
  assert apply_zero_calorie_override(items)[0].calories == 0

test_coca_cola_not_affected:
  input: [{name: 'Coca-Cola', calories: 42}]
  assert result[0].calories == 42

test_override_does_not_mutate_original:
  Проверить что оригинальный список не изменён (иммутабельность).

test_empty_list_returns_empty:
  apply_zero_calorie_override([]) == []
```

### 6.2 Unit-тесты `ai_service_v2.py` с mock AI

```
tests/unit/test_ai_service_v2.py:

test_not_food_returns_structured_not_food:
  Mock AI → {is_food: false, confidence: 95}
  result = await recognize_photo_v2(dog_image_bytes, 'ru')
  assert result.is_food == False
  assert result.items == []
  assert result.not_food_reason == 'not_food'
  assert result.message_key == 'recognition_not_food'

test_low_confidence_returns_not_food:
  Mock AI → {is_food: true, confidence: 45}
  result → is_food=False, items=[]

test_food_with_water_gets_zero_calories:
  Mock AI → {is_food: true, confidence: 88,
    items: [{name: 'вода в стакане', calories: 250, ...}]}
  result.items[0].calories == 0
  result.is_food == True
```

### 6.3 Интеграционные тесты эндпоинта

```
tests/integration/test_recognize_photo_endpoint.py:
(использовать httpx.AsyncClient + TestClient FastAPI)

test_recognize_photo_not_food_returns_200_with_is_food_false:
  POST /api/v2/recognize_photo + dog.jpg (mock AI)
  response.status_code == 200
  response.json()['is_food'] == False
  response.json()['items'] == []
  response.json()['message_key'] == 'recognition_not_food'

test_recognize_photo_food_returns_200_with_items:
  POST /api/v2/recognize_photo + food.jpg (mock AI)
  response.status_code == 200
  len(response.json()['items']) > 0
  response.json()['is_food'] == True

test_recognize_photo_water_returns_zero_calories:
  POST /api/v2/recognize_photo + water.jpg (mock AI → water 250 cal)
  response.json()['items'][0]['nutrients_total']['calories'] == 0
```

Фикстуры:
- `dog_image_bytes` — любой валидный JPEG, mock AI всегда вернёт `{is_food: false}`
- `food_image_bytes` — то же, mock AI вернёт `{is_food: true, items: [...]}`
- Использовать `pytest-mock` или `unittest.mock.patch` для подмены AI-клиента

---

## 7. Acceptance (из ТЗ продукта §4.3 и §5.1)

### Тикет 4.3 — Вода 0 ккал

- [ ] Вода в любом виде (text input, photo) → 0 ккал в response
- [ ] Тест-кейс: фото «вода в стакане 250 мл» → 0 ккал (TC-4.3.1)
- [ ] Тест-кейс: text input «вода» → 0 ккал (TC-4.3.4)
- [ ] Контрольный тест: «Coca-Cola» → ненулевые калории (TC-4.3.3)
- [ ] Чай без сахара, черный кофе → 0 ккал
- [ ] Фронт отображает 0 ккал для воды без дополнительных правок UI

### Тикет 5.1 — is_food классификатор

- [ ] Фото собаки → `{is_food: false, items: [], not_food_reason: "not_food"}`
- [ ] Фото пейзажа → то же
- [ ] Фото текста/документа → то же
- [ ] Фото реальной еды → `{is_food: true, items: [...]}` — нормальная работа
- [ ] Фронт показывает диалог «Еда не обнаружена» с кнопками «Попробовать ещё раз» и «Ввести вручную»
- [ ] Нет падения приложения, нет случайных калорий при not_food ответе

---

## 8. Open Questions (критичность)

**OQ-1 [КРИТИЧНО]: Какая vision-модель используется?**  
GPT-4o Vision (OpenAI), Claude Vision (Anthropic), или другая? Влияет на стратегию two-step prompting: OpenAI поддерживает structured outputs с `response_format: {type: "json_schema"}`, Anthropic — tool_use для структурированного ответа. Если модель не поддерживает structured output — нужен regex-парсер JSON из free-text ответа.

**OQ-2 [ВЫСОКИЙ]: Возвращает ли AI confidence score сейчас?**  
Если да — пороговую логику (< 60%) можно применять к уже существующему полю без изменения промпта. Если нет — нужно явно запросить confidence в промпте.

**OQ-3 [СРЕДНИЙ]: Где живут промпты — в коде или в отдельных файлах?**  
Если `app/prompts/*.txt` или `*.jinja2` — правка изолирована, не трогаем Python. Если промпты — строки внутри сервисных функций — правка затрагивает `ai_service_v2.py` / `ai_service.py` шире.

**OQ-4 [СРЕДНИЙ]: Есть ли `tests/` каталог в бэк-репо?**  
Если тестовой инфраструктуры нет — нужно создать `pytest.ini`, `conftest.py`, fixtures. Это добавляет ~1–2 ч к оценке бэка (текущая оценка HLD: 2 ч на 4.3 + 2 ч на 5.1).

---

## Резюме

**Где ТЗ:** `/Users/user/Desktop/КУРСОР/mobileKayfit/specs/TZ_axisE_backend_2026-05-02.md`

**Vision-модель:** не определена (бэк-репо недоступен для клонирования в рамках этой задачи). Судя по `IngredientV2.source = 'claude'` в `ingredient_v2.dart:22` — вероятно Anthropic Claude. Требует подтверждения через OQ-1.

**Файлы для правки:**
- Бэк: 9 файлов (1 новый + 8 правок)
- Фронт: 3 файла (все правки в существующих файлах)

**Критичные open questions:** OQ-1 (vision-модель) блокирует реализацию two-step prompting; OQ-2 (confidence score) влияет на объём изменений промпта.

**Оценка** (подтверждает HLD): бэк 4 ч, фронт 2 ч. При отсутствии тестов в репо — бэк +1–2 ч на setup.
