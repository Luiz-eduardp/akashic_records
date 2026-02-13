class CrossPluginItem {
  final String id;
  final String name;
  final String site;
  final String lang;
  final String version;
  final String url;
  final String iconUrl;
  final String? customCSS;

  CrossPluginItem({
    required this.id,
    required this.name,
    required this.site,
    required this.lang,
    required this.version,
    required this.url,
    required this.iconUrl,
    this.customCSS,
  });

  factory CrossPluginItem.fromJson(Map<String, dynamic> json) {
    return CrossPluginItem(
      id: json['id'] as String,
      name: json['name'] as String,
      site: json['site'] as String,
      lang: json['lang'] as String,
      version: json['version'] as String,
      url: json['url'] as String,
      iconUrl: json['iconUrl'] as String,
      customCSS: json['customCSS'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'site': site,
        'lang': lang,
        'version': version,
        'url': url,
        'iconUrl': iconUrl,
        'customCSS': customCSS,
      };
}

class CrossPluginListResponse {
  final List<CrossPluginItem> plugins;

  CrossPluginListResponse({required this.plugins});

  factory CrossPluginListResponse.fromJson(Map<String, dynamic> json) {
    final list = json as List<dynamic>;
    return CrossPluginListResponse(
      plugins: list.map((e) => CrossPluginItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'plugins': plugins.map((e) => e.toJson()).toList(),
      };
}

class CrossPluginConfig {
  final String id;
  final String name;
  final String site;
  final String lang;
  final String version;
  final String iconUrl;
  final String? customCSS;
  final String pluginCode;
  final String listUrl;

  CrossPluginConfig({
    required this.id,
    required this.name,
    required this.site,
    required this.lang,
    required this.version,
    required this.iconUrl,
    required this.pluginCode,
    required this.listUrl,
    this.customCSS,
  });
}
