import 'dart:convert';
import 'package:akashic_records/screens/notify/notify_screen.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/screens/library/library_screen.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart';
import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:akashic_records/widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationBadge extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> notificationsFuture;
  final VoidCallback onPressed;

  const NotificationBadge({
    super.key,
    required this.notificationsFuture,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: notificationsFuture,
      builder: (context, snapshot) {
        int notificationCount = 0;
        if (snapshot.hasData) {
          notificationCount = snapshot.data!.length;
        }
        return IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              if (notificationCount > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onPressed,
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final _advancedDrawerController = AdvancedDrawerController();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _notificationsFuture = _loadNotifications();
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

  Future<List<Map<String, dynamic>>> _loadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.npoint.io/a701fcdc92e490b3289c'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> loadedNotifications =
            data.map((item) => item as Map<String, dynamic>).toList();

        return await _filterUnreadNotifications(loadedNotifications);
      } else {
        throw Exception(
          'Falha ao carregar notificações: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _filterUnreadNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final readNotificationIds = prefs.getStringList('readNotifications') ?? [];

    return notifications
        .where(
          (notification) => !readNotificationIds.contains(notification['id']),
        )
        .toList();
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
          actions: [
            NotificationBadge(
              notificationsFuture: _notificationsFuture,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationScreen(
                          notificationsFuture: _notificationsFuture,
                          onNotificationRead: _onNotificationRead,
                        ),
                  ),
                );
              },
            ),
          ],
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

  void _onNotificationRead(String notificationId) {
    setState(() {
      _notificationsFuture = _notificationsFuture.then((notifications) {
        notifications.removeWhere(
          (notification) => notification['id'] == notificationId,
        );
        return notifications;
      });
    });
  }
}
