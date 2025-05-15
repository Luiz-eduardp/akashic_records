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
      body: RefreshIndicator(
        onRefresh: () async {
          _onSearchChanged(_searchTextController.value);
          return Future.value();
        },
        color: theme.colorScheme.primary,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SearchBarWidget(
                  onSearch: _onSearchChanged,
                  onFilterPressed: null,
                ),
              ),
              Expanded(child: _buildContent(appState, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AppState appState, ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pesquisando...'.translate,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (appState.selectedPlugins.isEmpty) {
      return _buildNoPluginsSelected(theme);
    }

    if (_searchResults.isNotEmpty) {
      return NovelGridWidget(
        novels: _searchResults,
        isListView: false,
        scrollController: ScrollController(),
        onNovelTap: _handleNovelTap,
        onNovelLongPress: (Novel novel) {},
        errorMessage: _errorMessage,
        isLoading: _isLoading,
      );
    }

    return ListView.builder(
      itemCount: appState.selectedPlugins.length,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        final pluginName = appState.selectedPlugins.elementAt(index);
        return PluginCard(pluginName: pluginName);
      },
    );
  }

  Widget _buildNoPluginsSelected(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_add,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum plugin selecionado. Acesse as configurações para adicionar plugins.'
                  .translate,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/plugins');
              },
              icon: const Icon(Icons.add),
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text('Gerenciar plugins'.translate),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
