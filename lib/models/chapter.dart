// lib/models/chapter.dart
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
      order: 0,
    );
  }

  get order => null;
}
