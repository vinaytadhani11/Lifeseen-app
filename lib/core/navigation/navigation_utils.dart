import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_screen_time_screen.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/enter_number_screen.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/see_whatsapp_chats_screen.dart';

abstract final class NavigationUtils {
  static Future<T?>? to<T>(Widget Function() page) => Get.to<T>(page);

  static void offAll(Widget Function() page) => Get.offAll(page);

  /// Reminder tap: Splash replaces every screen, same as a cleared task.
  /// The cold-start route is already Splash, so that launch is left as-is.
  static void openSplashClearingStack(Widget Function() page) {
    void go() {
      if (Get.key.currentState == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => go());
        return;
      }
      final route = Get.currentRoute;
      if (route == '/' || route == '/SplashScreen') return;
      offAll(page);
    }

    go();
  }

  static void toFriendsScreenTime() =>
      offAll(() => const FriendsScreenTimeScreen());

  static void toEnterNumber() => offAll(() => const EnterNumberScreen());

  static void toWhatsAppChats() =>
      offAll(() => const SeeWhatsAppChatsScreen());

  static void back<T>([T? result]) => Get.back<T>(result: result);

  static void showProcessingOverlay() {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      barrierDismissible: false,
    );
  }

  static void hideProcessingOverlay() {
    if (Get.isDialogOpen ?? false) {
      Get.back<void>();
    }
  }
}
