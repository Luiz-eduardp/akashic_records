import 'dart:async';
import 'dart:convert';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/models/novel.dart';
import 'package:akashic_records/services/plugins/ptbr/novelmania_service.dart';
import 'package:akashic_records/services/plugins/ptbr/tsundoku_service.dart';
import 'package:akashic_records/services/plugins/ptbr/centralnovel_service.dart';
import 'package:akashic_records/helpers/novel_loading_helper.dart';
import 'package:async/async.dart';
import 'package:akashic_records/screens/history/history_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  final NovelMania novelMania = NovelMania();
  final Tsundoku tsundoku = Tsundoku();
  final CentralNovel centralNovel = CentralNovel();
  bool _mounted = false;

  @override
  void initState() {
    super.initState();
    _mounted = true;
    _loadHistory();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadHistory({bool forceRefresh = false}) async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> loadedHistory = [];

      if (!forceRefresh) {
        final cachedHistoryJson = prefs.getString('history_cache');
        if (cachedHistoryJson != null) {
          final List<dynamic> cachedHistoryList = jsonDecode(cachedHistoryJson);
          loadedHistory =
              cachedHistoryList
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
          if (_mounted) {
            setState(() {
              _history = loadedHistory;
              _isLoading = false;
            });
          }
          print("Histórico carregado do cache.");
          return;
        }
      }

      final historyKeys =
          prefs.getKeys().where((key) => key.startsWith('lastRead_')).toList();
      historyKeys.sort(
        (a, b) => _extractTimestamp(b).compareTo(_extractTimestamp(a)),
      );

      final group = AsyncMemoizer<void>();

      for (final key in historyKeys) {
        group.runOnce(() => _loadHistoryItem(key, prefs, loadedHistory));
      }

      await group.future;

      prefs.setString('history_cache', jsonEncode(loadedHistory));
      print("Histórico salvo no cache.");

      if (_mounted) {
        setState(() {
          _history = loadedHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar histórico: $e");
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _extractTimestamp(String key) {
    try {
      final timestampString = key.split('_').last;
      return int.parse(timestampString);
    } catch (e) {
      print("Erro ao extrair timestamp de $key: $e");
      return 0;
    }
  }

  Future<void> _loadHistoryItem(
    String key,
    SharedPreferences prefs,
    List<Map<String, dynamic>> loadedHistory,
  ) async {
    final novelIdWithTimestamp = key.substring('lastRead_'.length);
    final lastUnderscoreIndex = novelIdWithTimestamp.lastIndexOf('_');

    if (lastUnderscoreIndex == -1) {
      print("Chave de histórico inválida: $key");
      return;
    }

    final novelId = novelIdWithTimestamp.substring(0, lastUnderscoreIndex);
    final chapterId = prefs.getString(key);

    if (chapterId == null || chapterId.isEmpty) return;

    Novel? novel;
    String pluginId = '';
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedPlugins.contains('NovelMania') &&
        novelId.startsWith('/novels/')) {
      novel = await loadNovelWithTimeout(() => novelMania.parseNovel(novelId));
      if (novel != null) pluginId = 'NovelMania';
    }
    if (appState.selectedPlugins.contains('Tsundoku') &&
        novelId.startsWith('/manga/')) {
      novel = await loadNovelWithTimeout(() => tsundoku.parseNovel(novelId));
      if (novel != null) pluginId = 'Tsundoku';
    }
    if (appState.selectedPlugins.contains('CentralNovel') &&
        novelId.startsWith('/series/')) {
      novel = await loadNovelWithTimeout(
        () => centralNovel.parseNovel(novelId),
      );
      if (novel != null) pluginId = 'CentralNovel';
    }

    if (novel == null) return;
    String? chapterTitle;
    try {
      chapterTitle =
          novel.chapters.firstWhere((chap) => chap.id == chapterId).title;
    } catch (e) {
      print(
        "Capítulo não encontrado para novel ID $novelId e chapter ID $chapterId: $e",
      );
      chapterTitle = "Capítulo Desconhecido";
    }

    final lastReadTime = _extractTimestamp(key);
    final readDate = DateTime.fromMillisecondsSinceEpoch(lastReadTime);

    final item = {
      'novelId': novelId,
      'novelTitle': novel.title,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'lastRead': readDate.toIso8601String(),
      'pluginId': pluginId,
    };
    loadedHistory.add(item);
  }

  void _handleHistoryTap(String novelId, String chapterId, String pluginId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(
              novelId: novelId,
              pluginId: pluginId,
              selectedPlugins:
                  Provider.of<AppState>(context, listen: false).selectedPlugins,
            ),
      ),
    );
  }

  Future<void> _refreshHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('history_cache');
    await _loadHistory(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
              ? const Center(child: Text('Seu histórico está vazio.'))
              : RefreshIndicator(
                onRefresh: _refreshHistory,
                child: ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return HistoryCardWidget(
                      novelTitle: item['novelTitle'],
                      chapterTitle: item['chapterTitle'],
                      pluginId: item['pluginId'] ?? '',
                      lastRead: DateTime.parse(item['lastRead']),
                      onTap:
                          () => _handleHistoryTap(
                            item['novelId'],
                            item['chapterId'],
                            item['pluginId'],
                          ),
                    );
                  },
                ),
              ),
    );
  }
}
