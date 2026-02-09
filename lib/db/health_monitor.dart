import 'dart:async';
import 'package:flutter/foundation.dart';

class HealthMonitor {
  static const Duration checkInterval = Duration(seconds: 30);
  static const Duration maxDatabaseLatency = Duration(seconds: 5);
  static const int maxMemoryMB = 512;

  Timer? _monitorTimer;
  final List<HealthCheck> _checks = [];
  bool _isHealthy = true;
  DateTime? _lastCheck;
  String? _lastError;

  bool get isHealthy => _isHealthy;
  String? get lastError => _lastError;
  DateTime? get lastCheck => _lastCheck;

  HealthMonitor() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(checkInterval, (_) {
      _performHealthChecks();
    });
  }

  Future<void> _performHealthChecks() async {
    try {
      _lastCheck = DateTime.now();
      _lastError = null;
      _isHealthy = true;

      for (final check in _checks) {
        try {
          final result = await check.run();
          if (!result) {
            _isHealthy = false;
            _lastError = '${check.name} failed';
            if (kDebugMode) print('Health check failed: ${check.name}');
            break;
          }
        } catch (e) {
          _isHealthy = false;
          _lastError = '${check.name}: $e';
          if (kDebugMode) print('Health check error: ${check.name} - $e');
          break;
        }
      }
    } catch (e) {
      _isHealthy = false;
      _lastError = 'Health monitor error: $e';
    }
  }

  void registerCheck(HealthCheck check) {
    _checks.add(check);
  }

  Future<void> recover() async {
    if (kDebugMode) print('Attempting to recover...');
  }

  void dispose() {
    _monitorTimer?.cancel();
  }
}

abstract class HealthCheck {
  String get name;
  Future<bool> run();
}

class DatabaseHealthCheck implements HealthCheck {
  final Future<bool> Function() testQuery;

  DatabaseHealthCheck(this.testQuery);

  @override
  String get name => 'Database';

  @override
  Future<bool> run() async {
    try {
      return await testQuery().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }
}

class MemoryHealthCheck implements HealthCheck {
  @override
  String get name => 'Memory';

  @override
  Future<bool> run() async {
    return true;
  }
}
