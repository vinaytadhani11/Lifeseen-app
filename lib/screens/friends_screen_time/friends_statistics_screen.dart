import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

class FriendsStatisticsScreen extends StatefulWidget {
  const FriendsStatisticsScreen({
    super.key,
    required this.uid,
    required this.name,
    required this.photo,
  });

  final String uid;
  final String name;
  final String photo;

  @override
  State<FriendsStatisticsScreen> createState() => _FriendsStatisticsScreenState();
}

class _FriendsStatisticsScreenState extends State<FriendsStatisticsScreen>
    with WidgetsBindingObserver {
  final _flow = FriendsFlowController.instance;
  DateTime _day = DateTime.now();
  ScreenTimeDay _data = const ScreenTimeDay();
  bool _loading = true;
  StreamSubscription<ScreenTimeDay>? _daySub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindDay();
    _load();
    _timer = Timer.periodic(FriendsFlowController.liveRefreshInterval, (_) {
      if (!isSameDay(_day, DateTime.now())) return;
      _load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _daySub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(silent: true);
  }

  void _bindDay() {
    _daySub?.cancel();
    _daySub = _flow.watchDay(widget.uid, _day).listen((stored) {
      if (!mounted) return;
      setState(() {
        _data = _flow.presentDay(widget.uid, _day, stored);
        _loading = false;
      });
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && _data.apps.isEmpty && mounted) {
      setState(() => _loading = true);
    }
    if (widget.uid == _flow.documentId && isSameDay(_day, DateTime.now())) {
      await _flow.refreshUsage();
    }
    try {
      final day = await _flow.dayFor(widget.uid, _day);
      if (!mounted) return;
      setState(() {
        _data = day;
        _loading = false;
      });
    } catch (error) {
      debugPrint('[Friends] statistics load failed: $error');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showDay(DateTime day) {
    _day = day;
    _data = const ScreenTimeDay();
    _bindDay();
    _load();
  }

  int get _total {
    if (!_data.hourlyEmpty) return totalMinutesFromHourly(_data.hourlyMinutes);
    return totalMinutesFromApps(_data.apps);
  }

  List<double> get _hourly {
    if (_data.hourlyMinutes.length == 24) return _data.hourlyMinutes;
    return List<double>.filled(24, 0);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.name.trim().isEmpty ? "Friends' Statistics" : widget.name;
    return LsScaffold(
      safeBottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          LsTopBar(onBack: () => Get.back<void>()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    LsAvatar(
                      index: title.hashCode.abs(),
                      size: 46,
                      photoUrl: widget.photo,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(20, FontWeight.w800)),
                          LsCaption('// statistics · ${statsDateLabel(_day)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LsSegmentedToggle(
                  labels: const ['Today', 'Calendar'],
                  icons: const [null, LsIconType.calendar],
                  index: 0,
                  onChanged: (i) async {
                    if (i == 0) {
                      _showDay(DateTime.now());
                      return;
                    }
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked == null) return;
                    _showDay(picked);
                  },
                ),
                const SizedBox(height: 12),
                LsWeekStrip(selected: _day, onSelect: _showDay),
                const SizedBox(height: 14),
                LsCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('TOTAL TIME', style: AppText.mono(10.5, FontWeight.w500, spacing: 1.05)),
                      const SizedBox(height: 2),
                      Text(formatTotalMinutes(_total), style: AppText.jakarta(22, FontWeight.w800)),
                      const SizedBox(height: 10),
                      LsAreaChart(values: _hourly),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.green)),
                  )
                else if (_data.apps.isEmpty)
                  const FlowEmptyText(emptyScreenTimeText)
                else
                  ..._data.apps.map((app) => ScreenTimeTile(app: app)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
