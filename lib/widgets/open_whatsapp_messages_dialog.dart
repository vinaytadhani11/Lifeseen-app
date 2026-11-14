import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/config/app_config.dart';
import 'package:tableflow_plus/core/navigation/navigation_utils.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/subscription_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/ip_location_text.dart';
import 'package:url_launcher/url_launcher.dart';

/// Paywall shown to returning users (`isUserWhiteLineDialog == true`).
class OpenWhatsAppMessagesDialog {
  OpenWhatsAppMessagesDialog._();

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Open WhatsApp Messages',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const _OpenWhatsAppMessagesDialogOverlay(),
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _OpenWhatsAppMessagesDialogOverlay extends StatelessWidget {
  const _OpenWhatsAppMessagesDialogOverlay();

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
                  child: _OpenWhatsAppMessagesDialogBody(
                    onClose: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
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

class _OpenWhatsAppMessagesDialogBody extends StatefulWidget {
  const _OpenWhatsAppMessagesDialogBody({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_OpenWhatsAppMessagesDialogBody> createState() =>
      _OpenWhatsAppMessagesDialogBodyState();
}

class _OpenWhatsAppMessagesDialogBodyState
    extends State<_OpenWhatsAppMessagesDialogBody>
    with SingleTickerProviderStateMixin {
  bool _showCloseButton = false;
  SubscriptionPlan _plan = SubscriptionPlan.weekly;
  bool _isPurchasing = false;
  Timer? _closeTimer;
  late final AnimationController _progressController;

  static const _goldGradient = LinearGradient(
    colors: [Color(0xFF3D3520), Color(0xFF2A2418)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

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
    _progressController.dispose();
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

  Future<void> _onDisconnect() async {
    await AppBootstrap.prefs.disconnectWhatsApp();
    NavigationUtils.toEnterNumber();
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
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
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
              const SizedBox(height: 14),
              _ProfileHeader(onDisconnect: _onDisconnect),
              const SizedBox(height: 14),
              _GoldFeatureCard(
                gradient: _goldGradient,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A4028),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD54F),
                    size: 22,
                  ),
                ),
                title: 'Open WhatsApp messages',
                subtitle: 'A subscription is required to view messages',
                showShield: true,
              ),
              const SizedBox(height: 16),
              _DecryptProgressSection(controller: _progressController),
              const SizedBox(height: 14),
              const _GoldFeatureCard(
                gradient: _goldGradient,
                leading: Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFFFD54F),
                  size: 24,
                ),
                title: 'View all WhatsApp messages',
                subtitle: 'Instant Access to Encrypted Content',
                trailing: Icon(
                  Icons.lock_rounded,
                  color: Color(0xFFFFD54F),
                  size: 22,
                ),
              ),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onDisconnect});

  final VoidCallback onDisconnect;

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
    return countries
        .firstWhere((c) => c.isoCode == iso, orElse: () => defaultCountry)
        .flagEmoji;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFF2D3748),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: Color(0xFF8696A0)),
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
                  _DisconnectButton(onTap: onDisconnect),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}

class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF4D4D)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.power_settings_new_rounded,
                size: 14,
                color: Color(0xFFFF4D4D),
              ),
              const SizedBox(width: 4),
              Text(
                'Disconnect',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF4D4D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldFeatureCard extends StatelessWidget {
  const _GoldFeatureCard({
    required this.gradient,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.showShield = false,
    this.trailing,
  });

  final LinearGradient gradient;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool showShield;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A4028)),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD54F),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showShield) ...[
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 12,
                        color: Color(0xFFB8860B),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFB8860B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _DecryptProgressSection extends StatelessWidget {
  const _DecryptProgressSection({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final step = (controller.value * 5).floor().clamp(0, 4);

        return Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A9B7A).withValues(alpha: 0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A9B7A).withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: Color(0xFF1A9B7A),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Decrypting password ...',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.logoWhiteText,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(5, (index) {
                final isActive = index <= step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF1A9B7A)
                          : const Color(0xFF2E3338),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFF3A4048),
                ),
                SizedBox(width: 20),
                Icon(Icons.storage_rounded, size: 16, color: Color(0xFF3A4048)),
                SizedBox(width: 20),
                Icon(
                  Icons.message_outlined,
                  size: 16,
                  color: Color(0xFF3A4048),
                ),
              ],
            ),
          ],
        );
      },
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
