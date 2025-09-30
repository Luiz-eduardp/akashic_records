import 'dart:convert';
import 'package:http/http.dart' as http;

class ProxyClient {
  final http.Client _client;

  ProxyClient([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _defaultHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Referer': 'https://www.google.com/',
    };
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) {
    final merged = {..._defaultHeaders(), ...?headers};
    return _client.get(uri, headers: merged);
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    final merged = {..._defaultHeaders(), ...?headers};
    return _client.post(uri, headers: merged, body: body, encoding: encoding);
  }

  void close() => _client.close();
}
