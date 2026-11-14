// LifeSeen – S37 History Settings · Light Green theme

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/premium_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:tableflow_plus/screens/history/history_ui.dart';

import 'choose_apps_screen.dart';

class HistorySettingsScreen extends StatefulWidget {
  const HistorySettingsScreen({super.key, this.service});
  final NotificationHistory? service;

  @override
  State<HistorySettingsScreen> createState() => _HistorySettingsScreenState();
}

class _HistorySettingsScreenState extends State<HistorySettingsScreen> with WidgetsBindingObserver {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  bool? _granted;
  int _apps = 0;
  NhSettings _s = const NhSettings();
  NhStorage _storage = const NhStorage();

  static const _retention = [7, 30, 0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final g = await _svc.isNotificationAccessGranted();
    final apps = await _svc.enabledApps();
    final s = await _svc.settings();
    final st = await _svc.storage();
    if (!mounted) return;
    var next = s;
    // Forever requires an active Premium subscription.
    if (next.retentionDays == 0 && !FriendsFlowController.instance.hasActiveSubscription) {
      next = next.copyWith(retentionDays: 30);
      await _svc.saveSettings(next);
    }
    if (!mounted) return;
    setState(() {
      _granted = g;
      _apps = apps.length;
      _s = next;
      _storage = st;
    });
  }

  Future<void> _update(NhSettings s) async {
    setState(() => _s = s);
    await _svc.saveSettings(s);
  }

  bool get _premium => FriendsFlowController.instance.hasActiveSubscription;

  Future<void> _setRetention(int index) async {
    final days = _retention[index];
    if (days == 0 && !_premium) {
      await Get.to<void>(() => const PremiumScreen());
      if (!mounted) return;
      if (FriendsFlowController.instance.hasActiveSubscription) {
        await _update(_s.copyWith(retentionDays: 0));
      }
      setState(() {});
      return;
    }
    await _update(_s.copyWith(retentionDays: days));
  }

  Future<void> _openPremium() async {
    await Get.to<void>(() => const PremiumScreen());
    if (mounted) setState(() {});
  }

  Future<void> _clear() async {
    final ok = await showLsConfirm(
      context,
      title: 'Clear history?',
      message:
          'All ${nhNumber(_storage.count)} notifications and ${nhNumber(_storage.images)} images will be deleted from this phone. This cannot be undone.',
      confirmLabel: 'Clear',
    );
    if (!ok) return;
    await _svc.clearAll();
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text('History cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = _granted == true;
    return LsScaffold(
      safeBottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 30 + MediaQuery.paddingOf(context).bottom),
        children: [
          LsTopBar(onBack: () => Navigator.of(context).maybePop()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('History Settings', style: AppText.h1),
              const SizedBox(height: 4),
              LsRichCaption([('// notification access · ', false), (_granted == null ? '…' : (on ? 'on' : 'off'), on)]),
              const SizedBox(height: 14),
              // access card
              LsCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    const LsArt(LsArts.iconBell, height: 44, width: 44, fit: BoxFit.contain),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text('Notification access', style: AppText.jakarta(15.5, FontWeight.w700)),
                        Text(on ? 'Reading notifications from $_apps apps' : 'Turn it on to save notifications', style: AppText.small),
                      ]),
                    ),
                    on ? const LsPill('on', variant: LsPillVariant.fill) : const LsPill('off', variant: LsPillVariant.amber),
                  ]),
                  const SizedBox(height: 12),
                  LsSmallCta(
                    label: 'Manage in Android settings',
                    icon: LsIconType.gear,
                    variant: LsSmallCtaVariant.ghost,
                    onPressed: () async {
                      await _svc.openNotificationAccessSettings();
                      if (_svc.isDemo) await _load();
                    },
                  ),
                ]),
              ),
              _label('Saving'),
              _group([
                _row(
                  art: LsArts.iconApps,
                  title: 'Apps to save',
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('$_apps apps', style: AppText.mono(13, FontWeight.w700, color: AppColors.text)),
                    const SizedBox(width: 8),
                    const LsIcon(LsIconType.chevron, size: 17, color: AppColors.muted, stroke: 1.9),
                  ]),
                  onTap: () => Navigator.of(context)
                      .push<void>(MaterialPageRoute(
                        builder: (ctx) => ChooseAppsScreen(service: widget.service, onSaved: (_) => Navigator.of(ctx).pop()),
                      ))
                      .then((_) => _load()),
                ),
                _row(
                  art: LsArts.iconPause,
                  title: 'Pause saving',
                  subtitle: 'Stop saving until you turn it back on',
                  onTap: () => _update(_s.copyWith(paused: !_s.paused)),
                  trailing: LsSwitch(
                    value: _s.paused,
                    onChanged: (v) => _update(_s.copyWith(paused: v)),
                    semanticLabel: 'Pause saving',
                  ),
                ),
              ]),
              _label('Keep history for'),
              _RetentionToggle(
                index: _retention.indexOf(_s.retentionDays).clamp(0, 2),
                premium: _premium,
                onChanged: _setRetention,
              ),
              if (!_premium) ...[
                const SizedBox(height: 12),
                _ForeverUnlockBanner(onUnlock: _openPremium),
              ] else if (_s.retentionDays == 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const LsArt(LsArts.crownTile, height: 16, width: 16, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Text(
                      'Premium · old notifications are never deleted',
                      style: AppText.mono(11, FontWeight.w600, color: AppColors.goldBottom, spacing: .2),
                    ),
                  ],
                ),
              ],
              _label('Storage'),
              LsCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        '${nhNumber(_storage.count)} notifications',
                        // '${nhNumber(_storage.count)} notifications · ${nhNumber(_storage.images)} images',
                        style: AppText.jakarta(15, FontWeight.w700),
                      ),
                    ),
                    Text(nhBytes(_storage.bytes), style: AppText.mono(12, FontWeight.w700, color: AppColors.green)),
                  ]),
                  const SizedBox(height: 8),
                  LsUsageBar(value: (_storage.bytes / (500 * 1024 * 1024)).clamp(0.0, 1.0).toDouble()),
                  const SizedBox(height: 8),
                  Text(
                    _storage.oldest == null ? 'Nothing saved yet' : 'Oldest saved: ${nhDate(_storage.oldest!)}',
                    style: AppText.small,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _group(danger: true, [
                _row(art: LsArts.iconTrash, title: 'Clear history', titleColor: AppColors.red, onTap: _clear, chevron: true),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 0, 10),
        child: Text(t.toUpperCase(), style: AppText.mono(11, FontWeight.w700, spacing: 1.1)),
      );

  Widget _group(List<Widget> rows, {bool danger = false}) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: danger ? AppColors.red.withValues(alpha: .25) : AppColors.stroke),
        ),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: AppColors.stroke),
            rows[i],
          ],
        ]),
      );

  Widget _row({
    required String art,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color titleColor = AppColors.text,
    VoidCallback? onTap,
    bool chevron = false,
  }) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              LsArt(art, height: 40, width: 40, fit: BoxFit.contain),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(title, style: AppText.jakarta(15, FontWeight.w600, color: titleColor)),
                  if (subtitle != null) Text(subtitle, style: AppText.small),
                ]),
              ),
              if (trailing != null) trailing,
              if (chevron) const LsIcon(LsIconType.chevron, size: 17, color: AppColors.muted, stroke: 1.9),
            ]),
          ),
        ),
      );
}

class _RetentionToggle extends StatelessWidget {
  const _RetentionToggle({required this.index, required this.premium, required this.onChanged});
  final int index;
  final bool premium;
  final ValueChanged<int> onChanged;

  static const _labels = ['7 days', '30 days', 'Forever'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        LsSegmentedToggle(labels: _labels, index: index, onChanged: onChanged),
        if (!premium)
          const Positioned(
            top: -10,
            right: 6,
            child: LsArt(LsArts.iconForever, height: 26, width: 26, fit: BoxFit.contain),
          ),
      ],
    );
  }
}

class _ForeverUnlockBanner extends StatelessWidget {
  const _ForeverUnlockBanner({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.chipAmberBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amberFill.withValues(alpha: .45)),
      ),
      child: Row(
        children: [
          const LsArt(LsArts.crownTile, height: 28, width: 28, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Keep history forever with Premium',
              style: AppText.jakarta(13.5, FontWeight.w700, height: 1.25),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onUnlock,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: AppColors.goldEdge, offset: Offset(0, 3))],
              ),
              child: Text('UNLOCK', style: AppText.mono(11, FontWeight.w800, color: AppColors.boostInkGold, spacing: .6)),
            ),
          ),
        ],
      ),
    );
  }
}
