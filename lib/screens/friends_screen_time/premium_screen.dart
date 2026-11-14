import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/theme/app_theme.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/screens/friends_screen_time/flow_ui.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/friends_flow_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _weekly = true;
  bool _buying = false;

  Future<void> _buy() async {
    final config = AppBootstrap.remoteConfig.config;
    setState(() => _buying = true);
    showFlowProcessing();
    var ok = false;
    try {
      ok = await FriendsFlowController.instance.purchase(
        _weekly ? 'weekly' : 'monthly',
        _weekly ? config.package1Text : config.package2Text,
        _weekly ? config.packageId1 : config.packageId2,
      );
    } catch (_) {
      ok = false;
    }
    hideFlowProcessing();
    if (!mounted) return;
    setState(() => _buying = false);
    final closed = await _showPurchaseResultDialog(success: ok);
    if (!mounted) return;
    if (ok && closed) Get.back<void>();
  }

  Future<bool> _showPurchaseResultDialog({required bool success}) async {
    final result = await Get.dialog<bool>(
      Theme(
        data: AppTheme.light,
        child: Center(
          child: _PurchaseResultDialog(success: success),
        ),
      ),
      barrierColor: AppColors.overlay,
      barrierDismissible: !success,
    );
    return result ?? false;
  }

  void _select(bool weekly) {
    if (_weekly == weekly) return;
    HapticFeedback.selectionClick();
    setState(() => _weekly = weekly);
  }

  @override
  Widget build(BuildContext context) {
    final config = AppBootstrap.remoteConfig.config;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return LsScaffold(
      safeBottom: false,
      glowColor: AppColors.neon,
      glowOpacity: .18,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: SizedBox(
              height: 42,
              child: Row(
                children: [
                  LsHeaderButton(
                    icon: LsIconType.close,
                    semanticLabel: 'Close',
                    onTap: () => Get.back<void>(),
                  ),
                  const Expanded(child: Center(child: LsWordmark(fontSize: 12, dotSize: 7))),
                  GestureDetector(
                    onTap: () => showFlowToast('Purchases restored locally.'),
                    child: Text(
                      'RESTORE',
                      style: AppText.mono(11, FontWeight.w600, color: AppColors.muted, spacing: 1.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(14, 0, 14, 18 + bottom),
              children: [
                const Center(child: LsArt(LsArts.premiumHero, height: 170, fit: BoxFit.fill)),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    style: AppText.jakarta(28, FontWeight.w800, height: 1.15, spacing: -0.4),
                    children: [
                      const TextSpan(text: 'Screen Time + '),
                      TextSpan(
                        text: 'History',
                        style: AppText.jakarta(28, FontWeight.w800, color: AppColors.green, height: 1.15, spacing: -0.4).copyWith(
                              fontStyle: FontStyle.italic,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.neon.withValues(alpha: .55),
                              decorationThickness: 2,
                            ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  "See friends' screen time and keep every notification and deleted message.",
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
                ),
                const SizedBox(height: 16),
                const _FeatureGrid(),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PlanTile(
                        selected: _weekly,
                        title: config.package1Text,
                        price: r'$4.99',
                        per: 'per week',
                        onTap: () => _select(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlanTile(
                        selected: !_weekly,
                        title: config.package2Text,
                        price: r'$14.99',
                        per: 'per month',
                        detail: r'$3.75/WK',
                        badge: 'SAVE 25%',
                        onTap: () => _select(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _UnlockCta(enabled: !_buying, onPressed: _buy),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _link('PRIVACY POLICY', 'https://sites.google.com/view/seenx/privacy'),
                    Text('  ·  ', style: AppText.mono(10, FontWeight.w700, color: AppColors.finePrint)),
                    _link('TERMS OF USE', 'https://sites.google.com/view/seenx/terms'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Subscription is renewed monthly and weekly at the end of the term. It continues to renew unless you cancel it. You can cancel your subscription at any time through your Google account.',
                  textAlign: TextAlign.center,
                  style: AppText.jakarta(11.5, FontWeight.w400, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String url) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(label, style: AppText.mono(12, FontWeight.w800, color: AppColors.muted, spacing: .4)),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeatureCard(
                asset: LsArts.featureFriendsTime,
                title: "Friends' Time",
                subtitle: 'DAILY · PER APP',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _FeatureCard(
                asset: LsArts.featureStatistics,
                title: 'Full Statistics',
                subtitle: 'WEEK · TRENDS',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _FeatureCard(
          asset: LsArts.featureHistory,
          title: 'Unlimited History',
          subtitle: 'ALL APPS · SEARCH · SAVED FOREVER',
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.asset, required this.title, required this.subtitle});
  final String asset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [BoxShadow(color: AppColors.text.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LsArt(asset, height: 44, width: 44, fit: BoxFit.contain),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.jakarta(14.5, FontWeight.w800, height: 1.15),maxLines: 2,),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppText.mono(10, FontWeight.w600, color: AppColors.muted, spacing: .6),maxLines: 2,),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockCta extends StatefulWidget {
  const _UnlockCta({required this.enabled, required this.onPressed});
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_UnlockCta> createState() => _UnlockCtaState();
}

class _UnlockCtaState extends State<_UnlockCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : .55,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onPressed();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 64,
          transform: Matrix4.translationValues(0, _down ? 4 : 0, 0),
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(color: AppColors.goldEdge, offset: Offset(0, _down ? 0 : 4)),
              BoxShadow(
                color: AppColors.amberFill.withValues(alpha: _down ? .3 : .55),
                offset: const Offset(0, 14),
                blurRadius: 30,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'UNLOCK PREMIUM',
                  style: AppText.jakarta(15.5, FontWeight.w800, color: AppColors.boostInkGold, spacing: .5),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.chipAmberBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const LsArt(LsArts.crownTile, height: 30, width: 30, fit: BoxFit.contain),
                    ),
                    const Spacer(),
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.goldBottom.withValues(alpha: .35),
                        shape: BoxShape.circle,
                      ),
                      child: const LsIcon(LsIconType.chevron, size: 16, color: AppColors.boostInkGold, stroke: 2.4),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.selected,
    required this.title,
    required this.price,
    required this.per,
    required this.onTap,
    this.detail,
    this.badge,
  });

  final bool selected;
  final String title;
  final String price;
  final String per;
  final String? detail;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? AppColors.green : AppColors.stroke2,
                  width: selected ? 1.8 : 1.2,
                ),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.white,
                          AppColors.neon.withValues(alpha: .16),
                        ],
                        stops: const [0.55, 1],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: selected ? AppColors.neon.withValues(alpha: .28) : AppColors.text.withValues(alpha: .04),
                    blurRadius: selected ? 18 : 8,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.mono(
                            11,
                            FontWeight.w700,
                            color: selected ? AppColors.green : AppColors.muted,
                            spacing: .8,
                          ),
                        ),
                      ),
                      _RadioMark(selected: selected),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(price, style: AppText.jakarta(28, FontWeight.w800, height: 1)),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      text: per.toUpperCase(),
                      style: AppText.mono(11, FontWeight.w600, color: AppColors.grey, spacing: .4),
                      children: [
                        if (detail != null)
                          TextSpan(
                            text: '  ·  $detail',
                            style: AppText.mono(11, FontWeight.w600, color: AppColors.muted, spacing: .2),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -11,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amberFill,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: AppColors.amberFill.withValues(alpha: .35), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  badge!,
                  style: AppText.mono(9, FontWeight.w800, color: AppColors.white, spacing: .4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.green : AppColors.white,
        border: Border.all(color: selected ? AppColors.green : AppColors.dash, width: 1.6),
      ),
      child: selected ? const LsIcon(LsIconType.check, size: 12, color: AppColors.white, stroke: 2.6) : null,
    );
  }
}

class _PurchaseResultDialog extends StatelessWidget {
  const _PurchaseResultDialog({required this.success});
  final bool success;

  @override
  Widget build(BuildContext context) {
    return LsDialogCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              LsArt(
                success ? LsArts.crownTile : LsArts.premiumAccess,
                height: 56,
                width: 56,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              LsPill(
                success ? 'success' : 'failed',
                variant: success ? LsPillVariant.fill : LsPillVariant.amber,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            success ? 'Successfully Purchased Premium' : 'Premium Purchase Failed',
            style: AppText.jakarta(20, FontWeight.w800, height: 1.2),textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            success
                ? 'Your LifeSeen Premium is active. Enjoy friends’ screen time and unlimited notification history.'
                : 'Something went wrong and Premium could not be activated. Please try again.',
            style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          if (success)
            LsCta(
              label: 'Continue',
              icon: LsIconType.check,
              gold: true,
              centerLabel: true,
              onPressed: () => Get.back(result: true),
            )
          else
            Row(
              children: [
                Expanded(
                  child: LsSmallCta(
                    label: 'Close',
                    variant: LsSmallCtaVariant.ghost,
                    onPressed: () => Get.back(result: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LsSmallCta(
                    label: 'Try Again',
                    onPressed: () => Get.back(result: false),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
