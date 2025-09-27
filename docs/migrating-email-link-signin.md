# Goodbye Firebase Dynamic Links: Migrating Email Link Sign‑In to Custom App/Universal Links (Flutter: Android, iOS, macOS)

## Overview
- Objective: Replace deprecated Firebase Dynamic Links with App Links (Android) and Universal Links (iOS/macOS) using a custom domain.
- Stack:
  - Flutter (Android/iOS/macOS)
  - Firebase Auth (Email link sign‑in)
  - Firebase Hosting on custom domain: `auth.spiritlightsoft.com`
- Result:
  - Android: reliable deep linking and in‑app completion.
  - iOS: sign‑in completes; sometimes Safari remains foregrounded.
  - macOS: app focuses on “Open in App”; link delivery can be inconsistent across OS versions.

## Why migrate off Dynamic Links?
- Firebase Dynamic Links (FDL) are no longer recommended for email link sign‑in.
- Apple requires App/Universal Links tied directly to your domain via site association (AASA), not via dynamic link intermediaries.
- Firebase now supports this via “Hosting domain” configuration and client-side `linkDomain`.

---

## Prerequisites
- Firebase project (e.g., `vasis-beats`)
- Firebase Hosting set up on your custom domain `auth.spiritlightsoft.com`
- App identifiers:
  - Android `applicationId`: `dev.suragch.flutter_audio_service_demo`
  - iOS `bundleId`: `dev.spiritsoft.flutterAudioServiceDemo`
  - macOS `bundleId`: `com.spiritsoft.FlutterAudio`
- Apple Developer Team ID (example: `L35TJZA3UC`)

---

## 1) Hosting: Configure AASA and Digital Asset Links

Files in your repo:
- `public/.well-known/apple-app-site-association`
- `public/.well-known/assetlinks.json`
- `firebase.json` (headers)

### AASA (Apple)
- Path: `public/.well-known/apple-app-site-association`
- Must be JSON (no extension change), served as `application/json`.
- `appID = TeamID.BundleID`.
- Include the paths your app needs (Firebase Auth action + your final redirect).

Example used:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "L35TJZA3UC.dev.spiritsoft.flutterAudioServiceDemo",
        "paths": [
          "NOT /_/*",
          "/__/auth/*",
          "/finishSignIn*",
          "/*"
        ]
      },
      {
        "appID": "L35TJZA3UC.com.spiritsoft.FlutterAudio",
        "paths": [
          "NOT /_/*",
          "/__/auth/*",
          "/finishSignIn*",
          "/*"
        ]
      }
    ]
  }
}
```

### Digital Asset Links (Android)
- Path: `public/.well-known/assetlinks.json`
- Must match your package name and the SHA‑256 of the certificate that signed the installed build.

**⚠️ CRITICAL: Google Play Store Apps**
- For apps distributed through Google Play Store, you **MUST** use the Google Play signing key SHA-256, not your upload key
- Google Play re-signs your app with their own signing key when publishing
- Find the correct SHA-256 in Google Play Console → Setup → App integrity → App signing → "App signing key certificate"
- **DO NOT** include both your upload key and Google Play signing key in the same `assetlinks.json` - this causes verification conflicts

Example:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "dev.suragch.flutter_audio_service_demo",
      "sha256_cert_fingerprints": [
        "DF:BB:E8:36:CC:0F:72:83:60:4D:9D:24:49:1A:7D:68:0A:9A:0E:D2:F0:EA:AD:70:C9:FA:63:35:B0:AC:5F:12"
      ]
    }
  }
]
```

### Hosting headers
- Path: `firebase.json`
- Ensure both AASA and `assetlinks.json` are served as `application/json`.

```json
"headers": [
  {
    "source": "/.well-known/apple-app-site-association",
    "headers": [{ "key": "Content-Type", "value": "application/json" }]
  },
  {
    "source": "/.well-known/assetlinks.json",
    "headers": [{ "key": "Content-Type", "value": "application/json" }]
  }
]
```

### Deploy and verify
- `firebase deploy --only hosting`
- `curl -I https://auth.spiritlightsoft.com/.well-known/apple-app-site-association`
- `curl -I https://auth.spiritlightsoft.com/.well-known/assetlinks.json`

---

## 2) Client code changes (Flutter)

### Generate email link
Where: `lib/screens/sign_in_screen.dart`

```dart
final actionCodeSettings = ActionCodeSettings(
  url: 'https://auth.spiritlightsoft.com/finishSignIn',
  linkDomain: 'auth.spiritlightsoft.com',
  handleCodeInApp: true,
  iOSBundleId: 'dev.spiritsoft.flutterAudioServiceDemo',
  androidPackageName: 'dev.suragch.flutter_audio_service_demo',
  androidInstallApp: false,
);
```

### Robust link handling early in lifecycle
Where: `lib/splash.dart`
- Listen for `getInitialLink()` and `uriLinkStream`.
- If the OS delivers a final redirect like `/finishSignIn?oobCode=...`, reconstruct a `.../__/auth/action?...` URL and pass it to Firebase Auth.
- Complete `signInWithEmailLink` using cached email (from `SharedPreferences`).

---

## 3) Platform specifics

### Android (deterministic)
- `android/app/src/main/AndroidManifest.xml` intent-filters should include:
  - `https://auth.spiritlightsoft.com/__/auth/`
  - `https://auth.spiritlightsoft.com/finishSignIn`
  - Optional legacy: `https://vasis-beats.web.app/__/auth/links`
- The installed APK must be release‑signed with the certificate whose SHA‑256 is in `assetlinks.json`.
- On Android 12+, allow up to a minute for App Links verification.

### iOS (works; sometimes Safari stays foregrounded)
- `ios/Runner/Runner.entitlements`:
  - Keep only `applinks:auth.spiritlightsoft.com` to avoid routing conflicts.
- Apple Developer → Identifiers → App ID must have “Associated Domains” enabled.
- Team ID must match AASA `appID` prefix.
- `ios/Runner/AppDelegate.swift`: forward Universal Link events to Flutter (call `super`).
- Reset if behavior is “stuck”:
  - Delete app → Settings → Safari → Advanced → Website Data → remove your domain → reboot → reinstall → test from Apple Mail.

### macOS (app focuses; link delivery can be inconsistent)
- `macos/Runner/Release.entitlements` and `macos/Runner/RunnerProfile.entitlements`:
  - Keep only `applinks:auth.spiritlightsoft.com`.
- AASA must include the macOS `appID`: `L35TJZA3UC.com.spiritsoft.FlutterAudio`.
- `macos/Runner/AppDelegate.swift`: forward `application(_:continue:)` to `super`.
- Optional: add `NSUserActivityTypes = ["NSUserActivityTypeBrowsingWeb"]` to `macos/Runner/Info.plist`.

---

## 5) Theory vs Practice 
- Android: Tapping link opens app directly; sign‑in completes immediately.
- iOS: App opens; sometimes Safari remains foregrounded. Switching back shows you’re signed in.
- macOS: “Open in App” focuses the app; link delivery may require retry with the app already open. The Splash handler reconstructs the action URL when necessary.

### Demo assets (placeholders)

Android flow (video):

![Android email link sign-in](https://drive.google.com/file/d/1UhT10xHMXxioGYEgbRDMAc5qfVqR06Vp/view?usp=sharing)


iOS flow (video):

![iOS link tap](https://drive.google.com/file/d/1XcgTUGOdFuT6cfTJ4Krx5rGcbn4ts6cY/view?usp=sharing)


macOS flow (video):

![macOS link tap] (https://drive.google.com/file/d/1uHhHOZFp4txuzHL5nVMmHVJpR9TC719Q/view?usp=sharing)

---

## 6) Troubleshooting checklist
- Hosting
  - AASA/assetlinks.json valid JSON, served as `application/json` (no redirect).
- Flutter
  - `ActionCodeSettings.linkDomain = 'auth.spiritlightsoft.com'`.
  - Early lifecycle link listener + reconstruction fallback for `finishSignIn` URL.
- Android
  - Installed APK release‑signed with the certificate SHA‑256 listed in `assetlinks.json`.
  - Intent‑filters cover `/__/auth/` and `/finishSignIn` paths.
- iOS
  - Only `applinks:auth.spiritlightsoft.com` in entitlements.
  - App ID has “Associated Domains”; Team ID matches AASA `appID` prefix.
  - Reset Safari Website Data if links start opening in Safari.
- macOS
  - macOS bundle included in AASA; entitlements include only the custom domain.
  - AppDelegate forwards to `super`.

---

## Common pitfalls and fixes

- **Multiple Associated Domains on iOS cause routing conflicts**
  - Symptom: Tapping the link opens Safari; long‑press shows only “Open in Safari,” not your app.
  - Cause: Having multiple `applinks:` entries (e.g., `applinks:vasis-beats.web.app`, `applinks:vasis-beats.firebaseapp.com`, plus your custom domain) lets iOS choose the web page instead of your app.
  - Fix:
    - Keep only your custom domain in `ios/Runner/Runner.entitlements`: `applinks:auth.spiritlightsoft.com`.
    - Re‑archive (TestFlight recommended) and install the new build.
    - If behavior is “stuck,” reset iOS caching (remove site data, reboot, reinstall).

- **Remove deprecated Firebase Dynamic Links configuration**
  - Symptom: Confusing redirects or legacy FDL behavior interleaving with new Universal Links.
  - Cause: Old Dynamic Links setup still present in the Firebase project.
  - Fix:
    - In Firebase console, delete any Dynamic Links you no longer use.
    - Client must use `ActionCodeSettings.linkDomain = 'auth.spiritlightsoft.com'` (not the deprecated `dynamicLinkDomain`).

- **iOS/macOS association not applied to the installed build**
  - Symptom: No “Open in App” option; app may focus but no link is delivered to Dart.
  - Causes:
    - App ID missing “Associated Domains” capability.
    - Team ID/Bundle ID mismatch with AASA `appID`.
    - AASA not served as `application/json` or served via redirect.
  - Fix:
    - Enable “Associated Domains” for your App ID; recreate provisioning profiles.
    - Ensure AASA `appID` matches `TeamID.BundleID` for iOS/macOS.
    - Verify headers and redeploy Hosting; reinstall the app and test with a fresh link.

- **Android App Links not verified**
  - Symptom: Link opens in browser instead of the app.
  - Cause: Installed APK is signed with a certificate not matching the SHA‑256 in `assetlinks.json`.
  - Fix:
    - **For Play Store apps**: Use Google Play signing key SHA-256 (from Play Console → Setup → App integrity → App signing)
    - **For direct APK distribution**: Use your upload key SHA-256
    - **DO NOT** include both fingerprints in `assetlinks.json` - this causes verification conflicts
    - Install a release‑signed APK whose certificate SHA‑256 matches `assetlinks.json`.
    - If keystore changes, update `assetlinks.json` and redeploy Hosting.
    - Clear app data and Google Play Services cache after updating `assetlinks.json`

- **Final redirect vs action URL (reconstruction fallback)**
  - Symptom: The OS delivers `https://auth.spiritlightsoft.com/finishSignIn?...` (not the Firebase action link), and `isSignInWithEmailLink` returns false.
  - Fix:
    - In an early lifecycle handler (e.g., `lib/splash.dart`), parse `oobCode`, `mode`, `apiKey`, etc., and reconstruct:
      - `https://auth.spiritlightsoft.com/__/auth/action?...`
    - Then call `signInWithEmailLink` with the cached email.

---

## Commands cheat sheet
- Deploy Hosting:
  - `firebase deploy --only hosting`
- Verify AASA:
  - `curl -I https://auth.spiritlightsoft.com/.well-known/apple-app-site-association`
- Verify asset links:
  - `curl -I https://auth.spiritlightsoft.com/.well-known/assetlinks.json`
- Android release build:
  - `flutter build apk --release`
- iOS archive:
  - `flutter build ipa --release` or use Xcode → Archive
- macOS build:
  - `flutter build macos`

---

## Closing notes
Migrating off Dynamic Links is about aligning three layers:
- Firebase project config (HOSTING_DOMAIN)
- Hosting files and correct headers (AASA/assetlinks.json)
- OS association and delivery (entitlements, App/Universal Links, plugin forwarding)

Android is deterministic once SHA‑256 and intent‑filters are correct. iOS enforces stronger association rules and sometimes cache prior decisions; removing legacy domains, resetting Safari Website Data, and ensuring entitlements/profiles are correct improves reliability significantly.

**macOS Limitation**: While we successfully achieved URL association (the app is recognized and can be opened via the link), we were unable to get the URL delivered to the app for completing the sign-in process. The association works correctly, but the URL forwarding mechanism to complete the Firebase Auth flow remains unresolved on macOS.
