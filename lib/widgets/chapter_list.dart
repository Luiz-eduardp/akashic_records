import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/services/download_queue_service.dart';

typedef ChapterTap = void Function(Chapter chapter, int index);
typedef ChapterLongPress = void Function(Chapter chapter, int index);
typedef ChapterDownload = Future<void> Function(Chapter chapter);
typedef ChapterCancelDownload = Future<void> Function(String chapterId);
typedef DownloadAllChapters = Future<void> Function(List<Chapter> chapters);

class ChapterList extends StatefulWidget {
  final List<Chapter> chapters;
  final Set<String> readChapters;
  final ChapterTap onTap;
  final ChapterLongPress? onLongPressToggleRead;
  final String novelId;
  final bool sliver;
  final ChapterDownload? onDownload;
  final ChapterCancelDownload? onCancelDownload;
  final DownloadAllChapters? onDownloadAll;
  final Map<String, DownloadStatus> downloadStatus;

  const ChapterList({
    super.key,
    required this.chapters,
    required this.readChapters,
    required this.onTap,
    this.onLongPressToggleRead,
    required this.novelId,
    this.sliver = false,
    this.onDownload,
    this.onCancelDownload,
    this.onDownloadAll,
    this.downloadStatus = const {},
  });

  @override
  State<ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<ChapterList> {
  Widget _buildDownloadIcon(DownloadStatus? status) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    switch (status) {
      case DownloadStatus.queued:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 20,
              color: Colors.grey[600],
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
      case DownloadStatus.downloading:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.blue[300]! : Colors.blue,
            ),
          ),
        );
      case DownloadStatus.completed:
        return Icon(
          Icons.cloud_done,
          size: 20,
          color: Colors.green[600],
        );
      case DownloadStatus.failed:
        return Icon(
          Icons.cloud_off,
          size: 20,
          color: Colors.red[600],
        );
      case null:
        return Icon(
          Icons.cloud_download_outlined,
          size: 20,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliver) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((ctx, i) {
          final ch = widget.chapters[i];
          final originalIndex = i;
          final isRead = widget.readChapters.contains(ch.id);
          final status = widget.downloadStatus[ch.id];
          
          return Column(
            children: [
              ListTile(
                title: Text(
                  ch.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: ch.releaseDate != null ? Text(ch.releaseDate!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onDownload != null)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              if (status == DownloadStatus.downloading ||
                                  status == DownloadStatus.queued) {
                                showDialog(
                                  context: context,
                                  builder: (dialogCtx) => AlertDialog(
                                    title: const Text('Cancelar Download'),
                                    content: Text(
                                      'Cancelar o download de "${ch.title}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogCtx),
                                        child: const Text('Não'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogCtx);
                                          widget.onCancelDownload?.call(ch.id);
                                        },
                                        child: const Text('Sim'),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                await widget.onDownload?.call(ch);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _buildDownloadIcon(status),
                            ),
                          ),
                        ),
                      ),
                    if (isRead)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
                onTap: () => widget.onTap(ch, originalIndex),
                onLongPress:
                    widget.onLongPressToggleRead == null
                        ? null
                        : () =>
                            widget.onLongPressToggleRead!(ch, originalIndex),
              ),
              if (i != widget.chapters.length - 1) const Divider(height: 1),
            ],
          );
        }, childCount: widget.chapters.length),
      );
    }

    return ListView.separated(
      itemCount: widget.chapters.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final ch = widget.chapters[i];
        final originalIndex = i;
        final isRead = widget.readChapters.contains(ch.id);
        final status = widget.downloadStatus[ch.id];
        
        return ListTile(
          title: Text(ch.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: ch.releaseDate != null ? Text(ch.releaseDate!) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onDownload != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        if (status == DownloadStatus.downloading ||
                            status == DownloadStatus.queued) {
                          showDialog(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Cancelar Download'),
                              content: Text(
                                'Cancelar o download de "${ch.title}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogCtx),
                                  child: const Text('Não'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(dialogCtx);
                                    widget.onCancelDownload?.call(ch.id);
                                  },
                                  child: const Text('Sim'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          await widget.onDownload?.call(ch);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildDownloadIcon(status),
                      ),
                    ),
                  ),
                ),
              if (isRead) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
          onTap: () => widget.onTap(ch, originalIndex),
          onLongPress:
              widget.onLongPressToggleRead == null
                  ? null
                  : () => widget.onLongPressToggleRead!(ch, originalIndex),
        );
      },
    );
  }
}
