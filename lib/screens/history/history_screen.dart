import 'dart:convert';
import 'package:akashic_records/screens/reader/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:akashic_records/screens/history/history_card_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
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

      if (_mounted) {
        setState(() {
          _history = loadedHistory;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
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

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: Theme.of(context).colorScheme.secondary,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _history.length,
        separatorBuilder:
            (context, index) => const Divider(height: 1, color: Colors.grey),
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
    );
  }
}
