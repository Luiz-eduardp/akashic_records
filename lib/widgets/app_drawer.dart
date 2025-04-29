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
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text('Configurações'.translate),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                  advancedDrawerController.hideDrawer();
                },
                splashColor: theme.splashColor,
                hoverColor: theme.hoverColor,
              ),
              ListTile(
                leading: const Icon(Icons.extension),
                title: Text('Plugins'.translate),
                onTap: () {
                  Navigator.pushNamed(context, '/plugins');
                  advancedDrawerController.hideDrawer();
                },
                splashColor: theme.splashColor,
                hoverColor: theme.hoverColor,
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
}
