import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:akashic_records/db/novel_database.dart';

Future<http.Response> fetch(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  final db = await NovelDatabase.getInstance();
  final dns = await db.getSetting('custom_dns');
  final ua = await db.getSetting('custom_user_agent');

  final Map<String, String> h = {};
  if (headers != null) h.addAll(headers);
  if (ua != null && ua.isNotEmpty) h['User-Agent'] = ua;

  Uri target = uri;
  if (dns != null && dns.isNotEmpty) {
    try {
      final originalHost = uri.host;
      final replaced = uri.replace(host: dns);
      target = replaced;
      h['Host'] = originalHost;
    } catch (_) {}
  }

  final client = http.Client();
  try {
    final respFuture = client.get(target, headers: h);
    if (timeout != null) return await respFuture.timeout(timeout);
    return await respFuture;
  } finally {
    client.close();
  }
}

Future<String> fetchString(
  Uri uri, {
  Map<String, String>? headers,
  Duration? timeout,
}) async {
  final resp = await fetch(uri, headers: headers, timeout: timeout);
  if (resp.statusCode >= 200 && resp.statusCode < 300) return resp.body;
  throw HttpException('Request failed ${resp.statusCode} for $uri');
}
