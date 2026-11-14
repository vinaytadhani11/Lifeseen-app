import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tableflow_plus/core/constants/pref_keys.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/services/app_prefs_service.dart';
import 'package:tableflow_plus/services/firebase/firebase_remote_config_service.dart';
import 'package:tableflow_plus/services/notifications/notification_constants.dart';
import 'package:tableflow_plus/services/notifications/notification_item.dart';
import 'package:tableflow_plus/services/notifications/notification_worker.dart';
import 'package:workmanager/workmanager.dart';

/// Local WorkManager reminders for the WhatsApp flow only (`page_log = 1`).
/// Not used by Friends / Screen Time. Not FCM.
class NotificationScheduler {
  NotificationScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function() _openSplashScreen = _splashNotBound;
  static void Function(String chatId)? onFriendMessageOpened;
  static String? pendingFriendChatId;

  /// Wired from `main` so this file does not import the splash screen.
  static void bindSplashOpener(void Function() opener) {
    _openSplashScreen = opener;
  }

  static void _splashNotBound() {
    debugPrint('[NotificationScheduler] splash opener is not bound');
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onReminderTapped,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.channelId,
        NotificationConstants.channelName,
        description: NotificationConstants.channelDescription,
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationConstants.friendChannelId,
        NotificationConstants.friendChannelName,
        description: NotificationConstants.friendChannelDescription,
        importance: Importance.high,
      ),
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Workmanager().initialize(notificationWorkDispatcher);
    }

    _initialized = true;
  }

  /// App was opened from a killed state by a reminder. Home is already Splash.
  static Future<void> consumeLaunchNotification() async {
    if (kIsWeb) return;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return;
    final payload = details?.notificationResponse?.payload ?? '';
    if (payload.startsWith(NotificationConstants.friendPayloadPrefix)) {
      _openFriendMessage(payload);
      return;
    }
    if (payload != NotificationConstants.tapPayload) return;
    _openSplash();
  }

  static void _onReminderTapped(NotificationResponse response) {
    final payload = response.payload ?? '';
    if (payload.startsWith(NotificationConstants.friendPayloadPrefix)) {
      _openFriendMessage(payload);
      return;
    }
    if (payload != NotificationConstants.tapPayload) return;
    _openSplash();
  }

  static void _openFriendMessage(String payload) {
    final chatId =
        payload.substring(NotificationConstants.friendPayloadPrefix.length);
    if (chatId.isEmpty) return;
    final opener = onFriendMessageOpened;
    if (opener == null) {
      pendingFriendChatId = chatId;
      return;
    }
    opener(chatId);
  }

  /// Heads-up alert for the person who received a Friends chat message.
  static Future<void> showFriendMessage({
    required String chatId,
    required String senderName,
    required String body,
  }) async {
    await initialize();
    if (!await notificationsEnabled()) return;
    final title = senderName.trim().isEmpty ? 'New message' : senderName.trim();
    final androidDetails = AndroidNotificationDetails(
      NotificationConstants.friendChannelId,
      NotificationConstants.friendChannelName,
      channelDescription: NotificationConstants.friendChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(body),
    );
    await _plugin.show(
      id: 93000 + ((chatId.hashCode & 0x7fffffff) % 10000),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: '${NotificationConstants.friendPayloadPrefix}$chatId',
    );
  }

  static void _openSplash() {
    debugPrint('[NotificationScheduler] reminder tap → Splash');
    _openSplashScreen();
  }

  /// Gate used by chat list / settings: schedule or cancel from RC + premium.
  static Future<void> syncForWhatsAppFlow({
    required AppPrefsService prefs,
    required FirebaseRemoteConfigService remoteConfig,
  }) async {
    final shouldSchedule =
        remoteConfig.config.notification == 1 && !prefs.isUserPremium;
    if (shouldSchedule) {
      await scheduleNotifications(wpLoginNumber(prefs));
    } else {
      await cancelAll();
    }
  }

  /// Full WhatsApp login number used for the title mask (`+dial` + digits).
  static String wpLoginNumber(AppPrefsService prefs) {
    final digits = (prefs.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final iso = prefs.phoneCountryIso ?? defaultCountry.isoCode;
    final country = countries.firstWhere(
      (c) => c.isoCode == iso,
      orElse: () => defaultCountry,
    );
    if (digits.isEmpty) return '';
    return '+${country.dialCode}$digits';
  }

  /// Schedules all 8 OneTime works with REPLACE policy.
  /// [phone] is `prefs.wpLoginNumber` (or already-masked phone on loop).
  static Future<void> scheduleNotifications(String phone) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(PrefKeys.isUserPremium) ?? false;
    if (isPremium) {
      await cancelAll();
      return;
    }

    final masked = maskPhone(phone);
    // Full phone kept for prefs; display uses mask. On loop, [phone] may
    // already be masked — maskPhone keeps it stable when length > 7.
    final savedPhone = phone.trim().isEmpty ? masked : phone.trim();
    await prefs.setString(PrefKeys.notificationPhoneNumber, savedPhone);
    await prefs.setBool(PrefKeys.notificationRemindersEnabled, true);

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    for (final item in NotificationItem.items) {
      final title = '$masked ${item.title}';
      await Workmanager().registerOneOffTask(
        NotificationConstants.uniqueName(item.id),
        NotificationConstants.uniqueName(item.id),
        initialDelay: item.delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        inputData: <String, dynamic>{
          'id': item.id,
          'title': title,
          'body': item.subtitle,
        },
        constraints: Constraints(networkType: NetworkType.notRequired),
      );
    }
    debugPrint('[NotificationScheduler] scheduled 8 reminders for $masked');
  }

  /// Cancels unique works 1001…1008 and clears saved notification phone.
  /// Does not remove already-shown tray notifications.
  static Future<void> cancelAll() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.notificationRemindersEnabled, false);
    await prefs.remove(PrefKeys.notificationPhoneNumber);

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    for (final id in NotificationConstants.allIds) {
      await Workmanager().cancelByUniqueName(
        NotificationConstants.uniqueName(id),
      );
    }
    debugPrint('[NotificationScheduler] cancelled all reminder works');
  }

  /// Posts one reminder immediately, using the same channel, group and tap
  /// payload as the WorkManager worker. Does not change the scheduled chain.
  static Future<bool> showTestNotification({
    required NotificationItem item,
    required String phone,
  }) async {
    await initialize();
    if (!await _notificationsAllowed()) return false;

    final title = '${maskPhone(phone)} ${item.title}';
    const androidDetails = AndroidNotificationDetails(
      NotificationConstants.channelId,
      NotificationConstants.channelName,
      channelDescription: NotificationConstants.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: NotificationConstants.groupKey,
      category: AndroidNotificationCategory.message,
    );
    await _plugin.show(
      id: item.id,
      title: title,
      body: item.subtitle,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: NotificationConstants.tapPayload,
    );
    debugPrint('[NotificationScheduler] test sent id=${item.id}');
    return true;
  }

  static Future<bool> _notificationsAllowed() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final enabled = await android.areNotificationsEnabled();
    if (enabled ?? false) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  static Future<bool> notificationsEnabled() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    return await android.areNotificationsEnabled() ?? false;
  }

  /// Register screen shows the same 6-digit code. Only when permission is on.
  static Future<void> showVerificationCode(String code) async {
    await initialize();
    const androidDetails = AndroidNotificationDetails(
      'verification_code',
      'Verification code',
      channelDescription: 'Shows the local registration code',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: 91001,
      title: 'Verification Code',
      body: code,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  /// Android 13+: ask POST_NOTIFICATIONS. Call when MessagesReady dialog
  /// closes and user is not premium. Deny still allows jobs; show may fail.
  static Future<void> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// First 7 characters + `*******`. Example: `+919979927307` → `+91997*******`.
  static String maskPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '*******';
    if (trimmed.length <= 7) return trimmed;
    return '${trimmed.substring(0, 7)}*******';
  }
}
