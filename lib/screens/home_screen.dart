import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/services/backup_service.dart';
import 'package:akashic_records/services/home_stats_handler.dart';
import 'package:akashic_records/widgets/home_header.dart';
import 'package:akashic_records/widgets/home_content_builder.dart';
import 'package:akashic_records/widgets/home_import_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeStatsHandler _statsHandler;
  AppState? _appStateRef;

  @override
  void initState() {
    super.initState();
    _statsHandler = HomeStatsHandler(
      onStatsUpdated: _handleStatsUpdated,
    );
    _setupInitialData();
  }

  void _setupInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appStateRef = Provider.of<AppState>(context, listen: false);
      _loadStats();
      _appStateRef?.addListener(_loadStats);
      _runBackup();
    });
  }

  Future<void> _runBackup() async {
    try {
      final svc = BackupService();
      final performed = await svc.performDailyBackup();
      if (performed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('backup_created'.translate),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    final appState = _appStateRef;
    if (appState == null) return;
    await _statsHandler.loadStats(appState);
  }

  void _handleStatsUpdated() {
    if (mounted) setState(() {});
  }

  void _openReader(Novel novel, int index) {
    Navigator.pushNamed(
      context,
      '/reader',
      arguments: {'novel': novel, 'chapterIndex': index},
    );
  }

  @override
  void dispose() {
    _appStateRef?.removeListener(_loadStats);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            const HomeHeader(),
            HomeContentBuilder(
              totalWordsRead: _statsHandler.totalWordsRead,
              totalChaptersRead: _statsHandler.totalChaptersRead,
              favoritesCount: appState.favoriteNovels.length,
              localEpubCount: _statsHandler.localEpubCount,
              localEpubChapters: _statsHandler.localEpubChapters,
              recentReadChapters: _statsHandler.recentReadChapters,
              favoriteNovels: appState.favoriteNovels,
              onOpenReader: _openReader,
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: HomeImportFab(
        onSuccess: (novel) {
          if (mounted) {
            Navigator.pushNamed(context, '/local_epubs');
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error)),
            );
          }
        },
        onImportStart: () {
          if (mounted) setState(() {});
        },
        onImportEnd: () {
          if (mounted) setState(() {});
        },
      ),
    );
  }
}

