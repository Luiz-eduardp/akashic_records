import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'package:flutter/widgets.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:intl/intl.dart';

class Chireads implements PluginService {
  String get id => 'chireads';

  @override
  String get name => 'Chireads';

  @override
  String get lang => 'fr';

  @override
  String get version => '1.0.1';

  final String site = 'https://chireads.com';

  @override
  Map<String, dynamic> get filters => {
    'tag': {
      'type': FilterTypes.picker,
      'label': 'Tag',
      'value': 'all',
      'options': [
        {'label': 'Tous', 'value': 'all'},
        {'label': 'Arts martiaux', 'value': 'arts-martiaux'},
        {'label': 'De faible à fort', 'value': 'de-faible-a-fort'},
        {'label': 'Adapté en manhua', 'value': 'adapte-en-manhua'},
        {'label': 'Cultivation', 'value': 'cultivation'},
        {'label': 'Action', 'value': 'action'},
        {'label': 'Aventure', 'value': 'aventure'},
        {'label': 'Monstres', 'value': 'monstres'},
        {'label': 'Xuanhuan', 'value': 'xuanhuan'},
        {'label': 'Fantastique', 'value': 'fantastique'},
        {'label': 'Adapté en Animé', 'value': 'adapte-en-anime'},
        {'label': 'Alchimie', 'value': 'alchimie'},
        {'label': 'Éléments de jeux', 'value': 'elements-de-jeux'},
        {'label': 'Calme Protagoniste', 'value': 'calme-protagoniste'},
        {
          'label': 'Protagoniste intelligent',
          'value': 'protagoniste-intelligent',
        },
        {'label': 'Polygamie', 'value': 'polygamie'},
        {'label': 'Belle femelle Lea', 'value': 'belle-femelle-lea'},
        {'label': 'Personnages arrogants', 'value': 'personnages-arrogants'},
        {'label': 'Système de niveau', 'value': 'systeme-de-niveau'},
        {'label': 'Cheat', 'value': 'cheat'},
        {'label': 'Protagoniste génie', 'value': 'protagoniste-genie'},
        {'label': 'Comédie', 'value': 'comedie'},
        {'label': 'Gamer', 'value': 'gamer'},
        {'label': 'Mariage', 'value': 'mariage'},
        {'label': 'seeking Protag', 'value': 'seeking-protag'},
        {'label': 'Romance précoce', 'value': 'romance-precoce'},
        {'label': 'Croissance accélérée', 'value': 'croissance-acceleree'},
        {'label': 'Artefacts', 'value': 'artefacts'},
        {
          'label': 'Intelligence artificielle',
          'value': 'intelligence-artificielle',
        },
        {'label': 'Mariage arrangé', 'value': 'mariage-arrange'},
        {'label': 'Mature', 'value': 'mature'},
        {'label': 'Adulte', 'value': 'adulte'},
        {
          'label': 'Administrateur de système',
          'value': 'administrateur-de-systeme',
        },
        {'label': 'Beau protagoniste', 'value': 'beau-protagoniste'},
        {
          'label': 'Protagoniste charismatique',
          'value': 'protagoniste-charismatique',
        },
        {'label': 'Protagoniste masculin', 'value': 'protagoniste-masculin'},
        {'label': 'Démons', 'value': 'demons'},
        {'label': 'Reincarnation', 'value': 'reincarnation'},
        {'label': 'Académie', 'value': 'academie'},
        {
          'label': 'Cacher les vraies capacités',
          'value': 'cacher-les-vraies-capacites',
        },
        {
          'label': 'Protagoniste surpuissant',
          'value': 'protagoniste-surpuissant',
        },
        {'label': 'Joueur', 'value': 'joueur'},
        {
          'label': 'Protagoniste fort dès le départ',
          'value': 'protagoniste-fort-des-le-depart',
        },
        {'label': 'Immortels', 'value': 'immortels'},
        {'label': 'Cultivation rapide', 'value': 'cultivation-rapide'},
        {'label': 'Harem', 'value': 'harem'},
        {'label': 'Assasins', 'value': 'assasins'},
        {'label': 'De pauvre à riche', 'value': 'de-pauvre-a-riche'},
        {
          'label': 'Système de classement de jeux',
          'value': 'systeme-de-classement-de-jeux',
        },
        {'label': 'Capacités spéciales', 'value': 'capacites-speciales'},
        {'label': 'Vengeance', 'value': 'vengeance'},
      ],
    },
  };

  Future<String> _fetchApi(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept-Encoding': 'deflate'},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data from: $url');
    }
  }

  Future<List<Novel>> _parseNovels(String html, bool showLatestNovels) async {
    final novels = <Novel>[];
    final document = parse(html);

    if (showLatestNovels) {
      dom.Element? romansContent = document.querySelector('.romans-content');
      romansContent ??= document.querySelector('#content');

      if (romansContent != null) {
        final romans = romansContent.querySelectorAll('li');
        for (final elem in romans) {
          final novelName =
              elem
                  .querySelector(
                    '#content > ul > li > div.news-list-inform > div.news-list-tit > h5 > a',
                  )
                  ?.text
                  .trim() ??
              '';
          final novelCover =
              elem.querySelector('div img')?.attributes['src'] ?? '';
          final novelUrl = elem.querySelector('div a')?.attributes['href'];

          if (novelUrl != null) {
            final novel = Novel(
              id: novelUrl.replaceFirst(site, ''),
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
            novels.add(novel);
          }
        }
      }
    } else {
      final populaireParent =
          document.querySelectorAll(':contains("Populaire")').last.parent;
      final populaire = populaireParent?.nextElementSibling?.querySelectorAll(
        'li > div',
      );

      if (populaire != null && populaire.length == 12) {
        String? novelCover;
        String? novelName;
        String? novelUrl;

        for (int i = 0; i < populaire.length; i++) {
          final elem = populaire[i];
          if (i % 2 == 0) {
            novelCover = elem.querySelector('img')?.attributes['src'];
          } else {
            novelName = elem.text.trim();
            novelUrl = elem.querySelector('a')?.attributes['href'];

            if (novelUrl != null) {
              final novel = Novel(
                id: novelUrl.replaceFirst(site, ''),
                title: novelName,
                coverImageUrl:
                    novelCover ??
                    'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
                author: '',
                description: '',
                genres: [],
                chapters: [],
                artist: '',
                statusString: '',
                pluginId: id,
              );
              novels.add(novel);
            }
          }
        }
      } else if (populaire != null) {
        for (final element in populaire) {
          final novelName =
              element.querySelector('.popular-list-name')?.text.trim();
          final novelCover =
              element.querySelector('.popular-list-img img')?.attributes['src'];
          final novelUrl = element.querySelector('a')?.attributes['href'];

          if (novelUrl != null && novelName != null && novelCover != null) {
            final novel = Novel(
              id: novelUrl.replaceFirst(site, ''),
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
            novels.add(novel);
          }
        }
      }
    }
    return novels;
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
    BuildContext? context,
    bool showLatestNovels = true,
  }) async {
    String url = site;
    String tag = 'all';

    if (showLatestNovels) {
      url += '/category/translatedtales/page/$pageNo';
    } else {
      if (filters != null &&
          filters['tag'] != null &&
          filters['tag']['value'] is String &&
          filters['tag']['value'] != 'all') {
        tag = filters['tag']['value'];
      }
      if (tag != 'all') {
        url += '/tag/$tag/page/$pageNo';
      } else if (pageNo > 1) {
        return [];
      }
    }

    final html = await _fetchApi(url);
    List<Novel> novels = await _parseNovels(html, showLatestNovels);

    if (showLatestNovels) {
      final htmlOriginal = await _fetchApi(
        site + '/category/original/page/$pageNo',
      );
      novels.addAll(await _parseNovels(htmlOriginal, true));
    }

    return novels;
  }

  @override
  Future<Novel> parseNovel(String novelPath) async {
    final url = site + novelPath;
    final html = await _fetchApi(url);
    final document = parse(html);

    final novel = Novel(
      id: novelPath,
      title:
          document.querySelector('.inform-product-txt')?.text.trim() ??
          document.querySelector('.inform-title')?.text.trim() ??
          'Sans titre',
      coverImageUrl:
          document.querySelector('.inform-product img')?.attributes['src'] ??
          document
              .querySelector('.inform-product-img img')
              ?.attributes['src'] ??
          'https://placehold.co/400x450.png?text=Cover%20Scrap%20Failed',
      author: '',
      description:
          document.querySelector('.inform-inform-txt')?.text.trim() ??
          document.querySelector('.inform-intr-txt')?.text.trim() ??
          '',
      genres: [],
      chapters: [],
      artist: '',
      statusString: '',
      pluginId: id,
    );

    final infosElement =
        document.querySelector(
          'div.inform-product-txt > div.inform-intr-col',
        ) ??
        document.querySelector('div.inform-inform-data > h6');
    final infos = infosElement?.text.trim() ?? '';

    if (infos.contains('Auteur : ')) {
      novel.author =
          infos
              .substring(
                infos.indexOf('Auteur : ') + 9,
                infos.indexOf('Statut de Parution : '),
              )
              .trim();
    } else if (infos.contains('Fantrad : ')) {
      novel.author =
          infos
              .substring(
                infos.indexOf('Fantrad : ') + 10,
                infos.indexOf('Statut de Parution : '),
              )
              .trim();
    } else {
      novel.author = 'Inconnu';
    }

    final statusString =
        infos
            .substring(infos.indexOf('Statut de Parution : ') + 21)
            .toLowerCase();
    switch (statusString) {
      case 'en pause':
        novel.status = NovelStatus.Pausada;
        break;
      case 'complet':
        novel.status = NovelStatus.Completa;
        break;
      default:
        novel.status = NovelStatus.Andamento;
        break;
    }

    final chapters = <Chapter>[];
    List<dom.Element> chapterList =
        document.querySelectorAll('.chapitre-table a').toList();
    if (chapterList.isEmpty) {
      document.querySelector('div.inform-annexe-list')?.remove();
      chapterList = document.querySelectorAll('.inform-annexe-list a').toList();
    }

    for (final elem in chapterList) {
      final chapterName = elem.text.trim();
      final chapterUrl = elem.attributes['href'];

      if (chapterUrl != null) {
        String releaseDate = '';
        try {
          final dateString = chapterUrl.substring(
            chapterUrl.length - 11,
            chapterUrl.length - 1,
          );
          final parsedDate = DateFormat('yyyy-MM-dd').parse(dateString);
          releaseDate = DateFormat('dd MMMM yyyy').format(parsedDate);
        } catch (e) {
          print('Error parsing date: $e');
        }

        chapters.add(
          Chapter(
            id: chapterUrl.replaceFirst(site, ''),
            title: chapterName,
            content: '',
            order: chapters.length,
            chapterNumber: chapters.length + 1,
            releaseDate: releaseDate,
          ),
        );
      }
    }

    novel.chapters = chapters;

    return novel;
  }

  @override
  Future<String> parseChapter(String chapterUrl) async {
    final url = site + chapterUrl;
    final html = await _fetchApi(url);
    final document = parse(html);

    final chapterContentElement = document.querySelector('#content');
    String chapterText = chapterContentElement?.innerHtml ?? '';

    return chapterText;
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    if (pageNo != 1) return [];
    List<Novel> novels = [];

    bool finished = false;
    int i = 1;
    while (!finished) {
      List<Novel> res = await popularNovels(i, showLatestNovels: true);
      if (res.isEmpty) finished = true;
      novels.addAll(res);
      i++;
    }

    novels =
        novels
            .where(
              (novel) => novel.title
                  .toLowerCase()
                  .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
                  .contains(
                    searchTerm.toLowerCase().replaceAll(
                      RegExp(r'[\u0300-\u036f]'),
                      '',
                    ),
                  ),
            )
            .toList();

    return novels;
  }

  @override
  Future<List<Novel>> getAllNovels({
    BuildContext? context,
    int pageNo = 1,
  }) async {
    final url = site + '/category/translatedtales/page/$pageNo';
    final html = await _fetchApi(url);
    return _parseNovels(html, true);
  }
}

enum FilterTypes { textInput, excludableCheckboxGroup, picker }
