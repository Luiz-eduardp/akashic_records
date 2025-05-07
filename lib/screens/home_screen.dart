import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:akashic_records/screens/library/library_screen.dart';
import 'package:akashic_records/screens/favorites/favorites_screen.dart';
import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:akashic_records/widgets/app_drawer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final _advancedDrawerController = AdvancedDrawerController();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoadingNotifications = false;
  String? _notificationError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
      _notificationError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.npoint.io/a701fcdc92e490b3289c'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> loadedNotifications =
            data.map((item) => item as Map<String, dynamic>).toList();

        _notifications = await _filterUnreadNotifications(loadedNotifications);
      } else {
        _notificationError =
            'Falha ao carregar notificações: ${response.statusCode}';
      }
    } catch (e) {
      _notificationError = 'Erro ao carregar notificações: $e';
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
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
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (_notifications.isNotEmpty)
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
                          '${_notifications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationScreen(
                          notifications: _notifications,
                          isLoading: _isLoadingNotifications,
                          error: _notificationError,
                          onNotificationRead: _onNotificationRead,
                        ),
                  ),
                ).then((_) {
                  _loadNotifications();
                });
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
      _notifications.removeWhere(
        (notification) => notification['id'] == notificationId,
      );
    });
  }
}

class NotificationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final String? error;
  final Function(String) onNotificationRead;

  const NotificationScreen({
    super.key,
    required this.notifications,
    required this.isLoading,
    this.error,
    required this.onNotificationRead,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<bool> _isExpandedList = [];

  @override
  void initState() {
    super.initState();
    _isExpandedList = List.generate(
      widget.notifications.length,
      (index) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações'.translate),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child:
              widget.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : widget.error != null
                  ? Text(widget.error!)
                  : widget.notifications.isEmpty
                  ? Text('Nenhuma notificação'.translate)
                  : RefreshIndicator(
                    onRefresh: _refreshNotifications,
                    child: ListView.builder(
                      itemCount: widget.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = widget.notifications[index];
                        return _buildNotificationItem(
                          notification,
                          index,
                          theme,
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    Map<String, dynamic> notification,
    int index,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          notification['content'] ?? 'Sem conteúdo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Toque para ver detalhes',
          style: TextStyle(color: Colors.grey[500]),
        ),
        initiallyExpanded: _isExpandedList[index],
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpandedList[index] = expanded;
          });
        },
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalhes: ${notification['details'] ?? 'Nenhum detalhe adicional.'}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      _handleAction(notification, context);
                    },
                    child: Text(notification['action'] ?? 'Ver Mais'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(
    Map<String, dynamic> notification,
    BuildContext context,
  ) async {
    final url = notification['url'];
    final notificationId = notification['id'];

    if (url != null && url.isNotEmpty) {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível abrir o link: $url')),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Atenção'),
            content: Text(
              'Nenhuma ação extra disponível para esta notificação.',
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    if (notificationId != null) {
      _markNotificationAsRead(notificationId);
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> readNotifications =
        prefs.getStringList('readNotifications') ?? [];
    if (!readNotifications.contains(notificationId)) {
      readNotifications.add(notificationId);
      await prefs.setStringList('readNotifications', readNotifications);
      widget.onNotificationRead(notificationId);
    }
  }

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notificações atualizadas!'.translate)),
    );
  }
}
