// LifeSeen – History tab · Light Green theme
//   access off            → S31 intro → S32 guide → S33 choose apps
//   on, nothing saved yet → S38 empty ("Choose Apps")
//   on, with items        → S34 Notification History (stats, chips, search, list)
// Updates live from the native listener and re-checks access on app resume.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';

import 'app_history_screen.dart';
import 'choose_apps_screen.dart';
import 'history_settings_screen.dart';
import 'notification_access_screen.dart';
import 'thread_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, this.service, this.showNav = true});
  final NotificationHistory? service;
  final bool showNav;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> with WidgetsBindingObserver {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;

  bool _loading = true;
  bool _granted = false;
  int _enabledCount = 0;
  NhSettings _settings = const NhSettings();
  NhStats _stats = const NhStats();
  List<NhItem> _items = const [];
  String? _filter; // package
  String _query = '';
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<NhItem?>? _sub;

  /// Items newer than this get the green "unread" dot.
  DateTime _seenAt = DateTime.now();
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = _svc.onChange.listen((_) => _scheduleReload());
    _reload();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = LsShellScope.maybeOf(context)?.active == LsNavTab.history;
    if (_wasActive && !active) _seenAt = DateTime.now(); // leaving the tab marks everything read
    if (!_wasActive && active) _reload();
    _wasActive = active;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  void _scheduleReload() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  Future<void> _reload() async {
    final granted = await _svc.isNotificationAccessGranted();
    final enabled = await _svc.enabledApps();
    final settings = await _svc.settings();
    final stats = await _svc.stats();
    final items = await _svc.items(package: _filter, search: _query.isEmpty ? null : _query);
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _enabledCount = enabled.length;
      _settings = settings;
      _stats = stats;
      _items = items;
      _loading = false;
    });
  }

  Future<void> _turnOn() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => TurnOnAccessScreen(service: widget.service)));
    if (ok == true && mounted) {
      if (_enabledCount == 0) await _chooseApps();
      await _reload();
    }
  }

  Future<void> _chooseApps() => Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (ctx) => ChooseAppsScreen(service: widget.service, onSaved: (_) => Navigator.of(ctx).pop()),
      )).then((_) => _reload());

  void _openThread(NhItem i) => Navigator.of(context)
      .push<void>(MaterialPageRoute(
        builder: (_) => ThreadScreen(service: widget.service, package: i.package, appName: i.appName, title: i.title),
      ))
      .then((_) => _reload());

  void _openApp(String pkg, String name) => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => AppHistoryScreen(service: widget.service, package: pkg, appName: name)))
      .then((_) => _reload());

  void _openSettings() => Navigator.of(context)
      .push<void>(MaterialPageRoute(builder: (_) => HistorySettingsScreen(service: widget.service)))
      .then((_) => _reload());

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return LsScaffold(
        safeBottom: false,
        child: Stack(children: [
          const Center(child: CircularProgressIndicator(color: AppColors.neon, strokeWidth: 3)),
          if (widget.showNav) const Positioned(left: 0, right: 0, bottom: 0, child: LsBottomNav(active: LsNavTab.history)),
        ]),
      );
    }
    if (!_granted) return NotificationAccessIntro(onAllow: _turnOn, showNav: widget.showNav);

    final empty = _stats.week == 0 && _items.isEmpty && _query.isEmpty && _filter == null;
    final inset = MediaQuery.paddingOf(context).bottom;

    return LsScaffold(
      safeBottom: false,
      child: Stack(children: [
        Positioned.fill(
          child: RefreshIndicator(
            color: AppColors.green,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 130 + inset),
              children: [
                LsTopBar(
                  right: LsHeaderButton(
                    icon: LsIconType.gear,
                    onTap: _openSettings,
                    semanticLabel: 'History settings',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Notification History', style: AppText.h1),
                    const SizedBox(height: 4),
                    LsRichCaption([
                      ('// ', false),
                      ('${nhNumber(_stats.today)} saved today', _stats.today > 0),
                      (' · $_enabledCount apps', false),
                    ]),
                  ]),
                ),
                if (empty)
                  _Empty(onChoose: _chooseApps)
                else ...[
                  if (_settings.paused)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      child: _PausedBanner(onResume: () async {
                        await _svc.saveSettings(_settings.copyWith(paused: false));
                        await _reload();
                      }),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: _StatsCard(stats: _stats, appsOn: _enabledCount),
                  ),
                  NhChips(
                    selected: _filter,
                    onSelect: (id) {
                      setState(() => _filter = id);
                      _reload();
                    },
                    chips: [
                      NhChip(null, 'All', _stats.today),
                      for (final a in _stats.perApp) NhChip(a.package, a.appName, a.count),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      LsTextField(
                        controller: _search,
                        hint: 'Search notifications',
                        icon: LsIconType.search,
                        onChanged: (v) {
                          _query = v.trim();
                          _scheduleReload();
                        },
                      ),
                      if (_filter != null) ...[
                        const SizedBox(height: 10),
                        _OpenAppRow(
                          package: _filter!,
                          name: _stats.perApp.firstWhere((a) => a.package == _filter, orElse: () => NhAppCount(_filter!, _filter!, 0)).appName,
                          service: widget.service,
                          onTap: _openApp,
                        ),
                      ],
                      ..._grouped(),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.showNav) const Positioned(left: 0, right: 0, bottom: 0, child: LsBottomNav(active: LsNavTab.history)),
      ]),
    );
  }

  List<Widget> _grouped() {
    if (_items.isEmpty) {
      return [
        const SizedBox(height: 16),
        LsEmptyCard(
          icon: LsIconType.search,
          text: _query.isNotEmpty ? 'No notifications match "$_query".' : 'No notifications saved for this app yet.',
        ),
      ];
    }
    final out = <Widget>[];
    String? day;
    var n = 0;
    for (final i in _items) {
      final d = nhDayLabel(i.time);
      if (d != day) {
        day = d;
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
          child: Text(d.toUpperCase(), style: AppText.mono(11, FontWeight.w700, spacing: 1.1)),
        ));
      } else {
        out.add(const SizedBox(height: 10));
      }
      out.add(LsReveal(
        delay: n < 8 ? n * 40 : 0,
        child: NhNotificationCard(item: i, unread: i.time.isAfter(_seenAt), service: widget.service, onTap: () => _openThread(i)),
      ));
      n++;
    }
    return out;
  }
}

// ----------------------------------------------------------------------------
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats, required this.appsOn});
  final NhStats stats;
  final int appsOn;

  @override
  Widget build(BuildContext context) {
    Widget cell(String k, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: AppText.mono(10, FontWeight.w500, spacing: 1)),
          Text(v, style: AppText.jakarta(21, FontWeight.w800, height: 1.2)),
        ]);
    return LsCard(
      padding: const EdgeInsets.all(14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: cell('TODAY', nhNumber(stats.today))),
        Expanded(child: cell('THIS WEEK', nhNumber(stats.week))),
        Expanded(child: cell('APPS', '$appsOn')),
        NhBars(values: stats.last7, highlight: 6),
      ]),
    );
  }
}

class _OpenAppRow extends StatelessWidget {
  const _OpenAppRow({required this.package, required this.name, required this.onTap, this.service});
  final String package, name;
  final void Function(String, String) onTap;
  final NotificationHistory? service;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(package, name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Color.alphaBlend(AppColors.neon.withValues(alpha: .08), AppColors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.neon.withValues(alpha: .4)),
          ),
          child: Row(children: [
            NhAppIcon(package: package, name: name, size: 28, service: service),
            const SizedBox(width: 10),
            Expanded(child: Text('Open $name history', style: AppText.jakarta(13.5, FontWeight.w700))),
            Text('CHATS · HOURS →', style: AppText.mono(10.5, FontWeight.w700, color: AppColors.green, spacing: .8)),
          ]),
        ),
      );
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.onResume});
  final VoidCallback onResume;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.amberFill.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amberFill.withValues(alpha: .5)),
        ),
        child: Row(children: [
          const LsIcon(LsIconType.pause, size: 18, color: AppColors.amber, stroke: 2),
          const SizedBox(width: 10),
          Expanded(child: Text('Saving is paused. New notifications are not saved.', style: AppText.jakarta(13, FontWeight.w600, color: AppColors.amber))),
          GestureDetector(
            onTap: onResume,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text('RESUME', style: AppText.mono(11, FontWeight.w700, color: AppColors.green, spacing: 1)),
            ),
          ),
        ]),
      );
}

/// S38 – nothing saved yet.
class _Empty extends StatelessWidget {
  const _Empty({required this.onChoose});
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(children: [
          const LsArt(LsArts.noNotifications, height: 300, fit: BoxFit.contain),
          const SizedBox(height: 18),
          LsCta(label: 'Choose Apps', icon: LsIconType.grid, onPressed: onChoose, centerLabel: true),
        ]),
      );
}
