import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/navigation/navigation_utils.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_routeAfterSplash());
  }

  Future<void> _routeAfterSplash() async {
    // Joins the fetch started in AppBootstrap, instead of starting a second one.
    final refreshFuture = AppBootstrap.remoteConfig.refresh();
    await Future.wait<void>([
      Future<void>.delayed(const Duration(seconds: 2)),
      refreshFuture,
    ]);
    if (!mounted) return;

    await AppBootstrap.prefs.syncPremiumAndBoostExpiry();
    if (!AppBootstrap.prefs.isUserPremium) {
      AppBootstrap.decryption.pauseBecausePremiumEnded();
    }

    final pageLog = AppBootstrap.remoteConfig.config.pageLog;
    debugPrint('[Splash] routing with page_log=$pageLog');
    if (pageLog == 0) {
      NavigationUtils.toFriendsScreenTime();
      return;
    }

    if (AppBootstrap.prefs.hasWpLogin) {
      NavigationUtils.toWhatsAppChats();
      return;
    }

    NavigationUtils.toEnterNumber();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splashBackground,
      ),
      child: const Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: Center(child: LifeSeenLogo(dark: true)),
      ),
    );
  }
}
