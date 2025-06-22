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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        backgroundColor: colorScheme.surfaceContainer,
        color: colorScheme.primary,
        child: _buildBody(theme, colorScheme),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterDialog(context, theme, colorScheme),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'Filtrar'.translate,
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainer,
          surfaceTintColor: colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Filtrar por Novel'.translate,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  _availableNovels.map((novel) {
                    return RadioListTile<String?>(
                      title: Text(
                        novel,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      value:
                          novel == 'Todas as Novels'.translate ? null : novel,
                      groupValue: _selectedNovel,
                      onChanged: (String? value) {
                        _updateSelectedNovel(value);
                        Navigator.of(context).pop();
                      },
                      activeColor: colorScheme.primary,
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
              ),
              child: Text('Fechar'.translate),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          backgroundColor: colorScheme.surfaceVariant,
        ),
      );
    }

    if (_history.isEmpty) {
      return _buildEmptyHistoryView(theme, colorScheme);
    }

    return Column(
      children: [
        _buildMetricsWidget(theme, colorScheme),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _history.length,
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

  Widget _buildEmptyHistoryView(ThemeData theme, ColorScheme colorScheme) {
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seu histórico está vazio.'.translate,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comece a ler para ver seus livros aqui.'.translate,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  String _getMostReadNovel() {
    if (_history.isEmpty) return 'Nenhuma'.translate;

    final novelCounts = <String, int>{};
    for (var item in _history) {
      final novelTitle = item['novelTitle'] as String;
      novelCounts[novelTitle] = (novelCounts[novelTitle] ?? 0) + 1;
    }

    return novelCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Widget _buildMetricsWidget(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: colorScheme.surfaceContainerHigh,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ExpansionTile(
          title: Text(
            'Estatísticas'.translate,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16.0),
          backgroundColor: Colors.transparent,
          children: <Widget>[
            _buildStatItem(
              theme,
              colorScheme,
              Icons.book_outlined,
              _history.length.toString(),
              'Capítulos Lidos'.translate,
            ),
            _buildStatItem(
              theme,
              colorScheme,
              Icons.favorite_border,
              _getMostReadNovel(),
              'Novel Mais Lida'.translate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String value,
    String label,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.start,
                ),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.start,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
