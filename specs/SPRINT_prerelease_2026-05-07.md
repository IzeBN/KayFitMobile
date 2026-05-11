# Sprint: Pre-App Store Release — 2026-05-07

> Цель: устранить блокеры и подготовить сборку для загрузки в App Store.

## Выполненные изменения

### 1. Онбординг — переход на синюю палитру
**Файл**: `lib/shared/theme/app_theme.dart`  
**Что**: `OBColors` переделан под AppColors (акцент `#007AFF`, фон белый). Все экраны онбординга подхватили изменения автоматически — файлы не трогались.
```dart
OBColors.pink      = Color(0xFF007AFF)   // было: pink #FF597D
OBColors.orange    = Color(0xFF0062CC)   // было: orange #FE7650
OBColors.bg        = Color(0xFFFFFFFF)   // было: beige #FFF5EE
OBColors.pinkSoft  = Color(0xFFDCEEFF)   // было: soft pink
OBColors.gradient  = LinearGradient(blue → darkBlue)
```
Также исправлен хардкодный розовый градиент в хедере `_LandingStep` онбординга → синий.

### 2. Шаг Weight — убрали ручной ввод целевого веса
**Файл**: `lib/features/onboarding/screens/onboarding_screen.dart`  
**Что**:  
- Удалён контроллер `_targetWeightCtrl` и вся UI для ввода целевого веса  
- `_WeightStep` показывает только текущий вес  
- `_handleBodyFormCompleted` получает расчётный `calcTargetWeight` из Body Form-шага и записывает в `_targetWeight` только если цель = `lose_weight`  
- Для целей `muscle_gain` / `maintain` — `_targetWeight = null`, график не строится

**Причина**: баг — пользователь вводил 90 кг (текущий) и 105 кг (целевой), но график показывал снижение до 75 кг (брал расчётное значение из body form вместо введённого).

### 3. Диалог "Skip this step?" — убрали жёлтое подчёркивание
**Файл**: `lib/features/onboarding/screens/onboarding_screen.dart`  
**Что**: добавлен `decoration: TextDecoration.none` в оба TextStyle внутри диалога (Material 3 наследовал `DefaultTextStyle` с underline).

### 4. Экран Login — синяя тема + кликабельные ToS
**Файл**: `lib/features/auth/screens/login_screen.dart`  
**Что**:  
- Фон `AppColors.surface` (был `OBColors.bg`)  
- Градиент хедера синий `#007AFF → #0062CC`  
- Заменён `Text(l10n.auth_terms)` на новый виджет `_TermsText` с `TapGestureRecognizer` → `Navigator.push(DocumentScreen(type: DocumentType.termsOfService))`

### 5. AI Consent — H-5: отклонение ≠ выход из аккаунта
**Файл**: `lib/router.dart` + `lib/features/ai_consent/screens/ai_consent_screen.dart`  
**Что**:  
- Router gate: `aiConsent != true` → `aiConsent == null` (пользователь с `false` проходит через гейт)  
- `_onDecline`: убрана ветка `logout()`, вместо — `setConsent(false)` + `context.go('/')`  
- Текст кнопки: «Decline & sign out» → «Decline»  
- Описание: убрано «AI features will be unavailable»  
**Причина**: App Store compliance H-5 — пользователь должен иметь возможность использовать приложение (ручной ввод) без принятия AI consent.

### 6. iOS Deployment Target → 16.0
**Файл**: `ios/Runner.xcodeproj/project.pbxproj`  
**Что**: все 3 вхождения `IPHONEOS_DEPLOYMENT_TARGET = 13.0` → `16.0`  
**Причина**: MLKit требует iOS ≥ 15.5; Podfile уже имел `platform :ios, '16.0'`; несоответствие вызывало linker warnings и ошибки при деплое на физическое устройство.

### 7. CocoaPods frameworks.sh — исправлен unbound variable
**Файл**: `ios/Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks.sh`  
**Что**: добавлен `local source=""` перед if/elif-цепочкой в `install_framework()`. Убраны `local` у переназначений в elif-ветках.  
**Причина**: `set -u` (unbound variable protection) + отсутствие `else` в цепочке → `source: unbound variable` на строке 42 → `PhaseScriptExecution` фейлилась при деплое на устройство.

### 8. Recognition Result Screen — "REVIEW" → "KAYFIT"
**Файл**: `lib/features/add_meal/screens/recognition_result_sheet_kf2.dart` (строка ~557)  
```dart
Text('KAYFIT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, ...))
// было: 'REVIEW', fontSize: 11
```

### 9. App Store Build
**Артефакт**: `build/appstore_release/Kayfit_appstore.zip` (65 МБ)  
Содержит `Kayfit.xcarchive` + инструкцию `КАК_ЗАГРУЗИТЬ.txt`.  
Коллеги открывают xcarchive в Xcode Organizer → Distribute App → App Store Connect → подписывают своим Distribution-сертификатом.

---

## Статус

| # | Изменение | Статус |
|---|---|---|
| 1 | Онбординг синяя палитра | ✅ Done |
| 2 | Weight step без ручного целевого веса | ✅ Done |
| 3 | Skip диалог без желтого underline | ✅ Done |
| 4 | Login синяя тема + кликабельные ToS | ✅ Done |
| 5 | AI Consent H-5 | ✅ Done |
| 6 | iOS deployment target 16.0 | ✅ Done |
| 7 | Pods frameworks.sh unbound variable fix | ✅ Done |
| 8 | REVIEW → KAYFIT (2x размер) | ✅ Done |
| 9 | App Store сборка `.zip` | ✅ Done |
