import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/secure_connection_screen.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/select_country_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:tableflow_plus/widgets/lifeseen_logo.dart';

class EnterNumberScreen extends StatefulWidget {
  const EnterNumberScreen({super.key});

  @override
  State<EnterNumberScreen> createState() => _EnterNumberScreenState();
}

class _EnterNumberScreenState extends State<EnterNumberScreen> {
  final _random = Random();
  Country _selectedCountry = defaultCountry;
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    setState(() {});
  }

  bool get _hasPhoneNumber => _phoneController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _phoneController
      ..removeListener(_onPhoneChanged)
      ..dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openCountryPicker() async {
    _phoneFocusNode.unfocus();
    final result = await Navigator.push<Country>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectCountryScreen(selectedCountry: _selectedCountry),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedCountry = result);
    }
  }

  Future<void> _onViewPressed() async {
    if (_isProcessing || !_hasPhoneNumber) return;

    _phoneFocusNode.unfocus();
    setState(() => _isProcessing = true);

    final delayMs = 4000 + _random.nextInt(1001);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    if (!mounted) return;

    final prefs = AppBootstrap.prefs;
    await prefs.setPhoneNumber(_phoneController.text.trim());
    await prefs.setPhoneCountryIso(_selectedCountry.isoCode);
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    await prefs.setWpLoginNumber('+${_selectedCountry.dialCode}$digits');
    if (!mounted) return;

    await Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute(
        builder: (_) => SecureConnectionScreen(
          country: _selectedCountry,
          phoneNumber: _phoneController.text.trim(),
        ),
      ),
    );

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.splashBackground,
      ),
      child: Scaffold(
        backgroundColor: AppColors.splashBackground,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const LifeSeenLogo(fontSize: 28, dark: true),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _ZeroIntrinsicHeight(
                        child: Lottie.asset(
                          'assets/json/user.json',
                          fit: BoxFit.contain,
                          frameRate: FrameRate.max,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.logoWhiteText,
                            height: 1.3,
                          ),
                          children: const [
                            TextSpan(text: 'View '),
                            TextSpan(
                              text: 'WhatsApp',
                              style: TextStyle(color: AppColors.whatsAppGreen),
                            ),
                            TextSpan(text: ' Messages'),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        'Enter the phone number of the person whose messages you want to see',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.subtitleText,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _CountryPickerButton(
                                  country: _selectedCountry,
                                  onTap: _isProcessing
                                      ? null
                                      : _openCountryPicker,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PhoneNumberField(
                                    controller: _phoneController,
                                    focusNode: _phoneFocusNode,
                                    enabled: !_isProcessing,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'The entered number is used only to view WhatsApp messages and location information.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.subtitleText,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            AppCtaButton(
                              label: _isProcessing ? 'Processing...' : 'View',
                              onTap: _onViewPressed,
                              enabled: !_isProcessing && _hasPhoneNumber,
                            ),
                            const SizedBox(height: 14),
                            _TermsFooter(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerButton extends StatelessWidget {
  const _CountryPickerButton({required this.country, required this.onTap});

  final Country country;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                country.formattedDialCode,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.logoWhiteText,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.logoWhiteText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneNumberField extends StatelessWidget {
  const _PhoneNumberField({
    required this.controller,
    required this.focusNode,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        cursorColor: AppColors.cursorGreen,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.logoWhiteText,
        ),
        decoration: InputDecoration(
          hintText: 'Enter Number',
          hintStyle: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.placeholderText,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.montserrat(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: AppColors.subtitleText,
      height: 1.45,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to the '),
          TextSpan(
            text: 'Terms of Service',
            style: baseStyle.copyWith(
              color: AppColors.linkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: baseStyle.copyWith(
              color: AppColors.linkText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Keeps the illustration out of the column's intrinsic height.
///
/// [SliverFillRemaining] sizes the page from that height. Reporting zero lets
/// the animation take leftover space on a tall screen, and collapse so the
/// form can scroll when the window is short.
class _ZeroIntrinsicHeight extends SingleChildRenderObjectWidget {
  const _ZeroIntrinsicHeight({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderZeroIntrinsicHeight();
  }
}

class _RenderZeroIntrinsicHeight extends RenderProxyBox {
  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) => 0;
}
