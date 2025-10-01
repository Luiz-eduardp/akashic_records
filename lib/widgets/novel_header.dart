import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:math' as math;
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/services/http_client.dart';
import 'package:akashic_records/widgets/skeleton.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class NovelHeader extends StatefulWidget {
  final Novel novel;
  final bool loading;
  const NovelHeader({super.key, required this.novel, this.loading = false});

  @override
  State<NovelHeader> createState() => _NovelHeaderState();
}

class _NovelHeaderState extends State<NovelHeader> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final novel = widget.novel;
    final loading = widget.loading;
    Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.all(12.0),
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
                  if (!loading && novel.coverImageUrl.isNotEmpty)
                    Positioned.fill(
                      child:
                          novel.coverImageUrl.startsWith('http')
                              ? Image.network(
                                novel.coverImageUrl,
                                fit: BoxFit.cover,
                              )
                              : Image.file(
                                File(novel.coverImageUrl),
                                fit: BoxFit.cover,
                              ),
                    )
                  else
                    Container(color: Colors.grey.shade200),
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
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  loading
                                      ? const LoadingSkeleton.square()
                                      : (novel.coverImageUrl.isNotEmpty
                                          ? GestureDetector(
                                            onTap:
                                                () => _openFullImage(context),
                                            child: Hero(
                                              tag: _heroTag(novel),
                                              child:
                                                  novel.coverImageUrl
                                                          .startsWith('http')
                                                      ? Image.network(
                                                        novel.coverImageUrl,
                                                        width: coverW,
                                                        height: coverH,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              _,
                                                              __,
                                                              ___,
                                                            ) => Container(
                                                              width: coverW,
                                                              height: coverH,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                      )
                                                      : Image.file(
                                                        File(
                                                          novel.coverImageUrl,
                                                        ),
                                                        width: coverW,
                                                        height: coverH,
                                                        fit: BoxFit.cover,
                                                      ),
                                            ),
                                          )
                                          : Container(
                                            width: coverW,
                                            height: coverH,
                                            color: Colors.grey,
                                          )),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    novel.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  if (!loading && novel.author.isNotEmpty)
                    Text(
                      '${'by'.translate} ${novel.author}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),
          loading
              ? const LoadingSkeleton.rect(height: 100)
              : GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Text(
                    novel.description,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'download_image'.translate,
                  icon: const Icon(Icons.download),
                  onPressed: () async {
                    if (novel.coverImageUrl.startsWith('http')) {
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
                          final file = File(
                            '${dir.path}/cover_${novel.title.hashCode}.$ext',
                          );
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('no_remote_image'.translate)),
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
                        final dest = File(
                          '${dir.path}/cover_upload_${novel.title.hashCode}${src.path.substring(src.path.lastIndexOf('.'))}',
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
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
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
                      novel.coverImageUrl.startsWith('http')
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
