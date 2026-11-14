import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';

class WhatsAppAnalyzedDialog {
  WhatsAppAnalyzedDialog._();

  static const Duration holdDuration = Duration(seconds: 7);

  static const List<String> statusMessages = [
    'Your WhatsApp chats are being analyzed...',
    'Checking media files...',
    'Scanning deleted messages....',
    'Retrieving contact information...',
    'Preparing conversations...',
    'Upload complete.',
  ];
}

/// Full-screen blur overlay with centered analysis progress dialog.
class WhatsAppAnalyzedDialogOverlay extends StatefulWidget {
  const WhatsAppAnalyzedDialogOverlay({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<WhatsAppAnalyzedDialogOverlay> createState() =>
      _WhatsAppAnalyzedDialogOverlayState();
}

class _WhatsAppAnalyzedDialogOverlayState
    extends State<WhatsAppAnalyzedDialogOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: WhatsAppAnalyzedDialog.holdDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            widget.onCompleted();
          }
        });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _statusText {
    const messages = WhatsAppAnalyzedDialog.statusMessages;
    if (messages.isEmpty) return '';

    final progress = _controller.value.clamp(0.0, 1.0);
    var index = (progress * messages.length).floor();
    if (index >= messages.length) {
      index = messages.length - 1;
    }
    return messages[index];
  }

  int get _percent {
    return (7 + (_controller.value * 93)).round().clamp(7, 100);
  }

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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C3E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/json/social.png',
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(height: 24),
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
                                  widthFactor: _controller.value.clamp(
                                    0.07,
                                    1.0,
                                  ),
                                  child: Container(
                                    color: AppColors.whatsAppGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_percent%',
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.whatsAppGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.subtitleText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
