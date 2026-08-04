import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/favorites_screen.dart';
import 'package:akashic_records/screens/plugins_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/screens/offline_library_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  bool _navVisible = true;
  double _lastScrollOffset = 0.0;

  List<Widget> _basePages() => const [
    HomeScreen(),
    FavoritesScreen(),
    PluginsScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    final alwaysVisible = context.select((AppState s) => s.navAlwaysVisible);
    final scrollThreshold = context.select(
      (AppState s) => s.navScrollThreshold,
    );
    final animDuration = Duration(
      milliseconds: context.select((AppState s) => s.navAnimationMs),
    );

    final double navWidth = math.min(screenWidth * 0.98, 600);
    final double dynamicHeight = screenWidth < 360 ? 60 : 66;
    final double dynamicRadius = 32.0;

    return Scaffold(
      extendBody: true,
 body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (alwaysVisible) return false;
          if (notification is ScrollUpdateNotification) {
            final pixels = notification.metrics.pixels;
            final delta = pixels - _lastScrollOffset;

            if (delta > scrollThreshold && _navVisible && pixels > 50) {
              setState(() => _navVisible = false);
            } else if (delta < -scrollThreshold && !_navVisible) {
              setState(() => _navVisible = true);
            }
            _lastScrollOffset = pixels;
          }
          return false;
        },
        child: Stack(
          children: [
            Builder(
              builder: (ctx) {
                final pages = <Widget>[..._basePages()];
                final destinations = <NavigationDestination>[
                  _buildNavDest(Icons.home_outlined, Icons.home, 'home'),
                  _buildNavDest(
                    Icons.favorite_border,
                    Icons.favorite,
                    'favorites',
                  ),
                  _buildNavDest(
                    Icons.auto_awesome_outlined,
                    Icons.auto_awesome,
                    'updates',
                  ),
                  _buildNavDest(
                    Icons.extension_outlined,
                    Icons.extension,
                    'plugins',
                  ),
                ];
                pages.add(const OfflineLibraryScreen());
                destinations.add(
                  _buildNavDest(Icons.cloud_off, Icons.cloud_off, 'offline'),
                );

                if (_selectedIndex >= pages.length) _selectedIndex = 0;

                return IndexedStack(index: _selectedIndex, children: pages);
              },
            ),

            _buildFloatingNavBar(
              context: context,
              isVisible: _navVisible || alwaysVisible,
              width: navWidth,
              height: dynamicHeight,
              radius: dynamicRadius,
              duration: animDuration,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar({
    required BuildContext context,
    required bool isVisible,
    required double width,
    required double height,
    required double radius,
    required Duration duration,
    required ColorScheme colorScheme,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20 + MediaQuery.of(context).padding.bottom,
      child: Center(
        child: AnimatedSlide(
          duration: duration,
          offset: isVisible ? Offset.zero : const Offset(0, 2.0),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isVisible ? 1.0 : 0.0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: colorScheme.surface.withOpacity(0.85),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 56.0),
                          child: Builder(
                            builder: (ctx2) {
                              final isOnline = ctx2.select(
                                (AppState s) => s.isOnline,
                              );
                              final dests = <NavigationDestination>[
                                _buildNavDest(
                                  Icons.home_outlined,
                                  Icons.home,
                                  'home',
                                ),
                                _buildNavDest(
                                  Icons.favorite_border,
                                  Icons.favorite,
                                  'favorites',
                                ),
                                _buildNavDest(
                                  Icons.extension_outlined,
                                  Icons.extension,
                                  'plugins',
                                ),
                              ];
                              if (!isOnline)
                                dests.add(
                                  _buildNavDest(
                                    Icons.cloud_off,
                                    Icons.cloud_off,
                                    'offline',
                                  ),
                                );
                              return NavigationBar(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                height: height,
                                selectedIndex: _selectedIndex,
                                onDestinationSelected: (i) {
                                  _onItemTapped(i);
                                },
                                labelBehavior:
                                    NavigationDestinationLabelBehavior
                                        .alwaysHide,
                                indicatorColor: colorScheme.primaryContainer,
                                destinations: dests,
                              );
                            },
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: _buildGlassIconButton(
                                icon: Icons.settings_outlined,
                                onPressed: () => _openSettings(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDest(
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(
        activeIcon,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      label: label.translate,
      tooltip: label.translate,
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SettingsScreen(
              onLocaleChanged: (locale) async {
                await I18n.updateLocate(locale);
                if (mounted) setState(() {});
              },
            ),
      ),
    );
  }
}
