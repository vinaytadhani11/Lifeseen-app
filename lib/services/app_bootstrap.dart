import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableflow_plus/firebase_options.dart';
import 'package:tableflow_plus/services/app_prefs_service.dart';
import 'package:tableflow_plus/services/decryption_timer_service.dart';
import 'package:tableflow_plus/services/firebase/firebase_remote_config_service.dart';
import 'package:tableflow_plus/services/ip_location_service.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:tableflow_plus/services/subscription_service.dart';

class AppBootstrap {
  AppBootstrap._();

  static late AppPrefsService prefs;
  static late FirebaseRemoteConfigService remoteConfig;
  static late IpLocationStore ipLocation;
  static late SubscriptionService subscription;
  static late DecryptionTimerService decryption;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final sharedPrefs = await SharedPreferences.getInstance();
    prefs = AppPrefsService(sharedPrefs);
    ipLocation = IpLocationStore(prefs);
    unawaited(ipLocation.ensureFetched());

    remoteConfig = FirebaseRemoteConfigService(FirebaseRemoteConfig.instance);
    await remoteConfig.init();

    await NotificationScheduler.initialize();

    subscription = SubscriptionService(prefs, remoteConfig);
    decryption = DecryptionTimerService(prefs);
    subscription.onSubscribed = (_) {
      decryption.startInitial(remoteConfig.settings.startTime);
      unawaited(NotificationScheduler.cancelAll());
    };
  }

  /// Chat list resume: pending boost replaces the countdown, then the flag clears.
  static Future<void> applyBoostOnChatResume() async {
    if (!prefs.isUserPremium || !prefs.boostActivated) return;
    decryption.startBoost(subscription.boostCountdownHours());
    await prefs.setBoostActivated(false);
  }
}
