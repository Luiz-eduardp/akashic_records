import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class Sunovels implements PluginService {
  String get id => 'sunovels';

  @override
  String get name => 'Sunovels';

  @override
  String get version => '1.0.0';

  @override
  String get lang => 'ar';

  final String site = 'https://sunovels.com/';

  @override
  Map<String, dynamic> get filters => {
    'categories': {
      'value': <String>[],
      'label': 'التصنيفات',
      'options': [
        {'label': 'Wuxia', 'value': 'Wuxia'},
        {'label': 'Xianxia', 'value': 'Xianxia'},
        {'label': 'XUANHUAN', 'value': 'XUANHUAN'},
        {'label': 'أصلية', 'value': 'أصلية'},
        {'label': 'أكشن', 'value': 'أكشن'},
        {'label': 'إثارة', 'value': 'إثارة'},
        {'label': 'إنتقال الى عالم أخر', 'value': 'إنتقال+الى+عالم+أخر'},
        {'label': 'إيتشي', 'value': 'إيتشي'},
        {'label': 'الخيال العلمي', 'value': 'الخيال+العلمي'},
        {'label': 'بوليسي', 'value': 'بوليسي'},
        {'label': 'تاريخي', 'value': 'تاريخي'},
        {'label': 'تقمص شخصيات', 'value': 'تقمص+شخصيات'},
        {'label': 'جريمة', 'value': 'جريمة'},
        {'label': 'جوسى', 'value': 'جوسى'},
        {'label': 'حريم', 'value': 'حريم'},
        {'label': 'حياة مدرسية', 'value': 'حياة+مدرسية'},
        {'label': 'خارقة للطبيعة', 'value': 'خارقة+للطبيعة'},
        {'label': 'خيالي', 'value': 'خيالي'},
        {'label': 'دراما', 'value': 'دراما'},
        {'label': 'رعب', 'value': 'رعب'},
        {'label': 'رومانسي', 'value': 'رومانسي'},
        {'label': 'سحر', 'value': 'سحر'},
        {'label': 'سينن', 'value': 'سينن'},
        {'label': 'شريحة من الحياة', 'value': 'شريحة+من+الحياة'},
        {'label': 'شونين', 'value': 'شونين'},
        {'label': 'غموض', 'value': 'غموض'},
        {'label': 'فنون القتال', 'value': 'فنون+القتال'},
        {'label': 'قوى خارقة', 'value': 'قوى+خارقة'},
        {'label': 'كوميدى', 'value': 'كوميدى'},
        {'label': 'مأساوي', 'value': 'مأساوي'},
        {'label': 'ما بعد الكارثة', 'value': 'ما+بعد+الكارثة'},
        {'label': 'مغامرة', 'value': 'مغامرة'},
        {'label': 'ميكا', 'value': 'ميكا'},
        {'label': 'ناضج', 'value': 'ناضج'},
        {'label': 'نفسي', 'value': 'نفسي'},
        {'label': 'فانتازيا', 'value': 'فانتازيا'},
        {'label': 'رياضة', 'value': 'رياضة'},
        {'label': 'ابراج', 'value': 'ابراج'},
        {'label': 'الالهة', 'value': 'الالهة'},
        {'label': 'شياطين', 'value': 'شياطين'},
        {'label': 'السفر عبر الزمن', 'value': 'السفر+عبر+الزمن'},
        {'label': 'رواية صينية', 'value': 'رواية+صينية'},
        {'label': 'رواية ويب', 'value': 'رواية+ويب'},
        {'label': 'لايت نوفل', 'value': 'لايت+نوفل'},
        {'label': 'كوري', 'value': 'كوري'},
        {'label': '+18', 'value': '%2B18'},
        {'label': 'إيسكاي', 'value': 'إيسكاي'},
        {'label': 'ياباني', 'value': 'ياباني'},
        {'label': 'مؤلفة', 'value': 'مؤلفة'},
      ],
      'type': FilterTypes.excludableCheckboxGroup,
    },
    'status': {
      'value': '',
      'label': 'الحالة',
      'options': [
        {'label': 'جميع الروايات', 'value': ''},
        {'label': 'مكتمل', 'value': 'Completed'},
        {'label': 'جديد', 'value': 'New'},
        {'label': 'مستمر', 'value': 'Ongoing'},
      ],
      'type': FilterTypes.picker,
    },
  };

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data from: $url');
    }
  }

  List<Novel> _parseNovels(String html) {
    final novels = <Novel>[];
    final document = parse(html);
    final imageUrlList = <String>[];

    document.querySelectorAll('script').forEach((element) {
      final scriptText = element.text;
      final regex = RegExp(r'\/uploads\/[^\s"]+', multiLine: true);
      final imageUrlMatches =
          regex.allMatches(scriptText).map((m) => m.group(0)!).toList();
      imageUrlList.addAll(imageUrlMatches);
    });

    int counter = 0;
    document.querySelectorAll('.list-item').forEach((listItem) {
      listItem.querySelectorAll('a').forEach((anchor) {
        final novelName = anchor.querySelector('h4')?.text.trim() ?? '';
        final novelUrl =
            anchor.attributes['href']?.trim().replaceFirst(
              RegExp(r'^\/*'),
              '',
            ) ??
            '';
        String novelCover =
            'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

        if (imageUrlList.isNotEmpty) {
          novelCover = site + imageUrlList[counter].substring(1);
        } else {
          final imageUrl = anchor.querySelector('img')?.attributes['src'];
          if (imageUrl != null) {
            novelCover = site + imageUrl.substring(1);
          }
        }

        final novel = Novel(
          id: novelUrl,
          title: novelName,
          coverImageUrl: novelCover,
          author: '',
          description: '',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
          pluginId: id,
        );
        counter++;
        novels.add(novel);
      });
    });

    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
    bool showLatestNovels = true,
  }) async {
    final pageCorrected = pageNo - 1;
    String link = '${site}library?';

    if (filters != null) {
      final categories =
          (filters['categories']['value'] as List<String>?) ?? [];
      if (categories.isNotEmpty) {
        for (final genre in categories) {
          link += '&category=$genre';
        }
      }
      if (filters['status']['value'] != null &&
          filters['status']['value'].isNotEmpty) {
        link += '&status=${filters['status']['value']}';
      }
    }
    link += '&page=$pageCorrected';

    final body = await _fetchApi(link);
    return _parseNovels(body);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = Uri.parse(novelPath).isAbsolute ? novelPath : site + novelPath;
    final html = await _fetchApi(url);
    final document = parse(html);

    final novel = Novel(
      id: novelPath,
      title:
          document.querySelector('div.main-head h3')?.text.trim() ?? 'Untitled',
      author: document.querySelector('.novel-author')?.text.trim() ?? '',
      description:
          document
              .querySelector('section.info-section div.description p')
              ?.text
              .trim() ??
          '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: id,
      coverImageUrl: '',
    );

    final statusWords = {'مكتمل', 'جديد', 'مستمر'};
    final mainGenres = document
        .querySelectorAll('div.categories li.tag')
        .map((el) => el.text.trim())
        .join(',');

    final statusGenreElements = document
        .querySelectorAll('div.header-stats span')
        .elementAt(3)
        .querySelectorAll('strong');
    final statusGenre =
        statusGenreElements
            .map((el) => el.text.trim())
            .where((text) => statusWords.contains(text))
            .join();

    novel.genres =
        (statusGenre.isNotEmpty || mainGenres.isNotEmpty)
            ? '$statusGenre,$mainGenres'.split(',').toList()
            : [];

    final statusTextElements = document
        .querySelectorAll('div.header-stats span')
        .elementAt(3)
        .querySelectorAll('strong');
    final statusText =
        statusTextElements
            .map((el) => el.text.trim())
            .where((text) => statusWords.contains(text))
            .join();

    novel.statusString = statusText;
    novel.status = _parseNovelStatus(statusText);

    final imageUrl =
        document
            .querySelector('div.img-container figure.cover img')
            ?.attributes['src'];
    novel.coverImageUrl =
        imageUrl != null
            ? site + imageUrl.substring(1)
            : 'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

    novel.chapters = await _getChapters(novelPath);

    return novel;
  }

  Future<List<Chapter>> _getChapters(String novelPath) async {
    final chapterList = <Chapter>[];

    final url = Uri.parse(novelPath).isAbsolute ? novelPath : site + novelPath;
    final html = await _fetchApi(url);
    final document = parse(html);

    final headerLinks = document.querySelectorAll('nav.header-links a');
    String? firstChapterUrl = headerLinks.first.attributes['href'];
    String? lastChapterUrl =
        headerLinks
            .lastWhere((element) => element.attributes.containsKey('href'))
            .attributes['href'];

    if (firstChapterUrl == null || lastChapterUrl == null) {
      return chapterList;
    }

    int firstChapterNumber = int.tryParse(firstChapterUrl.split('/').last) ?? 0;
    int lastChapterNumber = int.tryParse(lastChapterUrl.split('/').last) ?? 0;

    for (int i = firstChapterNumber; i <= lastChapterNumber; i++) {
      final chapterUrl = 'novel/nine-star-hegemon-body-art/$i';
      chapterList.add(
        Chapter(
          id: chapterUrl,
          title: 'Chapter $i',
          content: '',
          order: i - firstChapterNumber,
          chapterNumber: i,
        ),
      );
    }

    return chapterList;
  }

  NovelStatus _parseNovelStatus(String statusText) {
    switch (statusText) {
      case 'جديد':
        return NovelStatus.Andamento;
      case 'مكتمل':
        return NovelStatus.Completa;
      case 'مستمر':
        return NovelStatus.Andamento;
      default:
        return NovelStatus.Desconhecido;
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final result = await _fetchApi(site + chapterPath);
    final body = result;
    final document = parse(body);

    final chapterContentElement = document.querySelector(
      'section.page-in.content-wrap',
    );

    chapterContentElement?.querySelectorAll('.d-none').forEach((element) {
      element.remove();
    });

    String chapterText = chapterContentElement?.innerHtml ?? '';

    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final searchUrl = '${site}search?page=$pageNo&title=$searchTerm';
    final body = await _fetchApi(searchUrl);
    return _parseNovels(body);
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    final url = '${site}library?page=$pageNo';
    final body = await _fetchApi(url);
    return _parseNovels(body);
  }
}

enum FilterTypes { textInput, excludableCheckboxGroup, picker }
