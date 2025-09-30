import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:akashic_records/services/core/proxy_client.dart';
import 'package:html/parser.dart' show parse;
import 'dart:convert';

class _ImageResult {
  final List<int> bytes;
  final String url;
  _ImageResult(this.bytes, this.url);
}

Future<_ImageResult?> searchCoverOnline(
  ProxyClient client,
  String query,
) async {
  try {
    final url = Uri.parse(
      'https://www.google.com/search?tbm=isch&q=${Uri.encodeQueryComponent(query)}',
    );
    final resp = await client.get(url);
    if (resp.statusCode != 200) return null;
    final doc = parse(resp.body);
    final imgs = doc.querySelectorAll('img');
    String? imgUrl;
    for (final img in imgs) {
      final src = img.attributes['src'] ?? img.attributes['data-src'];
      if (src != null && (src.startsWith('http') || src.startsWith('https'))) {
        imgUrl = src;
        break;
      }
    }
    if (imgUrl == null) return null;
    final r = await client.get(Uri.parse(imgUrl));
    if (r.statusCode != 200) return null;
    return _ImageResult(r.bodyBytes, imgUrl);
  } catch (_) {
    return null;
  }
}

bool _looksLikeImage(List<int> bytes) {
  if (bytes.isEmpty) return false;
  if (bytes.length > 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF)
    return true;
  if (bytes.length > 7 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47)
    return true;
  if (bytes.length > 2 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46)
    return true;
  if (bytes.length > 11 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50)
    return true;
  return false;
}

class EpubImportService {
  final Uuid _uuid = const Uuid();

  Future<Novel?> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes);

      String? opfPath;
      for (final f in archive) {
        if (f.isFile && f.name == 'META-INF/container.xml') {
          final content = utf8.decode(f.content as List<int>);
          try {
            final doc = XmlDocument.parse(content);
            final rootfile = doc.findAllElements('rootfile').first;
            opfPath = rootfile.getAttribute('full-path');
          } catch (_) {}
          break;
        }
      }

      if (opfPath == null) {
        final possible =
            archive
                .where((e) => e.isFile && e.name.toLowerCase().endsWith('.opf'))
                .toList();
        if (possible.isNotEmpty) opfPath = possible.first.name;
      }

      if (opfPath == null) return null;

      final opfFile = archive.firstWhere((e) => e.isFile && e.name == opfPath);
      final opfXml = utf8.decode(opfFile.content as List<int>);
      final opf = XmlDocument.parse(opfXml);

      String title = p.basenameWithoutExtension(filePath);
      try {
        final t = opf.findAllElements('title').first.text;
        if (t.trim().isNotEmpty) title = t.trim();
      } catch (_) {}

      String author = '';
      try {
        final a = opf.findAllElements('creator').first.text;
        author = a.trim();
      } catch (_) {}

      String description = '';
      try {
        final d = opf.findAllElements('description').first.text;
        description = d.trim();
      } catch (_) {}

      final manifest = <String, String>{};
      for (final item in opf.findAllElements('item')) {
        final idAttr = item.getAttribute('id');
        final href = item.getAttribute('href');
        if (idAttr != null && href != null) manifest[idAttr] = href;
      }

      String? coverHref;
      try {
        final metas = opf.findAllElements('meta');
        for (final m in metas) {
          final name = m.getAttribute('name');
          if (name != null && name.toLowerCase() == 'cover') {
            final content = m.getAttribute('content');
            if (content != null && manifest.containsKey(content)) {
              coverHref = manifest[content];
              break;
            }
          }
        }
      } catch (_) {}

      if (coverHref == null) {
        final candidates = ['cover', 'cover-image', 'coverimg'];
        for (final c in candidates) {
          if (manifest.containsKey(c)) {
            coverHref = manifest[c];
            break;
          }
        }
      }

      final chapters = <Chapter>[];
      final spineIds = <String>[];
      for (final itemref in opf.findAllElements('itemref')) {
        final idref = itemref.getAttribute('idref');
        if (idref != null) spineIds.add(idref);
      }

      int idx = 0;
      for (final idref in spineIds) {
        final href = manifest[idref];
        if (href == null) continue;
        final base = p.dirname(opfPath);
        final resourcePath = p.normalize(p.join(base, href));
        final entry = archive.firstWhere(
          (e) => e.isFile && e.name == resourcePath,
          orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
        );
        if (entry.name.isEmpty) continue;
        final content = utf8.decode((entry.content as List<int>));
        final cid = _uuid.v4();
        final ctitle = 'Chapter ${idx + 1}';
        chapters.add(
          Chapter(
            id: cid,
            title: ctitle,
            content: content,
            chapterNumber: idx + 1,
          ),
        );
        idx++;
      }

      String coverPathLocal = '';
      if (coverHref != null) {
        final base = p.dirname(opfPath);
        final res = p.normalize(p.join(base, coverHref));
        final ent = archive.firstWhere(
          (e) => e.isFile && e.name == res,
          orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
        );
        if (ent.name.isNotEmpty) {
          try {
            final dir = await getApplicationDocumentsDirectory();
            final bytes = ent.content as List<int>;
            if (_looksLikeImage(bytes)) {
              final ext =
                  p.extension(ent.name).isNotEmpty
                      ? p.extension(ent.name)
                      : '.png';
              final fname = 'cover_${_uuid.v4()}$ext';
              final cp = p.join(dir.path, fname);
              await File(cp).writeAsBytes(bytes);
              coverPathLocal = cp;
            } else {
              try {
                final text = utf8.decode(bytes);
                final doc = parse(text);
                final img = doc.querySelector('img');
                if (img != null) {
                  final src = img.attributes['src'];
                  if (src != null && src.isNotEmpty) {
                    final imgPath = p.normalize(p.join(p.dirname(res), src));
                    final ient = archive.firstWhere(
                      (e) => e.isFile && e.name == imgPath,
                      orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
                    );
                    if (ient.name.isNotEmpty) {
                      final ibytes = ient.content as List<int>;
                      if (_looksLikeImage(ibytes)) {
                        final iext =
                            p.extension(ient.name).isNotEmpty
                                ? p.extension(ient.name)
                                : '.png';
                        final ifname = 'cover_${_uuid.v4()}$iext';
                        final icp = p.join(dir.path, ifname);
                        await File(icp).writeAsBytes(ibytes);
                        coverPathLocal = icp;
                      }
                    }
                  }
                }
              } catch (_) {}
            }
          } catch (_) {}
        }
      }

      if (coverPathLocal.isEmpty) {
        try {
          final proxy = ProxyClient();
          final found = await searchCoverOnline(proxy, '$title cover');
          if (found != null && _looksLikeImage(found.bytes)) {
            final dir = await getApplicationDocumentsDirectory();
            final ext =
                p.extension(found.url).isNotEmpty
                    ? p.extension(found.url)
                    : '.png';
            final fname = 'cover_${_uuid.v4()}$ext';
            final cp = p.join(dir.path, fname);
            await File(cp).writeAsBytes(found.bytes);
            coverPathLocal = cp;
          }
        } catch (_) {}

        if (coverPathLocal.isEmpty) {
          final tmpl = 'placeholder_cover_template'.translate;
          try {
            final name = Uri.encodeComponent(title);
            coverPathLocal = tmpl.replaceAll('{NAME}', name);
          } catch (_) {
            coverPathLocal = tmpl.replaceAll(
              '{NAME}',
              Uri.encodeComponent(p.basenameWithoutExtension(filePath)),
            );
          }
        }
      }

      final novel = Novel(
        id: _uuid.v4(),
        title: title,
        coverImageUrl: coverPathLocal,
        author: author,
        description: description,
        chapters: chapters,
        pluginId: 'local_epub',
        genres: [],
        isFavorite: false,
      );

      return novel;
    } catch (e) {
      print('Failed to import epub $filePath: $e');
      return null;
    }
  }
}
