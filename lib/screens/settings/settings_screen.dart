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
      appBar: AppBar(centerTitle: true, title: Text('settings'.translate)),
      body: ListView(
        children: [
          ListTile(
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
            trailing: ElevatedButton(
              child: Text('check_update_button'.translate),
              onPressed: () async {
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
                      (latest['author'] != null &&
                              latest['author']['login'] != null)
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

                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    final shouldShow = appState.shouldShowReleaseNotes(tag);

                    if (!shouldShow) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('no_update_available'.translate),
                        ),
                      );
                      return;
                    }

                    final assets = (latest['assets'] as List<dynamic>?) ?? [];

                    await showDialog(
                      context: context,
                      builder: (_) {
                        return StatefulBuilder(
                          builder: (ctx, setSt) {
                            double progress = 0.0;
                            String? downloading;
                            return AlertDialog(
                              title: Text(
                                '${'update_available'.translate} — $name',
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (author.isNotEmpty)
                                      Text('by'.translate + ': $author'),
                                    const SizedBox(height: 8),
                                    if (body.isNotEmpty)
                                      SizedBox(
                                        height: 200,
                                        child: MarkdownBody(data: body),
                                      )
                                    else
                                      Text(
                                        '${'latest_release'.translate}: $tag',
                                      ),
                                    const SizedBox(height: 12),
                                    Text('assets'.translate),
                                    const SizedBox(height: 8),
                                    ...assets.map((a) {
                                      final an =
                                          a['name']?.toString() ?? 'asset';
                                      final url =
                                          a['browser_download_url']
                                              ?.toString() ??
                                          '';
                                      return ListTile(
                                        title: Text(an),
                                        subtitle: Text(url),
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
                                                      } else {
                                                        final uri = Uri.file(
                                                          target,
                                                        );
                                                        if (await canLaunchUrl(
                                                          uri,
                                                        )) {
                                                          await launchUrl(uri);
                                                        } else {
                                                          final ruri =
                                                              Uri.parse(url);
                                                          if (await canLaunchUrl(
                                                            ruri,
                                                          ))
                                                            await launchUrl(
                                                              ruri,
                                                              mode:
                                                                  LaunchMode
                                                                      .externalApplication,
                                                            );
                                                        }
                                                      }
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
                                          child: Text(
                                            downloading == an
                                                ? '${(progress * 100).toStringAsFixed(0)}%'
                                                : 'download'.translate,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('cancel'.translate),
                                ),
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
                            );
                          },
                        );
                      },
                    );

                    await appState.markReleaseNotesShown(tag);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('no_update_available'.translate)),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('update_check_failed'.translate)),
                  );
                }
              },
            ),
          ),

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
                if (widget.onLocaleChanged != null)
                  widget.onLocaleChanged!(locale);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'language'.translate + ': ' + locale.languageCode,
                    ),
                  ),
                );
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
          const Divider(),
          SwitchListTile(
            title: Text('nav_always_visible'.translate),
            value: appState.navAlwaysVisible,
            onChanged: (v) async {
              await appState.setNavAlwaysVisible(v);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('nav_always_visible'.translate)),
              );
            },
          ),
          ListTile(
            title: Text('nav_scroll_threshold'.translate),
            subtitle: Text('nav_scroll_threshold_sub'.translate),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Slider(
                      min: 2.0,
                      max: 20.0,
                      divisions: 18,
                      value: _tempNavThreshold!,
                      label: _tempNavThreshold!.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _tempNavThreshold = v),
                      onChangeEnd: (v) async {
                        await appState.setNavScrollThreshold(v);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${'nav_scroll_threshold'.translate}: ${v.toStringAsFixed(1)}',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('nav_animation_duration'.translate),
            subtitle: Text('nav_animation_duration_sub'.translate),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Slider(
                      min: 100,
                      max: 600,
                      divisions: 50,
                      value: (_tempNavAnimMs ?? 250).toDouble(),
                      label: '${_tempNavAnimMs ?? 250} ms',
                      onChanged:
                          (v) => setState(() => _tempNavAnimMs = v.toInt()),
                      onChangeEnd: (v) async {
                        await appState.setNavAnimationMs(v.toInt());
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${'nav_animation_duration'.translate}: ${v.toInt()} ms',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            title: Text('nav_animation_duration'.translate),
            subtitle: Text('nav_animation_duration_sub'.translate),
            trailing: SizedBox(
              width: 200,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Slider(
                      min: 50,
                      max: 1000,
                      divisions: 95,
                      value: (_tempNavAnimMs ?? 250).toDouble(),
                      label: '${_tempNavAnimMs ?? 250} ms',
                      onChanged:
                          (v) => setState(() => _tempNavAnimMs = v.toInt()),
                      onChangeEnd:
                          (v) async =>
                              await appState.setNavAnimationMs(v.toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
