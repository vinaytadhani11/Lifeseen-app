import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/theme/app_theme.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/screens/friends_screen_time/account_error_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/home_shell_screen.dart';
import 'package:tableflow_plus/screens/friends_screen_time/onboarding_screen.dart';
import 'package:tableflow_plus/screens/history/activate_screen_time_screen.dart';
import 'package:tableflow_plus/screens/history/choose_apps_screen.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';

class FriendsScreenTimeScreen extends StatefulWidget {
  const FriendsScreenTimeScreen({super.key});

  @override
  State<FriendsScreenTimeScreen> createState() => _FriendsScreenTimeScreenState();
}

class _FriendsScreenTimeScreenState extends State<FriendsScreenTimeScreen> {
  final _flow = FriendsFlowController.instance;
  bool _loading = true;
  bool _onboardingDone = false;
  bool _usageGranted = false;
  bool _chooseAppsPending = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    _onboardingDone = AppBootstrap.prefs.isOnboardingFinish;
    await _flow.prepareEntry();
    _usageGranted = await UsageStatsService.hasPermission();
    if (!mounted) return;
    setState(() => _loading = false);
    if (_onboardingDone && _usageGranted && _flow.accountReady) {
      await _flow.refreshUsage();
    }
  }

  Future<void> _afterActivate(ActivationResult result) async {
    if (!mounted) return;
    setState(() {
      _usageGranted = result.usageAccess;
      _chooseAppsPending = result.notificationAccess;
    });
    if (_usageGranted) await _flow.refreshUsage();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _BootSplash();
    if (_flow.accountLoadFailed) {
      return AccountErrorScreen(onRetry: () {
        setState(() => _loading = true);
        _boot();
      });
    }
    if (!_onboardingDone) {
      return OnboardingScreen(
        onFinished: () async {
          _usageGranted = await UsageStatsService.hasPermission();
          if (!mounted) return;
          setState(() => _onboardingDone = true);
          if (_usageGranted) await _flow.refreshUsage();
        },
      );
    }
    if (!_usageGranted) {
      return Theme(
        data: AppTheme.light,
        child: ActivateScreenTimeScreen(onContinue: _afterActivate),
      );
    }
    if (_chooseAppsPending) {
      void finishChooseApps() {
        if (!mounted) return;
        setState(() => _chooseAppsPending = false);
      }

      return Theme(
        data: AppTheme.light,
        child: ChooseAppsScreen(
          onSkip: finishChooseApps,
          onBack: finishChooseApps,
          onSaved: (_) => finishChooseApps(),
        ),
      );
    }
    return const HomeShellScreen();
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return LsScaffold(
      child: Column(
        children: [
          const Spacer(),
          const LsHeroTile(icon: LsIconType.eye, size: 84, iconSize: 40),
          const SizedBox(height: 18),
          const LsWordmark(fontSize: 22, dotSize: 12),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: AppColors.stroke,
                    color: AppColors.neon,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: '> syncing screen time ',
                    style: AppText.mono(12.5, FontWeight.w400),
                    children: [
                      TextSpan(text: '...', style: AppText.mono(12.5, FontWeight.w500, color: AppColors.green)),
                    ],
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
