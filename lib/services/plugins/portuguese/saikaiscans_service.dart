import 'dart:async';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/models/plugin_service.dart';
import 'dart:convert';
import 'package:html/parser.dart' show parse;

class SaikaiScans implements PluginService {
  @override
  String get name => 'SaikaiScans';

  String get id => 'SaikaiScans';

  String get version => '1.0.4';

  @override
  Map<String, dynamic> get filters => {
    'genres': {
      'value': '',
      'label': 'Gêneros',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ação', 'value': '1'},
        {'label': 'Aventura', 'value': '2'},
        {'label': 'Fantasia', 'value': '3'},
        {'label': 'Horror', 'value': '27'},
        {'label': 'Militar', 'value': '76'},
        {'label': 'Mistério', 'value': '57'},
        {'label': 'Terror', 'value': '82'},
      ],
    },
    'status': {
      'value': '',
      'label': 'Status',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Ativo', 'value': '1'},
        {'label': 'Completo', 'value': '2'},
        {'label': 'Pausado', 'value': '3'},
        {'label': 'Dropado', 'value': '4'},
        {'label': 'Em Breve', 'value': '5'},
        {'label': 'Hiato', 'value': '6'},
      ],
    },
    'country': {
      'value': '',
      'label': 'País',
      'options': [
        {'label': 'Todos', 'value': ''},
        {'label': 'Brasil', 'value': '32'},
        {'label': 'Coreia', 'value': '115'},
      ],
    },
    'ordem': {
      'label': 'Ordenar Por',
      'value': 'title',
      'options': [
        {'label': 'Título', 'value': 'title'},
        {'label': 'Views', 'value': 'views'},
        {'label': 'Lançamento', 'value': 'release'},
      ],
    },
    'direction': {
      'label': 'Direção',
      'value': 'asc',
      'options': [
        {'label': 'Ascendente', 'value': 'asc'},
        {'label': 'Descendente', 'value': 'desc'},
      ],
    },
  };

  final String baseURL = 'https://saikaiscans.net';
  final String catalogURL = 'https://saikaiscans.net/series';
  final String apiUrl = 'https://api.saikaiscans.net/api/stories';
  static const String defaultCover =
      'https://placehold.co/400x450.png?text=Sem%20Capa';

  Future<dynamic> _fetchApi(String url) async {
    print('Fetching API: $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Referer': baseURL,
        },
      );

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('json')) {
          try {
            return jsonDecode(response.body);
          } catch (e) {
            print(
              'Erro ao decodificar JSON (possivelmente HTML foi retornado): $e',
            );
            print('Response body: ${response.body}');
            return response.body;
          }
        } else {
          print(
            'Content-Type is not JSON, assuming HTML. Content-Type: $contentType',
          );
          return response.body;
        }
      } else {
        print(
          'Falha ao carregar dados de: $url - Status code: ${response.statusCode}',
        );
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erro ao fazer a requisição: $e');
      return null;
    }
  }

  Future<String?> getBookCoverImageUrl(String bookUrl) async {
    try {
      final body = await _fetchApi(bookUrl);
      if (body is String) {
        final document = parse(body);
        final element = document.querySelector(".story-header img[src]");
        return element?.attributes['src'];
      }
      return null;
    } catch (e) {
      print('Erro ao obter a URL da capa do livro: $e');
      return null;
    }
  }

  Future<String?> getBookDescription(String bookUrl) async {
    try {
      final body = await _fetchApi(bookUrl);
      if (body is String) {
        final document = parse(body);
        final element = document.querySelector("#synopsis-content");
        return element?.text.trim();
      }
      return null;
    } catch (e) {
      print('Erro ao obter a descrição do livro: $e');
      return null;
    }
  }

  Future<List<Chapter>> getChapterList(String bookUrl) async {
    print('getChapterList: Iniciando para URL: $bookUrl');

    try {
      final url =
          Uri.parse(
            bookUrl,
          ).replace(queryParameters: {'tab': 'capitulos'}).toString();
      print('getChapterList: URL de capítulos: $url');

      final body = await _fetchApi(url);
      if (body is String) {
        print('getChapterList: Corpo da resposta obtido (HTML)');
        final chaptersDoc = parse(body);

        List<Chapter> chapterList = [];
        final chapterElements = chaptersDoc.querySelectorAll(
          "ul.__chapters li",
        );

        if (chapterElements.isNotEmpty) {
          print(
            'getChapterList: Encontrados ${chapterElements.length} capítulos na lista HTML.',
          );

          for (var chapterElement in chapterElements) {
            final chapterLinkElement = chapterElement.querySelector("a");
            final chapterTitleElement = chapterElement.querySelector(
              ".__chapters--title",
            );

            if (chapterLinkElement != null && chapterTitleElement != null) {
              final fullChapterUrl = chapterLinkElement.attributes['href'];
              final chapterTitle = chapterTitleElement.text.trim();

              if (fullChapterUrl != null) {
                RegExp regex = RegExp(r"^/ler/series/(.+)/(\d+)/(.+)$");
                final match = regex.firstMatch(fullChapterUrl);

                if (match != null && match.groupCount >= 3) {
                  final bookpath = match.group(1)!;
                  final dispUrl = int.parse(match.group(2)!);
                  final chapterUrlSlug = match.group(3)!;

                  final chapter = Chapter(
                    url:
                        "https://saikaiscans.net/ler/series/$bookpath/$dispUrl/$chapterUrlSlug",
                    title: chapterTitle,
                    content: '',
                    order: chapterList.length,
                    id:
                        "https://saikaiscans.net/ler/series/$bookpath/$dispUrl/$chapterUrlSlug",
                  );
                  print(
                    'getChapterList: Capítulo HTML extraído: ${chapter.title}, URL: ${chapter.url}',
                  );
                  chapterList.add(chapter);
                } else {
                  print('getChapterList: Falha ao analisar URL do capítulo.');
                }
              } else {
                print('getChapterList: URL do capítulo é nula.');
              }
            } else {
              print(
                'getChapterList: Informações incompletas do capítulo na HTML.',
              );
            }
          }
        } else {
          print('getChapterList: Nenhum capítulo encontrado na lista HTML.');
        }

        if (chapterList.isEmpty) {
          print(
            'getChapterList: Nenhum capítulo encontrado na lista HTML, tentando extrair do JSON.',
          );
          List<Chapter> preList = [];
          final scriptElements = chaptersDoc.querySelectorAll("script");
          Element? scriptElement = scriptElements.firstWhere(
            (s) => s.text.startsWith("window.__NUXT__"),
            orElse: () => Element.tag('script'),
          );

          if (scriptElement != null) {
            print('getChapterList: Script window.__NUXT__ encontrado.');
            final scriptData = scriptElement.text;
            print('getChapterList: Script data bruto: $scriptData');

            final startIndex = scriptData.indexOf('{');
            String jsonString = '';
            if (startIndex != -1) {
              jsonString = scriptData.substring(startIndex);
              jsonString = jsonString.trim();
              if (jsonString.startsWith('{return ')) {
                jsonString = jsonString.substring(7).trim();
              }
              if (jsonString.startsWith('{')) {
              } else {
                final firstCurly = jsonString.indexOf('{');
                if (firstCurly != -1) {
                  jsonString = jsonString.substring(firstCurly);
                }
              }
            } else {
              print(
                'getChapterList: ERRO: Não foi encontrado "{" no scriptData!',
              );
              return [];
            }

            print(
              'getChapterList: String JSON extraída (SIMPLIFICADA): $jsonString',
            );

            try {
              final jsonData = jsonDecode(jsonString);
              print('getChapterList: JSON decodificado com SUCESSO!');
              final data = jsonData["data"] as List<dynamic>?;
              if (data != null && data.isNotEmpty) {
                final separators =
                    data[0]?["story"]?["data"]?["separators"] as List<dynamic>?;
                if (separators != null) {
                  print(
                    'getChapterList: Seções de capítulos (separators) encontradas no JSON.',
                  );
                  preList =
                      separators.expand<Chapter>((volume) {
                        final releases = volume["releases"] as List<dynamic>?;
                        print(
                          'getChapterList: Releases em um volume: ${releases?.length ?? 0}',
                        );
                        return releases
                                ?.map((release) {
                                  final chapterNumber =
                                      release["chapter"] as num?;
                                  final chapterSlug =
                                      release["slug"] as String?;
                                  final releaseTitle =
                                      release["title"] as String?;

                                  if (chapterNumber != null &&
                                      chapterSlug != null &&
                                      releaseTitle != null) {
                                    final chapter = Chapter(
                                      url: chapterSlug,
                                      title: releaseTitle,
                                      content: '',
                                      order: chapterNumber.toInt(),
                                      id: chapterSlug,
                                    );
                                    print(
                                      'getChapterList: Capítulo JSON extraído: ${chapter.title}, Slug: ${chapter.url}, Order: ${chapter.order}',
                                    );
                                    return chapter;
                                  }
                                  print(
                                    'getChapterList: Dados incompletos de capítulo JSON, pulando.',
                                  );
                                  return null;
                                })
                                .whereType<Chapter>()
                                .toList() ??
                            [];
                      }).toList();
                } else {
                  print(
                    'getChapterList: Nenhuma seção de capítulos (separators) encontrada no JSON.',
                  );
                }
              } else {
                print(
                  'getChapterList: data array vazio ou não encontrado no JSON.',
                );
              }
            } catch (e) {
              print('getChapterList: ERRO ao analisar JSON do script: $e');
              print('getChapterList: JSON String com ERRO: $jsonString');
            }
          } else {
            print(
              'getChapterList: Script element window.__NUXT__ NÃO encontrado.',
            );
          }
          return preList;
        }

        print(
          'getChapterList: Lista total de capítulos: ${chapterList.length}',
        );
        return chapterList;
      } else {
        print(
          'getChapterList: Corpo da resposta NÃO é String (erro na requisição).',
        );
        return [];
      }
    } catch (e) {
      print('getChapterList: Erro geral ao obter lista de capítulos: $e');
      return [];
    }
  }

  @override
  Future<List<Novel>> popularNovels(
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    return _getPageBooks(index: pageNo - 1, filters: filters);
  }

  @override
  Future<List<Novel>> searchNovels(
    String searchTerm,
    int pageNo, {
    Map<String, dynamic>? filters,
  }) async {
    if (searchTerm.isEmpty) {
      return [];
    }
    return _getPageBooks(
      index: pageNo - 1,
      input: searchTerm,
      filters: filters,
    );
  }

  Future<List<Novel>> _getPageBooks({
    int index = 0,
    String input = "",
    Map<String, dynamic>? filters,
  }) async {
    try {
      final page = index + 1;
      final url =
          Uri.parse(apiUrl)
              .replace(
                queryParameters: {
                  "format": "1",
                  "q": input,
                  "status": filters?['status']?['value'] ?? 'null',
                  "genres": filters?['genres']?['value'] ?? '',
                  "country": filters?['country']?['value'] ?? 'null',
                  "sortProperty": filters?['ordem']?['value'] ?? 'title',
                  "sortDirection": filters?['direction']?['value'] ?? 'asc',
                  "page": "$page",
                  "per_page": "12",
                  "relationships": "language,type,format",
                },
              )
              .toString();

      final body = await _fetchApi(url);
      if (body is Map<String, dynamic>) {
        final data = body["data"] as List<dynamic>?;
        if (data != null) {
          return data.map((item) {
            return Novel(
              id: item["slug"],
              title: item["title"],
              coverImageUrl:
                  "https://s3-alpha.saikaiscans.net/${item["image"]}",
              pluginId: name,
              author:
                  item['authors'].isNotEmpty
                      ? item['authors'][0]['name']
                      : 'Desconhecido',
              description: item['resume'],
              genres:
                  (item['genres'] as List<dynamic>)
                      .map((genre) => genre['name'].toString())
                      .toList(),
              chapters: [],
              artist: '',
              statusString: '',
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao obter a lista de livros paginada: $e');
      return [];
    }
  }

  @override
  Future<Novel> parseNovel(String novelSlug) async {
    final novelUrl = '$baseURL/series/$novelSlug';
    print('parseNovel: Fetching novel details from $novelUrl');
    try {
      final body = await _fetchApi(novelUrl);

      if (body is String) {
        final document = parse(body);

        final coverImageUrl =
            document
                .querySelector(".story-header img[src]")
                ?.attributes['src'] ??
            defaultCover;
        final description =
            document.querySelector("#synopsis-content")?.text.trim() ??
            'Sem descrição disponível.';
        final title =
            document.querySelector(".story-header h1")?.text.trim() ??
            'Título não encontrado';

        String author = 'Desconhecido';
        final authorElement = document.querySelector(".header--author > span");
        if (authorElement != null) {
          author = authorElement.text.trim();
        }

        List<String> genres = [];
        final genreElements = document.querySelectorAll(
          ".header--categories > a",
        );
        for (var genreElement in genreElements) {
          genres.add(genreElement.text.trim());
        }

        String statusString = 'Desconhecido';
        final statusElement = document.querySelector(".header--status > span");
        if (statusElement != null) {
          statusString = statusElement.text.trim();
        }

        final novel = Novel(
          id: novelSlug,
          title: title,
          coverImageUrl: coverImageUrl,
          author: author,
          description: description,
          genres: genres,
          chapters: [],
          artist: '',
          statusString: statusString,
          pluginId: name,
        );

        novel.chapters = await getChapterList(novelUrl);
        return novel;
      } else {
        print(
          'parseNovel: Body is not String, failed to parse novel details for $novelSlug',
        );
        return Novel(
          id: novelSlug,
          title: 'Erro ao carregar',
          coverImageUrl: defaultCover,
          description: 'Não foi possível carregar os dados do novel.',
          genres: [],
          chapters: [],
          artist: '',
          statusString: '',
          pluginId: name,
          author: 'Desconhecido',
        );
      }
    } catch (e) {
      print('Error in parseNovel for $novelSlug: $e');
      return Novel(
        id: novelSlug,
        title: 'Erro ao carregar',
        coverImageUrl: defaultCover,
        description: 'Erro ao carregar os dados do novel.',
        genres: [],
        chapters: [],
        artist: '',
        statusString: '',
        pluginId: name,
        author: 'Desconhecido',
      );
    }
  }

  @override
  Future<String> parseChapter(String chapterPath) async {
    print('parseChapter: Fetching chapter content from $chapterPath');
    try {
      final body = await _fetchApi(chapterPath);
      if (body is String) {
        final document = parse(body);
        final chapterContentElement = document.querySelector('.content-page');

        if (chapterContentElement != null) {
          chapterContentElement.querySelectorAll('p').forEach((element) {
            if (element.text.trim().isEmpty) {
              element.remove();
            }
          });
          chapterContentElement.querySelectorAll('img').forEach((img) {
            img.attributes['style'] = 'max-width: 100%; height: auto;';
          });

          final chapterTitleElement = document.querySelector('h1.entry-title');
          final chapterTitle = chapterTitleElement?.text.trim() ?? '';

          final chapterTextContent = chapterContentElement.innerHtml;

          return '<h1>$chapterTitle</h1>$chapterTextContent';
        } else {
          print(
            'parseChapter: Chapter content element not found for path: $chapterPath',
          );
          return 'Conteúdo não encontrado';
        }
      } else {
        print(
          'parseChapter: Body is not String, failed to parse chapter content for $chapterPath',
        );
        return 'Conteúdo não encontrado';
      }
    } catch (e) {
      print('Error in parseChapter for $chapterPath: $e');
      return 'Conteúdo não encontrado';
    }
  }
}
