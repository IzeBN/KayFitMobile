# Changelog — KayFit 1.0.2+1

> Previous release: 1.0.0+10 (App Store build)

## Bug Fixes

### UI / Localisation
- **Macro labels in meal tile** (`kf2_item_tile.dart`): hardcoded `'PROTEIN'`, `'FAT'`, `'CARBS'`, `'Done'` replaced with `AppLocalizations` keys — now display in Russian when the app language is Russian.
- **AI-consent decline snackbar** (`chat_v2_screen.dart`): was always showing English text regardless of locale; now locale-aware (RU/EN).
- **Document screen** (`document_screen.dart`): Privacy Policy (RU) and Terms of Service (RU) were incorrectly rendering the English version — replaced with full Russian translations.
- **"Carb Counter" → "Kayfit"** across all in-app documents and Bluetooth usage description strings.

### Third-party brand removal
- **FatSecret** brand removed from UI per App Store Guideline 5.2.1:
  - `nutrient_detail_sheet.dart`: source badge `'FatSecret'` → `'Nutrition DB'`
  - `kf2_item_tile.dart`: `_labelFor` returned `'FATSECRET'` → `'DB'`
  - App Store screenshots (RU + EN HTML): `'проверяю FatSecret'` / `'cross-checking FatSecret'` → neutral phrasing

## iOS / Privacy

- **`PrivacyInfo.xcprivacy` added** — declares `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1) and `NSPrivacyAccessedAPICategoryFileTimestamp` (C617.1); no tracking, no collected data types.
- **`InfoPlist.strings` localised** — `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription` moved out of `Info.plist` into `en.lproj/InfoPlist.strings` and `ru.lproj/InfoPlist.strings`.
- **`https` removed** from `LSApplicationQueriesSchemes` — `https` is not a valid custom scheme and caused App Store warnings; only `tg` remains.
- **`NSSpeechRecognitionUsageDescription`** removed from `Info.plist` — Speech Recognition API is not used.
- **`AppIcon76x76@2x~ipad.png` deleted** — app targets iPhone only (`UIDeviceFamily=[1]`); iPad icon entry removed from `Contents.json` and physical file deleted.

## Dependencies

- **`app_links: ^6.1.0` removed** from `pubspec.yaml` — dependency was pulling in an iOS-16-tainted symbol and required a broken AASA endpoint; deep-link handling is not used in this release.

---

## What's New (App Store Connect — English)

```
Kayfit 2.0

Redesigned from scratch:
• New journal — calendar strip, macro rings, meal rows, swipe to delete
• New chat UI — thinking-step bubbles, attach toolbar (camera / voice / barcode), add meal directly from chat
• New food recognition flow — full-screen capture → results sheet in the new design
• New settings screen in the KF2 style

Improvements:
• Voice input wired into the new chat
• Macro goal changes now immediately update the dashboard rings
• Stats refresh correctly after saving weight or macro goals
• Onboarding progress is saved — you can resume after closing the app

Language & localisation:
• Russian language fully supported — switch in Settings
• App opens in English by default regardless of system language
• All macro labels, consent messages, and errors now respect the selected language
• Privacy Policy and Terms of Service available in Russian

Privacy & security:
• Auth tokens moved to iOS Keychain (Secure Enclave)
• AI feature consent gate — can be reviewed or changed in Settings at any time
• Privacy manifest (PrivacyInfo.xcprivacy) added per Apple requirements
```

## What's New (App Store Connect — Russian)

```
Kayfit 2.0

Полный редизайн:
• Новый дневник — лента календаря, кольца макронутриентов, карточки приёмов пищи, удаление свайпом
• Новый чат — пузыри с шагами обработки, панель вложений (камера / голос / штрихкод), добавление еды прямо из чата
• Новый экран распознавания еды — полноэкранная камера → карточка результата в новом стиле
• Новый экран настроек в дизайне KF2

Улучшения:
• Голосовой ввод подключён к новому чату
• Изменения цели по макронутриентам мгновенно отображаются в кольцах на дашборде
• Статистика корректно обновляется после сохранения веса или нормы КБЖУ
• Прогресс онбординга сохраняется — можно вернуться после закрытия приложения

Язык и локализация:
• Полная поддержка русского языка — переключение в Настройках
• Приложение открывается на английском по умолчанию, независимо от языка системы
• Названия макронутриентов, сообщения о согласии и ошибки учитывают выбранный язык
• Политика конфиденциальности и Условия использования доступны на русском языке

Конфиденциальность и безопасность:
• Токены авторизации перенесены в iOS Keychain
• Запрос согласия перед использованием ИИ-функций — можно изменить в Настройках
• Добавлен манифест конфиденциальности (PrivacyInfo.xcprivacy) по требованию Apple
```
