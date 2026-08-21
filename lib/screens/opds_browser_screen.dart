import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'package:akashic_records/services/opds_service.dart';
import 'package:akashic_records/services/epub_import_service.dart';
import 'package:akashic_records/state/app_state.dart';

class OpdsBrowserScreen extends StatefulWidget {
  const OpdsBrowserScreen({super.key});

  @override
  State<OpdsBrowserScreen> createState() => _OpdsBrowserScreenState();
}

class _OpdsBrowserScreenState extends State<OpdsBrowserScreen> {
  final OpdsService _opdsService = OpdsService();
  final EpubImportService _importService = EpubImportService();

  String _currentFeedUrl = OpdsService.defaultFeeds[0]['url']!;
  String _currentFeedTitle = OpdsService.defaultFeeds[0]['title']!;
  final TextEditingController _customUrlController = TextEditingController();

  List<OpdsEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, bool> _downloadingMap = {};

  @override
  void initState() {
    super.initState();
    _loadFeed(_currentFeedUrl, _currentFeedTitle);
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadFeed(String url, String title) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentFeedUrl = url;
      _currentFeedTitle = title;
    });

    try {
      final entries = await _opdsService.fetchFeed(url);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadAndImportBook(OpdsEntry entry) async {
    if (entry.downloadUrl == null) return;

    setState(() {
      _downloadingMap[entry.title] = true;
    });

    try {
      final ext = entry.downloadType?.contains('pdf') == true ? '.pdf' : '.epub';
      final safeTitle = entry.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      final fileName = '$safeTitle$ext';

      final downloadedFile = await _opdsService.downloadBook(entry.downloadUrl!, fileName);
      final importedNovel = await _importService.importFromFile(downloadedFile.path);

      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addOrUpdateNovel(importedNovel);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('downloaded_and_imported'.translateParams({'title': entry.title})),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('failed_to_download'.translateParams({'error': e.toString()})),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingMap[entry.title] = false;
        });
      }
    }
  }

  void _showAddCustomFeedModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'add_opds_feed'.translate,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customUrlController,
                decoration: InputDecoration(
                  labelText: 'opds_feed_url'.translate,
                  hintText: 'http://192.168.1.10:8080/opds',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final url = _customUrlController.text.trim();
                    if (url.isNotEmpty) {
                      Navigator.pop(context);
                      _loadFeed(url, 'custom_opds_catalog'.translate);
                    }
                  },
                  child: Text('connect_feed'.translate),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: M3EAppBar(
        title: 'opds_catalogs'.translate,
        subtitle: _currentFeedTitle,
        actions: [
          IconButton(
            tooltip: 'add_opds_feed'.translate,
            icon: const Icon(Icons.add_link_rounded),
            onPressed: _showAddCustomFeedModal,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: OpdsService.defaultFeeds.map((feed) {
                final selected = _currentFeedUrl == feed['url'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    selected: selected,
                    label: Text(feed['title']!),
                    onSelected: (_) => _loadFeed(feed['url']!, feed['title']!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _loadFeed(_currentFeedUrl, _currentFeedTitle),
                              child: Text('retry'.translate),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          final isDownloading = _downloadingMap[entry.title] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: entry.coverUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              entry.coverUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.book_rounded),
                                            ),
                                          )
                                        : const Icon(Icons.book_rounded),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.title,
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          entry.author,
                                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.summary,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (entry.downloadUrl != null)
                                    isDownloading
                                        ? const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2.5),
                                            ),
                                          )
                                        : IconButton(
                                            tooltip: 'Download & Import',
                                            icon: const Icon(Icons.file_download_rounded),
                                            onPressed: () => _downloadAndImportBook(entry),
                                          ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
