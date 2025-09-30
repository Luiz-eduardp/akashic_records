import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:akashic_records/state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  const SettingsScreen({super.key, required this.onLocaleChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color? _tempColor;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(title: Text('settings'.translate)),
      body: ListView(
        children: [
          ListTile(
            title: Text('language'.translate),
            subtitle: Text('change_app_language'.translate),
            onTap: () async {
              final locale = await showDialog<Locale>(
                context: context,
                builder:
                    (ctx) => SimpleDialog(
                      title: Text('select_language'.translate),
                      children: [
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('en')),
                          child: Text('english'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, Locale('pt', 'BR')),
                          child: Text('portuguese_br'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('es')),
                          child: Text('spanish'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('ja')),
                          child: Text('japanese'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('ar')),
                          child: Text('arabic'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('it')),
                          child: Text('italian'.translate),
                        ),
                        SimpleDialogOption(
                          onPressed:
                              () => Navigator.pop(ctx, const Locale('fr')),
                          child: Text('french'.translate),
                        ),
                      ],
                    ),
              );
              if (locale != null) {
                await I18n.updateLocate(locale);
                await Provider.of<AppState>(
                  context,
                  listen: false,
                ).setLocale(locale);
                widget.onLocaleChanged(locale);
              }
            },
          ),
          const Divider(),
          ListTile(
            title: Text('theme'.translate),
            subtitle: Text(
              '${'current'.translate}: ${appState.themeMode.toString().split('.').last}',
            ),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: appState.themeMode,
            title: Text('system'.translate),
            onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: appState.themeMode,
            title: Text('light'.translate),
            onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: appState.themeMode,
            title: Text('dark'.translate),
            onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
          ),
          const Divider(),
          ListTile(
            title: Text('accent_color'.translate),
            subtitle: Text('tap_to_change'.translate),
            trailing: CircleAvatar(backgroundColor: appState.accentColor),
            onTap: () async {
              _tempColor = appState.accentColor;
              await showDialog(
                context: context,
                builder:
                    (ctx) => AlertDialog(
                      title: Text('pick_accent_color'.translate),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: _tempColor!,
                          onColorChanged: (c) => setState(() => _tempColor = c),
                          showLabel: true,
                          pickerAreaHeightPercent: 0.7,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('cancel'.translate),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_tempColor != null)
                              appState.setAccentColor(_tempColor!);
                            Navigator.pop(ctx);
                          },
                          child: Text('select'.translate),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
