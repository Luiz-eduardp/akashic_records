import 'dart:io';
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/models/chapter.dart';
import 'package:dio/dio.dart';

import 'package:akashic_records/models/novel_status.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class LightNovelPub {
  final String id = 'LightNovelPub';
  final String name = 'Light Novel Pub';
  final String baseURL = 'https://www.lightnovelpub.com';
  final String version = '1.0.0';
  final Dio dio = Dio();
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36';

  static const String defaultCover =
      'https://via.placeholder.com/150x200?text=No+Cover';

  LightNovelPub() {
    HttpOverrides.global = MyHttpOverrides();
    dio.options.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': _userAgent,
    };
  }

  String _shrinkURL(String url) {
    return url.replaceAll(RegExp(r'^.+lightnovelpub\.com'), '');
  }

  String _expandURL(String path) {
    return baseURL + path;
  }

  Future<Response> _fetchApi(String url) async {
    final response = await dio.get(
      url,
      options: Options(headers: {'User-Agent': _userAgent}),
    );
    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception(
        'Failed to load data from: $url, status code: ${response.statusCode}',
      );
    }
  }

  Future<List<Novel>> _parseNovelList(String url) async {
    final response = await _fetchApi(url);
    final body = response.data;
    final document = parse(body);

    final novelElements = document.querySelectorAll('div.novel-list-item');

    List<Novel> novels = [];
    for (final element in novelElements) {
      final titleElement = element.querySelector('.novel-title a');
      final title = titleElement?.text.trim() ?? '';
      final link = _shrinkURL(titleElement?.attributes['href'] ?? '');
      final coverElement = element.querySelector('.novel-cover img');
      final cover = coverElement?.attributes['data-src'] ?? defaultCover;
      final author =
          element.querySelector('.novel-author')?.text.trim() ?? 'Unknown';

      if (title.isNotEmpty && link.isNotEmpty) {
        novels.add(
          Novel(
            id: link,
            title: title,
            coverImageUrl: cover,
            author: author,
            description: '',
            genres: [],
            chapters: [],
            artist: '',
            statusString: '',
          ),
        );
      }
    }
    return novels;
  }

  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$baseURL/browse/most-popular-novel/all/$pageNo?page=$pageNo';
    return await _parseNovelList(url);
  }

  Future<List<Novel>> recentNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url =
        '$baseURL/browse/recently-updated-novel/all/$pageNo?page=$pageNo';
    return await _parseNovelList(url);
  }

  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    final url = '$baseURL/lnsearchlive';

    final link = '$baseURL/search';
    final response = await dio.get(
      link,
      options: Options(headers: {'User-Agent': _userAgent}),
    );
    final document = parse(response.data);
    final verifytoken =
        document
            .querySelector(
              "#novelSearchForm input[name=__LNRequestVerifyToken]",
            )
            ?.attributes['value'];

    if (verifytoken == null) {
      throw Exception('LNRequestVerifyToken not found');
    }

    final formData = FormData.fromMap({'inputContent': searchTerm});

    final searchResponse = await dio.post(
      url,
      data: formData,
      options: Options(
        headers: {
          'LNRequestVerifyToken': verifytoken,
          'User-Agent': _userAgent,
        },
      ),
    );

    final resultView = searchResponse.data['resultview'];
    if (resultView != null) {
      final searchDocument = parse(resultView);
      final novelElements = searchDocument.querySelectorAll('.novel-item a');

      List<Novel> novels = [];
      for (final element in novelElements) {
        final titleElement = element.querySelector(
          'div.item-body .novel-title',
        );
        final title = titleElement?.text.trim() ?? '';
        final link = _shrinkURL(element.attributes['href'] ?? '');
        final coverElement = element.querySelector('div.novel-cover img');
        final cover = coverElement?.attributes['src'] ?? defaultCover;

        if (title.isNotEmpty && link.isNotEmpty) {
          novels.add(
            Novel(
              id: link,
              title: title,
              coverImageUrl: cover,
              author: '',
              description: '',
              genres: [],
              chapters: [],
              artist: '',
              statusString: '',
            ),
          );
        }
      }
      return novels;
    } else {
      throw Exception('Search results not found in response');
    }
  }

  Future<Novel> parseNovel(String novelPath) async {
    final response = await _fetchApi(_expandURL(novelPath));
    final document = parse(response.data);

    final title =
        document.querySelector('.novel-title')?.text.trim() ?? 'Sem título';
    final coverElement = document.querySelector('.novel-cover img');
    final cover = coverElement?.attributes['data-src'] ?? defaultCover;
    final author =
        document.querySelector('.novel-author')?.text.trim() ?? 'Desconhecido';
    final description =
        document.querySelector('.novel-summary')?.text.trim() ??
        'Sem descrição';
    final genres =
        document
            .querySelectorAll('.novel-genres a')
            .map((e) => e.text.trim())
            .toList();

    final statusSpan = document.querySelector('.novel-stats span.status');
    String statusString = statusSpan?.text.trim() ?? 'Unknown';

    NovelStatus status;
    if (statusString.contains('Ongoing')) {
      status = NovelStatus.Ongoing;
    } else if (statusString.contains('Completed')) {
      status = NovelStatus.Completed;
    } else {
      status = NovelStatus.Unknown;
    }

    final List<Chapter> chapters = [];
    final chapterElements = document.querySelectorAll('.chapter-list li a');
    int order = 0;
    for (final chapterElement in chapterElements) {
      order++;
      final chapterPath = _shrinkURL(chapterElement.attributes['href'] ?? '');
      final chapterTitle =
          chapterElement.querySelector('.chapter-title')?.text.trim() ?? '';

      if (chapterPath.isNotEmpty && chapterTitle.isNotEmpty) {
        chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterTitle,
            order: order,
            content: '',
            releaseDate: '',
            chapterNumber: null,
          ),
        );
      }
    }
    chapters.sort((a, b) => a.order.compareTo(b.order));

    return Novel(
      id: novelPath,
      title: title,
      coverImageUrl: cover,
      author: author,
      description: description,
      genres: genres,
      status: status,
      chapters: chapters,
      artist: '',
      statusString: '',
    );
  }

  Future<String> parseChapter(String chapterPath) async {
    final response = await _fetchApi(_expandURL(chapterPath));
    final document = parse(response.data);

    final chapterContentElement = document.querySelector('div.chapter-content');

    if (chapterContentElement != null) {
      chapterContentElement
          .querySelectorAll('div[id^="div-gpt-ad"]')
          .forEach((el) => el.remove());
      chapterContentElement
          .querySelectorAll('div.hidden')
          .forEach((el) => el.remove());
      chapterContentElement
          .querySelectorAll('div.ads-holder')
          .forEach((el) => el.remove());

      return chapterContentElement.innerHtml;
    } else {
      throw Exception('Chapter content not found at $chapterPath');
    }
  }

  String createFilterUrl(
    Map<String, dynamic>? filters,
    String order,
    int page,
  ) {
    String genre = "genre-all-04061342";
    String orderBy = "order-new";
    String status = "status-all";

    if (filters != null) {
      if (filters.containsKey('genres') && filters['genres'] != null) {
        final genreValues = filters['genres']['value'];
        if (genreValues is List && genreValues.isNotEmpty) {
          genre = getGenreValue(genreValues.first);
        }
      }

      if (filters.containsKey('order') && filters['order'] != null) {
        final orderValue = filters['order']['value'];
        if (orderValue is String && orderValue.isNotEmpty) {
          orderBy = getOrderByValue(orderValue);
        }
      }

      if (filters.containsKey('status') && filters['status'] != null) {
        final statusValue = filters['status']['value'];
        if (statusValue is String && statusValue.isNotEmpty) {
          status = getStatusValue(statusValue);
        }
      }
    }
    final url = '$baseURL/browse/$genre/$orderBy/$status/?page=$page';
    print("URL gerada: $url");
    return url;
  }

  String getOrderByValue(String key) {
    const filterOrderbyValues = {
      'default': 'order-new',
      'a-z': 'order-az',
      'z-a': 'order-za',
      'latest-update': 'order-updated',
      'latest-added': 'order-new',
      'popular': 'order-popular',
    };
    return filterOrderbyValues[key] ?? 'order-new';
  }

  String getStatusValue(String key) {
    const filterStatusValues = {
      'all': 'status-all',
      'ongoing': 'status-ongoing',
      'on-hiatus': 'status-hiatus',
      'completed': 'status-completed',
    };
    return filterStatusValues[key] ?? 'status-all';
  }

  String getGenreValue(String key) {
    const filterGenresValues = {
      'all': "genre-all-04061342",
      'action': "genre-action-04061342",
      'adventure': "genre-adventure-04061342",
      'drama': "genre-drama-04061342",
      'fantasy': "genre-fantasy-04061342",
      'harem': "genre-harem-04061342",
      'martial-arts': "genre-martial-arts-10032131",
      'mature': "genre-mature-04061342",
      'romance': "genre-romance-04061342",
      'tragedy': "genre-tragedy-10032131",
      'xuanhuan': "genre-xuanhuan-10032131",
      'ecchi': "genre-ecchi-04061342",
      'comedy': "genre-comedy-10032131",
      'slice-of-life': "genre-slice-of-life-04061342",
      'mystery': "genre-mystery-10032131",
      'supernatural': "genre-supernatural-10032131",
      'psychological': "genre-psychological-10032131",
      'sci-fi': "genre-sci-fi-04061342",
      'xianxia': "genre-xianxia-04061342",
      'school-life': "genre-school-life-10032131",
      'josei': "genre-josei-04061342",
      'wuxia': "genre-wuxia-04061342",
      'shounen': "genre-shounen-10032131",
      'horror': "genre-horror-04061342",
      'mecha': "genre-mecha-10032131",
      'historical': "genre-historical-04061342",
      'shoujo': "genre-shoujo-10032131",
      'adult': "genre-adult-04061342",
      'seinen': "genre-seinen-04061342",
      'sports': "genre-sports-10032131",
      'lolicon': "genre-lolicon-10032131",
      'gender-bender': "genre-gender-bender-04061342",
      'shounen-ai': "genre-shounen-ai-10032131",
      'yaoi': "genre-yaoi-04061342",
      'video-games': "genre-video-games-04061342",
      'smut': "genre-smut-04061342",
      'magical-realism': "genre-magical-realism-10032131",
      'eastern-fantasy': "genre-eastern-fantasy-04061342",
      'contemporary-romance': "genre-contemporary-romance-10032131",
      'fantasy-romance': "genre-fantasy-romance-10032131",
      'shoujo-ai': "genre-shoujo-ai-10032131",
      'yuri': "genre-yuri-10032131",
    };
    return filterGenresValues[key] ?? key;
  }

  Map<String, dynamic> get filters => {
    'order': {
      'label': 'Ordenar por',
      'value': 'default',
      'options': [
        {'label': 'Padrão', 'value': 'default'},
        {'label': 'A-Z', 'value': 'a-z'},
        {'label': 'Z-A', 'value': 'z-a'},
        {'label': 'Últ. Att', 'value': 'latest-update'},
        {'label': 'Últ. Add', 'value': 'latest-added'},
        {'label': 'Populares', 'value': 'popular'},
      ],
    },
    'status': {
      'label': 'Status',
      'value': 'all',
      'options': [
        {'label': 'Todos', 'value': 'all'},
        {'label': 'Em andamento', 'value': 'ongoing'},
        {'label': 'Completo', 'value': 'completed'},
      ],
    },
    'genres': {
      'label': 'Gêneros',
      'value': [],
      'options': [
        {'label': 'All', 'value': 'all'},
        {'label': 'Action', 'value': 'action'},
        {'label': 'Adventure', 'value': 'adventure'},
        {'label': 'Drama', 'value': 'drama'},
        {'label': 'Fantasy', 'value': 'fantasy'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Martial Arts', 'value': 'martial-arts'},
        {'label': 'Mature', 'value': 'mature'},
        {'label': 'Romance', 'value': 'romance'},
        {'label': 'Tragedy', 'value': 'tragedy'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Ecchi', 'value': 'ecchi'},
        {'label': 'Comedy', 'value': 'comedy'},
        {'label': 'Slice of Life', 'value': 'slice-of-life'},
        {'label': 'Mystery', 'value': 'mystery'},
        {'label': 'Supernatural', 'value': 'supernatural'},
        {'label': 'Psychological', 'value': 'psychological'},
        {'label': 'Sci-fi', 'value': 'sci-fi'},
        {'label': 'Xianxia', 'value': 'xianxia'},
        {'label': 'School Life', 'value': 'school-life'},
        {'label': 'Josei', 'value': 'josei'},
        {'label': 'Wuxia', 'value': 'wuxia'},
        {'label': 'Shounen', 'value': 'shounen'},
        {'label': 'Horror', 'value': 'horror'},
        {'label': 'Mecha', 'value': 'mecha'},
        {'label': 'Historical', 'value': 'historical'},
        {'label': 'Shoujo', 'value': 'shoujo'},
        {'label': 'Adult', 'value': 'adult'},
        {'label': 'Seinen', 'value': 'seinen'},
        {'label': 'Sports', 'value': 'sports'},
        {'label': 'Lolicon', 'value': 'lolicon'},
        {'label': 'Gender Bender', 'value': 'gender-bender'},
        {'label': 'Shounen Ai', 'value': 'shounen-ai'},
        {'label': 'Yaoi', 'value': 'yaoi'},
        {'label': 'Video Games', 'value': 'video-games'},
        {'label': 'Smut', 'value': 'smut'},
        {'label': 'Magical Realism', 'value': 'magical-realism'},
        {'label': 'Eastern Fantasy', 'value': 'eastern-fantasy'},
        {'label': 'Contemporary Romance', 'value': 'contemporary-romance'},
        {'label': 'Fantasy Romance', 'value': 'fantasy-romance'},
        {'label': 'Shoujo Ai', 'value': 'shoujo-ai'},
        {'label': 'Yuri', 'value': 'yuri'},
      ],
    },
  };
}
