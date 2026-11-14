import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/whatsapp_analyzer_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';
import 'package:tableflow_plus/widgets/ip_location_text.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';

class ConnectingWhatsAppScreen extends StatefulWidget {
  const ConnectingWhatsAppScreen({
    super.key,
    required this.country,
    required this.phoneNumber,
  });

  final Country country;
  final String phoneNumber;

  static const Duration viewButtonDelay = Duration(seconds: 3);

  @override
  State<ConnectingWhatsAppScreen> createState() =>
      _ConnectingWhatsAppScreenState();
}

class _ConnectingWhatsAppScreenState extends State<ConnectingWhatsAppScreen> {
  bool _showViewMessagesButton = false;
  Timer? _buttonTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_logIpDetails());
    _buttonTimer = Timer(ConnectingWhatsAppScreen.viewButtonDelay, () {
      if (mounted) setState(() => _showViewMessagesButton = true);
    });
  }

  Future<void> _logIpDetails() async {
    final location = AppBootstrap.ipLocation;
    await location.ensureFetched();
    if (!mounted) return;
    location.logDetails('ConnectingWhatsApp');
  }

  @override
  void dispose() {
    _buttonTimer?.cancel();
    super.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LifeSeenLogo(fontSize: 26, dark: true),
                  const SizedBox(height: 20),
                  _ProfileStatsCard(
                    country: widget.country,
                    phoneNumber: _displayPhone,
                  ),
                  const SizedBox(height: 14),
                  const _AnalysisStatusCard(),
                  const SizedBox(height: 14),
                  const _WhatsAppConnectionCard(),
                  const SizedBox(height: 20),
                  AnimatedOpacity(
                    opacity: _showViewMessagesButton ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSlide(
                      offset: _showViewMessagesButton
                          ? Offset.zero
                          : const Offset(0, 0.15),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: _showViewMessagesButton
                          ? AppCtaButton(
                              label: 'View Messages',
                              onTap: () {
                                Navigator.pushReplacement<void, void>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const WhatsAppAnalyzerScreen(),
                                  ),
                                );
                              },
                            )
                          : const SizedBox(height: 54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatsCard extends StatelessWidget {
  const _ProfileStatsCard({required this.country, required this.phoneNumber});

  final Country country;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        border: Border.all(color: AppColors.secureCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/icons/connect_profile.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
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
                        Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
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
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(
                child: _StatColumn(
                  asset: 'assets/icons/connect_shield.png',
                  label: 'OPERATOR',
                  value: 'airtel',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  asset: 'assets/icons/connect_clock.png',
                  label: 'LAST SEEN',
                  value: '13 minutes ago last seen',
                ),
              ),
              Expanded(
                child: _StatColumn(
                  asset: 'assets/icons/connect_chat.png',
                  label: 'MESSAGE',
                  value: '8700+',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _InfoChip(field: IpLocationField.country)),
              SizedBox(width: 8),
              Expanded(child: _InfoChip(field: IpLocationField.city)),
              SizedBox(width: 8),
              Expanded(child: _InfoChip(text: 'airtel', isAccent: true)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.asset,
    required this.label,
    required this.value,
  });

  final String asset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          asset,
          width: 46,
          height: 46,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.subtitleText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.logoWhiteText,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({this.text, this.field, this.isAccent = false});

  final String? text;
  final IpLocationField? field;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isAccent ? AppColors.logoAccent : AppColors.logoAccent,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: field == null
          ? Text(
              text ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            )
          : IpLocationText(
              field: field!,
              textAlign: TextAlign.center,
              style: style,
            ),
    );
  }
}

class _AnalysisStatusCard extends StatelessWidget {
  const _AnalysisStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        border: Border.all(color: AppColors.secureCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            'Operator',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.subtitleText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'airtel',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.logoWhiteText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Guide Analysis',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.subtitleText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analysis Completed',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.logoAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppConnectionCard extends StatelessWidget {
  const _WhatsAppConnectionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.secureCardBackground,
        border: Border.all(color: AppColors.secureCardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chat_rounded,
            color: AppColors.whatsAppGreen,
            size: 28,
          ),
          const SizedBox(width: 10),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.whatsAppGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 36, color: AppColors.progressTrack),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected to WhatsApp',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.logoWhiteText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Secure Connection',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.whatsAppGreen,
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

