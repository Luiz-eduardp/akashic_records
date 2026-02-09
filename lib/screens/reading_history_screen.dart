import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen> {
  String _sortBy = 'recent';
  DateTimeRange? _dateRange;
  final Set<String> _selectedNovels = {};
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    List<Novel> novels =
        List.of(
          appState.localNovels,
        ).where((n) => n.lastReadAt != null).toList();

    if (_dateRange != null) {
      novels =
          novels.where((n) {
            final dateTime = DateTime.tryParse(n.lastReadAt ?? '');
            if (dateTime == null) return false;
            return dateTime.isAfter(_dateRange!.start) &&
                dateTime.isBefore(_dateRange!.end.add(const Duration(days: 1)));
          }).toList();
    }

    if (_selectedNovels.isNotEmpty) {
      novels = novels.where((n) => _selectedNovels.contains(n.id)).toList();
    }

    if (_sortBy == 'recent') {
      novels.sort((a, b) {
        final dateA = DateTime.tryParse(a.lastReadAt ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b.lastReadAt ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });
    } else if (_sortBy == 'title') {
      novels.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortBy == 'author') {
      novels.sort((a, b) => a.author.compareTo(b.author));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('reading_history'.translate),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'recent',
                    child: Text('sort_by_recent'.translate),
                  ),
                  PopupMenuItem<String>(
                    value: 'title',
                    child: Text('sort_by_title'.translate),
                  ),
                  PopupMenuItem<String>(
                    value: 'author',
                    child: Text('sort_by_author'.translate),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterPanel(context, appState),
          Expanded(
            child:
                novels.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_outlined,
                            size: 80,
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'reading_history_empty'.translate,
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: novels.length,
                      itemBuilder: (context, index) {
                        final novel = novels[index];
                        return _buildHistoryCard(context, novel);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final allNovels =
        List.of(
          appState.localNovels,
        ).where((n) => n.lastReadAt != null).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        spacing: 12,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _dateRange == null
                          ? 'filter_by_date'.translate
                          : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_dateRange != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => _dateRange = null),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final novel in allNovels)
                  FilterChip(
                    label: Text(novel.title, maxLines: 1),
                    selected: _selectedNovels.contains(novel.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedNovels.add(novel.id);
                        } else {
                          _selectedNovels.remove(novel.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Novel novel) {
    final theme = Theme.of(context);
    final dateTime = DateTime.tryParse(novel.lastReadAt ?? '');
    final formattedDate =
        dateTime != null
            ? '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}'
            : 'N/A';
    final formattedTime =
        dateTime != null
            ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
            : 'N/A';

    Chapter? lastChapter;
    if (novel.lastReadChapterId != null) {
      try {
        lastChapter = novel.chapters.firstWhere(
          (ch) => ch.id == novel.lastReadChapterId,
        );
      } catch (_) {
        lastChapter = novel.chapters.isNotEmpty ? novel.chapters.last : null;
      }
    } else {
      lastChapter = novel.chapters.isNotEmpty ? novel.chapters.last : null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NovelDetailScreen(novel: novel)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (novel.coverImageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        novel.coverImageUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 60,
                              height: 90,
                              color: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.book_outlined,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          novel.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          novel.author,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),

              if (lastChapter != null) ...[
                Text(
                  'last_chapter_read'.translate,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastChapter.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (lastChapter.content != null &&
                    lastChapter.content!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _extractPreview(lastChapter.content!),
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 1),
                const SizedBox(height: 12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          Text(
                            formattedDate,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        spacing: 6,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          Text(
                            formattedTime,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${novel.chapters.length} ${'chapters'.translate}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractPreview(String content) {
    String text = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[^;]+;'), ' ');

    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text.length > 150 ? '${text.substring(0, 150)}...' : text;
  }
}
