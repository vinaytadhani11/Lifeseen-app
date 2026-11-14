import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/whatsapp_message_analyzed_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';
import 'package:tableflow_plus/widgets/ip_location_text.dart';

class SecureConnectionScreen extends StatefulWidget {
  const SecureConnectionScreen({
    super.key,
    required this.country,
    required this.phoneNumber,
  });

  final Country country;
  final String phoneNumber;

  static const Duration holdDuration = Duration(seconds: 16);

  @override
  State<SecureConnectionScreen> createState() => _SecureConnectionScreenState();
}

class _SecureConnectionScreenState extends State<SecureConnectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    unawaited(AppBootstrap.ipLocation.ensureFetched());
    _progressController = AnimationController(
      vsync: this,
      duration: SecureConnectionScreen.holdDuration,
    )..forward();

    _progressController.addStatusListener(_onProgressFinished);
  }

  void _onProgressFinished(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WhatsAppMessageAnalyzedScreen(
          country: widget.country,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressFinished);
    _progressController.dispose();
    super.dispose();
  }

  String get _statusTitle {
    final progress = _progressController.value;
    if (progress < 1 / 3) return 'Started';
    if (progress < 2 / 3) return 'Being Questioned';
    return 'Transaction Completed Successfully!';
  }

  String get _userStatusLabel {
    return _progressController.value >= 2 / 3 ? 'Completed' : 'Connecting...';
  }

  String get _displayPhone {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '01234 567890';
    if (digits.length <= 5) return digits;
    return '${digits.substring(0, digits.length - 5)} ${digits.substring(digits.length - 5)}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splashBackground,
      ),
      child: BlockBackNavigation(
        child: Scaffold(
          backgroundColor: AppColors.splashBackground,
          body: SafeArea(
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusCard(
                        statusTitle: _statusTitle,
                        progress: _progressController.value,
                      ),
                      const SizedBox(height: 20),
                      _UserInfoRow(
                        country: widget.country,
                        phoneNumber: _displayPhone,
                        statusLabel: _userStatusLabel,
                        isCompleted: _progressController.value >= 2 / 3,
                      ),
                      const SizedBox(height: 20),
                      const _WarningCard(),
                      const SizedBox(height: 20),
                      const _SecureConnectionBar(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.statusTitle, required this.progress});

  final String statusTitle;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            statusTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: statusTitle.length > 20 ? 15 : 18,
              fontWeight: FontWeight.w700,
              color: AppColors.logoAccent,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.progressTrack),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.logoAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _SecurityBadgesRow(),
        ],
      ),
    );
  }
}

class _SecurityBadgesRow extends StatelessWidget {
  const _SecurityBadgesRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _SecurityBadge(icon: Icons.vpn_key_rounded, label: 'AES-156'),
        ),
        Expanded(
          child: _SecurityBadge(
            icon: Icons.verified_user_rounded,
            label: 'SSL/TLS',
          ),
        ),
        Expanded(
          child: _SecurityBadge(icon: Icons.dns_rounded, label: 'API v2.1.4'),
        ),
      ],
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.logoAccent, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.logoWhiteText,
          ),
        ),
      ],
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.country,
    required this.phoneNumber,
    required this.statusLabel,
    required this.isCompleted,
  });

  final Country country;
  final String phoneNumber;
  final String statusLabel;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: AppColors.secureCardBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.logoWhiteText,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '***** *******',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.logoWhiteText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(country.flagEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      phoneNumber,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.logoWhiteText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.locationChipBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.logoWhiteText,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: IpLocationText(
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
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
        const SizedBox(width: 8),
        Text(
          statusLabel,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isCompleted ? AppColors.logoAccent : AppColors.logoAccent,
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warningOrange,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You may see a different name in the Name Surname section because the line may belong to another family member. However, the person using WhatsApp is the actual owner of the messages.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.subtitleText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecureConnectionBar extends StatelessWidget {
  const _SecureConnectionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.secureCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.logoAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Secure Connection Active',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.logoAccent,
            ),
          ),
        ],
      ),
    );
  }
}
