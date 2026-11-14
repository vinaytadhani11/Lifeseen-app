import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/services/app_bootstrap.dart';
import 'package:tableflow_plus/services/notifications/notification_item.dart';
import 'package:tableflow_plus/services/notifications/notification_scheduler.dart';

/// Lists the 8 WhatsApp reminders and can post each one immediately.
class ReminderScheduleScreen extends StatefulWidget {
  const ReminderScheduleScreen({super.key});

  @override
  State<ReminderScheduleScreen> createState() => _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState extends State<ReminderScheduleScreen> {
  static const _background = Color(0xFF080C10);
  static const _card = Color(0xFF16182A);

  int? _sendingId;

  @override
  Widget build(BuildContext context) {
    final prefs = AppBootstrap.prefs;
    final notificationOn =
        AppBootstrap.remoteConfig.config.notification == 1;
    final premium = prefs.isUserPremium;
    final chainOn =
        notificationOn && !premium && prefs.notificationRemindersEnabled;
    final phone = NotificationScheduler.wpLoginNumber(prefs);
    final masked = NotificationScheduler.maskPhone(phone);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _background,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.logoWhiteText,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reminder schedule',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.logoWhiteText,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Test Send posts that reminder now. It does not change the timed chain.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitleText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _StatusCard(
                lines: [
                  'Remote Config notification: ${notificationOn ? 1 : 0} (1 = Schedule, 0 = Cancel)',
                  'Premium: ${premium ? 'Yes' : 'No'}',
                  'Timed chain: ${chainOn ? 'Scheduled' : 'Off'}',
                  'Title phone: $masked',
                ],
              ),
              const SizedBox(height: 16),
              for (final item in NotificationItem.items) ...[
                _ReminderTile(
                  item: item,
                  maskedPhone: masked,
                  sending: _sendingId == item.id,
                  onTest: () => _send(item, phone),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send(NotificationItem item, String phone) async {
    if (_sendingId != null) return;
    setState(() => _sendingId = item.id);
    var sent = false;
    try {
      sent = await NotificationScheduler.showTestNotification(
        item: item,
        phone: phone,
      );
    } catch (error) {
      debugPrint('[ReminderSchedule] test send failed: $error');
      sent = false;
    }
    if (!mounted) return;
    setState(() => _sendingId = null);
    Fluttertoast.showToast(
      msg: sent
          ? 'Notification ${item.id} sent'
          : 'Notification blocked. Allow notifications and try again.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF1C1E2A),
      textColor: Colors.white,
      fontSize: 15,
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _ReminderScheduleScreenState._card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.logoWhiteText,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.item,
    required this.maskedPhone,
    required this.sending,
    required this.onTest,
  });

  final NotificationItem item;
  final String maskedPhone;
  final bool sending;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _ReminderScheduleScreenState._card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.id}  ·  ${_delayLabel(item.delay)}',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.whatsAppGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$maskedPhone ${item.title}',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.logoWhiteText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitleText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: sending ? null : onTest,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    sending ? 'Sending...' : 'Test Send',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _delayLabel(Duration delay) {
    final minutes = delay.inMinutes;
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hour' : '$hours hours';
    }
    return '$minutes min';
  }
}
