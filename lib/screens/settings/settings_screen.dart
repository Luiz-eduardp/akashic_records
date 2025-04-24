import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/settings/update_settings.dart';
import 'package:akashic_records/screens/settings/appearance_settings.dart';
import 'package:akashic_records/screens/settings/about_button.dart';
import 'package:akashic_records/screens/settings/skeleton_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onLocaleChanged});

  final Function(Locale) onLocaleChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onLocaleChange(Locale? newLocale) async {
    if (newLocale != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('locale', newLocale.languageCode);
      await I18n.updateLocate(newLocale);
      widget.onLocaleChanged(newLocale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações'.translate),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        surfaceTintColor: theme.colorScheme.surfaceVariant,
        scrolledUnderElevation: 3,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: I18n.currentLocate,
                icon: Icon(
                  Icons.language,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                dropdownColor: theme.colorScheme.surface,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                items:
                    I18n.supportedLocales.map((Locale locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          locale.languageCode,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                onChanged: _onLocaleChange,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.onSurface,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          tabs: [
            Tab(text: 'Aparência'.translate, icon: const Icon(Icons.palette)),
            Tab(
              text: 'Atualização'.translate,
              icon: const Icon(Icons.system_update),
            ),
          ],
        ),
      ),
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child:
                  _isLoading
                      ? const SkeletonCard()
                      : Card(
                        elevation: 1,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AppearanceSettings(
                            appState: appState,
                            theme: theme,
                          ),
                        ),
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child:
                  _isLoading
                      ? const SkeletonCard()
                      : Card(
                        elevation: 1,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: UpdateSettings(),
                        ),
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AboutButton(),
    );
  }
}
