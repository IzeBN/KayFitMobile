# Kayfit 2.0 — Radically Minimal Redesign · HLD

> Источник: handoff-bundle from Claude Design (`specs/kayfit_2.0/source_handoff/`).
> Финальный вариант: **V1 — Apple Activity rings**.
> Платформы: iOS + Android (Flutter, единая визуальная система).

## 1. Концепция

Kayfit 2.0 — полная переделка приложения по принципу **«одна задача — быстрый ввод приёма пищи»**. Отказ от Dashboard. Только два экрана: **Journal** и **Chat**. Account-кнопка сверху-справа. Центральная «+»-кнопка открывает Chat (чат — это и есть универсальный input для photo/voice/barcode/text).

**Эстетика:** радикальный минимализм. Монохром (`#FAFAFA` light / `#0A0A0A` dark). Один акцент — Apple system blue `#007AFF`. Apple Activity colors на 4 кольцах (Move/Exercise/Stand/Workout). Никаких эмодзи в UI, никаких градиентов кроме Apple-rings и кнопки «+».

## 2. Дизайн-токены

### 2.1 Цвета

| Token | Light | Dark |
|---|---|---|
| `bg` | `#FAFAFA` | `#0A0A0A` |
| `surface` | `#FFFFFF` | `#0A0A0A` |
| `card` | `#FFFFFF` | `#141414` |
| `fg` | `#0A0A0A` | `#FAFAFA` |
| `fgDim` | `#737373` | `#888888` |
| `fgMute` | `#A3A3A3` | `#555555` |
| `border` | `#E5E5E5` | `#1F1F1F` |
| `borderStrong` | `#D4D4D4` | `#2A2A2A` |
| `hairline` | `#EFEFEF` | `#1A1A1A` |
| `accent` | `#007AFF` | `#007AFF` |

**Apple Activity ring colors:**
| Ring | From | To | Track (light) | Track (dark) |
|---|---|---|---|---|
| Move (kcal) | `#FF2D55` | `#FF375F` | `rgba(255,55,95,0.12)` | `rgba(255,55,95,0.18)` |
| Exercise (protein) | `#A6FF00` | `#76E60E` | `rgba(118,230,14,0.14)` | `rgba(166,255,0,0.18)` |
| Stand (carbs) | `#1ECEDA` | `#3FE9FF` | `rgba(30,206,218,0.14)` | `rgba(30,206,218,0.18)` |
| Workout (fat) | `#FF9500` | `#FFCC00` | `rgba(255,149,0,0.14)` | `rgba(255,149,0,0.18)` |

**Calendar status colors:**
| Status | Ring | Track |
|---|---|---|
| Good (within goal) | `#34C759` | `rgba(52,199,89,0.18)` |
| Over (over goal) | `#FF3B30` | `rgba(255,59,48,0.18)` |

### 2.2 Типографика

- **Sans (UI body):** `Geist` (fallback: SF Pro / System)
- **Mono (numbers):** `JetBrains Mono` (fallback: SF Mono / monospace)
- **Иерархия:**
  - Hero kcal (numeric variant): 56–88px mono, weight 500, letter-spacing -2 to -3.5
  - H1: 22-26px sans, weight 600
  - Body: 14-15px sans, weight 400-500
  - Caption: 11-13px mono или sans
  - Label: 10-11px sans, uppercase, letter-spacing 0.6-1.0

### 2.3 Sizing / spacing

- Phone frame: 390×760 (design canvas reference)
- Status bar: 54px (iOS)
- Tab bar: 64px min-height
- "+" button: 44×44, gradient `#5AC8FA → #007AFF`, shadow `0 4px 14px rgba(0,122,255,0.42)`
- Apple rings: 140×140, radii `[60, 48, 36, 24]`, strokeWidth 10
- Calendar week ring: 36×36, strokeWidth 2.5
- Calendar month grid ring: viewBox 0 0 100 100, strokeWidth 6, dasharray 289 289 (full closed ring)
- Border radius: 4-16, hairline 0.5-1px

## 3. Карта экранов

### 3.1 Journal (главный экран)

```
┌──────────────────────────────────┐
│ [account]                  [≡]  │ ← TopBar 56px
├──────────────────────────────────┤
│ M  T  W  T  F  S  S       [v]  │ ← CalendarStrip
│ 28 29 30  1  2  3  4            │   week strip
│             ●                   │   today highlight
├──────────────────────────────────┤
│ ┌──────────┐  KCAL    1450/2100 │
│ │ 4 RINGS  │  PROT    65/130    │ ← SummaryAppleRings
│ │   ◯      │  CARBS   180/250   │   140x140 + labels
│ └──────────┘  FAT     30/70     │
├──────────────────────────────────┤
│ BREAKFAST  · 08:24                │
│ [photo]   oatmeal with berries   │
│           P 12 · F 6 · C 54   320│
│                              kcal│
├──────────────────────────────────┤
│ LUNCH    · 13:10                  │
│ ...                               │
├──────────────────────────────────┤
│  Journal      [+]      Chat      │ ← TabBar
└──────────────────────────────────┘
```

### 3.2 Chat

- Сверху: TopBar с account
- Список сообщений (user / ai bubbles)
- AI-thinking-bubble: «parsing portions… → matching USDA → cross-checking FatSecret → compiling»
- Inline-input снизу: text field + кнопки (camera / mic / barcode / send)
- TabBar внизу

### 3.3 Add-meal flow (вызывается «+» из TabBar — открывает Chat с предзаполненным attachment-picker)

1. Tap «+» → переход на Chat tab
2. На Chat внизу — input bar с paperclip/camera/mic/barcode
3. Tap camera → RecognitionScreen в режиме `photo` → capture → recognizing → preview & edit → save → возврат на Journal

### 3.4 Recognition / Preview & Edit

- Header: ✕ + label (`photo` / `voice` / `barcode` / `review`)
- Capture state: 240×240 dashed border placeholder, capture-circle 64×64
- Recognizing state: solid border, label «analyzing… AI is identifying items»
- Preview state:
  - TOTAL hero (mono 56px, kcal + macros)
  - Item rows: name + kcal, weight input, P/F/C inline, **+** add / **×** delete / **✏** edit P/F/C
  - «tell AI to correct» — natural-language коррекция
  - Save to journal — primary CTA

## 4. Архитектура Flutter

### 4.1 Что РАЗВЕРНУТЬ (новые файлы)

| Файл | Назначение |
|---|---|
| `lib/shared/theme/kayfit2_theme.dart` | Дизайн-токены (light/dark), Apple ring colors, calendar status colors |
| `lib/shared/widgets/kayfit_rings.dart` | `KayfitRings` widget — 4-ring Apple Activity SVG-аналог через `CustomPainter` |
| `lib/shared/widgets/calendar_strip.dart` | Week strip + expandable month с Apple-style status rings |
| `lib/shared/widgets/meal_photo_placeholder.dart` | Striped greyscale tile 56×56 (если фото есть) |
| `lib/shared/widgets/kayfit2_tab_bar.dart` | Tab bar в Apple-стиле с центральной «+»-кнопкой |
| `lib/features/journal/screens/journal_v2_screen.dart` | Новый Journal экран (сменит текущий) |
| `lib/features/chat/screens/chat_v2_screen.dart` | Новый Chat экран с inline input + thinking-bubble |
| `lib/features/add_meal/screens/recognition_v2_screen.dart` | Capture / recognizing / preview & edit |
| `lib/features/add_meal/widgets/preview_item_card.dart` | Item с +/×/✏ + AI-correct |

### 4.2 Что УБРАТЬ

| Что | Почему |
|---|---|
| `dashboard_screen.dart` (отдельная вкладка) | Сводка переехала на Journal |
| `bottom_nav.dart` (старый) | Замена `kayfit2_tab_bar.dart` |
| `add_meal_sheet.dart` (modal grid) | «+» теперь открывает Chat |

### 4.3 Что АДАПТИРОВАТЬ

| Что | Изменение |
|---|---|
| Routing (`router.dart`) | Только 2 stack: `/journal`, `/chat`. `/` редиректит на `/journal` |
| `addmeal` flow | Точка входа — Chat. Внутри Chat — inline-кнопки фото/голос/баркод |
| Onboarding result-screen | Сохраняется (но визуально переезжает на palette 2.0) |

## 5. Декомпозиция в тикеты

| Ticket | Title | Платформа | Estimate |
|---|---|---|---|
| `KF2-FOUND-1` | Дизайн-токены + KayfitRings widget | Flutter | 1 день |
| `KF2-FOUND-2` | Calendar strip + month-grid widget | Flutter | 0.5 дня |
| `KF2-FOUND-3` | Tab bar Apple-стиль | Flutter | 0.5 дня |
| `KF2-FOUND-4` | Meal photo placeholder + meal row | Flutter | 0.5 дня |
| `KF2-JOURNAL` | JournalV2Screen — собрать из foundation | Flutter | 1 день |
| `KF2-CHAT` | ChatV2Screen + thinking bubble + inline input | Flutter | 1.5 дня |
| `KF2-RECOG` | Recognition capture/recognizing/preview | Flutter | 2 дня |
| `KF2-PREVIEW-EDIT` | Preview & edit с +/×/✏ + AI-correct | Flutter + бэкенд endpoint | 2 дня |
| `KF2-CHAT-AI-PIPELINE` | Real progress events (parsing → DB → compile) | Frontend + backend | 2 дня |
| `KF2-ROUTE` | Roadmap routing (drop dashboard) | Flutter | 0.5 дня |
| `KF2-FONTS` | Подключить Geist + JetBrains Mono в pubspec assets | Flutter | 0.5 дня |
| `KF2-MIGRATE` | Cleanup старых экранов | Flutter | 1 день |

**Итого:** ~13 человеко-дней, 2 спринта.

## 6. Риски

| # | Риск | Mitigation |
|---|---|---|
| 1 | Flutter не имеет нативного SVG `linearGradient` на arc — нужен `CustomPainter` с `Shader.linear` | Использовать `Path` + `Canvas.drawArc` + `SweepGradient`/`LinearGradient` shader |
| 2 | Производительность 4 анимированных колец на каждом frame Journal | `CustomPainter` с `shouldRepaint = false` после первого render; анимировать только при invalidate |
| 3 | Дизайнер указывает Geist — у Apple нет такого fallback | Подключить через `pubspec.yaml assets`, fallback `system-ui` |
| 4 | Backend Chat-pipeline (parsing → USDA → FatSecret → compile) — сейчас один-shot | Расширить `/api/v2/parse_meal_suggestions` со streaming/server-sent-events ИЛИ просто симулировать прогресс на фронте по таймингам |
| 5 | Удаление Dashboard может сломать существующих юзеров | Phased rollout: feature flag `kayfit2_enabled`, на первом этапе — отдельный билд для test cohort |
| 6 | Фото в карточке журнала — сейчас бэк хранит только текст | Backend: добавить `meal.photo_url` (S3 / object storage), отдельный спринт |

## 7. Что вне scope этого редизайна

- Goal-setting flow (way_to_goal) — оставить как есть
- Onboarding (16 шагов) — оставить как есть, отдельный sprint NEW-OB по FitnesBot
- Subscription / tariffs screen — оставить как есть
- Settings — оставить как есть, только сменить иконки на Geist sans

## 8. Полезные файлы handoff

| Что | Где |
|---|---|
| Главный HTML-прототип | `specs/kayfit_2.0/source_handoff/project/Kayfit 2.0.html` |
| Главный JSX компонент | `specs/kayfit_2.0/source_handoff/project/kayfit-app.jsx` |
| Screens (Journal/Chat/MealDetailSheet) | `specs/kayfit_2.0/source_handoff/project/kayfit-screens.jsx` |
| Полный chat от дизайнера (все итерации) | `specs/kayfit_2.0/source_handoff/chats/chat1.md` |
