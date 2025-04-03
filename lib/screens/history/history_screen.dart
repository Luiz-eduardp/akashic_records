import 'dart:convert';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/history/history_card_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _fullHistory = [];
  List<String> _availableNovels = [];
  String? _selectedNovel;
  bool _isLoading = true;
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

  Future<void> _loadHistory() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> loadedHistory = [];
      Set<String> novels = {};

      final historyKeys =
          prefs.getKeys().where((key) => key.startsWith('history_')).toList();

      for (final historyKey in historyKeys) {
        final historyString = prefs.getString(historyKey) ?? '[]';
        try {
          List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));
          loadedHistory.addAll(
            history.map((item) => Map<String, dynamic>.from(item)),
          );
        } catch (e) {
          debugPrint(
            "Erro ao decodificar histórico para a chave $historyKey: $e",
          );
        }
      }

      loadedHistory.sort((a, b) {
        DateTime? dateA;
        DateTime? dateB;

        try {
          dateA = a['lastRead'] != null ? DateTime.parse(a['lastRead']) : null;
        } catch (e) {
          debugPrint(
            "Erro ao fazer o parse da data A: ${a['lastRead']}, erro: $e",
          );
        }

        try {
          dateB = b['lastRead'] != null ? DateTime.parse(b['lastRead']) : null;
        } catch (e) {
          debugPrint(
            "Erro ao fazer o parse da data B: ${b['lastRead']}, erro: $e",
          );
        }

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      for (var item in loadedHistory) {
        novels.add(item['novelTitle']);
      }

      if (_mounted) {
        setState(() {
          _fullHistory = loadedHistory;
          _availableNovels = novels.toList();
          _filterHistory();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterHistory() {
    List<Map<String, dynamic>> filteredHistory = [];

    if (_selectedNovel == null) {
      filteredHistory = List.from(_fullHistory);
    } else if (_selectedNovel == 'Todas as Novels') {
      filteredHistory = List.from(_fullHistory);
    } else {
      filteredHistory =
          _fullHistory
              .where((item) => item['novelTitle'] == _selectedNovel)
              .toList();
    }

    setState(() {
      _history = filteredHistory;
    });
  }

  void _handleHistoryTap(String novelId, String pluginId, String chapterId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(novelId: novelId, chapterId: chapterId),
      ),
    );
  }

  Future<void> _refreshHistory() async {
    await _loadHistory();
  }

  void _updateSelectedNovel(String? novel) {
    setState(() {
      _selectedNovel = novel;
    });
    _filterHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _updateSelectedNovel,
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Todas as Novels',
                  child: Text('Todas as Novels'),
                ),
                ..._availableNovels.map((novel) {
                  return PopupMenuItem<String>(
                    value: novel,
                    child: Text(novel),
                  );
                }),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Seu histórico está vazio.',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comece a ler para ver seus livros aqui.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildMetricsWidget(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshHistory,
            color: Theme.of(context).colorScheme.secondary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: _history.length,
              separatorBuilder:
                  (context, index) =>
                      const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                final item = _history[index];
                return HistoryCardWidget(
                  novelTitle: item['novelTitle'],
                  chapterTitle: item['chapterTitle'],
                  pluginId: item['pluginId'] ?? '',
                  lastRead: DateTime.parse(
                    item['lastRead'] ?? DateTime.now().toIso8601String(),
                  ),
                  onTap:
                      () => _handleHistoryTap(
                        item['novelId'],
                        item['pluginId'],
                        item['chapterId'],
                      ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsWidget() {
    int totalReadingTimeInMinutes = _history.length * 10;
    int totalChaptersRead = _history.length;

    Map<String, int> novelChapterCounts = {};
    for (var item in _history) {
      novelChapterCounts.update(
        item['novelTitle'],
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    String mostReadNovel =
        novelChapterCounts.entries.isNotEmpty
            ? novelChapterCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : 'Nenhuma';

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas de Leitura',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text('Tempo Total de Leitura: $totalReadingTimeInMinutes minutos'),
            Text('Total de Capítulos Lidos: $totalChaptersRead'),
            Text('Novel Mais Lida: $mostReadNovel'),
          ],
        ),
      ),
    );
  }
}
