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
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onError),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
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
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        child: _buildBody(theme),
      ),
      floatingActionButton: _buildFilterButton(theme),
    );
  }

  Widget _buildFilterButton(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () {
        _showFilterDialog(context, theme);
      },
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      tooltip: 'Filtrar'.translate,
      child: const Icon(Icons.filter_list),
    );
  }

  void _showFilterDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Filtrar por Novel'.translate,
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                RadioListTile<String?>(
                  title: Text(
                    'Todas as Novels'.translate,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                  value: null,
                  groupValue: _selectedNovel,
                  onChanged: (String? value) {
                    _updateSelectedNovel(value);
                    Navigator.of(context).pop();
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                ..._availableNovels.map((novel) {
                  return RadioListTile<String?>(
                    title: Text(
                      novel,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    value: novel,
                    groupValue: _selectedNovel,
                    onChanged: (String? value) {
                      _updateSelectedNovel(value);
                      Navigator.of(context).pop();
                    },
                    activeColor: theme.colorScheme.primary,
                  );
                }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Fechar'.translate,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    if (_history.isEmpty) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 60,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seu histórico está vazio.'.translate,
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comece a ler para ver seus livros aqui.'.translate,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        _buildMetricsWidget(theme),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: _history.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: theme.dividerColor),
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
      ],
    );
  }

  Widget _buildMetricsWidget(ThemeData theme) {
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
      color: theme.colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.book_outlined,
                    '$totalChaptersRead',
                    'Capítulos Lidos'.translate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    Icons.favorite_border,
                    mostReadNovel,
                    'Novel Mais Lida'.translate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
