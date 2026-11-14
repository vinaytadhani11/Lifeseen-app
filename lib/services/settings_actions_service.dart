import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tableflow_plus/core/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

enum SettingsAction {
  privacyPolicy,
  termsOfUse,
  eula,
  rateUs,
  share,
  support,
  deleteAccount,
}

class SettingsActionsService {
  SettingsActionsService._();

  static Future<void> handle(
    SettingsAction action, {
    required Rect? shareOrigin,
  }) async {
    switch (action) {
      case SettingsAction.privacyPolicy:
        await _openUrl(AppConfig.privacyPolicyUrl);
      case SettingsAction.termsOfUse:
        await _openUrl(AppConfig.termsOfUseUrl);
      case SettingsAction.eula:
        await _openUrl(AppConfig.eulaUrl);
      case SettingsAction.rateUs:
        await _rateApp();
      case SettingsAction.share:
        await _shareApp(shareOrigin: shareOrigin);
      case SettingsAction.support:
        await _contactSupport();
      case SettingsAction.deleteAccount:
        break;
    }
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw SettingsActionException('Could not open link.');
    }
  }

  static Future<void> _rateApp() async {
    final review = InAppReview.instance;

    if (await review.isAvailable()) {
      await review.requestReview();
      return;
    }

    await openStoreListing();
  }

  /// Opens the Play Store / App Store page of this app.
  static Future<void> openStoreListing() async {
    final storeUri = await _storeListingUri();
    if (storeUri == null) {
      throw SettingsActionException(
        'App store is not available on this device.',
      );
    }

    var launched = await launchUrl(
      storeUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && Platform.isAndroid) {
      launched = await launchUrl(
        Uri.parse(AppConfig.androidStoreUrl),
        mode: LaunchMode.externalApplication,
      );
    }

    if (!launched) {
      throw SettingsActionException('Could not open the app store.');
    }
  }

  static Future<Uri?> _storeListingUri() async {
    if (kIsWeb) return null;

    if (Platform.isIOS) {
      return Uri.parse(
        'https://apps.apple.com/app/id${AppConfig.iosAppStoreId}?action=write-review',
      );
    }

    if (Platform.isAndroid) {
      final marketUri = Uri.parse(
        'market://details?id=${AppConfig.androidPackageName}',
      );
      if (await canLaunchUrl(marketUri)) {
        return marketUri;
      }
      return Uri.parse(AppConfig.androidStoreUrl);
    }

    return null;
  }

  static Future<void> _shareApp({required Rect? shareOrigin}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appLabel = packageInfo.appName.isNotEmpty
        ? packageInfo.appName
        : AppConfig.appName;

    final message =
        'Check out $appLabel — secure WhatsApp insights.\n'
        '${Platform.isIOS ? AppConfig.iosStoreUrl : AppConfig.androidStoreUrl}';

    final result = await Share.share(
      message,
      subject: appLabel,
      sharePositionOrigin: shareOrigin,
    );

    if (result.status == ShareResultStatus.unavailable) {
      throw SettingsActionException('Sharing is not available on this device.');
    }
  }

  static Future<void> _contactSupport() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final build = packageInfo.buildNumber;
    final platform = Platform.isIOS ? 'iOS' : 'Android';

    final body = Uri.encodeComponent(
      '\n\n---\n'
      'App: ${AppConfig.appName}\n'
      'Version: $version ($build)\n'
      'Platform: $platform',
    );

    final uri = Uri.parse(
      'mailto:${AppConfig.supportEmail}'
      '?subject=${Uri.encodeComponent(AppConfig.supportSubject)}'
      '&body=$body',
    );

    final launched = await launchUrl(uri);
    if (!launched) {
      throw SettingsActionException(
        'No email app found. Contact us at ${AppConfig.supportEmail}',
      );
    }
  }
}

class SettingsActionException implements Exception {
  SettingsActionException(this.message);

  final String message;

  @override
  String toString() => message;
}
