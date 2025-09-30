import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:akashic_records/screens/reader/script_store_tab.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_fonts/google_fonts.dart';

typedef ReaderConfig = Map<String, dynamic>;

class ReaderConfigModal extends StatefulWidget {
  final ReaderConfig config;
  final ValueChanged<ReaderConfig> onChange;
  final ValueChanged<List<String>>? onApplyScripts;
  final ValueChanged<String>? onRemoveScript;

  const ReaderConfigModal({
    super.key,
    required this.config,
    required this.onChange,
    this.onApplyScripts,
    this.onRemoveScript,
  });

  @override
  State<ReaderConfigModal> createState() => _ReaderConfigModalState();
}

class _ReaderConfigModalState extends State<ReaderConfigModal> {
  late ReaderConfig temp;

  @override
  void initState() {
    super.initState();
    temp = Map<String, dynamic>.from(widget.config);
  }

  void _apply() {
    widget.onChange(Map<String, dynamic>.from(temp));
  }

  TextStyle _previewStyle() {
    final size =
        (temp['fontSize'] is num) ? (temp['fontSize'] as num).toDouble() : 18.0;
    final lh =
        (temp['lineHeight'] is num)
            ? (temp['lineHeight'] as num).toDouble()
            : 1.6;
    final weightVal =
        (temp['fontWeight'] is num)
            ? (temp['fontWeight'] as num).toInt()
            : ((temp['fontBold'] ?? false) ? 700 : 400);
    final bold = (temp['fontBold'] ?? false) as bool;
    Color? color;
    try {
      if (temp['fontColor'] != null) {
        color = Color(
          int.parse((temp['fontColor'] as String).replaceFirst('#', '0xff')),
        );
      }
    } catch (_) {}

    final fam = (temp['fontFamily'] as String?) ?? 'serif';
    TextStyle base;
    switch (fam) {
      case 'Merriweather':
        base = GoogleFonts.merriweather(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'Lora':
        base = GoogleFonts.lora(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'Roboto':
        base = GoogleFonts.roboto(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'Inter':
        base = GoogleFonts.inter(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'Open Sans':
        base = GoogleFonts.openSans(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'Roboto Mono':
        base = GoogleFonts.robotoMono(
          fontSize: size,
          height: lh,
          fontWeight: FontWeight.values[(weightVal ~/ 100) - 1],
        );
        break;
      case 'serif':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight:
              bold
                  ? FontWeight.bold
                  : FontWeight.values[(weightVal ~/ 100) - 1],
          fontFamily: 'serif',
        );
        break;
      case 'sans-serif':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight:
              bold
                  ? FontWeight.bold
                  : FontWeight.values[(weightVal ~/ 100) - 1],
          fontFamily: 'sans-serif',
        );
        break;
      case 'monospace':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight:
              bold
                  ? FontWeight.bold
                  : FontWeight.values[(weightVal ~/ 100) - 1],
          fontFamily: 'monospace',
        );
        break;
      default:
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight:
              bold
                  ? FontWeight.bold
                  : FontWeight.values[(weightVal ~/ 100) - 1],
          fontFamily: fam,
        );
    }
    if (color != null) base = base.copyWith(color: color);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'settings'.translate),
              Tab(text: 'script_store'.translate),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TabBarView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('preview'.translate),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                color: Theme.of(context).colorScheme.background,
                                child: Text(
                                  'The quick brown fox jumps over the lazy dog',
                                  style: _previewStyle(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'reader_settings_title'.translate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text('', style: const TextStyle())),
                            IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                _apply();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('alignment'.translate),
                        Row(
                          children: [
                            ChoiceChip(
                              label: Text('left'.translate),
                              selected: (temp['align'] ?? 'left') == 'left',
                              onSelected: (v) {
                                setState(() => temp['align'] = 'left');
                                _apply();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('center'.translate),
                              selected: (temp['align'] ?? 'left') == 'center',
                              onSelected: (v) {
                                setState(() => temp['align'] = 'center');
                                _apply();
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('justify'.translate),
                              selected: (temp['align'] ?? 'left') == 'justify',
                              onSelected: (v) {
                                setState(() => temp['align'] = 'justify');
                                _apply();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('font'.translate),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text('serif'.translate),
                              selected:
                                  (temp['fontFamily'] ?? 'serif') == 'serif',
                              onSelected: (v) {
                                setState(() => temp['fontFamily'] = 'serif');
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('sans'.translate),
                              selected:
                                  (temp['fontFamily'] ?? 'serif') ==
                                  'sans-serif',
                              onSelected: (v) {
                                setState(
                                  () => temp['fontFamily'] = 'sans-serif',
                                );
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('mono'.translate),
                              selected:
                                  (temp['fontFamily'] ?? 'serif') ==
                                  'monospace',
                              onSelected: (v) {
                                setState(
                                  () => temp['fontFamily'] = 'monospace',
                                );
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('merriweather'.translate),
                              selected:
                                  (temp['fontFamily'] ?? '') == 'Merriweather',
                              onSelected: (v) {
                                setState(
                                  () => temp['fontFamily'] = 'Merriweather',
                                );
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('lora'.translate),
                              selected: (temp['fontFamily'] ?? '') == 'Lora',
                              onSelected: (v) {
                                setState(() => temp['fontFamily'] = 'Lora');
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('roboto'.translate),
                              selected: (temp['fontFamily'] ?? '') == 'Roboto',
                              onSelected: (v) {
                                setState(() => temp['fontFamily'] = 'Roboto');
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('inter'.translate),
                              selected: (temp['fontFamily'] ?? '') == 'Inter',
                              onSelected: (v) {
                                setState(() => temp['fontFamily'] = 'Inter');
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('open_sans'.translate),
                              selected:
                                  (temp['fontFamily'] ?? '') == 'Open Sans',
                              onSelected: (v) {
                                setState(
                                  () => temp['fontFamily'] = 'Open Sans',
                                );
                                _apply();
                              },
                            ),
                            ChoiceChip(
                              label: Text('roboto_mono'.translate),
                              selected:
                                  (temp['fontFamily'] ?? '') == 'Roboto Mono',
                              onSelected: (v) {
                                setState(
                                  () => temp['fontFamily'] = 'Roboto Mono',
                                );
                                _apply();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${'font_size'.translate}: ${(temp['fontSize'] ?? 18).toString()}',
                        ),
                        Slider(
                          min: 12,
                          max: 36,
                          value: (temp['fontSize'] ?? 18).toDouble(),
                          onChanged: (v) {
                            setState(() => temp['fontSize'] = v.round());
                            _apply();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'spacing'.translate}: ${(temp['lineHeight'] ?? 1.6).toStringAsFixed(1)}',
                        ),
                        Slider(
                          min: 1.0,
                          max: 2.4,
                          value: (temp['lineHeight'] ?? 1.6).toDouble(),
                          onChanged: (v) {
                            final rounded = (v * 10).round() / 10.0;
                            setState(() => temp['lineHeight'] = rounded);
                            _apply();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'padding'.translate}: ${(temp['padding'] ?? 12).toStringAsFixed(0)}',
                        ),
                        Slider(
                          min: 4,
                          max: 36,
                          value: (temp['padding'] ?? 12).toDouble(),
                          onChanged: (v) {
                            setState(() => temp['padding'] = v);
                            _apply();
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: Text('font_weight'.translate)),
                            Text((temp['fontWeight'] ?? 400).toString()),
                          ],
                        ),
                        Slider(
                          min: 100,
                          max: 900,
                          divisions: 8,
                          value: (temp['fontWeight'] ?? 400).toDouble(),
                          onChanged: (v) {
                            setState(() => temp['fontWeight'] = v.round());
                            _apply();
                          },
                        ),
                        Row(
                          children: [
                            Text('bold'.translate),
                            const SizedBox(width: 8),
                            Switch(
                              value: (temp['fontBold'] ?? false) as bool,
                              onChanged: (v) {
                                setState(() => temp['fontBold'] = v);
                                if (v) temp['fontWeight'] = 700;
                                _apply();
                              },
                            ),
                          ],
                        ),
                        Text('text_color'.translate),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final initial =
                                    temp['fontColor'] != null
                                        ? Color(
                                          int.parse(
                                            (temp['fontColor'] as String)
                                                .replaceFirst('#', '0xff'),
                                          ),
                                        )
                                        : Colors.black;
                                Color picked = initial;
                                await showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      title: Text(
                                        'select_text_color'.translate,
                                      ),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: initial,
                                          onColorChanged: (c) => picked = c,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: Text('ok'.translate),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                setState(() {
                                  temp['fontColor'] =
                                      '#${picked.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                                });
                                _apply();
                              },
                              child: Text('choose'.translate),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('default'.translate),
                              selected: (temp['fontColor'] == null),
                              onSelected: (v) {
                                setState(() => temp.remove('fontColor'));
                                _apply();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('background_color'.translate),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final initial =
                                    temp['bgColor'] != null
                                        ? Color(
                                          int.parse(
                                            (temp['bgColor'] as String)
                                                .replaceFirst('#', '0xff'),
                                          ),
                                        )
                                        : Colors.white;
                                Color picked = initial;
                                await showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      title: Text('select_bg_color'.translate),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: initial,
                                          onColorChanged: (c) => picked = c,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: Text('ok'.translate),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                setState(() {
                                  temp['bgColor'] =
                                      '#${picked.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                                });
                                _apply();
                              },
                              child: Text('choose'.translate),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('default'.translate),
                              selected: (temp['bgColor'] == null),
                              onSelected: (v) {
                                setState(() => temp.remove('bgColor'));
                                _apply();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${'text_brightness'.translate}: ${(temp['textBrightness'] ?? 1.0).toStringAsFixed(2)}',
                        ),
                        Slider(
                          min: 0.5,
                          max: 2.0,
                          value: (temp['textBrightness'] ?? 1.0).toDouble(),
                          onChanged: (v) {
                            setState(() => temp['textBrightness'] = v);
                            _apply();
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                ScriptStoreTab(
                  prefs: temp,
                  onToggle: (enabledScripts) {
                    setState(() => temp['enabledScripts'] = enabledScripts);
                    _apply();
                    if (widget.onApplyScripts != null)
                      widget.onApplyScripts!(enabledScripts);
                  },
                  onRemoveScript: widget.onRemoveScript,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
