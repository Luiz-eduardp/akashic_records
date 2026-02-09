import 'dart:async';

class MemoryCache<K, V> {
  final int maxSize;
  final Duration expiration;
  final _cache = <K, _CacheEntry<V>>{};
  Timer? _cleanupTimer;

  MemoryCache({
    this.maxSize = 1000,
    this.expiration = const Duration(hours: 1),
  }) {
    _startCleanupTimer();
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _removeExpired();
    });
  }

  void _removeExpired() {
    final now = DateTime.now();
    final toRemove = <K>[];

    _cache.forEach((key, entry) {
      if (now.difference(entry.createdAt) > expiration) {
        toRemove.add(key);
      }
    });

    for (final key in toRemove) {
      _cache.remove(key);
    }
  }

  void set(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    }

    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(value, DateTime.now());
  }

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.createdAt) > expiration) {
      _cache.remove(key);
      return null;
    }

    _cache.remove(key);
    _cache[key] = entry;
    return entry.value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  void remove(K key) => _cache.remove(key);

  void clear() => _cache.clear();

  int get size => _cache.length;

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime createdAt;

  _CacheEntry(this.value, this.createdAt);
}
