import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'connection_pool.dart';
import 'memory_cache.dart';
import 'health_monitor.dart';

class DatabaseService {
  final Database _db;
  final ConnectionPool _connectionPool;
  final MemoryCache<String, dynamic> _cache;
  final HealthMonitor _healthMonitor;

  DatabaseService(
    this._db, {
    ConnectionPool? connectionPool,
    MemoryCache<String, dynamic>? cache,
    HealthMonitor? healthMonitor,
  }) : _connectionPool = connectionPool ?? ConnectionPool(),
       _cache = cache ?? MemoryCache<String, dynamic>(maxSize: 500),
       _healthMonitor = healthMonitor ?? HealthMonitor() {
    _setupHealthChecks();
  }

  void _setupHealthChecks() {
    _healthMonitor.registerCheck(
      DatabaseHealthCheck(() async {
        try {
          final result = await rawQuery('SELECT 1');
          return result != null && result.isNotEmpty;
        } catch (_) {
          return false;
        }
      }),
    );
    _healthMonitor.registerCheck(MemoryHealthCheck());
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, {
    List<dynamic>? arguments,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      return await _connectionPool.execute(() async {
        return await _db.rawQuery(sql, arguments).timeout(timeout);
      });
    } catch (e) {
      if (e is TimeoutException) {
        throw Exception('Database query timeout: $sql');
      }
      rethrow;
    }
  }

  Future<dynamic> queryWithCache(
    String table, {
    required String cacheKey,
    bool noCache = false,
    Duration? cacheDuration,
  }) async {
    if (!noCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final result = await rawQuery('SELECT * FROM $table');

    if (!noCache && result.isNotEmpty) {
      _cache.set(cacheKey, result);
    }

    return result;
  }

  @Deprecated('Use rawQuery instead')
  Future<dynamic> queryWithTimeout(
    String sql, {
    List<dynamic>? arguments,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return rawQuery(sql, arguments: arguments, timeout: timeout);
  }

  Future<int> insertWithCache(
    String table,
    Map<String, dynamic> values, {
    String? conflictAlgorithm,
    List<String> cacheKeysToInvalidate = const [],
  }) async {
    try {
      final result = await _connectionPool.execute(() async {
        return await _db.insert(
          table,
          values,
          conflictAlgorithm:
              conflictAlgorithm != null
                  ? ConflictAlgorithm.values.firstWhere(
                    (e) => e.toString().split('.').last == conflictAlgorithm,
                  )
                  : ConflictAlgorithm.abort,
        );
      });

      for (final key in cacheKeysToInvalidate) {
        _cache.remove(key);
      }

      return result;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Insert operation failed: $e');
    }
  }

  Future<int> deleteWithCache(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    List<String> cacheKeysToInvalidate = const [],
  }) async {
    try {
      final result = await _connectionPool.execute(() async {
        return await _db.delete(table, where: where, whereArgs: whereArgs);
      });

      for (final key in cacheKeysToInvalidate) {
        _cache.remove(key);
      }

      return result;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Delete operation failed: $e');
    }
  }

  Future<void> batchOperations(
    Future<void> Function(Batch batch) operations,
  ) async {
    try {
      await _connectionPool.execute(() async {
        final batch = _db.batch();
        await operations(batch);
        await batch.commit(noResult: true);
        _cache.clear();
      });
    } catch (e) {
      throw Exception('Batch operation failed: $e');
    }
  }

  Future<void> pruneOldData({
    required String table,
    required String dateColumn,
    required Duration keepDuration,
  }) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(keepDuration).toIso8601String();
      await deleteWithCache(
        table,
        where: '$dateColumn < ?',
        whereArgs: [cutoffDate],
        cacheKeysToInvalidate: ['$table:all'],
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Prune operation failed: $e');
    }
  }

  Future<void> vacuum() async {
    try {
      await _connectionPool.execute(() async {
        await _db.execute('VACUUM');
      });
      _cache.clear();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Vacuum failed: $e');
    }
  }

  bool get isHealthy => _healthMonitor.isHealthy;
  String? get lastHealthError => _healthMonitor.lastError;

  int get cacheSize => _cache.size;
  int get activeConnections => _connectionPool.activeConnections;
  int get totalConnections => _connectionPool.totalConnections;

  void dispose() {
    _cache.dispose();
    _connectionPool.dispose();
    _healthMonitor.dispose();
  }
}
