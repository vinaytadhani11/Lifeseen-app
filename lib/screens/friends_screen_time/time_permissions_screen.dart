import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';

class TimePermissionsScreen extends StatefulWidget {
  const TimePermissionsScreen({super.key, required this.onGranted});

  final VoidCallback onGranted;

  @override
  State<TimePermissionsScreen> createState() => _TimePermissionsScreenState();
}

class _TimePermissionsScreenState extends State<TimePermissionsScreen> with WidgetsBindingObserver {
  bool _waitingForSettings = false;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForSettings) {
      _check();
    }
  }

  Future<void> _check() async {
    if (await UsageStatsService.hasPermission()) {
      if (mounted) setState(() => _granted = true);
      widget.onGranted();
      return;
    }
    if (_waitingForSettings) await UsageStatsService.openSettings();
  }

  Future<void> _activate() async {
    _waitingForSettings = true;
    if (await UsageStatsService.hasPermission()) {
      if (mounted) setState(() => _granted = true);
      widget.onGranted();
      return;
    }
    await UsageStatsService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
        child: Column(
          children: [
            const SizedBox(height: 40, child: Center(child: LsWordmark())),
            const Expanded(
              child: Center(child: LsArt(LsArts.secureShield, height: 230)),
            ),
            Text('Activate Screen Time', textAlign: TextAlign.center, style: AppText.h1),
            const SizedBox(height: 6),
            Text('We need this permission to view apps.', textAlign: TextAlign.center, style: AppText.sub),
            const SizedBox(height: 14),
            const LsFeatureRow(
              icon: LsIconType.eye,
              title: 'View app usage',
              subtitle: 'Only time spent per app',
            ),
            const SizedBox(height: 8),
            const LsFeatureRow(
              icon: LsIconType.lock,
              color: AppColors.teal,
              title: 'Your data is securely protected',
              subtitle: 'Shared only with friends you approve',
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: '> status: ',
                style: AppText.mono(12, FontWeight.w400),
                children: [
                  TextSpan(
                    text: _granted ? 'granted' : 'awaiting usage access',
                    style: AppText.mono(12, FontWeight.w500, color: AppColors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCtaButton(label: 'Activate', onTap: _activate),
          ],
        ),
      ),
    );
  }
}
