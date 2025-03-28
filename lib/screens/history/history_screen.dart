import 'dart:async';
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
        List<dynamic> history = List<dynamic>.from(jsonDecode(historyString));

        loadedHistory.addAll(
          history.map((item) => Map<String, dynamic>.from(item)),
        );
      }

      loadedHistory.sort((a, b) {
        DateTime? dateA;
        DateTime? dateB;

        try {
          dateA = a['lastRead'] != null ? DateTime.parse(a['lastRead']) : null;
        } catch (e) {
          print("Erro ao fazer o parse da data A: ${a['lastRead']}, erro: $e");
        }

        try {
          dateB = b['lastRead'] != null ? DateTime.parse(b['lastRead']) : null;
        } catch (e) {
          print("Erro ao fazer o parse da data B: ${b['lastRead']}, erro: $e");
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
      print("Erro ao carregar histórico: $e");
      if (_mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleHistoryTap(String novelId, String pluginId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderScreen(novelId: novelId)),
    );
  }

  Future<void> _refreshHistory() async {
    await _loadHistory();
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
                      lastRead: DateTime.parse(
                        item['lastRead'] ?? DateTime.now().toIso8601String(),
                      ),
                      onTap:
                          () => _handleHistoryTap(
                            item['novelId'],
                            item['pluginId'],
                          ),
                    );
                  },
                ),
              ),
    );
  }
}
