abstract final class PrefKeys {
  static const auth = 'auth';
  static const isOnboardingFinish = 'isOnboardingFinish';
  static const documentID = 'documentID';
  static const screenTimeUser = 'screenTimeUser';
  static const screenTimeSubscription = 'screenTimeSubscription';
  static const phoneNumber = 'phoneNumber';
  static const phoneCountryIso = 'phoneCountryIso';
  static const isUserPremium = 'isUserPremium';
  static const isBoostUnlocked = 'isBoostUnlocked';
  static const isInstantDecryption = 'isInstantDecryption';
  static const city = 'city';
  static const country = 'country';
  static const isUserWhiteLineDialog = 'isUserWhiteLineDialog';
  static const isStarDialogDone = 'isStarDialogDone';
  static const subscriptionPlanLabel = 'subscriptionPlanLabel';
  static const boostId = 'boostId';
  static const boostExpiryMillis = 'boostExpiryMillis';
  static const normalBoostExpiryMillis = 'normalBoostExpiryMillis';
  static const superBoostExpiryMillis = 'superBoostExpiryMillis';
  static const decryptionStage = 'decryptionStage';
  static const decryptionRemainingSeconds = 'decryptionRemainingSeconds';
  static const decryptionTotalSeconds = 'decryptionTotalSeconds';
  static const subscriptionPlan = 'subscriptionPlan';
  static const subscriptionPackageId = 'subscriptionPackageId';
  static const subscriptionStartMillis = 'subscriptionStartMillis';
  static const subscriptionExpiryMillis = 'subscriptionExpiryMillis';

  /// NotificationPrefs.phone_number — WP reminder chain only.
  static const notificationPhoneNumber = 'notificationPhoneNumber';

  /// Cached RC gate so the WorkManager isolate can reschedule without RC.
  static const notificationRemindersEnabled = 'notificationRemindersEnabled';

  /// Full WhatsApp number, e.g. +9199... Empty sends Splash back to phone entry.
  static const wpLoginNumber = 'wpLoginNumber';
  static const wpSubscription = 'wpSubscription';
  static const wpNormalBoostSubscription = 'wpNormalBoostSubscription';
  static const wpSuperBoostSubscription = 'wpSuperBoostSubscription';
  static const normalBoost = 'normalBoost';
  static const superBoost = 'superBoost';
  static const isUserPremiumContinueWhereYouLeftOff =
      'isUserPremiumContinueWhereYouLeftOff';
  static const boostActivated = 'boost_activated';

  static const timerType = 'timer_type';
  static const timerStatus = 'timer_status';
  static const timerAnchorMillis = 'timer_anchor_millis';
}
