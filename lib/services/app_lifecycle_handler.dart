import 'package:flutter/material.dart';
import 'package:akashic_records/state/app_state.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  final AppState appState;

  AppLifecycleHandler(this.appState);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAppPaused() {
    debugPrint('[AppLifecycle] App paused - ensuring data persistence');
    _ensureDataPersistence();
  }

  void _onAppDetached() {
    debugPrint('[AppLifecycle] App detached - final data persistence');
    _ensureDataPersistence();
  }

  void _ensureDataPersistence() {
    try {
      appState
          .ensureDataPersistence()
          .then((_) {
            debugPrint('[AppLifecycle] Data persistence completed');
          })
          .catchError((e) {
            debugPrint('[AppLifecycle] Data persistence error: $e');
          });
    } catch (e) {
      debugPrint('[AppLifecycle] Error during data persistence: $e');
    }
  }
}
