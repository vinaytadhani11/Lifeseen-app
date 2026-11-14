import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  static const _pages = [
    (
      asset: LsArts.socialHub,
      title: "Your Friend's Screen Time",
      sub: 'See in detail how much time your friends spend on which apps',
    ),
    (
      asset: LsArts.focusDashboard,
      title: 'Focus on What Matters',
      sub: 'Manage your time wisely, reduce distractions, and achieve more with ease',
    ),
    (
      asset: LsArts.friendsNetwork,
      title: 'Build Better Habits Together',
      sub: 'Stay balanced and motivated with friends who share your goals',
    ),
  ];

  Future<void> _finish() async {
    await AppBootstrap.prefs.setOnboardingFinish(true);
    widget.onFinished();
  }

  void _next() {
    if (_page >= _pages.length - 1) {
      _finish();
      return;
    }
    _pager.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowPage(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _finish,
                child: Text('SKIP', style: AppText.mono(12, FontWeight.w700, color: AppColors.muted, spacing: 1.1)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: _pages.length,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _Page(asset: page.asset, title: page.title, subtitle: page.sub, index: index);
                },
              ),
            ),
            AppCtaButton(label: 'Continue', onTap: _next),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.index,
  });

  final String asset;
  final String title;
  final String subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(child: LsArt(asset, height: 300)),
        ),
        LsDots(count: 3, index: index),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: AppText.h1),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(subtitle, textAlign: TextAlign.center, style: AppText.sub),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
