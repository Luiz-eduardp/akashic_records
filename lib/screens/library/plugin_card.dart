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

  Widget _buildInfoTag({
    required BuildContext context,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.0, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: theme.textTheme.labelSmall!.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    bool isDispositivo = widget.pluginName == 'Dispositivo';

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24.0,
                backgroundColor: colorScheme.surfaceVariant,
                child: Icon(
                  Icons.extension_outlined,
                  size: 28.0,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isDispositivo
                          ? widget.pluginName.translate
                          : widget.pluginName,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        _buildInfoTag(
                          context: context,
                          label: _pluginLang,
                          icon: Icons.language_outlined,
                        ),
                        _buildInfoTag(
                          context: context,
                          label: 'v$_pluginVersion',
                          icon: Icons.info_outline,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 28.0,
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
