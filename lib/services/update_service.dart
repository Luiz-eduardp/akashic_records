import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

class UpdateService {
  final String owner;
  final String repo;

  UpdateService({required this.owner, required this.repo});

  Future<Map<String, dynamic>?> fetchLatestRelease() async {
    final url = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases/latest',
    );
    final resp = await http
        .get(
          url,
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'akashic_records_update_checker',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) return null;
    final data = json.decode(resp.body) as Map<String, dynamic>;
    return data;
  }

  Future<String> downloadAsset(
    String assetUrl,
    String targetFile,
    void Function(double)? onProgress,
  ) async {
    final dio = Dio();
    final file = File(targetFile);
    try {
      await dio.download(
        assetUrl,
        file.path,
        onReceiveProgress: (rcv, total) {
          if (total > 0 && onProgress != null) onProgress(rcv / total);
        },
      );
      return file.path;
    } catch (e) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }
}
