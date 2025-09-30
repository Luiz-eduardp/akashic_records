import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/favorites_screen.dart';
import 'package:akashic_records/screens/updates_screen.dart';
import 'package:akashic_records/screens/plugins_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    FavoritesScreen(),
    UpdatesScreen(),
    PluginsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akashic Records',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A powerful reader',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('settings'.translate),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => SettingsScreen(
                            onLocaleChanged: (locale) async {
                              await I18n.updateLocate(locale);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('about'.translate),
                onTap: () {},
              ),
            ],
          ),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(icon: Icon(Icons.update), label: 'Updates'),
            NavigationDestination(
              icon: Icon(Icons.extension),
              label: 'Plugins',
            ),
          ],
        ),
      ),
    );
  }
}
