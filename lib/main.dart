import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/navigation/navigation_utils.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text_scale.dart';
import 'package:tableflow_plus/screens/splash_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  NotificationScheduler.bindSplashOpener(
    () => NavigationUtils.openSplashClearingStack(
      () => const SplashScreen(),
    ),
  );
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await AppBootstrap.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.splashBackground,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LifeSeenApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(NotificationScheduler.consumeLaunchNotification());
  });
}

class LifeSeenApp extends StatelessWidget {
  const LifeSeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'LifeSeen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.splashBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.logoAccent,
          brightness: Brightness.dark,
          surface: AppColors.splashBackground,
        ),
        useMaterial3: true,
      ),
      builder: AppTextScale.wrap,
      home: const SplashScreen(),
    );
  }
}
