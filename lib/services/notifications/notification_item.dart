import 'package:tableflow_plus/services/notifications/notification_constants.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  final int id;
  final String title;
  final String subtitle;
  final Duration delay;

  /// strings.xml → notification_title_1…8 / notification_sub_title_1…8
  static const items = <NotificationItem>[
    NotificationItem(
      id: NotificationConstants.idVoice1,
      title: 'A voice message was sent on WhatsApp.',
      subtitle: 'Secret voice message — click to listen',
      delay: Duration(milliseconds: 120000),
    ),
    NotificationItem(
      id: NotificationConstants.idPhoto1,
      title: 'A photo was sent on WhatsApp.',
      subtitle: 'Shocking photo — check now',
      delay: Duration(milliseconds: 1800000),
    ),
    NotificationItem(
      id: NotificationConstants.idChats1,
      title: 'WhatsApp chats were found.',
      subtitle: 'Secret conversations exposed',
      delay: Duration(milliseconds: 3000000),
    ),
    NotificationItem(
      id: NotificationConstants.idVoice2,
      title: 'A voice message was sent on WhatsApp.',
      subtitle: 'Voice recording arrived',
      delay: Duration(milliseconds: 5100000),
    ),
    NotificationItem(
      id: NotificationConstants.idVideo,
      title: 'A video was sent on WhatsApp!',
      subtitle: 'Secret video shared',
      delay: Duration(milliseconds: 9300000),
    ),
    NotificationItem(
      id: NotificationConstants.idPhoto2,
      title: 'A photo was sent on WhatsApp.',
      subtitle: 'Another photo dropped',
      delay: Duration(milliseconds: 12300000),
    ),
    NotificationItem(
      id: NotificationConstants.idChats2,
      title: 'WhatsApp chats were found.',
      subtitle: 'Secret chats exposed',
      delay: Duration(milliseconds: 43200000),
    ),
    NotificationItem(
      id: NotificationConstants.idVoice3,
      title: 'A voice message was sent on WhatsApp.',
      subtitle: 'Secret voice message — click to listen',
      delay: Duration(milliseconds: 86400000),
    ),
  ];
}
