import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Cache entry with metadata
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  
  const CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
  
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
  
  Duration get remainingTime {
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = ttl - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Cache configuration
class CacheConfig {
  final Duration defaultTTL;
  final Duration shortTTL;
  final Duration longTTL;
  final int maxMemoryEntries;
  final bool enablePersistence;
  
  const CacheConfig({
    this.defaultTTL = const Duration(minutes: 5),
    this.shortTTL = const Duration(minutes: 1),
    this.longTTL = const Duration(hours: 1),
    this.maxMemoryEntries = 100,
    this.enablePersistence = true,
  });
}

/// Cache provider configuration
final cacheConfigProvider = Provider<CacheConfig>((ref) {
  return const CacheConfig();
});

/// Shared preferences provider
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// In-memory cache manager
class MemoryCacheManager {
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Map<String, Duration> _ttls = {};
  final int maxEntries;
  
  MemoryCacheManager({this.maxEntries = 100});
  
  /// Get cached data
  T? get<T>(String key) {
    final timestamp = _timestamps[key];
    final ttl = _ttls[key];
    
    if (timestamp == null || ttl == null) return null;
    
    // Check if expired
    if (DateTime.now().difference(timestamp) > ttl) {
      remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }
  
  /// Set cached data
  void set<T>(String key, T data, Duration ttl) {
    // Enforce max entries
    if (_cache.length >= maxEntries && !_cache.containsKey(key)) {
      _evictOldest();
    }
    
    _cache[key] = data;
    _timestamps[key] = DateTime.now();
    _ttls[key] = ttl;
  }
  
  /// Remove cached data
  void remove(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
    _ttls.remove(key);
  }
  
  /// Clear all cache
  void clear() {
    _cache.clear();
    _timestamps.clear();
    _ttls.clear();
  }
  
  /// Invalidate cache by pattern
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      remove(key);
    }
  }
  
  /// Evict oldest entry
  void _evictOldest() {
    if (_timestamps.isEmpty) return;
    
    final oldestKey = _timestamps.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    remove(oldestKey);
  }
  
  /// Get cache stats
  Map<String, dynamic> getStats() {
    return {
      'total_entries': _cache.length,
      'max_entries': maxEntries,
      'usage_percent': (_cache.length / maxEntries * 100).toStringAsFixed(1),
      'keys': _cache.keys.toList(),
    };
  }
}

/// Memory cache provider
final memoryCacheProvider = Provider<MemoryCacheManager>((ref) {
  final config = ref.watch(cacheConfigProvider);
  return MemoryCacheManager(maxEntries: config.maxMemoryEntries);
});

/// Persistent cache manager (using SharedPreferences)
class PersistentCacheManager {
  final SharedPreferences _prefs;
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'cache_ts_';
  static const String _ttlPrefix = 'cache_ttl_';
  
  PersistentCacheManager(this._prefs);
  
  /// Get cached data
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      final ttlKey = '$_ttlPrefix$key';
      
      final jsonString = _prefs.getString(cacheKey);
      final timestamp = _prefs.getInt(timestampKey);
      final ttlSeconds = _prefs.getInt(ttlKey);
      
      if (jsonString == null || timestamp == null || ttlSeconds == null) {
        return null;
      }
      
      // Check if expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final ttl = Duration(seconds: ttlSeconds);
      
      if (DateTime.now().difference(cacheTime) > ttl) {
        await remove(key);
        return null;
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  /// Get list of cached data
  Future<List<T>?> getList<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      final ttlKey = '$_ttlPrefix$key';
      
      final jsonString = _prefs.getString(cacheKey);
      final timestamp = _prefs.getInt(timestampKey);
      final ttlSeconds = _prefs.getInt(ttlKey);
      
      if (jsonString == null || timestamp == null || ttlSeconds == null) {
        return null;
      }
      
      // Check if expired
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final ttl = Duration(seconds: ttlSeconds);
      
      if (DateTime.now().difference(cacheTime) > ttl) {
        await remove(key);
        return null;
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }
  
  /// Set cached data
  Future<void> set(String key, dynamic data, Duration ttl) async {
    try {
      final cacheKey = '$_cachePrefix$key';
      final timestampKey = '$_timestampPrefix$key';
      final ttlKey = '$_ttlPrefix$key';
      
      final jsonString = jsonEncode(data);
      
      await _prefs.setString(cacheKey, jsonString);
      await _prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setInt(ttlKey, ttl.inSeconds);
    } catch (e) {
      // Silently fail
    }
  }
  
  /// Remove cached data
  Future<void> remove(String key) async {
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    final ttlKey = '$_ttlPrefix$key';
    
    await _prefs.remove(cacheKey);
    await _prefs.remove(timestampKey);
    await _prefs.remove(ttlKey);
  }
  
  /// Clear all cache
  Future<void> clear() async {
    final keys = _prefs.getKeys();
    final cacheKeys = keys.where((key) => 
        key.startsWith(_cachePrefix) || 
        key.startsWith(_timestampPrefix) ||
        key.startsWith(_ttlPrefix)
    );
    
    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }
  }
  
  /// Invalidate cache by pattern
  Future<void> invalidatePattern(String pattern) async {
    final keys = _prefs.getKeys();
    final keysToRemove = keys
        .where((key) => key.startsWith(_cachePrefix) && key.contains(pattern))
        .map((key) => key.replaceFirst(_cachePrefix, ''))
        .toList();
    
    for (final key in keysToRemove) {
      await remove(key);
    }
  }
}

/// Persistent cache provider
final persistentCacheProvider = FutureProvider<PersistentCacheManager>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return PersistentCacheManager(prefs);
});

/// Cache invalidation controller using Notifier (Riverpod 3.x)
class CacheInvalidationController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  
  /// Invalidate specific key
  void invalidate(String key) {
    state = {...state, key};
  }
  
  /// Invalidate multiple keys
  void invalidateMultiple(List<String> keys) {
    state = {...state, ...keys};
  }
  
  /// Invalidate by pattern
  void invalidatePattern(String pattern) {
    state = {...state, pattern};
  }
  
  /// Clear invalidation state
  void clear() {
    state = {};
  }
  
  /// Check if key is invalidated
  bool isInvalidated(String key) {
    return state.contains(key);
  }
}

/// Cache invalidation provider
final cacheInvalidationProvider = NotifierProvider<CacheInvalidationController, Set<String>>(() {
  return CacheInvalidationController();
});
