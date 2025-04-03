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
            'Configurações de Leitura',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Aparência'),
              Tab(text: 'Texto'),
              Tab(text: 'JS'),
              Tab(text: 'CSS'),
              Tab(text: 'Plugins'),
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
              child: const Text('Salvar'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
