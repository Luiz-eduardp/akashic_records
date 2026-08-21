import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/db/repositories/annotations_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnnotationDialog extends StatefulWidget {
  final String novelId;
  final String chapterId;
  final String selectedText;

  const AnnotationDialog({
    super.key,
    required this.novelId,
    required this.chapterId,
    required this.selectedText,
  });

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedColor = '#FDE047';
  bool _isLoadingDict = false;
  bool _isLoadingTrans = false;
  String? _dictionaryDefinition;
  String? _translationResult;

  final List<Map<String, String>> _colors = [
    {'name': 'Yellow', 'hex': '#FDE047'},
    {'name': 'Green', 'hex': '#86EFAC'},
    {'name': 'Blue', 'hex': '#93C5FD'},
    {'name': 'Pink', 'hex': '#F472B6'},
    {'name': 'Orange', 'hex': '#FDBA74'},
  ];

  Future<void> _saveAnnotation() async {
    try {
      final db = await NovelDatabase.getInstance();
      final annotation = Annotation(
        id: const Uuid().v4(),
        novelId: widget.novelId,
        chapterId: widget.chapterId,
        selectedText: widget.selectedText,
        note: _noteController.text.trim(),
        colorHex: _selectedColor,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.annotations.addAnnotation(annotation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('done'.translate)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save annotation: $e')),
        );
      }
    }
  }

  Future<void> _lookupDictionary() async {
    final cleanWord = widget.selectedText.trim().split(RegExp(r'\s+')).first;
    if (cleanWord.isEmpty) return;

    setState(() {
      _isLoadingDict = true;
      _dictionaryDefinition = null;
    });

    try {
      final uri = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$cleanWord');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        if (data.isNotEmpty && data[0]['meanings'] != null) {
          final meanings = data[0]['meanings'] as List;
          final buffer = StringBuffer();
          for (final m in meanings.take(2)) {
            final partOfSpeech = m['partOfSpeech'] ?? '';
            final defs = m['definitions'] as List?;
            if (defs != null && defs.isNotEmpty) {
              buffer.writeln('• ($partOfSpeech) ${defs[0]['definition']}');
            }
          }
          setState(() {
            _dictionaryDefinition = buffer.toString().trim();
          });
        }
      } else {
        setState(() {
          _dictionaryDefinition = 'No definition found for "$cleanWord"';
        });
      }
    } catch (e) {
      setState(() {
        _dictionaryDefinition = 'Error looking up dictionary: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoadingDict = false);
    }
  }

  Future<void> _translateText() async {
    final text = widget.selectedText.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoadingTrans = true;
      _translationResult = null;
    });

    try {
      final targetLang = I18n.currentLocale.languageCode;
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=autodetect|$targetLang',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final translatedText = data['responseData']?['translatedText'];
        setState(() {
          _translationResult = translatedText ?? 'Translation unavailable';
        });
      } else {
        setState(() {
          _translationResult = 'Translation service unavailable';
        });
      }
    } catch (e) {
      setState(() {
        _translationResult = 'Translation error: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoadingTrans = false);
    }
  }

  Color _parseHex(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'ff$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'annotations_title'.translate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _parseHex(_selectedColor).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _parseHex(_selectedColor)),
              ),
              child: Text(
                widget.selectedText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'add_highlight'.translate,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _colors.map((c) {
                      final isSel = _selectedColor == c['hex'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = c['hex']!),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _parseHex(c['hex']!),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? colorScheme.primary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isSel
                              ? const Icon(Icons.check, size: 18, color: Colors.black87)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'add_note'.translate,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingDict ? null : _lookupDictionary,
                    icon: _isLoadingDict
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.menu_book_rounded, size: 18),
                    label: Text('dictionary_lookup'.translate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingTrans ? null : _translateText,
                    icon: _isLoadingTrans
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.g_translate_rounded, size: 18),
                    label: Text('translate_text'.translate),
                  ),
                ),
              ],
            ),
            if (_dictionaryDefinition != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dictionary_lookup'.translate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_dictionaryDefinition!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            if (_translationResult != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'translate_text'.translate,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_translationResult!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveAnnotation,
                child: Text('save'.translate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
