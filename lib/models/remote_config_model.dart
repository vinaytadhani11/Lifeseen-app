int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String _asString(dynamic value, String fallback) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

/// Remote Config param `data` (remote_config_data.json).
class RemoteConfigModel {
  const RemoteConfigModel({
    required this.pageLog,
    this.premiumOption = 0,
    this.close = 1,
    this.notification = 1,
    this.star = 0,
    this.packageId1 = r'$rc_weekly',
    this.packageId2 = r'$rc_monthly',
    this.package1Text = 'Weekly',
    this.package2Text = 'Monthly',
    this.boostTitle = 'Boost Your Recovery',
    this.boostSubTitle = 'Unlock messages faster',
    this.boostSelected1Title = 'Normal Boost',
    this.boostSelected1SubTitle = 'Standard speed unlock',
    this.boostSelected2Title = 'Super Boost',
    this.boostSelected2SubTitle = 'Maximum speed unlock',
    this.boostButton = 'Activate Boost',
    this.boostId1 = 'normal_boost',
    this.boostId2 = 'super_boost',
  });

  final int pageLog;

  /// 0 = Weekly/Monthly tabs visible, 1 = tabs hidden.
  final int premiumOption;

  /// 1 = close button after 5 s, 0 = immediately, anything else = no close.
  final int close;

  /// Reminder notifications before premium (cancelled on buy).
  final int notification;

  /// 1 = Play review before paywall, 2 = Play Store page, 0 = skip.
  final int star;

  final String packageId1;
  final String packageId2;
  final String package1Text;
  final String package2Text;

  final String boostTitle;
  final String boostSubTitle;
  final String boostSelected1Title;
  final String boostSelected1SubTitle;
  final String boostSelected2Title;
  final String boostSelected2SubTitle;
  final String boostButton;
  final String boostId1;
  final String boostId2;

  bool get showPlanTabs => premiumOption == 0;

  /// `null` means the close button is never shown.
  Duration? get closeButtonDelay => switch (close) {
    0 => Duration.zero,
    1 => const Duration(seconds: 5),
    _ => null,
  };

  factory RemoteConfigModel.defaults() => const RemoteConfigModel(pageLog: 1);

  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    const d = RemoteConfigModel(pageLog: 1);
    return RemoteConfigModel(
      pageLog: _asInt(json['page_log'], 1),
      premiumOption: _asInt(json['premium_option'], d.premiumOption),
      close: _asInt(json['close'], d.close),
      notification: _asInt(json['notification'], d.notification),
      star: _asInt(json['star'], d.star),
      packageId1: _asString(json['package_id_1'], d.packageId1),
      packageId2: _asString(json['package_id_2'], d.packageId2),
      package1Text: _asString(json['package_id_1_text'], d.package1Text),
      package2Text: _asString(json['package_id_2_text'], d.package2Text),
      boostTitle: _asString(json['boost_title'], d.boostTitle),
      boostSubTitle: _asString(json['boost_sub_title'], d.boostSubTitle),
      boostSelected1Title: _asString(
        json['boost_selected_1_title'],
        d.boostSelected1Title,
      ),
      boostSelected1SubTitle: _asString(
        json['boost_selected_1_sub_title'],
        d.boostSelected1SubTitle,
      ),
      boostSelected2Title: _asString(
        json['boost_selected_2_title'],
        d.boostSelected2Title,
      ),
      boostSelected2SubTitle: _asString(
        json['boost_selected_2_sub_title'],
        d.boostSelected2SubTitle,
      ),
      boostButton: _asString(json['boost_button'], d.boostButton),
      boostId1: _asString(json['boost_id_1'], d.boostId1),
      boostId2: _asString(json['boost_id_2'], d.boostId2),
    );
  }

  Map<String, dynamic> toJson() => {
    'page_log': pageLog,
    'premium_option': premiumOption,
    'close': close,
    'notification': notification,
    'star': star,
    'package_id_1': packageId1,
    'package_id_2': packageId2,
    'package_id_1_text': package1Text,
    'package_id_2_text': package2Text,
    'boost_title': boostTitle,
    'boost_sub_title': boostSubTitle,
    'boost_selected_1_title': boostSelected1Title,
    'boost_selected_1_sub_title': boostSelected1SubTitle,
    'boost_selected_2_title': boostSelected2Title,
    'boost_selected_2_sub_title': boostSelected2SubTitle,
    'boost_button': boostButton,
    'boost_id_1': boostId1,
    'boost_id_2': boostId2,
  };

  @override
  String toString() => 'RemoteConfigModel(${toJson()})';
}

/// Remote Config param `settings` (remote_config_settings.json). Hours.
class RemoteSettingsModel {
  const RemoteSettingsModel({
    this.startTime = 48,
    this.normalBoost = 24,
    this.superBoost = 12,
    this.extendedTime = 6,
    this.tiktokKey = '',
  });

  final int startTime;
  final int normalBoost;
  final int superBoost;
  final int extendedTime;
  final String tiktokKey;

  factory RemoteSettingsModel.defaults() => const RemoteSettingsModel();

  factory RemoteSettingsModel.fromJson(Map<String, dynamic> json) {
    const d = RemoteSettingsModel();
    // 0 is valid: that phase completes immediately (0 * 3600 = 0 seconds).
    int hours(String key, int fallback) {
      if (!json.containsKey(key) || json[key] == null) return fallback;
      final value = _asInt(json[key], fallback);
      return value < 0 ? fallback : value;
    }

    return RemoteSettingsModel(
      startTime: hours('start_time', d.startTime),
      normalBoost: hours('normal_boost', d.normalBoost),
      superBoost: hours('super_boost', d.superBoost),
      extendedTime: hours('extended_time', d.extendedTime),
      tiktokKey: json['tiktok_key']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'start_time': startTime,
    'normal_boost': normalBoost,
    'super_boost': superBoost,
    'extended_time': extendedTime,
    'tiktok_key': tiktokKey,
  };

  @override
  String toString() => 'RemoteSettingsModel(${toJson()})';
}
