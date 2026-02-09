import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/home_stats_grid.dart';
import 'package:akashic_records/widgets/home_quick_actions.dart';
import 'package:akashic_records/widgets/favorites_carousel.dart';
import 'package:akashic_records/widgets/recent_read_list.dart';

typedef OnOpenReader = void Function(Novel novel, int index);

class HomeContentBuilder extends StatelessWidget {
  final int totalWordsRead;
  final int totalChaptersRead;
  final int favoritesCount;
  final int localEpubCount;
  final int localEpubChapters;
  final List<Map<String, dynamic>> recentReadChapters;
  final List<Novel> favoriteNovels;
  final OnOpenReader onOpenReader;

  const HomeContentBuilder({
    super.key,
    required this.totalWordsRead,
    required this.totalChaptersRead,
    required this.favoritesCount,
    required this.localEpubCount,
    required this.localEpubChapters,
    required this.recentReadChapters,
    required this.favoriteNovels,
    required this.onOpenReader,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeStatsGrid(
              totalWordsRead: totalWordsRead,
              totalChaptersRead: totalChaptersRead,
              favoritesCount: favoritesCount,
            ),
            const SizedBox(height: 24),

            HomeQuickActions(
              localEpubCount: localEpubCount,
              localEpubChapters: localEpubChapters,
            ),
            const SizedBox(height: 24),

            if (favoriteNovels.isNotEmpty) ...[
              _buildSectionTitle(context, 'favorites'.translate),
              FavoritesCarousel(favorites: favoriteNovels),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle(context, 'last_novels'.translate),
            RecentReadList(
              recentReadChapters: recentReadChapters,
              onOpenReader: onOpenReader,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
