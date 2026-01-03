import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final dir = Directory('lib/assets/i18n/locale');
  if (!await dir.exists()) {
    print('i18n locale directory not found: ${dir.path}');
    return;
  }

  final enFile = File('${dir.path}/en.json');
  if (!await enFile.exists()) {
    print('en.json not found in ${dir.path}');
    return;
  }

  final enMap =
      json.decode(await enFile.readAsString()) as Map<String, dynamic>;
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where(
            (f) => f.path.endsWith('.json') && !f.path.endsWith('/en.json'),
          )
          .toList();

  for (final f in files) {
    try {
      final content = await f.readAsString();
      final map = json.decode(content) as Map<String, dynamic>;
      var changed = false;
      for (final key in enMap.keys) {
        if (!map.containsKey(key)) {
          map[key] = enMap[key];
          changed = true;
        }
      }
      if (changed) {
        final sortedKeys = map.keys.toList()..sort();
        final sortedMap = <String, dynamic>{};
        for (final k in sortedKeys) sortedMap[k] = map[k];
        final encoder = JsonEncoder.withIndent('  ');
        await f.writeAsString(encoder.convert(sortedMap) + '\n');
        print('Updated ${f.path} (added missing keys)');
      } else {
        print('No changes for ${f.path}');
      }
    } catch (e) {
      print('Failed to process ${f.path}: $e');
    }
  }
  print('i18n sync complete.');
}
