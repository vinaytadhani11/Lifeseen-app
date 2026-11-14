// LifeSeen – Notification History service.
//
// Android: talks to the native NotificationListenerService through
//   MethodChannel 'lifeseen/notification_history'
//   EventChannel  'lifeseen/notification_history/events'
// (see android/…/com/lifeseen/notifications/*.kt).
// Anywhere else (iOS, desktop preview, or before the native code is added)
// it falls back to an in-memory demo so every screen still works.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ============================================================================
// Models
// ============================================================================
class NhApp {
  const NhApp({
    required this.package,
    required this.name,
    this.icon,
    this.enabled = false,
    this.social = false,
    this.todayCount = 0,
  });
  final String package;
  final String name;
  final Uint8List? icon;
  final bool enabled;
  final bool social; // chat & social apps are listed first
  final int todayCount;

  NhApp copyWith({bool? enabled, int? todayCount}) => NhApp(
        package: package,
        name: name,
        icon: icon,
        enabled: enabled ?? this.enabled,
        social: social,
        todayCount: todayCount ?? this.todayCount,
      );

  static NhApp fromMap(Map m) => NhApp(
        package: m['package'] as String,
        name: (m['name'] as String?) ?? m['package'] as String,
        icon: m['icon'] as Uint8List?,
        enabled: m['enabled'] == true,
        social: m['social'] == true,
        todayCount: (m['todayCount'] as num?)?.toInt() ?? 0,
      );
}

final _nhPlaceholder = RegExp(
  r'^(📷|🖼|🎥|📹)?\s*(photo|image|picture|video|gif|sticker)\s*$',
  caseSensitive: false,
);

bool nhIsMediaPlaceholder(String s) => _nhPlaceholder.hasMatch(s.trim());

class NhItem {
  const NhItem({
    required this.id,
    required this.package,
    required this.appName,
    required this.title,
    required this.text,
    required this.time,
    this.removed = false,
    this.mediaPath,
    this.thumbPath,
    this.mediaMime,
    this.mediaW,
    this.mediaH,
  });
  final int id;
  final String package;
  final String appName;
  final String title; // chat / sender name
  final String text;
  final DateTime time;

  /// The sender deleted this message after it arrived (we kept the copy).
  final bool removed;

  /// Absolute file path in LifeSeen's private folder, or "asset:..." in demo mode.
  final String? mediaPath;
  final String? thumbPath;
  final String? mediaMime;
  final int? mediaW;
  final int? mediaH;

  bool get hasImage => mediaPath != null;

  double get aspect => (mediaW != null && mediaH != null && mediaW! > 0 && mediaH! > 0)
      ? (mediaW! / mediaH!).clamp(.56, 1.8).toDouble()
      : 4 / 3;

  /// Real caption without the "📷 Photo" placeholder and group "Sender: " prefix.
  String get caption {
    var t = text;
    final i = t.indexOf(': ');
    if (i > 0 && i < 40 && t.substring(i + 2).trim().isNotEmpty) t = t.substring(i + 2);
    return nhIsMediaPlaceholder(t) ? '' : t;
  }

  static NhItem fromMap(Map m) => NhItem(
        id: (m['id'] as num).toInt(),
        package: m['pkg'] as String,
        appName: (m['app'] as String?) ?? m['pkg'] as String,
        title: (m['title'] as String?) ?? '',
        text: (m['body'] as String?) ?? '',
        time: DateTime.fromMillisecondsSinceEpoch((m['time'] as num).toInt()),
        removed: m['removed'] == true || m['removed'] == 1,
        mediaPath: m['mediaPath'] as String?,
        thumbPath: m['thumbPath'] as String?,
        mediaMime: m['mediaMime'] as String?,
        mediaW: (m['mediaW'] as num?)?.toInt(),
        mediaH: (m['mediaH'] as num?)?.toInt(),
      );
}

class NhAppCount {
  const NhAppCount(this.package, this.appName, this.count);
  final String package, appName;
  final int count;
}

class NhStats {
  const NhStats({this.today = 0, this.week = 0, this.appsOn = 0, this.last7 = const [0, 0, 0, 0, 0, 0, 0], this.perApp = const []});
  final int today, week, appsOn;

  /// Oldest → today.
  final List<int> last7;

  /// Today's count per app, biggest first.
  final List<NhAppCount> perApp;
}

class NhThread {
  const NhThread({required this.title, required this.lastText, required this.lastTime, required this.count, this.removed = 0});
  final String title, lastText;
  final DateTime lastTime;
  final int count, removed;
}

class NhAppDetail {
  const NhAppDetail({required this.hourly, required this.threads, required this.today, required this.total});
  final List<int> hourly; // 24 values for today
  final List<NhThread> threads;
  final int today, total;
}

class NhSettings {
  const NhSettings({
    this.paused = false,
    this.retentionDays = 30,
    this.saveMedia = true,
    this.saveImages = true,
  });
  final bool paused;

  /// 7, 30 or 0 (= keep forever)
  final int retentionDays;

  /// false = skip "📷 Photo", "Video", "Sticker"… alerts
  final bool saveMedia;

  /// false = do not copy photos from notifications (text still saved)
  final bool saveImages;

  NhSettings copyWith({bool? paused, int? retentionDays, bool? saveMedia, bool? saveImages}) => NhSettings(
        paused: paused ?? this.paused,
        retentionDays: retentionDays ?? this.retentionDays,
        saveMedia: saveMedia ?? this.saveMedia,
        saveImages: saveImages ?? this.saveImages,
      );
}

class NhStorage {
  const NhStorage({
    this.count = 0,
    this.bytes = 0,
    this.oldest,
    this.images = 0,
    this.mediaBytes = 0,
  });
  final int count, bytes, images, mediaBytes;
  final DateTime? oldest;
}

/// Known chat apps that are switched on by default the first time.
const nhSuggestedPackages = {
  'com.whatsapp',
  'com.whatsapp.w4b',
  'com.instagram.android',
  'org.telegram.messenger',
  'com.google.android.apps.messaging',
  'com.facebook.orca',
  'org.thoughtcrime.securesms',
};

// ============================================================================
// Service
// ============================================================================
abstract class NotificationHistory {
  static NotificationHistory? _instance;

  /// Android → native channel, everything else → demo data.
  static NotificationHistory get instance =>
      _instance ??= (!kIsWeb && Platform.isAndroid) ? ChannelNotificationHistory() : DemoNotificationHistory();
  static set instance(NotificationHistory value) => _instance = value;

  bool get isDemo;

  // permissions
  Future<bool> isNotificationAccessGranted();
  Future<void> openNotificationAccessSettings();
  Future<bool> isUsageAccessGranted();
  Future<void> openUsageAccessSettings();

  // apps
  Future<List<NhApp>> installedApps();
  Future<Set<String>> enabledApps();
  Future<void> setEnabledApps(Set<String> packages);
  Future<Uint8List?> appIcon(String package);

  // settings
  Future<NhSettings> settings();
  Future<void> saveSettings(NhSettings settings);

  // history
  Future<NhStats> stats();
  Future<List<NhItem>> items({String? package, String? title, String? search, int limit = 300});
  Future<NhAppDetail> appDetail(String package);
  Future<void> deleteThread(String package, String title);
  Future<void> clearAll();
  Future<NhStorage> storage();
  Future<void> shareText(String text);

  /// Every image in one chat, oldest → newest (viewer + grid).
  Future<List<NhItem>> media(String package, String title);
  Future<void> shareImage(String path, {String? text});

  /// true = saved to Pictures/LifeSeen
  Future<bool> saveImageToGallery(String path);

  /// Fires for every newly saved notification (and `null` when items changed, e.g. "removed").
  Stream<NhItem?> get onChange;
}

// ----------------------------------------------------------------------------
// Native (Android)
// ----------------------------------------------------------------------------
class ChannelNotificationHistory extends NotificationHistory {
  ChannelNotificationHistory();

  static const _ch = MethodChannel('lifeseen/notification_history');
  static const _ev = EventChannel('lifeseen/notification_history/events');

  final _icons = <String, Uint8List?>{};
  DemoNotificationHistory? _demo; // used only if the native side is missing
  Stream<NhItem?>? _stream;

  @override
  bool get isDemo => _demo != null;

  Future<T> _call<T>(String method, Map<String, dynamic>? args, T Function(dynamic) parse,
      Future<T> Function(DemoNotificationHistory d) fallback) async {
    if (_demo != null) return fallback(_demo!);
    try {
      final r = await _ch.invokeMethod<dynamic>(method, args);
      return parse(r);
    } on MissingPluginException {
      debugPrint('LifeSeen: native notification history not found – using demo data.');
      _demo = DemoNotificationHistory();
      return fallback(_demo!);
    }
  }

  @override
  Future<bool> isNotificationAccessGranted() =>
      _call('isNotificationAccessGranted', null, (r) => r == true, (d) => d.isNotificationAccessGranted());
  @override
  Future<void> openNotificationAccessSettings() =>
      _call('openNotificationAccessSettings', null, (_) {}, (d) => d.openNotificationAccessSettings());
  @override
  Future<bool> isUsageAccessGranted() => _call('isUsageAccessGranted', null, (r) => r == true, (d) => d.isUsageAccessGranted());
  @override
  Future<void> openUsageAccessSettings() => _call('openUsageAccessSettings', null, (_) {}, (d) => d.openUsageAccessSettings());

  @override
  Future<List<NhApp>> installedApps() => _call('installedApps', null, (r) {
        final list = [for (final m in (r as List)) NhApp.fromMap(m as Map)];
        for (final a in list) {
          if (a.icon != null) _icons[a.package] = a.icon;
        }
        return list;
      }, (d) => d.installedApps());

  @override
  Future<Set<String>> enabledApps() =>
      _call('enabledApps', null, (r) => {...(r as List).cast<String>()}, (d) => d.enabledApps());
  @override
  Future<void> setEnabledApps(Set<String> packages) =>
      _call('setEnabledApps', {'packages': packages.toList()}, (_) {}, (d) => d.setEnabledApps(packages));

  @override
  Future<Uint8List?> appIcon(String package) async {
    if (_icons.containsKey(package)) return _icons[package];
    final icon = await _call<Uint8List?>('appIcon', {'package': package}, (r) => r as Uint8List?, (d) => d.appIcon(package));
    _icons[package] = icon;
    return icon;
  }

  @override
  Future<NhSettings> settings() => _call('getSettings', null, (r) {
        final m = r as Map;
        return NhSettings(
          paused: m['paused'] == true,
          retentionDays: (m['retentionDays'] as num?)?.toInt() ?? 30,
          saveMedia: m['saveMedia'] != false,
          saveImages: m['saveImages'] != false,
        );
      }, (d) => d.settings());

  @override
  Future<void> saveSettings(NhSettings s) => _call(
        'saveSettings',
        {
          'paused': s.paused,
          'retentionDays': s.retentionDays,
          'saveMedia': s.saveMedia,
          'saveImages': s.saveImages,
        },
        (_) {},
        (d) => d.saveSettings(s),
      );

  @override
  Future<NhStats> stats() => _call('stats', null, (r) {
        final m = r as Map;
        return NhStats(
          today: (m['today'] as num).toInt(),
          week: (m['week'] as num).toInt(),
          appsOn: (m['appsOn'] as num).toInt(),
          last7: [for (final v in (m['last7'] as List)) (v as num).toInt()],
          perApp: [
            for (final a in (m['perApp'] as List))
              NhAppCount((a as Map)['pkg'] as String, (a['app'] as String?) ?? a['pkg'] as String, (a['count'] as num).toInt()),
          ],
        );
      }, (d) => d.stats());

  @override
  Future<List<NhItem>> items({String? package, String? title, String? search, int limit = 300}) => _call(
      'items',
      {'package': package, 'title': title, 'search': search, 'limit': limit},
      (r) => [for (final m in (r as List)) NhItem.fromMap(m as Map)],
      (d) => d.items(package: package, title: title, search: search, limit: limit));

  @override
  Future<NhAppDetail> appDetail(String package) => _call('appDetail', {'package': package}, (r) {
        final m = r as Map;
        return NhAppDetail(
          hourly: [for (final v in (m['hourly'] as List)) (v as num).toInt()],
          today: (m['today'] as num).toInt(),
          total: (m['total'] as num).toInt(),
          threads: [
            for (final t in (m['threads'] as List))
              NhThread(
                title: ((t as Map)['title'] as String?) ?? '',
                lastText: (t['body'] as String?) ?? '',
                lastTime: DateTime.fromMillisecondsSinceEpoch((t['time'] as num).toInt()),
                count: (t['count'] as num).toInt(),
                removed: (t['removed'] as num?)?.toInt() ?? 0,
              ),
          ],
        );
      }, (d) => d.appDetail(package));

  @override
  Future<void> deleteThread(String package, String title) =>
      _call('deleteThread', {'package': package, 'title': title}, (_) {}, (d) => d.deleteThread(package, title));
  @override
  Future<void> clearAll() => _call('clearAll', null, (_) {}, (d) => d.clearAll());
  @override
  Future<NhStorage> storage() => _call('storage', null, (r) {
        final m = r as Map;
        final oldest = (m['oldest'] as num?)?.toInt();
        return NhStorage(
          count: (m['count'] as num).toInt(),
          bytes: (m['bytes'] as num).toInt(),
          images: (m['images'] as num?)?.toInt() ?? 0,
          mediaBytes: (m['mediaBytes'] as num?)?.toInt() ?? 0,
          oldest: oldest == null ? null : DateTime.fromMillisecondsSinceEpoch(oldest),
        );
      }, (d) => d.storage());
  @override
  Future<void> shareText(String text) => _call('shareText', {'text': text}, (_) {}, (d) => d.shareText(text));

  @override
  Future<List<NhItem>> media(String package, String title) => _call(
        'media',
        {'package': package, 'title': title},
        (r) => [for (final m in (r as List)) NhItem.fromMap(m as Map)],
        (d) => d.media(package, title),
      );

  @override
  Future<void> shareImage(String path, {String? text}) =>
      _call('shareImage', {'path': path, 'text': text}, (_) {}, (d) => d.shareImage(path, text: text));

  @override
  Future<bool> saveImageToGallery(String path) =>
      _call('saveImageToGallery', {'path': path}, (r) => r == true, (d) => d.saveImageToGallery(path));

  @override
  Stream<NhItem?> get onChange {
    if (_demo != null) return _demo!.onChange;
    return _stream ??= _ev.receiveBroadcastStream().map<NhItem?>((e) {
      if (e is Map && e['id'] != null) return NhItem.fromMap(e);
      return null;
    }).handleError((Object _) {}).asBroadcastStream();
  }
}

// ----------------------------------------------------------------------------
// Demo (in memory) – used for previews and non-Android platforms
// ----------------------------------------------------------------------------
class DemoNotificationHistory extends NotificationHistory {
  DemoNotificationHistory({this.liveDemo = true}) {
    _seed();
    if (liveDemo) {
      _timer = Timer.periodic(const Duration(seconds: 25), (_) => _simulateIncoming());
    }
  }

  /// Adds a fake WhatsApp message every 25 s so the live badge can be seen.
  final bool liveDemo;
  Timer? _timer;

  bool _notifGranted = false;
  bool _usageGranted = false;
  NhSettings _settings = const NhSettings();
  final Set<String> _enabled = {};
  final List<NhItem> _items = [];
  final _controller = StreamController<NhItem?>.broadcast();
  int _nextId = 1;

  static const _apps = <(String, String, bool)>[
    ('com.whatsapp', 'WhatsApp', true),
    ('com.instagram.android', 'Instagram', true),
    ('org.telegram.messenger', 'Telegram', true),
    ('com.snapchat.android', 'Snapchat', true),
    ('com.facebook.katana', 'Facebook', true),
    ('com.google.android.apps.messaging', 'Messages', true),
    ('com.google.android.gm', 'Gmail', false),
    ('com.google.android.youtube', 'YouTube', false),
  ];

  String _name(String pkg) => _apps.firstWhere((a) => a.$1 == pkg, orElse: () => (pkg, pkg, false)).$2;

  void _seed() {
    _enabled.addAll(['com.whatsapp', 'com.instagram.android', 'org.telegram.messenger', 'com.google.android.gm', 'com.google.android.apps.messaging']);
    final now = DateTime.now();
    DateTime at(int daysAgo, int h, int m) {
      final d = DateTime(now.year, now.month, now.day - daysAgo, h, m);
      return d.isAfter(now) ? now.subtract(Duration(minutes: 5 + m)) : d;
    }

    void add(
      String pkg,
      String title,
      String text,
      DateTime t, {
      bool removed = false,
      String? media,
      int? w,
      int? h,
    }) =>
        _items.add(NhItem(
          id: _nextId++,
          package: pkg,
          appName: _name(pkg),
          title: title,
          text: text,
          time: t,
          removed: removed,
          mediaPath: media,
          thumbPath: media,
          mediaMime: media == null ? null : 'image/jpeg',
          mediaW: w,
          mediaH: h,
        ));

    add('com.whatsapp', 'Rahul Karkar', 'Hey, are you free this evening?', at(0, 15, 58));
    add('com.whatsapp', 'Rahul Karkar', "We're booking the turf at 7", at(0, 16, 1));
    add('com.whatsapp', 'Rahul Karkar', 'Bring the speaker too', at(0, 16, 5), removed: true);
    add(
      'com.whatsapp',
      'Rahul Karkar',
      '📷 Photo',
      at(0, 16, 20),
      media: 'asset:assets/demo/nh_photo_1.jpg',
      w: 800,
      h: 600,
    );
    add(
      'com.whatsapp',
      'Rahul Karkar',
      'Match tickets 🎟',
      at(0, 16, 24),
      media: 'asset:assets/demo/nh_photo_2.jpg',
      w: 800,
      h: 1000,
    );
    add(
      'com.whatsapp',
      'Rahul Karkar',
      '📷 Photo',
      at(0, 16, 28),
      media: 'asset:assets/demo/nh_photo_3.jpg',
      w: 900,
      h: 700,
      removed: true,
    );
    add(
      'com.whatsapp',
      'Rahul Karkar',
      'See you there',
      at(0, 16, 30),
      media: 'asset:assets/demo/nh_photo_4.jpg',
      w: 800,
      h: 800,
    );
    add('com.whatsapp', 'Rahul Karkar', 'Are you coming to the match tonight?', at(0, 16, 32));
    add('com.whatsapp', 'Family', "Mom: Dinner at 8, don't be late", at(0, 15, 2), removed: true);
    add('com.whatsapp', 'Family', 'Papa: Reached office', at(0, 9, 40));
    add('com.whatsapp', 'Vinay', 'See you at 6, check your stats', at(0, 14, 5));
    add('com.whatsapp', 'Priya Shah', 'Haha same here', at(0, 11, 20));
    add('com.instagram.android', 'priya.shah', 'liked your photo.', at(0, 16, 10));
    add('com.instagram.android', 'rahul.k', 'started following you.', at(0, 12, 44));
    add('com.instagram.android', 'Instagram', 'vinay.p shared a reel', at(0, 10, 3));
    add('org.telegram.messenger', 'Study Group', 'Vinay: Notes for chapter 4 are uploaded, check the pinned file.', at(0, 15, 48));
    add('org.telegram.messenger', 'Study Group', 'Priya: Thanks!', at(0, 15, 50));
    add('com.google.android.apps.messaging', 'AX-HDFCBK', 'Rs 499 debited from A/c XX4521 on 10-11. Not you? Call 18002586161', at(0, 8, 12));
    add('com.google.android.gm', 'Google', 'Security alert: new sign-in on a Windows device', at(1, 21, 14));
    add('com.whatsapp', 'Rahul Karkar', 'Good night 😴', at(1, 23, 2));
    add('com.instagram.android', 'priya.shah', 'commented: so good!', at(1, 19, 30));
    add('org.telegram.messenger', 'Study Group', 'Exam moved to Friday', at(2, 18, 5));
    add('com.whatsapp', 'Family', 'Papa: Call me when free', at(3, 13, 0));
    _items.sort((a, b) => b.time.compareTo(a.time));
  }

  void _simulateIncoming() {
    if (!_notifGranted || _settings.paused || !_enabled.contains('com.whatsapp')) return;
    const lines = ['Where are you?', 'Check your screen time 😄', 'Call me', 'Done ✅', 'Coming in 10 min'];
    final item = NhItem(
      id: _nextId++,
      package: 'com.whatsapp',
      appName: 'WhatsApp',
      title: 'Rahul Karkar',
      text: lines[math.Random().nextInt(lines.length)],
      time: DateTime.now(),
    );
    _items.insert(0, item);
    _controller.add(item);
  }

  @override
  bool get isDemo => true;

  @override
  Future<bool> isNotificationAccessGranted() async => _notifGranted;
  @override
  Future<void> openNotificationAccessSettings() async {
    _notifGranted = true; // demo: granting is instant
  }
  @override
  Future<bool> isUsageAccessGranted() async => _usageGranted;
  @override
  Future<void> openUsageAccessSettings() async {
    _usageGranted = true;
  }

  int _todayCount(String pkg) {
    final start = _startOfDay(0);
    return _items.where((i) => i.package == pkg && !i.time.isBefore(start)).length;
  }

  @override
  Future<List<NhApp>> installedApps() async => [
        for (final a in _apps)
          NhApp(package: a.$1, name: a.$2, social: a.$3, enabled: _enabled.contains(a.$1), todayCount: _todayCount(a.$1)),
      ];
  @override
  Future<Set<String>> enabledApps() async => {..._enabled};
  @override
  Future<void> setEnabledApps(Set<String> packages) async {
    _enabled
      ..clear()
      ..addAll(packages);
  }
  @override
  Future<Uint8List?> appIcon(String package) async => null;

  @override
  Future<NhSettings> settings() async => _settings;
  @override
  Future<void> saveSettings(NhSettings s) async {
    _settings = s;
  }

  DateTime _startOfDay(int daysAgo) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - daysAgo);
  }

  @override
  Future<NhStats> stats() async {
    final today = _startOfDay(0);
    final counts = <String, int>{};
    for (final i in _items.where((i) => !i.time.isBefore(today))) {
      counts[i.package] = (counts[i.package] ?? 0) + 1;
    }
    final perApp = counts.entries.map((e) => NhAppCount(e.key, _name(e.key), e.value)).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return NhStats(
      today: counts.values.fold(0, (a, b) => a + b),
      week: _items.where((i) => !i.time.isBefore(_startOfDay(6))).length,
      appsOn: _enabled.length,
      last7: [
        for (var d = 6; d >= 0; d--)
          _items.where((i) => !i.time.isBefore(_startOfDay(d)) && i.time.isBefore(_startOfDay(d - 1))).length,
      ],
      perApp: perApp,
    );
  }

  @override
  Future<List<NhItem>> items({String? package, String? title, String? search, int limit = 300}) async {
    final q = search?.trim().toLowerCase() ?? '';
    return _items
        .where((i) =>
            (package == null || i.package == package) &&
            (title == null || i.title == title) &&
            (q.isEmpty || i.title.toLowerCase().contains(q) || i.text.toLowerCase().contains(q)))
        .take(limit)
        .toList();
  }

  @override
  Future<NhAppDetail> appDetail(String package) async {
    final today = _startOfDay(0);
    final hourly = List<int>.filled(24, 0);
    final threads = <String, List<NhItem>>{};
    var todayCount = 0, total = 0;
    for (final i in _items.where((i) => i.package == package)) {
      total++;
      if (!i.time.isBefore(today)) {
        todayCount++;
        hourly[i.time.hour]++;
      }
      threads.putIfAbsent(i.title, () => []).add(i);
    }
    final list = threads.entries
        .map((e) => NhThread(
              title: e.key,
              lastText: e.value.first.text,
              lastTime: e.value.first.time,
              count: e.value.length,
              removed: e.value.where((i) => i.removed).length,
            ))
        .toList()
      ..sort((a, b) => b.lastTime.compareTo(a.lastTime));
    return NhAppDetail(hourly: hourly, threads: list, today: todayCount, total: total);
  }

  @override
  Future<void> deleteThread(String package, String title) async {
    _items.removeWhere((i) => i.package == package && i.title == title);
    _controller.add(null);
  }

  @override
  Future<void> clearAll() async {
    _items.clear();
    _controller.add(null);
  }

  @override
  Future<NhStorage> storage() async {
    final images = _items.where((i) => i.hasImage).length;
    return NhStorage(
      count: _items.length,
      images: images,
      bytes: _items.fold(0, (a, i) => a + 120 + i.text.length * 2 + i.title.length * 2) + images * 120000,
      mediaBytes: images * 120000,
      oldest: _items.isEmpty ? null : _items.last.time,
    );
  }

  @override
  Future<void> shareText(String text) async => Clipboard.setData(ClipboardData(text: text));

  @override
  Future<List<NhItem>> media(String package, String title) async {
    final list = _items.where((i) => i.package == package && i.title == title && i.hasImage).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  @override
  Future<void> shareImage(String path, {String? text}) async {}

  @override
  Future<bool> saveImageToGallery(String path) async => true;

  @override
  Stream<NhItem?> get onChange => _controller.stream;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
