import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:tableflow_plus/models/local_plan_record.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/friends_database_service.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';

class FriendsFlowController extends ChangeNotifier {
  FriendsFlowController._();

  static final FriendsFlowController instance = FriendsFlowController._();

  final FriendsDatabaseService _db = FriendsDatabaseService.instance;

  ScreenTimeUser? user;
  bool accountLoadFailed = false;
  bool accountReady = false;
  List<ScreenTimeApp> todayApps = const [];
  List<double> todayHourly = List<double>.filled(24, 0);
  List<FriendChatPreview> chats = const [];
  String? selectedPlan = 'weekly';
  /// 0 persons · 1 history · 2 home · 3 messages
  int tabIndex = 2;
  String? activeChatId;

  void setTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  StreamSubscription<ScreenTimeUser?>? _userSub;
  StreamSubscription<List<FriendChatPreview>>? _chatSub;
  Timer? _liveTimer;
  bool _refreshing = false;
  final Map<String, double> _chatStamps = {};
  bool _chatStampsReady = false;

  static const liveRefreshInterval = Duration(seconds: 15);

  String get documentId => AppBootstrap.prefs.documentId;

  bool get hasActiveSubscription {
    final record = AppBootstrap.prefs.screenTimeSubscription;
    if (record == null || !record.active) return false;
    return !record.isExpired;
  }

  Future<void> prepareEntry() async {
    await _expireSubscriptionIfNeeded();
    accountLoadFailed = false;
    accountReady = documentId.isEmpty;
    if (documentId.isNotEmpty) {
      try {
        user = await _db.loadUser(documentId);
        accountLoadFailed = user == null;
        accountReady = user != null;
        if (user != null) {
          _listenUser();
          _listenChats();
        }
      } catch (error) {
        debugPrint('[Friends] user load failed: $error');
        accountLoadFailed = true;
        accountReady = false;
      }
    }
    notifyListeners();
  }

  void startLiveRefresh() {
    _liveTimer ??= Timer.periodic(liveRefreshInterval, (_) => refreshUsage());
    refreshUsage();
  }

  void stopLiveRefresh() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  Future<void> refreshUsage() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      if (!await UsageStatsService.hasPermission()) return;
      todayApps = await UsageStatsService.queryToday();
      todayHourly = await UsageStatsService.queryHourlyToday();
      if (documentId.isNotEmpty && todayApps.isNotEmpty) {
        try {
          final dayKey = screenTimeDayKey(DateTime.now());
          await _db.uploadToday(
            uid: documentId,
            dayKey: dayKey,
            apps: todayApps,
            hourly: todayHourly,
          );
        } catch (error) {
          debugPrint('[Friends] screen time upload failed: $error');
        }
      }
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  Stream<ScreenTimeDay> watchDay(String uid, DateTime day) {
    return _db.watchDay(uid, screenTimeDayKey(day));
  }

  ScreenTimeDay presentDay(String uid, DateTime day, ScreenTimeDay stored) {
    if (uid == documentId && isSameDay(day, DateTime.now())) {
      if (stored.apps.isEmpty) {
        return ScreenTimeDay(apps: todayApps, hourlyMinutes: todayHourly);
      }
      if (stored.hourlyEmpty) {
        return ScreenTimeDay(apps: stored.apps, hourlyMinutes: todayHourly);
      }
    }
    if (stored.hourlyEmpty && stored.apps.isNotEmpty) {
      return ScreenTimeDay(
        apps: stored.apps,
        hourlyMinutes: distributeAppsToHourly(stored.apps),
      );
    }
    return stored;
  }

  Future<ScreenTimeDay> dayFor(String uid, DateTime day) async {
    final stored = await _db.fetchDay(uid, screenTimeDayKey(day));
    return presentDay(uid, day, stored);
  }

  Future<bool> purchase(String planId, String planLabel, String packageId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final days = planId == 'monthly' ? 30 : 7;
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = LocalPlanRecord(
      planId: planId,
      planLabel: planLabel,
      packageId: packageId,
      purchaseDateMs: now,
      expiryDateMs: now + Duration(days: days).inMilliseconds,
      active: true,
      source: 'local',
    );
    await AppBootstrap.prefs.setScreenTimeSubscription(record);
    notifyListeners();
    return true;
  }

  Future<void> resetSubscription() async {
    await AppBootstrap.prefs.setScreenTimeSubscription(null);
    notifyListeners();
  }

  String newVerificationCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10).toString()).join();
  }

  Future<String> saveRegisteredUser({
    required String phone,
    required String username,
  }) async {
    final existingId = await _db.uidForPhone(phone);
    if (existingId == null) {
      user = await _db.createUser(phone: phone, username: username);
      await AppBootstrap.prefs.setDocumentId(user!.uid);
    } else {
      user = await _db.loadUser(existingId);
      user ??= ScreenTimeUser(
        uid: existingId,
        phone: phone,
        username: username,
      );
      await AppBootstrap.prefs.setDocumentId(user!.uid);
    }
    accountReady = true;
    accountLoadFailed = false;
    _listenUser();
    _listenChats();
    notifyListeners();
    return existingId == null ? 'SuccessRegister' : 'Login';
  }

  Future<void> savePhotoUrl(String url) async {
    if (documentId.isEmpty) return;
    await _db.updatePhoto(documentId, url);
  }

  Future<void> updateUsername(String name) async {
    if (documentId.isEmpty) return;
    await _db.updateUsername(documentId, name);
  }

  Future<({String status, String uid})> lookupPhone(String phone) async {
    final uid = await _db.uidForPhone(phone);
    if (uid == null) return (status: 'UserNotFound', uid: '');
    final them = await _db.loadUser(uid);
    final status = classifyLookup(them, documentId);
    return (status: status, uid: them?.uid ?? uid);
  }

  Future<void> sendRequest(String uid) => _db.sendRequest(documentId, uid);

  Future<void> accept(String uid) => _db.acceptRequest(documentId, uid);

  Future<void> reject(String uid) => _db.cancelOrReject(documentId, uid);

  Future<void> removeFriend(String uid) => _db.removeFriend(documentId, uid);

  Future<List<ScreenTimeUser>> peopleFor(Iterable<String> ids) =>
      _db.usersByIds(ids);

  Future<String> openChatId(ScreenTimeUser them) async {
    final me = user;
    if (me == null) return '';
    final chatId = _db.chatIdFor(me.uid, them.uid);
    await _db.ensureChat(chatId: chatId, me: me, them: them);
    return chatId;
  }

  Stream<List<FriendChatMessage>> messages(String chatId) =>
      _db.watchMessages(chatId, documentId);

  Future<void> sendText({
    required String chatId,
    required String otherUid,
    required String text,
  }) async {
    final me = user;
    if (me == null) return;
    await _db.sendText(
      chatId: chatId,
      myId: me.uid,
      text: text,
      me: me,
      otherUid: otherUid,
    );
  }

  Future<void> hideChat(String chatId) =>
      _db.hideChatForMe(chatId: chatId, myId: documentId);

  Future<void> logout() async {
    await _close();
    user = null;
    chats = const [];
    await AppBootstrap.prefs.clearFriendsSession();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final current = user;
    if (current != null) await _db.deleteAccount(current);
    await logout();
  }

  Future<void> _expireSubscriptionIfNeeded() async {
    final record = AppBootstrap.prefs.screenTimeSubscription;
    if (record != null && record.active && record.isExpired) {
      await AppBootstrap.prefs.setScreenTimeSubscription(
        record.copyWith(active: false),
      );
    }
  }

  void _listenUser() {
    _userSub?.cancel();
    if (documentId.isEmpty) return;
    _userSub = _db.watchUser(documentId).listen((next) {
      user = next;
      notifyListeners();
    });
  }

  void _listenChats() {
    _chatSub?.cancel();
    _chatStampsReady = false;
    _chatStamps.clear();
    if (documentId.isEmpty) return;
    _chatSub = _db.watchChats(documentId).listen((next) {
      if (_chatStampsReady) {
        final looking =
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
        for (final room in next) {
          final previous = _chatStamps[room.chatId] ?? 0;
          if (room.text.isEmpty || room.timestamp <= previous) continue;
          if (room.senderId.isEmpty || room.senderId == documentId) continue;
          if (looking && activeChatId == room.chatId) continue;
          NotificationScheduler.showFriendMessage(
            chatId: room.chatId,
            senderName: room.otherName,
            body: room.text,
          );
        }
      }
      _chatStamps
        ..clear()
        ..addEntries(next.map((room) => MapEntry(room.chatId, room.timestamp)));
      _chatStampsReady = true;
      chats = next;
      notifyListeners();
    });
  }

  Future<void> _close() async {
    stopLiveRefresh();
    await _userSub?.cancel();
    await _chatSub?.cancel();
    _userSub = null;
    _chatSub = null;
    _chatStampsReady = false;
    _chatStamps.clear();
    activeChatId = null;
  }
}
