import 'package:akashic_records/models/chapter.dart';
import 'package:akashic_records/models/novel_status.dart';
class Novel {
  late String id;
  late String title;
  late String coverImageUrl;
  late String author;
  late String description;
  late List<Chapter> chapters;
  var genres;
  Novel({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.author,
    required this.description,
    required this.chapters,
    required String statusString,
    required String artist,
    required List genres,
    NovelStatus? status,
    String? summary,
  });
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverImageUrl': coverImageUrl,
      'author': author,
      'description': description,
      'chapters': chapters.map((chapter) => chapter.toMap()).toList(),
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
      statusString: '',
      artist: '',
      genres: [],
    );
  }
  set status(NovelStatus status) {}
}
