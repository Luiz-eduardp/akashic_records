import 'package:flutter/material.dart';
import 'package:akashic_records/screens/library/library_screen.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart';
import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:akashic_records/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<AppState>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Akashic Records',
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opções',
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'plugins') {
                Navigator.pushNamed(context, '/plugins');
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                _buildPopupMenuItem(
                  'Configurações',
                  Icons.settings,
                  'settings',
                  tooltip: 'Configurações do aplicativo',
                ),
                _buildPopupMenuItem(
                  'Plugins',
                  Icons.extension,
                  'plugins',
                  tooltip: 'Gerenciar plugins',
                ),
              ];
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [LibraryScreen(), FavoritesScreen(), HistoryScreen()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Biblioteca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String text,
    IconData icon,
    String value, {
    String? tooltip,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Tooltip(
        message: tooltip ?? text,
        child: Row(
          children: [Icon(icon), const SizedBox(width: 8), Text(text)],
        ),
      ),
    );
  }
}
