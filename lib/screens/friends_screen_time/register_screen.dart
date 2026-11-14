import 'package:flutter/material.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_country_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/verification_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/friends_photo_service.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late Country _country = friendsDefaultCountry();
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    NotificationScheduler.requestNotificationPermission();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final bytes = await pickSquareProfilePhoto();
      if (bytes == null) return;
      setState(() => _photoBytes = bytes);
    } catch (_) {
      await showFlowToast('Photo could not be loaded');
    }
  }

  Future<void> _continue() async {
    if (!isValidNationalPhone(_country, _phone.text)) {
      await showFlowToast('Invalid phone number');
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      await showFlowToast('Enter your name');
      return;
    }
    final code = FriendsFlowController.instance.newVerificationCode();
    final notificationsOn = await NotificationScheduler.notificationsEnabled();
    if (notificationsOn) {
      await NotificationScheduler.showVerificationCode(code);
    }
    await Clipboard.setData(ClipboardData(text: code));
    final go = await confirmFlowDialog(
      title: 'Verification Code',
      message: notificationsOn
          ? 'Enter this exact code on the next screen. It has been copied to your clipboard.\n\n$code'
          : 'Enter this exact code on the next screen. It has been copied to your clipboard.\n\n$code\n\nNotifications are off. Use the code shown above (also copied to clipboard).',
      positive: 'Continue',
      negative: 'Cancel',
      barrierDismissible: false,
    );
    if (!go) return;
    await Get.off<void>(
      () => VerificationScreen(
        code: code,
        phone: fullPhone(_country, _phone.text),
        username: name,
        photoBytes: _photoBytes,
      ),
    );
  }

  Future<void> _pickCountry() async {
    final selected = await Get.to<Country>(() => FriendsCountryScreen(selected: _country));
    if (selected != null) setState(() => _country = selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photoBytes != null;
    return LsScaffold(
      safeBottom: false,
      child: Column(
        children: [
          LsTopBar(onBack: () => Get.back<void>()),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    children: [
                      const LsDashedRing(size: 132),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.white,
                            image: hasPhoto ? DecorationImage(image: MemoryImage(_photoBytes!), fit: BoxFit.cover) : null,
                          ),
                          child: hasPhoto ? null : const LsIcon(LsIconType.user, size: 44, color: AppColors.muted),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 6,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.btnGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LsIcon(hasPhoto ? LsIconType.check : LsIconType.camera, size: 19, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          LsSheet(
            children: [
              const Align(alignment: Alignment.centerLeft, child: LsPill('step 1 / 2 · profile')),
              const SizedBox(height: 12),
              Text('Complete Your Information', style: AppText.h2),
              const SizedBox(height: 6),
              Text('Enter your phone number and name', style: AppText.jakarta(14, FontWeight.w400, color: AppColors.grey)),
              const SizedBox(height: 12),
              LsTextField(controller: _name, hint: 'Name', icon: LsIconType.user, textCapitalization: TextCapitalization.words),
              const SizedBox(height: 12),
              Row(
                children: [
                  LsCountryCodeChip(country: _country, onTap: _pickCountry),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LsTextField(
                      controller: _phone,
                      hint: 'Phone number',
                      mono: true,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                      onSubmitted: (_) => _continue(),
                    ),
                  ),
                ],
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
