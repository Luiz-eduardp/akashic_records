import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
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
  bool _navVisible = true;
  double _lastScrollOffset = 0.0;

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
  const double navBarHeight = 56.0;
  const double navBarBottom = 16.0;
  final double navWidth = math.min(MediaQuery.of(context).size.width * 0.95, 600);
  final double screenWidth = MediaQuery.of(context).size.width;
  final appState = Provider.of<AppState>(context);
  final bool alwaysVisible = appState.navAlwaysVisible;
  final double scrollThreshold = appState.navScrollThreshold;
  final Duration animDuration = Duration(milliseconds: appState.navAnimationMs);
    final double dynamicHeight = screenWidth < 360 ? 52 : (screenWidth < 600 ? 56 : 64);
    final double dynamicRadius = screenWidth < 360 ? 16 : (screenWidth < 600 ? 20 : 28);
    final labelBehavior = screenWidth < 360
        ? NavigationDestinationLabelBehavior.alwaysHide
        : NavigationDestinationLabelBehavior.alwaysShow;
    return SafeArea(
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (alwaysVisible) return false;
            if (notification is ScrollUpdateNotification) {
              final pixels = notification.metrics.pixels;
              final delta = pixels - _lastScrollOffset;
              _lastScrollOffset = pixels;
              if (delta > scrollThreshold && _navVisible) {
                setState(() => _navVisible = false);
              } else if (delta < -scrollThreshold && !_navVisible) {
                setState(() => _navVisible = true);
              }
            }
            return false;
          },
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  bottom: navBarHeight + navBarBottom + MediaQuery.of(context).padding.bottom,
                ),
                child: _pages[_selectedIndex],
              ),
              Positioned(
                top: 8,
                left: 8,
                child: SafeArea(
                  child: IconButton(
                    tooltip: 'settings'.translate,
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            onLocaleChanged: (locale) async {
                              await I18n.updateLocate(locale);
                              (context as Element).markNeedsBuild();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: AnimatedSlide(
                      duration: animDuration,
                      offset: _navVisible || alwaysVisible ? Offset.zero : const Offset(0, 1.4),
                      curve: Curves.easeInOut,
                      child: AnimatedOpacity(
                        duration: animDuration,
                        opacity: _navVisible || alwaysVisible ? 1.0 : 0.0,
                        curve: Curves.easeInOut,
                        child: AnimatedPhysicalModel(
                          duration: animDuration,
                          shape: BoxShape.rectangle,
                          elevation: _navVisible || alwaysVisible ? 8 : 0,
                          color: Theme.of(context).colorScheme.surface,
                          shadowColor: Colors.black54,
                          borderRadius: BorderRadius.circular(dynamicRadius),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(dynamicRadius),
                            child: SizedBox(
                              width: navWidth,
                              child: NavigationBar(
                                height: dynamicHeight,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                selectedIndex: _selectedIndex,
                                onDestinationSelected: _onItemTapped,
                                labelBehavior: labelBehavior,
                                destinations: [
                                  NavigationDestination(
                                    icon: Icon(Icons.home),
                                    label: 'home'.translate,
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.favorite),
                                    label: 'favorites'.translate,
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.update),
                                    label: 'updates'.translate,
                                  ),
                                  NavigationDestination(
                                    icon: Icon(Icons.extension),
                                    label: 'plugins'.translate,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
