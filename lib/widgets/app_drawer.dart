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

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: ListTileTheme(
          textColor: theme.colorScheme.onSurfaceVariant,
          iconColor: theme.colorScheme.onSurfaceVariant,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 35),
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
                icon: Icons.paid,
                title: "Github Sponsor",
                onTap:
                    () => launchURL(
                      'https://github.com/sponsors/AkashicRecordsApp',
                    ),
              ),
              const Spacer(),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: const Text('Akashic Records App'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: onTap,
        splashColor: theme.splashColor,
        hoverColor: theme.hoverColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}
