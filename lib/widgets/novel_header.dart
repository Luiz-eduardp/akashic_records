import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:math' as math;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/http_client.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/widgets/skeleton.dart';

class NovelHeader extends StatefulWidget {
  final Novel novel;
  final bool loading;
  const NovelHeader({super.key, required this.novel, this.loading = false});

  @override
  State<NovelHeader> createState() => _NovelHeaderState();
}

class _NovelHeaderState extends State<NovelHeader> {
  bool _expanded = false;

  Widget _buildCoverImage(double width, double height, Novel novel) {
    if (novel.coverImageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade400,
        child: Icon(
          Icons.menu_book,
          color: Colors.grey.shade700,
          size: height * 0.4,
        ),
      );
    }

    final isNetworkImage = novel.coverImageUrl.startsWith('http');

    Widget imageWidget =
        isNetworkImage
            ? Image.network(
              novel.coverImageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    width: width,
                    height: height,
                    color: Colors.grey,
                    child: const Icon(Icons.error_outline),
                  ),
            )
            : Image.file(
              File(novel.coverImageUrl),
              width: width,
              height: height,
              fit: BoxFit.cover,
            );

    return GestureDetector(
      onTap: () => _openFullImage(context),
      child: Hero(tag: _heroTag(novel), child: imageWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final novel = widget.novel;
    final loading = widget.loading;
    Provider.of<AppState>(context);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
        isDark
            ? theme.colorScheme.surface.withOpacity(0.6)
            : theme.colorScheme.surface.withOpacity(0.3);
    final highlightColor =
        isDark
            ? theme.colorScheme.background.withOpacity(0.2)
            : theme.colorScheme.background.withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: _expanded ? 16 / 5 : 16 / 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child:
                        loading
                            ? LoadingSkeleton.rect(
                              height: double.infinity,
                              width: double.infinity,
                              baseColor: baseColor,
                              highlightColor: highlightColor,
                            )
                            : (novel.coverImageUrl.isNotEmpty
                                ? (novel.coverImageUrl.startsWith('http')
                                    ? Image.network(
                                      novel.coverImageUrl,
                                      fit: BoxFit.cover,
                                    )
                                    : Image.file(
                                      File(novel.coverImageUrl),
                                      fit: BoxFit.cover,
                                    ))
                                : Container(color: theme.colorScheme.surface)),
                  ),

                  if (!loading && novel.coverImageUrl.isNotEmpty)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(color: Colors.black.withOpacity(0.35)),
                      ),
                    ),

                  Align(
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) {
                        final available =
                            constraints.maxHeight.isFinite
                                ? constraints.maxHeight
                                : 200.0;
                        final coverH = math.min(available * 0.75, 200.0);
                        final coverW = coverH * 0.7;

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              loading
                                  ? LoadingSkeleton.rect(
                                    width: coverW,
                                    height: coverH,
                                    baseColor: baseColor,
                                    highlightColor: highlightColor,
                                  )
                                  : _buildCoverImage(coverW, coverH, novel),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  loading
                      ? LoadingSkeleton.rect(
                        height: 24,
                        width: double.infinity,
                        baseColor: baseColor,
                        highlightColor: highlightColor,
                      )
                      : Text(
                        novel.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                  const SizedBox(height: 6),
                  if (!loading)
                    if (novel.author.isNotEmpty)
                      Text(
                        '${'by'.translate} ${novel.author}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Container(
                        height: 16,
                        width: 120,
                        color: Colors.transparent,
                      )
                  else
                    LoadingSkeleton.rect(
                      height: 18,
                      width: 150,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          loading
              ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingSkeleton.rect(
                      height: 14,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeleton.rect(
                      height: 14,
                      width: 300,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                    const SizedBox(height: 6),
                    LoadingSkeleton.rect(
                      height: 14,
                      width: 250,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                    ),
                  ],
                ),
              )
              : GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    novel.description.isNotEmpty
                        ? novel.description
                        : 'no_description_available'.translate,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.start,
                    maxLines: _expanded ? 1000 : 6,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _heroTag(Novel novel) => 'novel-cover-${novel.title.hashCode}';

  void _openFullImage(BuildContext context) {
    final novel = widget.novel;
    if (novel.coverImageUrl.isEmpty) return;

    final isNetworkImage = novel.coverImageUrl.startsWith('http');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                if (isNetworkImage)
                  IconButton(
                    tooltip: 'download_image'.translate,
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      try {
                        final res = await fetch(Uri.parse(novel.coverImageUrl));
                        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
                          final dir = await getApplicationDocumentsDirectory();
                          final ext =
                              novel.coverImageUrl
                                  .split('.')
                                  .last
                                  .split('?')
                                  .first;
                          final fileName = 'cover_${novel.title.hashCode}.$ext';
                          final file = File('${dir.path}/$fileName');
                          await file.writeAsBytes(res.bodyBytes);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'image_saved_to'.translate + ': ${file.path}',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('download_failed'.translate),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('download_failed'.translate)),
                        );
                      }
                    },
                  ),
                IconButton(
                  tooltip: 'upload_image'.translate,
                  icon: const Icon(Icons.upload_file),
                  onPressed: () async {
                    try {
                      final res = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (res != null && res.files.single.path != null) {
                        final src = File(res.files.single.path!);
                        final dir = await getApplicationDocumentsDirectory();
                        final ext = src.path.substring(
                          src.path.lastIndexOf('.'),
                        );
                        final dest = File(
                          '${dir.path}/cover_upload_${novel.title.hashCode}$ext',
                        );

                        await dest.writeAsBytes(await src.readAsBytes());

                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        final updated = Novel.fromMap(novel.toMap());
                        updated.coverImageUrl = dest.path;
                        await appState.addOrUpdateNovel(updated);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('cover_updated'.translate)),
                        );
                        if (mounted) Navigator.of(context).pop();
                      }
                    } catch (e) {
                      debugPrint('Upload failed: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('upload_failed'.translate)),
                      );
                    }
                  },
                ),
              ],
            ),
            body: Center(
              child: Hero(
                tag: _heroTag(novel),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child:
                      isNetworkImage
                          ? Image.network(
                            novel.coverImageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          )
                          : Image.file(
                            File(novel.coverImageUrl),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
