# ТЗ: Ось D — Онбординг — Тикет P0-3.1 «Пропадает кнопка Далее»

> Дата: 2026-05-02
> Тикет: P0-3.1
> Исполнитель: frontend-dev (вайбкодинг)
> Оценка: 3 ч фронт, 0 ч бэк
> Зависимости: нет внешних; может идти параллельно с Auth (ось A)

---

## 1. Аудит экранов онбординга

Файл реализации: `lib/features/onboarding/screens/onboarding_screen.dart`

Весь онбординг реализован в **одном файле** как единый `OnboardingScreen` (`ConsumerStatefulWidget`)
со switch-based рендером шагов. Отдельных файлов на экран нет — только внутренние приватные
виджеты `_*Step`.

### Полный список шагов

| # | `_Step` enum | Тип | TextField | Кнопка Далее сейчас | Skip есть |
|---|---|---|---|---|---|
| 1 | `landing` | обязательный | нет | внутри `_LandingStep`, в `SafeArea` | нет |
| 2 | `health` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет (но есть «Нет ограничений») |
| 3 | `diet` | обязательный | нет | НЕТ в `_buildFooter` (case пропущен) | нет |
| 4 | `food_restrictions` | **опциональный** | `TextField (maxLines:4)`, `autofocus: false` | в `_buildFooter`, `SafeArea` | есть |
| 5 | `goals` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 6 | `age` | обязательный | нет | НЕТ в `_buildFooter` (case пропущен) | нет |
| 7 | `height` | обязательный | `TextField`, `autofocus: true`, `keyboardType: number` | в `_buildFooter`, `SafeArea` | нет |
| 8 | `gender` | обязательный | нет | НЕТ в `_buildFooter` (case пропущен) | нет |
| 9 | `weight` | обязательный | 2x `TextField`, `autofocus: true/false`, `keyboardType: decimal` | в `_buildFooter`, `SafeArea` | нет |
| 10 | `training` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 11 | `weight_loss_info` | опциональный (только если цель lose_weight) | нет | в `_buildFooter`, `SafeArea` | нет |
| 12 | `info_1` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 13 | `info_2` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 14 | `info_3` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 15 | `method` | обязательный | `TextField (maxLines:2)` внутри `SingleChildScrollView` | в `_buildFooter`, `SafeArea` | нет |
| 16 | `result` | обязательный | нет | в `_buildFooter`, `SafeArea` | нет |
| 17 | `auth` | служебный | нет | нет (auto-navigate) | нет |

**Допущение**: реальных пользовательских шагов 16 (без `auth`). В архитектурной памяти
зафиксировано «6 реальных шагов» — это относится к более ранней версии ТЗ. Код содержит
минимум 16 `_Step` enum-значений; hotfix покрывает все экраны с TextField и все шаги
где кнопка в `_buildFooter` отсутствует.

---

## 2. Корневые причины (диагноз по коду)

Найдено три независимых проблемы:

### 2.1 Отсутствие кнопки на трёх шагах

В методе `_buildFooter` case-ветки `_Step.diet`, `_Step.age`, `_Step.gender` явно
возвращают `SizedBox.shrink()` (сгруппированы в `case _Step.landing: case _Step.age:
case _Step.gender: case _Step.diet: case _Step.auth: return const SizedBox.shrink()`).

У `diet` и `age` тапается вариант → `onChange` сразу вызывает `_goNext()`, то есть
навигация встроена в сами опции. Это скрытое поведение: пользователь, не понявший что
нужно тапнуть по карточке, не видит кнопки «Далее».

У `gender` аналогично — `onSelect` вызывает `_handleGenderSelect` → `_goNext`.

### 2.2 Кнопка уезжает за клавиатуру на шагах с TextField

`Scaffold` в `OnboardingScreen.build` **не задаёт** `resizeToAvoidBottomInset`.
По умолчанию Flutter выставляет `resizeToAvoidBottomInset: true`, но кнопка находится
вне `bottomNavigationBar` — она в `Column` тела. При этом layout:

```
Scaffold
  body: Stack
    Column
      _buildHeader       ← фиксированный
      Expanded           ← _buildStepContent (SingleChildScrollView внутри шагов)
      _buildFooter       ← кнопка ЗДЕСЬ, в Column.bottom
    _buildSkipDialog
```

Кнопка в `_buildFooter` — часть `Column` внутри `body`. Когда клавиатура поднимается,
`resizeToAvoidBottomInset: true` сжимает `body`, и `_buildFooter` вместе с кнопкой
физически поднимается — **но `Expanded` секция `_buildStepContent` уже занимает всё
оставшееся место**, из-за чего кнопка может оказаться за пределами видимой области
либо перекрыта клавиатурой на низких устройствах (iPhone SE).

Конкретно: на `_HeightStep` (`autofocus: true`) и `_WeightStep` (`autofocus: true`)
клавиатура открывается автоматически. На `_FoodRestrictionsStep` (`autofocus: false`)
кнопка «Далее» / «Пропустить» тоже входит в `Column.bottom` тела, и при фокусе
на `TextField` может частично перекрываться.

### 2.3 Шаг `method` — текстовый ввод при демо

`_MethodStep` рендерит `TextField` (`autofocus: true`) внутри `SingleChildScrollView`.
Кнопка «Далее» находится в `_buildFooter` и при открытии клавиатуры для демо-ввода
может уехать.

---

## 3. Единый паттерн для всех шагов с TextField

### 3.1 Структура `Scaffold`

```
Scaffold(
  resizeToAvoidBottomInset: true,   // явно задан (сейчас не задан — default true, но неявно)
  backgroundColor: OBColors.bg,
  body: SafeArea(
    bottom: false,
    child: Column(
      children: [
        _buildHeader(l10n),          // прогресс-бар + кнопка назад
        Expanded(
          child: _buildStepContent(l10n),
        ),
      ],
    ),
  ),
  bottomNavigationBar: _buildFooter(l10n),  // кнопка ВСЕГДА здесь
)
```

`bottomNavigationBar` в Flutter автоматически сдвигается выше клавиатуры при
`resizeToAvoidBottomInset: true`. Это решает проблему 2.2 и 2.3.

### 3.2 Контент шагов с TextField

Шаги `height`, `weight`, `food_restrictions`, `method` должны использовать:

```
SingleChildScrollView(
  reverse: false,
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
  child: Column(
    children: [
      ... контент ...
    ],
  ),
)
```

Контент прокручивается, кнопка фиксирована в `bottomNavigationBar`.

### 3.3 Состояния кнопки «Далее»

| Ситуация | Состояние кнопки |
|---|---|
| Обязательное поле пустое / не выбрано | `onTap: null` → disabled (серая) — видна |
| Обязательное поле заполнено | `onTap: callback` → enabled (градиент) |
| Опциональный шаг | enabled с первого момента + кнопка «Пропустить» ниже |
| Клавиатура открыта | кнопка остаётся в `bottomNavigationBar`, не перекрыта |

### 3.4 Шаги-тапы (diet, age, gender)

Сохранить текущее поведение «тап по опции = переход», но **добавить** видимую
кнопку «Далее» в `_buildFooter` для каждого из этих шагов:

- `diet`: кнопка enabled если `_dietType != ''` (пустая строка — дефолт `'none'`, поэтому
  кнопка enabled сразу). Поведение тапа по опции остаётся без изменений.
- `age`: кнопка enabled если `_age != null`.
- `gender`: кнопка enabled если `_gender != ''`.

Это устраняет скрытое поведение и даёт пользователю явный CTA.

---

## 4. Новый виджет `OnboardingScaffold`

**Файл**: `lib/features/onboarding/widgets/onboarding_scaffold.dart`

Цель: инкапсулировать layout с `bottomNavigationBar` для переиспользования.

### Сигнатура

```dart
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.header,
    required this.body,
    required this.primaryCta,
    this.secondaryCta,
    this.backgroundColor,
  });

  final Widget header;
  final Widget body;
  final Widget primaryCta;
  final Widget? secondaryCta;
  final Color? backgroundColor;
}
```

Параметр `primaryCta` — `_GradientButton` (существующий приватный виджет; при рефакторинге
переместить его в `lib/features/onboarding/widgets/ob_gradient_button.dart` и сделать
package-private или перенести в `lib/shared/widgets/`).

Параметр `secondaryCta` — `TextButton('Пропустить')` для опциональных шагов.

`bottomNavigationBar` виджета строится как:

```dart
SafeArea(
  top: false,
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        primaryCta,
        if (secondaryCta != null) ...[
          const SizedBox(height: 8),
          secondaryCta!,
        ],
      ],
    ),
  ),
)
```

---

## 5. Файлы для создания и правки

| Действие | Путь | Что делать |
|---|---|---|
| Создать | `lib/features/onboarding/widgets/onboarding_scaffold.dart` | Новый layout-виджет (§4) |
| Создать | `lib/features/onboarding/widgets/ob_gradient_button.dart` | Вынести `_GradientButton` из `onboarding_screen.dart` |
| Изменить | `lib/features/onboarding/screens/onboarding_screen.dart` | Применить `OnboardingScaffold`; добавить кнопки для `diet`/`age`/`gender`; перенести `_buildFooter` в `bottomNavigationBar` |
| Создать | `test/features/onboarding/onboarding_scaffold_test.dart` | Widget-тесты (§6) |

Других файлов в `lib/features/onboarding/screens/` нет — весь онбординг в одном файле.

---

## 6. Сценарии использования (UC)

### UC1: Обязательный шаг, поле не заполнено

- Пользователь открывает шаг Height.
- Поле пустое → кнопка «Далее» видна, цвет серый, `onTap == null`.
- Тап по кнопке не реагирует.
- Пользователь не может продвинуться без ввода.

### UC2: Обязательный шаг, поле заполнено

- Пользователь вводит `175` в поле Height.
- Кнопка «Далее» переходит в enabled-состояние (градиент).
- Тап → `_handleHeightNext` → валидация → `_goNext`.

### UC3: Клавиатура открыта — кнопка не перекрыта

- Пользователь тапает по TextField на шаге Height или Weight.
- iOS-клавиатура поднимается.
- `bottomNavigationBar` автоматически поднимается вместе с кнопкой благодаря
  `resizeToAvoidBottomInset: true`.
- Кнопка «Далее» видна над клавиатурой.
- Пользователь нажимает «Далее» без необходимости закрывать клавиатуру вручную.

### UC4: Опциональный шаг (food_restrictions)

- Поле ввода пустое → кнопка «Далее» enabled (шаг опциональный).
- Дополнительно видна кнопка «Пропустить».
- Тап «Пропустить» → `_foodRestrictions = ''` + `_goNext`.
- Тап «Далее» → `_goNext` с текущим значением поля.

### UC5: Повторный запуск — восстановление состояния

- Пользователь заполнил шаги 1–5, закрыл приложение.
- При повторном открытии данные восстанавливаются из `OnboardingPendingStorage`.
- `_stepIndex` восстанавливается до последнего завершённого шага.
- Кнопка «Далее» на восстановленном шаге в enabled-состоянии (поля заполнены).

_Допущение_: восстановление `_stepIndex` при старте — часть тикета P0-1.1/1.2 (ось A),
не этого тикета. Тикет 3.1 обеспечивает только корректное отображение кнопки при любом
`_stepIndex`. Ось D не зависит от оси A.

---

## 7. Тестовая стратегия

**Файл**: `test/features/onboarding/onboarding_scaffold_test.dart`

### Widget-тесты для `OnboardingScaffold`

```dart
// Проверка: primaryCta всегда в bottomNavigationBar
testWidgets('renders primaryCta in bottomNavigationBar', ...)

// Проверка: secondaryCta виден только если передан
testWidgets('does not render secondaryCta when null', ...)
testWidgets('renders secondaryCta below primaryCta when provided', ...)
```

### Widget-тесты для шагов с TextField (smoke + CTA visible)

Для каждого из шагов: `height`, `weight`, `food_restrictions`, `method`:

```dart
testWidgets('HeightStep: shows disabled Next button when field is empty', ...)
testWidgets('HeightStep: shows enabled Next button when valid height entered', ...)
testWidgets('WeightStep: shows disabled Next button when fields are empty', ...)
testWidgets('FoodRestrictionsStep: shows enabled Next button and Skip button', ...)
```

### Widget-тесты: кнопка не уезжает при симуляции клавиатуры

```dart
testWidgets('HeightStep: Next button remains visible after keyboard opens', (tester) async {
  // Arrange: pump OnboardingScreen до шага height
  // Act: фокус на TextField (tester.tap(find.byType(TextField).first))
  // Assert: find.text('Далее') или find.text('Next') findsOneWidget
  //         tester.getBottomLeft(find.text('Next')).dy < tester.binding.window.physicalSize.height
})
```

Симуляцию закрытия/открытия клавиатуры в widget-тестах делать через
`tester.showKeyboard(find.byType(TextField))`.

### Manual regression на iOS-симуляторе (iPhone SE, 375×667)

- [ ] Шаг Height: открыть клавиатуру → кнопка «Далее» видна выше клавиатуры.
- [ ] Шаг Weight: открыть клавиатуру → кнопка «Далее» видна.
- [ ] Шаг FoodRestrictions: тап в TextField → кнопки «Далее» и «Пропустить» видны.
- [ ] Шаг Method: тап в текстовое поле демо → кнопка «Далее» видна.
- [ ] Шаг Diet: отображается видимая кнопка «Далее».
- [ ] Шаг Age: отображается видимая кнопка «Далее».
- [ ] Шаг Gender: отображается видимая кнопка «Далее».
- [ ] Пройти все шаги полностью — кнопка присутствует на каждом.

---

## 8. Acceptance (из ТЗ продукта §3.1)

- [ ] На каждом экране онбординга есть видимая кнопка перехода вперёд («Далее» или аналог).
- [ ] Если поле опциональное — есть кнопка «Пропустить».
- [ ] Кнопка не уезжает за пределы экрана при появлении клавиатуры на любом шаге с TextField.
- [ ] Кнопка «Далее» отображается как disabled (серая), если обязательное поле пустое, но остаётся видимой.

---

## 9. Open questions

1. **Восстановление `_stepIndex`**: тикет 3.1 предполагает что `_stepIndex` при старте
   = 0. Если ось A (1.1) реализует восстановление с промежуточного шага через
   `SharedPreferences`, нужна координация: `_OnboardingScreenState.initState` должен
   читать сохранённый шаг до первого `build`. Риск: если ось A делает это иначе —
   кнопки могут быть в неправильном initial-состоянии. Согласовать с разработчиком оси A.

2. **`_Step.diet`, `_Step.age`, `_Step.gender`: добавить явную кнопку или оставить тап-навигацию?**
   ТЗ продукта не регламентирует этот UX-паттерн явно. Рекомендация: добавить кнопку
   (UC3 complaint с ТЗ §3.1 «на каждом экране есть видимая кнопка»), но тап по опции
   сохранить для скорости. Если продукт решит иначе — удалить кнопку из footer для этих
   шагов, это локальное изменение в `_buildFooter`.

---

## Покрытие компонентов из HLD

| HLD-компонент | Покрыт в ТЗ |
|---|---|
| Ось D — все 16 шагов онбординга | Аудит в §1, диагноз в §2 |
| Корневая причина `resizeToAvoidBottomInset` | §2.2 |
| Корневая причина «нет кнопки» у `diet/age/gender` | §2.1 |
| Единый паттерн `bottomNavigationBar` | §3 |
| Новый виджет `OnboardingScaffold` | §4, §5 |
| Use cases | §6 (UC1–UC5) |
| Widget-тесты | §7 |
| Manual regression | §7 |
| Acceptance criteria | §8 |
| Открытые вопросы | §9 |
