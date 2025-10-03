import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:akashic_records/services/update_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:version/version.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import 'storage_manager_screen.dart';

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

  bool _tagEquals(String a, String b) {
    String norm(String s) => s.startsWith('v') ? s.substring(1) : s;
    return norm(a).trim() == norm(b).trim();
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kCardPadding,
        vertical: kSectionSpacing / 2,
      ),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final updateService = UpdateService(
      owner: 'Luiz-eduardp',
      repo: 'akashic_records',
    );
    _tempNavThreshold ??= appState.navScrollThreshold;
    _tempNavAnimMs ??= appState.navAnimationMs;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'settings'.translate,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: kSectionSpacing),
        child: Column(
          children: [
            _buildSettingsSection(
              title: 'app_info'.translate,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (ctx, snap) {
                      final version = snap.hasData ? snap.data!.version : '...';
                      return Text('${'app_version'.translate}: $version');
                    },
                  ),
                  subtitle:
                      appState.latestReleaseTag != null
                          ? Text(
                            '${'latest_release'.translate}: ${appState.latestReleaseTag}',
                          )
                          : null,
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('check_update_button'.translate),
                    onPressed:
                        () => _handleUpdateCheck(
                          context,
                          appState,
                          updateService,
                        ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('language'.translate),
                  subtitle: Text(
                    '${'current'.translate}: ${Localizations.localeOf(context).languageCode.toUpperCase()}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                  secondary: const Icon(Icons.brightness_auto),
                  onChanged:
                      (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: appState.themeMode,
                  title: Text('light'.translate),
                  secondary: const Icon(Icons.wb_sunny),
                  onChanged:
                      (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: appState.themeMode,
                  title: Text('dark'.translate),
                  secondary: const Icon(Icons.nights_stay),
                  onChanged:
                      (v) => appState.setThemeMode(v ?? ThemeMode.system),
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: Text('accent_color'.translate),
                  subtitle: Text('tap_to_change'.translate),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: appState.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
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

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kCardPadding,
                vertical: kSectionSpacing / 2,
              ),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.settings_ethernet),
                  title: Text('advanced_network'.translate),
                  children: [
                    ListTile(
                      title: Text('custom_dns'.translate),
                      subtitle: Text('custom_dns_sub'.translate),
                      trailing: DropdownButton<String?>(
                        value: appState.customDns,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('System Default'),
                          ),
                          const DropdownMenuItem(
                            value: '1.1.1.1',
                            child: Text('Cloudflare (1.1.1.1)'),
                          ),
                          const DropdownMenuItem(
                            value: '8.8.8.8',
                            child: Text('Google (8.8.8.8)'),
                          ),
                          const DropdownMenuItem(
                            value: '9.9.9.9',
                            child: Text('Quad9 (9.9.9.9)'),
                          ),
                        ],
                        onChanged: (v) async => await appState.setCustomDns(v),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: TextEditingController(
                          text: appState.customUserAgent ?? '',
                        ),
                        decoration: InputDecoration(
                          labelText: 'custom_user_agent'.translate,
                          hintText: 'e.g. MyApp/1.0',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) async {
                          await appState.setCustomUserAgent(
                            v.isEmpty ? null : v,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            _buildSettingsSection(
              title: 'data_management'.translate,
              children: [
                ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text('storage_manager_title'.translate),
                  subtitle: Text('storage_manager_sub'.translate),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StorageManagerScreen(),
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
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
      builder:
          (ctx) => SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
                Locale('pt', 'BR'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'language'.translate +
                ' updated to: ' +
                (locale.countryCode != null
                        ? '${locale.languageCode}_${locale.countryCode}'
                        : locale.languageCode)
                    .toUpperCase(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(name),
      ),
    );
  }

  Future<void> _handleUpdateCheck(
    BuildContext context,
    AppState appState,
    UpdateService updateService,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 12),
                Expanded(child: Text('checking'.translate)),
              ],
            ),
          ),
    );
    try {
      final latest = await updateService.fetchLatestRelease();
      Navigator.pop(context);

      if (latest == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update_check_failed'.translate)),
        );
        return;
      }

      final tag = (latest['tag_name'] ?? '') as String;
      final url = (latest['html_url'] ?? '') as String;
      final name = (latest['name'] ?? '') as String;
      final body = (latest['body'] ?? '') as String;
      final author =
          (latest['author'] != null && latest['author']['login'] != null)
              ? latest['author']['login'].toString()
              : '';

      final pkg = await PackageInfo.fromPlatform();
      final current = pkg.version;
      bool isNew = false;
      try {
        final vTag = Version.parse(
          tag.startsWith('v') ? tag.substring(1) : tag,
        );
        final vCur = Version.parse(current);
        isNew = vTag > vCur;
      } catch (e) {
        isNew = tag != current && !_tagEquals(tag, current);
      }

      if (isNew) {
        await Provider.of<AppState>(
          context,
          listen: false,
        ).saveLatestReleaseInfo(tag, url);
        final assets = (latest['assets'] as List<dynamic>?) ?? [];

        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (ctx) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('${'update_available'.translate} — $name'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StatefulBuilder(
                      builder: (ctx2, setSt) {
                        double progress = 0.0;
                        String? downloading;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (author.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  'by'.translate + ': $author',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (body.isNotEmpty)
                                      MarkdownBody(data: body)
                                    else
                                      Text(
                                        '${'latest_release'.translate}: $tag',
                                      ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'assets'.translate,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ...assets.map((a) {
                                      final an =
                                          a['name']?.toString() ?? 'asset';
                                      final url =
                                          a['browser_download_url']
                                              ?.toString() ??
                                          '';
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(an),
                                        subtitle: Text(
                                          url,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed:
                                              url.isEmpty
                                                  ? null
                                                  : () async {
                                                    if (downloading != null)
                                                      return;
                                                    setSt(
                                                      () => downloading = an,
                                                    );
                                                    try {
                                                      final dir =
                                                          await getApplicationDocumentsDirectory();
                                                      final target =
                                                          '${dir.path}/$an';
                                                      await updateService
                                                          .downloadAsset(
                                                            url,
                                                            target,
                                                            (p) => setSt(
                                                              () =>
                                                                  progress = p,
                                                            ),
                                                          );
                                                      setSt(
                                                        () => progress = 1.0,
                                                      );

                                                      if (Platform.isAndroid) {
                                                        final intent =
                                                            AndroidIntent(
                                                              action:
                                                                  'action_view',
                                                              data:
                                                                  Uri.file(
                                                                    target,
                                                                  ).toString(),
                                                              arguments: {
                                                                'mimeType':
                                                                    'application/vnd.android.package-archive',
                                                              },
                                                            );
                                                        await intent.launch();
                                                      } else {}
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'update_check_failed'
                                                                .translate,
                                                          ),
                                                        ),
                                                      );
                                                    } finally {
                                                      setSt(
                                                        () =>
                                                            downloading = null,
                                                      );
                                                    }
                                                  },
                                          child:
                                              downloading == an
                                                  ? Text(
                                                    '${(progress * 100).toStringAsFixed(0)}%',
                                                  )
                                                  : Text('download'.translate),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('cancel'.translate),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final ruri = Uri.parse(url);
                                    if (await canLaunchUrl(ruri))
                                      await launchUrl(
                                        ruri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                  },
                                  child: Text('open_release'.translate),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );

        await appState.markReleaseNotesShown(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('no_update_available'.translate)),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('update_check_failed'.translate)));
    }
  }
}
