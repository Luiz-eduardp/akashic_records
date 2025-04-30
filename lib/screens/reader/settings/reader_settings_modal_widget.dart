import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/reader/settings/tabs/appearance_tab.dart';
import 'package:akashic_records/screens/reader/settings/tabs/customcss_tab.dart';
import 'package:akashic_records/screens/reader/settings/tabs/text_tab.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/screens/reader/settings/tabs/custom_plugin_tab.dart';

class ReaderSettingsModal extends StatefulWidget {
  const ReaderSettingsModal({super.key});

  @override
  State<ReaderSettingsModal> createState() => _ReaderSettingsModalState();
}

class _ReaderSettingsModalState extends State<ReaderSettingsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações de Leitura'.translate,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                isScrollable: true,
                tabs: [
                  Tab(
                    text: 'Aparência'.translate,
                    icon: const Icon(Icons.palette),
                  ),
                  Tab(
                    text: 'Texto'.translate,
                    icon: const Icon(Icons.text_fields),
                  ),
                  Tab(
                    text: 'Plugins'.translate,
                    icon: const Icon(Icons.extension),
                  ),
                  Tab(text: 'CSS'.translate, icon: const Icon(Icons.css)),
                ],
              ),
              Flexible(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    AppearanceTab(),
                    TextTab(),
                    CustomPluginTab(),
                    CustomCssTab(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text('Salvar'.translate),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
