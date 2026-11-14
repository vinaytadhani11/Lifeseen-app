import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:tableflow_plus/models/screen_time_user.dart';
import 'package:tableflow_plus/services/usage_stats_service.dart';

/// Shares the real launcher icon of an installed app so another phone can show it.
class AppIconStore {
  AppIconStore._();

  static final Map<String, String> _urls = {};

  static Reference _ref(String packageName) {
    return FirebaseStorage.instance.ref('screen_time_icons/$packageName.png');
  }

  static Future<List<ScreenTimeApp>> attach(List<ScreenTimeApp> apps) async {
    final next = <ScreenTimeApp>[];
    for (final app in apps) {
      final url = await ensureUploaded(
        packageName: app.packageName,
        name: app.name,
      );
      next.add(url.isEmpty ? app : app.copyWith(iconUrl: url));
    }
    return next;
  }

  /// Uploads this phone's icon once, then reuses the public file URL.
  static Future<String> ensureUploaded({
    required String packageName,
    required String name,
  }) async {
    if (packageName.isEmpty) return '';
    final cached = _urls[packageName];
    if (cached != null && cached.isNotEmpty) return cached;
    final existing = await _readUrl(packageName);
    if (existing.isNotEmpty) return existing;
    final bytes = await UsageStatsService.appIcon(
      packageName: packageName,
      name: name,
    );
    if (bytes == null || bytes.isEmpty) return '';
    try {
      await _ref(packageName).putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );
      return _readUrl(packageName);
    } catch (error) {
      debugPrint('[Friends] app icon upload failed for $packageName: $error');
      return '';
    }
  }

  /// URL already stored for this package. Does not upload.
  static Future<String> urlForPackage(String packageName) async {
    if (packageName.isEmpty) return '';
    final cached = _urls[packageName];
    if (cached != null && cached.isNotEmpty) return cached;
    return _readUrl(packageName);
  }

  static Future<String> _readUrl(String packageName) async {
    try {
      final url = await _ref(packageName).getDownloadURL();
      if (url.isNotEmpty) _urls[packageName] = url;
      return url;
    } catch (_) {
      return '';
    }
  }
}
