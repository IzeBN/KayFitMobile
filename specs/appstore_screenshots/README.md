# Kayfit · App Store screenshots

Six 1290 × 2796 PNG screenshots for App Store Connect, in the same blue-card-with-phone-mockup style as the reference set the user shared.

## Files

| File | Frame |
|---|---|
| `screenshots.html` | All 6 frames in one HTML (open in Chrome to preview) |
| `export.js` | Puppeteer script — exports each frame as PNG at exact 1290×2796 |
| `appstore_main.png` | 1 · Главная — визитная карточка |
| `appstore_chat.png` | 2 · Чат с ИИ-нутрициологом |
| `appstore_voice.png` | 3 · Голосовой ввод |
| `appstore_photo.png` | 4 · Фото блюда |
| `appstore_barcode.png` | 5 · Штрихкод |
| `appstore_plan.png` | 6 · Персональный план |

## Slogans (subtitle лозунги)

| Frame | Hero | Subtitle |
|---|---|---|
| main | Дневник питания | Ежедневный трекинг калорий со встроенным ИИ |
| chat | Чат с ИИ-нутрициологом | Спроси что съесть и логируй блюда прямо в диалоге |
| voice | Скажи — и готово | Опиши что съел голосом, ИИ распознает за 2 секунды |
| photo | Просто сфотографируй | ИИ узнает каждый ингредиент на тарелке |
| barcode | Сканируй штрихкоды | Точные данные с упаковки за пару секунд |
| plan | Твой план, рассчитан ИИ | Персональная норма по возрасту, весу и цели |

## Превью (без экспорта)

```bash
cd specs/appstore_screenshots
open screenshots.html  # opens in default browser
```

В браузере увеличь масштаб 25-33% чтобы увидеть все 6 кадров.

## Экспорт в PNG

### Через Puppeteer (рекомендуется)

```bash
cd specs/appstore_screenshots
npm install puppeteer
node export.js
```

→ создаст `appstore_*.png` (по 1 на кадр) в этой же папке.

### Через Chrome DevTools (альтернатива)

1. Открой `screenshots.html` в Chrome
2. DevTools → Cmd+Shift+P → «Capture node screenshot»
3. Выбери `<div class="frame" id="frame-main">` → save
4. Повтори для каждого `frame-*` id

## Загрузка в App Store Connect

1. https://appstoreconnect.apple.com → My Apps → Kayfit → App Store
2. Версия → **App Previews and Screenshots**
3. Размер **iPhone 6.9" Display** (1290 × 2796) или **6.7"** (1284 × 2778)
4. Drag-n-drop PNG в нужном порядке (1 → 6)
5. Save

Apple допускает **до 10 скриншотов**. У нас 6 — есть запас на ещё 4 (например, calendar view, settings, weight chart).

## Дизайн-система

Цвета и компоненты согласованы с **Kayfit 2.0** (см. `specs/kayfit_2.0/HLD_kayfit_2.0_redesign.md`):

- Background: `#2563EB` (Apple-blue)
- Apple Activity ring colors: kcal red/pink, protein green, carbs cyan, fat orange
- Single accent: `#2563EB` (для check-circle, +-кнопки, и т.д.)
- Шрифт: Geist (sans) + JetBrains Mono (numeric)
- Phone bezel: `#131316`, дисплей с dynamic island

Внутри телефона — упрощённые версии экранов KF2 (Journal с rings, Chat thinking bubble, Voice text, Photo viewfinder, Barcode, Plan Ready hero). Не претендует на полное соответствие — цель именно маркетинговая визуализация.

## Что менять

В `screenshots.html` всё inline (HTML + CSS + SVG, без зависимостей). Найди соответствующий `<div class="frame" id="frame-*">` и правь напрямую:

- Заголовок: `<span class="t1">…</span>` + `<span class="t2">…</span>` + `<span class="sub">…</span>`
- Контент телефона: внутри `.phone .screen`
- Floating card: `<div class="result-card floating-*">`

После правок — снова `node export.js` для PNG.
