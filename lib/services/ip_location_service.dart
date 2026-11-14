import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tableflow_plus/services/app_prefs_service.dart';

class IpLocation {
  const IpLocation({
    required this.ip,
    required this.city,
    required this.region,
    required this.country,
    required this.countryCode,
  });

  final String ip;
  final String city;
  final String region;
  final String country;
  final String countryCode;
}

/// Public-IP lookup used by the reference app:
/// ipify, then ipapi.co, then freeipapi.com.
class IpLocationStore extends ChangeNotifier {
  IpLocationStore(this._prefs);

  static const fallback = '********';
  static const _timeout = Duration(seconds: 10);
  static final _ipPattern = RegExp(r'^[0-9a-fA-F:.]+$');

  final AppPrefsService _prefs;
  final http.Client _client = http.Client();

  late String city = _display(_prefs.city);
  late String country = _display(_prefs.country);
  IpLocation? details;

  String get locationLabel => '$city, $country';

  Future<void>? _inFlight;
  bool _settled = false;

  Future<void> ensureFetched() {
    final request = _inFlight;
    if (request != null) return request;
    if (_settled && city != fallback && country != fallback) {
      return Future.value();
    }
    final next = _fetch().whenComplete(() => _inFlight = null);
    _inFlight = next;
    return next;
  }

  Future<void> _fetch() async {
    try {
      final ip = await _publicIp();
      if (ip == null) {
        _applyFailure();
        return;
      }

      final fromIpApi = await _fromIpApi(ip);
      final location = fromIpApi ?? await _fromFreeIpApi(ip);
      if (location == null) {
        _applyFailure();
        return;
      }

      _apply(
        location,
        source: fromIpApi != null ? 'ipapi.co' : 'freeipapi.com',
        settled: true,
      );
    } catch (error, stackTrace) {
      debugPrint('[IpLocation] lookup failed: $error\n$stackTrace');
      _applyFailure();
    }
  }

  Future<String?> _publicIp() async {
    final json = await _getJson(
      Uri.parse('https://api64.ipify.org?format=json'),
    );
    final ip = json?['ip']?.toString() ?? '';
    if (!_ipPattern.hasMatch(ip)) return null;
    return ip;
  }

  Future<IpLocation?> _fromIpApi(String ip) async {
    final json = await _getJson(
      Uri.parse('https://ipapi.co/$ip/json/'),
      headers: const {'User-Agent': 'SeenXpp/1.0'},
    );
    if (json == null || json['error'] == true) return null;
    return IpLocation(
      ip: ip,
      city: _string(json, 'city'),
      region: _string(json, 'region'),
      country: _string(json, 'country_name'),
      countryCode: _string(json, 'country_code'),
    );
  }

  Future<IpLocation?> _fromFreeIpApi(String ip) async {
    final json = await _getJson(
      Uri.parse('https://freeipapi.com/api/json/$ip'),
    );
    if (json == null) return null;
    return IpLocation(
      ip: ip,
      city: _string(json, 'cityName'),
      region: _string(json, 'regionName'),
      country: _string(json, 'countryName'),
      countryCode: _string(json, 'countryCode'),
    );
  }

  Future<Map<String, dynamic>?> _getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      debugPrint('[IpLocation] $uri failed: $error');
      return null;
    }
  }

  String? _source;

  void _apply(
    IpLocation? location, {
    required String? source,
    required bool settled,
  }) {
    _settled = settled;
    _source = source;
    details = location;
    final nextCity = _display(location?.city);
    final nextCountry = _display(location?.country);
    final changed = city != nextCity || country != nextCountry;
    city = nextCity;
    country = nextCountry;
    unawaited(_prefs.setCity(nextCity));
    unawaited(_prefs.setCountry(nextCountry));
    if (changed) notifyListeners();
  }

  void logDetails(String screen) {
    final location = details;
    debugPrint(
      '[$screen] IP details\n'
      'source: ${_source ?? '-'}\n'
      'ip: ${location?.ip ?? '-'}\n'
      'city: $city\n'
      'region: ${_text(location?.region)}\n'
      'country: $country\n'
      'countryCode: ${_text(location?.countryCode)}\n'
      'label: $locationLabel',
    );
  }

  void _applyFailure() {
    final cachedCity = _prefs.city;
    final cachedCountry = _prefs.country;
    final hasRealCache =
        cachedCity != null &&
        cachedCity.isNotEmpty &&
        cachedCity != fallback &&
        cachedCountry != null &&
        cachedCountry.isNotEmpty &&
        cachedCountry != fallback;
    if (hasRealCache) {
      _settled = true;
      return;
    }
    _apply(null, source: null, settled: false);
  }

  String _text(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _display(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return '';
    return value.toString();
  }
}
