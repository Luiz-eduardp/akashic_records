import 'package:akashic_records/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/i18n/i18n.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final ReaderSettings readerSettings;
  final VoidCallback onSettingsPressed;

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.readerSettings,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: readerSettings.backgroundColor,
      foregroundColor: readerSettings.textColor,
      elevation: 1,
      scrolledUnderElevation: 3,
      centerTitle: true,
      title: Text(
        title ?? "Carregando...".translate,
        style: theme.textTheme.titleLarge?.copyWith(
          color: readerSettings.textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: readerSettings.textColor),
          onPressed: onSettingsPressed,
          tooltip: 'Configurações de Leitura'.translate,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}