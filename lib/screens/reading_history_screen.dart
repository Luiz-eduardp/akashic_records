import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';

class ReadingHistoryScreen extends StatefulWidget {
  const ReadingHistoryScreen({super.key});

  @override
  State<ReadingHistoryScreen> createState() => _ReadingHistoryScreenState();
}

class _ReadingHistoryScreenState extends State<ReadingHistoryScreen>
    with SingleTickerProviderStateMixin {
  String _sortBy = 'recent';
  DateTimeRange? _dateRange;
  final Set<String> _selectedNovels = {};
  bool _showFilters = false;
  late AnimationController _filterAnimController;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _filterAnimController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimController.forward();
    } else {
      _filterAnimController.reverse();
    }
  }

  bool _hasActiveFilters() {
    return _dateRange != null || _selectedNovels.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();

    List<Novel> novels = List.of(
      appState.localNovels,
    ).where((n) => n.lastReadAt != null).toList();

    if (_dateRange != null) {
      novels = novels.where((n) {
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
      appBar: M3EAppBar(
        title: 'reading_history'.translate,
        subtitle: 'reading_history_desc'.translate,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _sortBy = value),
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: _sortBy == 'recent' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('sort_by_recent'.translate),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'title',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      size: 18,
                      color: _sortBy == 'title' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('sort_by_title'.translate),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'author',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: _sortBy == 'author' ? theme.colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text('sort_by_author'.translate),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_hasActiveFilters())
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            onPressed: _toggleFilters,
            tooltip: 'filter_by_date'.translate,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters
                ? _buildFilterPanel(context, appState)
                : const SizedBox.shrink(),
          ),
          if (novels.isNotEmpty && _hasActiveFilters())
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${novels.length} ${novels.length == 1 ? 'document_singular'.translate : 'documents_count'.translateParams({'count': novels.length})}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _dateRange = null;
                        _selectedNovels.clear();
                        _showFilters = false;
                      });
                      _filterAnimController.reverse();
                    },
                    child: Text(
                      'clear_selection'.translate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: novels.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_outlined,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'reading_history_empty'.translate,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
                    itemCount: novels.length,
                    itemBuilder: (context, index) {
                      final novel = novels[index];
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _buildHistoryCard(context, novel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, AppState appState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'filter_by_date'.translate,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      border: Border.all(
                        color: _dateRange != null
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: _dateRange != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: _dateRange != null
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRange == null
                                ? 'filter_by_date'.translate
                                : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _dateRange != null
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dateRange != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _dateRange = null),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Novel novel) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NovelDetailScreen(novel: novel),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 84,
                  child: novel.coverImageUrl.isNotEmpty
                      ? Image.network(
                          novel.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.book_rounded,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.book_rounded,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      novel.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      novel.author.isNotEmpty ? novel.author : 'unknown_author'.translate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          novel.lastReadAt != null
                              ? '${'last_read'.translate}: ${novel.lastReadAt}'
                              : 'never'.translate,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
