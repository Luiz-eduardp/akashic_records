import 'package:flutter/material.dart';
import 'package:akashic_records/screens/library/library_screen.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart';
import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final _advancedDrawerController = AdvancedDrawerController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _tabController.animateTo(index);
  }

  void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AdvancedDrawer(
      backdropColor: theme.colorScheme.surfaceVariant,
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: false,
      disabledGestures: false,
      childDecoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: Colors.black12, blurRadius: 5.0),
        ],
      ),
      drawer: SafeArea(
        child: ListTileTheme(
          textColor: theme.colorScheme.onSurfaceVariant,
          iconColor: theme.colorScheme.onSurfaceVariant,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(height: 35),

              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Aparência'.translate),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                  _advancedDrawerController.hideDrawer();
                },
              ),
              ListTile(
                leading: Icon(Icons.extension),
                title: Text('Plugins'.translate),
                onTap: () {
                  Navigator.pushNamed(context, '/plugins');
                  _advancedDrawerController.hideDrawer();
                },
              ),

              Spacer(),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Akashic Records App'),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Akashic Records'.translate),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
          actionsIconTheme: IconThemeData(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          titleTextStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 25,
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleMenuButtonPressed,
            icon: ValueListenableBuilder<AdvancedDrawerValue>(
              valueListenable: _advancedDrawerController,
              builder: (_, value, __) {
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: 250),
                  child: Icon(
                    value.visible ? Icons.clear : Icons.menu,
                    key: ValueKey<bool>(value.visible),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          actions: [],
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [LibraryScreen(), FavoritesScreen(), HistoryScreen()],
        ),
        bottomNavigationBar: Container(
          color: theme.colorScheme.surfaceContainerHighest,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: GNav(
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              GButton(icon: Icons.library_books, text: 'Biblioteca'.translate),
              GButton(icon: Icons.favorite, text: 'Favoritos'.translate),
              GButton(icon: Icons.history, text: 'Histórico'.translate),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
