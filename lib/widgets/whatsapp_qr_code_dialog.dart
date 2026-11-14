import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/widgets/block_back_navigation.dart';
import 'package:tableflow_plus/screens/whatsapp_mode/see_whatsapp_chats_screen.dart';

class WhatsAppQRCodeDialog {
  WhatsAppQRCodeDialog._();

  static const Duration holdDuration = Duration(seconds: 8);

  static const List<String> statusMessages = [
    'Scan the QR code...',
    'Verifying the QR code...',
    'Generating encryption keys...',
    'Establishing secure connection...',
    'Verifying session...',
    'Connection completed...',
    'Analysis completed. You are being redirected...',
  ];

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'WhatsApp QR Code',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _WhatsAppQRCodeDialogOverlay(parentContext: context);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _WhatsAppQRCodeDialogOverlay extends StatelessWidget {
  const _WhatsAppQRCodeDialogOverlay({required this.parentContext});

  final BuildContext parentContext;

  void _navigateToChats(BuildContext dialogContext) {
    if (Navigator.canPop(dialogContext)) {
      Navigator.pop(dialogContext);
    }
    if (!parentContext.mounted) return;
    Navigator.pushReplacement<void, void>(
      parentContext,
      MaterialPageRoute(builder: (_) => const SeeWhatsAppChatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlockBackNavigation(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _WhatsAppQRCodeDialogBody(
                  onCompleted: () => _navigateToChats(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhatsAppQRCodeDialogBody extends StatefulWidget {
  const _WhatsAppQRCodeDialogBody({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_WhatsAppQRCodeDialogBody> createState() =>
      _WhatsAppQRCodeDialogBodyState();
}

class _WhatsAppQRCodeDialogBodyState extends State<_WhatsAppQRCodeDialogBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: WhatsAppQRCodeDialog.holdDuration,
    )..forward();

    _holdTimer = Timer(WhatsAppQRCodeDialog.holdDuration, () {
      if (!mounted) return;
      widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _statusText {
    const messages = WhatsAppQRCodeDialog.statusMessages;
    if (messages.isEmpty) return '';

    final progress = _controller.value.clamp(0.0, 1.0);
    var index = (progress * messages.length).floor();
    if (index >= messages.length) {
      index = messages.length - 1;
    }
    return messages[index];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: AppColors.secureCardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.secureCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WhatsApp QR Code',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.whatsAppGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecting to WhatsApp Web...',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.logoWhiteText,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 320,
                child: Lottie.asset(
                  'assets/json/qr_code_black.json',
                  fit: BoxFit.contain,
                  frameRate: FrameRate.max,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: AppColors.progressTrack),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _controller.value.clamp(0.0, 1.0),
                        child: Container(color: AppColors.whatsAppGreen),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.subtitleText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
