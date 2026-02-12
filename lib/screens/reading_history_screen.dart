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
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _sortBy = value),
            icon: const Icon(Icons.sort),
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'recent',
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color:
                              _sortBy == 'recent'
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                        Text('sort_by_recent'.translate),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'title',
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.abc,
                          size: 18,
                          color:
                              _sortBy == 'title'
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
                        Text('sort_by_title'.translate),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'author',
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.person,
                          size: 18,
                          color:
                              _sortBy == 'author'
                                  ? theme.colorScheme.primary
                                  : null,
                        ),
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
                const Icon(Icons.filter_list),
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
            tooltip: 'Filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                _showFilters
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
                    '${novels.length} resultado${novels.length != 1 ? 's' : ''}',
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
                      'Limpar filtros',
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
            child:
                novels.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.1),
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
                          const SizedBox(height: 8),
                          Text(
                            _hasActiveFilters()
                                ? 'Nenhuma novel encontrada com esses filtros'
                                : 'Comece a ler para ver seu histórico aqui',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
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
        spacing: 16,
        children: [
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Período',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border.all(
                            color:
                                _dateRange != null
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                            width: _dateRange != null ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          spacing: 8,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color:
                                  _dateRange != null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                            Expanded(
                              child: Text(
                                _dateRange == null
                                    ? 'Selecione um período'
                                    : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      _dateRange != null
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
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _dateRange = null),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (allNovels.isNotEmpty)
            Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Novels',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_selectedNovels.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _selectedNovels.clear()),
                        child: Text(
                          'Limpar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
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
                          label: Text(
                            novel.title,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 12),
                          ),
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
                          avatar:
                              _selectedNovels.contains(novel.id)
                                  ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                  )
                                  : null,
                        ),
                    ],
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NovelDetailScreen(novel: novel),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (novel.coverImageUrl.isNotEmpty)
                        Hero(
                          tag: 'cover_${novel.id}',
                          child: ClipRRect(
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
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.book_outlined,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      size: 32,
                                    ),
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
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              novel.author,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              spacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${novel.chapters.length} cap.',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (lastChapter != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withOpacity(
                          0.4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Row(
                            spacing: 6,
                            children: [
                              Icon(
                                Icons.bookmark,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              Text(
                                'Último capítulo',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            lastChapter.title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (lastChapter?.content != null &&
                      lastChapter!.content!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _extractPreview(lastChapter.content!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.15,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
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
                        const SizedBox(
                          height: 14,
                          child: VerticalDivider(width: 1),
                        ),
                        Row(
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
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
                  ),
                ],
              ),
            ),
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
