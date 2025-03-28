import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'chapter_list_widget.dart';

class NovelDetailsWidget extends StatelessWidget {
  final Novel novel;
  final String? lastReadChapterId;
  final int? lastReadChapterIndex;
  final VoidCallback? onContinueReading;
  final Function(String) onChapterTap;

  const NovelDetailsWidget({
    super.key,
    required this.novel,
    required this.lastReadChapterId,
    required this.lastReadChapterIndex,
    this.onContinueReading,
    required this.onChapterTap,
  });

  Widget _buildImageSkeleton(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(width: 150, height: 220, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: novel.coverImageUrl,
                fit: BoxFit.cover,
                width: screenWidth,
                height: 300,
                placeholder:
                    (context, url) => Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[300],
                    ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                imageBuilder:
                    (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.6),
                            BlendMode.dstATop,
                          ),
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            isDarkMode
                                ? Colors.black.withOpacity(0.8)
                                : Colors.white.withOpacity(0.8),
                            isDarkMode
                                ? Colors.black.withOpacity(0.8)
                                : Colors.white.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
              ),

              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 220,
                    child: Card(
                      elevation: 8,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: novel.coverImageUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => _buildImageSkeleton(context),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 250,
                left: 0,
                right: 0,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      novel.title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (novel.author != null && novel.author.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    novel.author.startsWith('por')
                        ? novel.author
                        : 'por ${novel.author}',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Text(
                  novel.description,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                if (lastReadChapterId != null && lastReadChapterIndex != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onContinueReading,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar Leitura'),
                    ),
                  ),

                const SizedBox(height: 16),

                const Text(
                  'Capítulos:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ChapterListWidget(
                  chapters: novel.chapters,
                  onChapterTap: onChapterTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
