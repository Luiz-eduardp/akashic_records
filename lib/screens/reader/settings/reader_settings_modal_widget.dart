import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/reader/settings/tabs/advancedjs_tab.dart';
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
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurações de Leitura'.translate,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Aparência'.translate),
              Tab(text: 'Texto'.translate),
              Tab(text: 'JS'.translate),
              Tab(text: 'CSS'.translate),
              Tab(text: 'Plugins'.translate),
            ],
          ),
          SizedBox(
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                AppearanceTab(),
                TextTab(),
                AdvancedTab(),
                CustomCssTab(),
                CustomPluginTab(),
              ],
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Salvar'.translate),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
