# HLD: Перенос «Путь к цели» и «После достижения цели» из FitKeep в KayFit

**Дата:** 2026-05-06  
**Статус:** Ожидает одобрения пользователя  
**Ветка:** создать новую (см. Вопрос 4)

---

## 1. SCOPE — что входит, что нет

### Входит
- Экран выбора формы тела (текущая + желаемая): `BodyFormScreen` из FitKeep
- «Путь к цели» в трактовке FitKeep: форма → % жира → расчёт веса и даты
- Понимание «После достижения цели» (см. раздел 2.3 ниже)
- Адаптация UI к KayFit-стилю (OBColors / AppColors, без FitKeep-токенов)
- Перенос/доработка локализации (EN+RU)

### Не входит (до отдельного решения)
- Переработка онбординга KayFit целиком
- Добавление видеороликов / анимаций, которых нет в FitKeep
- Push-уведомления по цели
- Аналитика за пределами уже используемых событий

---

## 2. Точная карта источника (FitKeepMobile)

### 2.1 Экраны и файлы

| Файл | Строк | Что содержит |
|------|-------|--------------|
| `lib/features/body_form/screens/body_form_screen.dart` | 442 | Выбор текущей + желаемой формы тела; 2-шаговый слайдер; POST `/quiz/answer/add` question_id 1101/1102 |
| `lib/features/way_to_goal/screens/way_to_goal_screen.dart` | 729 | Форма (возраст/вес/рост) + кнопка «Рассчитать»; результат (дата цели, целевой вес, fl_chart); секция «научный базис» |

### 2.2 Провайдеры и зависимости FitKeep

FitKeep **не использует** Riverpod-провайдеры для body_form или way_to_goal. Оба экрана — `ConsumerStatefulWidget`, которые напрямую читают `ref.read(apiClientProvider)` и держат стейт в локальных `setState`. Никаких отдельных `.dart`-провайдеров, `@freezed`-моделей, `.g.dart` файлов для этих фич нет.

### 2.3 «После достижения цели» — что это на самом деле

Поиск по всему коду FitKeep (`afterGoal`, `reachGoal`, `celebrate`, `after_goal`) не дал отдельного экрана или фичи. По итогам анализа:

**«После достижения цели» — это экран результата (`_buildResult()`) внутри самого `WayToGoalScreen`**, который показывается после расчёта:
- Дата достижения цели (`dateToGoal`)
- Целевой вес (карточка `_buildTargetWeightCard`)
- График снижения/набора веса (`fl_chart`, 5 точек)
- Карточка набора мышечной массы (`_buildMuscleGainCard`, если muscle_gain > 0)
- Мотивационный текст + «Научный базис»
- Кнопка «Next» → `/trains`

Отдельного экрана «после достижения» (push/celebration/повторный онбординг) в FitKeep не существует.

### 2.4 Ассеты

14 изображений форм тела — мужские и женские:
```
assets/onboarding/body-form-1.jpg … body-form-7.jpg
assets/onboarding/body-form-girl-1.jpg … body-form-girl-7.jpg
```
В KayFit директория `assets/` содержит только `assets/icon/icon.png` и **не объявляет** `assets/onboarding/` в `pubspec.yaml`. Папку и записи в pubspec нужно добавить.

### 2.5 API-вызовы FitKeep

| Метод + путь | Откуда вызывается | Назначение |
|---|---|---|
| `POST /quiz/answer/find` | `WayToGoalScreen._loadUserData()` | Получить age/height/weight/fat% из quiz |
| `POST /quiz/answer/add` (question_id 1101, 1102) | `BodyFormScreen._handleNext()` | Записать текущую и желаемую форму тела |
| `POST /calculate/weight_loss_date` | `WayToGoalScreen._calculate()` | Получить date_to_goal, target_weight, muscle_gain |

**Критично:** KayFit бэк (`app.carbcounter.online`) использует совершенно другой API: `/api/profile`, `/api/calculate`, `/api/calculation/result`, `/api/goals`. Эндпоинта `/calculate/weight_loss_date` и quiz-системы (`/quiz/answer/find`, `/quiz/answer/add`) в KayFit **нет**.

### 2.6 Локализация FitKeep (ключи для переноса)

**bodyForm-ключи (12 ключей):** `bodyFormCurrentQuestion`, `bodyFormDesiredQuestion`, `bodyFormNextButton`, `bodyFormFinishButton`, `bodyFormSliderLean`, `bodyFormSliderCurvy`, `bodyFormGoalLabel`, `bodyFormSendError`, `bodyFormGoal0Title`, `bodyFormGoal0Desc`, `bodyFormGoal1Title`, `bodyFormGoal1Desc`, `bodyFormGoal2Title`, `bodyFormGoal2Desc`, `bodyFormGoalConsultTitle`, `bodyFormGoalConsultDesc`

**wayToGoal-ключи (23 ключа):** `wayToGoalTitle`, `wayToGoalSubtitle`, `wayToGoalAge`, `wayToGoalAgeHint`, `wayToGoalWeight`, `wayToGoalWeightHint`, `wayToGoalHeight`, `wayToGoalHeightHint`, `wayToGoalDesiredFat`, `wayToGoalCalculate`, `wayToGoalResultTitle`, `wayToGoalMuscleTitle`, `wayToGoalMuscleUnit`, `wayToGoalMuscleDesc`, `wayToGoalTargetWeight`, `wayToGoalNextButton`, `wayToGoalMotivation`, `wayToGoalScienceTitle`, `wayToGoalToday`, `wayToGoalGoal`, `wayToGoalErrorFillAll`, `wayToGoalErrorAge`, `wayToGoalErrorWeight`, `wayToGoalErrorHeight`, `wayToGoalErrorNoFatTitle`, `wayToGoalErrorNoFat`, `wayToGoalErrorNoCurrentFatTitle`, `wayToGoalErrorNoCurrentFat`, `wayToGoalGoToBodyForm`, `wayToGoalErrorIncomplete`, `wayToGoalErrorDateFormat`, `wayToGoalErrorCalc`, `wayToGoalScience1`, `wayToGoalScience2`, `wayToGoalScience3`

Все ключи есть в EN и RU (`app_en.arb`, `app_ru.arb`).

---

## 3. Сравнение с существующим KayFit way_to_goal

### Что уже есть в KayFit (lib/features/way_to_goal/)

| Компонент | Файл | Описание |
|---|---|---|
| Экран | `screens/way_to_goal_screen.dart` | `ConsumerWidget`; загружает `calculationResultProvider`; показывает `PlanResultView`; sticky CTA «Начать дневник» → `/` |
| Провайдер | `providers/way_to_goal_provider.dart` | `@riverpod calculationResult` — пробует `/api/calculation/result`, fallback `/api/calculate`, кэш через `SharedPreferences` |
| Виджет | `widgets/plan_result_view.dart` | Персонализированный AI-баннер, hero-карточка с калориями, макросы, fl_chart, «как достичь», citation card |
| Модель | `shared/models/calculation_result.dart` | `@freezed`: bmr, tdee, targetCalories, protein, fat, carbs, daysToGoal, targetWeight, chartData, personalizedPlan |

### Что есть в FitKeep, чего нет в KayFit

| Возможность | FitKeep | KayFit | Решение |
|---|---|---|---|
| Выбор формы тела + % жира | BodyFormScreen (полноценный экран) | Нет | **Перенести** |
| Дата достижения цели (конкретная строка) | Да (из `/calculate/weight_loss_date`) | Есть поле `daysToGoal` в модели, но не дата | Адаптировать через daysToGoal → вычислить дату на клиенте |
| muscle_gain карточка (зелёная) | Да | Частично (chart показывает gain-ветку) | Можно добавить как вариант в PlanResultView |
| Форма ввода (age/weight/height) в way_to_goal | Да (первый шаг) | Нет — данные берутся из профиля автоматически | Открытый вопрос: нужна ли ручная форма или брать из профиля (см. вопросы) |
| Мотивационный текст | Статический текст | AI personalizedPlan (гораздо богаче) | KayFit-вариант лучше, оставить |
| «Научный базис» bullets | Да (3 пункта) | Да (CitationCard с PubMed + WHO) | KayFit-вариант лучше, оставить |

### Что уже реализовано в KayFit ЛУЧШЕ, чем в FitKeep
- Персонализированный AI-план (`personalizedPlan` от бэка)
- Кэш расчёта через `SharedPreferences`
- Fallback-логика (API → calculate → cache)
- Дизайн-система (OBColors, AppColors, градиенты)
- `PlanResultView` как переиспользуемый виджет (онбординг + отдельный экран)

### Вывод по стратегии
**Не заменять KayFit way_to_goal.** Перенести только отсутствующую часть: `BodyFormScreen` (выбор форм тела) и опционально форму ввода (age/weight/height) внутри way_to_goal. Обе части требуют адаптации к KayFit API и KayFit-стилю.

---

## 4. Расхождения и необходимые адаптации

### State management
Оба проекта на **Riverpod + go_router**. Версии практически идентичны:
- FitKeep: `flutter_riverpod: ^2.5.1`, `riverpod_annotation: ^2.3.5`
- KayFit: `flutter_riverpod: ^2.5.0`, `riverpod_annotation: ^2.3.0`

Идиомы совпадают. BodyFormScreen из FitKeep — `ConsumerStatefulWidget` с прямым вызовом `ref.read(apiClientProvider)` — паттерн работает в KayFit.

### Дизайн-токены (критично)

FitKeep использует захардкоженные hex-значения: `Color(0xFF3164E3)`, `Color(0xFF374151)`, `Color(0xFF525252)`. KayFit имеет собственную систему токенов `OBColors` и `AppColors`. При переносе все хардкоды нужно заменить на KayFit-токены.

| FitKeep хардкод | Смысл | KayFit-эквивалент |
|---|---|---|
| `Color(0xFF4E7EFB)` | primary blue | `AppColors.accent` или `OBColors.pink` |
| `Color(0xFF374151)` | dark button | `AppColors.text` |
| `Color(0xFFDBEAFE)` | light blue bg | `AppColors.accentSoft` |
| `Color(0xFF22C55E)` | green muscle | `AppColors.accent` (blue) или оставить зелёный |
| `Colors.white` scaffold | фон | `OBColors.bg` (кремовый) для онбординга или `Colors.white` для app-экранов |

### Навигация
KayFit router (`lib/router.dart`):
- `/body-form` — **маршрута нет**, нужно добавить
- `/way-to-goal` — уже есть, ведёт на `WayToGoalScreen`
- После `BodyFormScreen` FitKeep делает `context.go('/onboarding')` — в KayFit нет такого онбординга; кнопка «Finish» должна вести на `/way-to-goal` или `/settings/goals`

### API-адаптация (самое сложное)

FitKeep `BodyFormScreen` пишет ответы через `POST /quiz/answer/add` с `question_id: 1101/1102`. В KayFit такого API нет.

Возможные стратегии для хранения body_form данных:
1. **Добавить в `/api/profile`** — расширить профиль полями `current_fat_percentage`, `desired_fat_percentage` (требует бэкенд-работы в `CaloriesApp_backend/`)
2. **Хранить локально** — `SharedPreferences` (потеря при переустановке, не синхронизируется)
3. **Передавать через `/api/calculate`** — fat% как параметры при каждом пересчёте

FitKeep `WayToGoalScreen._calculate()` вызывает `POST /calculate/weight_loss_date` (age, weight, height, current_fat_percentage, desired_fat_percentage → date_to_goal, target_weight, muscle_gain). В KayFit можно:
- Вычислить `date_to_goal` на клиенте из `daysToGoal` поля `CalculationResult` (уже есть в модели)
- Либо добавить этот endpoint в `CaloriesApp_backend/`

### Локализация
KayFit использует `lib/core/i18n/generated/app_localizations.dart`. Нужно добавить ~47 новых ключей в оба `.arb`-файла и перегенерировать.

### Ассеты
Нужно:
1. Скопировать 14 jpg-файлов из `FitKeepMobile/assets/onboarding/` в `mobileKayfit/assets/onboarding/`
2. Добавить `- assets/onboarding/` в `flutter:` → `assets:` в `mobileKayfit/pubspec.yaml`

### Onboarding flow
KayFit `OnboardingScreen` уже содержит step `result`, который рендерит `PlanResultView`. `BodyFormScreen` нужно либо вставить как дополнительный шаг в онбординг KayFit, либо сделать отдельным экраном, доступным из Settings.

Текущий flow KayFit после онбординга:
```
onboarding result → auth → showWayToGoalProvider = true → router redirect → /way-to-goal
```
BodyFormScreen логично вставить **между шагами weight и training** в онбординге, или как отдельный экран `/body-form`, доступный из Settings → Цели.

---

## 5. Диаграмма итогового UX

```mermaid
flowchart TD
    A[Онбординг KayFit\nвозраст / вес / рост / пол / тренировки] --> B{Новый шаг:\nBodyFormScreen}
    B --> B1[Шаг 1: Текущая форма тела\n7 вариантов слайдер + фото]
    B1 --> B2[Шаг 2: Желаемая форма тела\n+ карточка goal info]
    B2 --> C[Онбординг: шаги info_1 / info_2 / info_3]
    C --> D[Онбординг: шаг result\nPlanResultView — калории + макросы + chart]
    D --> E[Онбординг: auth]
    E --> F{showWayToGoalProvider = true}
    F --> G[/way-to-goal\nWayToGoalScreen]
    G --> G1[PlanResultView\nперсональный план + калории + макросы]
    G1 --> G2{daysToGoal != null?}
    G2 -->|Да| G3[Карточка: целевой вес + дата\n+ forecast chart]
    G2 -->|Нет / maintain| G4[Карточка: поддержание веса]
    G3 --> H[CTA: Начать дневник → /]
    G4 --> H
    H --> I[Dashboard — дневник питания KayFit]

    J[Settings → Цели] --> K[GoalsScreen\nручная правка калорий/макросов]
    J --> L[/body-form — новый маршрут\nBodyFormScreen для повторной настройки]
    L --> B1
```

---

## 6. Декомпозиция задач

### Задача 1: Подготовка окружения
**Вайбкодинг | XS**  
- Создать ветку `feat/body-form-port`
- Скопировать 14 ассетов в `mobileKayfit/assets/onboarding/`
- Добавить `- assets/onboarding/` в `pubspec.yaml`
- Файлы: `pubspec.yaml`

### Задача 2: Добавить ARB-ключи локализации
**Вайбкодинг | S**  
- Добавить ~47 ключей (`bodyForm*`, `wayToGoal*`) в `lib/core/i18n/app_en.arb` и `app_ru.arb`
- Запустить codegen: `dart run build_runner build --delete-conflicting-outputs`
- Файлы: `lib/core/i18n/app_en.arb`, `lib/core/i18n/app_ru.arb`

### Задача 3: Портировать BodyFormScreen
**Вайбкодинг | M**  
Создать `mobileKayfit/lib/features/body_form/screens/body_form_screen.dart`:
- Заменить все FitKeep-хардкоды на KayFit-токены (`OBColors`, `AppColors`)
- Заменить API-вызов `POST /quiz/answer/add` → **решение из вопроса 2** (бэк / local prefs)
- Заменить навигацию: `context.go('/onboarding')` → `context.go('/way-to-goal')` или параметризовать
- Убрать `import analytics_service.dart` из FitKeep, заменить на KayFit `AnalyticsService`
- Файлы: новый `lib/features/body_form/screens/body_form_screen.dart`

### Задача 4: Добавить маршрут /body-form в router
**Вайбкодинг | XS**  
- Добавить `GoRoute(path: '/body-form', builder: ...)` в `lib/router.dart`
- Файлы: `lib/router.dart`

### Задача 5: Добавить BodyFormScreen в онбординг KayFit
**Вайбкодинг | S**  
- Добавить `_Step.bodyForm` в enum `_Step` в `onboarding_screen.dart`
- Вставить шаг после weight (или после training — **открытый вопрос 5**)
- Сохранить выбранные значения fat% в state онбординга и передать в `/api/calculate`
- Файлы: `lib/features/onboarding/screens/onboarding_screen.dart`

### Задача 6: Адаптировать /api/calculate для fat%
**ПРО-РАЗРАБОТЧИК | M**  
Если решение — добавить fat% на бэк:
- В `CaloriesApp_backend/` расширить схему запроса `/api/calculate`: добавить `current_fat_percentage`, `desired_fat_percentage` (опциональные)
- Опционально: добавить `/api/calculate/weight_loss_date` по образцу FitKeep
- Обновить `CalculationResult` freezed-модель в KayFit при изменении ответа
- **Полный контекст:** FitKeep endpoint принимает `{age, weight, height, current_fat_percentage, desired_fat_percentage}` и возвращает `{date_to_goal: ISO-строка, target_weight: float, muscle_gain: float}`
- Файлы: `CaloriesApp_backend/` (роуты + схемы), `mobileKayfit/lib/shared/models/calculation_result.dart`

### Задача 7: Показывать BodyFormScreen из Settings
**Вайбкодинг | XS**  
- Добавить пункт в `SettingsScreen` / `SettingsV2Screen` → `context.push('/body-form')`
- Файлы: `lib/features/settings/screens/settings_screen.dart` или `settings_v2_screen.dart`

---

## 7. Открытые вопросы к пользователю

### Q1. Перезаписать KayFit way_to_goal или добавить BodyFormScreen параллельно?
**Рекомендация:** не трогать существующий `WayToGoalScreen` — он полноценный. Добавить `BodyFormScreen` как отдельный экран (`/body-form`), который собирает fat%-данные и передаёт в `/api/calculate` при онбординге. Согласны?

### Q2. Бэк KayFit умеет хранить fat% или мокаем на клиенте?
- Вариант A: Расширить `CaloriesApp_backend/` — добавить поля в `/api/profile` и учесть fat% в `/api/calculate`
- Вариант B: Хранить в `SharedPreferences` (быстро, но теряется при переустановке)
- Вариант C: Передавать fat% в каждый запрос пересчёта без сохранения

### Q3. «После достижения цели» — уточнение
В FitKeep это просто результат-экран внутри way_to_goal (дата + вес + chart). В KayFit это уже реализовано в `PlanResultView`. Если подразумевалось что-то другое — push-уведомление при достижении веса, in-app celebration, повторный онбординг с новой целью — уточни, это отдельная задача.

### Q4. В какую ветку коммитим?
Рекомендую новую ветку от `main`: `feat/body-form-port`. В `main` сейчас 17 несохранённых файлов (modified: `mobileKayfit`) — нужно либо закоммитить их перед стартом, либо начать от текущего состояния.

### Q5. BodyFormScreen — только в онбординге или тоже в Settings?
- Только в онбординге (один раз при первом запуске)
- Из Settings тоже (пользователь может поменять целевую форму)
- Оба места

### Q6. Нужна ли форма ввода age/weight/height в way_to_goal?
FitKeep показывает форму ввода перед расчётом — KayFit берёт данные автоматически из профиля. Форма нужна только если пользователь хочет «проверить» другой сценарий без изменения профиля. Нужна ли ручная форма в /way-to-goal?

---

## 8. Риски

| Риск | Вероятность | Влияние | Митигация |
|---|---|---|---|
| Конфликты с 17 несохранёнными файлами | Высокая | Высокое | Создать ветку до начала; `git stash` или коммит накопленных изменений |
| Эндпоинта `/calculate/weight_loss_date` нет в KayFit бэке | Высокая | Среднее | Вычислять `dateToGoal` из `daysToGoal` на клиенте — данные уже есть в `CalculationResult` |
| Ассеты не объявлены в pubspec | Высокая | Высокое | Задача 1 обязательна первой |
| Дизайн-несовпадение: FitKeep синий vs KayFit розово-оранжевый | Высокая | Среднее | Заменить все хардкоды на токены при портировании |
| API quiz (`/quiz/answer/find`, `/quiz/answer/add`) отсутствует в KayFit | Высокая | Высокое | Либо SharedPreferences, либо расширить `/api/profile` |
| Несовпадение локализационных ключей | Средняя | Низкое | Добавить новые ключи перед запуском codegen |
| `shared_preferences` — уже есть в KayFit pubspec? | — | — | Да, есть (`shared_preferences: ^2.2.0`) — зависимость не нужно добавлять |
| `fl_chart` — есть в обоих? | — | — | FitKeep `^0.69.0`, KayFit `^0.68.0` — минорная разница, API совместимо |
| `intl` для DateFormat | — | — | Есть в обоих — OK |

---

## 9. Что НЕ нужно переносить

| Компонент FitKeep | Причина |
|---|---|
| Весь `analytics_service.dart` FitKeep | KayFit имеет собственный `AnalyticsService` |
| `core/api/api_client.dart` FitKeep | KayFit использует свой `apiDio` |
| Riverpod-провайдеры FitKeep | Их нет у body_form/way_to_goal в FitKeep |
| `l10n/generated/` файлы FitKeep | Регенерируются в KayFit после добавления `.arb`-ключей |
| Навигация FitKeep (`/trains`, `/onboarding` FitKeep) | Разные приложения |
