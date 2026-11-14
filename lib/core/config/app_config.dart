/// App-wide URLs and store identifiers for settings actions.
abstract final class AppConfig {
  static const String appName = 'LifeSeen';

  static const String privacyPolicyUrl = 'https://lifeseen.app/privacy-policy';
  static const String termsOfUseUrl = 'https://lifeseen.app/terms-of-use';
  static const String eulaUrl = 'https://lifeseen.app/eula';

  static const String supportEmail = 'support@lifeseen.app';
  static const String supportSubject = 'LifeSeen Support Request';

  /// Android application id from `android/app/build.gradle`.
  static const String androidPackageName = 'com.android.test1';

  /// iOS App Store id — replace when the app is published.
  static const String iosAppStoreId = '0000000000';

  static String get androidStoreUrl =>
      'https://play.google.com/store/apps/details?id=$androidPackageName';

  static String get iosStoreUrl =>
      'https://apps.apple.com/app/id$iosAppStoreId';

  static String get shareMessage =>
      'Check out $appName — secure WhatsApp insights and analysis.\n'
      'Download: $androidStoreUrl';
}
