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
