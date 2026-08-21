import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:akashic_records/i18n/i18n.dart';
import '../safe_network_image.dart';

class M3EDocumentCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverPath;
  final String format;
  final double progressPercent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const M3EDocumentCard({
    super.key,
    required this.title,
    required this.author,
    this.coverPath,
    required this.format,
    required this.progressPercent,
    required this.onTap,
    this.onLongPress,
  });

  Color _formatBadgeColor(BuildContext context) {
    final fmt = format.toLowerCase();
    if (fmt == 'pdf') return const Color(0xFFDC2626);
    if (fmt == 'mobi') return const Color(0xFFD97706);
    if (fmt == 'epub') return const Color(0xFF2563EB);
    if (fmt == 'cbz' || fmt == 'cbr') return const Color(0xFF7C3AED);
    if (fmt == 'txt') return const Color(0xFF0D9488);
    return Theme.of(context).colorScheme.primary;
  }

  Widget _buildCoverImage(BuildContext context) {
    if (coverPath != null && coverPath!.isNotEmpty) {
      if (coverPath!.startsWith('http://') || coverPath!.startsWith('https://')) {
        return SafeNetworkImage(
          url: coverPath!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        final f = File(coverPath!);
        if (f.existsSync()) {
          return Image.file(
            f,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildPlaceholderCover(context),
          );
        }
      }
    }
    return _buildPlaceholderCover(context);
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _formatIcon(format),
              size: 38,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _formatIcon(String fmt) {
    switch (fmt.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'cbz':
      case 'cbr':
        return Icons.collections_bookmark_rounded;
      case 'mobi':
      case 'epub':
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColor = _formatBadgeColor(context);
    final pctText = '${(progressPercent * 100).clamp(0, 100).toInt()}%';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: _buildCoverImage(context),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          format.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ClipRRect(
                child: LinearProgressIndicator(
                  value: progressPercent.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: progressPercent >= 1.0 ? Colors.green : colorScheme.primary,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            author.isNotEmpty ? author : 'unknown_author'.translate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          pctText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 10,
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
    );
  }
}
