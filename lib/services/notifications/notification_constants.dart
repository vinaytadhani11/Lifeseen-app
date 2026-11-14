/// Mirrors Android `NotificationConstants`.
abstract final class NotificationConstants {
  static const channelId = 'scheduled_notification_channel';
  static const channelName = 'WhatsApp reminders';
  static const channelDescription =
      'Reminders while WhatsApp messages stay locked';
  static const groupKey = 'whatsapp_notifications';

  static const uniqueNamePrefix = 'scheduled_notification_';

  /// Tap opens Splash and clears the screen stack.
  static const tapPayload = 'splash';

  static const friendChannelId = 'friend_messages';
  static const friendChannelName = 'Friend messages';
  static const friendChannelDescription =
      'Alerts when a friend sends a message';
  static const friendPayloadPrefix = 'friend_message:';

  static const idVoice1 = 1001;
  static const idPhoto1 = 1002;
  static const idChats1 = 1003;
  static const idVoice2 = 1004;
  static const idVideo = 1005;
  static const idPhoto2 = 1006;
  static const idChats2 = 1007;
  static const idVoice3 = 1008;

  static const allIds = <int>[
    idVoice1,
    idPhoto1,
    idChats1,
    idVoice2,
    idVideo,
    idPhoto2,
    idChats2,
    idVoice3,
  ];

  static String uniqueName(int id) => '$uniqueNamePrefix$id';
}
