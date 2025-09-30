import 'package:akashic_records/models/plugin_service.dart';

class PluginRegistry {
  static final Map<String, PluginService> _registry = {};

  static void register(PluginService service) {
    _registry[service.name] = service;
  }

  static PluginService? get(String name) => _registry[name];

  static List<String> get registeredPluginNames => _registry.keys.toList();

  static List<PluginService> get allPlugins => _registry.values.toList();
}
