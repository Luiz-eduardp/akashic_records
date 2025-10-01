import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:akashic_records/models/model.dart';
import 'package:http/http.dart' as http;
import 'package:akashic_records/db/novel_database.dart';
import 'package:akashic_records/widgets/chapter_list.dart';
import 'package:akashic_records/services/plugin_registry.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/services.dart';
import 'package:battery_plus/battery_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'package:akashic_records/screens/reader/reader_subheader.dart';
import 'package:akashic_records/screens/reader/reader_config_modal.dart';
import 'package:akashic_records/services/reader_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Novel novel;
  int selectedChapter = 0;
  WebViewController? _controller;
  bool _argsHandled = false;
  List<Map<String, dynamic>> _presets = [];
  late Map<String, dynamic> _prefs;
  double _scrollProgress = 0.0;
  double _lastSavedProgress = 0.0;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);
  final ReaderTts _tts = ReaderTts();
  FlutterLocalNotificationsPlugin? _localNotif;
  bool _ttsPlaying = false;
  int _wordCountCached = 0;
  String _currentTime = '';
  int _batteryLevel = -1;
  bool _isLoading = true;

  Future<void> _saveReaderPrefs() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.setReaderPrefs(_prefs);
  }

  Map<String, dynamic> _getDefaultPrefs() {
    return {
      'presetIndex': 0,
      'fontSize': 18.0,
      'lineHeight': 1.6,
      'fontFamily': 'serif',
      'padding': 12.0,
      'align': 'left',
      'focusMode': false,
      'focusBlur': 6,
      'textBrightness': 1.0,
      'fontColor': null,
      'bgColor': null,
      'fullscreen': false,
      'enabledScripts': <String>[],
    };
  }

  Future<void> _removeScriptFromWebView(String scriptName) async {
    try {
      final uri = Uri.parse('https://api.npoint.io/bcd94c36fa7f3bf3b1e6');
      final resp = await http.read(uri);
      final Map<String, dynamic> data =
          jsonDecode(resp) as Map<String, dynamic>;
      final List scripts = data['scripts'] as List? ?? [];
      final match = scripts.firstWhere(
        (s) => (s['name'] ?? s['use']) == scriptName,
        orElse: () => null,
      );
      if (match != null) {
        final removeJs = '''
          (function(){
            try {
              if (window['$scriptName']) { window['$scriptName'] = undefined; }
              var style = document.getElementById('scriptstore-style-$scriptName');
              if (style) { style.remove(); }
              if (window['scriptstoreCleanup_$scriptName']) { window['scriptstoreCleanup_$scriptName'](); }
            } catch(e) {}
          })();
        ''';
        await _controller!.runJavaScript(removeJs);
      }
    } catch (e) {
      print('Falha ao remover script do WebView: $e');
    }
  }

  Timer? _timeTimer;
  Timer? _batteryTimer;
  final Battery _battery = Battery();

  Future<void> _setFullscreenMode(bool enabled) async {
    if (enabled) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsHandled) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Map) {
      final maybeNovel = arg['novel'];
      final maybeIdx = arg['chapterIndex'];
      if (maybeNovel is Novel) novel = maybeNovel;
      if (maybeIdx is int) selectedChapter = maybeIdx;
    } else if (arg is Novel) {
      novel = arg;
    } else {
      novel = Novel(
        id: '0',
        title: 'unknown'.translate,
        coverImageUrl: '',
        author: '',
        description: '',
        chapters: [],
        pluginId: '',
        genres: [],
      );
    }
    _argsHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initReader();
      _loadChapter();
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _initReader() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final prefs = appState.getReaderPrefs();
    _prefs = prefs.isNotEmpty ? prefs : _getDefaultPrefs();

    if (_controller == null) {
      _controller =
          WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
      try {
        _controller!.addJavaScriptChannel(
          'Scroll',
          onMessageReceived: (msg) {
            _handleScrollMessage(msg.message);
          },
        );
      } catch (_) {}
      await _controller!.loadHtmlString(
        '<html><body><h2>Loading...</h2></body></html>',
      );
    }

    _buildPresets();
    _startTimers();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final enabledScripts =
          (prefs['enabledScripts'] is List)
              ? List<String>.from(prefs['enabledScripts'])
              : <String>[];
      if (enabledScripts.isNotEmpty) {
        await _applyScriptsToWebView(enabledScripts);
      }
      _initTtsAndNotifications();
    });
  }

  void _initTtsAndNotifications() async {
    try {
      _tts.onComplete = () async {
        final idx = _currentIndex();
        if (idx >= 0 && idx < novel.chapters.length - 1) {
          setState(() => selectedChapter = idx + 1);
          await _loadChapter();
          Future.delayed(const Duration(milliseconds: 800), () async {
            await _startTtsForCurrentChapter();
          });
        } else {
          _ttsPlaying = false;
          _showTtsNotification(false);
        }
      };
      _tts.onStart = () {
        _ttsPlaying = true;
        _showTtsNotification(true);
      };
      _localNotif = FlutterLocalNotificationsPlugin();
      final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings();
      await _localNotif!.initialize(
        InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (resp) async {
          final payload = resp.payload ?? '';
          if (payload == 'toggle') {
            if (_ttsPlaying) {
              await _tts.pause();
              _ttsPlaying = false;
              _showTtsNotification(false);
            } else {
              await _tts.resume();
              _ttsPlaying = true;
              _showTtsNotification(true);
            }
          } else if (payload == 'next_para') {
            await _scrollToNextParagraph();
          } else if (payload == 'prev_para') {
            await _scrollToPreviousParagraph();
          }
        },
      );
    } catch (_) {}
  }

  void _startTimers() {
    _currentTime = _formatTime(DateTime.now());
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _currentTime = _formatTime(DateTime.now()));
    });
    _updateBattery();
    _batteryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateBattery(),
    );
  }

  Future<void> _updateBattery() async {
    try {
      final level = await _battery.batteryLevel;
      setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _handleScrollMessage(String message) {
    try {
      final Map<String, dynamic> m =
          message.isNotEmpty
              ? Map<String, dynamic>.from(jsonDecode(message) as Map)
              : {};
      final pos = (m['pos'] as num?)?.toDouble() ?? 0.0;
      final max = (m['max'] as num?)?.toDouble() ?? 1.0;
      final progress = max > 0 ? (pos / max).clamp(0.0, 1.0) : 0.0;
      setState(() => _scrollProgress = progress);

      try {
        final now = DateTime.now();
        final diff = (progress - _lastSavedProgress).abs();
        final elapsed = now.difference(_lastSavedAt).inMilliseconds;
        if (diff >= 0.01 || elapsed > 5000) {
          _lastSavedProgress = progress;
          _lastSavedAt = now;
          if (novel != null && novel.chapters.isNotEmpty) {
            final chapter = novel.chapters[selectedChapter];
            final key = 'scroll_${novel.id}_${chapter.id}';
            NovelDatabase.getInstance().then((db) async {
              try {
                await db.setSetting(key, progress.toString());
              } catch (_) {}
            });
          }
        }
      } catch (_) {}
    } catch (e) {}
  }

  Future<void> _showTtsNotification(bool playing) async {
    try {
      if (_localNotif == null) return;
      final androidDetails = AndroidNotificationDetails(
        'tts_channel',
        'TTS',
        channelDescription: 'Reader TTS controls',
        importance: Importance.low,
        playSound: false,
        ongoing: true,
        styleInformation: MediaStyleInformation(),
      );
      final iosDetails = DarwinNotificationDetails();
      final settings = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final action = playing ? 'Pause' : 'Play';
      await _localNotif!.show(
        777,
        'TTS: ${novel.title}',
        action,
        settings,
        payload: 'toggle',
      );
    } catch (e) {
      print('Failed to show notification: $e');
    }
  }

  void _buildPresets() {
    _presets = [
      {
        'name': 'Light 1',
        'bg': '#FFFFFF',
        'fg': '#222222',
        'accent': '#1E88E5',
      },
      {
        'name': 'Light 2',
        'bg': '#FAF8F6',
        'fg': '#222222',
        'accent': '#8E24AA',
      },
      {
        'name': 'Light 3',
        'bg': '#FFF8E1',
        'fg': '#222222',
        'accent': '#FB8C00',
      },
      {
        'name': 'Light 4',
        'bg': '#F0F4C3',
        'fg': '#222222',
        'accent': '#43A047',
      },
      {
        'name': 'Light 5',
        'bg': '#ECEFF1',
        'fg': '#263238',
        'accent': '#607D8B',
      },
      {
        'name': 'Light 6',
        'bg': '#FFFFFF',
        'fg': '#333333',
        'accent': '#607D8B',
      },
      {
        'name': 'Light 7',
        'bg': '#FFFDE7',
        'fg': '#222222',
        'accent': '#FBC02D',
      },
      {
        'name': 'Light 8',
        'bg': '#FFF3E0',
        'fg': '#334155',
        'accent': '#FB8C00',
      },
      {
        'name': 'Light 10',
        'bg': '#F7F7F7',
        'fg': '#222222',
        'accent': '#1976D2',
      },
      {'name': 'Dark 1', 'bg': '#121212', 'fg': '#E0E0E0', 'accent': '#BB86FC'},
      {'name': 'Dark 2', 'bg': '#0D1117', 'fg': '#C9D1D9', 'accent': '#58A6FF'},
      {'name': 'Dark 3', 'bg': '#111827', 'fg': '#E6E6E6', 'accent': '#10B981'},
      {'name': 'Dark 4', 'bg': '#0B0F19', 'fg': '#E5E7EB', 'accent': '#F59E0B'},
      {'name': 'Dark 5', 'bg': '#1A1A1A', 'fg': '#F3F4F6', 'accent': '#EF4444'},
      {'name': 'Dark 6', 'bg': '#0F172A', 'fg': '#E6EEF8', 'accent': '#60A5FA'},
      {'name': 'Dark 7', 'bg': '#141414', 'fg': '#DDDDDD', 'accent': '#9CA3AF'},
      {'name': 'Dark 8', 'bg': '#101010', 'fg': '#EDEDED', 'accent': '#F472B6'},
      {'name': 'Dark 9', 'bg': '#0B0B0B', 'fg': '#EAEAEA', 'accent': '#34D399'},
      {
        'name': 'Dark 10',
        'bg': '#0A0A0A',
        'fg': '#F8F8F8',
        'accent': '#3B82F6',
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeReader();
  }

  Future<void> _initializeReader() async {
    await _initReader();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller == null) {
      return const Center(
        child: Text('Erro ao inicializar o WebViewController'),
      );
    }

    final appState = Provider.of<AppState>(context);

    if (_prefs == null || _prefs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isFullscreen = (_prefs['fullscreen'] as bool?) ?? false;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar:
            isFullscreen
                ? null
                : AppBar(
                  centerTitle: true,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          novel.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Previous',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _goToPrevious,
                    ),
                    IconButton(
                      tooltip: 'TTS play/pause',
                      icon: Icon(_ttsPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: () async {
                        try {
                          if (_ttsPlaying) {
                            await _tts.pause();
                            setState(() => _ttsPlaying = false);
                            _showTtsNotification(false);
                          } else {
                            await _startTtsForCurrentChapter();
                            setState(() => _ttsPlaying = true);
                          }
                        } catch (e) {}
                      },
                    ),
                    IconButton(
                      tooltip: 'Chapters',
                      icon: const Icon(Icons.list),
                      onPressed: _openChapterSelector,
                    ),
                    IconButton(
                      tooltip: 'Reader settings',
                      icon: const Icon(Icons.settings),
                      onPressed: _openConfigModal,
                    ),
                    IconButton(
                      tooltip: 'Next',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _goToNext,
                    ),
                  ],
                ),
        body: SafeArea(
          child: Column(
            children: [
              if (!isFullscreen)
                ReaderSubheader(
                  wordCount: _wordCountCached,
                  time: _currentTime,
                  batteryLevel: _batteryLevel,
                  progress: _scrollProgress,
                  accent: appState.accentColor,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                  ),
                  child: GestureDetector(
                    onDoubleTap: () async {
                      final current = (_prefs['fullscreen'] as bool?) ?? false;
                      final newVal = !current;
                      await _setFullscreenMode(newVal);
                      setState(() {
                        _prefs['fullscreen'] = newVal;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            newVal
                                ? 'Tela cheia ativada'
                                : 'Tela cheia desativada',
                          ),
                        ),
                      );
                    },
                    child: WebViewWidget(controller: _controller!),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openConfigModal({bool fullModal = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (c, sc) {
                return SingleChildScrollView(
                  controller: sc,
                  child: ReaderConfigModal(
                    config: _prefs,
                    onChange: (cfg) async {
                      _prefs = Map<String, dynamic>.from(cfg);
                      await _saveReaderPrefs();
                      setState(() {});
                      _loadChapter();
                    },
                    onApplyScripts: (enabledScripts) async {
                      _prefs['enabledScripts'] = enabledScripts;
                      await _saveReaderPrefs();
                      await _applyScriptsToWebView(enabledScripts);
                      setState(() {});
                    },
                    onRemoveScript: (scriptName) async {
                      await _removeScriptFromWebView(scriptName);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _wordCount(String html) {
    final text = html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    final words = text.split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty);
    return words.length;
  }

  Future<void> _loadChapter() async {
    if (_prefs == null) {
      await _initReader();
    }
    if (novel.chapters.isEmpty) return;
    final chapter = novel.chapters[selectedChapter];

    if (chapter.content == null || chapter.content!.trim().isEmpty) {
      final svc = PluginRegistry.get(novel.pluginId);
      if (svc != null) {
        try {
          final fetched = await svc.parseChapter(chapter.id);
          if (fetched != null && fetched.isNotEmpty) {
            chapter.content = fetched;
            try {
              final db = await NovelDatabase.getInstance();
              await db.upsertNovel(novel);
            } catch (e) {
              print('Failed to persist chapter content: $e');
            }
          }
        } catch (e) {
          print('Failed to fetch chapter content: $e');
        }
      }
    }

    final content = chapter.content ?? '<p>Empty</p>';
    final presetIndex =
        (_prefs['presetIndex'] is num)
            ? (_prefs['presetIndex'] as num).toInt()
            : 0;
    final preset = _presets[presetIndex % _presets.length];
    final bg = preset['bg'] as String;
    final fg = preset['fg'] as String;
    final fontSize =
        (_prefs['fontSize'] is num)
            ? (_prefs['fontSize'] as num).toDouble().toString()
            : '18.0';
    final lineHeight =
        (_prefs['lineHeight'] is num)
            ? (_prefs['lineHeight'] as num).toDouble().toString()
            : '1.6';
    final padding =
        (_prefs['padding'] is num)
            ? (_prefs['padding'] as num).toDouble().toString()
            : '12.0';
    final fontFamily = _prefs['fontFamily'] as String? ?? 'serif';

    final align = (_prefs['align'] as String?) ?? 'left';
    final focusMode = (_prefs['focusMode'] as bool?) ?? false;
    final focusBlur =
        (_prefs['focusBlur'] is num) ? (_prefs['focusBlur'] as num).toInt() : 6;

    final fontColorPref = (_prefs['fontColor'] as String?);
    final bgColorPref = (_prefs['bgColor'] as String?);
    final effectiveBg = bgColorPref ?? bg;
    final effectiveFg = fontColorPref ?? fg;
    final brightnessVal = (_prefs['textBrightness'] as double?) ?? 1.0;
    final opacityNorm = ((brightnessVal.clamp(0.5, 2.0) - 0.5) / (2.0 - 0.5))
        .clamp(0.0, 1.0);
    final textAlpha = (0.5 + opacityNorm * 0.5).clamp(0.0, 1.0);
    String fgRgba() {
      try {
        final colorStr = (fontColorPref ?? fg).replaceFirst('#', '');
        String hex = colorStr;
        if (hex.length == 6) hex = 'ff$hex';
        final intVal = int.parse(hex, radix: 16);
        final r = (intVal >> 16) & 0xFF;
        final g = (intVal >> 8) & 0xFF;
        final b = intVal & 0xFF;
        return 'rgba($r,$g,$b,${textAlpha.toStringAsFixed(3)})';
      } catch (e) {
        return effectiveFg;
      }
    }

    String fontImport = '';
    String cssFontFamily = fontFamily;
    final googleMap = {
      'Merriweather': 'Merriweather',
      'Lora': 'Lora',
      'Roboto': 'Roboto',
      'Inter': 'Inter',
      'Open Sans': 'Open+Sans',
      'Roboto Mono': 'Roboto+Mono',
    };
    if (googleMap.containsKey(fontFamily)) {
      fontImport =
          "@import url('https://fonts.googleapis.com/css2?family=${googleMap[fontFamily]}:wght@100;200;300;400;500;600;700;800;900&display=swap');";
      cssFontFamily = "'$fontFamily', serif";
    }

    final css = '''
      $fontImport
      body { background: $effectiveBg; color: ${fgRgba()}; font-size: ${fontSize}px; line-height: $lineHeight; padding: ${padding}px; font-family: $cssFontFamily; }
      img { max-width: 100%; height: auto; }
      a { color: ${preset['accent']}; }
      p, div { text-align: $align; }
  .para { transition: filter 220ms ease, opacity 220ms ease; filter: blur(${focusMode ? focusBlur : 0}px); opacity: ${textAlpha.toStringAsFixed(3)}; }
  .para.focus { opacity: 1; filter: none; }
    ''';

    String wrapped = content;
    if (focusMode) {
      wrapped = content.replaceAllMapped(
        RegExp(r'<p[^>]*>([\s\S]*?)<\/p>'),
        (m) => '<div class="para">${m[1]}</div>',
      );
    }
    final base =
        '<html><head><meta name="viewport" content="width=device-width, initial-scale=1"><style>$css</style></head><body><div class="reader-content">${focusMode ? wrapped : content}</div>';
    final scrollJs = '''
<script>
(function(){
  function findParagraphOffsets(){
    try{
      var paras = Array.from(document.querySelectorAll('p,div.para'));
      var offs = paras.map(function(p){ var r=p.getBoundingClientRect(); var top = (r.top + (window.scrollY||0)); return Math.floor(top); });
      return offs;
    }catch(e){ return []; }
  }
  function scrollToParagraph(offset){ try{ window.scrollTo(0, offset); }catch(e){} }
  window._akashic_findParagraphOffsets = findParagraphOffsets;
  window._akashic_scrollToParagraph = scrollToParagraph;
  function send(){
    try{
      var pos = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
      var max = Math.max(document.body.scrollHeight - window.innerHeight, 1);
      Scroll.postMessage(JSON.stringify({pos: pos, max: max}));
    }catch(e){}
  }
  var ticking = false;
  function updateFocus(){
    try{
      var paras = document.querySelectorAll('.para');
      if(!paras || paras.length==0) return;
      var topScroll = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
      var docHeight = document.body.scrollHeight || 0;
      if(topScroll < 200){
        for(var i=0;i<paras.length;i++) paras[i].classList.remove('focus');
        paras[0].classList.add('focus');
        return;
      }
      if(topScroll + window.innerHeight >= docHeight - 200){
        for(var i=0;i<paras.length;i++) paras[i].classList.remove('focus');
        paras[paras.length-1].classList.add('focus');
        return;
      }
      var mid = window.innerHeight/2 + topScroll;
      var best = null; var bestDist = 1e9; var bestIdx = -1;
      for(var i=0;i<paras.length;i++){
        var r = paras[i].getBoundingClientRect();
        if(!r || r.height===0) continue;
        var top = r.top + topScroll;
        var center = top + r.height/2;
        var d = Math.abs(center - mid);
        if(d < bestDist){ bestDist = d; best = paras[i]; bestIdx = i; }
      }
      for(var i=0;i<paras.length;i++){ paras[i].classList.remove('focus'); }
      if(best) {
        best.classList.add('focus');
      } else if(paras.length>0) {
        paras[0].classList.add('focus');
      }
    }catch(e){}
  }
  window.addEventListener('scroll', function(){
    if(!ticking){
      window.requestAnimationFrame(function(){ send(); if(${focusMode ? 'true' : 'false'}) updateFocus(); ticking = false; });
      ticking = true;
    }
  }, {passive:true});
  setTimeout(function(){ send(); if(${focusMode ? 'true' : 'false'}) updateFocus(); }, 500);
  setInterval(function(){ send(); if(${focusMode ? 'true' : 'false'}) updateFocus(); }, 1000);
})();
</script>
''';
    final html = '$base$scrollJs</body></html>';
    await _controller!.loadHtmlString(html);

    try {
      final db = await NovelDatabase.getInstance();
      final chapter = novel.chapters[selectedChapter];
      final key = 'scroll_${novel.id}_${chapter.id}';
      final saved = await db.getSetting(key);
      if (saved != null && saved.isNotEmpty) {
        final val = double.tryParse(saved);
        if (val != null && val > 0.0 && val <= 1.0) {
          Future.delayed(const Duration(milliseconds: 600), () async {
            try {
              final js =
                  "(function(){ try{ var y = Math.floor((document.body.scrollHeight - window.innerHeight) * ${val.toStringAsFixed(6)}); window.scrollTo(0, y); }catch(e){} })();";
              await _controller!.runJavaScript(js);
            } catch (_) {}
          });
        }
      }
    } catch (_) {}

    setState(() {
      _wordCountCached = _wordCount(content);
    });

    try {
      final db = await NovelDatabase.getInstance();
      await db.setChapterRead(novel.id, chapter.id, true);
      try {
        novel.lastReadChapterId = chapter.id;
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addOrUpdateNovel(novel);
      } catch (e) {
        try {
          await db.upsertNovel(novel);
        } catch (_) {}
      }
    } catch (e) {
      print('Failed to mark chapter read: $e');
    }
  }

  Future<void> _openChapterSelector() async {
    final db = await NovelDatabase.getInstance();
    Set<String> readSet = await db.getReadChaptersForNovel(novel.id);
    final result = await showModalBottomSheet<Chapter>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        String search = '';
        bool asc = true;
        List<Chapter> chapters = List.from(novel.chapters);
        List<Chapter> filtered = List.from(chapters);
        Timer? searchDebounce;

        void applyFilters(void Function(void Function()) setStateModal) {
          var list = List.of(chapters);
          if (search.isNotEmpty) {
            final q = search.toLowerCase();
            list =
                list.where((c) => c.title.toLowerCase().contains(q)).toList();
          }
          list.sort(
            (a, b) =>
                asc
                    ? (a.chapterNumber ?? 0).compareTo(b.chapterNumber ?? 0)
                    : (b.chapterNumber ?? 0).compareTo(a.chapterNumber ?? 0),
          );
          setStateModal(() => filtered = list);
        }

        return StatefulBuilder(
          builder: (ctx, setStateModal) {
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Capítulos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Buscar capítulos...',
                            ),
                            onChanged: (v) {
                              searchDebounce?.cancel();
                              searchDebounce = Timer(
                                const Duration(milliseconds: 200),
                                () {
                                  search = v;
                                  applyFilters(setStateModal);
                                },
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(asc ? Icons.sort_by_alpha : Icons.sort),
                          onPressed: () {
                            setStateModal(() {
                              asc = !asc;
                              applyFilters(setStateModal);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.done_all),
                          onPressed: () async {
                            for (final ch in chapters) {
                              await db.setChapterRead(novel.id, ch.id, true);
                            }
                            readSet = await db.getReadChaptersForNovel(
                              novel.id,
                            );
                            setStateModal(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(ctx).size.height * 0.55,
                    child: ChapterList(
                      chapters: filtered,
                      readChapters: readSet,
                      onTap: (ch, idx) {
                        Navigator.of(ctx).pop(ch);
                      },
                      onLongPressToggleRead: (ch, idx) async {
                        final isRead = readSet.contains(ch.id);
                        await db.setChapterRead(novel.id, ch.id, !isRead);
                        readSet = await db.getReadChaptersForNovel(novel.id);
                        setStateModal(() {});
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (result is Chapter) {
      final index = novel.chapters.indexWhere((ch) => ch.id == result.id);
      if (index != -1) {
        setState(() => selectedChapter = index);
        _loadChapter();
      }
    }
  }

  int _currentIndex() {
    if (novel.chapters.isEmpty) return -1;
    if (selectedChapter >= 0 && selectedChapter < novel.chapters.length)
      return selectedChapter;
    return 0;
  }

  void _goToPrevious() {
    final idx = _currentIndex();
    if (idx <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('no_previous_chapter'.translate)));
      return;
    }
    setState(() => selectedChapter = idx - 1);
    _loadChapter();
  }

  void _goToNext() {
    final idx = _currentIndex();
    if (idx == -1 || idx >= novel.chapters.length - 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('no_next_chapter'.translate)));
      return;
    }
    setState(() => selectedChapter = idx + 1);
    _loadChapter();
  }

  Future<bool> _onWillPop() async {
    await _setFullscreenMode(false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('fullscreen_disabled'.translate)));
    return true;
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _batteryTimer?.cancel();
    _setFullscreenMode(false);
    super.dispose();
  }

  Future<void> _applyScriptsToWebView(List<String> enabledScripts) async {
    try {
      for (final script in enabledScripts) {
        final js = """
          (function() {
            console.log('Applying script: $script');
          })();
        """;
        await _controller!.runJavaScript(js);
      }
    } catch (e) {
      print('Erro ao aplicar scripts: $e');
    }
  }

  Future<void> _startTtsForCurrentChapter() async {
    try {
      if (novel.chapters.isEmpty) return;
      final chapter = novel.chapters[selectedChapter];
      final content = chapter.content ?? '';
      final text = _extractTextFromHtml(content);
      if (text.trim().isEmpty) return;
      await _tts.speak(text);
      _ttsPlaying = true;
      _showTtsNotification(true);
    } catch (e) {
      print('Failed to start TTS: $e');
    }
  }

  String _extractTextFromHtml(String html) {
    try {
      final text = html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (e) {
      return html;
    }
  }

  Future<void> _scrollToNextParagraph() async {
    try {
      final res = await _controller!.runJavaScriptReturningResult(
        "(function(){ try{ return JSON.stringify(window._akashic_findParagraphOffsets()); }catch(e){ return '[]'; } })();",
      );
      final jsonStr = (res is String) ? res : res.toString();
      final List offs = jsonDecode(jsonStr) as List? ?? [];
      final currRes = await _controller!.runJavaScriptReturningResult(
        "(function(){ try{ return window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0; }catch(e){ return 0; } })();",
      );
      final curr =
          (currRes is num)
              ? currRes.toDouble()
              : double.tryParse(currRes.toString()) ?? 0.0;
      dynamic next;
      for (final o in offs) {
        final val =
            (o is num) ? o.toDouble() : double.tryParse(o.toString()) ?? 0.0;
        if (val > curr + 10) {
          next = val;
          break;
        }
      }
      if (next != null) {
        await _controller!.runJavaScript(
          "window.scrollTo({top: ${next.toString()}, behavior:'smooth'}); put = true;",
        );
      } else {
        await _controller!.runJavaScript(
          "window.scrollTo(0, document.body.scrollHeight);",
        );
      }
    } catch (e) {
      print('Failed to jump to next paragraph: $e');
    }
  }

  Future<void> _scrollToPreviousParagraph() async {
    try {
      final res = await _controller!.runJavaScriptReturningResult(
        "(function(){ try{ return JSON.stringify(window._akashic_findParagraphOffsets()); }catch(e){ return '[]'; } })();",
      );
      final jsonStr = (res is String) ? res : res.toString();
      final List offs = jsonDecode(jsonStr) as List? ?? [];
      final currRes = await _controller!.runJavaScriptReturningResult(
        "(function(){ try{ return window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0; }catch(e){ return 0; } })();",
      );
      final curr =
          (currRes is num)
              ? currRes.toDouble()
              : double.tryParse(currRes.toString()) ?? 0.0;
      dynamic prev;
      for (int i = offs.length - 1; i >= 0; i--) {
        final o = offs[i];
        final val =
            (o is num) ? o.toDouble() : double.tryParse(o.toString()) ?? 0.0;
        if (val < curr - 10) {
          prev = val;
          break;
        }
      }
      if (prev != null) {
        await _controller!.runJavaScript(
          "window.scrollTo({top: ${prev.toString()}, behavior:'smooth'}); put = true;",
        );
      } else {
        await _controller!.runJavaScript("window.scrollTo(0, 0);");
      }
    } catch (e) {
      print('Failed to jump to previous paragraph: $e');
    }
  }
}
