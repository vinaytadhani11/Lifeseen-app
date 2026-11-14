// LifeSeen – S31 Save Your Notifications (intro) + S32 Turn On Notification Access (guide)
// Light Green theme. Both re-check the permission when the user returns from Android settings.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/notification_history.dart';
import 'package:flutter/services.dart';


// ============================================================================
// S31 · intro (used as the History tab while access is off)
// ============================================================================
class NotificationAccessIntro extends StatelessWidget {
  const NotificationAccessIntro({super.key, required this.onAllow, this.onBack, this.showNav = true});

  /// Open the S32 guide (it returns true when access was turned on).
  final VoidCallback onAllow;
  final VoidCallback? onBack;
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return LsScaffold(
      safeBottom: false,
      child: Stack(children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 130 + inset),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  height: 42,
                  child: Row(children: [
                    SizedBox(width: 40, child: onBack == null ? null : LsHeaderButton(icon: LsIconType.back, onTap: onBack)),
                    const Expanded(child: Center(child: LsWordmark())),
                    const SizedBox(width: 40),
                  ]),
                ),
              ),
              const Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: LsArt(LsArts.notificationBell, height: 220, fit: BoxFit.contain),
                  ),
                ),
              ),
              LsReveal(delay: 100, child: Text('Save Your Notifications', textAlign: TextAlign.center, style: AppText.h1)),
              const SizedBox(height: 6),
              LsReveal(
                delay: 160,
                child: Text(
                  'Allow notification access so LifeSeen can keep a history of notifications from the apps you choose.',
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
              const LsReveal(
                delay: 220,
                child: LsFeatureRow(icon: LsIconType.bell, title: 'Read incoming notifications', subtitle: 'Only from apps you turn on'),
              ),
              const SizedBox(height: 8),
              const LsReveal(
                delay: 280,
                child: LsFeatureRow(
                    icon: LsIconType.lock, color: AppColors.teal, title: 'Saved privately on your phone', subtitle: 'Clear your history anytime'),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(style: AppText.mono(12, FontWeight.w400), children: [
                  const TextSpan(text: '> notification access: '),
                  TextSpan(text: 'off', style: AppText.mono(12, FontWeight.w500, color: AppColors.amber)),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LsCta(label: 'Allow Access', icon: LsIconType.bell, onPressed: onAllow),
            ]),
          ),
        ),
        if (showNav) const Positioned(left: 0, right: 0, bottom: 0, child: LsBottomNav(active: LsNavTab.history)),
      ]),
    );
  }
}

// ============================================================================
// S32 · step-by-step guide; pops `true` once access is on
// ============================================================================
class TurnOnAccessScreen extends StatefulWidget {
  const TurnOnAccessScreen({super.key, this.service});
  final NotificationHistory? service;

  @override
  State<TurnOnAccessScreen> createState() => _TurnOnAccessScreenState();
}

class _TurnOnAccessScreenState extends State<TurnOnAccessScreen> with WidgetsBindingObserver {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  bool _granted = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check({bool userAsked = false}) async {
    final g = await _svc.isNotificationAccessGranted();
    if (!mounted) return;
    setState(() => _granted = g);
    if (g && !_closing) {
      _closing = true;
      HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop(true);
    } else if (!g && userAsked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Notification access is still off. Turn on LifeSeen in the list.'),
      ));
    }
  }

  Future<void> _open() async {
    await _svc.openNotificationAccessSettings();
    if (_svc.isDemo) unawaited(_check());
  }

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      safeBottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          LsTopBar(onBack: () => Navigator.of(context).maybePop(false)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Turn On Notification Access', style: AppText.h1),
              const SizedBox(height: 4),
              const LsCaption('// step 2 of 3 · android settings'),
              const SizedBox(height: 14),
              LsCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(children: [
                  for (final (i, a, b) in const [(1, 'Open', 'Notification access'), (2, 'Find', 'LifeSeen in the list'), (3, 'Turn on', 'Allow notification access')]) ...[
                    if (i > 1) const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i == 3 ? AppColors.neon : AppColors.neon.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('$i', style: AppText.mono(13, FontWeight.w700, color: i == 3 ? AppColors.ink : AppColors.green)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(TextSpan(style: AppText.jakarta(14.5, FontWeight.w400), children: [
                          TextSpan(text: '$a '),
                          TextSpan(text: b, style: AppText.jakarta(14.5, FontWeight.w700)),
                        ])),
                      ),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 14),
              Text('PREVIEW · ANDROID SETTINGS', style: AppText.mono(11, FontWeight.w700, spacing: 1.1)),
              const SizedBox(height: 10),
              _SettingsPreview(on: _granted),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(style: AppText.mono(12, FontWeight.w400), children: [
                  const TextSpan(text: '> notification access: '),
                  TextSpan(
                    text: _granted ? 'granted' : 'waiting…',
                    style: AppText.mono(12, FontWeight.w500, color: _granted ? AppColors.green : AppColors.amber),
                  ),
                ]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LsCta(label: 'Open Settings', icon: LsIconType.gear, onPressed: _open),
              const SizedBox(height: 12),
              LsSmallCta(
                label: "I've turned it on",
                icon: LsIconType.check,
                variant: LsSmallCtaVariant.ghost,
                onPressed: () => _check(userAsked: true),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SettingsPreview extends StatelessWidget {
  const _SettingsPreview({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    Widget row(String name, Color c, LsIconType icon, bool me) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: me ? Color.alphaBlend(AppColors.neon.withValues(alpha: .08), AppColors.white) : null,
            border: me ? const Border(left: BorderSide(color: AppColors.neon, width: 3)) : null,
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
              child: LsIcon(icon, size: 18, color: me ? AppColors.green : c, stroke: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name, style: AppText.jakarta(14.5, me ? FontWeight.w700 : FontWeight.w500)),
                Text(me ? (on ? 'Allowed' : 'Not allowed') : 'Not allowed', style: AppText.small),
              ]),
            ),
            _MiniSwitch(on: me && on),
          ]),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.stroke2),
        boxShadow: [BoxShadow(color: AppColors.text.withValues(alpha: .35), offset: const Offset(0, 14), blurRadius: 30, spreadRadius: -18)],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.stroke))),
          child: Row(children: [
            const LsIcon(LsIconType.back, size: 18, color: AppColors.grey, stroke: 2),
            const SizedBox(width: 10),
            Text('Notification access', style: AppText.jakarta(15, FontWeight.w700)),
          ]),
        ),
        row('Android Auto', const Color(0xFF4285F4), LsIconType.grid, false),
        row('LifeSeen', AppColors.neon, LsIconType.eye, true),
        row('Smart Lock', const Color(0xFF8E9691), LsIconType.lock, false),
      ]),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AppColors.neon : AppColors.stroke2,
          borderRadius: BorderRadius.circular(14),
          boxShadow: on ? [BoxShadow(color: AppColors.neon.withValues(alpha: .8), blurRadius: 12, spreadRadius: -2)] : const [],
        ),
        child: Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white)),
      );
}
