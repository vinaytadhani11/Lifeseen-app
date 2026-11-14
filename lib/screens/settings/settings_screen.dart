import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/navigation/navigation_utils.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/models/local_plan_record.dart';
import 'package:tableflow_plus/screens/settings/reminder_schedule_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/app_prefs_service.dart';
import 'package:tableflow_plus/services/decryption_timer_service.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:tableflow_plus/services/settings_actions_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _background = Color(0xFF080C10);
  static const _cardBackground = Color(0xFF1A1B2E);
  static const _iconTileBackground = Color(0xFF252636);
  static const _deleteRed = Color(0xFFFF4D4D);

  static const _aboutItems = [
    _SettingsItem(
      icon: Icons.lock_outline_rounded,
      title: 'Privacy Policy',
      action: SettingsAction.privacyPolicy,
    ),
    _SettingsItem(
      icon: Icons.description_outlined,
      title: 'Terms Of Use',
      action: SettingsAction.termsOfUse,
    ),
    _SettingsItem(
      icon: Icons.language_rounded,
      title: 'EULA',
      action: SettingsAction.eula,
    ),
    _SettingsItem(
      icon: Icons.star_outline_rounded,
      title: 'Rate Us',
      action: SettingsAction.rateUs,
    ),
    _SettingsItem(
      icon: Icons.ios_share_rounded,
      title: 'Share',
      action: SettingsAction.share,
    ),
    _SettingsItem(
      icon: Icons.help_outline_rounded,
      title: 'Support',
      action: SettingsAction.support,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.logoWhiteText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Settings',
                  style: GoogleFonts.montserrat(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.logoWhiteText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 28),
                const _PremiumTestPanel(),
                const SizedBox(height: 14),
                _TestCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminder schedule',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.logoWhiteText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TestButton(
                        label: 'Open reminder schedule',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ReminderScheduleScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const _SettingsSectionTitle(title: 'About'),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: _aboutItems
                      .map((item) => _SettingsTile(item: item))
                      .toList(),
                ),
                const SizedBox(height: 28),
                const _SettingsSectionTitle(title: 'Delete Account'),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      item: const _SettingsItem(
                        icon: Icons.person_remove_outlined,
                        title: 'Delete Account',
                        action: SettingsAction.deleteAccount,
                        isDestructive: true,
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardBackground,
        title: Text(
          'Delete Account',
          style: GoogleFonts.montserrat(
            color: AppColors.logoWhiteText,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently remove your account and all associated data. '
          'This action cannot be undone.',
          style: GoogleFonts.montserrat(
            color: AppColors.subtitleText,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(color: AppColors.subtitleText),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: GoogleFonts.montserrat(
                color: _deleteRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    NavigationUtils.showProcessingOverlay();
    try {
      await AppBootstrap.prefs.resetEntireWhatsAppFlow();
      AppBootstrap.decryption.resetForTest();
      await NotificationScheduler.cancelAll();
      NavigationUtils.hideProcessingOverlay();
      NavigationUtils.toEnterNumber();
    } catch (_) {
      NavigationUtils.hideProcessingOverlay();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete the account. Please try again.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: _cardBackground,
        ),
      );
    }
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.action,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final SettingsAction action;
  final bool isDestructive;
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.logoWhiteText,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: SettingsScreen._cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item, this.onTap});

  final _SettingsItem item;
  final VoidCallback? onTap;

  Future<void> _handleTap(BuildContext context) async {
    if (onTap != null) {
      onTap!();
      return;
    }

    if (item.action == SettingsAction.deleteAccount) return;

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SettingsActionsService.handle(item.action, shareOrigin: origin);
    } on SettingsActionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.montserrat()),
          backgroundColor: SettingsScreen._cardBackground,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: SettingsScreen._cardBackground,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = item.isDestructive
        ? SettingsScreen._deleteRed
        : AppColors.logoWhiteText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              _IconTile(
                icon: item.icon,
                iconColor: item.isDestructive
                    ? SettingsScreen._deleteRed
                    : AppColors.logoWhiteText,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
              ),
              const _ChevronTile(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: SettingsScreen._iconTileBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}

class _ChevronTile extends StatelessWidget {
  const _ChevronTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: SettingsScreen._iconTileBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.subtitleText,
        size: 22,
      ),
    );
  }
}

/// Live local premium, boost and timer controls for testing.
class _PremiumTestPanel extends StatefulWidget {
  const _PremiumTestPanel();

  @override
  State<_PremiumTestPanel> createState() => _PremiumTestPanelState();
}

class _PremiumTestPanelState extends State<_PremiumTestPanel> {
  static const _card = Color(0xFF16182A);
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final timer = AppBootstrap.decryption;
    return ListenableBuilder(
      listenable: timer,
      builder: (context, _) {
        final prefs = AppBootstrap.prefs;
        final premium = _premiumView(prefs);
        final normal = _boostView(
          title: 'Normal Boost (weekly)',
          planName: 'Normal Boost',
          record: prefs.normalBoostSubscription,
          flag: prefs.normalBoost,
        );
        final superBoost = _boostView(
          title: 'Super Boost (monthly)',
          planName: 'Super Boost',
          record: prefs.superBoostSubscription,
          flag: prefs.superBoost,
        );
        final timerRunning = timer.isCounting || timer.isPaused;
        final showFlowReset =
            premium.active || normal.active || superBoost.active || timerRunning;

        return Column(
          children: [
            if (showFlowReset) ...[
              _TestCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardTitle('WhatsApp flow (test)'),
                    const SizedBox(height: 12),
                    _TestButton(
                      label: 'Reset entire WhatsApp flow (test)',
                      onTap: _resetFlow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _TestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('WhatsApp Subscription'),
                  const SizedBox(height: 10),
                  if (!premium.active)
                    _line('Status: Not subscribed', strong: true)
                  else ...[
                    _line('Status: Active', strong: true),
                    _line('Plan: ${premium.plan}'),
                    _line('Purchased: ${premium.purchased}'),
                    _line('Expires: ${premium.expires}'),
                    _line('Days remaining: ${premium.days}'),
                    const SizedBox(height: 12),
                    _TestButton(
                      label: 'Reset subscription (test)',
                      onTap: _resetSubscription,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Start time (test)'),
                  const SizedBox(height: 10),
                  _line(
                    'Configured: ${AppBootstrap.remoteConfig.settings.startTime} h',
                  ),
                  _line('Status: ${_startTimeStatus(timer)}', strong: true),
                  if (timer.stage == DecryptionStage.initial &&
                      timerRunning) ...[
                    _line(_remainingLabel(timer.remainingSeconds)),
                    const SizedBox(height: 12),
                    _TestButton(
                      label: 'Complete timer (test)',
                      onTap: () {
                        timer.completeInitialPhase();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Boost Subscription'),
                  const SizedBox(height: 10),
                  _boostBlock(normal),
                  const SizedBox(height: 10),
                  _boostBlock(superBoost),
                  if (normal.active || superBoost.active) ...[
                    const SizedBox(height: 12),
                    _TestButton(
                      label: 'Reset boost (test)',
                      onTap: _resetBoost,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _TestCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Additional time (test)'),
                  const SizedBox(height: 10),
                  _line('Phase: ${_phaseLabel(timer)}', strong: true),
                  if (timer.stage == DecryptionStage.extra && timerRunning) ...[
                    _line(_remainingLabel(timer.remainingSeconds)),
                    const SizedBox(height: 12),
                    _TestButton(
                      label: 'Complete timer (test)',
                      onTap: () {
                        timer.completeCurrentPhase();
                        setState(() {});
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _boostBlock(_BoostView boost) {
    if (!boost.active) {
      return _line('${boost.title} — Status: Not subscribed', strong: true);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _line('${boost.title} — Status: Active', strong: true),
        _line('Plan: ${boost.plan}'),
        _line('Purchased: ${boost.purchased}'),
        _line('Expires: ${boost.expires}'),
        _line('Days remaining: ${boost.days}'),
      ],
    );
  }

  Future<void> _resetSubscription() async {
    await AppBootstrap.prefs.resetWpSubscription();
    AppBootstrap.decryption.resetForTest();
    await NotificationScheduler.syncForWhatsAppFlow(
      prefs: AppBootstrap.prefs,
      remoteConfig: AppBootstrap.remoteConfig,
    );
    if (mounted) setState(() {});
  }

  Future<void> _resetBoost() async {
    final timer = AppBootstrap.decryption;
    final wasBoost = timer.stage == DecryptionStage.boost;
    await AppBootstrap.prefs.resetBoostSubscriptions();
    if (wasBoost) timer.completeCurrentPhase();
    if (mounted) setState(() {});
  }

  Future<void> _resetFlow() async {
    await AppBootstrap.prefs.resetEntireWhatsAppFlow();
    AppBootstrap.decryption.resetForTest();
    await NotificationScheduler.cancelAll();
    if (!mounted) return;
    NavigationUtils.toEnterNumber();
  }

  String _startTimeStatus(DecryptionTimerService timer) {
    if (timer.stage == DecryptionStage.initial) {
      if (timer.isPaused) return 'Paused';
      if (timer.isCounting) return 'Running';
    }
    if (timer.stage == DecryptionStage.none) return 'Not started';
    return 'Finished';
  }

  String _phaseLabel(DecryptionTimerService timer) {
    return switch (timer.stage) {
      DecryptionStage.none => 'Not started',
      DecryptionStage.initial => 'INITIAL',
      DecryptionStage.boost => 'BOOST',
      DecryptionStage.extra => 'EXTRA',
      DecryptionStage.awaitingExtra => 'Waiting for additional time',
      DecryptionStage.completed => 'Completed',
    };
  }

  String _remainingLabel(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return 'Remaining: $hours h $minutes m';
  }

  _PlanView _premiumView(AppPrefsService prefs) {
    final record = prefs.wpSubscription;
    final active = prefs.isUserPremium &&
        (record == null || (record.active && !record.isExpired));
    return _PlanView(
      active: active,
      plan: _titleCase(record?.planLabel ?? prefs.subscriptionPlan ?? 'Weekly'),
      purchased: _formatMillis(
        record?.purchaseDateMs ?? prefs.subscriptionStartMillis,
      ),
      expires: _formatMillis(
        record?.expiryDateMs ?? prefs.subscriptionExpiryMillis,
      ),
      days: _daysLeft(record?.expiryDateMs ?? prefs.subscriptionExpiryMillis),
    );
  }

  _BoostView _boostView({
    required String title,
    required String planName,
    required LocalPlanRecord? record,
    required bool flag,
  }) {
    final active =
        flag && record != null && record.active && !record.isExpired;
    return _BoostView(
      title: title,
      active: active,
      plan: planName,
      purchased: _formatMillis(record?.purchaseDateMs),
      expires: _formatMillis(record?.expiryDateMs),
      days: _daysLeft(record?.expiryDateMs),
    );
  }

  String _formatMillis(int? millis) {
    if (millis == null || millis <= 0) return '-';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  int _daysLeft(int? millis) {
    if (millis == null || millis <= 0) return 0;
    final left = DateTime.fromMillisecondsSinceEpoch(millis).difference(
      DateTime.now(),
    );
    if (left.isNegative) return 0;
    return left.inDays;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.logoWhiteText,
      ),
    );
  }

  Widget _line(String text, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.logoWhiteText,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PlanView {
  const _PlanView({
    required this.active,
    required this.plan,
    required this.purchased,
    required this.expires,
    required this.days,
  });

  final bool active;
  final String plan;
  final String purchased;
  final String expires;
  final int days;
}

class _BoostView {
  const _BoostView({
    required this.title,
    required this.active,
    required this.plan,
    required this.purchased,
    required this.expires,
    required this.days,
  });

  final String title;
  final bool active;
  final String plan;
  final String purchased;
  final String expires;
  final int days;
}

class _TestCard extends StatelessWidget {
  const _TestCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: _PremiumTestPanelState._card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111111),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
