import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:jsf/jsf.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:archive/archive_io.dart';

class Dispositivo implements PluginService {
  @override
  String get name => 'Dispositivo';

  @override
  String get lang => 'Local'.translate;

  @override
  Map<String, dynamic> get filters => {};

  final String id = 'Dispositivo';
  final String nameService = 'Dispositivo';
  @override
  final String version = '1.2.3';

  static const String defaultCover =
      'https://placehold.co/400x500.png?text=Cover%20Scrap%20Failed';

  Future<Directory> _getLocalNovelsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final novelsDirectory = Directory('${directory.path}/novels');
    if (!novelsDirectory.existsSync()) {
      await novelsDirectory.create(recursive: true);
    }
    return novelsDirectory;
  }

  Future<String> _copyNovelToLocalDirectory(String filePath) async {
    final originalFile = File(filePath);
    final novelsDirectory = await _getLocalNovelsDirectory();
    final newPath = '${novelsDirectory.path}/${path.basename(filePath)}';
    final newFile = await originalFile.copy(newPath);
    return newFile.path;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    if (context != null) {
      final appState = Provider.of<AppState>(context, listen: false);
      return appState.localNovels;
    }
    return [];
  }

  Future<Novel> _parseEpubWithEpubx(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final epubx.EpubBook epubBook = await epubx.EpubReader.readBook(bytes);

      final title = epubBook.Title ?? 'Untitled';
      final author = epubBook.Author ?? 'Unknown Author';

      String? coverImageUrl;
      if (epubBook.CoverImage != null) {
        if (epubBook.CoverImage is img.Image) {
          img.Image image = epubBook.CoverImage as img.Image;
          List<int> imageBytes = img.encodePng(image);
          String base64Image = base64Encode(imageBytes);
          coverImageUrl = 'data:image/png;base64,$base64Image';
        } else if (epubBook.CoverImage is List<int>) {
          List<int> imageBytes = epubBook.CoverImage as List<int>;
          String base64Image = base64Encode(imageBytes);
          coverImageUrl = 'data:image/png;base64,$base64Image';
        } else {
          print("Unknown cover image type: ${epubBook.CoverImage.runtimeType}");
          coverImageUrl = null;
        }
      }

      String description =
          epubBook.Schema?.Package?.Metadata?.Description ??
          'No description available.';

      final novel = Novel(
        id: filePath,
        title: title,
        coverImageUrl:
            coverImageUrl ??
            'https://placehold.co/400x500.png?text=Cover%20Scrap%20Failed',
        author: author,
        description: description,
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: name,
      );

      for (var chapter in epubBook.Chapters!) {
        String? chapterContent = chapter.HtmlContent;
        if (chapterContent != null && chapterContent.isNotEmpty) {
          novel.chapters.add(
            Chapter(
              id: chapter.ContentFileName ?? '',
              title: chapter.Title ?? 'Untitled Chapter',
              content: chapterContent,
              chapterNumber: epubBook.Chapters!.indexOf(chapter) + 1,
            ),
          );
        }
      }

      return novel;
    } catch (e) {
      print('Error parsing EPUB file with epubx: $e');
      return _parseEpubWithEpubJS(filePath);
    }
  }

  Future<Novel> _parseEpubWithEpubJS(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      base64Encode(bytes);

      final jsRuntime = JsRuntime();

      final epubJsCode = await _loadEpubJsCode();
      jsRuntime.eval(epubJsCode);

      String jsCode = '''
async function parseEpubData(epubPath) {
    try {
        const book = ePub(epubPath);
        await book.ready;

        const metadata = book.package.metadata;
        const title = metadata.title || "Untitled";
        const author = metadata.creator || "Unknown Author";
        const description = metadata.description || "No description available.";

        let coverImageUrl = null;
        try {
            const coverUrl = await book.coverUrl();
            coverImageUrl = coverUrl;
        } catch (e) {
            console.log("Error getting cover URL: ", e);
        }

        const chapters = [];
        const spine = book.spine;

        const container = document.createElement("div");
        container.style.display = "none"; 
        document.body.appendChild(container); 


        for (let i = 0; i < spine.length(); i++) {
            const item = spine.get(i);
            const href = item.href;
            const chapterTitle = item.title || "Untitled Chapter";
            let chapterContent = "";

            try {
                console.log("Loading chapter:", href);

                try {
                    chapterContent = await item.load();
                    console.log("Attempt 1: item.load() - Content:", chapterContent);
                } catch (e) {
                    console.warn("item.load() failed:", e);
                }

                if (!chapterContent) {
                    try {
                        const rendition = book.renderTo(container);
                        await rendition.display(href);
                        chapterContent = container.innerHTML;
                        console.log("Attempt 2: rendition.display() - Content:", chapterContent);
                         rendition.destroy();
                         container.innerHTML = "";
                    } catch (e) {
                         console.warn("rendition.display() failed:", e);
                    }
                }

                if (!chapterContent) {
                  try {
                    chapterContent = await book.chapterText(href);
                     console.log("Attempt 3: book.chapterText() - Content:", chapterContent);
                  } catch (err) {
                    console.warn("book.chapterText() failed", err);
                  }
                }


            }  catch (e) {
                console.error("Error loading chapter content:", e);
                chapterContent = "Error loading chapter content.";
            }


            if(chapterContent) { 
                chapters.push({
                    id: href,
                    title: chapterTitle,
                    chapterNumber: i + 1,
                    content: chapterContent,
                });
            }
        }

        document.body.removeChild(container);

        return {
            title: title,
            author: author,
            coverImageUrl: coverImageUrl,
            description: description,
            chapters: chapters,
        };
    } catch (error) {
        console.error("Error parsing EPUB in JavaScript:", error);
        throw error;
    }
}
      ''';

      dynamic result = await jsRuntime.evalAsync(jsCode);

      jsRuntime.dispose();

      if (result == null) {
        throw Exception("Failed to parse EPUB data using EpubJS");
      }

      final novel = Novel(
        id: filePath,
        title: result['title'] ?? 'Untitled',
        coverImageUrl: result['coverImageUrl'] ?? defaultCover,
        author: result['author'] ?? 'Unknown Author',
        description: result['description'] ?? 'No description available',
        genres: [],
        chapters:
            (result['chapters'] as List<dynamic>)
                .map(
                  (chapter) => Chapter(
                    id: chapter['id'],
                    title: chapter['title'],
                    chapterNumber: chapter['chapterNumber'],
                    content: chapter['content'],
                  ),
                )
                .toList(),
        artist: '',
        statusString: '',
        pluginId: name,
      );

      novel.chapters.removeWhere(
        (chapter) => chapter.content == null || chapter.content!.isEmpty,
      );

      return novel;
    } catch (e) {
      print('Error parsing EPUB file with EpubJS: $e');
      return _parseEpubFromContentOpf(filePath);
    }
  }

  Future<Novel> _parseEpubFromContentOpf(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      String? contentOpfPath;
      for (final file in archive) {
        if (file.name.endsWith('content.opf')) {
          contentOpfPath = file.name;
          break;
        } else if (file.name.contains('META-INF/') &&
            file.name.endsWith('.xml')) {
          final content = String.fromCharCodes(file.content);
          if (content.contains('content.opf')) {
            final start = content.indexOf('content.opf');
            final end = content.indexOf('"', start);
            contentOpfPath = content.substring(start, end);
            break;
          }
        }
      }

      if (contentOpfPath == null) {
        throw Exception('content.opf not found in EPUB archive.');
      }

      final contentOpfFile = archive.firstWhere(
        (file) => file.name == contentOpfPath,
      );
      final contentOpfString = String.fromCharCodes(contentOpfFile.content);

      String title = _extractValue(contentOpfString, '<dc:title>');
      String author = _extractValue(contentOpfString, '<dc:creator>');
      String description = _extractValue(contentOpfString, '<dc:description>');

      List<Chapter> chapters = [];
      final manifestItems = contentOpfString.split('<item ');
      for (final item in manifestItems) {
        if (item.contains('media-type="application/xhtml+xml"')) {
          String id = _extractValue(item, 'id="');
          String href = _extractValue(item, 'href="');
          String chapterTitle = id;
          String content = "";

          try {
            final chapterPath = path.join(path.dirname(contentOpfPath), href);

            final chapterFile = archive.firstWhere(
              (f) => f.name == chapterPath,
              orElse: () => ArchiveFile('notfound', 0, []),
            );
            if (chapterFile.name != 'notfound') {
              content = String.fromCharCodes(chapterFile.content);
            } else {
              print("File not found");
            }
          } catch (e) {
            print('Error loading chapter content from OPF: $e');
            content = 'Error loading content';
          }
          if (content.isNotEmpty) {
            chapters.add(
              Chapter(
                id: href,
                title: chapterTitle,
                chapterNumber: chapters.length + 1,
                content: content,
              ),
            );
          }
        }
      }
      String coverImageUrl =
          'https://placehold.co/400x500.png?text=Cover%20Scrap%20Failed';

      final novel = Novel(
        id: filePath,
        title: title,
        coverImageUrl: coverImageUrl,
        author: author,
        description: description,
        genres: [],
        chapters: chapters,
        artist: '',
        statusString: '',
        pluginId: name,
      );
      novel.chapters.removeWhere(
        (chapter) => chapter.content == null || chapter.content!.isEmpty,
      );

      return novel;
    } catch (e) {
      print('Error parsing EPUB from content.opf: $e');
      throw Exception('Failed to parse EPUB: $e');
    }
  }

  String _extractValue(String content, String tag) {
    try {
      final startTag = tag;
      final endTag = tag.replaceAll('<', '</');
      final startIndex = content.indexOf(startTag);

      if (startIndex == -1) {
        return '';
      }

      final endIndex = content.indexOf(endTag, startIndex + startTag.length);
      if (endIndex == -1) {
        return '';
      }
      return content.substring(startIndex + startTag.length, endIndex).trim();
    } catch (e) {
      print("Error extracting value with tag $tag");
      return "";
    }
  }

  Future<String> _loadEpubJsCode() async {
    String epubJs = await rootBundle.loadString('assets/epubjs.min.js');
    String helperJs = '''
    function base64ToArrayBuffer(base64) {
        const binary_string = atob(base64);
        const len = binary_string.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
            bytes[i] = binary_string.charCodeAt(i);
        }
        return bytes.buffer;
    }
    ''';

    return '$epubJs\n$helperJs';
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final extension = path.extension(novelPath).toLowerCase();

    switch (extension) {
      case '.epub':
        return _parseEpubWithEpubx(novelPath);
      case '.pdf':
        throw UnimplementedError('PDF parsing is not yet implemented.');
      case '.mobi':
        throw UnimplementedError('MOBI parsing is not yet implemented.');
      default:
        throw UnsupportedError('Unsupported file format: $extension');
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    return "This function is no longer used as chapter content is extracted when the novel is parsed.";
  }

  Future<Novel> parseNovelWithCurrentPath(String novelPath) async {
    return await parseNovel(novelPath);
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    return [];
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'mobi', 'pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      List<Novel> novels = [];
      for (var file in result.files) {
        if (file.path != null) {
          try {
            String localPath = await _copyNovelToLocalDirectory(file.path!);

            Novel novel = await parseNovelWithCurrentPath(localPath);
            novels.add(novel);
          } catch (e) {
            print("Error loading file: " + file.path.toString());
          }
        }
      }
      if (context != null) {
        final appState = Provider.of<AppState>(context, listen: false);
        appState.addLocalNovels(novels);
      }
      return novels;
    } else {
      return [];
    }
  }

  Future<void> deleteNovel(String novelId, {BuildContext? context}) async {
    try {
      final novelFile = File(novelId);
      if (await novelFile.exists()) {
        await novelFile.delete();
        debugPrint('Novel with ID $novelId deleted successfully.');

        if (context != null) {
          final appState = Provider.of<AppState>(context, listen: false);

          await appState.removeNovelCache('Dispositivo', novelId);

          appState.localNovels.removeWhere((novel) => novel.id == novelId);
        }
      } else {
        debugPrint('Novel with ID $novelId not found.');
      }
    } catch (e) {
      debugPrint('Error deleting novel with ID $novelId: $e');
      rethrow;
    }
  }
}

extension on JsRuntime {
  evalAsync(String jsCode) {}
}
