import 'package:akashic_records/screens/library/plugin_novels_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';

class PluginCard extends StatefulWidget {
  final String pluginName;

  const PluginCard({super.key, required this.pluginName});

  @override
  State<PluginCard> createState() => _PluginCardState();
}

class _PluginCardState extends State<PluginCard>
    with AutomaticKeepAliveClientMixin {
  String _pluginVersion = 'Desconhecido'.translate;
  String _pluginLang = 'Desconhecido'.translate;

  @override
  void initState() {
    super.initState();
    _loadPluginInfo();
  }

  Future<void> _loadPluginInfo() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final pluginService = appState.pluginServices[widget.pluginName];

    String version = 'Desconhecido'.translate;
    String lang = 'Desconhecido'.translate;

    if (pluginService != null) {
      version = pluginService.version;
      lang = pluginService.lang;
    }

    if (mounted) {
      setState(() {
        _pluginVersion = version;
        _pluginLang = lang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    Provider.of<AppState>(context, listen: false);
    bool isDispositivo = widget.pluginName == 'Dispositivo';
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      PluginNovelsScreen(pluginName: widget.pluginName),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Icon(
                  Icons.extension,
                  size: 36.0,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isDispositivo
                                ? widget.pluginName.translate
                                : widget.pluginName,
                            style: theme.textTheme.titleLarge!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          _pluginLang,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          'Versão'.translate + ': ',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _pluginVersion,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
