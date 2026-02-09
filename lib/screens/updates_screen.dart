import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/widgets/optimized_network_image.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  bool _isChecking = false;
  final Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _refreshUnreadCounts();
  }

  Future<void> _refreshUnreadCounts() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final Map<String, int> counts = {};

    for (final novel in appState.favoriteNovels) {
      final db = await NovelDatabase.getInstance();
      final readSet = await db.getReadChaptersForNovel(novel.id);
      int unread = 0;
      if (novel.chapters.isNotEmpty) {
        for (final ch in novel.chapters) {
          if (!readSet.contains(ch.id)) unread++;
        }
      }
      counts[novel.id] = unread;
    }

    if (mounted) {
      setState(() {
        _unreadCounts.clear();
        _unreadCounts.addAll(counts);
      });
    }
  }

  Future<void> _checkForUpdates() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.checkForUpdates();
    await _refreshUnreadCounts();

    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('updates_checked'.translate),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final favs = List.of(appState.favoriteNovels)..sort((a, b) {
      int unreadA = _unreadCounts[a.id] ?? 0;
      int unreadB = _unreadCounts[b.id] ?? 0;
      if (unreadA != unreadB) return unreadB.compareTo(unreadA);
      return a.title.compareTo(b.title);
    });

    final totalUnread = _unreadCounts.values.fold<int>(0, (a, b) => a + b);
    final totalChapters = favs.fold<int>(
      0,
      (sum, n) => sum + (n.chapters.length),
    );
    final totalRead = totalChapters > totalUnread 
        ? (totalChapters - totalUnread).clamp(0, totalChapters)
        : 0;
    final percentRead = totalChapters > 0 ? (totalRead / totalChapters) : 0.0;
    final nextIdx = favs.indexWhere((n) => (_unreadCounts[n.id] ?? 0) > 0);
    final Novel? nextNovel = nextIdx != -1 ? favs[nextIdx] : null;

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: _checkForUpdates,
        edgeOffset: 120,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text('favorites_updates'.translate),
              centerTitle: true,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(15),
                child: const SizedBox(height: 15),
              ),
              actions: [
                if (totalUnread > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Badge.count(
                      count: totalUnread,
                      backgroundColor: theme.colorScheme.error,
                      child: const Icon(Icons.notifications_none),
                    ),
                  ),
                IconButton(
                  icon:
                      _isChecking
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh),
                  onPressed: _checkForUpdates,
                ),
              ],
            ),

            if (favs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    _isChecking
                        ? 'checking_updates_msg'.translate
                        : 'update_list_caption'.translate,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),

            if (favs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'progress'.translate,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: percentRead,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalChapters > 0
                                    ? '$totalRead/$totalChapters ${'chapters_read'.translate}'
                                    : '0/0 ${'chapters_read'.translate}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                '${(percentRead * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          if (nextNovel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${'next'.translate}: ${nextNovel.title}',
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (_) {
                                final unreadForNext =
                                    _unreadCounts[nextNovel.id] ?? 0;
                                final chaptersForNext =
                                    (nextNovel.chapters.length);
                                final readForNext = (chaptersForNext -
                                        unreadForNext)
                                    .clamp(0, chaptersForNext);
                                final pctNext =
                                    chaptersForNext > 0
                                        ? (readForNext / chaptersForNext)
                                        : 0.0;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                            LinearProgressIndicator(
                              value: pctNext,
                              color: theme.colorScheme.primary
                                  .withOpacity(0.8),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  chaptersForNext > 0
                                      ? '$readForNext/$chaptersForNext ${'chapters_read'.translate}'
                                      : '',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  chaptersForNext > 0
                                      ? '${(pctNext * 100).toStringAsFixed(0)}%'
                                      : '',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (favs.isEmpty)
              const SliverFillRemaining(child: EmptyUpdatesWidget())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: MediaQuery.of(context).size.width < 600 ? 350 : 500,
                    mainAxisExtent: 110,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final novel = favs[index];
                    final unreadCount = _unreadCounts[novel.id] ?? 0;
                    return UpdateCard(
                      novel: novel,
                      unreadCount: unreadCount,
                      onRefresh: _refreshUnreadCounts,
                    );
                  }, childCount: favs.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          _isChecking
              ? null
              : Builder(
                builder: (ctx) {
                  final bottomPad =
                      kBottomNavigationBarHeight +
                      MediaQuery.of(ctx).padding.bottom +
                      20.0;
                  return Padding(
                    padding: EdgeInsets.only(bottom: bottomPad, right: 16.0),
                    child: FloatingActionButton(
                      onPressed: _checkForUpdates,
                      tooltip: 'check_updates'.translate,
                      child: const Icon(Icons.update),
                    ),
                  );
                },
              ),
    );
  }
}

class UpdateCard extends StatelessWidget {
  final dynamic novel;
  final int unreadCount;
  final VoidCallback onRefresh;

  const UpdateCard({
    super.key,
    required this.novel,
    required this.unreadCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              unreadCount > 0
                  ? colorScheme.primary.withOpacity(0.6)
                  : colorScheme.outlineVariant,
          width: unreadCount > 0 ? 2 : 1,
        ),
      ),
      child: Container(
        decoration: unreadCount > 0
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              )
            : null,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NovelDetailScreen(novel: novel)),
            ).then((_) => onRefresh());
          },
          child: Row(
          children: [
            SizedBox(
              width: 80,
              height: double.infinity,
              child: OptimizedNetworkImage(
                novel.coverImageUrl,
                fit: BoxFit.cover,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      novel.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      novel.author,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class EmptyUpdatesWidget extends StatelessWidget {
  const EmptyUpdatesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_motion_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'no_favorites_yet'.translate,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'add_favorites_to_track'.translate,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
