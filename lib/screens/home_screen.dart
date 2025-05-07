import 'package:flutter/material.dart';
import 'package:akashic_records/screens/library/library_screen.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart';
import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:akashic_records/widgets/app_drawer.dart';

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
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5.0),
        ],
      ),
      drawer: AppDrawer(advancedDrawerController: _advancedDrawerController),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Akashic Records'.translate,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleMenuButtonPressed,
            icon: AnimatedBuilder(
              animation: _advancedDrawerController,
              builder: (context, child) {
                return Icon(
                  _advancedDrawerController.value.visible
                      ? Icons.close
                      : Icons.menu,
                  color: theme.colorScheme.onSurface,
                );
              },
            ),
          ),
          actions: const [],
          elevation: 2,
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [LibraryScreen(), FavoritesScreen(), HistoryScreen()],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isTablet, theme),
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isTablet, ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 4,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: GNav(
            rippleColor: theme.colorScheme.primary.withOpacity(0.1),
            hoverColor: theme.colorScheme.primary.withOpacity(0.1),
            gap: 8,
            activeColor: theme.colorScheme.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.colorScheme.primaryContainer,
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              GButton(
                icon: Icons.library_books,
                text: 'Biblioteca'.translate,
                backgroundColor:
                    _selectedIndex == 0
                        ? theme.colorScheme.primaryContainer
                        : null,
              ),
              GButton(
                icon: Icons.favorite,
                text: 'Favoritos'.translate,
                backgroundColor:
                    _selectedIndex == 1
                        ? theme.colorScheme.primaryContainer
                        : null,
              ),
              GButton(
                icon: Icons.history,
                text: 'Histórico'.translate,
                backgroundColor:
                    _selectedIndex == 2
                        ? theme.colorScheme.primaryContainer
                        : null,
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: _onItemTapped,
            curve: Curves.easeOutExpo,
          ),
        ),
      ),
    );
  }
}
