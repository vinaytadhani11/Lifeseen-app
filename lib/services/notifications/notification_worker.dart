import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableflow_plus/core/constants/pref_keys.dart';
import 'package:tableflow_plus/services/notifications/notification_constants.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:workmanager/workmanager.dart';

/// WorkManager entry point — mirrors Android `NotificationWorker`.
@pragma('vm:entry-point')
void notificationWorkDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    final id = int.tryParse('${inputData?['id'] ?? ''}');
    final title = inputData?['title']?.toString() ?? '';
    final body = inputData?['body']?.toString() ?? '';
    if (id == null || title.isEmpty) return true;

    await _showLocalNotification(id: id, title: title, body: body);

    // Last reminder restarts the whole 8-notification chain.
    if (id == NotificationConstants.idVoice3) {
      final prefs = await SharedPreferences.getInstance();
      final premium = prefs.getBool(PrefKeys.isUserPremium) ?? false;
      final enabled =
          prefs.getBool(PrefKeys.notificationRemindersEnabled) ?? false;
      final phone = prefs.getString(PrefKeys.notificationPhoneNumber) ?? '';
      if (!premium && enabled && phone.isNotEmpty) {
        // Reschedule with the saved (already masked) phone — same as Android.
        await NotificationScheduler.scheduleNotifications(phone);
      }
    }
    return true;
  });
}

Future<void> _showLocalNotification({
  required int id,
  required String title,
  required String body,
}) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );

  const androidDetails = AndroidNotificationDetails(
    NotificationConstants.channelId,
    NotificationConstants.channelName,
    channelDescription: NotificationConstants.channelDescription,
    importance: Importance.high,
    priority: Priority.high,
    groupKey: NotificationConstants.groupKey,
    category: AndroidNotificationCategory.message,
  );

  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: NotificationConstants.tapPayload,
  );
}
