import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/db/repositories/annotations_repository.dart';
import 'dart:convert';

class AnnotationsManagerScreen extends StatefulWidget {
  final String novelId;
  final String novelTitle;

  const AnnotationsManagerScreen({
    super.key,
    required this.novelId,
    required this.novelTitle,
  });

  @override
  State<AnnotationsManagerScreen> createState() => _AnnotationsManagerScreenState();
}

class _AnnotationsManagerScreenState extends State<AnnotationsManagerScreen> {
  List<Annotation> _annotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnotations();
  }

  Future<void> _loadAnnotations() async {
    setState(() => _isLoading = true);
    try {
      final db = await NovelDatabase.getInstance();
      final list = await db.annotations.getAnnotationsForNovel(widget.novelId);
      setState(() {
        _annotations = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAnnotation(String id) async {
    try {
      final db = await NovelDatabase.getInstance();
      await db.annotations.deleteAnnotation(id);
      _loadAnnotations();
    } catch (_) {}
  }

  void _exportMarkdown() {
    if (_annotations.isEmpty) return;
    final buffer = StringBuffer();
    buffer.writeln('# ${widget.novelTitle} - ${'annotations_title'.translate}');
    buffer.writeln();

    for (final a in _annotations) {
      buffer.writeln('> ${a.selectedText}');
      if (a.note.isNotEmpty) {
        buffer.writeln('**Note**: ${a.note}');
      }
      buffer.writeln('*Date: ${a.createdAt.split("T").first}*');
      buffer.writeln('---');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied_to_clipboard'.translate)),
    );
  }

  void _exportJson() {
    if (_annotations.isEmpty) return;
    final listMap = _annotations.map((a) => a.toMap()).toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(listMap);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied_to_clipboard'.translate)),
    );
  }

  Color _parseHex(String hex) {
    try {
      var h = hex.replaceAll('#', '');
      if (h.length == 6) h = 'ff$h';
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return Colors.yellow.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('annotations_title'.translate),
        actions: [
          IconButton(
            icon: const Icon(Icons.code_rounded),
            tooltip: 'export_json'.translate,
            onPressed: _annotations.isEmpty ? null : _exportJson,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'export_markdown'.translate,
            onPressed: _annotations.isEmpty ? null : _exportMarkdown,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _annotations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_quote_rounded, size: 64, color: colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        'no_annotations'.translate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _annotations.length,
                  itemBuilder: (ctx, idx) {
                    final item = _annotations[idx];
                    final color = _parseHex(item.colorHex);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.createdAt.split('T').first,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _deleteAnnotation(item.id),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.selectedText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.edit_note, size: 18, color: colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.note,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
