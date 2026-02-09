import 'package:flutter/material.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/services/download_queue_service.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/theme/app_colors.dart';

class ChapterDownloadButton extends StatelessWidget {
  final Chapter chapter;
  final String novelId;
  final DownloadStatus? status;
  final VoidCallback onDownload;
  final VoidCallback? onCancel;

  const ChapterDownloadButton({
    super.key,
    required this.chapter,
    required this.novelId,
    this.status,
    required this.onDownload,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: _getTooltip(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _handleTap(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildIcon(isDarkMode),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDarkMode) {
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
                decoration: BoxDecoration(
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
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.info,
            ),
          ),
        );
      case DownloadStatus.completed:
        return const Icon(Icons.cloud_done, size: 20, color: AppColors.success);
      case DownloadStatus.failed:
        return const Icon(Icons.cloud_off, size: 20, color: AppColors.error);
      case null:
        return Icon(
          Icons.cloud_download_outlined,
          size: 20,
          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        );
    }
  }

  VoidCallback _handleTap(BuildContext context) {
    return () {
      if (status == DownloadStatus.downloading ||
          status == DownloadStatus.queued) {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text('cancel_download'.translate),
                content: Text('cancel_download_chapter'.translate.replaceAll('{chapter}', chapter.title)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('no_button'.translate),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onCancel?.call();
                    },
                    child: Text('yes_button'.translate),
                  ),
                ],
              ),
        );
      } else {
        onDownload();
      }
    };
  }

  String _getTooltip() {
    switch (status) {
      case DownloadStatus.queued:
        return 'Na fila de download';
      case DownloadStatus.downloading:
        return 'Baixando...';
      case DownloadStatus.completed:
        return 'Baixado';
      case DownloadStatus.failed:
        return 'Falha no download';
      case null:
        return 'Baixar capítulo';
    }
  }
}
