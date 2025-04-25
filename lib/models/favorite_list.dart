class FavoriteList {
  String id;
  String name;
  List<String> novelIds;

  FavoriteList({required this.id, required this.name, List<String>? novelIds})
    : novelIds = novelIds ?? [];

  static String novelToCompositeKey(String pluginId, String novelId) {
    return '${pluginId}_$novelId';
  }

  static Map<String, String>? compositeKeyToNovel(String key) {
    final parts = key.split('_');
    if (parts.length >= 2) {
      final pluginId = parts[0];
      final novelId = parts.sublist(1).join('_');
      return {'pluginId': pluginId, 'novelId': novelId};
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'novelIds': novelIds,
  };

  factory FavoriteList.fromJson(Map<String, dynamic> json) => FavoriteList(
    id: json['id'] as String,
    name: json['name'] as String,
    novelIds: List<String>.from(json['novelIds'] as List? ?? []),
  );
}
