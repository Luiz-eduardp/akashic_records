import 'package:akashic_records/utils/launchUrl.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';

class AppDrawer extends StatelessWidget {
  final AdvancedDrawerController advancedDrawerController;

  const AppDrawer({super.key, required this.advancedDrawerController});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: ListTileTheme(
          textColor: colorScheme.onSurface,
          iconColor: colorScheme.onSurface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 16.0,
                ),
                width: double.infinity,
                child: Text(
                  'Akashic Records',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDrawerTile(
                context: context,
                icon: Icons.settings,
                title: 'Configurações'.translate,
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                  advancedDrawerController.hideDrawer();
                },
              ),
              _buildDrawerTile(
                context: context,
                icon: Icons.extension,
                title: 'Plugins'.translate,
                onTap: () {
                  Navigator.pushNamed(context, '/plugins');
                  advancedDrawerController.hideDrawer();
                },
              ),
              _buildDrawerTile(
                context: context,
                icon: Icons.discord,
                title: "Discord",
                onTap: () => launchURL('https://discord.gg/eSuc2znz5V'),
              ),
              _buildDrawerTile(
                context: context,
                icon: Icons.volunteer_activism,
                title: "Github Sponsor",
                onTap:
                    () => launchURL('https://github.com/sponsors/Luiz-eduardp'),
              ),
              const Spacer(),
              DefaultTextStyle(
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Akashic Records App',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
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

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurface),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        splashColor: colorScheme.secondaryContainer,
        hoverColor: colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
    );
  }
}
