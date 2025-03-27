import 'package:akashic_records/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:akashic_records/screens/home_screen.dart';
import 'package:akashic_records/screens/settings/settings_screen.dart';
import 'package:akashic_records/screens/plugins/plugins_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:akashic_records/themes/app_themes.dart';
import 'package:provider/provider.dart';
import 'package:akashic_records/state/app_state.dart';

void main() async {
  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.initialize();

  await requestPermissions();

  runApp(
    ChangeNotifierProvider(create: (context) => appState, child: const MyApp()),
  );
}

Future<void> requestPermissions() async {
  final permissions = [
    Permission.storage,
    Permission.mediaLibrary,
    Permission.speech,
    Permission.notification,
  ];

  final statuses = await permissions.request();

  for (final permission in permissions) {
    if (statuses[permission]!.isDenied) {
      print('Permissão ${permission.toString()} negada.');
    } else if (statuses[permission]!.isPermanentlyDenied) {
      print('Permissão ${permission.toString()} negada permanentemente.');

      openAppSettings();
    } else if (statuses[permission]!.isRestricted) {
      print('Permissão ${permission.toString()} restrita.');
    } else {
      print('Permissão ${permission.toString()} concedida.');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final settingsLoaded = appState.settingsLoaded;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppThemes.lightTheme(appState.accentColor),
      darkTheme: AppThemes.darkTheme(appState.accentColor),
      home:
          settingsLoaded
              ? HomeScreen()
              : const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
      routes: {
        '/settings': (context) => SettingsScreen(),
        '/plugins': (context) => PluginsScreen(),
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}
