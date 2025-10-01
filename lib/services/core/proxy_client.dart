import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akashic_records/db/novel_database.dart';

class ProxyClient {
  final http.Client _client;

  Map<String, dynamic>? _parseDnsString(String dns) {
    var s = dns.trim();
    if (s.isEmpty) return null;
    if (s.contains('://')) s = s.split('://').last;
    if (s.contains('/')) s = s.split('/').first;
    String host = s;
    int? port;
    final hostPortMatch = RegExp(r'^\[?([^\]]+)\]?(?::(\d+))?\$').firstMatch(s);
    if (hostPortMatch != null) {
      host = hostPortMatch.group(1)!;
      final portStr = hostPortMatch.group(2);
      if (portStr != null) port = int.tryParse(portStr);
    }

    final ipv4 = RegExp(r'^(\d{1,3}\.){3}\d{1,3}\$');
    final hostname = RegExp(r'^[a-zA-Z0-9.\-]+\$');

    if (ipv4.hasMatch(host)) {
      final parts = host.split('.');
      for (final part in parts) {
        final v = int.tryParse(part) ?? -1;
        if (v < 0 || v > 255) return null;
      }
      return {'host': host, 'port': port};
    } else if (hostname.hasMatch(host)) {
      return {'host': host, 'port': port};
    }
    return null;
  }

  ProxyClient([http.Client? client]) : _client = client ?? http.Client();

  Future<Map<String, String>> _defaultHeaders() async {
    final db = await NovelDatabase.getInstance();
    final ua = await db.getSetting('custom_user_agent');

    final headers = {
      'User-Agent':
          ua != null && ua.isNotEmpty
              ? ua
              : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Referer': 'https://www.google.com/',
    };
    return headers;
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    final defaultHeaders = await _defaultHeaders();
    final merged = {...defaultHeaders, ...?headers};

    final db = await NovelDatabase.getInstance();
    final dns = await db.getSetting('custom_dns');
    Uri target = uri;
    if (dns != null && dns.isNotEmpty) {
      final parsed = _parseDnsString(dns);
      if (parsed != null) {
        final hostPart = parsed['host'] as String;
        final portPart = parsed['port'] as int?;
        final originalHostHeader =
            uri.host +
            ((uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80))
                ? ':${uri.port}'
                : '');
        try {
          final replaced = uri.replace(
            host: hostPart,
            port: portPart ?? uri.port,
          );
          target = replaced;
          merged['Host'] = originalHostHeader;
        } catch (e) {
          print('ProxyClient: failed to replace host with custom DNS: $e');
        }
      } else {
        print('ProxyClient: ignoring invalid custom_dns value: "$dns"');
      }
    }

    return _client.get(target, headers: merged);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    final defaultHeaders = await _defaultHeaders();
    final merged = {...defaultHeaders, ...?headers};

    final db = await NovelDatabase.getInstance();
    final dns = await db.getSetting('custom_dns');
    Uri target = uri;
    if (dns != null && dns.isNotEmpty) {
      final parsed = _parseDnsString(dns);
      if (parsed != null) {
        final hostPart = parsed['host'] as String;
        final portPart = parsed['port'] as int?;
        final originalHostHeader =
            uri.host +
            ((uri.hasPort && uri.port != (uri.scheme == 'https' ? 443 : 80))
                ? ':${uri.port}'
                : '');
        try {
          final replaced = uri.replace(
            host: hostPart,
            port: portPart ?? uri.port,
          );
          target = replaced;
          merged['Host'] = originalHostHeader;
        } catch (e) {
          print(
            'ProxyClient: failed to replace host with custom DNS (post): $e',
          );
        }
      } else {
        print(
          'ProxyClient: ignoring invalid custom_dns value for post: "$dns"',
        );
      }
    }

    return _client.post(
      target,
      headers: merged,
      body: body,
      encoding: encoding,
    );
  }

  void close() => _client.close();
}
