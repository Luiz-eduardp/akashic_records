import 'package:akashic_records/screens/library/novel_grid_widget.dart';
import 'package:akashic_records/screens/library/plugin_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/library/search_bar_widget.dart';
import 'package:akashic_records/models/model.dart';
import 'package:akashic_records/screens/details/novel_details_screen.dart';
import 'package:rxdart/rxdart.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchTextController = BehaviorSubject<String>();
  List<Novel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchTextController
        .debounceTime(const Duration(milliseconds: 500))
        .listen(_searchAllPlugins);
  }

  @override
  void dispose() {
    _searchTextController.close();
    super.dispose();
  }

  Future<void> _searchAllPlugins(String term) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (term.isNotEmpty) {
        final appState = Provider.of<AppState>(context, listen: false);
        final selectedPlugins = appState.selectedPlugins;
        List<Novel> allResults = [];

        for (final pluginName in selectedPlugins) {
          final plugin = appState.pluginServices[pluginName];
          if (plugin != null) {
            final searchResults = await plugin.searchNovels(term, 1);
            for (final novel in searchResults) {
              novel.pluginId = pluginName;
            }
            allResults.addAll(searchResults);
          }
        }

        setState(() {
          _searchResults = allResults;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao pesquisar: ${e.toString()}'.translate;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String term) {
    _searchTextController.add(term);
  }

  void _handleNovelTap(Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NovelDetailsScreen(novel: novel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchBarWidget(
                onSearch: _onSearchChanged,
                onFilterPressed: null,
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : appState.selectedPlugins.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Nenhum plugin selecionado. Acesse as configurações para adicionar plugins.'
                                  .translate,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/plugins');
                              },
                              child: Text('Plugins'.translate),
                            ),
                          ],
                        ),
                      )
                      : _searchResults.isNotEmpty
                      ? NovelGridWidget(
                        novels: _searchResults,
                        isListView: false,
                        scrollController: ScrollController(),
                        onNovelTap: _handleNovelTap,
                        onNovelLongPress: (Novel novel) {},
                        errorMessage: _errorMessage,
                        isLoading: _isLoading,
                      )
                      : ListView.builder(
                        itemCount: appState.selectedPlugins.length,
                        itemBuilder: (context, index) {
                          final pluginName = appState.selectedPlugins.elementAt(
                            index,
                          );
                          return PluginCard(pluginName: pluginName);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
