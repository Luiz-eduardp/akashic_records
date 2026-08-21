import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:akashic_records/theme/app_text_styles.dart';
import 'package:akashic_records/widgets/m3e/m3e_app_bar.dart';
import 'storage_and_backup_screen.dart';

const double kCardPadding = 16.0;
const double kSectionSpacing = 12.0;

class SettingsScreen extends StatefulWidget {
  final ValueChanged<Locale>? onLocaleChanged;
  const SettingsScreen({super.key, this.onLocaleChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color? _tempColor;
  double? _tempNavThreshold;
  int? _tempNavAnimMs;

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding,
        vertical: kSectionSpacing / 2,
      ),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: colorScheme.outlineVariant.withOpacity(0.3)),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    _tempNavThreshold ??= appState.navScrollThreshold;
    _tempNavAnimMs ??= appState.navAnimationMs;

    return Scaffold(
      appBar: M3EAppBar(
        title: 'settings'.translate,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: kSectionSpacing, bottom: 120),
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'app_info'.translate,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (ctx, snap) {
                      final version = snap.hasData ? snap.data!.version : '2.2.5';
                      return Text('${'app_version'.translate}: $version');
                    },
                  ),
                  subtitle: const Text('Akashic Reader • Material 3 Expressive'),
                ),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text('language'.translate),
                  subtitle: Text(
                    '${'current'.translate}: ${Localizations.localeOf(context).languageCode.toUpperCase()}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _handleLanguageSelection(context, appState),
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'theme'.translate,
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: appState.themeMode,
                  title: Text('system'.translate),
                  secondary: const Icon(Icons.brightness_auto_rounded),
                  onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: appState.themeMode,
                  title: Text('light'.translate),
                  secondary: const Icon(Icons.wb_sunny_rounded),
                  onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: appState.themeMode,
                  title: Text('dark'.translate),
                  secondary: const Icon(Icons.nights_stay_rounded),
                  onChanged: (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens_rounded),
                  title: Text('accent_color'.translate),
                  subtitle: Text('tap_to_change'.translate),
                  trailing: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: appState.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onTap: () => _handleColorPicker(context, appState),
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'navigation_settings'.translate,
              children: [
                SwitchListTile(
                  title: Text('nav_always_visible'.translate),
                  value: appState.navAlwaysVisible,
                  onChanged: (v) async => await appState.setNavAlwaysVisible(v),
                ),
                ListTile(
                  title: Text('nav_scroll_threshold'.translate),
                  subtitle: Text(
                    '${'nav_scroll_threshold_sub'.translate}: ${_tempNavThreshold!.toStringAsFixed(1)}',
                  ),
                ),
                Slider(
                  min: 2.0,
                  max: 20.0,
                  divisions: 18,
                  value: _tempNavThreshold!,
                  label: _tempNavThreshold!.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _tempNavThreshold = v),
                  onChangeEnd: (v) async {
                    await appState.setNavScrollThreshold(v);
                  },
                ),
                ListTile(
                  title: Text('nav_animation_duration'.translate),
                  subtitle: Text(
                    '${'nav_animation_duration_sub'.translate}: ${_tempNavAnimMs ?? 250} ms',
                  ),
                ),
                Slider(
                  min: 100,
                  max: 600,
                  divisions: 50,
                  value: (_tempNavAnimMs ?? 250).toDouble(),
                  label: '${_tempNavAnimMs ?? 250} ms',
                  onChanged: (v) => setState(() => _tempNavAnimMs = v.toInt()),
                  onChangeEnd: (v) async {
                    await appState.setNavAnimationMs(v.toInt());
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'health_status'.translate,
              children: [
                FutureBuilder<void>(
                  future: Future.delayed(const Duration(milliseconds: 100)),
                  builder: (ctx, snap) {
                    final isHealthy = appState.database.isHealthy;
                    final lastError = appState.database.lastHealthError;

                    return Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            isHealthy ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isHealthy ? Colors.green : Colors.red,
                          ),
                          title: Text('database_status'.translate),
                          subtitle: Text(
                            isHealthy
                                ? 'database_healthy'.translate
                                : 'database_unhealthy'.translate,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isHealthy
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isHealthy ? 'OK' : 'ERROR',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isHealthy ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        if (lastError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'last_error'.translate,
                                    style: context.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastError,
                                    style: context.bodySmall.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.health_and_safety_rounded, size: 18),
                              label: Text('run_health_check'.translate),
                              onPressed: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('health_check_running'.translate),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                try {
                                  await appState.database.optimize();
                                  if (!mounted) return;
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('health_check_completed'.translate),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${'health_check_failed'.translate}: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            _buildSettingsSection(
              title: 'data_management'.translate,
              children: [
                ListTile(
                  leading: const Icon(Icons.sd_storage_rounded),
                  title: Text('storage_and_backup_title'.translate),
                  subtitle: Text('storage_and_backup_subtitle'.translate),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StorageAndBackupScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleColorPicker(
    BuildContext context,
    AppState appState,
  ) async {
    _tempColor = appState.accentColor;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text('pick_accent_color'.translate),
        content: SingleChildScrollView(
          child: HueRingPicker(
            pickerColor: _tempColor!,
            onColorChanged: (c) => setState(() => _tempColor = c),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.translate),
          ),
          ElevatedButton(
            onPressed: () {
              if (_tempColor != null) appState.setAccentColor(_tempColor!);
              Navigator.pop(ctx);
            },
            child: Text('select'.translate),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLanguageSelection(
    BuildContext context,
    AppState appState,
  ) async {
    final locale = await showDialog<Locale>(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text('select_language'.translate),
        children: [
          _buildLanguageOption(
            ctx,
            const Locale('en'),
            'english'.translate,
          ),
          _buildLanguageOption(
            ctx,
            const Locale('pt', 'BR'),
            'portuguese_br'.translate,
          ),
          _buildLanguageOption(
            ctx,
            const Locale('es'),
            'spanish'.translate,
          ),
          _buildLanguageOption(
            ctx,
            const Locale('ja'),
            'japanese'.translate,
          ),
          _buildLanguageOption(ctx, const Locale('ar'), 'arabic'.translate),
          _buildLanguageOption(
            ctx,
            const Locale('it'),
            'italian'.translate,
          ),
          _buildLanguageOption(ctx, const Locale('fr'), 'french'.translate),
        ],
      ),
    );
    if (locale != null) {
      await I18n.updateLocate(locale);
      await appState.setLocale(locale);
      if (widget.onLocaleChanged != null) widget.onLocaleChanged!(locale);
    }
  }

  Widget _buildLanguageOption(
    BuildContext context,
    Locale locale,
    String name,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, locale),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        child: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
