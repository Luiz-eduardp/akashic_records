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
    final theme = Theme.of(context);

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
              Icon(Icons.notifications, color: theme.colorScheme.onSurface),
              if (notificationCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: TextStyle(
                        color: theme.colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
      ),
      drawer: AppDrawer(advancedDrawerController: _advancedDrawerController),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Akashic Records'.translate,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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
                  size: 28,
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
                ).then((_) {
                  setState(() {
                    _notificationsFuture = _loadNotifications();
                  });
                });
              },
            ),
          ],
          elevation: 4,
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [LibraryScreen(), FavoritesScreen(), HistoryScreen()],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(theme),
      ),
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    return Material(
      color: theme.colorScheme.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: GNav(
            rippleColor: theme.colorScheme.primary.withOpacity(0.1),
            hoverColor: theme.colorScheme.primary.withOpacity(0.1),
            gap: 10,
            activeColor: theme.colorScheme.primary,
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: theme.colorScheme.primaryContainer,
            color: theme.colorScheme.onSurfaceVariant,
            tabs: [
              GButton(icon: Icons.library_books, text: 'Biblioteca'.translate),
              GButton(icon: Icons.favorite, text: 'Favoritos'.translate),
              GButton(icon: Icons.history, text: 'Histórico'.translate),
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
      _notificationsFuture = _loadNotifications();
    });
  }
}
