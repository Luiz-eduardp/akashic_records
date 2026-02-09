import 'package:akashic_records/db/novel_database.dart';

class NetworkSettingsManager {
  final NovelDatabase _db;

  String? _customDns;
  String? _customUserAgent;

  NetworkSettingsManager(this._db);

  String? get customDns => _customDns;
  String? get customUserAgent => _customUserAgent;

  Future<void> initialize() async {
    await _loadDns();
    await _loadUserAgent();
  }

  Future<void> _loadDns() async {
    try {
      final dns = await _db.getSetting('custom_dns');
      if (dns != null && dns.isNotEmpty) _customDns = dns;
    } catch (_) {}
  }

  Future<void> _loadUserAgent() async {
    try {
      final ua = await _db.getSetting('custom_user_agent');
      if (ua != null && ua.isNotEmpty) _customUserAgent = ua;
    } catch (_) {}
  }

  Future<void> setCustomDns(String? dns) async {
    _customDns = dns;
    try {
      await _db.setSetting('custom_dns', dns ?? '');
    } catch (_) {}
  }

  Future<void> setCustomUserAgent(String? ua) async {
    _customUserAgent = ua;
    try {
      await _db.setSetting('custom_user_agent', ua ?? '');
    } catch (_) {}
  }
}
