import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:akashic_records/screens/reader/script_store_tab.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:akashic_records/services/reader_tts.dart';

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
  List<String> _availableLangs = [];
  String? _selectedLang;
  bool _langsLoading = false;

  @override
  void initState() {
    super.initState();
    temp = Map<String, dynamic>.from(widget.config);
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    setState(() => _langsLoading = true);
    try {
      final langs = await ReaderTts().getLanguages();
      if (langs != null && langs.isNotEmpty) {
        String normalizeLang(dynamic v) {
          try {
            var s = v.toString().trim();
            s = s.replaceAll('_', '-').replaceAll(RegExp(r'-+'), '-');
            s = s.replaceAll(RegExp(r'(^-+|-+$)'), '');
            if (s.isEmpty) return '';
            final parts = s.split('-');
            if (parts.length == 1) return parts[0].toLowerCase();
            final lang = parts[0].toLowerCase();
            final region = parts.sublist(1).join('-').toUpperCase();
            return '$lang-$region';
          } catch (_) {
            return v.toString().trim();
          }
        }

        final seen = <String>{};
        final list = <String>[];
        for (final e in langs) {
          final n = normalizeLang(e);
          if (n.isEmpty) continue;
          if (!seen.contains(n)) {
            seen.add(n);
            list.add(n);
          }
        }
        _availableLangs = list;
      }
    } catch (_) {}
    if (_availableLangs.isEmpty) {
      _availableLangs = ['en-US', 'pt-BR', 'es-ES', 'fr-FR', 'ja-JP', 'ar'];
    }
    final prefLang =
        (temp['tts'] is Map) ? (temp['tts']['language'] as String?) : null;
    if (prefLang != null && _availableLangs.contains(prefLang)) {
      _selectedLang = prefLang;
    } else {
      _selectedLang = _availableLangs.isNotEmpty ? _availableLangs.first : null;
      if (prefLang != null) {
        temp['tts'] =
            (temp['tts'] is Map) ? Map<String, dynamic>.from(temp['tts']) : {};
        temp['tts']['language'] = _selectedLang;
      }
    }
    setState(() => _langsLoading = false);
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
  int weightIdx = (weightVal ~/ 100) - 1;
  if (weightIdx < 0) weightIdx = 0;
  if (weightIdx >= FontWeight.values.length) weightIdx = FontWeight.values.length - 1;
  final resolvedWeight = bold ? FontWeight.bold : FontWeight.values[weightIdx];
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
          fontWeight: resolvedWeight,
        );
        break;
      case 'Lora':
        base = GoogleFonts.lora(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
        );
        break;
      case 'Roboto':
        base = GoogleFonts.roboto(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
        );
        break;
      case 'Inter':
        base = GoogleFonts.inter(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
        );
        break;
      case 'Open Sans':
        base = GoogleFonts.openSans(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
        );
        break;
      case 'Roboto Mono':
        base = GoogleFonts.robotoMono(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
        );
        break;
      case 'serif':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
          fontFamily: 'serif',
        );
        break;
      case 'sans-serif':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
          fontFamily: 'sans-serif',
        );
        break;
      case 'monospace':
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
          fontFamily: 'monospace',
        );
        break;
      default:
        base = TextStyle(
          fontSize: size,
          height: lh,
          fontWeight: resolvedWeight,
          fontFamily: fam,
        );
    }
    if (color != null) base = base.copyWith(color: color);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'settings'.translate),
              Tab(text: 'appearance'.translate),
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
                            final w = v.round();
                            setState(() {
                              temp['fontWeight'] = w;
                              temp['fontBold'] = (w >= 700);
                            });
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
                                setState(() {
                                  temp['fontBold'] = v;
                                  temp['fontWeight'] = v ? 700 : 400;
                                });
                                _apply();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        Text(
                          'tts_settings'.translate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('language'.translate),
                        _langsLoading
                            ? const SizedBox(
                              height: 48,
                              child: Center(child: CircularProgressIndicator()),
                            )
                            : Builder(
                              builder: (ctx) {
                                final items =
                                    _availableLangs
                                        .map(
                                          (l) => DropdownMenuItem(
                                            value: l,
                                            child: Text(l),
                                          ),
                                        )
                                        .toList();
                                String? effectiveValue;
                                if (items.isNotEmpty) {
                                  if (_selectedLang != null &&
                                      items
                                              .where(
                                                (it) =>
                                                    it.value == _selectedLang,
                                              )
                                              .length ==
                                          1) {
                                    effectiveValue = _selectedLang;
                                  } else {
                                    effectiveValue = items.first.value;
                                    temp['tts'] =
                                        (temp['tts'] is Map)
                                            ? Map<String, dynamic>.from(
                                              temp['tts'],
                                            )
                                            : {};
                                    temp['tts']['language'] = effectiveValue;
                                    _selectedLang = effectiveValue;
                                  }
                                } else {
                                  effectiveValue = null;
                                }
                                return DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  items: items,
                                  value: effectiveValue,
                                  onChanged: (v) {
                                    if (v == null) return;
                                    temp['tts'] =
                                        (temp['tts'] is Map)
                                            ? Map<String, dynamic>.from(
                                              temp['tts'],
                                            )
                                            : {};
                                    temp['tts']['language'] = v;
                                    _selectedLang = v;
                                    _apply();
                                  },
                                );
                              },
                            ),
                        const SizedBox(height: 8),
                        Text(
                          '${'tts_rate'.translate}: ${((temp['tts'] is Map ? (temp['tts']['rate'] ?? 0.8) : 0.8) as num).toDouble().toStringAsFixed(2)}',
                        ),
                        Slider(
                          min: 0.1,
                          max: 1.5,
                          value:
                              (temp['tts'] is Map)
                                  ? ((temp['tts']['rate'] ?? 0.8) as num)
                                      .toDouble()
                                  : 0.8,
                          onChanged: (v) {
                            temp['tts'] =
                                (temp['tts'] is Map)
                                    ? Map<String, dynamic>.from(temp['tts'])
                                    : {};
                            temp['tts']['rate'] = v;
                            _apply();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'tts_volume'.translate}: ${((temp['tts'] is Map ? (temp['tts']['volume'] ?? 1.0) : 1.0) as num).toDouble().toStringAsFixed(2)}',
                        ),
                        Slider(
                          min: 0.0,
                          max: 1.0,
                          value:
                              (temp['tts'] is Map)
                                  ? ((temp['tts']['volume'] ?? 1.0) as num)
                                      .toDouble()
                                  : 1.0,
                          onChanged: (v) {
                            temp['tts'] =
                                (temp['tts'] is Map)
                                    ? Map<String, dynamic>.from(temp['tts'])
                                    : {};
                            temp['tts']['volume'] = v;
                            _apply();
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${'tts_pitch'.translate}: ${((temp['tts'] is Map ? (temp['tts']['pitch'] ?? 1.0) : 1.0) as num).toDouble().toStringAsFixed(2)}',
                        ),
                        Slider(
                          min: 0.5,
                          max: 2.0,
                          value:
                              (temp['tts'] is Map)
                                  ? ((temp['tts']['pitch'] ?? 1.0) as num)
                                      .toDouble()
                                  : 1.0,
                          onChanged: (v) {
                            temp['tts'] =
                                (temp['tts'] is Map)
                                    ? Map<String, dynamic>.from(temp['tts'])
                                    : {};
                            temp['tts']['pitch'] = v;
                            _apply();
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'appearance'.translate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('theme_presets'.translate),
                        const SizedBox(height: 8),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.1,
                          children:
                              _presetThemes().map((t) {
                                final bg = t['bg'] as String;
                                final fg = t['fg'] as String;
                                final keyName = t['key'] as String;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      temp['bgColor'] = bg;
                                      temp['fontColor'] = fg;
                                    });
                                    _apply();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(
                                        int.parse(
                                          '0xff${bg.replaceFirst('#', '')}',
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          keyName.translate,
                                          style: TextStyle(
                                            color: Color(
                                              int.parse(
                                                '0xff${fg.replaceFirst('#', '')}',
                                              ),
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'AaBbCc',
                                          style: TextStyle(
                                            color: Color(
                                              int.parse(
                                                '0xff${fg.replaceFirst('#', '')}',
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text('custom_colors'.translate),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                              child: Text('choose_text_color'.translate),
                            ),
                            const SizedBox(width: 8),
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
                              child: Text('choose_bg_color'.translate),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('default'.translate),
                              selected:
                                  (temp['bgColor'] == null &&
                                      temp['fontColor'] == null),
                              onSelected: (v) {
                                setState(() {
                                  temp.remove('bgColor');
                                  temp.remove('fontColor');
                                });
                                _apply();
                              },
                            ),
                          ],
                        ),
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

  List<Map<String, String>> _presetThemes() {
    return [
      {"key": "theme_default_classic", "bg": "#FFFFFF", "fg": "#000000"},
      {"key": "theme_aged_sepia", "bg": "#F4ECD8", "fg": "#2B2B2B"},
      {"key": "theme_deep_night", "bg": "#0A0A0A", "fg": "#F8F8F8"},
      {"key": "theme_solar_terminal", "bg": "#002B36", "fg": "#839496"},
      {"key": "theme_midnight_nebula", "bg": "#0B1220", "fg": "#DDE6F0"},
      {"key": "theme_old_wood", "bg": "#1E1B18", "fg": "#E6D7C3"},
      {"key": "theme_soft_vanilla", "bg": "#FFF9E6", "fg": "#3B3A32"},
      {"key": "theme_noble_ivory", "bg": "#FFFFF0", "fg": "#2B2B2B"},
      {"key": "theme_papyrus_scroll", "bg": "#F6F3EA", "fg": "#2A2A28"},
      {"key": "theme_antique_print", "bg": "#EFE6D6", "fg": "#3C2F2F"},
      {"key": "theme_morning_mist", "bg": "#F2F2F4", "fg": "#333333"},
      {"key": "theme_calm_horizon", "bg": "#EAF4FF", "fg": "#16324F"},
      {"key": "theme_atlantic_depth", "bg": "#E8F6F9", "fg": "#05445E"},
      {"key": "theme_forest_moss", "bg": "#EFFAF1", "fg": "#0B3D2E"},
      {"key": "theme_mint_breeze", "bg": "#E8FFF4", "fg": "#174A3A"},
      {"key": "theme_violet_dusk", "bg": "#F5F0FF", "fg": "#2E1A47"},
      {"key": "theme_rose_petal", "bg": "#FFF0F2", "fg": "#4A1F2F"},
      {"key": "theme_afternoon_blush", "bg": "#FFF3F1", "fg": "#4A2F2B"},
      {"key": "theme_grey_stone", "bg": "#ECECEC", "fg": "#2E2E2E"},
      {"key": "theme_activated_charcoal", "bg": "#1E1E1E", "fg": "#E6E6E6"},
      {"key": "theme_night_slate", "bg": "#0F1724", "fg": "#CFE8FF"},
      {"key": "theme_green_tea", "bg": "#F6FFF2", "fg": "#214F3A"},
      {"key": "theme_hot_cocoa", "bg": "#F7ECE1", "fg": "#3D2C23"},
      {"key": "theme_aged_copper", "bg": "#FFF6EE", "fg": "#4B2E2E"},
      {"key": "theme_ebony_high_contrast", "bg": "#0A0A0A", "fg": "#F5F5F5"},
      {"key": "theme_open_sky", "bg": "#EAF6FF", "fg": "#0B3A66"},
      {"key": "theme_orange_sunset", "bg": "#FFF2E6", "fg": "#6B2E00"},
      {"key": "theme_golden_honey", "bg": "#FFF7E0", "fg": "#5A3E1B"},
      {"key": "theme_ancient_parchment", "bg": "#FAF3E0", "fg": "#3B3226"},
      {"key": "theme_soft_olive", "bg": "#F2F6EA", "fg": "#2E3A19"},
      {"key": "theme_deep_navy", "bg": "#071A2F", "fg": "#DCECF9"},
      {"key": "theme_light_granite", "bg": "#ECEFF1", "fg": "#202124"},
      {"key": "theme_pure_vanilla", "bg": "#FFFBF0", "fg": "#2F2A20"},
      {"key": "theme_soft_coral", "bg": "#FFF6F5", "fg": "#7A2B2B"},
      {"key": "theme_water_moss", "bg": "#EDF7ED", "fg": "#1F4D2A"},
      {"key": "theme_midnight_blue", "bg": "#001328", "fg": "#DCECF9"},
      {"key": "theme_sketch_paper", "bg": "#F7F7F9", "fg": "#2D2D2D"},
    ];
  }
}
