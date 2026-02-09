import 'dart:async';

class ConnectionPool {
  static const int maxConnections = 5;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration idleTimeout = Duration(minutes: 5);

  final List<_PooledConnection> _connections = [];
  final Map<_PooledConnection, DateTime> _lastUsed = {};
  Timer? _cleanupTimer;
  int _activeConnections = 0;

  ConnectionPool() {
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupIdleConnections();
    });
  }

  void _cleanupIdleConnections() {
    final now = DateTime.now();
    final toRemove = <_PooledConnection>[];

    for (final conn in _connections) {
      if (_lastUsed[conn] != null) {
        final idle = now.difference(_lastUsed[conn]!);
        if (idle > idleTimeout) {
          toRemove.add(conn);
        }
      }
    }

    for (final conn in toRemove) {
      _connections.remove(conn);
      _lastUsed.remove(conn);
      conn.dispose();
    }
  }

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_activeConnections >= maxConnections) {
      throw Exception('Connection pool exhausted');
    }

    _activeConnections++;
    try {
      return await operation().timeout(
        connectionTimeout,
        onTimeout: () => throw TimeoutException('Database operation timeout'),
      );
    } finally {
      _activeConnections--;
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    for (final conn in _connections) {
      conn.dispose();
    }
    _connections.clear();
    _lastUsed.clear();
  }

  int get activeConnections => _activeConnections;
  int get totalConnections => _connections.length;
}

class _PooledConnection {
  void dispose() {}
}
