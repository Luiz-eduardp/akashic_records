import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart' as xml;
import 'package:akashic_records/services/core/proxy_client.dart';

class OpdsEntry {
  final String title;
  final String author;
  final String summary;
  final String? coverUrl;
  final String? downloadUrl;
  final String? downloadType;
  final String? navUrl;

  OpdsEntry({
    required this.title,
    required this.author,
    required this.summary,
    this.coverUrl,
    this.downloadUrl,
    this.downloadType,
    this.navUrl,
  });
}

class OpdsService {
  final ProxyClient _client = ProxyClient();

  static final List<Map<String, String>> defaultFeeds = [
    {
      'title': 'Project Gutenberg',
      'url': 'https://www.gutenberg.org/ebooks/search.opds/?sort_order=downloads',
      'description': 'Over 70,000 free public domain ebooks'
    },
    {
      'title': 'Standard Ebooks',
      'url': 'https://standardebooks.org/opds/all',
      'description': 'Free, high-quality public domain ebooks'
    },
  ];

  Future<List<OpdsEntry>> fetchFeed(String feedUrl, {int depth = 0, Map<String, String>? authHeaders}) async {
    final baseUri = Uri.parse(feedUrl);
    final headers = <String, String>{
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
      'Accept': 'application/atom+xml,application/xml,text/xml,application/opds+json,*/*',
    };
    if (authHeaders != null) {
      headers.addAll(authHeaders);
    }

    final response = await _client.get(baseUri, headers: headers).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load OPDS catalog: ${response.statusCode}');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('json') || response.body.trim().startsWith('{')) {
      return _parseJsonOpdsFeed(response.body, baseUri);
    }

    return _parseXmlOpdsFeed(response.body, baseUri, depth, authHeaders);
  }

  List<OpdsEntry> _parseJsonOpdsFeed(String jsonStr, Uri baseUri) {
    final entries = <OpdsEntry>[];
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final publications = map['publications'] as List? ?? map['navigation'] as List? ?? [];

      for (final pub in publications) {
        if (pub is Map) {
          final titleObj = pub['metadata']?['title'] ?? pub['title'] ?? 'E-Book Title';
          final title = titleObj is Map ? (titleObj['name'] ?? titleObj.values.first ?? '') : titleObj.toString();

          final authorObj = pub['metadata']?['author'] ?? pub['author'] ?? 'Unknown Author';
          final author = authorObj is List
              ? (authorObj.isNotEmpty ? (authorObj[0] is Map ? authorObj[0]['name'] : authorObj[0].toString()) : 'Unknown Author')
              : (authorObj is Map ? (authorObj['name'] ?? 'Unknown Author') : authorObj.toString());

          final summary = pub['metadata']?['description'] ?? pub['summary'] ?? '';

          String? coverUrl;
          String? downloadUrl;
          String? downloadType;
          String? navUrl;
          int bestPriority = -1;

          final links = pub['links'] as List? ?? pub['images'] as List? ?? [];
          for (final link in links) {
            if (link is Map) {
              final rel = (link['rel'] ?? '').toString().toLowerCase();
              final href = link['href'] ?? '';
              final type = (link['type'] ?? '').toString().toLowerCase();
              if (href.toString().isEmpty) continue;
              final resolved = baseUri.resolve(href.toString()).toString();

              if (rel.contains('cover') || rel.contains('image') || type.startsWith('image/')) {
                coverUrl = resolved;
              }
              if (rel.contains('navigation') || type.contains('opds')) {
                navUrl = resolved;
              }

              int priority = 0;
              if (type == 'application/epub+zip' || resolved.toLowerCase().contains('.epub')) {
                priority = 100;
              } else if (type == 'application/pdf' || resolved.toLowerCase().contains('.pdf')) {
                priority = 90;
              } else if (type.contains('mobi') || resolved.toLowerCase().contains('.mobi') || resolved.toLowerCase().contains('.kindle')) {
                priority = 80;
              } else if (rel.contains('acquisition') && !type.contains('html') && !type.contains('text/')) {
                priority = 50;
              }

              if (priority > bestPriority) {
                bestPriority = priority;
                downloadUrl = resolved;
                downloadType = type;
              }
            }
          }

          entries.add(OpdsEntry(
            title: title,
            author: author,
            summary: summary,
            coverUrl: coverUrl,
            downloadUrl: downloadUrl,
            downloadType: downloadType,
            navUrl: navUrl,
          ));
        }
      }
    } catch (_) {}
    return entries;
  }

  Future<List<OpdsEntry>> _parseXmlOpdsFeed(String xmlStr, Uri baseUri, int depth, Map<String, String>? authHeaders) async {
    final document = xml.XmlDocument.parse(xmlStr);
    final entries = <OpdsEntry>[];
    final navSubLinks = <String>[];

    final rawEntries = document.descendants
        .whereType<xml.XmlElement>()
        .where((e) => e.name.local.toLowerCase() == 'entry');

    for (final node in rawEntries) {
      final title = _getXmlChildText(node, 'title') ?? 'E-Book Title';
      final authorNode = node.descendants.whereType<xml.XmlElement>().firstWhere((e) => e.name.local.toLowerCase() == 'author', orElse: () => xml.XmlElement(xml.XmlName('author')));
      final author = _getXmlChildText(authorNode, 'name') ?? 'Unknown Author';
      final summary = _getXmlChildText(node, 'summary') ?? _getXmlChildText(node, 'content') ?? '';

      String? coverUrl;
      String? downloadUrl;
      String? downloadType;
      String? navUrl;
      int bestPriority = -1;

      final links = node.descendants
          .whereType<xml.XmlElement>()
          .where((e) => e.name.local.toLowerCase() == 'link');

      for (final link in links) {
        final rel = (link.getAttribute('rel') ?? '').toLowerCase();
        final type = (link.getAttribute('type') ?? '').toLowerCase();
        final href = link.getAttribute('href') ?? '';

        if (href.isEmpty) continue;
        final resolvedHref = baseUri.resolve(href).toString();

        if (rel.contains('image') || rel.contains('thumbnail') || type.startsWith('image/')) {
          coverUrl = resolvedHref;
        }

        if (rel.contains('subsection') || rel.contains('start') || rel.contains('navigation') || type.contains('atom+xml') || type.contains('opds')) {
          navUrl = resolvedHref;
        }

        int priority = 0;
        final lowerHref = resolvedHref.toLowerCase();
        if (type == 'application/epub+zip' || lowerHref.endsWith('.epub') || lowerHref.contains('.epub.images') || lowerHref.contains('.epub.noimages')) {
          priority = 100;
        } else if (type == 'application/pdf' || lowerHref.endsWith('.pdf')) {
          priority = 90;
        } else if (type.contains('mobipocket') || type.contains('mobi') || lowerHref.contains('.mobi') || lowerHref.contains('.kindle')) {
          priority = 80;
        } else if ((type.contains('epub') || type.contains('pdf') || type.contains('zip') || type.contains('octet-stream')) && !type.contains('html')) {
          priority = 70;
        } else if (rel.contains('acquisition') && !type.contains('html') && !type.contains('text/')) {
          priority = 50;
        }

        if (priority > bestPriority) {
          bestPriority = priority;
          downloadUrl = resolvedHref;
          downloadType = type;
        }
      }

      if (downloadUrl != null || title.isNotEmpty) {
        entries.add(OpdsEntry(
          title: title,
          author: author,
          summary: summary,
          coverUrl: coverUrl,
          downloadUrl: downloadUrl,
          downloadType: downloadType,
          navUrl: navUrl,
        ));
      }

      if (downloadUrl == null && navUrl != null && depth == 0 && navSubLinks.length < 5) {
        navSubLinks.add(navUrl);
      }
    }

    if (entries.every((e) => e.downloadUrl == null) && navSubLinks.isNotEmpty && depth == 0) {
      final subEntries = <OpdsEntry>[];
      for (final subLink in navSubLinks) {
        try {
          final res = await fetchFeed(subLink, depth: 1, authHeaders: authHeaders);
          subEntries.addAll(res);
        } catch (_) {}
      }
      if (subEntries.isNotEmpty) return subEntries;
    }

    return entries;
  }

  String? _getXmlChildText(xml.XmlElement parent, String localName) {
    for (final child in parent.children) {
      if (child is xml.XmlElement && child.name.local.toLowerCase() == localName.toLowerCase()) {
        return child.text.trim();
      }
    }
    return null;
  }

  Future<String?> extractOpenSearchUrl(String feedUrl) async {
    try {
      final baseUri = Uri.parse(feedUrl);
      final res = await _client.get(baseUri);
      if (res.statusCode == 200) {
        final document = xml.XmlDocument.parse(res.body);
        final links = document.descendants.whereType<xml.XmlElement>().where((e) => e.name.local.toLowerCase() == 'link');
        for (final link in links) {
          final rel = (link.getAttribute('rel') ?? '').toLowerCase();
          final type = (link.getAttribute('type') ?? '').toLowerCase();
          final href = link.getAttribute('href') ?? '';
          if (rel == 'search' || type.contains('opds-search') || type.contains('opensearch')) {
            return baseUri.resolve(href).toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<File> downloadBook(String downloadUrl, String fileName) async {
    Uri targetUri = Uri.parse(downloadUrl);

    if (downloadUrl.toLowerCase().contains('.opds') || downloadUrl.toLowerCase().contains('catalog')) {
      try {
        final detailEntries = await fetchFeed(downloadUrl);
        for (final entry in detailEntries) {
          if (entry.downloadUrl != null && !entry.downloadUrl!.toLowerCase().contains('.opds')) {
            targetUri = Uri.parse(entry.downloadUrl!);
            break;
          }
        }
      } catch (_) {}
    }

    var response = await _client.get(
      targetUri,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
        'Accept': 'application/epub+zip,application/pdf,application/octet-stream,*/*',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to download book: ${response.statusCode}');
    }

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    final bodySample = response.body.trim().toLowerCase();

    if (contentType.contains('xml') || contentType.contains('atom') || bodySample.startsWith('<?xml') || bodySample.startsWith('<feed') || bodySample.startsWith('<entry')) {
      try {
        final subEntries = await _parseXmlOpdsFeed(response.body, targetUri, 0, null);
        for (final entry in subEntries) {
          if (entry.downloadUrl != null && !entry.downloadUrl!.toLowerCase().contains('.opds')) {
            response = await _client.get(
              Uri.parse(entry.downloadUrl!),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
                'Accept': 'application/epub+zip,application/pdf,*/*',
              },
            );
            break;
          }
        }
      } catch (_) {}
    } else if (contentType.contains('text/html') || bodySample.startsWith('<!doctype html') || bodySample.startsWith('<html')) {
      final htmlStr = response.body;
      final epubMatch = RegExp(r'href="([^"]+\.epub[^"]*)"|href=\x27([^\x27]+\.epub[^\x27]*)\x27', caseSensitive: false).firstMatch(htmlStr);

      if (epubMatch != null) {
        final matchedUrl = epubMatch.group(1) ?? epubMatch.group(2);
        if (matchedUrl != null) {
          final directEpubUrl = targetUri.resolve(matchedUrl).toString();
          response = await _client.get(
            Uri.parse(directEpubUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
            },
          );
        }
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
