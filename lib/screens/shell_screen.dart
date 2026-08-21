import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:akashic_records/i18n/i18n.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';
import 'package:akashic_records/screens/library_dashboard_screen.dart';
import 'package:akashic_records/screens/reading_history_screen.dart';
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

  final List<Widget> _pages = const [
    LibraryDashboardScreen(),
    ReadingHistoryScreen(),
    PluginsScreen(),
    SettingsScreen(),
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

    final double navWidth = math.min(screenWidth * 0.92, 540);
    final double dynamicHeight = screenWidth < 360 ? 64 : 70;
    const double dynamicRadius = 36.0;

    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (alwaysVisible) return false;
          if (notification is ScrollUpdateNotification) {
            final pixels = notification.metrics.pixels;
            final delta = pixels - _lastScrollOffset;

            if (delta > scrollThreshold && _navVisible && pixels > 60) {
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
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
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

  Widget _buildFloatingNavBar({
    required BuildContext context,
    required bool isVisible,
    required double width,
    required double height,
    required double radius,
    required Duration duration,
    required ColorScheme colorScheme,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 14 + MediaQuery.of(context).padding.bottom,
      child: Center(
        child: AnimatedSlide(
          duration: duration,
          offset: isVisible ? Offset.zero : const Offset(0, 2.2),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: isVisible ? 1.0 : 0.0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.45)
                        : colorScheme.shadow.withOpacity(0.16),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainer.withOpacity(0.85)
                          : colorScheme.surface.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.5),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: NavigationBar(
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      height: height,
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onItemTapped,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      indicatorColor: colorScheme.primaryContainer,
                      destinations: [
                        _buildNavDest(
                          Icons.local_library_outlined,
                          Icons.local_library,
                          'library',
                        ),
                        _buildNavDest(
                          Icons.auto_stories_outlined,
                          Icons.auto_stories,
                          'history',
                        ),
                        _buildNavDest(
                          Icons.extension_outlined,
                          Icons.extension,
                          'plugins',
                        ),
                        _buildNavDest(
                          Icons.settings_outlined,
                          Icons.settings,
                          'settings',
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
    String labelKey,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final translatedLabel = labelKey.translate;

    return NavigationDestination(
      icon: Icon(icon, color: colorScheme.onSurfaceVariant),
      selectedIcon: Icon(
        activeIcon,
        color: colorScheme.onPrimaryContainer,
      ),
      label: translatedLabel,
      tooltip: translatedLabel,
    );
  }
}
