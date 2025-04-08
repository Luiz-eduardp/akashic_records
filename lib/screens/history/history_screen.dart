import 'dart:convert';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/history/history_card_widget.dart';
import 'package:akashic_records/i18n/i18n.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

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
    _loadHistoryData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadHistoryData() async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final loadedHistory = await _loadHistoryFromPreferences(prefs);
      final novels = _extractNovelTitles(loadedHistory);

      if (_mounted) {
        setState(() {
          _fullHistory = loadedHistory;
          _availableNovels = novels.toList();
          _filterHistory();
          _setLoading(false);
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");
      _showErrorSnackBar(context, "Falha ao carregar o histórico: $e");
      if (_mounted) {
        _setLoading(false);
      }
    }
  }

  void _setLoading(bool isLoading) {
    if (_mounted) {
      setState(() {
        _isLoading = isLoading;
      });
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<List<Map<String, dynamic>>> _loadHistoryFromPreferences(
    SharedPreferences prefs,
  ) async {
    List<Map<String, dynamic>> loadedHistory = [];

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

    return loadedHistory;
  }

  Set<String> _extractNovelTitles(List<Map<String, dynamic>> history) {
    Set<String> novels = {};
    for (var item in history) {
      novels.add(item['novelTitle']);
    }
    return novels;
  }

  void _filterHistory() {
    List<Map<String, dynamic>> filteredHistory = [];

    if (_selectedNovel == null || _selectedNovel == 'Todas as Novels') {
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
    await _loadHistoryData();
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
      body: _buildBody(),
      floatingActionButton: _buildFilterButton(),
    );
  }

  Widget _buildFilterButton() {
    return FloatingActionButton(
      onPressed: () {
        _showFilterDialog(context);
      },
      tooltip: 'Filtrar'.translate,
      child: const Icon(Icons.filter_list),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Novel'.translate),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                RadioListTile<String?>(
                  title: Text('Todas as Novels'.translate),
                  value: null,
                  groupValue: _selectedNovel,
                  onChanged: (String? value) {
                    _updateSelectedNovel(value);
                    Navigator.of(context).pop();
                  },
                ),
                ..._availableNovels.map((novel) {
                  return RadioListTile<String?>(
                    title: Text(novel),
                    value: novel,
                    groupValue: _selectedNovel,
                    onChanged: (String? value) {
                      _updateSelectedNovel(value);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
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
              'Seu histórico está vazio.'.translate,
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Comece a ler para ver seus livros aqui.'.translate,
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
            : 'Nenhuma'.translate;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estatísticas de Leitura'.translate,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text('Total de Capítulos Lidos: $totalChaptersRead'),
            Text('Novel Mais Lida: $mostReadNovel'),
          ],
        ),
      ),
    );
  }
}
