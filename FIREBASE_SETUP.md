# Firebase Setup for Kayfit

Push notifications (FCM) are implemented but require Firebase project configuration
files that contain project-specific credentials.  Follow the steps below to enable them.

---

## 1. Create a Firebase project

1. Go to https://console.firebase.google.com and create a project (or reuse an existing one).
2. Register both the Android and iOS apps:
   - **Android**: package name `ru.kayfit.kayfit`
   - **iOS**: bundle ID `ru.kayfit.kayfit` (verify in `ios/Runner.xcodeproj`)

---

## 2. Android — `google-services.json`

1. In Firebase Console → Project settings → Your apps → Android → Download `google-services.json`.
2. Place the file at:
   ```
   android/app/google-services.json
   ```
   The Gradle plugin `com.google.gms.google-services` (already added to
   `android/app/build.gradle.kts` and `android/settings.gradle.kts`) will
   pick it up automatically.

---

## 3. iOS — `GoogleService-Info.plist`

1. In Firebase Console → Project settings → Your apps → iOS → Download `GoogleService-Info.plist`.
2. Open the project in Xcode (`ios/Runner.xcworkspace`) and drag the file into
   the **Runner** target (make sure "Copy items if needed" is checked and
   the target membership is set to **Runner**).
3. Alternatively, place it at `ios/Runner/GoogleService-Info.plist` — Flutter
   will include it automatically.

---

## 4. iOS — APNs key or certificate

FCM on iOS requires APNs integration:

1. In Apple Developer Portal → Certificates, Identifiers & Profiles →
   Keys → create a new key with **Apple Push Notifications service (APNs)** enabled.
2. Download the `.p8` file and upload it in Firebase Console →
   Project settings → Cloud Messaging → Apple app configuration.

---

## 5. App Config — `lib/core/config/app_config.dart`

If you need the `GOOGLE_CLIENT_ID` (for Google Sign-In) you can also set the
`ServerClientId` from the Firebase / Google Cloud OAuth2 credentials.

---

## 6. Backend — `GOOGLE_CLIENT_ID` env var

The backend verifies Google ID tokens.  Set in `.env`:
```
GOOGLE_CLIENT_ID=<your Web Client ID from Google Cloud Console>
```

---

## Verification

After adding the config files run:
```
flutter run
```

Check logcat / Xcode console for:
```
[FCM] NotificationService initialised
[FCM] token registered with backend
```

If Firebase files are missing the app will log:
```
[FCM] init skipped (Firebase not configured): ...
```
and continue to run normally without push notifications.
