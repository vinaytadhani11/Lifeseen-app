import 'package:flutter/foundation.dart';
import 'package:tableflow_plus/services/app_prefs_service.dart';
import 'package:tableflow_plus/services/firebase/firebase_remote_config_service.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';

enum SubscriptionPlan {
  weekly(
    id: 'weekly',
    label: 'Weekly',
    days: 7,
    periodPrice: r'$9.99 / week',
    dailyPrice: r'$1.43 / daily',
  ),
  monthly(
    id: 'monthly',
    label: 'Monthly',
    days: 30,
    periodPrice: r'$29.99 / month',
    dailyPrice: r'$1.00 / daily',
  );

  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.days,
    required this.periodPrice,
    required this.dailyPrice,
  });

  final String id;
  final String label;
  final int days;
  final String periodPrice;
  final String dailyPrice;
}

enum BoostPlan {
  normal(
    recordDays: 7,
    periodPrice: r'$4.99 / week',
    dailyPrice: r'$0.71 / daily',
  ),
  superBoost(
    recordDays: 30,
    periodPrice: r'$14.99 / month',
    dailyPrice: r'$0.50 / daily',
  );

  const BoostPlan({
    required this.recordDays,
    required this.periodPrice,
    required this.dailyPrice,
  });

  /// How long the "boost purchased" record stays active.
  final int recordDays;
  final String periodPrice;
  final String dailyPrice;
}

/// Local-only subscription and boost records. No Play Store / RevenueCat
/// purchase is made.
class SubscriptionService {
  SubscriptionService(this._prefs, this._remoteConfig);

  final AppPrefsService _prefs;
  final FirebaseRemoteConfigService _remoteConfig;

  /// Called after a local subscription has been saved.
  void Function(SubscriptionPlan plan)? onSubscribed;

  String packageIdFor(SubscriptionPlan plan) {
    final config = _remoteConfig.config;
    return plan == SubscriptionPlan.weekly
        ? config.packageId1
        : config.packageId2;
  }

  String labelFor(SubscriptionPlan plan) {
    final config = _remoteConfig.config;
    return plan == SubscriptionPlan.weekly
        ? config.package1Text
        : config.package2Text;
  }

  Future<void> subscribeLocally(SubscriptionPlan plan) async {
    final now = DateTime.now();
    final expiry = now.add(Duration(days: plan.days));
    final packageId = packageIdFor(plan);
    await _prefs.saveSubscription(
      plan: plan.id,
      planLabel: labelFor(plan),
      packageId: packageId,
      startMillis: now.millisecondsSinceEpoch,
      expiryMillis: expiry.millisecondsSinceEpoch,
    );
    debugPrint(
      '[Subscription] local ${plan.id} package=$packageId expires=$expiry',
    );
    onSubscribed?.call(plan);
  }

  bool get isSubscriptionExpired {
    final expiry = _prefs.subscriptionExpiryMillis;
    if (expiry == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiry;
  }

  String boostIdFor(BoostPlan plan) {
    final config = _remoteConfig.config;
    return plan == BoostPlan.normal ? config.boostId1 : config.boostId2;
  }

  bool _isExpiryActive(int? expiryMillis) {
    if (expiryMillis == null) return false;
    return DateTime.now().millisecondsSinceEpoch < expiryMillis;
  }

  bool get isNormalBoostActive =>
      _isExpiryActive(_prefs.normalBoostExpiryMillis) ||
      (_prefs.boostId == _remoteConfig.config.boostId1 &&
          _isExpiryActive(_prefs.boostExpiryMillis));

  bool get isSuperBoostActive =>
      _isExpiryActive(_prefs.superBoostExpiryMillis) ||
      (_prefs.boostId == _remoteConfig.config.boostId2 &&
          _isExpiryActive(_prefs.boostExpiryMillis));

  /// Screen countdown hours for the BOOST phase.
  /// If Normal and Super are both active, Super wins (`super_boost` hours).
  int boostCountdownHours() {
    final settings = _remoteConfig.settings;
    if (isSuperBoostActive) return settings.superBoost;
    return settings.normalBoost;
  }

  Future<void> activateBoostLocally(BoostPlan plan) async {
    final expiry = DateTime.now().add(Duration(days: plan.recordDays));
    final id = boostIdFor(plan);
    await _prefs.saveBoost(
      boostId: id,
      expiryMillis: expiry.millisecondsSinceEpoch,
      isSuper: plan == BoostPlan.superBoost,
    );
    debugPrint('[Subscription] local boost $id expires=$expiry');
    // Boost buy also cancels the WP reminder chain.
    await NotificationScheduler.cancelAll();
  }
}
