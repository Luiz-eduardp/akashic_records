import 'dart:async';
import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:intl/intl.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:provider/provider.dart';
import 'package:traffic_stats/traffic_stats.dart';

class ReaderAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final ReaderSettings readerSettings;
  final VoidCallback onSettingsPressed;
  final int? wordCount;
  final double scrollPercentage;
  final ScrollController scrollController;

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.readerSettings,
    required this.onSettingsPressed,
    this.wordCount,
    required this.scrollPercentage,
    required this.scrollController,
    required Color appBarColor, // Este parâmetro parece redundante, pois a cor é obtida de readerSettings
  });

  @override
  State<ReaderAppBar> createState() => _ReaderAppBarState();

  // Altura ajustada para a AppBar padrão + uma linha compacta para status + barra de progresso
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 27.0);
}

class _ReaderAppBarState extends State<ReaderAppBar> {
  String _currentTime = '';
  int _batteryLevel = 100;
  Battery battery = Battery();

  final NetworkSpeedService _networkSpeedService = NetworkSpeedService();
  late Stream<NetworkSpeedData> _speedStream;
  NetworkSpeedData _currentSpeed = NetworkSpeedData(
    downloadSpeed: 0,
    uploadSpeed: 0,
  );

  double _currentScrollPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _updateBatteryLevel();
    Timer.periodic(const Duration(minutes: 1), (Timer t) => _updateTime());
    Timer.periodic(
      const Duration(minutes: 5),
      (Timer t) => _updateBatteryLevel(),
    );

    _networkSpeedService.init();
    _speedStream = _networkSpeedService.speedStream;
    _speedStream.listen((speedData) {
      if (mounted) {
        setState(() {
          _currentSpeed = speedData;
        });
      }
    });

    widget.scrollController.addListener(_updateScrollPercentage);
    _currentScrollPercentage = widget.scrollPercentage;
  }

  @override
  void didUpdateWidget(covariant ReaderAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_updateScrollPercentage);
      widget.scrollController.addListener(_updateScrollPercentage);
    }
  }

  @override
  void dispose() {
    _networkSpeedService.dispose();
    widget.scrollController.removeListener(_updateScrollPercentage);
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm').format(DateTime.now());
      });
    }
  }

  Future<void> _updateBatteryLevel() async {
    try {
      final level = await battery.batteryLevel;
      if (mounted) {
        setState(() {
          _batteryLevel = level;
        });
      }
    } catch (e) {
      debugPrint('Could not get battery level: $e');
    }
  }

  void _updateScrollPercentage() {
    if (mounted) {
      setState(() {
        _currentScrollPercentage = widget.scrollPercentage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // O Provider.of<AppState>(context) é usado aqui para garantir que o widget
    // seja reconstruído quando o AppState mudar, o que é necessário para
    // reagir a mudanças nas configurações do leitor.
    Provider.of<AppState>(context);

    return Material(
      color: widget.readerSettings.backgroundColor,
      elevation: 1,
      child: SafeArea( // Adicionado SafeArea para evitar sobreposição com a barra de status do sistema
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: widget.readerSettings.textColor,
              elevation: 0,
              shadowColor: Colors.transparent,
              centerTitle: true,
              title: Text(
                widget.title ?? "Carregando...".translate,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: widget.readerSettings.textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18, // Tamanho da fonte ajustado para caber melhor
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: widget.readerSettings.textColor,
                  ),
                  onPressed: widget.onSettingsPressed,
                  tooltip: 'Configurações de Leitura'.translate,
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.list,
                      color: widget.readerSettings.textColor,
                    ),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    tooltip: 'Lista de Capítulos'.translate,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentTime,
                    style: TextStyle(
                      color: widget.readerSettings.textColor,
                      fontSize: 11,
                    ),
                  ),
                  if (widget.wordCount != null)
                    Text(
                      '${widget.wordCount} ' + 'palavras'.translate,
                      style: TextStyle(
                        color: widget.readerSettings.textColor,
                        fontSize: 11,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        '↓${_currentSpeed.downloadSpeed} Kbps ↑${_currentSpeed.uploadSpeed} Kbps',
                        style: TextStyle(
                          color: widget.readerSettings.textColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.battery_std,
                        color: widget.readerSettings.textColor,
                        size: 14,
                      ),
                      Text(
                        ' $_batteryLevel%',
                        style: TextStyle(
                          color: widget.readerSettings.textColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: _currentScrollPercentage,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 3.0,
            ),
          ],
        ),
      ),
    );
  }
}
