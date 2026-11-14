import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_theme.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friend_chat_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_settings_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/home_tab.dart';
import 'package:tableflow_plus/screens/friends_screen_time/messages_tab.dart';
import 'package:tableflow_plus/screens/friends_screen_time/persons_tab.dart';
import 'package:tableflow_plus/screens/history/history_screen.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => HomeShellScreenState();
}

class HomeShellScreenState extends State<HomeShellScreen> with WidgetsBindingObserver {
  final _flow = FriendsFlowController.instance;
  final _history = NotificationHistory.instance;

  int _badge = 0;
  String? _historySummary;
  StreamSubscription<NhItem?>? _historySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flow.addListener(_onFlow);
    NotificationScheduler.onFriendMessageOpened = _openIncomingMessage;
    NotificationScheduler.requestNotificationPermission();
    _flow.startLiveRefresh();
    _historySub = _history.onChange.listen((item) {
      if (!mounted) return;
      if (item != null && _flow.tabIndex != 1) {
        setState(() => _badge++);
      }
      _loadHistorySummary();
    });
    _loadHistorySummary();
    final pending = NotificationScheduler.pendingFriendChatId;
    if (pending != null) {
      NotificationScheduler.pendingFriendChatId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openIncomingMessage(pending);
      });
    }
  }

  @override
  void dispose() {
    if (NotificationScheduler.onFriendMessageOpened == _openIncomingMessage) {
      NotificationScheduler.onFriendMessageOpened = null;
    }
    _historySub?.cancel();
    _flow.stopLiveRefresh();
    _flow.removeListener(_onFlow);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openIncomingMessage(String chatId) {
    if (_flow.documentId.isEmpty) return;
    _flow.setTab(3);
    for (final chat in _flow.chats) {
      if (chat.chatId != chatId) continue;
      Get.to<void>(
        () => FriendChatScreen(
          chatId: chat.chatId,
          otherUid: chat.otherUid,
          otherName: chat.otherName,
          otherPhoto: chat.otherPhoto,
        ),
      );
      return;
    }
  }

  void _onFlow() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _flow.startLiveRefresh();
      _loadHistorySummary();
    } else if (state == AppLifecycleState.paused) {
      _flow.stopLiveRefresh();
    }
  }

  Future<void> _loadHistorySummary() async {
    final granted = await _history.isNotificationAccessGranted();
    final stats = await _history.stats();
    if (!mounted) return;
    setState(() {
      _historySummary = !granted && stats.week == 0
          ? 'Turn on to save your notifications'
          : '${nhNumber(stats.today)} saved today · ${stats.appsOn} apps';
    });
  }

  void goTo(LsNavTab tab) {
    if (tab == LsNavTab.settings) {
      Get.to<void>(
        () => FriendsSettingsScreen(
          historySummary: _historySummary,
          onNotificationHistory: () {
            Get.back<void>();
            goTo(LsNavTab.history);
          },
        ),
      );
      return;
    }
    final index = switch (tab) {
      LsNavTab.persons => 0,
      LsNavTab.history => 1,
      LsNavTab.home => 2,
      LsNavTab.messages => 3,
      LsNavTab.settings => 2,
    };
    if (tab == LsNavTab.history && _badge != 0) {
      setState(() => _badge = 0);
    }
    if (_flow.tabIndex != index) _flow.setTab(index);
  }

  LsNavTab get _activeTab => switch (_flow.tabIndex) {
        0 => LsNavTab.persons,
        1 => LsNavTab.history,
        3 => LsNavTab.messages,
        _ => LsNavTab.home,
      };

  @override
  Widget build(BuildContext context) {
    final tab = _activeTab;
    return Theme(
      data: AppTheme.light,
      child: PopScope(
        canPop: tab == LsNavTab.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) goTo(LsNavTab.home);
        },
        child: LsShellScope(
          active: tab,
          historyBadge: _badge,
          goTo: goTo,
          child: LsScaffold(
            safeBottom: false,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _flow.tabIndex,
                    children: [
                      const PersonsTab(),
                      HistoryTab(showNav: false, service: _history),
                      HomeTab(
                        historySummary: _historySummary,
                        historyNew: _badge,
                        onNotificationHistory: () => goTo(LsNavTab.history),
                      ),
                      const MessagesTab(),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LsBottomNav(
                    active: tab,
                    historyBadge: _badge,
                    onTap: goTo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
