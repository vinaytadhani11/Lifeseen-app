import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/local_plan_record.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friendship_status_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/premium_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/register_screen.dart';
import 'package:tableflow_plus/screens/splash_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/friends_photo_service.dart';
import 'package:tableflow_plus/services/settings_actions_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendsSettingsScreen extends StatefulWidget {
  const FriendsSettingsScreen({
    super.key,
    this.historySummary,
    this.onNotificationHistory,
  });

  final String? historySummary;
  final VoidCallback? onNotificationHistory;

  @override
  State<FriendsSettingsScreen> createState() => _FriendsSettingsScreenState();
}

class _FriendsSettingsScreenState extends State<FriendsSettingsScreen> {
  final _flow = FriendsFlowController.instance;
  final _name = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _flow.addListener(_sync);
    _name.text = _flow.user?.username ?? '';
  }

  @override
  void dispose() {
    _flow.removeListener(_sync);
    _name.dispose();
    super.dispose();
  }

  void _sync() {
    if (!_editing && mounted) {
      _name.text = _flow.user?.username ?? '';
      setState(() {});
    }
  }

  LocalPlanRecord? get _sub => AppBootstrap.prefs.screenTimeSubscription;

  Future<void> _saveName() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      await showFlowToast('Enter your name');
      return;
    }
    showFlowProcessing();
    try {
      await _flow.updateUsername(name);
      hideFlowProcessing();
      setState(() => _editing = false);
      await showFlowToast('Username updated');
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast('Could not update the name');
    }
  }

  Future<void> _photo() async {
    try {
      final bytes = await pickSquareProfilePhoto();
      if (bytes == null || _flow.documentId.isEmpty) return;
      showFlowProcessing();
      final url = await uploadProfileBytes(_flow.documentId, bytes);
      await _flow.savePhotoUrl(url);
      hideFlowProcessing();
      await showFlowToast('Profile photo updated');
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast('Photo could not be loaded');
    }
  }

  Future<void> _logout() async {
    final yes = await confirmFlowDialog(
      title: 'Log Out',
      message: 'Are you sure you want to exit the app?',
      positive: 'Log Out',
      negative: 'Cancel',
    );
    if (!yes) return;
    await _flow.logout();
    Get.offAll<void>(() => const SplashScreen());
  }

  Future<void> _delete() async {
    final yes = await confirmFlowDialog(
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
      positive: 'Delete',
      negative: 'Cancel',
    );
    if (!yes) return;
    showFlowProcessing();
    try {
      await _flow.deleteAccount();
      hideFlowProcessing();
      Get.offAll<void>(() => const SplashScreen());
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast('Could not delete the account');
    }
  }

  Future<void> _resetSub() async {
    final yes = await confirmFlowDialog(
      title: 'Reset screen time subscription?',
      message: 'This clears the local subscription so the premium screen appears again, as if it were the first time.',
      positive: 'Reset subscription (test)',
      negative: 'Cancel',
    );
    if (!yes) return;
    await _flow.resetSubscription();
    await showFlowToast('Local subscription cleared.');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = _flow.user;
    final registered = _flow.documentId.isNotEmpty && user != null;
    final profile = registered ? user : null;
    final sub = _sub;
    final active = sub != null && sub.active && !sub.isExpired;
    return LsScaffold(
      safeBottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 30 + MediaQuery.paddingOf(context).bottom),
        children: [
          LsTopBar(
            right: LsHeaderButton(icon: LsIconType.close, semanticLabel: 'Close', onTap: () => Get.back<void>()),
          ),
          Text('Settings', style: AppText.h1),
          const SizedBox(height: 4),
          LsCaption(registered ? '// profile · friends · plan' : '// account · general'),
          const SizedBox(height: 16),
          if (profile != null) ...[
            _ProfileCard(
              name: profile.username,
              phone: profile.phone,
              photo: profile.photo,
              onUpload: _photo,
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Profile'),
            _Card(
              child: Column(
                children: [
                  _InfoRow(
                    icon: LsIconType.user,
                    tint: AppColors.green,
                    wash: AppColors.mint,
                    title: 'Name',
                    trailing: GestureDetector(
                      onTap: () {
                        if (_editing) {
                          _saveName();
                        } else {
                          setState(() => _editing = true);
                        }
                      },
                      child: LsIcon(_editing ? LsIconType.check : LsIconType.edit, size: 18, color: AppColors.green, stroke: 1.8),
                    ),
                    value: _editing
                        ? TextField(
                            controller: _name,
                            autofocus: true,
                            style: AppText.jakarta(13, FontWeight.w500, color: AppColors.grey),
                            cursorColor: AppColors.green,
                            onSubmitted: (_) => _saveName(),
                            decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
                          )
                        : Text(profile.username, style: AppText.jakarta(13, FontWeight.w500, color: AppColors.grey)),
                  ),
                  const _Hairline(),
                  _InfoRow(
                    icon: LsIconType.phone,
                    tint: AppColors.green,
                    wash: AppColors.mint,
                    title: 'Phone number',
                    value: Text(profile.phone, style: AppText.jakarta(13, FontWeight.w500, color: AppColors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Social'),
            _Card(
              child: Column(
                children: [
                  _NavRow(
                    icon: LsIconType.users,
                    tint: AppColors.indigo,
                    wash: AppColors.indigo.withValues(alpha: .12),
                    title: 'My Friends',
                    count: profile.friends.length,
                    onTap: () => Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.friends)),
                  ),
                  const _Hairline(),
                  _NavRow(
                    icon: LsIconType.send,
                    tint: AppColors.blue,
                    wash: AppColors.blue.withValues(alpha: .12),
                    title: 'Sent Requests',
                    count: profile.sentRequests.length,
                    onTap: () => Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.sentRequests)),
                  ),
                  const _Hairline(),
                  _NavRow(
                    icon: LsIconType.userPlus,
                    tint: AppColors.teal,
                    wash: AppColors.mint,
                    title: 'Received Requests',
                    count: profile.receivedRequests.length,
                    onTap: () => Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.requestsReceived)),
                  ),
                ],
              ),
            ),
          ] else ...[
            const _SectionLabel('Profile'),
            _CompleteInfoCard(
              onTap: () {
                HapticFeedback.vibrate();
                Get.to<void>(() => const RegisterScreen());
              },
            ),
          ],
          const SizedBox(height: 18),
          const _SectionLabel('Plan'),
          _PlanCard(
            sub: sub,
            active: active,
            daysLeft: sub == null ? 0 : _days(sub),
            onUpgrade: () => Get.to<void>(() => const PremiumScreen()),
            onReset: sub == null ? null : _resetSub,
          ),
          if (widget.onNotificationHistory != null) ...[
            const SizedBox(height: 18),
            const _SectionLabel('Tools'),
            _Card(
              child: _NavRow(
                icon: LsIconType.bell,
                tint: AppColors.green,
                wash: AppColors.mint,
                title: 'Notification History',
                subtitle: widget.historySummary,
                onTap: widget.onNotificationHistory!,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const _SectionLabel('General Settings'),
          _Card(
            child: Column(
              children: [
                _NavRow(
                  icon: LsIconType.doc,
                  tint: AppColors.green,
                  wash: AppColors.mint,
                  title: 'Privacy and Policy',
                  onTap: () => launchUrl(Uri.parse('https://sites.google.com/view/seenx/privacy'), mode: LaunchMode.externalApplication),
                ),
                const _Hairline(),
                _NavRow(
                  icon: LsIconType.doc,
                  tint: AppColors.green,
                  wash: AppColors.mint,
                  title: 'Terms of Use',
                  onTap: () => launchUrl(Uri.parse('https://sites.google.com/view/seenx/terms'), mode: LaunchMode.externalApplication),
                ),
                const _Hairline(),
                _NavRow(
                  icon: LsIconType.doc,
                  tint: AppColors.green,
                  wash: AppColors.mint,
                  title: 'EULA',
                  onTap: () => launchUrl(Uri.parse('https://sites.google.com/view/seenx/eula'), mode: LaunchMode.externalApplication),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _NavRow(
                  icon: LsIconType.star,
                  tint: AppColors.amber,
                  wash: AppColors.chipAmberBg,
                  title: 'Rate Us',
                  onTap: () => SettingsActionsService.handle(SettingsAction.rateUs, shareOrigin: null),
                ),
                const _Hairline(),
                _NavRow(
                  icon: LsIconType.share,
                  tint: AppColors.indigo,
                  wash: AppColors.indigo.withValues(alpha: .12),
                  title: 'Share The App',
                  onTap: shareSeenX,
                ),
              ],
            ),
          ),
          if (registered) ...[
            const SizedBox(height: 10),
            _Card(
              border: AppColors.red.withValues(alpha: .28),
              child: Column(
                children: [
                  _NavRow(
                    icon: LsIconType.trash,
                    tint: AppColors.red,
                    wash: AppColors.red.withValues(alpha: .1),
                    title: 'Delete Account',
                    danger: true,
                    onTap: _delete,
                  ),
                  Divider(height: 1, color: AppColors.red.withValues(alpha: .15)),
                  _NavRow(
                    icon: LsIconType.logout,
                    tint: AppColors.red,
                    wash: AppColors.red.withValues(alpha: .1),
                    title: 'Log Out',
                    danger: true,
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _days(LocalPlanRecord sub) {
    final left = sub.expiryDateMs - DateTime.now().millisecondsSinceEpoch;
    if (left <= 0) return 0;
    return Duration(milliseconds: left).inDays;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text.toUpperCase(), style: AppText.mono(11, FontWeight.w600, color: AppColors.muted, spacing: 1.1)),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.border});

  final Widget child;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border ?? AppColors.stroke),
        boxShadow: [
          BoxShadow(color: AppColors.text.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 64),
      child: Divider(height: 1, color: AppColors.stroke),
    );
  }
}

class _IconWash extends StatelessWidget {
  const _IconWash({required this.icon, required this.tint, required this.wash});

  final LsIconType icon;
  final Color tint;
  final Color wash;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(12)),
      child: LsIcon(icon, size: 18, color: tint, stroke: 1.8),
    );
  }
}

class _CompleteInfoCard extends StatelessWidget {
  const _CompleteInfoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: const _DashedRoundRectPainter(
          color: AppColors.green,
          radius: 24,
          strokeWidth: 1.6,
          dash: 5,
          gap: 4,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const LsArt(LsArts.completeProfile, height: 54, width: 58),
              Container(
                width: 1,
                height: 46,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.stroke2,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Complete Your Information', style: AppText.jakarta(14.5, FontWeight.w800, height: 1.15)),
                    const SizedBox(height: 4),
                    Text(
                      'Add your name and phone number to complete your profile.',
                      style: AppText.jakarta(12, FontWeight.w400, color: AppColors.grey, height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.mint),
                child: const LsIcon(LsIconType.chevron, size: 16, color: AppColors.green, stroke: 2.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundRectPainter extends CustomPainter {
  const _DashedRoundRectPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundRectPainter old) =>
      old.color != color || old.radius != radius || old.strokeWidth != strokeWidth || old.dash != dash || old.gap != gap;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.phone,
    required this.photo,
    required this.onUpload,
  });

  final String name;
  final String phone;
  final String photo;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            LsAvatar(
              index: name.hashCode.abs(),
              size: 54,
              status: LsStatus.online,
              photoUrl: photo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(16, FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(phone, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.jakarta(13, FontWeight.w500, color: AppColors.grey)),
                ],
              ),
            ),
            GestureDetector(
              onTap: onUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LsIcon(LsIconType.camera, size: 14, color: AppColors.green, stroke: 1.8),
                    const SizedBox(width: 6),
                    Text('UPLOAD', style: AppText.mono(11, FontWeight.w700, color: AppColors.green, spacing: .4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.tint,
    required this.wash,
    required this.title,
    required this.value,
    this.trailing,
  });

  final LsIconType icon;
  final Color tint;
  final Color wash;
  final String title;
  final Widget value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconWash(icon: icon, tint: tint, wash: wash),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.jakarta(15, FontWeight.w700)),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.tint,
    required this.wash,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.count,
    this.danger = false,
  });

  final LsIconType icon;
  final Color tint;
  final Color wash;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final int? count;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.red : AppColors.text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _IconWash(icon: icon, tint: tint, wash: wash),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.jakarta(15, FontWeight.w700, color: color)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: AppText.small),
                ],
              ),
            ),
            if (count != null) ...[
              Text('$count', style: AppText.jakarta(15, FontWeight.w700, color: AppColors.text)),
              const SizedBox(width: 6),
            ],
            LsIcon(LsIconType.chevron, size: 16, color: danger ? AppColors.red : AppColors.muted, stroke: 2),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.sub,
    required this.active,
    required this.daysLeft,
    required this.onUpgrade,
    required this.onReset,
  });

  final LocalPlanRecord? sub;
  final bool active;
  final int daysLeft;
  final VoidCallback onUpgrade;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final status = sub == null ? 'status · not subscribed' : active ? 'status · active' : 'status · expired';
    final totalMs = sub == null ? 0 : sub!.expiryDateMs - sub!.purchaseDateMs;
    final totalDays = totalMs <= 0 ? 1 : (totalMs / Duration.millisecondsPerDay).ceil();
    final span = totalDays < daysLeft ? daysLeft : totalDays;
    final progress = sub == null ? 0.0 : (daysLeft / span).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.amberFill.withValues(alpha: .45)),
        boxShadow: [
          BoxShadow(color: AppColors.amberFill.withValues(alpha: .12), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: LsArt(LsArts.crownPremium, height: 36, width: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use Unlimited!', style: AppText.jakarta(18, FontWeight.w800)),
                    Text('Experience premium quality', style: AppText.jakarta(13, FontWeight.w400, color: AppColors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LsPill(status, variant: active ? LsPillVariant.green : LsPillVariant.amber, dot: active),
          if (sub != null) ...[
            const SizedBox(height: 14),
            _planLine('Plan', sub!.planLabel),
            _planLine('Purchased', planDateLabel(sub!.purchaseDateMs)),
            _planLine('Expires', planDateLabel(sub!.expiryDateMs)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('DAYS REMAINING', style: AppText.mono(10, FontWeight.w600, color: AppColors.muted, spacing: .6)),
                const Spacer(),
                Text('$daysLeft', style: AppText.jakarta(14, FontWeight.w800, color: AppColors.green)),
                Text(' / $span', style: AppText.jakarta(14, FontWeight.w600, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.mint,
                color: AppColors.neon,
              ),
            ),
          ],
          if (!active) ...[
            const SizedBox(height: 14),
            AppCtaButton(label: 'Upgrade', variant: AppCtaVariant.gold, onTap: onUpgrade),
          ],
          if (onReset != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onReset,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LsIcon(LsIconType.close, size: 14, color: AppColors.text, stroke: 2),
                    const SizedBox(width: 8),
                    Text('RESET SUBSCRIPTION (TEST)', style: AppText.jakarta(13, FontWeight.w800, spacing: .3)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _planLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label.toUpperCase(), style: AppText.mono(10, FontWeight.w600, color: AppColors.muted, spacing: .5)),
          ),
          Expanded(
            child: Text(value, style: AppText.jakarta(13.5, FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

