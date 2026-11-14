// LifeSeen – S05 Activate (Screen Time + Notification History) · Light Green theme
//
// Step 1  Usage access         (required) → "ACTIVATE SCREEN TIME"
// Step 2  Notification access  (optional) → "ALLOW NOTIFICATIONS" / "SKIP FOR NOW"
// Both checked again every time the user comes back from Android settings.

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


class ActivationResult {
  const ActivationResult({required this.usageAccess, required this.notificationAccess});
  final bool usageAccess;
  final bool notificationAccess;
}

class ActivateScreenTimeScreen extends StatefulWidget {
  const ActivateScreenTimeScreen({super.key, required this.onContinue, this.service});

  /// Called with the final permission state (go to Choose Apps when
  /// notificationAccess is true, else straight to Complete Information).
  final ValueChanged<ActivationResult> onContinue;
  final NotificationHistory? service;

  @override
  State<ActivateScreenTimeScreen> createState() => _ActivateScreenTimeScreenState();
}

class _ActivateScreenTimeScreenState extends State<ActivateScreenTimeScreen> with WidgetsBindingObserver {
  NotificationHistory get _svc => widget.service ?? NotificationHistory.instance;
  bool _usage = false, _notif = false, _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final u = await _svc.isUsageAccessGranted();
    final n = await _svc.isNotificationAccessGranted();
    if (!mounted) return;
    if ((u && !_usage) || (n && !_notif)) HapticFeedback.mediumImpact();
    setState(() {
      _usage = u;
      _notif = n;
      _loading = false;
    });
  }

  Future<void> _primary() async {
    // Usage access is required.
    if (!_usage) {
      await _svc.openUsageAccessSettings();
      if (_svc.isDemo) unawaited(_refresh());
      return;
    }
    // Notifications are optional — primary action always continues.
    widget.onContinue(ActivationResult(usageAccess: _usage, notificationAccess: _notif));
  }

  Future<void> _allowNotifications() async {
    await _svc.openNotificationAccessSettings();
    if (_svc.isDemo) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final needsUsage = !_usage;
    final ctaLabel = needsUsage ? 'Activate Screen Time' : 'Continue';
    final ctaIcon = needsUsage ? LsIconType.shield : LsIconType.bolt;
    final heroStep = needsUsage ? 0 : (_notif ? 2 : 1);

    return LsScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 40, child: Center(child: LsWordmark())),
          Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: _Hero(step: heroStep)))),
          LsReveal(
            delay: 120,
            child: Text(
              _usage && _notif ? 'You\'re All Set' : 'Activate LifeSeen',
              textAlign: TextAlign.center,
              style: AppText.h1,
            ),
          ),
          const SizedBox(height: 6),
          LsReveal(
            delay: 180,
            child: Text(
              needsUsage
                  ? 'Usage access is required to show screen time. Notification history is optional.'
                  : 'You can continue now. Notification access is optional and can be turned on anytime.',
              textAlign: TextAlign.center,
              style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          LsReveal(
            delay: 240,
            child: _PermissionCard(
              number: 1,
              art: LsArts.usageAccess,
              title: 'Usage access',
              subtitle: 'Screen time per app · required',
              granted: _usage,
              active: needsUsage,
              onTap: _usage ? null : _svc.openUsageAccessSettings,
            ),
          ),
          const SizedBox(height: 8),
          LsReveal(
            delay: 310,
            child: _PermissionCard(
              number: 2,
              art: LsArts.notificationAccess,
              title: 'Notification access',
              subtitle: 'Save notification history · optional',
              granted: _notif,
              active: false,
              onTap: !_usage || _notif ? null : _allowNotifications,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(style: AppText.mono(12, FontWeight.w400), children: [
              const TextSpan(text: '> usage: '),
              TextSpan(
                text: _loading ? '…' : (_usage ? 'granted' : 'off'),
                style: AppText.mono(12, FontWeight.w500, color: _usage ? AppColors.green : AppColors.amber),
              ),
              const TextSpan(text: ' · notifications: '),
              TextSpan(
                text: _loading ? '…' : (_notif ? 'granted' : 'optional'),
                style: AppText.mono(
                  12,
                  FontWeight.w500,
                  color: _notif ? AppColors.green : AppColors.muted,
                ),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: LsCta(
              key: ValueKey(ctaLabel),
              label: ctaLabel,
              icon: ctaIcon,
              centerLabel: true,
              onPressed: _loading ? null : _primary,
            ),
          ),
          if (_usage && !_notif) ...[
            const SizedBox(height: 10),
            LsSmallCta(
              label: 'Allow Notifications',
              icon: LsIconType.bell,
              variant: LsSmallCtaVariant.ghost,
              onPressed: _loading ? null : _allowNotifications,
            ),
          ] else
            const SizedBox(height: 10),
        ]),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final asset = step == 0 ? LsArts.secureShield : LsArts.notificationBell;
    return SizedBox(
      width: 260,
      height: 230,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
        child: LsArt(asset, key: ValueKey(asset), height: 220, fit: BoxFit.contain),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.number,
    required this.art,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.active,
    this.onTap,
  });
  final int number;
  final String art;
  final String title, subtitle;
  final bool granted, active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: granted ? Color.alphaBlend(AppColors.neon.withValues(alpha: .07), AppColors.white) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? AppColors.green : (granted ? AppColors.neon.withValues(alpha: .45) : AppColors.stroke),
              width: active ? 1.5 : 1,
            ),
            boxShadow: active ? [BoxShadow(color: AppColors.neon.withValues(alpha: .45), blurRadius: 22, spreadRadius: -8)] : const [],
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: LsArt(art, width: 52, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('$number · $title', style: AppText.jakarta(14, FontWeight.w700)),
                Text(subtitle, style: AppText.small),
              ]),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: granted
                  ? Container(
                      key: const ValueKey('ok'),
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neon,
                        boxShadow: [BoxShadow(color: AppColors.neon.withValues(alpha: .7), blurRadius: 8)],
                      ),
                      child: const LsIcon(LsIconType.check, size: 14, color: AppColors.ink, stroke: 2.8),
                    )
                  : LsPill(
                      number == 1 ? 'required' : 'optional',
                      key: const ValueKey('pill'),
                      variant: number == 1 ? LsPillVariant.amber : LsPillVariant.off,
                      fontSize: 9.5,
                    ),
            ),
          ]),
        ),
      );
}
