# ТЗ — Ось C: UX Dismiss Patterns (тикеты P0-7.1, 7.2, 7.3)
# Kayfit Flutter · Hotfix 1.0.1

> Версия: 1.0.0  
> Дата: 2026-05-02  
> Автор: system-analyst agent  
> Основание: HLD_hotfix_p0_2026-05-02.md §Ось C; ТЗ_исправления_первый_запуск.md §7.1–7.3

---

## 1. Введение

Три тикета — одна корневая причина: **отсутствие единого паттерна dismiss-поведений в приложении**.

| Симптом | Тикет |
|---------|-------|
| Клавиатура не прячется по тапу вне поля и по свайпу | 7.1 |
| Bottom sheets не реагируют на drag-down, tap-outside, нет кнопки X | 7.2 |
| Из AI-чата невозможно выйти — нет back-кнопки | 7.3 |

**Общее решение** закрывает все три тикета двумя инфраструктурными изменениями:

1. `KeyboardDismisser` — виджет-обёртка, добавляемый на каждый экран с `TextField`.
2. `DismissibleSheetWrapper` — стандартизированная обёртка для всех bottom sheets.

Дополнительно для 7.3: добавление `AppBar` с back-кнопкой в `ChatScreen` (экран уже доступен через `ShellRoute` в go_router).

**Допущение A**: `ChatScreen` открывается строго как tab-роут `/chat` через `ShellRoute` — не через `showModalBottomSheet`. Подтверждено чтением `lib/router.dart`: `GoRoute(path: '/chat', builder: ...)` внутри `ShellRoute`. Drag-down для чата не применяется — используется back-навигация.

**Допущение Б**: `flutter_secure_storage` не используется в рамках этого тикета. Зависимостей от тикетов Оси A нет — Ось C полностью независима.

---

## 2. Тикет 7.1 — Закрытие клавиатуры

### 2.1 Где сейчас баг

Экраны с `TextField`, где клавиатура не прячется по тапу вне поля:

| # | Файл | TextField |
|---|------|-----------|
| 1 | `lib/features/chat/screens/chat_screen.dart` | `_InputRow` → `TextField` (multiline) |
| 2 | `lib/features/add_meal/screens/add_meal_sheet.dart` | текстовый ввод блюда (`_textController`) |
| 3 | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` | `_V2IngredientSearchSheet` → `TextField` поиска |
| 4 | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` | `_IngredientTile` → вес (`_weightCtrl`) |
| 5 | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` | `_CorrectionPanel` → `_correctionCtrl` |
| 6 | `lib/features/journal/screens/edit_meal_screen.dart` | поля name/calories/protein/fat/carbs |

### 2.2 Решение

#### 2.2.1 Новый виджет KeyboardDismisser

**Файл (новый)**: `lib/shared/widgets/keyboard_dismisser.dart`

```dart
// Сигнатура (без реализации):
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  final Widget child;

  // Оборачивает child в GestureDetector с behavior: HitTestBehavior.opaque,
  // onTap вызывает FocusScope.of(context).unfocus().
  // Не перехватывает taps на интерактивные дочерние виджеты —
  // GestureDetector срабатывает только на пустое пространство благодаря
  // стандартной hit-test bubble в Flutter.
}
```

**Параметры**:
- `child` (required) — содержимое экрана
- Нет дополнительных параметров. Виджет стационарный, без состояния.

#### 2.2.2 Применение KeyboardDismisser

Завернуть `Scaffold.body` (или сам `Scaffold`) в `KeyboardDismisser` на каждом экране из §2.1. Порядок — снаружи `Scaffold`, чтобы охватить всю область.

#### 2.2.3 ScrollView keyboardDismissBehavior

В `ChatScreen._ChatScreenState.build()` — `ListView.builder` со списком сообщений:

```dart
// Добавить параметр:
keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
```

Аналогично в `_V2IngredientSearchSheet` — если используется `ListView` для результатов поиска.

#### 2.2.4 TextInputAction.done (iOS toolbar)

В `_InputRow._InputRowState.build()` добавить к `TextField`:

```dart
textInputAction: TextInputAction.newline, // уже есть или заменить на:
onSubmitted: (_) => FocusScope.of(context).unfocus(),
```

Явный toolbar «Готово» через `inputAccessoryView` — за пределами scope этого тикета (нет зависимости `flutter_keyboard_actions` в `pubspec.yaml`). Достаточно `TextInputAction.done` для однострочных полей. Многострочное поле чата (`minLines: 1, maxLines: 4`) оставить с `textInputAction: TextInputAction.newline` — iOS показывает Return, что приемлемо.

### 2.3 Файлы для правки

| Действие | Файл |
|----------|------|
| **Создать** | `lib/shared/widgets/keyboard_dismisser.dart` |
| Правка | `lib/features/chat/screens/chat_screen.dart` |
| Правка | `lib/features/add_meal/screens/add_meal_sheet.dart` |
| Правка | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` |
| Правка | `lib/features/journal/screens/edit_meal_screen.dart` |

### 2.4 Тесты

**Файл (новый)**: `test/widget/keyboard_dismisser_test.dart`

- `testWidgets('KeyboardDismisser unfocuses on tap outside TextField')`:
  1. `pumpWidget(MaterialApp(home: KeyboardDismisser(child: Scaffold(body: TextField()))))` 
  2. `tap(find.byType(TextField))` → фокус получен
  3. `tap(find.byType(Scaffold))` в координатах вне поля
  4. `expect(FocusScope.of(context).hasPrimaryFocus, isFalse)`

- `testWidgets('chat ListView has keyboardDismissBehavior.onDrag')`:
  1. pump `ChatScreen` с заглушкой провайдеров
  2. `expect(find.byWidgetPredicate((w) => w is ListView && w.keyboardDismissBehavior == ScrollViewKeyboardDismissBehavior.onDrag), findsOneWidget)`

---

## 3. Тикет 7.2 — Стандартизация Bottom Sheets

### 3.1 Аудит — все места вызова showModalBottomSheet

Все вызовы найдены grep'ом по `lib/`:

| # | Файл | Метод/контекст | isDismissible | enableDrag | showDragHandle | кнопка X |
|---|------|---------------|:---:|:---:|:---:|:---:|
| 1 | `lib/features/dashboard/screens/dashboard_screen.dart:156` | `_showAddMeal` → `AddMealSheet` | — | — | — | нет |
| 2 | `lib/features/journal/screens/journal_screen.dart:150` | `_showAddMeal` → `AddMealSheet` | — | — | — | нет |
| 3 | `lib/features/add_meal/screens/add_meal_sheet.dart:166` | `_parseText` → `DraggableScrollableSheet` + `RecognitionResultSheetV2` | — | — | — | нет |
| 4 | `lib/features/add_meal/screens/add_meal_sheet.dart:346` | `_pickAndRecognizePhoto` → `DraggableScrollableSheet` + `RecognitionResultSheetV2` | — | — | — | нет |
| 5 | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart:168` | `_addIngredient` → `_V2IngredientSearchSheet` | — | — | — | нет |
| 6 | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart:822` | `_showDetailSheet` → `NutrientDetailSheet` | — | — | — | нет |
| 7 | `lib/features/journal/widgets/meal_group_card.dart:228` | `_showGroupDetail` → `_GroupDetailSheet` | — | — | — | нет |
| 8 | `lib/features/journal/widgets/meal_group_card.dart:237` | `_showMealDetail` → `_MealDetailSheet` | — | — | — | нет |

**Итого: 8 мест**. Ни одно не задаёт `isDismissible`, `enableDrag`, `showDragHandle`. Drag handle существует только декоративно внутри контента (ручной `Container` 36×4 в `_MealDetailSheet`, `NutrientDetailSheet`).

Дополнительно — кастомные sheet-контейнеры (не через `showModalBottomSheet`, но выглядят как шторки):
- `AddMealSheet` — сам является содержимым шторки (#1, #2), завёрнут в `FadeTransition + SlideTransition`. Не имеет кнопки X.
- `RecognitionResultSheetV2` — содержимое `DraggableScrollableSheet` (#3, #4). Нет кнопки закрытия.

### 3.2 Новый виджет DismissibleSheetWrapper

**Файл (новый)**: `lib/shared/widgets/dismissible_sheet_wrapper.dart`

```dart
// Сигнатура (без реализации):
class DismissibleSheetWrapper extends StatelessWidget {
  const DismissibleSheetWrapper({
    super.key,
    required this.child,
    this.onClose,
    this.showCloseButton = true,
    this.draggable = true,
    this.dismissibleByBarrier = true,
    this.borderRadius = const BorderRadius.vertical(top: Radius.circular(20)),
  });

  /// Основной контент шторки.
  final Widget child;

  /// Коллбэк при закрытии через кнопку X. Если null — вызывается Navigator.pop.
  final VoidCallback? onClose;

  /// Показывать кнопку X в правом верхнем углу. Default: true.
  final bool showCloseButton;

  /// Включить drag handle и свайп вниз. Default: true.
  final bool draggable;

  /// Закрывать по тапу на barrier. Default: true.
  /// Используется только как документация — управляется через showModalBottomSheet(isDismissible:).
  final bool dismissibleByBarrier;

  /// Радиус углов контейнера.
  final BorderRadius borderRadius;
}
```

**Поведение**:
- Отображает декоративный drag handle сверху (если `draggable: true`): `Container` шириной 36, высотой 4, цвет `AppColors.border`, `BorderRadius.circular(2)`.
- Кнопка X (`IconButton` с `Icons.close_rounded`) в правом верхнем углу поверх контента (Stack или Row в заголовке), если `showCloseButton: true`. При нажатии вызывает `onClose?.call() ?? Navigator.of(context).pop()`.
- Оборачивает `child` в `Container` с `borderRadius` и `color: AppColors.surface`.

### 3.3 Стандартизация вызовов showModalBottomSheet

Каждый из 8 вызовов привести к форме:

```dart
showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,   // уже установлен везде
  backgroundColor: Colors.transparent,  // уже установлен везде
  isDismissible: true,         // ДОБАВИТЬ
  enableDrag: true,            // ДОБАВИТЬ
  showDragHandle: false,       // false — handle внутри DismissibleSheetWrapper
  builder: (_) => DismissibleSheetWrapper(
    child: <исходный контент>,
  ),
);
```

**Исключения для DraggableScrollableSheet** (#3, #4):  
`DraggableScrollableSheet` имеет собственный drag. Добавить `isDismissible: true` и `enableDrag: true` к вызову `showModalBottomSheet`. `DismissibleSheetWrapper` завернуть только вокруг `RecognitionResultSheetV2` — кнопка X в правом верхнем углу закрывает через `Navigator.pop(context, false)`.

### 3.4 Файлы для правки/создания

| Действие | Файл |
|----------|------|
| **Создать** | `lib/shared/widgets/dismissible_sheet_wrapper.dart` |
| Правка | `lib/features/dashboard/screens/dashboard_screen.dart` |
| Правка | `lib/features/journal/screens/journal_screen.dart` |
| Правка | `lib/features/add_meal/screens/add_meal_sheet.dart` |
| Правка | `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` |
| Правка | `lib/features/journal/widgets/meal_group_card.dart` |

### 3.5 Тесты

**Файл (новый)**: `test/widget/dismissible_sheet_wrapper_test.dart`

- `testWidgets('sheet closes on barrier tap')`:
  1. pump кнопку, по нажатию открывает `showModalBottomSheet(..., isDismissible: true, builder: (_) => DismissibleSheetWrapper(child: SizedBox(height: 200)))`
  2. tap на кнопку → sheet виден
  3. `tapAt(Offset(200, 100))` — координаты на barrier
  4. `pumpAndSettle()`
  5. `expect(find.byType(DismissibleSheetWrapper), findsNothing)`

- `testWidgets('sheet closes on X button tap')`:
  1. pump `DismissibleSheetWrapper(showCloseButton: true, child: SizedBox())`
  2. `tap(find.byIcon(Icons.close_rounded))`
  3. `expect(find.byType(DismissibleSheetWrapper), findsNothing)`

- `testWidgets('drag handle visible when draggable: true')`:
  1. pump `DismissibleSheetWrapper(draggable: true, child: SizedBox())`
  2. `expect(find.byWidgetPredicate((w) => w is Container && /* 36×4 */), findsOneWidget)`

---

## 4. Тикет 7.3 — Выход из AI-чата

### 4.1 Где проблема

**Файл**: `lib/features/chat/screens/chat_screen.dart`

`ChatScreen.build()` возвращает `Scaffold` без `AppBar`. Вместо AppBar используется кастомный `_ChatHeader` — `Container` с градиентом. В нём есть `Row` с аватаром, названием и кнопкой корзины — но нет back-кнопки.

**Навигация**: чат открывается как tab-роут `/chat` через `ShellRoute` → `ScaffoldWithBottomNav`. При переходе `context.go('/chat')` стек GoRouter не создаёт pop-точки — `context.pop()` вернёт на предыдущий tab. Swipe-back на iOS работает при использовании `context.push('/chat')`, но текущий код использует `context.go`. 

**Допущение В**: бизнес-требование — вернуться на предыдущий tab (Dashboard или Journal), откуда был открыт чат. Это уже обеспечивает `ScaffoldWithBottomNav` через нижнюю навигацию. Достаточно добавить back-кнопку в `_ChatHeader`, которая вызывает `context.go('/')` (или хранит предыдущий tab — см. Open Questions).

### 4.2 Решение

В `_ChatHeader.build()` добавить back-кнопку как первый элемент `Row`:

```dart
// Сигнатура изменения _ChatHeader (без реализации):
// Добавить параметр:
final VoidCallback onBack;

// В Row:
// leading: IconButton / GestureDetector с Icons.arrow_back_ios_new_rounded,
// цвет: Colors.white, размер 20, onPressed: onBack
```

В `ChatScreen.build()` передать `onBack: () => context.go('/')`.

**iOS swipe-back**: Поскольку чат — ShellRoute tab, а не pushed route, нативный swipe-back iOS недоступен. Это стандартное поведение для tab-based навигации. Два способа выхода из чата:
1. Кнопка X / стрелка назад в `_ChatHeader` → `context.go('/')`.
2. Тап по другому tab в `ScaffoldWithBottomNav`.

Этого достаточно для выполнения acceptance-критерия «выйти минимум двумя способами».

### 4.3 Файлы для правки

| Действие | Файл |
|----------|------|
| Правка | `lib/features/chat/screens/chat_screen.dart` |

### 4.4 Тесты

**Файл (новый)**: `test/widget/chat_screen_back_test.dart`

- `testWidgets('ChatScreen has back button in header')`:
  1. pump `ChatScreen` с overrides провайдеров (`aiConsentProvider → true`, mock `apiDio`)
  2. `expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget)`

- `testWidgets('back button triggers navigation')`:
  1. pump с mock `GoRouter`
  2. `tap(find.byIcon(Icons.arrow_back_ios_new_rounded))`
  3. verify `router.go('/')` был вызван

---

## 5. Общая инфраструктура

### 5.1 KeyboardDismisser — полная спецификация

**Файл**: `lib/shared/widgets/keyboard_dismisser.dart`

```dart
// Публичный API:
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({super.key, required this.child});
  final Widget child;
  // build() возвращает GestureDetector(
  //   behavior: HitTestBehavior.opaque,
  //   onTap: () => FocusScope.of(context).unfocus(),
  //   child: child,
  // )
}
```

**Ограничения**:
- Не использовать `TapRegion` — требует Flutter 3.3+; `pubspec.yaml` таргетирует sdk `^3.11.1`, TapRegion доступен, но `GestureDetector` проще и достаточен.
- Не оборачивать `MaterialApp.builder` глобально: `GestureDetector` с `HitTestBehavior.opaque` на уровне `MaterialApp` перехватывает taps в диалогах и шторках, что создаёт неожиданное поведение. Использовать локально на уровне Scaffold каждого экрана.

### 5.2 DismissibleSheetWrapper — полная спецификация

**Файл**: `lib/shared/widgets/dismissible_sheet_wrapper.dart`

Параметры описаны в §3.2.

**Ключевое поведение**:
- Кнопка X: `Positioned(top: 8, right: 8)` или последний элемент `Row` в шапке шторки. Размер иконки 20, цвет `AppColors.textMuted`.
- Drag handle: всегда первый элемент `Column` — `Center(child: Container(...))`.
- Фон: `Colors.transparent` у `showModalBottomSheet`, сам виджет задаёт `color: AppColors.surface` внутри `Container` с `borderRadius`.

### 5.3 Порядок применения на каждом экране

1. Обернуть `Scaffold` (или `body` Scaffold) в `KeyboardDismisser` на экранах #1–#6 из §2.1.
2. Заменить все 8 вызовов `showModalBottomSheet` по схеме §3.3.
3. Добавить back-кнопку в `_ChatHeader` по §4.2.

---

## 6. Полный список файлов

### Новые файлы

| Файл | Назначение |
|------|-----------|
| `lib/shared/widgets/keyboard_dismisser.dart` | Обёртка для скрытия клавиатуры |
| `lib/shared/widgets/dismissible_sheet_wrapper.dart` | Стандартная шторка с X, drag handle |
| `test/widget/keyboard_dismisser_test.dart` | Widget tests 7.1 |
| `test/widget/dismissible_sheet_wrapper_test.dart` | Widget tests 7.2 |
| `test/widget/chat_screen_back_test.dart` | Widget tests 7.3 |

### Изменяемые файлы

| Файл | Что меняется |
|------|-------------|
| `lib/features/chat/screens/chat_screen.dart` | `_ChatHeader`: добавить back-кнопку + параметр `onBack`; `ListView.builder`: добавить `keyboardDismissBehavior`; Scaffold обернуть в `KeyboardDismisser` |
| `lib/features/add_meal/screens/add_meal_sheet.dart` | 2 вызова `showModalBottomSheet` → добавить `isDismissible`, `enableDrag`; завернуть контент в `DismissibleSheetWrapper`; Scaffold/Container обернуть в `KeyboardDismisser` |
| `lib/features/add_meal/screens/recognition_result_sheet_v2.dart` | `_showDetailSheet`, `_addIngredient`: добавить параметры шторки; добавить кнопку X в `RecognitionResultSheetV2`; `_V2IngredientSearchSheet`: `KeyboardDismisser` |
| `lib/features/dashboard/screens/dashboard_screen.dart` | `_showAddMeal`: добавить `isDismissible`, `enableDrag`, `DismissibleSheetWrapper` |
| `lib/features/journal/screens/journal_screen.dart` | `_showAddMeal`: добавить `isDismissible`, `enableDrag`, `DismissibleSheetWrapper` |
| `lib/features/journal/widgets/meal_group_card.dart` | `_showGroupDetail`, `_showMealDetail`: добавить `isDismissible`, `enableDrag`, `DismissibleSheetWrapper` |
| `lib/features/journal/screens/edit_meal_screen.dart` | Scaffold обернуть в `KeyboardDismisser` |

---

## 7. Тестовая стратегия

### 7.1 Widget Tests (автоматические)

Файлы описаны в §2.4, §3.5, §4.4. Итого: 7 widget-тестов.

Для каждого теста использовать `ProviderScope` с минимальными overrides:
- `aiConsentProvider` → `StateProvider<bool?>((_) => true)`
- HTTP-вызовы мокировать через fake `apiDio` или не вызывать (тесты чисто UI)

### 7.2 Manual Regression Checklist (для QA)

**7.1 — Клавиатура:**

| # | Экран | Шаг | Ожидаемый результат |
|---|-------|-----|---------------------|
| 1 | AI-чат (`/chat`) | Тапнуть в поле ввода → напечатать → тапнуть в область списка сообщений | Клавиатура убирается |
| 2 | AI-чат | Открыть клавиатуру → свайпнуть вниз по списку сообщений | Клавиатура убирается интерактивно |
| 3 | AddMealSheet (текстовый режим) | Тапнуть в поле → тапнуть вне поля на фон шторки | Клавиатура убирается |
| 4 | EditMealScreen | Тапнуть в поле «Название» → тапнуть на свободную область экрана | Клавиатура убирается |
| 5 | RecognitionResultSheetV2 → поле веса ингредиента | Тапнуть в поле → тапнуть вне | Клавиатура убирается |

**7.2 — Bottom sheets:**

| # | Шторка | Способ закрытия | Ожидаемый результат |
|---|--------|----------------|---------------------|
| 6 | AddMealSheet (Dashboard или Journal) | Тап на затемнение | Шторка закрывается |
| 7 | AddMealSheet | Свайп вниз | Закрывается с инерцией |
| 8 | AddMealSheet | Кнопка X | Закрывается |
| 9 | RecognitionResultSheetV2 | Тап на затемнение | Закрывается, результат `false` |
| 10 | RecognitionResultSheetV2 | Свайп вниз | Закрывается |
| 11 | RecognitionResultSheetV2 | Кнопка X | Закрывается, результат `false` |
| 12 | NutrientDetailSheet (long press на ингредиент) | Тап на затемнение | Закрывается |
| 13 | _MealDetailSheet (тап на блюдо в Journal) | Свайп вниз | Закрывается |
| 14 | _GroupDetailSheet (тап «Детали» в MealGroupCard) | Кнопка X | Закрывается |
| 15 | _V2IngredientSearchSheet | Все три способа | Закрывается |

**7.3 — AI-чат:**

| # | Шаг | Ожидаемый результат |
|---|-----|---------------------|
| 16 | Перейти на `/chat` → нажать кнопку «Назад» в шапке | Переход на `/` (Dashboard) |
| 17 | Перейти на `/chat` → нажать вкладку «Сегодня» в BottomNav | Переход на `/` |

---

## 8. Acceptance Criteria (из ТЗ продукта §7.1–7.3)

### 7.1 Клавиатура

- [ ] Тап вне поля ввода → клавиатура исчезает. Покрыто: `KeyboardDismisser` на всех экранах с `TextField`; тест `keyboard_dismisser_test.dart`.
- [ ] Свайп по списку сообщений → клавиатура убирается интерактивно. Покрыто: `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` в `ChatScreen`; тест `chat_screen_back_test.dart`.
- [ ] Toolbar с «Готово» над клавиатурой. Покрыто: `TextInputAction.done` + `onSubmitted: unfocus` для однострочных полей. Полноценный iOS inputAccessoryView — в open questions.

### 7.2 Bottom Sheets

- [ ] Все три способа закрытия для каждой шторки: тап вне, свайп вниз, кнопка X. Покрыто: `isDismissible: true`, `enableDrag: true`, `DismissibleSheetWrapper(showCloseButton: true)` на всех 8 местах; тесты `dismissible_sheet_wrapper_test.dart`.
- [ ] Закрытие свайпом — интерактивное (с инерцией). Покрыто: `enableDrag: true` передаётся Flutter, который реализует инерцию нативно.

### 7.3 AI-чат

- [ ] Из чата можно выйти минимум двумя способами. Покрыто: back-кнопка в `_ChatHeader` + тап по другому tab в `ScaffoldWithBottomNav`; тест `chat_screen_back_test.dart`.

---

## 9. Open Questions

1. **Back-кнопка чата: куда навигировать?** Текущее допущение — `context.go('/')`. Если пользователь пришёл из Journal, логичнее вернуться на `/journal`. Нужно ли хранить `previousLocation` в `StateProvider`? Требует уточнения у продукта перед имплементацией.

2. **iOS toolbar «Готово»**: ТЗ продукта требует явную кнопку «Готово» над клавиатурой. Текущий `pubspec.yaml` не содержит `flutter_keyboard_actions`. Добавить зависимость или реализовать кастомный overlay? Решение влияет на объём работ (+0.5 ч если плагин, +1.5 ч если кастомный).

3. **DismissibleSheetWrapper в AddMealSheet**: `AddMealSheet` уже имеет кастомную анимацию входа (`FadeTransition + SlideTransition`) и кастомный `Container` с `BorderRadius.vertical(top: Radius.circular(28))`. Оборачивать в `DismissibleSheetWrapper` или дописать drag handle + кнопку X прямо внутри `AddMealSheet`, не нарушая анимацию? Рекомендация: добавить кнопку X внутри существующего `Stack` в `AddMealSheet` без `DismissibleSheetWrapper` — сохранит анимацию.
