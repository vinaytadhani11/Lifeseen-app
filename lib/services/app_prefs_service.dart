import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableflow_plus/core/constants/pref_keys.dart';
import 'package:tableflow_plus/models/local_plan_record.dart';

class AppPrefsService {
  AppPrefsService(this._prefs);

  final SharedPreferences _prefs;

  String? get auth => _prefs.getString(PrefKeys.auth);
  bool get isOnboardingFinish =>
      _prefs.getBool(PrefKeys.isOnboardingFinish) ?? false;
  String get documentId => _prefs.getString(PrefKeys.documentID) ?? '';

  LocalPlanRecord? get screenTimeSubscription =>
      _readPlan(PrefKeys.screenTimeSubscription);
  String? get phoneNumber => _prefs.getString(PrefKeys.phoneNumber);
  bool get isUserPremium => _prefs.getBool(PrefKeys.isUserPremium) ?? false;

  bool get notificationRemindersEnabled =>
      _prefs.getBool(PrefKeys.notificationRemindersEnabled) ?? false;
  bool get isBoostUnlocked => _prefs.getBool(PrefKeys.isBoostUnlocked) ?? false;
  bool get isInstantDecryption =>
      _prefs.getBool(PrefKeys.isInstantDecryption) ?? false;
  bool get isUserWhiteLineDialog =>
      _prefs.getBool(PrefKeys.isUserWhiteLineDialog) ?? false;
  bool get isStarDialogDone =>
      _prefs.getBool(PrefKeys.isStarDialogDone) ?? false;
  String? get phoneCountryIso => _prefs.getString(PrefKeys.phoneCountryIso);
  String? get city => _prefs.getString(PrefKeys.city);
  String? get country => _prefs.getString(PrefKeys.country);
  String? get subscriptionPlan => _prefs.getString(PrefKeys.subscriptionPlan);
  String? get subscriptionPackageId =>
      _prefs.getString(PrefKeys.subscriptionPackageId);
  int? get subscriptionStartMillis =>
      _prefs.getInt(PrefKeys.subscriptionStartMillis);
  int? get subscriptionExpiryMillis =>
      _prefs.getInt(PrefKeys.subscriptionExpiryMillis);

  Future<void> setUserWhiteLineDialog(bool value) =>
      _prefs.setBool(PrefKeys.isUserWhiteLineDialog, value);

  Future<void> setStarDialogDone(bool value) =>
      _prefs.setBool(PrefKeys.isStarDialogDone, value);

  String get wpLoginNumber => _prefs.getString(PrefKeys.wpLoginNumber) ?? '';

  bool get hasWpLogin {
    if (wpLoginNumber.trim().isNotEmpty) return true;
    return (phoneNumber ?? '').trim().isNotEmpty;
  }

  bool get continueWhereYouLeftOff =>
      _prefs.getBool(PrefKeys.isUserPremiumContinueWhereYouLeftOff) ?? false;

  bool get boostActivated => _prefs.getBool(PrefKeys.boostActivated) ?? false;

  bool get normalBoost => _prefs.getBool(PrefKeys.normalBoost) ?? false;

  bool get superBoost => _prefs.getBool(PrefKeys.superBoost) ?? false;

  String get timerType => _prefs.getString(PrefKeys.timerType) ?? '';

  String get timerStatus =>
      _prefs.getString(PrefKeys.timerStatus) ?? 'NOT_STARTED';

  int get timerAnchorMillis => _prefs.getInt(PrefKeys.timerAnchorMillis) ?? 0;

  LocalPlanRecord? get wpSubscription =>
      _readPlan(PrefKeys.wpSubscription);

  LocalPlanRecord? get normalBoostSubscription =>
      _readPlan(PrefKeys.wpNormalBoostSubscription);

  LocalPlanRecord? get superBoostSubscription =>
      _readPlan(PrefKeys.wpSuperBoostSubscription);

  Future<void> setWpLoginNumber(String value) =>
      _prefs.setString(PrefKeys.wpLoginNumber, value);

  Future<void> setContinueWhereYouLeftOff(bool value) =>
      _prefs.setBool(PrefKeys.isUserPremiumContinueWhereYouLeftOff, value);

  Future<void> setBoostActivated(bool value) =>
      _prefs.setBool(PrefKeys.boostActivated, value);

  /// Test only: drop the local weekly/monthly plan.
  Future<void> resetWpSubscription() async {
    await _prefs.remove(PrefKeys.wpSubscription);
    await _prefs.remove(PrefKeys.subscriptionPlan);
    await _prefs.remove(PrefKeys.subscriptionPlanLabel);
    await _prefs.remove(PrefKeys.subscriptionPackageId);
    await _prefs.remove(PrefKeys.subscriptionStartMillis);
    await _prefs.remove(PrefKeys.subscriptionExpiryMillis);
    await setUserPremium(false);
    await setContinueWhereYouLeftOff(false);
  }

  /// Test only: drop Normal and Super boost records separately stored.
  Future<void> resetBoostSubscriptions() async {
    await _prefs.remove(PrefKeys.wpNormalBoostSubscription);
    await _prefs.remove(PrefKeys.wpSuperBoostSubscription);
    await _prefs.remove(PrefKeys.boostId);
    await _prefs.remove(PrefKeys.boostExpiryMillis);
    await _prefs.remove(PrefKeys.normalBoostExpiryMillis);
    await _prefs.remove(PrefKeys.superBoostExpiryMillis);
    await _prefs.setBool(PrefKeys.normalBoost, false);
    await _prefs.setBool(PrefKeys.superBoost, false);
    await _prefs.setBool(PrefKeys.isBoostUnlocked, false);
    await setBoostActivated(false);
  }

  /// Test only: phone, premium, boosts and dialog flags back to a fresh WP flow.
  Future<void> resetEntireWhatsAppFlow() async {
    await disconnectWhatsApp();
    await resetWpSubscription();
    await resetBoostSubscriptions();
    await setStarDialogDone(false);
    await _prefs.remove(PrefKeys.notificationPhoneNumber);
    await _prefs.setBool(PrefKeys.notificationRemindersEnabled, false);
  }
  Future<void> disconnectWhatsApp() async {
    await clearPhone();
    await _prefs.setString(PrefKeys.wpLoginNumber, '');
    await setUserWhiteLineDialog(false);
  }

  Future<void> clearPhone() async {
    await _prefs.remove(PrefKeys.phoneNumber);
    await _prefs.remove(PrefKeys.phoneCountryIso);
  }

  LocalPlanRecord? _readPlan(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return LocalPlanRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writePlan(String key, LocalPlanRecord record) =>
      _prefs.setString(key, jsonEncode(record.toJson()));

  /// Splash: expired local plans drop premium / boost flags.
  Future<void> syncPremiumAndBoostExpiry() async {
    final subscription = wpSubscription;
    if (subscription != null &&
        (subscription.isExpired || !subscription.active)) {
      await writePlan(
        PrefKeys.wpSubscription,
        subscription.copyWith(active: false),
      );
      await setUserPremium(false);
    }

    Future<void> syncBoost({
      required String key,
      required LocalPlanRecord? record,
      required String flagKey,
    }) async {
      if (record == null) return;
      if (record.isExpired || !record.active) {
        await writePlan(key, record.copyWith(active: false));
        await _prefs.setBool(flagKey, false);
      }
    }

    await syncBoost(
      key: PrefKeys.wpNormalBoostSubscription,
      record: normalBoostSubscription,
      flagKey: PrefKeys.normalBoost,
    );
    await syncBoost(
      key: PrefKeys.wpSuperBoostSubscription,
      record: superBoostSubscription,
      flagKey: PrefKeys.superBoost,
    );
  }

  String? get boostId => _prefs.getString(PrefKeys.boostId);
  int? get boostExpiryMillis => _prefs.getInt(PrefKeys.boostExpiryMillis);
  int? get normalBoostExpiryMillis =>
      _prefs.getInt(PrefKeys.normalBoostExpiryMillis);
  int? get superBoostExpiryMillis =>
      _prefs.getInt(PrefKeys.superBoostExpiryMillis);

  Future<void> saveBoost({
    required String boostId,
    required int expiryMillis,
    required bool isSuper,
  }) async {
    await _prefs.setString(PrefKeys.boostId, boostId);
    await _prefs.setInt(PrefKeys.boostExpiryMillis, expiryMillis);
    await _prefs.setInt(
      isSuper
          ? PrefKeys.superBoostExpiryMillis
          : PrefKeys.normalBoostExpiryMillis,
      expiryMillis,
    );
    await _prefs.setBool(PrefKeys.isBoostUnlocked, true);
    await _prefs.setBool(
      isSuper ? PrefKeys.superBoost : PrefKeys.normalBoost,
      true,
    );
    await setBoostActivated(true);
    await writePlan(
      isSuper
          ? PrefKeys.wpSuperBoostSubscription
          : PrefKeys.wpNormalBoostSubscription,
      LocalPlanRecord(
        planId: isSuper ? 'super_boost' : 'normal_boost',
        planLabel: boostId,
        packageId: boostId,
        purchaseDateMs: DateTime.now().millisecondsSinceEpoch,
        expiryDateMs: expiryMillis,
        active: true,
        source: isSuper ? 'local_wp_super_boost' : 'local_wp_normal_boost',
      ),
    );
  }

  String? get decryptionStage => _prefs.getString(PrefKeys.decryptionStage);
  int get decryptionRemainingSeconds =>
      _prefs.getInt(PrefKeys.decryptionRemainingSeconds) ?? 0;
  int get decryptionTotalSeconds =>
      _prefs.getInt(PrefKeys.decryptionTotalSeconds) ?? 0;

  Future<void> saveDecryption({
    required String stage,
    required int remainingSeconds,
    required int totalSeconds,
    required String type,
    required String status,
    required int anchorMillis,
  }) async {
    await _prefs.setString(PrefKeys.decryptionStage, stage);
    await _prefs.setInt(PrefKeys.decryptionRemainingSeconds, remainingSeconds);
    await _prefs.setInt(PrefKeys.decryptionTotalSeconds, totalSeconds);
    await _prefs.setString(PrefKeys.timerType, type);
    await _prefs.setString(PrefKeys.timerStatus, status);
    await _prefs.setInt(PrefKeys.timerAnchorMillis, anchorMillis);
  }

  Future<void> setPhoneCountryIso(String value) =>
      _prefs.setString(PrefKeys.phoneCountryIso, value);

  Future<void> saveSubscription({
    required String plan,
    required String planLabel,
    required String packageId,
    required int startMillis,
    required int expiryMillis,
  }) async {
    await _prefs.setString(PrefKeys.subscriptionPlan, plan);
    await _prefs.setString(PrefKeys.subscriptionPlanLabel, planLabel);
    await _prefs.setString(PrefKeys.subscriptionPackageId, packageId);
    await _prefs.setInt(PrefKeys.subscriptionStartMillis, startMillis);
    await _prefs.setInt(PrefKeys.subscriptionExpiryMillis, expiryMillis);
    await _prefs.setBool(PrefKeys.isUserPremium, true);
    await setContinueWhereYouLeftOff(true);
    await writePlan(
      PrefKeys.wpSubscription,
      LocalPlanRecord(
        planId: plan,
        planLabel: planLabel,
        packageId: packageId,
        purchaseDateMs: startMillis,
        expiryDateMs: expiryMillis,
        active: true,
        source: 'local_wp',
      ),
    );
  }

  Future<void> setAuth(String value) => _prefs.setString(PrefKeys.auth, value);

  Future<void> setOnboardingFinish(bool value) =>
      _prefs.setBool(PrefKeys.isOnboardingFinish, value);

  Future<void> setDocumentId(String value) =>
      _prefs.setString(PrefKeys.documentID, value);

  Future<void> setScreenTimeSubscription(LocalPlanRecord? record) async {
    if (record == null) {
      await _prefs.remove(PrefKeys.screenTimeSubscription);
      return;
    }
    await writePlan(PrefKeys.screenTimeSubscription, record);
  }

  /// Friends logout / delete. WhatsApp keys stay so page_log = 1 is unchanged.
  Future<void> clearFriendsSession() async {
    await _prefs.remove(PrefKeys.documentID);
    await _prefs.remove(PrefKeys.screenTimeUser);
    await _prefs.remove(PrefKeys.screenTimeSubscription);
    await setOnboardingFinish(false);
  }

  Future<void> setPhoneNumber(String value) =>
      _prefs.setString(PrefKeys.phoneNumber, value);

  Future<void> setUserPremium(bool value) =>
      _prefs.setBool(PrefKeys.isUserPremium, value);

  Future<void> setBoostUnlocked(bool value) =>
      _prefs.setBool(PrefKeys.isBoostUnlocked, value);

  Future<void> setInstantDecryption(bool value) =>
      _prefs.setBool(PrefKeys.isInstantDecryption, value);

  Future<void> setCity(String value) => _prefs.setString(PrefKeys.city, value);

  Future<void> setCountry(String value) =>
      _prefs.setString(PrefKeys.country, value);

  Future<void> clear() => _prefs.clear();
}
