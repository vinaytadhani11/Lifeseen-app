import 'package:flutter/material.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/friends_photo_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.code,
    required this.phone,
    required this.username,
    this.photoBytes,
  });

  final String code;
  final String phone;
  final String username;
  final Uint8List? photoBytes;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final entered = _code.text.trim().replaceAll(' ', '');
    if (entered.isEmpty) {
      await showFlowToast('Please enter verification code');
      return;
    }
    if (entered != widget.code.trim()) {
      await showFlowToast(
        'Verification failed. Enter the exact 6-digit code shown on the previous screen or in your notification.',
      );
      return;
    }
    showFlowProcessing();
    try {
      await FriendsFlowController.instance.saveRegisteredUser(
        phone: widget.phone,
        username: widget.username,
      );
      final photo = widget.photoBytes;
      if (photo != null) {
        try {
          final url = await uploadProfileBytes(
            FriendsFlowController.instance.documentId,
            photo,
          );
          await FriendsFlowController.instance.savePhotoUrl(url);
        } catch (_) {
          await showFlowToast('Photo could not be loaded');
        }
      }
      hideFlowProcessing();
      Get.back<void>();
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast('Could not save your account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      safeBottom: false,
      child: Column(
        children: [
          LsTopBar(onBack: () => Get.back<void>()),
          const Expanded(
            child: Center(child: LsArt(LsArts.otpSecure, height: 210)),
          ),
          LsSheet(
            children: [
              const Align(alignment: Alignment.centerLeft, child: LsPill('step 2 / 2 · verify')),
              const SizedBox(height: 12),
              Text('Verification Code', style: AppText.h2),
              const SizedBox(height: 6),
              Text(
                'Please enter the verification code and continue',
                style: AppText.jakarta(14, FontWeight.w400, color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              LsTextField(
                controller: _code,
                focusNode: _focus,
                hint: '6-digit code',
                mono: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                onSubmitted: (_) => _continue(),
              ),
              const SizedBox(height: 14),
              Text.rich(
                TextSpan(
                  text: '> code sent to ',
                  style: AppText.mono(12, FontWeight.w400),
                  children: [
                    TextSpan(text: widget.phone, style: AppText.mono(12, FontWeight.w500, color: AppColors.green)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCtaButton(label: 'Continue', onTap: _continue),
            ],
          ),
        ],
      ),
    );
  }
}
