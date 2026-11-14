// LifeSeen – S35 App History (e.g. WhatsApp) · Light Green theme
// Hourly chart for today + chats grouped by sender, or every saved notification.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';

import 'history_settings_screen.dart';
import 'thread_screen.dart';

class AppHistoryScreen extends StatefulWidget {
  const AppHistoryScreen({super.key, required this.package, required this.appName, this.service});
  final String package, appName;
  final NotificationHistory? service;

  @override
  State<AppHistoryScreen> createState() => _AppHistoryScreenState();
}

class _AppHistoryScreenState extends State<AppHistoryScreen> {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  NhAppDetail? _detail;
  List<NhItem> _all = const [];
  bool _saving = true;
  int _tab = 0; // 0 chats, 1 all
  StreamSubscription<NhItem?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _svc.onChange.listen((i) {
      if (i == null || i.package == widget.package) _load();
    });
    _load();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await _svc.appDetail(widget.package);
    final all = await _svc.items(package: widget.package);
    final enabled = await _svc.enabledApps();
    final s = await _svc.settings();
    if (!mounted) return;
    setState(() {
      _detail = d;
      _all = all;
      _saving = enabled.contains(widget.package) && !s.paused;
    });
  }

  void _openThread(String title) => Navigator.of(context)
      .push<void>(MaterialPageRoute(
        builder: (_) => ThreadScreen(service: widget.service, package: widget.package, appName: widget.appName, title: title),
      ))
      .then((_) => _load());

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final peak = d == null ? 0 : d.hourly.indexOf(d.hourly.reduce((a, b) => a > b ? a : b));
    final hasToday = d != null && d.today > 0;

    return LsScaffold(
      safeBottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          LsTopBar(
            onBack: () => Navigator.of(context).maybePop(),
            right: LsHeaderButton(
              icon: LsIconType.gear,
              semanticLabel: 'History settings',
              onTap: () => Navigator.of(context)
                  .push<void>(MaterialPageRoute(builder: (_) => HistorySettingsScreen(service: widget.service)))
                  .then((_) => _load()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                NhAppIcon(package: widget.package, name: widget.appName, size: 52, service: widget.service),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(22, FontWeight.w800)),
                    LsRichCaption([
                      ('// ', false),
                      ('${nhNumber(d?.today ?? 0)} today', true),
                      (' · ${d?.threads.length ?? 0} chats', false),
                    ]),
                  ]),
                ),
                _saving
                    ? const LsPill('saving', dot: true)
                    : const LsPill('not saving', variant: LsPillVariant.off),
              ]),
              const SizedBox(height: 14),
              LsCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text('NOTIFICATIONS BY HOUR', style: AppText.mono(10.5, FontWeight.w500, spacing: 1.05))),
                    if (hasToday)
                      Text('PEAK ${peak.toString().padLeft(2, '0')}:00', style: AppText.mono(11, FontWeight.w700, color: AppColors.green)),
                  ]),
                  const SizedBox(height: 10),
                  LayoutBuilder(builder: (_, c) {
                    const gap = 4.0;
                    final w = (c.maxWidth - gap * 23) / 24;
                    return NhBars(values: d?.hourly ?? List.filled(24, 0), highlight: hasToday ? peak : -1, height: 70, barWidth: w, gap: gap);
                  }),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (final l in const ['00', '06', '12', '18', '23']) Text(l, style: AppText.mono(9.5, FontWeight.w400)),
                  ]),
                ]),
              ),
              const SizedBox(height: 12),
              LsSegmentedToggle(
                labels: ['Chats', 'All ${nhNumber(d?.total ?? 0)}'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: 12),
              if (d == null)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.neon, strokeWidth: 3)),
                )
              else if (d.threads.isEmpty)
                const LsEmptyCard(icon: LsIconType.bell, text: 'Nothing saved from this app yet. New notifications will appear here.')
              else if (_tab == 0)
                for (var i = 0; i < d.threads.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  LsReveal(delay: i < 8 ? i * 40 : 0, child: _ThreadRow(t: d.threads[i], onTap: () => _openThread(d.threads[i].title))),
                ]
              else
                for (var i = 0; i < _all.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  NhNotificationCard(item: _all[i], service: widget.service, onTap: () => _openThread(_all[i].title)),
                ],
            ]),
          ),
        ],
      ),
    );
  }
}

String _previewText(String raw) {
  final tail = raw.contains(': ') ? raw.split(': ').last : raw;
  if (nhIsMediaPlaceholder(tail) || raw.contains('📷')) return '📷 Photo';
  return raw;
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({required this.t, required this.onTap});
  final NhThread t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: LsCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            NhLetterAvatar(name: t.title, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Flexible(child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(15.5, FontWeight.w700))),
                  if (t.removed > 0) ...[const SizedBox(width: 6), NhRemovedTag(text: '${t.removed} removed')],
                ]),
                Text(
                  _previewText(t.lastText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small,
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              Text(nhShortWhen(t.lastTime), style: AppText.mono(11, FontWeight.w500)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: AppColors.neon.withValues(alpha: .12), borderRadius: BorderRadius.circular(8)),
                child: Text(nhNumber(t.count), style: AppText.mono(11, FontWeight.w700, color: AppColors.green)),
              ),
            ]),
          ]),
        ),
      );
}
