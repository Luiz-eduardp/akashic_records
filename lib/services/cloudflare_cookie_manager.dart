import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CloudflareCookieManager {
  static final CloudflareCookieManager _instance = CloudflareCookieManager._internal();
  factory CloudflareCookieManager() => _instance;
  CloudflareCookieManager._internal();

  static const String _cookiesPrefKey = 'akashic_cf_cookies';
  static const String _userAgentsPrefKey = 'akashic_cf_user_agents';

  final Map<String, Map<String, String>> _domainCookies = {};
  final Map<String, String> _domainUserAgents = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cookiesJson = prefs.getString(_cookiesPrefKey);
      if (cookiesJson != null) {
        final Map<String, dynamic> decoded = json.decode(cookiesJson);
        decoded.forEach((domain, cookieMap) {
          if (cookieMap is Map) {
            _domainCookies[domain] = Map<String, String>.from(cookieMap);
          }
        });
      }

      final uaJson = prefs.getString(_userAgentsPrefKey);
      if (uaJson != null) {
        final Map<String, dynamic> decoded = json.decode(uaJson);
        decoded.forEach((domain, ua) {
          if (ua is String) {
            _domainUserAgents[domain] = ua;
          }
        });
      }
    } catch (_) {}
    _initialized = true;
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.toLowerCase();
    } catch (_) {
      return url.toLowerCase();
    }
  }

  Future<void> saveCookies(String url, Map<String, String> cookies, {String? userAgent}) async {
    await init();
    final domain = _extractDomain(url);
    if (!_domainCookies.containsKey(domain)) {
      _domainCookies[domain] = {};
    }
    _domainCookies[domain]!.addAll(cookies);

    if (userAgent != null && userAgent.isNotEmpty) {
      _domainUserAgents[domain] = userAgent;
    }

    await _persist();
  }

  Future<void> saveRawCookieString(String url, String cookieString, {String? userAgent}) async {
    await init();
    final domain = _extractDomain(url);
    if (!_domainCookies.containsKey(domain)) {
      _domainCookies[domain] = {};
    }

    final parts = cookieString.split(';');
    for (final part in parts) {
      final kv = part.trim().split('=');
      if (kv.length >= 2) {
        final name = kv[0].trim();
        final value = kv.sublist(1).join('=').trim();
        if (name.isNotEmpty && value.isNotEmpty) {
          _domainCookies[domain]![name] = value;
        }
      }
    }

    if (userAgent != null && userAgent.isNotEmpty) {
      _domainUserAgents[domain] = userAgent;
    }

    await _persist();
  }

  String? getCookieHeader(String url) {
    final domain = _extractDomain(url);
    final cookies = <String, String>{};

    _domainCookies.forEach((key, map) {
      if (domain == key || domain.endsWith('.$key') || key.endsWith('.$domain')) {
        cookies.addAll(map);
      }
    });

    if (cookies.isEmpty) return null;
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  String? getUserAgent(String url) {
    final domain = _extractDomain(url);
    if (_domainUserAgents.containsKey(domain)) {
      return _domainUserAgents[domain];
    }
    for (final entry in _domainUserAgents.entries) {
      if (domain.endsWith('.${entry.key}') || entry.key.endsWith('.$domain')) {
        return entry.value;
      }
    }
    return null;
  }

  Future<void> clearDomain(String url) async {
    await init();
    final domain = _extractDomain(url);
    _domainCookies.remove(domain);
    _domainUserAgents.remove(domain);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cookiesPrefKey, json.encode(_domainCookies));
      await prefs.setString(_userAgentsPrefKey, json.encode(_domainUserAgents));
    } catch (_) {}
  }
}
