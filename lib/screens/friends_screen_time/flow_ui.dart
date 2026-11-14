import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tableflow_plus/core/navigation/navigation_utils.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';
import 'package:tableflow_plus/core/theme/app_theme.dart';
import 'package:tableflow_plus/core/widgets/ls_icons.dart';
import 'package:tableflow_plus/core/widgets/ls_kit.dart';
import 'package:tableflow_plus/core/widgets/ls_surface.dart';
import 'package:tableflow_plus/data/countries.dart';
import 'package:tableflow_plus/models/country.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';
import 'package:tableflow_plus/widgets/app_cta_button.dart';

const emptyScreenTimeText =
    'No screen time available yet; it will appear here once created';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _turkishMonths = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

String homeDateLabel(DateTime day) =>
    '${day.day} ${_months[day.month - 1]}, ${day.year}';

String calendarPickedLabel(DateTime day) =>
    '${day.day} ${_turkishMonths[day.month - 1]} ${day.year}';

String statsDateLabel(DateTime day) =>
    '${_months[day.month - 1]} ${day.day}, ${day.year}';

String clockLabel(double epochSeconds) {
  final time = DateTime.fromMillisecondsSinceEpoch((epochSeconds * 1000).round());
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String chatListTimeLabel(double epochSeconds) {
  final time = DateTime.fromMillisecondsSinceEpoch((epochSeconds * 1000).round());
  final now = DateTime.now();
  if (isSameDay(time, now)) return clockLabel(epochSeconds);
  if (isSameDay(time, now.subtract(const Duration(days: 1)))) return 'YDAY';
  return '${time.day.toString().padLeft(2, '0')} ${_months[time.month - 1].substring(0, 3)}';
}

String chatDayPillLabel(DateTime day) {
  final now = DateTime.now();
  if (isSameDay(day, now)) return 'TODAY';
  if (isSameDay(day, now.subtract(const Duration(days: 1)))) return 'YDAY';
  return '${day.day} ${_months[day.month - 1].substring(0, 3).toUpperCase()}';
}

String planDateLabel(int millis) {
  final time = DateTime.fromMillisecondsSinceEpoch(millis);
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  final month = _months[time.month - 1].substring(0, 3);
  return '${time.day.toString().padLeft(2, '0')} $month ${time.year}, $hour:$minute';
}

Country friendsDefaultCountry() {
  if (kIsWeb) {
    return countries.firstWhere((country) => country.isoCode == 'US');
  }
  final parts = Platform.localeName.split(RegExp(r'[_-]'));
  final iso = parts.isEmpty ? '' : parts.last.toUpperCase();
  return countries.firstWhere(
    (country) => country.isoCode == iso,
    orElse: () => countries.firstWhere((country) => country.isoCode == 'US'),
  );
}

String fullPhone(Country country, String national) {
  final digits = national.replaceAll(RegExp(r'\D'), '');
  return '${country.formattedDialCode}$digits';
}

bool isValidNationalPhone(Country country, String national) {
  final digits = national.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return false;
  try {
    final iso = IsoCode.values.byName(country.isoCode);
    return PhoneNumber.parse(digits, destinationCountry: iso).isValid();
  } catch (_) {
    return digits.length >= 6 && digits.length <= 14;
  }
}

Future<void> shareSeenX() async {
  final info = await PackageInfo.fromPlatform();
  await Share.share(
    'Hello, how about using the SeenX app?\n'
    'https://play.google.com/store/apps/details?id=${info.packageName}',
  );
}

Future<void> showFlowToast(String message) {
  return Fluttertoast.showToast(
    msg: message,
    backgroundColor: AppColors.mint,
    textColor: AppColors.text,
  );
}

Future<bool> confirmFlowDialog({
  required String title,
  required String message,
  required String positive,
  String? negative,
  bool barrierDismissible = true,
}) async {
  final result = await Get.dialog<bool>(
    Theme(
      data: AppTheme.light,
      child: Center(
        child: LsDialogCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.jakarta(20, FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message, style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45)),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (negative != null) ...[
                    Expanded(
                      child: LsSmallCta(
                        label: negative,
                        variant: LsSmallCtaVariant.ghost,
                        onPressed: () => Get.back(result: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: LsSmallCta(label: positive, onPressed: () => Get.back(result: true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    barrierColor: AppColors.overlay,
    barrierDismissible: barrierDismissible,
  );
  return result ?? false;
}

class FlowPage extends StatelessWidget {
  const FlowPage({
    super.key,
    required this.child,
    this.bottom,
  });

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: LsScaffold(
        safeBottom: bottom == null,
        child: bottom == null
            ? child
            : Column(
                children: [
                  Expanded(child: child),
                  bottom!,
                ],
              ),
      ),
    );
  }
}

class FlowBackButton extends StatelessWidget {
  const FlowBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return LsHeaderButton(
      icon: LsIconType.back,
      semanticLabel: 'Back',
      onTap: onPressed ?? () => Get.back<void>(),
    );
  }
}

class FlowContinueButton extends StatelessWidget {
  const FlowContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCtaButton(label: label, onTap: onPressed, enabled: onPressed != null);
  }
}

class ScreenTimeTile extends StatefulWidget {
  const ScreenTimeTile({super.key, required this.app});

  final ScreenTimeApp app;

  @override
  State<ScreenTimeTile> createState() => _ScreenTimeTileState();
}

class _ScreenTimeTileState extends State<ScreenTimeTile> {
  Uint8List? _logo;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  @override
  void didUpdateWidget(ScreenTimeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app.packageName != widget.app.packageName ||
        oldWidget.app.name != widget.app.name) {
      _loadLogo();
    }
  }

  Future<void> _loadLogo() async {
    final bytes = await UsageStatsService.appIcon(
      packageName: widget.app.packageName,
      name: widget.app.name,
    );
    if (!mounted) return;
    setState(() => _logo = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final limit = app.sortSeconds >= 3600;
    final fraction = (app.sortSeconds / (4 * 3600)).clamp(0.04, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Row(
          children: [
            LsAppChip(lsAppKind(app.name, app.packageName), size: 44, bytes: _logo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.jakarta(15, FontWeight.w700),
                        ),
                      ),
                      if (limit) ...[
                        const SizedBox(width: 8),
                        const LsPill('limit', variant: LsPillVariant.amber, fontSize: 9),
                      ],
                      const SizedBox(width: 8),
                      Text(compactAppTime(app), style: AppText.mono(13, FontWeight.w500, color: AppColors.text)),
                    ],
                  ),
                  const SizedBox(height: 7),
                  LsUsageBar(value: fraction, amber: limit),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String compactAppTime(ScreenTimeApp app) {
  if (app.hours <= 0) return '${app.minutes}m';
  return '${app.hours}h ${app.minutes.toString().padLeft(2, '0')}m';
}

String compactMinutes(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h <= 0) return '${m}m';
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}

abstract final class LsArts {
  static const otpSecure = 'assets/icons/3d/otp_secure.png';
  static const secureShield = 'assets/icons/3d/secure_shield.png';
  static const notificationBell = 'assets/icons/3d/notification_bell.png';
  static const usageAccess = 'assets/icons/3d/usage_access.png';
  static const notificationAccess = 'assets/icons/3d/notification_access.png';
  static const addFriends = 'assets/icons/3d/add_friends.png';
  static const noMessages = 'assets/icons/3d/no_messages.png';
  static const noNotifications = 'assets/icons/3d/no_notifications.png';
  static const focusDashboard = 'assets/icons/3d/focus_dashboard.png';
  static const envelopeAdd = 'assets/icons/3d/envelope_add.png';
  static const crownPremium = 'assets/icons/3d/crown_premium.png';
  static const crownTile = 'assets/icons/3d/crown_tile.png';
  static const premiumAccess = 'assets/icons/3d/premium_access.png';
  static const premiumHero = 'assets/icons/3d/premium_hero.png';
  static const featureFriendsTime = 'assets/icons/3d/feature_friends_time.png';
  static const featureStatistics = 'assets/icons/3d/feature_statistics.png';
  static const featureHistory = 'assets/icons/3d/feature_history.png';
  static const featurePhotos = 'assets/icons/3d/feature_photos.png';
  static const friendsNetwork = 'assets/icons/3d/friends_network.png';
  static const paperPlaneCard = 'assets/icons/3d/paper_plane_card.png';
  static const userRemove = 'assets/icons/3d/user_remove.png';
  static const noFriends = 'assets/icons/3d/no_friends.png';
  static const socialHub = 'assets/icons/3d/social_hub.png';
  static const home = 'assets/icons/3d/home.png';
  static const completeProfile = 'assets/icons/complete_profile.png';
  static const settingsGear = 'assets/icons/settings_gear.png';
  static const iconProfile = 'assets/icons/3d/icon_profile.png';
  static const iconPhone = 'assets/icons/3d/icon_phone.png';
  static const iconFriends = 'assets/icons/3d/icon_friends.png';
  static const iconSent = 'assets/icons/3d/icon_sent.png';
  static const iconReceived = 'assets/icons/3d/icon_received.png';
  static const iconBell = 'assets/icons/3d/icon_bell.png';
  static const iconDocument = 'assets/icons/3d/icon_document.png';
  static const iconStar = 'assets/icons/3d/icon_star.png';
  static const iconTrash = 'assets/icons/3d/icon_trash.png';
  static const iconLogout = 'assets/icons/3d/icon_logout.png';
  static const iconApps = 'assets/icons/3d/icon_apps.png';
  static const iconPause = 'assets/icons/3d/icon_pause.png';
  static const iconShare = 'assets/icons/3d/icon_share.png';
  static const iconForever = 'assets/icons/3d/icon_forever.png';
}

class LsArt extends StatelessWidget {
  const LsArt(
    this.asset, {
    super.key,
    this.height = 180,
    this.width,
    this.fit = BoxFit.contain,
  });

  final String asset;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}

class FlowEmptyText extends StatelessWidget {
  const FlowEmptyText(this.text, {super.key, this.asset});

  final String text;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    if (asset == null) {
      return LsEmptyCard(icon: LsIconType.hourglass, text: text);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LsArt(asset!, height: 168),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppText.jakarta(14.5, FontWeight.w400, color: AppColors.grey, height: 1.45),
        ),
      ],
    );
  }
}

void showFlowProcessing() => NavigationUtils.showProcessingOverlay();

void hideFlowProcessing() => NavigationUtils.hideProcessingOverlay();

