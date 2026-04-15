# Клиентские изменения с Build 4 → Build 6

Три изменения в коде Flutter-клиента. Все фронтенд, сервер не трогаем.

---

## 1. Fix: битая ссылка на WHO (404)

Старая ссылка `https://www.who.int/publications/i/item/9241547073` возвращает **404** (проверено curl'ом). Заменили на стабильную WHO fact sheet по здоровому питанию. Апл-ревьюер тапает ссылки — дохлый линк = реджект по 1.4.1.

**Файл: `lib/features/way_to_goal/widgets/plan_result_view.dart` (~line 338)**

```diff
   static const _pubmedUrl = 'https://pubmed.ncbi.nlm.nih.gov/2305711/';
-  static const _whoUrl = 'https://www.who.int/publications/i/item/9241547073';
+  static const _whoUrl = 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet';
```

**Файл: `lib/features/chat/screens/chat_screen.dart` (~line 930)**

```diff
   static const _whoUrl =
-      'https://www.who.int/publications/i/item/9241547073';
+      'https://www.who.int/news-room/fact-sheets/detail/healthy-diet';
```

PubMed-ссылку `https://pubmed.ncbi.nlm.nih.gov/2305711/` оставили как есть — это корректный URL на абстракт статьи Mifflin-St Jeor 1990, проверили.

---

## 2. Fix: USDA-ссылка на более стабильный хост

Ссылка на `https://www.dietaryguidelines.gov/` технически работает, но у сайта агрессивный бот-блок (WebFetch и curl с дата-центров получают 000/timeout). Если Apple использует автоматизированный краулер в процессе review (они пилотят AI-assisted review), наша ссылка может ложно считаться битой.

Заменили на канонический URL ODPHP/HHS — это тот же самый документ «Dietary Guidelines for Americans», публикуемый совместно USDA и HHS, просто хостится на более стабильном домене. Лейбл кнопки в UI оставили «USDA Dietary Guidelines» — пользователи узнают бренд.

**Файл: `lib/features/chat/screens/chat_screen.dart` (~line 932)**

```diff
   static const _usdaUrl =
-      'https://www.dietaryguidelines.gov/';
+      'https://odphp.health.gov/our-work/nutrition-physical-activity/dietary-guidelines';
```

---

## 3. Fix: микрофон не работал вообще (критично)

**Симптом:** пользователь нажимает голосовой ввод, app моментально показывает snackbar «Microphone access denied» без показа системного диалога iOS. Ссылка «Settings» открывает iOS Settings, но Kayfit **отсутствует в списке Privacy → Microphone вообще**.

**Корневая причина:** пакет `permission_handler` ^11.3.0 требует, чтобы в `ios/Podfile` были прописаны препроцессорные макросы — это задокументировано на [pub.dev/permission_handler](https://pub.dev/packages/permission_handler) в секции iOS. Без этих макросов `permission_handler_apple` собирается с заглушенными реализациями — `Permission.microphone.request()` моментально возвращает `denied + permanentlyDenied` без вызова iOS API. Поэтому iOS никогда не показывает диалог и app не появляется в Settings.

Баг **латентный с Build 1** — проявляется только если ревьюер попробует голосовой ввод. Apple в предыдущих раундах до этого не добирался, потому что реджектил по другим причинам (SIWA, цитаты). Но голосовой ввод открыто рекламируется в App Store description («Voice Logging — Say what you ate and it's logged instantly»), так что рано или поздно отреджектят.

### Что нужно изменить

**Файл: `ios/Podfile`** — расширить блок `post_install`:

```diff
 post_install do |installer|
   installer.pods_project.targets.each do |target|
     flutter_additional_ios_build_settings(target)
+    target.build_configurations.each do |config|
+      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
+        '$(inherited)',
+        'PERMISSION_MICROPHONE=1',
+        'PERMISSION_CAMERA=1',
+        'PERMISSION_PHOTOS=1',
+        'PERMISSION_SPEECH_RECOGNIZER=1',
+        'PERMISSION_NOTIFICATIONS=1',
+      ]
+    end
   end
 end
```

### Как применить и проверить

```bash
cd mobileKayfit_v6
rm -rf ios/Pods ios/Podfile.lock
flutter clean
flutter pub get
cd ios && pod install
cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions-AdHoc.plist
# установить на устройство через ios-deploy или Xcode
```

После установки:
1. Удалить старую версию Kayfit с устройства **до** установки (чтобы сбросить возможный кеш permissions)
2. Запустить новый билд → логин → Add Meal → голосовой ввод
3. **Ожидаемое:** системный диалог iOS «*Kayfit* Would Like to Access the Microphone»
4. Разрешить → записать фразу → транскрайбинг через `/api/transcribe` отрабатывает
5. В iOS Settings → Privacy & Security → Microphone → Kayfit должен появиться с тумблером

Мы у себя прогнали — работает. Проверено на iPhone 7 (iOS 15.8.7).

---

## 4. Bump версии

**Файл: `pubspec.yaml`**

```diff
-version: 1.0.0+4
+version: 1.0.0+6
```

Build 5 мы уже собрали и загрузили в ASC (там только фиксы ссылок из пунктов 1-2). Build 6 добавляет фикс микрофона из пункта 3. В ASC будем отправлять Build 6 (с вашими серверными фиксами когда будут готовы).

---

## Сводка по файлам

| Файл | Что меняется |
|------|--------------|
| `lib/features/way_to_goal/widgets/plan_result_view.dart` | 1 строка — WHO URL |
| `lib/features/chat/screens/chat_screen.dart` | 2 строки — WHO URL + USDA URL |
| `ios/Podfile` | расширить post_install блок — добавить GCC_PREPROCESSOR_DEFINITIONS |
| `pubspec.yaml` | версия 1.0.0+4 → 1.0.0+6 |

Плюс после изменения Podfile — переустановить Pods (`rm -rf ios/Pods ios/Podfile.lock && pod install`).

Полный исходник Build 6 у вас есть в архиве `mobileKayfit_v6_build6.zip`, можете сравнить построчно.
