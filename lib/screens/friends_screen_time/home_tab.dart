import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_gate.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_settings_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friendship_status_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/see_all_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    this.historySummary,
    this.historyNew = 0,
    this.onNotificationHistory,
  });

  final String? historySummary;
  final int historyNew;
  final VoidCallback? onNotificationHistory;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _flow = FriendsFlowController.instance;
  DateTime _selected = DateTime.now();
  List<ScreenTimeApp> _shown = const [];
  bool _loadingDay = false;

  @override
  void initState() {
    super.initState();
    _flow.addListener(_onFlow);
    _shown = _flow.todayApps;
  }

  @override
  void dispose() {
    _flow.removeListener(_onFlow);
    super.dispose();
  }

  void _onFlow() {
    if (!mounted) return;
    setState(() {
      if (isSameDay(_selected, DateTime.now())) {
        _shown = _flow.todayApps;
      }
    });
  }

  Future<void> _pickDate() async {
    if (_flow.documentId.isEmpty) {
      await showFlowToast('Register to see past days');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _selected = picked;
      _loadingDay = true;
    });
    final day = await _flow.dayFor(_flow.documentId, picked);
    if (!mounted) return;
    setState(() {
      _shown = isSameDay(picked, DateTime.now()) && day.apps.isEmpty
          ? _flow.todayApps
          : day.apps;
      _loadingDay = false;
    });
  }

  Future<void> _openUsageSettings() async {
    if (!await UsageStatsService.hasPermission()) {
      await UsageStatsService.openSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _flow.user;
    final showMenu = (user?.badgeCount ?? 0) > 0;
    final list = _flow.documentId.isEmpty ? const <ScreenTimeApp>[] : _shown;
    final totalSeconds = list.fold<int>(0, (sum, app) => sum + app.sortSeconds);
    final top = list.isEmpty
        ? null
        : list.reduce((a, b) => a.sortSeconds >= b.sortSeconds ? a : b);
    final inset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 130 + inset),
      children: [
        SizedBox(
          height: 42,
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: showMenu
                    ? LsHeaderButton(
                        icon: LsIconType.menu,
                        semanticLabel: 'Received requests',
                        onTap: () async {
                          if (!await passFriendsGate()) return;
                          await Get.to<void>(
                            () => const FriendshipStatusScreen(mode: FriendshipMode.requestsReceived),
                          );
                        },
                      )
                    : null,
              ),
              const Expanded(child: Center(child: LsWordmark(fontSize: 12, dotSize: 7))),
              _SettingsHeaderButton(
                onTap: () => Get.to<void>(
                  () => FriendsSettingsScreen(
                    historySummary: widget.historySummary,
                    onNotificationHistory: widget.onNotificationHistory == null
                        ? null
                        : () {
                            Get.back<void>();
                            widget.onNotificationHistory!();
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LsCaption('// today'),
                  const SizedBox(height: 2),
                  Text(
                    '${lsMonths[_selected.month - 1]}, ${_selected.year}',
                    style: AppText.jakarta(23, FontWeight.w800, spacing: -.3, height: 1.2),
                  ),
                ],
              ),
            ),
            LsHeaderButton(icon: LsIconType.calendar, semanticLabel: 'Calendar', onTap: _pickDate),
          ],
        ),
        const SizedBox(height: 12),
        LsWeekStrip(selected: _selected, onSelect: (day) => _show(day)),
        const SizedBox(height: 18),
        _AddFriendCard(
          onTap: () async {
            if (!await passFriendsGate()) return;
            _flow.setTab(0);
          },
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            await _openUsageSettings();
            if (!context.mounted) return;
            await Get.to<void>(() => const SeeAllScreen());
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: const LinearGradient(colors: [AppColors.white, AppColors.usageEnd]),
              border: Border.all(color: AppColors.stroke),
            ),
            child: Row(
              children: [
                LsProgressRing(
                  value: list.isEmpty ? 0 : (totalSeconds / (4.5 * 3600)).clamp(0.02, 1),
                  size: 116,
                  stroke: 9,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_ringLabel(totalSeconds), style: AppText.jakarta(22, FontWeight.w800, height: 1.1)),
                      const SizedBox(height: 2),
                      Text('TOTAL', style: AppText.mono(10, FontWeight.w500, spacing: 1.2)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Statistics', style: AppText.jakarta(17, FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Examine the screen time graph', style: AppText.small),
                      const SizedBox(height: 8),
                      if (list.isEmpty)
                        const LsPill('no data yet', variant: LsPillVariant.off)
                      else ...[
                        const LsPill('live', dot: true),
                        if (top != null) ...[
                          const SizedBox(height: 8),
                          Text('TOP · ${top.name.toUpperCase()}', style: AppText.mono(11, FontWeight.w500, spacing: .5)),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            if (!await passFriendsGate()) return;
            await Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.friendsStatics));
          },
          child: LsCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const LsIconChip(LsIconType.trend, color: AppColors.indigo, size: 44, radius: 13, iconSize: 21),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Friends' Statistics", style: AppText.jakarta(15.5, FontWeight.w700)),
                      Text('Review the statistical details of your friends', style: AppText.small),
                    ],
                  ),
                ),
                const LsIcon(LsIconType.chevron, size: 16, color: AppColors.text),
              ],
            ),
          ),
        ),
        if (widget.historySummary != null && widget.onNotificationHistory != null) ...[
          const SizedBox(height: 10),
          _HistoryRow(
            summary: widget.historySummary!,
            historyNew: widget.historyNew,
            onTap: widget.onNotificationHistory!,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('SCREEN TIME', style: AppText.mono(11, FontWeight.w700, spacing: 1.1))),
            GestureDetector(
              onTap: () => Get.to<void>(() => const SeeAllScreen()),
              child: Text('SEE ALL →', style: AppText.mono(11, FontWeight.w700, color: AppColors.green, spacing: 1.1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingDay)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppColors.green)),
          )
        else if (list.isEmpty)
          const FlowEmptyText(emptyScreenTimeText)
        else
          ...list.take(4).map((app) => ScreenTimeTile(app: app)),
      ],
    );
  }

  Future<void> _show(DateTime day) async {
    if (isSameDay(day, DateTime.now())) {
      setState(() {
        _selected = day;
        _shown = _flow.todayApps;
      });
      return;
    }
    if (_flow.documentId.isEmpty) {
      await showFlowToast('Register to see past days');
      return;
    }
    setState(() {
      _selected = day;
      _loadingDay = true;
    });
    final loaded = await _flow.dayFor(_flow.documentId, day);
    if (!mounted) return;
    setState(() {
      _shown = loaded.apps;
      _loadingDay = false;
    });
  }

  String _ringLabel(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h == 0 ? '${m}m' : '${h}h ${m}m';
  }
}

class _SettingsHeaderButton extends StatelessWidget {
  const _SettingsHeaderButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Settings',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: .10),
                offset: const Offset(0, 3),
                blurRadius: 10,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Image.asset(
            LsArts.settingsGear,
            width: 20,
            height: 20,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.summary,
    required this.historyNew,
    required this.onTap,
  });

  final String summary;
  final int historyNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasNew = historyNew > 0;
    return GestureDetector(
      onTap: onTap,
      child: LsCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Container(
          decoration: hasNew
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.neon.withValues(alpha: .55)),
                )
              : null,
          padding: hasNew ? const EdgeInsets.all(2) : EdgeInsets.zero,
          child: Row(
            children: [
              const LsIconChip(LsIconType.bell, color: AppColors.green, size: 44, radius: 13, iconSize: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notification History', style: AppText.jakarta(15.5, FontWeight.w700)),
                    Text(summary, style: AppText.small),
                  ],
                ),
              ),
              if (hasNew) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neon,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$historyNew NEW',
                    style: AppText.mono(10, FontWeight.w700, color: AppColors.ink, spacing: .6),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const LsIcon(LsIconType.chevron, size: 16, color: AppColors.text),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFriendCard extends StatelessWidget {
  const _AddFriendCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: LinearGradient(
            colors: [
              Color.alphaBlend(AppColors.neon.withValues(alpha: .16), AppColors.bg),
              Color.alphaBlend(AppColors.aqua.withValues(alpha: .06), AppColors.bg),
            ],
          ),
          border: Border.all(color: AppColors.neon.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Friend', style: AppText.jakarta(17, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text("Add to track your friends' screen time", style: AppText.jakarta(12.5, FontWeight.w400, color: AppColors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const LsArt(LsArts.envelopeAdd, height: 52, width: 64),
          ],
        ),
      ),
    );
  }
}

