import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/widgets/novel_card.dart';
import 'package:akashic_records/widgets/skeleton/novel_grid_skeleton.dart';

class NovelGridWidget extends StatelessWidget {
  final List<Novel> novels;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController scrollController;
  final Function(Novel) onNovelTap;
  final Function(Novel) onNovelLongPress;

  const NovelGridWidget({
    super.key,
    required this.novels,
    required this.isLoading,
    required this.errorMessage,
    required this.scrollController,
    required this.onNovelTap,
    required this.onNovelLongPress,
    required bool isListView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return NovelGridSkeletonWidget(itemCount: 8);
    }

    if (errorMessage != null) {
      return _buildErrorState(context, theme);
    }

    if (novels.isEmpty) {
      return _buildEmptyState(context);
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          key: const PageStorageKey<String>('novel_grid'),
          controller: scrollController,
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.7,
          ),
          itemCount: novels.length,
          itemBuilder: (context, index) {
            final novel = novels[index];
            return NovelCard(
              key: ValueKey(novel.id),
              novel: novel,
              onTap: () => onNovelTap(novel),
              onLongPress: () => onNovelLongPress(novel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 60,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          'Tentar Novamente'.translate,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Nenhuma novel encontrada.".translate,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/plugins');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Text(
                          'Plugins'.translate,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
