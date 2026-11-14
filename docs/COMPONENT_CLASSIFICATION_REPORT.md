# Component Classification Report

Android source: `LogSense-Reconstructed` / decompiled APK `com.app.logsense`  
Flutter target: `lifeseen_flutter`  
Generated: 2026-06-05

## Classification Legend

| Status                      | Meaning                         |
| --------------------------- | ------------------------------- |
| **Active**                  | Default user path               |
| **Conditionally Active**    | Gated by Remote Config or prefs |
| **Admin Only**              | Settings debug toggles          |
| **Feature Flag Controlled** | Remote Config key               |
| **Future Feature**          | Declared but stubbed            |
| **Legacy Feature**          | Original APK only               |
| **Truly Unused**            | No manifest / no references     |

---

## Activities (15)

| Component                      | Status               | RC / Gate                           | Flutter Screen            |
| ------------------------------ | -------------------- | ----------------------------------- | ------------------------- |
| SplashActivity                 | Active               | `page_log` routes WP vs Tracker     | `SplashScreen`            |
| OnBoardingActivity             | Conditionally Active | `isOnboardingFinish` pref           | `OnboardingScreen`        |
| NumberListActivity             | Active               | Tracker mode (`page_log=0`)         | `NumberListScreen`        |
| AddNumberActivity              | Active               | Tracker flow                        | `AddNumberScreen`         |
| EditNumberActivity             | Active               | From number list                    | `EditNumberScreen`        |
| CountryCodeActivity            | Active               | Country picker                      | `CountryPickerScreen`     |
| PhoneVerificationActivity      | Conditionally Active | `settings.ct` + `phoneVerification` | `PhoneVerificationScreen` |
| SettingsActivity               | Active               | Tracker settings                    | `SettingsScreen`          |
| Premium1Activity               | Conditionally Active | `premium_log`, non-premium users    | `Premium1Screen`          |
| Premium3Activity               | Conditionally Active | Boost / chat tap                    | `Premium3Screen`          |
| EnterWpNumberBlackActivity     | Active               | WP mode, empty phone                | `EnterWpNumberScreen`     |
| BeingAnalyzedBlackActivity     | Active               | WP flow                             | `BeingAnalyzedScreen`     |
| AnalysisCompletedBlackActivity | Active               | WP flow                             | `AnalysisCompletedScreen` |
| ChatListActivity               | Active               | WP mode main                        | `ChatListScreen`          |
| SettingsWpActivity             | Active               | WP settings                         | `SettingsWpScreen`        |

## Orphan Layout

| Component             | Status         | Notes                                               | Flutter                   |
| --------------------- | -------------- | --------------------------------------------------- | ------------------------- |
| activity_web_view.xml | Legacy Feature | No Activity in manifest; legal URLs use Custom Tabs | `WebViewScreen` preserved |

## Dialogs / Bottom Sheets

| Component                  | Status                  | Flutter                         |
| -------------------------- | ----------------------- | ------------------------------- |
| WhiteLineDialog            | Conditionally Active    | Logic stub in ChatList          |
| OpenWhatsappMessagesDialog | Conditionally Active    | Pending full UI port            |
| MessagesReadyBlackDialog   | Conditionally Active    | `MessagesReadyDialog` widget    |
| QrBlackDialog              | Feature Flag Controlled | `star` RC — pending             |
| StarDialog                 | Feature Flag Controlled | `star` RC — pending             |
| DisconnectDialog           | Active                  | Pending                         |
| ProcessingDialog           | Active                  | Loading overlay in AddNumber    |
| TwoActionDialog            | Truly Unused            | Not referenced in manifest flow |
| BottomSheetDialogBoost     | Active                  | `BoostBottomSheet`              |

## Remote Config Keys

| Key                        | Status                  | Values                       | Flutter                         |
| -------------------------- | ----------------------- | ---------------------------- | ------------------------------- |
| `page_log`                 | Feature Flag Controlled | 0=Tracker, 1=WhatsApp        | `RemoteConfigModel.pageLog`     |
| `notification`             | Feature Flag Controlled | 0/1                          | `NotificationScheduler`         |
| `premium_log`              | Feature Flag Controlled | Premium page routing         | Pending routing                 |
| `star`                     | Feature Flag Controlled | Star dialog                  | Pending                         |
| `package_id_1/2`           | Active                  | IAP IDs                      | Local unlock (no RC purchase)   |
| `boost_button`, `boost_id` | Active                  | Boost copy / SKU             | BoostBottomSheet                |
| `onboarding_1/2/3`         | Active                  | Onboarding strings           | Hardcoded + RC fallback pending |
| `settings.start_time`      | Active                  | Timer hours                  | `TimerManager`                  |
| `settings.boost_time`      | Active                  | Boost timer                  | `TimerManager`                  |
| `settings.extended_time`   | Active                  | Extra timer                  | `TimerManager`                  |
| `settings.ct`              | Conditionally Active    | Phone verification countries | AddNumber gate                  |

## Settings Debug Toggles (Admin Only)

| Toggle             | Android                       | Flutter                              |
| ------------------ | ----------------------------- | ------------------------------------ |
| Premium access     | SettingsActivity              | `PrefsProvider.setPremium`           |
| Boost access       | SettingsActivity / SettingsWp | `PrefsProvider.setBoostUnlocked`     |
| Instant decryption | SettingsActivity / SettingsWp | `PrefsProvider.setInstantDecryption` |

## Services

| Service                    | Status                                       | Flutter                                     |
| -------------------------- | -------------------------------------------- | ------------------------------------------- |
| Firebase Remote Config     | Active                                       | `FirebaseRemoteConfigService`               |
| Firebase Realtime Database | Active (Flutter) / Firestore (Android recon) | `FirebaseDatabaseService` + `AppRepository` |
| Firebase Auth (Phone)      | Conditionally Active                         | `FirebaseAuthService`                       |
| WorkManager notifications  | Conditionally Active                         | `NotificationScheduler`                     |
| RevenueCat                 | Legacy (removed in recon)                    | Local unlock only                           |
| IpLocationManager          | Active                                       | `IpLocationManager`                         |
| Timer Manager              | Active                                       | `TimerManager`                              |
| Offline write queue        | Active                                       | `OfflineWriteQueue`                         |

## Recommendation

**Do not remove any component.** Items marked "Pending" require UI/asset parity work but are classified as reachable or flag-controlled per Android behavior.
