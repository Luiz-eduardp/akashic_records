enum NovelStatus { Andamento, Completa, Pausada, Desconhecido }

class Novel {
  late String id;
  late String title;
  late String coverImageUrl;
  late String author;
  late String description;
  late List<Chapter> chapters;
  var genres;
  late String pluginId;
  late bool shouldShowNumberOfChapters;
  late NovelStatus status;

  Novel({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.author,
    required this.description,
    required this.chapters,
    required this.pluginId,
    required this.genres,
    this.shouldShowNumberOfChapters = true,
    this.status = NovelStatus.Desconhecido,
    String? artist,
    String? statusString,
  });

  int get numberOfChapters => shouldShowNumberOfChapters ? chapters.length : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'author': author,
      'description': description,
      'chapters': chapters.map((chapter) => chapter.toMap()).toList(),
      'pluginId': pluginId,
      'shouldShowNumberOfChapters': shouldShowNumberOfChapters,
      'status': status.index,
      'genres': genres,
    };
  }

  factory Novel.fromMap(Map<String, dynamic> map) {
    return Novel(
      id: map['id'] as String,
      title: map['title'] as String,
      coverImageUrl: map['coverImageUrl'] as String,
      author: map['author'] as String,
      description: map['description'] as String,
      chapters:
          (map['chapters'] as List<dynamic>)
              .map(
                (chapterMap) =>
                    Chapter.fromMap(chapterMap as Map<String, dynamic>),
              )
              .toList(),
      pluginId: map['pluginId'] as String,
      genres: map['genres'] as List<dynamic>,
      shouldShowNumberOfChapters:
          map['shouldShowNumberOfChapters'] as bool? ?? true,
      status: NovelStatus.values[map['status'] as int? ?? 3],
    );
  }
}

class Chapter {
  late String id;
  late String title;
  late String? content;
  late String? releaseDate;
  late int? chapterNumber;

  Chapter({
    required this.id,
    required this.title,
    this.content,
    this.releaseDate,
    this.chapterNumber,
    int? order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'releaseDate': releaseDate,
      'chapterNumber': chapterNumber,
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      releaseDate: map['releaseDate'] as String?,
      chapterNumber: map['chapterNumber'] as int?,
    );
  }
}
