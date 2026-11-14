import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';

class UsageStatsService {
  UsageStatsService._();

  static const _channel = MethodChannel('com.app.logsense/usage_stats');

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static Future<bool> hasPermission() async {
    if (!isAndroid) return true;
    final allowed = await _channel.invokeMethod<bool>('hasPermission');
    return allowed ?? false;
  }

  static Future<void> openSettings() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('openSettings');
  }

  static Future<List<ScreenTimeApp>> queryToday() async {
    if (!isAndroid) return const [];
    final raw = await _channel.invokeMethod<List<dynamic>>('queryToday');
    if (raw == null) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          ScreenTimeApp(
            name: item['name']?.toString() ?? '',
            packageName: item['package']?.toString() ?? '',
            hours: (item['hours'] as num?)?.toInt() ?? 0,
            minutes: (item['minutes'] as num?)?.toInt() ?? 0,
            seconds: (item['seconds'] as num?)?.toInt() ?? 0,
          ),
    ];
  }

  static final Map<String, Uint8List?> _iconCache = {};

  /// Installed app icon. Package is tried first, then the app name.
  static Future<Uint8List?> appIcon({
    required String packageName,
    required String name,
  }) async {
    if (!isAndroid) return null;
    final key = packageName.isNotEmpty ? packageName : name.toLowerCase();
    if (key.isEmpty) return null;
    if (_iconCache.containsKey(key)) return _iconCache[key];
    final raw = await _channel.invokeMethod<dynamic>('appIcon', {
      'package': packageName,
      'name': name,
    });
    final Uint8List? bytes = switch (raw) {
      Uint8List data => data,
      List<int> data when data.isNotEmpty => Uint8List.fromList(data),
      _ => null,
    };
    _iconCache[key] = bytes;
    return bytes;
  }

  static Future<List<double>> queryHourlyToday() async {
    if (!isAndroid) return List<double>.filled(24, 0);
    final raw = await _channel.invokeMethod<List<dynamic>>('queryHourlyToday');
    if (raw == null || raw.length != 24) return List<double>.filled(24, 0);
    return [for (final item in raw) (item as num?)?.toDouble() ?? 0];
  }
}
