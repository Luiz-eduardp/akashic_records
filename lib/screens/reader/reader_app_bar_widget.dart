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

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.readerSettings,
    required this.onSettingsPressed,
    this.wordCount,
    required this.scrollPercentage,
  });

  @override
  State<ReaderAppBar> createState() => _ReaderAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);
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
  }

  @override
  void dispose() {
    _networkSpeedService.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Provider.of<AppState>(context);

    return Material(
      color: widget.readerSettings.backgroundColor,
      elevation: 1,
      child: Column(
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentTime,
                  style: TextStyle(
                    color: widget.readerSettings.textColor,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.wordCount != null
                      ? '${widget.wordCount} ' + 'palavras'.translate
                      : '',
                  style: TextStyle(
                    color: widget.readerSettings.textColor,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '↓${_currentSpeed.downloadSpeed} Kbps ↑${_currentSpeed.uploadSpeed} Kbps',
                      style: TextStyle(
                        color: widget.readerSettings.textColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.battery_std,
                      color: widget.readerSettings.textColor,
                      size: 16,
                    ),
                    Text(
                      ' $_batteryLevel%',
                      style: TextStyle(
                        color: widget.readerSettings.textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: widget.scrollPercentage,
            backgroundColor: theme.colorScheme.primary,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
