import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:tableflow_plus/models/remote_config_model.dart';

class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigModel _config = RemoteConfigModel.defaults();

  RemoteSettingsModel _settings = RemoteSettingsModel.defaults();

  RemoteConfigModel get config => _config;
  RemoteSettingsModel get settings => _settings;

  Future<void>? _refreshInFlight;

  Future<void> init() async {
    await _applySettings();
    await _setDefaults();
    // Splash awaits this same fetch. Do not block the first frame on the network.
    unawaited(refresh());
  }

  /// Fetches the latest values. Concurrent callers share one request.
  Future<void> refresh() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final run = _refresh();
    _refreshInFlight = run;
    return run.whenComplete(() {
      if (identical(_refreshInFlight, run)) _refreshInFlight = null;
    });
  }

  Future<void> _refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('[RemoteConfig] fetch + activate succeeded');
    } catch (e, stack) {
      debugPrint(
        '[RemoteConfig] refresh failed, using last activated values: $e',
      );
      debugPrint('$stack');
    }

    _parseConfig();
    _parseSettings();
    _logRemoteConfig();
  }

  Future<void> _applySettings() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        // 0 cancels the HTTP call immediately and surfaces as
        // [firebase_remote_config/internal] internal remote config fetch error.
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero,
      ),
    );
    debugPrint(
      '[RemoteConfig] settings: fetchTimeout=10s, minimumFetchInterval=0',
    );
  }

  Future<void> _setDefaults() async {
    await _remoteConfig.setDefaults(<String, dynamic>{
      'data': jsonEncode(RemoteConfigModel.defaults().toJson()),
      'settings': jsonEncode(RemoteSettingsModel.defaults().toJson()),
    });
  }

  void _parseSettings() {
    final raw = _remoteConfig.getString('settings');
    if (raw.isEmpty) {
      _settings = RemoteSettingsModel.defaults();
      return;
    }
    try {
      _settings = RemoteSettingsModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      debugPrint('[RemoteConfig] parsed settings: $_settings');
    } catch (e) {
      _settings = RemoteSettingsModel.defaults();
      debugPrint('[RemoteConfig] settings parse error: $e — using defaults');
    }
  }

  void _parseConfig() {
    final raw = _remoteConfig.getString('data');
    if (raw.isEmpty) {
      _config = RemoteConfigModel.defaults();
      debugPrint('[RemoteConfig] parsed: empty data param, using defaults');
      return;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _config = RemoteConfigModel.fromJson(json);
      debugPrint('[RemoteConfig] parsed data JSON: $json');
    } catch (e) {
      _config = RemoteConfigModel.defaults();
      debugPrint('[RemoteConfig] parse error: $e — using defaults');
    }
  }

  void _logRemoteConfig() {
    final defaultData = RemoteConfigModel.defaults().toJson();
    final rawData = _remoteConfig.getString('data');
    final rawSettings = _remoteConfig.getString('settings');

    debugPrint('[RemoteConfig] ─────────────────────────────');
    debugPrint('[RemoteConfig] lastFetchTime: ${_remoteConfig.lastFetchTime}');
    debugPrint(
      '[RemoteConfig] lastFetchStatus: ${_remoteConfig.lastFetchStatus}',
    );
    debugPrint('[RemoteConfig] data (raw): $rawData');
    debugPrint('[RemoteConfig] data (parsed): $_config');
    debugPrint(
      '[RemoteConfig] settings (raw): ${rawSettings.isEmpty ? "(empty)" : rawSettings}',
    );
    debugPrint('[RemoteConfig] settings (parsed): $_settings');
    debugPrint('[RemoteConfig] defaults: $defaultData');
    debugPrint(
      '[RemoteConfig] mode: ${_config.pageLog == 0 ? "Friends / Screen Time (page_log=0)" : "WhatsApp (page_log=1)"}',
    );
    debugPrint('[RemoteConfig] ─────────────────────────────');
  }
}
