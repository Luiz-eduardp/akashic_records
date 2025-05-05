import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:epubx/epubx.dart' as epubx;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class Dispositivo implements PluginService {
  @override
  String get name => 'Dispositivo';

  @override
  String get lang => 'pt-BR';

  @override
  Map<String, dynamic> get filters => {};

  final String id = 'Dispositivo';
  final String nameService = 'Dispositivo';
  @override
  final String version = '1.1.0';

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

  Future<Novel> _parseEpub(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final epubx.EpubBook epubBook = await epubx.EpubReader.readBook(bytes);

      final title = epubBook.Title ?? 'Untitled';
      final author = epubBook.Author ?? 'Unknown Author';
      Uint8List? coverImage = epubBook.CoverImage as Uint8List?;

      String? coverImageUrl;

      if (coverImage != null) {
        List<int> imageBytes = coverImage;
        String base64Image = base64Encode(imageBytes);
        coverImageUrl = 'data:image/png;base64,$base64Image';
      }

      final novel = Novel(
        id: filePath,
        title: title,
        coverImageUrl:
            coverImageUrl ??
            'https://placehold.co/400x500.png?text=Cover%20Scrap%20Failed',
        author: author,
        description:
            epubBook.Schema?.Package?.Metadata?.Description ??
            'No description available.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: name,
      );

      for (var chapter in epubBook.Chapters!) {
        novel.chapters.add(
          Chapter(
            id: chapter.ContentFileName ?? '',
            title: chapter.Title ?? 'Untitled Chapter',
            content: chapter.HtmlContent ?? 'No content available.',
            chapterNumber: epubBook.Chapters!.indexOf(chapter) + 1,
          ),
        );
      }

      return novel;
    } catch (e) {
      print('Error parsing EPUB file: $e');
      throw Exception('Error parsing EPUB file: $e');
    }
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final extension = path.extension(novelPath).toLowerCase();

    switch (extension) {
      case '.epub':
        return _parseEpub(novelPath);
      case '.pdf':
        throw UnimplementedError('PDF parsing is not yet implemented.');
      case '.mobi':
        throw UnimplementedError('MOBI parsing is not yet implemented.');
      default:
        throw UnsupportedError('Unsupported file format: $extension');
    }
  }

  String _currentNovelPath = "";
  epubx.EpubBook? _currentEpubBook;

  @override
  Future<String> parseChapter(String chapterPath) async {
    if (_currentEpubBook == null) {
      if (_currentNovelPath.isEmpty) {
        return 'Novel not loaded. Please load a novel first.';
      }

      try {
        final file = File(_currentNovelPath);
        final bytes = await file.readAsBytes();
        _currentEpubBook = await epubx.EpubReader.readBook(bytes);
      } catch (e) {
        print('Error parsing EPUB book: $e');
        return 'Error loading the EPUB book.';
      }
    }

    try {
      final chapter = _currentEpubBook!.Chapters?.firstWhere(
        (c) => c.ContentFileName == chapterPath,
        orElse: () => epubx.EpubChapter(),
      );

      if (chapter != null) {
        return chapter.HtmlContent ?? 'No content available.';
      } else {
        return 'Chapter not found.';
      }
    } catch (e) {
      print('Error parsing chapter: $e');
      return 'Error loading chapter content.';
    }
  }

  Future<Novel> parseNovelWithCurrentPath(String novelPath) async {
    _currentNovelPath = novelPath;

    try {
      final file = File(_currentNovelPath);
      final bytes = await file.readAsBytes();
      _currentEpubBook = await epubx.EpubReader.readBook(bytes);

      return await _parseEpub(novelPath);
    } catch (e) {
      print('Error parsing EPUB file: $e');
      throw Exception('Error parsing EPUB file: $e');
    }
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
}
