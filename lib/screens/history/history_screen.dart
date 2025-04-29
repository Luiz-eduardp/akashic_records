import 'dart:convert';

import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/history/history_card_widget.dart';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (!_mounted) return;

    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final loadedHistory = await _loadHistoryFromPreferences(prefs);
      final novels = _extractNovelTitles(loadedHistory);

      if (_mounted) {
        setState(() {
          _fullHistory = loadedHistory;
          _availableNovels = novels.toList();
          _availableNovels.insert(0, 'Todas as Novels'.translate);
          _filterHistory();
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar histórico: $e");
      _showErrorSnackBar("Falha ao carregar o histórico: $e");
    } finally {
      if (_mounted) {
        _setLoading(false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadHistoryFromPreferences(
    SharedPreferences prefs,
  ) async {
    final loadedHistory = <Map<String, dynamic>>[];
    final historyKeys =
        prefs.getKeys().where((key) => key.startsWith('history_')).toList();

    for (final historyKey in historyKeys) {
      try {
        final historyString = prefs.getString(historyKey) ?? '[]';
        final history = jsonDecode(historyString) as List<dynamic>;
        loadedHistory.addAll(history.whereType<Map<String, dynamic>>());
      } catch (e) {
        debugPrint(
          "Erro ao decodificar histórico para a chave $historyKey: $e",
        );
      }
    }

    loadedHistory.sort((a, b) {
      final dateA = _parseDate(a['lastRead']);
      final dateB = _parseDate(b['lastRead']);

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return loadedHistory;
  }

  DateTime? _parseDate(dynamic dateString) {
    try {
      if (dateString != null) {
        return DateTime.tryParse(dateString.toString());
      }
    } catch (e) {
      debugPrint("Erro ao fazer o parse da data: $dateString, erro: $e");
      return null;
    }
    return null;
  }

  void _setLoading(bool isLoading) {
    if (_mounted) {
      setState(() {
        _isLoading = isLoading;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
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
  }

  Set<String> _extractNovelTitles(List<Map<String, dynamic>> history) {
    return history.map((item) => item['novelTitle'] as String).toSet();
  }

  void _filterHistory() {
    if (!_mounted) return;

    List<Map<String, dynamic>> filteredHistory =
        _fullHistory.where((item) {
          return _selectedNovel == null ||
              _selectedNovel == 'Todas as Novels'.translate ||
              item['novelTitle'] == _selectedNovel;
        }).toList();

    setState(() {
      _history = filteredHistory;
    });
  }

  void _handleHistoryTap(String novelId, String pluginId, String chapterId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ReaderScreen(
              novelId: novelId,
              chapterId: chapterId,
              pluginId: pluginId,
            ),
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
      onPressed: () => _showFilterDialog(context, theme),
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
              children:
                  _availableNovels.map((novel) {
                    return RadioListTile<String?>(
                      title: Text(
                        novel,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                      value:
                          novel == 'Todas as Novels'.translate ? null : novel,
                      groupValue: _selectedNovel,
                      onChanged: (String? value) {
                        _updateSelectedNovel(value);
                        Navigator.of(context).pop();
                      },
                      activeColor: theme.colorScheme.primary,
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Fechar'.translate,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
      return _buildEmptyHistoryView(theme);
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
                key: ValueKey('${item['novelId']}-${item['chapterId']}'),
                novelTitle: item['novelTitle'],
                chapterTitle: item['chapterTitle'],
                pluginId: item['pluginId'] as String,
                lastRead: _parseDate(item['lastRead']) ?? DateTime.now(),
                onTap:
                    () => _handleHistoryTap(
                      item['novelId'] as String,
                      item['pluginId'] as String,
                      item['chapterId'] as String,
                    ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHistoryView(ThemeData theme) {
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

  Widget _buildMetricsWidget(ThemeData theme) {
    final totalChaptersRead = _history.length;

    final novelChapterCounts = <String, int>{};
    for (final item in _history) {
      final novelTitle = item['novelTitle'] as String;
      novelChapterCounts.update(
        novelTitle,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final mostReadNovel =
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
