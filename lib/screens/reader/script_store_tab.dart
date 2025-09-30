import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ScriptStoreTab extends StatefulWidget {
  final Map<String, dynamic> prefs;
  final ValueChanged<List<String>> onToggle;
  final ValueChanged<String>? onRemoveScript;
  const ScriptStoreTab({
    super.key,
    required this.prefs,
    required this.onToggle,
    this.onRemoveScript,
  });

  @override
  State<ScriptStoreTab> createState() => _ScriptStoreTabState();
}

class _ScriptStoreTabState extends State<ScriptStoreTab> {
  List<Map<String, dynamic>> _scripts = [];
  List<Map<String, dynamic>> _filtered = [];
  String _q = '';
  bool _loading = false;
  final List<String> _enabled = [];

  @override
  void initState() {
    super.initState();
    _loadScripts();
    _updateEnabled();
  }

  @override
  void didUpdateWidget(covariant ScriptStoreTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateEnabled();
  }

  void _updateEnabled() {
    _enabled.clear();
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final prefs = appState.getReaderPrefs();
      if (prefs['enabledScripts'] is List) {
        _enabled.addAll((prefs['enabledScripts'] as List).cast<String>());
        return;
      }
    } catch (_) {}
    if (widget.prefs['enabledScripts'] is List) {
      _enabled.addAll((widget.prefs['enabledScripts'] as List).cast<String>());
    }
  }

  Future<void> _loadScripts() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('https://api.npoint.io/bcd94c36fa7f3bf3b1e6');
      final resp = await http.read(uri);
      final Map<String, dynamic> data =
          jsonDecode(resp) as Map<String, dynamic>;
      final List scripts = data['scripts'] as List? ?? [];
      _scripts =
          scripts.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      _applyFilter();
    } catch (e) {
      debugPrint('Failed to load scriptstore: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _q.toLowerCase();
    _filtered =
        _scripts.where((s) {
          final name = (s['name'] ?? s['use'] ?? '').toString().toLowerCase();
          final desc = (s['description'] ?? '').toString().toLowerCase();
          return name.contains(q) || desc.contains(q);
        }).toList();
    setState(() {});
  }

  Future<bool> _confirmEnable() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('activate_script'.translate),
          content: Text('script_warning'.translate),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('cancel'.translate),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('confirm'.translate),
            ),
          ],
        );
      },
    );
    final accepted = res == true;
    if (accepted) {
      final newPrefs = Map<String, dynamic>.from(widget.prefs);
      newPrefs['scriptStoreConfirmed'] = true;
      await appState.setReaderPrefs(newPrefs);
    }
    return accepted;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search scripts...',
            ),
            onChanged: (v) {
              _q = v;
              _applyFilter();
            },
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: ListView.separated(
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final s = _filtered[i];
              final name = (s['name'] ?? s['use'] ?? '').toString();
              final desc = (s['description'] ?? '').toString();
              final isEnabled = _enabled.contains(name);
              return ListTile(
                title: Text(name),
                subtitle: desc.isNotEmpty ? Text(desc) : null,
                trailing: StatefulBuilder(
                  builder: (c, st) {
                    return Switch(
                      value: isEnabled,
                      onChanged: (v) async {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        if (v) {
                          final alreadyConfirmed =
                              (widget.prefs['scriptStoreConfirmed'] ?? false)
                                  as bool;
                          if (!alreadyConfirmed) {
                            final ok = await _confirmEnable();
                            if (!ok) return;
                          }
                          setState(() {
                            _enabled.add(name);
                          });
                        } else {
                          setState(() {
                            _enabled.remove(name);
                          });
                        }

                        try {
                          final current = appState.getReaderPrefs();
                          final newPrefs = Map<String, dynamic>.from(current);
                          newPrefs['enabledScripts'] = List<String>.from(
                            _enabled,
                          );
                          await appState.setReaderPrefs(newPrefs);
                        } catch (e) {
                          debugPrint('Failed to persist enabled scripts: $e');
                        }

                        widget.onToggle(List<String>.from(_enabled));
                        if (!v && widget.onRemoveScript != null) {
                          widget.onRemoveScript!(name);
                        }

                        st(() {});
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
