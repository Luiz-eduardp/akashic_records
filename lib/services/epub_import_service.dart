import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart' as xml;
import 'package:epubx/epubx.dart' as epubx;
import 'package:dart_mobi/dart_mobi.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:image/image.dart' as img_pkg;
import 'package:pdfrx/pdfrx.dart';
import '../models/model.dart';

class EpubImportService {
  final Uuid _uuid = const Uuid();
  final HtmlUnescape _unescape = HtmlUnescape();

  Future<Novel> importFromFile(String filePath) => parseAndExtractEpub(filePath);

  Future<Novel> parseAndExtractEpub(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final ext = p.extension(filePath).toLowerCase().replaceAll('.', '');

    if (ext == 'cbz' || ext == 'cbr') {
      return _parseCbzManga(filePath, ext);
    }

    if (ext == 'pdf') {
      return _parsePdfDocument(filePath);
    }

    if (ext == 'mobi' || ext == 'azw' || ext == 'azw3') {
      return _parseMobiDocument(filePath, ext);
    }

    if (ext == 'txt' || ext == 'md' || ext == 'text') {
      return _parseTextDocument(filePath, ext);
    }

    if (ext == 'html' || ext == 'htm' || ext == 'fb2') {
      return _parseHtmlOrFb2Document(filePath, ext);
    }

    if (ext == 'doc' || ext == 'docx') {
      return _parseGenericBinaryTextDocument(filePath, ext);
    }

    try {
      final bytes = await file.readAsBytes();
      final book = await epubx.EpubReader.readBook(bytes);

      String title = book.Title ?? p.basenameWithoutExtension(filePath);
      title = _unescape.convert(title.trim());

      String author = book.Author ?? 'Unknown Author';
      author = _unescape.convert(author.trim());

      String description = '';
      if (book.Schema?.Package?.Metadata?.Description != null) {
        description = _unescape.convert(book.Schema!.Package!.Metadata!.Description!.trim());
      }

      String coverPathLocal = await _extractEpubCoverEnhanced(book, bytes);

      final chapters = <Chapter>[];
      if (book.Chapters != null && book.Chapters!.isNotEmpty) {
        _extractEpubChapters(book.Chapters!, chapters, 1);
      }

      if (chapters.isEmpty) {
        return _parseEpubManualFallback(bytes, filePath, ext, coverPathLocal);
      }

      return Novel(
        id: _uuid.v4(),
        title: title,
        coverImageUrl: coverPathLocal,
        author: author,
        description: description,
        chapters: chapters,
        pluginId: 'local_epub',
        genres: [ext.isEmpty ? 'EPUB' : ext.toUpperCase()],
        isFavorite: false,
      );
    } catch (_) {
      try {
        final bytes = await file.readAsBytes();
        return _parseEpubManualFallback(bytes, filePath, ext, '');
      } catch (_) {
        return _parseTextDocument(filePath, ext.isEmpty ? 'EPUB' : ext);
      }
    }
  }

  Future<String> _extractEpubCoverEnhanced(epubx.EpubBook book, Uint8List epubBytes) async {
    if (book.CoverImage != null) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final imgBytes = img_pkg.encodePng(book.CoverImage!);
        final cp = p.join(dir.path, 'cover_${_uuid.v4()}.png');
        await File(cp).writeAsBytes(imgBytes);
        return cp;
      } catch (_) {}
    }

    if (book.Content?.Images != null && book.Content!.Images!.isNotEmpty) {
      try {
        final images = book.Content!.Images!;
        epubx.EpubByteContentFile? bestImage;

        for (final entry in images.entries) {
          final key = entry.key.toLowerCase();
          if (key.contains('cover') || key.contains('front') || key.contains('poster') || key.contains('folder') || key.contains('thumb') || key.contains('jacket')) {
            bestImage = entry.value;
            break;
          }
        }

        bestImage ??= images.values.first;
        if (bestImage.Content != null && bestImage.Content!.isNotEmpty) {
          final dir = await getApplicationDocumentsDirectory();
          final ext = p.extension(bestImage.FileName ?? 'cover.png');
          final cp = p.join(dir.path, 'cover_${_uuid.v4()}$ext');
          await File(cp).writeAsBytes(bestImage.Content!);
          return cp;
        }
      } catch (_) {}
    }

    try {
      final archive = ZipDecoder().decodeBytes(epubBytes);
      final imgFile = archive.firstWhere(
        (e) {
          if (!e.isFile) return false;
          final name = e.name.toLowerCase();
          return (name.contains('cover') || name.contains('front') || name.contains('poster') || name.contains('folder') || name.contains('jacket') || name.contains('title')) &&
              (name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.jpeg') || name.endsWith('.webp'));
        },
        orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
      );

      if (imgFile.name.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final ext = p.extension(imgFile.name);
        final cp = p.join(dir.path, 'cover_${_uuid.v4()}$ext');
        await File(cp).writeAsBytes(imgFile.content as List<int>);
        return cp;
      }

      final anyImage = archive.firstWhere(
        (e) {
          if (!e.isFile) return false;
          final name = e.name.toLowerCase();
          return name.endsWith('.jpg') || name.endsWith('.png') || name.endsWith('.jpeg') || name.endsWith('.webp');
        },
        orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
      );

      if (anyImage.name.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final ext = p.extension(anyImage.name);
        final cp = p.join(dir.path, 'cover_${_uuid.v4()}$ext');
        await File(cp).writeAsBytes(anyImage.content as List<int>);
        return cp;
      }
    } catch (_) {}

    return '';
  }

  Future<Novel> _parsePdfDocument(String filePath) async {
    final title = p.basenameWithoutExtension(filePath);
    final chapters = <Chapter>[];
    String coverPathLocal = '';

    try {
      final pdfDoc = await PdfDocument.openFile(filePath);
      final pageCount = pdfDoc.pages.length;
      final fullTextBuffer = StringBuffer();

      if (pageCount > 0) {
        try {
          final page1 = pdfDoc.pages[0];
          final pdfImage = await page1.render(
            width: (page1.width * 2.0).toInt(),
            height: (page1.height * 2.0).toInt(),
          );
          if (pdfImage != null) {
            final img = img_pkg.Image.fromBytes(
              pdfImage.width,
              pdfImage.height,
              pdfImage.pixels,
            );
            final pngBytes = img_pkg.encodePng(img);
            final dir = await getApplicationDocumentsDirectory();
            final cp = p.join(dir.path, 'pdf_cover_${_uuid.v4()}.png');
            await File(cp).writeAsBytes(pngBytes);
            coverPathLocal = cp;
          }
        } catch (_) {}
      }

      for (int i = 1; i <= pageCount; i++) {
        final page = pdfDoc.pages[i - 1];
        final textPage = await page.loadText();
        final pageStr = textPage.fullText.trim();

        if (pageStr.isNotEmpty) {
          fullTextBuffer.writeln('### Page $i\n');
          fullTextBuffer.writeln(pageStr);
          fullTextBuffer.writeln('\n===PAGEBREAK===\n');
        }
      }

      final htmlContent = _convertMarkdownOrTextToHtml(fullTextBuffer.toString());
      final extractedChapters = _splitTextOrHtmlIntoChapters(htmlContent, title);
      chapters.addAll(extractedChapters);
    } catch (_) {}

    if (chapters.isEmpty) {
      chapters.add(Chapter(
        id: _uuid.v4(),
        title: title,
        content: '<p>PDF Document: <strong>$title</strong><br>File: $filePath</p>',
        chapterNumber: 1,
      ));
    }

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: coverPathLocal,
      author: 'PDF Document',
      description: 'Imported PDF document (${chapters.length} chapters)',
      chapters: chapters,
      pluginId: 'local_pdf',
      genres: ['PDF'],
      isFavorite: false,
    );
  }

  Future<Novel> _parseMobiDocument(String filePath, String ext) async {
    final title = p.basenameWithoutExtension(filePath);
    String rawMarkup = '';

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      rawMarkup = await _parseMobiWithDartMobi(bytes);
    } catch (_) {}

    final sanitizedMarkup = _sanitizeAndNormalizeHtml(rawMarkup);
    final chapters = _splitTextOrHtmlIntoChapters(sanitizedMarkup, title);

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: '',
      author: 'Kindle Book',
      description: 'Imported $ext book',
      chapters: chapters,
      pluginId: 'local_mobi',
      genres: [ext.toUpperCase()],
      isFavorite: false,
    );
  }

  Future<Novel> _parseTextDocument(String filePath, String ext) async {
    final title = p.basenameWithoutExtension(filePath);
    String rawText = '';

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      try {
        rawText = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        rawText = latin1.decode(bytes);
      }
    } catch (_) {
      rawText = 'Text document: $title';
    }

    final htmlContent = _convertMarkdownOrTextToHtml(rawText);
    final chapters = _splitTextOrHtmlIntoChapters(htmlContent, title);

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: '',
      author: 'Text Document',
      description: 'Imported $ext document (${chapters.length} chapters)',
      chapters: chapters,
      pluginId: 'local_txt',
      genres: [ext.toUpperCase()],
      isFavorite: false,
    );
  }

  Future<Novel> _parseHtmlOrFb2Document(String filePath, String ext) async {
    final title = p.basenameWithoutExtension(filePath);
    String rawHtml = '';

    try {
      final file = File(filePath);
      rawHtml = await file.readAsString();
    } catch (_) {}

    final sanitized = _sanitizeAndNormalizeHtml(rawHtml);
    final chapters = _splitTextOrHtmlIntoChapters(sanitized, title);

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: '',
      author: 'Web/FictionBook Document',
      description: 'Imported $ext file',
      chapters: chapters,
      pluginId: 'local_html',
      genres: [ext.toUpperCase()],
      isFavorite: false,
    );
  }

  Future<Novel> _parseGenericBinaryTextDocument(String filePath, String ext) async {
    final title = p.basenameWithoutExtension(filePath);
    String text = '';

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      text = utf8.decode(bytes.where((b) => b >= 32 || b == 10 || b == 13).toList(), allowMalformed: true);
    } catch (_) {
      text = 'Document: $title';
    }

    final htmlContent = _convertMarkdownOrTextToHtml(text);
    final chapters = _splitTextOrHtmlIntoChapters(htmlContent, title);

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: '',
      author: 'Office Document',
      description: 'Imported $ext file',
      chapters: chapters,
      pluginId: 'local_doc',
      genres: [ext.toUpperCase()],
      isFavorite: false,
    );
  }

  int _extractEpubChapters(
    List<epubx.EpubChapter> epubChapters,
    List<Chapter> chapters,
    int startCount,
  ) {
    int current = startCount;
    for (final ch in epubChapters) {
      final title = (ch.Title != null && ch.Title!.trim().isNotEmpty)
          ? _unescape.convert(ch.Title!.trim())
          : 'Chapter $current';

      final cleanHtml = _sanitizeAndNormalizeHtml(ch.HtmlContent ?? '');
      if (cleanHtml.trim().isNotEmpty) {
        chapters.add(Chapter(
          id: _uuid.v4(),
          title: title,
          content: cleanHtml,
          chapterNumber: current,
        ));
        current++;
      }

      if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
        current = _extractEpubChapters(ch.SubChapters!, chapters, current);
      }
    }
    return current;
  }

  Future<Novel> _parseCbzManga(String filePath, String ext) async {
    final title = p.basenameWithoutExtension(filePath);
    final chapters = <Chapter>[];
    String coverPathLocal = '';

    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final imageFiles = archive.where((e) {
        if (!e.isFile) return false;
        final name = e.name.toLowerCase();
        return name.endsWith('.jpg') ||
            name.endsWith('.jpeg') ||
            name.endsWith('.png') ||
            name.endsWith('.webp');
      }).toList();

      imageFiles.sort((a, b) => a.name.compareTo(b.name));

      if (imageFiles.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final mangaDir = Directory(p.join(dir.path, 'manga_${_uuid.v4()}'));
        await mangaDir.create(recursive: true);

        final pageUrls = <String>[];
        for (int i = 0; i < imageFiles.length; i++) {
          final imgFile = imageFiles[i];
          final extName = p.extension(imgFile.name);
          final savePath = p.join(mangaDir.path, 'page_${i + 1}$extName');
          await File(savePath).writeAsBytes(imgFile.content as List<int>);
          pageUrls.add(savePath);

          if (i == 0) {
            coverPathLocal = savePath;
          }
        }

        final contentBuffer = StringBuffer();
        for (int i = 0; i < pageUrls.length; i++) {
          contentBuffer.writeln('<div class="manga-page"><img src="${pageUrls[i]}" alt="Page ${i + 1}" /></div>');
        }

        chapters.add(Chapter(
          id: _uuid.v4(),
          title: 'Full Volume (${pageUrls.length} pages)',
          content: contentBuffer.toString(),
          chapterNumber: 1,
        ));
      }
    } catch (_) {}

    if (chapters.isEmpty) {
      chapters.add(Chapter(
        id: _uuid.v4(),
        title: title,
        content: '<p>Comic/Manga $ext: $title</p>',
        chapterNumber: 1,
      ));
    }

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: coverPathLocal,
      author: 'Comic Author',
      description: 'Manga/Comic format ${ext.toUpperCase()}',
      chapters: chapters,
      pluginId: 'local_manga',
      genres: [ext.toUpperCase()],
      isFavorite: false,
    );
  }

  Future<Novel> _parseEpubManualFallback(Uint8List bytes, String filePath, String ext, String existingCover) async {
    final title = p.basenameWithoutExtension(filePath);
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return _parseTextDocument(filePath, ext);
    }

    final containerFile = archive.firstWhere(
      (e) => e.name == 'META-INF/container.xml',
      orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
    );

    if (containerFile.name.isEmpty) {
      return _parseTextDocument(filePath, ext);
    }

    final containerXmlStr = String.fromCharCodes(containerFile.content as List<int>);
    final containerDoc = xml.XmlDocument.parse(containerXmlStr);
    final rootfileElement = containerDoc.findAllElements('rootfile').firstOrNull;

    if (rootfileElement == null) {
      return _parseTextDocument(filePath, ext);
    }

    final opfPath = rootfileElement.getAttribute('full-path');
    if (opfPath == null) {
      return _parseTextDocument(filePath, ext);
    }

    final opfFile = archive.firstWhere(
      (e) => e.name == opfPath,
      orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
    );

    if (opfFile.name.isEmpty) {
      return _parseTextDocument(filePath, ext);
    }

    final opfXmlStr = utf8.decode(opfFile.content as List<int>, allowMalformed: true);
    final opfDoc = xml.XmlDocument.parse(opfXmlStr);

    final manifestMap = <String, String>{};
    for (final item in opfDoc.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) {
        manifestMap[id] = href;
      }
    }

    final chapters = <Chapter>[];
    int chapterCount = 1;
    final baseDir = p.dirname(opfPath);

    for (final itemref in opfDoc.findAllElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref != null && manifestMap.containsKey(idref)) {
        final href = manifestMap[idref]!;
        final chapterPath = p.normalize(p.join(baseDir, href));

        final chapterFile = archive.firstWhere(
          (e) => e.isFile && e.name == chapterPath,
          orElse: () => ArchiveFile.noCompress('', 0, <int>[]),
        );

        if (chapterFile.name.isNotEmpty) {
          final chapterBytes = chapterFile.content as List<int>;
          final rawHtml = utf8.decode(chapterBytes, allowMalformed: true);
          final cleanContent = _sanitizeAndNormalizeHtml(rawHtml);

          if (cleanContent.trim().isNotEmpty) {
            chapters.add(Chapter(
              id: _uuid.v4(),
              title: 'Chapter $chapterCount',
              content: cleanContent,
              chapterNumber: chapterCount,
            ));
            chapterCount++;
          }
        }
      }
    }

    return Novel(
      id: _uuid.v4(),
      title: title,
      coverImageUrl: existingCover,
      author: 'Unknown Author',
      description: 'Imported EPUB book',
      chapters: chapters.isNotEmpty ? chapters : [
        Chapter(
          id: _uuid.v4(),
          title: title,
          content: '<p>Book content.</p>',
          chapterNumber: 1,
        )
      ],
      pluginId: 'local_epub',
      genres: [ext.isEmpty ? 'EPUB' : ext.toUpperCase()],
      isFavorite: false,
    );
  }

  Future<String> _parseMobiWithDartMobi(Uint8List bytes) async {
    try {
      final mobiData = await DartMobiReader.read(bytes);
      final rawml = mobiData.parseOpt(true, true, false);
      if (rawml.markup != null && rawml.markup!.data != null) {
        final dataList = List<int>.from(rawml.markup!.data!);
        try {
          return utf8.decode(dataList, allowMalformed: true);
        } catch (_) {
          return latin1.decode(dataList);
        }
      }
    } catch (_) {}
    return '';
  }

  String _sanitizeAndNormalizeHtml(String rawHtml) {
    if (rawHtml.trim().isEmpty) return '';

    String text = rawHtml;
    text = text.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<iframe[^>]*>[\s\S]*?</iframe>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<mbp:pagebreak/?>', caseSensitive: false), '\n\n===PAGEBREAK===\n\n');

    text = _unescape.convert(text);

    final hasHtmlTags = RegExp(r'<(p|div|h[1-6]|ul|ol|li|blockquote|pre|code|table|img|span|br|b|i|strong|em)[^>]*>', caseSensitive: false).hasMatch(text);

    if (!hasHtmlTags) {
      return _convertMarkdownOrTextToHtml(text);
    }

    return text.trim();
  }

  String _convertMarkdownOrTextToHtml(String rawText) {
    if (rawText.trim().isEmpty) return '';

    final lines = rawText.split(RegExp(r'\r?\n'));
    final sb = StringBuffer();
    bool inCodeBlock = false;
    String codeBlockLang = '';
    final codeBuffer = StringBuffer();

    for (var line in lines) {
      final trimmed = line.trimRight();

      if (trimmed.startsWith('```')) {
        if (inCodeBlock) {
          sb.writeln('<pre><code class="language-$codeBlockLang">${_escapeHtml(codeBuffer.toString().trim())}</code></pre>');
          codeBuffer.clear();
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
          codeBlockLang = trimmed.substring(3).trim();
        }
        continue;
      }

      if (inCodeBlock) {
        codeBuffer.writeln(line);
        continue;
      }

      final lineTrim = trimmed.trim();

      if (lineTrim.isEmpty) {
        continue;
      }

      if (lineTrim.startsWith('# ')) {
        sb.writeln('<h1>${_formatInlineMarkup(lineTrim.substring(2))}</h1>');
      } else if (lineTrim.startsWith('## ')) {
        sb.writeln('<h2>${_formatInlineMarkup(lineTrim.substring(3))}</h2>');
      } else if (lineTrim.startsWith('### ')) {
        sb.writeln('<h3>${_formatInlineMarkup(lineTrim.substring(4))}</h3>');
      } else if (lineTrim.startsWith('#### ')) {
        sb.writeln('<h4>${_formatInlineMarkup(lineTrim.substring(5))}</h4>');
      } else if (lineTrim.startsWith('> ')) {
        sb.writeln('<blockquote>${_formatInlineMarkup(lineTrim.substring(2))}</blockquote>');
      } else if (lineTrim == '---' || lineTrim == '***' || lineTrim == '___') {
        sb.writeln('<hr>');
      } else if (lineTrim.startsWith('- ') || lineTrim.startsWith('* ')) {
        sb.writeln('<ul><li>${_formatInlineMarkup(lineTrim.substring(2))}</li></ul>');
      } else {
        sb.writeln('<p>${_formatInlineMarkup(lineTrim)}</p>');
      }
    }

    if (inCodeBlock && codeBuffer.isNotEmpty) {
      sb.writeln('<pre><code>${_escapeHtml(codeBuffer.toString())}</code></pre>');
    }

    return sb.toString();
  }

  String _formatInlineMarkup(String text) {
    String res = text;
    res = res.replaceAllMapped(RegExp(r'(\*\*|__)(.*?)\1'), (m) => '<strong>${m[2]}</strong>');
    res = res.replaceAllMapped(RegExp(r'(\*|_)(.*?)\1'), (m) => '<em>${m[2]}</em>');
    res = res.replaceAllMapped(RegExp(r'`(.*?)`'), (m) => '<code>${_escapeHtml(m[1]!)}</code>');
    res = res.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\(([^)]+)\)'), (m) => '<img src="${m[2]}" alt="${m[1]}" />');
    res = res.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => '<a href="${m[2]}">${m[1]}</a>');
    return res;
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  List<Chapter> _splitTextOrHtmlIntoChapters(String fullContent, String bookTitle) {
    if (fullContent.trim().isEmpty) {
      return [
        Chapter(
          id: _uuid.v4(),
          title: bookTitle,
          content: '<p>No content available.</p>',
          chapterNumber: 1,
        )
      ];
    }

    final chapters = <Chapter>[];
    final rawSections = fullContent.split('===PAGEBREAK===');
    final processedSections = <String>[];

    for (final sec in rawSections) {
      final trimmed = sec.trim();
      if (trimmed.isEmpty) continue;

      final headerMatches = RegExp(r'<h[1-3][^>]*>([\s\S]*?)<\/h[1-3]>', caseSensitive: false).allMatches(trimmed).toList();
      if (headerMatches.length > 1) {
        final parts = trimmed.split(RegExp(r'(?=<h[1-3][^>]*>)', caseSensitive: false));
        for (final p in parts) {
          if (p.trim().isNotEmpty) processedSections.add(p.trim());
        }
      } else {
        processedSections.add(trimmed);
      }
    }

    int chapterNum = 1;
    for (final sectionContent in processedSections) {
      final trimmed = sectionContent.trim();
      if (trimmed.isEmpty) continue;

      String chapterTitle = 'Chapter $chapterNum';

      final headerMatch = RegExp(r'<h[1-6][^>]*>([\s\S]*?)<\/h[1-6]>', caseSensitive: false).firstMatch(trimmed);
      if (headerMatch != null && headerMatch.group(1) != null) {
        final extractedTitle = headerMatch.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (extractedTitle.isNotEmpty && extractedTitle.length < 120) {
          chapterTitle = extractedTitle;
        }
      }

      chapters.add(Chapter(
        id: _uuid.v4(),
        title: chapterTitle,
        content: trimmed,
        chapterNumber: chapterNum,
      ));
      chapterNum++;
    }

    if (chapters.isEmpty) {
      chapters.add(Chapter(
        id: _uuid.v4(),
        title: bookTitle,
        content: fullContent,
        chapterNumber: 1,
      ));
    }

    return chapters;
  }
}
