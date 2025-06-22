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
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        top: 40,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configurações de Leitura'.translate,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.onSurface,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                isScrollable: false,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
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
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('Salvar'.translate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
