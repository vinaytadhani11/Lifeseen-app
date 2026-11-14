import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/config/app_config.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';
import 'package:tableflow_plus/services/subscription_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/ip_location_text.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenMessagesDialog {
  OpenMessagesDialog._();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Open Messages',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _OpenMessagesDialogOverlay(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _OpenMessagesDialogOverlay extends StatelessWidget {
  const _OpenMessagesDialogOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                14,
                14,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: _OpenMessagesDialogBody(
                    onClose: () {
                      final wasPremium = AppBootstrap.prefs.isUserPremium;
                      unawaited(
                        AppBootstrap.prefs.setUserWhiteLineDialog(true),
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      // MessagesReady closed + not premium → ask POST_NOTIFICATIONS.
                      if (!wasPremium) {
                        unawaited(
                          NotificationScheduler.requestNotificationPermission(),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenMessagesDialogBody extends StatefulWidget {
  const _OpenMessagesDialogBody({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_OpenMessagesDialogBody> createState() =>
      _OpenMessagesDialogBodyState();
}

class _OpenMessagesDialogBodyState extends State<_OpenMessagesDialogBody> {
  bool _showCloseButton = false;
  SubscriptionPlan _plan = SubscriptionPlan.weekly;
  bool _isPurchasing = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    final delay = AppBootstrap.remoteConfig.config.closeButtonDelay;
    if (delay == Duration.zero) {
      _showCloseButton = true;
    } else if (delay != null) {
      _closeTimer = Timer(delay, () {
        if (mounted) setState(() => _showCloseButton = true);
      });
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  Future<void> _onOpenMessagesNow() async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);
    // Local subscription only: no Play Store / RevenueCat purchase.
    await AppBootstrap.subscription.subscribeLocally(_plan);
    if (!mounted) return;
    Fluttertoast.showToast(
      msg: 'Subscription successful',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF1C1E2A),
      textColor: Colors.white,
      fontSize: 15,
    );
    widget.onClose();
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF141A1E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF252636)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedOpacity(
                    opacity: _showCloseButton ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !_showCloseButton,
                      child: Material(
                        color: const Color(0xFF252636),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: widget.onClose,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 32,
                            height: 32,
                            child: Icon(
                              Icons.close_rounded,
                              color: AppColors.logoWhiteText,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StatusBanner(),
              const SizedBox(height: 12),
              const _ProfileCard(),
              const SizedBox(height: 16),
              _PremiumHeader(),
              const SizedBox(height: 12),
              const _FeatureGrid(),
              const SizedBox(height: 12),
              const _SecureBadge(),
              const SizedBox(height: 14),
              if (AppBootstrap.remoteConfig.config.showPlanTabs) ...[
                _PlanSelector(
                  plan: _plan,
                  onChanged: (plan) => setState(() => _plan = plan),
                ),
                const SizedBox(height: 10),
              ],
              _PriceRow(plan: _plan),
              const SizedBox(height: 16),
              AppCtaButton(
                label: 'Open Messages Now',
                onTap: _onOpenMessagesNow,
              ),
              const SizedBox(height: 14),
              _LegalFooter(onLinkTap: _openLink),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3D2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A5A40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A5A40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFFFD54F),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open WhatsApp messages',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.whatsAppGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: AppColors.whatsAppGreen,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Encrypted Messages are available for access',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8E9194),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  String get _phone {
    final digits = (AppBootstrap.prefs.phoneNumber ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (digits.isEmpty) return '01234 567890';
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, digits.length - 5)} '
        '${digits.substring(digits.length - 5)}';
  }

  String get _flag {
    final iso = AppBootstrap.prefs.phoneCountryIso ?? defaultCountry.isoCode;
    final country = countries.firstWhere(
      (c) => c.isoCode == iso,
      orElse: () => defaultCountry,
    );
    return country.flagEmoji;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF2D3748),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF8696A0),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '***** *****',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.logoWhiteText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.whatsAppGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+4000 messages',
                        style: GoogleFonts.montserrat(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whatsAppGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(_flag, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      _phone,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.logoWhiteText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B4A6B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.logoWhiteText,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: IpLocationText(
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.logoWhiteText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.workspace_premium_rounded,
          color: Color(0xFFFFD54F),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Premium Features are active',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.logoWhiteText,
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeatureTile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'All messages',
            color: Color(0xFF1A3D2E),
            iconColor: AppColors.whatsAppGreen,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeatureTile(
            icon: Icons.perm_media_outlined,
            label: 'Media',
            color: Color(0xFF1A2840),
            iconColor: Color(0xFF53BDEB),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _FeatureTile(
            icon: Icons.restore_rounded,
            label: 'Deleted',
            color: Color(0xFF3D2A1A),
            iconColor: Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.logoWhiteText,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureBadge extends StatelessWidget {
  const _SecureBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.whatsAppGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure & verified',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logoWhiteText,
                  ),
                ),
                Text(
                  'Encrypted with 256-bit SSL',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8696A0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({required this.plan, required this.onChanged});

  final SubscriptionPlan plan;
  final ValueChanged<SubscriptionPlan> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2430),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PlanTab(
              label: SubscriptionPlan.weekly.label,
              isSelected: plan == SubscriptionPlan.weekly,
              onTap: () => onChanged(SubscriptionPlan.weekly),
            ),
          ),
          Expanded(
            child: _PlanTab(
              label: SubscriptionPlan.monthly.label,
              isSelected: plan == SubscriptionPlan.monthly,
              onTap: () => onChanged(SubscriptionPlan.monthly),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2A3F55) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.logoWhiteText
                  : const Color(0xFF8696A0),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          plan.dailyPrice,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.logoWhiteText,
          ),
        ),
        Text(
          plan.periodPrice,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF8696A0),
          ),
        ),
      ],
    );
  }
}


class _LegalFooter extends StatelessWidget {
  const _LegalFooter({required this.onLinkTap});

  final Future<void> Function(String url) onLinkTap;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 11,
      color: Color(0xFF8696A0),
      height: 1.4,
    );
    const linkStyle = TextStyle(
      fontSize: 11,
      color: Color(0xFF1A9B7A),
      fontWeight: FontWeight.w600,
      height: 1.4,
    );

    return Text.rich(
      TextSpan(
        style: GoogleFonts.montserrat(textStyle: baseStyle),
        children: [
          const TextSpan(text: 'By continuing, you agree to the '),
          TextSpan(
            text: 'Terms of Service',
            style: GoogleFonts.montserrat(textStyle: linkStyle),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onLinkTap(AppConfig.termsOfUseUrl),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: GoogleFonts.montserrat(textStyle: linkStyle),
            recognizer: TapGestureRecognizer()
              ..onTap = () => onLinkTap(AppConfig.privacyPolicyUrl),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
