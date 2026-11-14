import 'package:flutter/material.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_country_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friends_gate.dart';
import 'package:tableflow_plus/screens/friends_screen_time/friendship_status_screen.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';

class PersonsTab extends StatefulWidget {
  const PersonsTab({super.key});

  @override
  State<PersonsTab> createState() => _PersonsTabState();
}

class _PersonsTabState extends State<PersonsTab> {
  final _phone = TextEditingController();
  final _flow = FriendsFlowController.instance;
  late Country _country = friendsDefaultCountry();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final selected = await Get.to<Country>(() => FriendsCountryScreen(selected: _country));
    if (selected != null) setState(() => _country = selected);
  }

  Future<void> _continue() async {
    if (!await passFriendsGate()) return;
    if (!isValidNationalPhone(_country, _phone.text)) {
      await showFlowToast('Invalid phone number');
      return;
    }
    showFlowProcessing();
    try {
      final result = await _flow.lookupPhone(fullPhone(_country, _phone.text));
      hideFlowProcessing();
      await _handle(result.status, result.uid);
    } catch (_) {
      hideFlowProcessing();
      await showFlowToast('Could not look up that number');
    }
  }

  Future<void> _handle(String status, String uid) async {
    switch (status) {
      case 'UserNotFound':
        final share = await confirmFlowDialog(
          title: 'User Not Found',
          message: 'Send an invitation to the person you want to add as a friend',
          positive: 'Share The App',
        );
        if (share) await shareSeenX();
      case 'ownProfile':
        await confirmFlowDialog(
          title: 'You Cannot Add Your Own Profile',
          message: 'You cannot add your own profile as a friend.',
          positive: 'OK',
          negative: null,
        );
      case 'alreadyFriends':
        await Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.friendsStatics));
      case 'requestSent':
        await Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.sentRequests));
      case 'requestReceived':
        await Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.requestsReceived));
      default:
        final send = await _notFriends();
        if (!send) return;
        showFlowProcessing();
        try {
          await _flow.sendRequest(uid);
          hideFlowProcessing();
          await showFlowToast('Friendship Request Sent');
        } catch (_) {
          hideFlowProcessing();
          await showFlowToast('Could not send the request');
        }
    }
  }

  Future<bool> _notFriends() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final result = await Get.dialog<bool>(
      Center(
        child: LsDialogCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  LsArt(LsArts.userRemove, height: 56, width: 56),
                  Spacer(),
                  LsPill('not connected', variant: LsPillVariant.amber),
                ],
              ),
              const SizedBox(height: 12),
              Text('You Are Not Friends', style: AppText.jakarta(20, FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'You need to add this person as a friend first to see their screen time.',
                style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    LsFlag(_country),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_country.formattedDialCode} $digits',
                        style: AppText.mono(14, FontWeight.w500, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LsSmallCta(
                      label: 'Cancel',
                      variant: LsSmallCtaVariant.ghost,
                      onPressed: () => Get.back(result: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: LsSmallCta(label: 'Send Request', onPressed: () => Get.back(result: true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierColor: AppColors.overlay,
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 130 + inset),
      children: [
        Text('Add Person', style: AppText.h1),
        const SizedBox(height: 4),
        const LsCaption('// enter the phone number of the person you want'),
        const SizedBox(height: 16),
        const Center(child: LsArt(LsArts.envelopeAdd, height: 96)),
        const SizedBox(height: 14),
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
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]'))],
                onSubmitted: (_) => _continue(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCtaButton(label: 'Continue', onTap: _continue),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Text('FRIENDS', style: AppText.mono(11, FontWeight.w700, spacing: 1.1))),
            GestureDetector(
              onTap: () async {
                if (!await passFriendsGate()) return;
                await Get.to<void>(() => const FriendshipStatusScreen(mode: FriendshipMode.friendsStatics));
              },
              child: Text('VIEW ALL →', style: AppText.mono(11, FontWeight.w700, color: AppColors.green, spacing: 1.1)),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Center(child: LsArt(LsArts.noFriends, height: 220)),
      ],
    );
  }
}
