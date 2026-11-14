import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';

class SeeAllScreen extends StatefulWidget {
  const SeeAllScreen({super.key});

  @override
  State<SeeAllScreen> createState() => _SeeAllScreenState();
}

class _SeeAllScreenState extends State<SeeAllScreen> with WidgetsBindingObserver {
  final _flow = FriendsFlowController.instance;
  List<ScreenTimeApp> _apps = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _apps = _flow.todayApps;
    _flow.addListener(_sync);
    _load();
  }

  @override
  void dispose() {
    _flow.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    setState(() => _apps = _flow.todayApps);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (!await UsageStatsService.hasPermission()) {
      await UsageStatsService.openSettings();
      return;
    }
    final apps = await UsageStatsService.queryToday();
    if (!mounted) return;
    setState(() => _apps = apps);
  }

  @override
  Widget build(BuildContext context) {
    final total = _apps.fold<int>(0, (sum, app) => sum + app.sortSeconds);
    final now = DateTime.now();
    return LsScaffold(
      safeBottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LsTopBar(onBack: () => Get.back<void>()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Screen Time', style: AppText.h1),
                const SizedBox(height: 4),
                LsRichCaption([
                  ('// ${lsWeekdays[now.weekday - 1]} ${now.day.toString().padLeft(2, '0')} ${lsMonths[now.month - 1].substring(0, 3)} · ', false),
                  ('total ${compactMinutes(total)}', true),
                  (' · ${_apps.length} apps', false),
                ]),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Expanded(
            child: _apps.isEmpty
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: FlowEmptyText(emptyScreenTimeText))
                : ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.paddingOf(context).bottom),
                    children: _apps.map((app) => ScreenTimeTile(app: app)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
