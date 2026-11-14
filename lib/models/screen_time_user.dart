class ScreenTimeUser {
  const ScreenTimeUser({
    required this.uid,
    required this.phone,
    required this.username,
    this.photo = '',
    this.friends = const {},
    this.sentRequests = const {},
    this.receivedRequests = const {},
  });

  final String uid;
  final String phone;
  final String username;
  final String photo;
  final Map<String, bool> friends;
  final Map<String, bool> sentRequests;
  final Map<String, bool> receivedRequests;

  int get badgeCount => sentRequests.length + receivedRequests.length;

  ScreenTimeUser copyWith({String? photo, String? username}) {
    return ScreenTimeUser(
      uid: uid,
      phone: phone,
      username: username ?? this.username,
      photo: photo ?? this.photo,
      friends: friends,
      sentRequests: sentRequests,
      receivedRequests: receivedRequests,
    );
  }

  factory ScreenTimeUser.fromMap(String uid, Map<dynamic, dynamic> raw) {
    return ScreenTimeUser(
      uid: (raw['uid'] as String?)?.isNotEmpty == true ? raw['uid'] as String : uid,
      phone: raw['phone']?.toString() ?? '',
      username: raw['username']?.toString() ?? '',
      photo: raw['photo']?.toString() ?? '',
      friends: _flags(raw['friends']),
      sentRequests: _flags(raw['sentRequests']),
      receivedRequests: _flags(raw['receivedRequests']),
    );
  }

  Map<String, Object> toMap() => {
        'uid': uid,
        'phone': phone,
        'username': username,
        'photo': photo,
        'notificationToken': '',
        'friends': friends,
        'sentRequests': sentRequests,
        'receivedRequests': receivedRequests,
      };

  static Map<String, bool> _flags(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value == true));
    }
    if (raw is List) {
      return {for (final item in raw) item.toString(): true};
    }
    return {};
  }
}

class ScreenTimeApp {
  const ScreenTimeApp({
    required this.name,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.packageName = '',
    this.iconUrl = '',
  });

  final String name;
  final int hours;
  final int minutes;
  final int seconds;
  final String packageName;
  final String iconUrl;

  int get sortSeconds => hours * 3600 + minutes * 60 + seconds;

  String get durationLabel => '$hours hr, $minutes min, $seconds sec';

  ScreenTimeApp copyWith({String? iconUrl}) {
    return ScreenTimeApp(
      name: name,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      packageName: packageName,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  Map<String, Object> toMap() => {
        'name': name,
        'duration': [hours, minutes, seconds],
        if (packageName.isNotEmpty) 'package': packageName,
        if (iconUrl.isNotEmpty) 'iconUrl': iconUrl,
      };

  factory ScreenTimeApp.fromMap(Map<dynamic, dynamic> raw) {
    final duration = _asList(raw['duration']);
    var hours = 0;
    var minutes = 0;
    var seconds = 0;
    if (duration.length >= 3) {
      hours = _asInt(duration[0]);
      minutes = _asInt(duration[1]);
      seconds = _asInt(duration[2]);
    }
    return ScreenTimeApp(
      name: raw['name']?.toString() ?? '',
      packageName: raw['package']?.toString() ?? '',
      iconUrl: raw['iconUrl']?.toString() ?? '',
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }
}

class ScreenTimeDay {
  const ScreenTimeDay({
    this.apps = const [],
    this.hourlyMinutes = const [],
  });

  final List<ScreenTimeApp> apps;
  final List<double> hourlyMinutes;

  bool get hourlyEmpty =>
      hourlyMinutes.length != 24 || hourlyMinutes.every((value) => value <= 0);

  factory ScreenTimeDay.fromMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) return const ScreenTimeDay();
    final apps = <ScreenTimeApp>[];
    for (final item in _asList(raw['data'])) {
      if (item is Map) apps.add(ScreenTimeApp.fromMap(item));
    }
    final hourly = <double>[
      for (final item in _asList(raw['hourly']))
        (item as num?)?.toDouble() ?? 0,
    ];
    return ScreenTimeDay(apps: apps, hourlyMinutes: hourly);
  }
}

class FriendChatPreview {
  const FriendChatPreview({
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.otherPhoto,
    required this.text,
    required this.timestamp,
    this.senderId = '',
    this.hidden = false,
  });

  final String chatId;
  final String otherUid;
  final String otherName;
  final String otherPhoto;
  final String text;
  final double timestamp;
  final String senderId;
  final bool hidden;

  factory FriendChatPreview.fromMap(String chatId, Map<dynamic, dynamic> raw) {
    return FriendChatPreview(
      chatId: chatId,
      otherUid: raw['otherUid']?.toString() ?? '',
      otherName: raw['otherName']?.toString() ?? '',
      otherPhoto: raw['otherPhoto']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      timestamp: (raw['timestamp'] as num?)?.toDouble() ?? 0,
      senderId: raw['senderId']?.toString() ?? '',
      hidden: raw['hidden'] == true,
    );
  }
}

class FriendChatMessage {
  const FriendChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.deletedBy = const {},
  });

  final String id;
  final String senderId;
  final String text;
  final double timestamp;
  final Map<String, bool> deletedBy;

  factory FriendChatMessage.fromMap(String id, Map<dynamic, dynamic> raw) {
    return FriendChatMessage(
      id: id,
      senderId: raw['senderId']?.toString() ?? '',
      text: raw['text']?.toString() ?? '',
      timestamp: (raw['timestamp'] as num?)?.toDouble() ?? 0,
      deletedBy: ScreenTimeUser._flags(raw['delete']),
    );
  }
}

List<dynamic> _asList(dynamic raw) {
  if (raw is List) return raw;
  if (raw is Map) {
    final entries = raw.entries.toList()
      ..sort((a, b) {
        final ai = int.tryParse(a.key.toString());
        final bi = int.tryParse(b.key.toString());
        if (ai != null && bi != null) return ai.compareTo(bi);
        return a.key.toString().compareTo(b.key.toString());
      });
    return [for (final entry in entries) entry.value];
  }
  return const [];
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// Local midnight epoch seconds. Realtime Database keys cannot contain '.'.
String screenTimeDayKey(DateTime day) {
  final midnight = DateTime(day.year, day.month, day.day);
  return (midnight.millisecondsSinceEpoch ~/ 1000).toString();
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatTotalMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours > 0 && minutes > 0) return '$hours hr $minutes min';
  if (hours > 0) return '$hours hr';
  return '$minutes min';
}

int totalMinutesFromApps(List<ScreenTimeApp> apps) {
  var total = 0;
  for (final app in apps) {
    total += app.hours * 60 + app.minutes + (app.seconds >= 30 ? 1 : 0);
  }
  return total;
}

int totalMinutesFromHourly(List<double> hourly) =>
    hourly.fold<double>(0, (sum, value) => sum + value).toInt();

const hourlyCurveWeights = <double>[
  0.45, 0.35, 0.30, 0.28, 0.30, 0.40, 0.55, 0.75,
  0.90, 0.95, 1.00, 1.05, 1.00, 0.95, 0.90, 0.95,
  1.05, 1.10, 1.00, 0.90, 0.80, 0.70, 0.60, 0.50,
];

List<double> distributeAppsToHourly(List<ScreenTimeApp> apps) {
  final total = apps.fold<double>(0, (sum, app) {
    return sum + app.hours * 60 + app.minutes + app.seconds / 60;
  });
  if (total <= 0) return List<double>.filled(24, 0);
  final weightSum = hourlyCurveWeights.fold<double>(0, (a, b) => a + b);
  return [
    for (final weight in hourlyCurveWeights) total * weight / weightSum,
  ];
}

/// Same decisions as UserFragment after a phone lookup.
String classifyLookup(ScreenTimeUser? them, String myId) {
  if (them == null || them.uid.isEmpty) return 'UserNotFound';
  if (them.uid == myId) return 'ownProfile';
  if (them.friends[myId] == true) return 'alreadyFriends';
  if (them.receivedRequests[myId] == true) return 'requestSent';
  if (them.sentRequests[myId] == true) return 'requestReceived';
  return 'notConnected';
}
