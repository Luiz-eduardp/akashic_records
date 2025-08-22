import 'dart:io';
import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class NovelMania implements PluginService {
  @override
  String get name => 'NovelMania';
  @override
  String get lang => 'pt-BR';
  @override
  String get siteUrl => site; 
  @override
  Map<String, dynamic> get filters => {
    'genres': {
      'value': '',
      'label': 'Gêneros',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ação', 'value': '01'},
        {'label': 'Adulto', 'value': '02'},
        {'label': 'Artes Marciais', 'value': '07'},
        {'label': 'Aventura', 'value': '03'},
        {'label': 'Comédia', 'value': '04'},
        {'label': 'Cotidiano', 'value': '16'},
        {'label': 'Drama', 'value': '23'},
        {'label': 'Ecchi', 'value': '27'},
        {'label': 'Erótico', 'value': '22'},
        {'label': 'Escolar', 'value': '13'},
        {'label': 'Fantasia', 'value': '05'},
        {'label': 'Harém', 'value': '21'},
        {'label': 'Isekai', 'value': '30'},
        {'label': 'Magia', 'value': '26'},
        {'label': 'Mecha', 'value': '08'},
        {'label': 'Medieval', 'value': '31'},
        {'label': 'Militar', 'value': '24'},
        {'label': 'Mistério', 'value': '09'},
        {'label': 'Mitologia', 'value': '10'},
        {'label': 'Psicológico', 'value': '11'},
        {'label': 'Realidade Virtual', 'value': '36'},
        {'label': 'Romance', 'value': '12'},
        {'label': 'Sci-fi', 'value': '14'},
        {'label': 'Sistema de Jogo', 'value': '15'},
        {'label': 'Sobrenatural', 'value': '17'},
        {'label': 'Suspense', 'value': '29'},
        {'label': 'Terror', 'value': '06'},
        {'label': 'Wuxia', 'value': '18'},
        {'label': 'Xianxia', 'value': '19'},
        {'label': 'Xuanhuan', 'value': '20'},
        {'label': 'Yaoi', 'value': '35'},
        {'label': 'Yuri', 'value': '37'},
      ],
    },
    'status': {
      'value': '',
      'label': 'Status',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ativo', 'value': 'ativo'},
        {'label': 'Completo', 'value': 'Completo'},
        {'label': 'Pausado', 'value': 'pausado'},
        {'label': 'Parado', 'value': 'Parado'},
      ],
    },
    'type': {
      'value': '',
      'label': 'Type',
      'options': [
        {'label': 'Todas', 'value': ''},
        {'label': 'Americana', 'value': 'americana'},
        {'label': 'Angolana', 'value': 'angolana'},
        {'label': 'Brasileira', 'value': 'brasileira'},
        {'label': 'Chinesa', 'value': 'chinesa'},
        {'label': 'Coreana', 'value': 'coreana'},
        {'label': 'Japonesa', 'value': 'japonesa'},
      ],
    },
    'ordem': {
      'label': 'Ordenar',
      'value': '',
      'options': [
        {'label': 'Qualquer ordem', 'value': ''},
        {'label': 'Ordem alfabética', 'value': '1'},
        {'label': 'Nº de Capítulos', 'value': '2'},
        {'label': 'Popularidade', 'value': '3'},
        {'label': 'Novidades', 'value': '4'},
      ],
    },
  };

  final String id = 'novelmania.com.br';
  final String nameService = 'NovelMania';
  final String site = 'https://novelmania.com.br';
  @override
  final String version = '1.0.8';
  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed';

  Future<String> _fetchApi(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha ao carregar dados de: $url');
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,  
      BuildContext? context,
  }) async {
    return _fetchNovels(pageNo, filters: filters);
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final body = await _fetchApi(site + novelPath);
    final document = parse(body);

    var titleElement = document.querySelector(
      'div.col-md-8 > div.novel-info > div.d-flex.flex-row.align-items-center > h1',
    );
    titleElement?.children.removeWhere((element) => element.localName == 'b');
    final novelName = titleElement?.text.trim() ?? 'Sem título';

    final novel = Novel(
      id: novelPath,
      title: novelName,
      author:
          document
              .querySelector('div.novel-info > span.authors.mb-1')
              ?.text
              .trim() ??
          'Desconhecido',
      coverImageUrl:
          document
              .querySelector('div.novel-img > img.img-responsive')
              ?.attributes['src'] ??
          NovelMania.defaultCover,
      description:
          document
              .querySelector('div.tab-pane.fade.show.active > div.text > p')
              ?.text
              .trim() ??
          '',
      genres:
          document
              .querySelectorAll('div.tags > ul.list-tags.mb-0 > li > a')
              .map((e) => e.text)
              .toList(),
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: name,
    );

    final statusString =
        document
            .querySelector('div.novel-info > span.authors.mb-3')
            ?.text
            .trim();
    switch (statusString) {
      case 'Ativo':
        novel.status = NovelStatus.Andamento;
        break;
      case 'Pausado':
        novel.status = NovelStatus.Pausada;
        break;
      case 'Completo':
        novel.status = NovelStatus.Completa;
        break;
      default:
        novel.status = NovelStatus.Desconhecido;
    }

    final chapterElements = document.querySelectorAll(
      'div.accordion.capitulo > div.card > div.collapse > div.card-body.p-0 > ol > li',
    );

    int chapterNumber = 1;
    for (var el in chapterElements) {
      final chapterNameElement = el.querySelector('a');
      final String chapterName;
      if (chapterNameElement != null) {
        final subVol =
            chapterNameElement.querySelector('span.sub-vol')?.text.trim() ?? '';
        final strongText =
            chapterNameElement.querySelector('strong')?.text.trim() ?? '';
        chapterName = '$subVol - $strongText';
      } else {
        chapterName = "Capitulo Sem Nome";
      }

      final chapterPath = el.querySelector('a')?.attributes['href'];
      if (chapterPath != null && chapterName.isNotEmpty) {
        novel.chapters.add(
          Chapter(
            id: chapterPath,
            title: chapterName,
            content: '',
            chapterNumber: chapterNumber,
          ),
        );
        chapterNumber++;
      }
    }

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    final body = await _fetchApi('$site$chapterPath');
    final document = parse(body);
    return document.querySelector('div#chapter-content')?.innerHtml ?? '';
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    return _fetchNovels(pageNo, searchTerm: searchTerm, filters: filters);
  }

  Future<List<Novel>> _fetchNovels(
    int pageNo, {
    String searchTerm = '',
    Map<String, dynamic>? filters,
  }) async {
    final queryParameters = {
      'titulo': searchTerm,
      'categoria': filters?['genres']?['value'] ?? '',
      'nacionalidade': filters?['type']?['value'] ?? '',
      'status': filters?['status']?['value'] ?? '',
      'ordem': filters?['ordem']?['value'] ?? '',
      'commit': 'Pesquisar+novel',
      'page[page]': pageNo.toString(),
    };

    queryParameters.removeWhere(
      (key, value) => value == null || value.toString().isEmpty,
    );

    final uri = Uri.https('novelmania.com.br', '/novels', queryParameters);

    try {
      final body = await _fetchApi(uri.toString());
      final document = parse(body);

      final novelElements = document.querySelectorAll(
        'div.top-novels.dark.col-6 > div.row.mb-2',
      );

      List<Novel> novels = [];

      for (var element in novelElements) {
        try {
          final name = element.querySelector('a.novel-title > h5')?.text ?? '';
          final cover =
              element
                  .querySelector(
                    'a > div.card.c-size-1.border > img.card-image',
                  )
                  ?.attributes['src'];
          final path =
              element.querySelector('a.novel-title')?.attributes['href'] ?? '';
          if (name.isNotEmpty && path.isNotEmpty) {
            if (cover != null) {
              novels.add(
                Novel(
                  id: path,
                  title: name,
                  coverImageUrl: cover,
                  author: '',
                  description: '',
                  genres: [],
                  chapters: [],
                  artist: '',
                  statusString: '',
                  pluginId: name,
                ),
              );
            }
          }
        } catch (e) {
          print('Error parsing novel element: $e');
        }
      }

      return novels;
    } catch (e) {
      print('Error fetching or parsing popular novels: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    return _fetchNovels(pageNo, searchTerm: '');
  }
}
