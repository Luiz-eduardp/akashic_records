import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/novel_detail_screen.dart';

class FavoritesCarousel extends StatelessWidget {
  final List<Novel> favorites;

  const FavoritesCarousel({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) {
          final n = favorites[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailScreen(novel: n))),
            child: SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: n.coverImageUrl.isNotEmpty
                        ? Image.network(n.coverImageUrl, width: 120, height: 160, fit: BoxFit.cover)
                        : Container(width: 120, height: 160, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 8),
                  Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
