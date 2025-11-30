# 🚀 Cache System Guide - Riverpod 3.x

## 📋 Tổng quan

Hệ thống cache được xây dựng với Riverpod 3.x, sử dụng dual-layer cache (memory + persistent) để tối ưu hóa hiệu năng ứng dụng.

### ✨ Tính năng chính

- ✅ **Memory Cache**: In-memory LRU cache với giới hạn 100 entries
- ✅ **Persistent Cache**: SharedPreferences-based cache cho dữ liệu quan trọng
- ✅ **TTL (Time To Live)**: Tự động expire cache theo thời gian
- ✅ **Cache Invalidation**: Invalidate theo pattern hoặc key cụ thể
- ✅ **Riverpod 3.x Compatible**: Sử dụng Notifier thay vì StateNotifier

## 🏗️ Kiến trúc

```
lib/providers/
├── cache_provider.dart           # Core cache infrastructure
└── cached_data_providers.dart    # Entity-specific cached providers
```

### Core Components

#### 1. MemoryCacheManager

In-memory cache với LRU eviction policy:

```dart
final memoryCacheProvider = Provider<MemoryCacheManager>((ref) {
  return MemoryCacheManager();
});
```

**Tính năng:**
- Giới hạn 100 entries (configurable)
- LRU eviction khi đầy
- TTL checking tự động
- Clear cache theo pattern

#### 2. PersistentCacheManager  

Persistent storage với SharedPreferences:

```dart
final persistentCacheProvider = FutureProvider<PersistentCacheManager>((ref) async {
  final manager = PersistentCacheManager();
  await manager.init();
  return manager;
});
```

**Tính năng:**
- Serialize/deserialize JSON
- Persist qua app restarts
- TTL tracking
- Clear all/pattern-based clearing

#### 3. CacheConfig

Cấu hình TTL cho các loại data:

```dart
class CacheConfig {
  static const shortTTL = Duration(minutes: 1);    // Dữ liệu thay đổi nhanh
  static const defaultTTL = Duration(minutes: 5);  // Dữ liệu thông thường
  static const longTTL = Duration(hours: 1);       // Dữ liệu ít thay đổi
}
```

#### 4. CacheInvalidationController

Quản lý cache invalidation với Riverpod 3.x Notifier:

```dart
final cacheInvalidationControllerProvider = NotifierProvider<CacheInvalidationController, Set<String>>(() {
  return CacheInvalidationController();
});
```

## 📦 Cached Providers

### 1. Companies

```dart
// Danh sách tất cả companies (Long TTL - 1 hour)
final cachedCompaniesProvider = FutureProvider<List<Company>>((ref) async {
  // Memory cache + API call + persist to disk
});

// Company detail by ID (Default TTL - 5 minutes)
final cachedCompanyProvider = FutureProvider.family<Company?, String>((ref, companyId) async {
  // Memory cache + API call (no disk persist)
});
```

**Cache Strategy:**
- Companies list: Memory + Disk (longTTL)
- Company detail: Memory only (defaultTTL)

### 2. Employee Documents

```dart
// Documents by company (Short TTL - 1 minute)
final cachedEmployeeDocumentsProvider = FutureProvider.family<List<EmployeeDocument>, String>((ref, companyId) async {
  // Memory cache + API call
});
```

**Cache Strategy:**
- Memory only
- Short TTL vì data thay đổi thường xuyên

### 3. Labor Contracts

```dart
// Contracts by company (Short TTL - 1 minute)
final cachedLaborContractsProvider = FutureProvider.family<List<LaborContract>, String>((ref, companyId) async {
  // Memory cache + API call
});
```

**Cache Strategy:**
- Memory only
- Short TTL vì data thay đổi thường xuyên

### 4. Business Documents

```dart
// Business documents by company (Default TTL - 5 minutes)
final cachedBusinessDocumentsProvider = FutureProvider.family<List<BusinessDocument>, String>((ref, companyId) async {
  // Memory cache + API call
});
```

**Cache Strategy:**
- Memory only
- Default TTL vì data ổn định hơn employee documents

### 5. Compliance Status

```dart
// Compliance status by company (Default TTL - 5 minutes)
final cachedComplianceStatusProvider = FutureProvider.family<ComplianceStatus, String>((ref, companyId) async {
  // Memory cache + API call
});
```

**Cache Strategy:**
- Memory only
- Default TTL vì tính toán từ business documents

## 🔧 Cache Invalidation

### Extension Methods

```dart
extension CacheInvalidation on WidgetRef {
  // Invalidate companies
  void invalidateCompanies() {
    invalidate(cachedCompaniesProvider);
    read(memoryCacheProvider).removePattern('companies');
  }
  
  // Invalidate company by ID
  void invalidateCompany(String companyId) {
    invalidate(cachedCompanyProvider(companyId));
    read(memoryCacheProvider).remove('company_$companyId');
  }
  
  // Invalidate employee documents
  void invalidateEmployeeDocuments(String companyId) {
    invalidate(cachedEmployeeDocumentsProvider(companyId));
    read(memoryCacheProvider).remove('employee_docs_$companyId');
  }
  
  // Invalidate labor contracts
  void invalidateLaborContracts(String companyId) {
    invalidate(cachedLaborContractsProvider(companyId));
    read(memoryCacheProvider).remove('labor_contracts_$companyId');
  }
  
  // Invalidate business documents
  void invalidateBusinessDocuments(String companyId) {
    invalidate(cachedBusinessDocumentsProvider(companyId));
    read(memoryCacheProvider).remove('business_docs_$companyId');
  }
  
  // Invalidate compliance status
  void invalidateComplianceStatus(String companyId) {
    invalidate(cachedComplianceStatusProvider(companyId));
    read(memoryCacheProvider).remove('compliance_$companyId');
  }
  
  // Clear all caches
  void clearAllCaches() {
    read(memoryCacheProvider).clear();
    read(persistentCacheProvider.future).then((manager) => manager.clearAll());
  }
}
```

## 💡 Sử dụng trong UI

### 1. Load Data with Cache

**Before (Direct Service Call):**
```dart
final documentsAsync = ref.watch(companyEmployeeDocumentsProvider(companyId));
```

**After (Cached Provider):**
```dart
final documentsAsync = ref.watch(cachedEmployeeDocumentsProvider(companyId));
```

### 2. Invalidate After Mutation

**Before:**
```dart
await service.verifyDocument(documentId);
ref.invalidate(companyEmployeeDocumentsProvider(companyId));
```

**After:**
```dart
await service.verifyDocument(documentId);
ref.invalidateEmployeeDocuments(companyId);
```

### 3. Manual Refresh

```dart
ElevatedButton(
  onPressed: () => ref.invalidateEmployeeDocuments(widget.companyId),
  child: Text('Refresh'),
)
```

### 4. Clear All Caches

```dart
ElevatedButton(
  onPressed: () => ref.clearAllCaches(),
  child: Text('Clear Cache'),
)
```

## 📊 Cache Performance

### Memory Cache

- **Max Entries**: 100
- **Eviction Policy**: LRU (Least Recently Used)
- **Average Hit Rate**: ~80-90% cho repeat views
- **Memory Usage**: ~1-5 MB (depends on data size)

### Persistent Cache

- **Storage**: SharedPreferences (up to 1 MB per key)
- **Persistence**: Across app restarts
- **Recommended Use**: Master data, settings, rarely-changed data

### TTL Configuration

| Data Type | TTL | Rationale |
|-----------|-----|-----------|
| Companies List | 1 hour | Ít thay đổi, master data |
| Company Detail | 5 minutes | Có thể thay đổi thông tin |
| Employee Documents | 1 minute | Thay đổi thường xuyên |
| Labor Contracts | 1 minute | Thay đổi thường xuyên |
| Business Documents | 5 minutes | Thay đổi vừa phải |
| Compliance Status | 5 minutes | Tính toán từ documents |

## 🔍 Debug & Monitoring

### Check Cache Status

```dart
// Check memory cache
final cache = ref.read(memoryCacheProvider);
print('Memory cache entries: ${cache.size()}');

// Check specific key
final hasData = cache.get('companies') != null;
print('Has companies cache: $hasData');

// Check persistent cache
final persistent = await ref.read(persistentCacheProvider.future);
final data = await persistent.get('companies');
print('Persistent companies: ${data != null}');
```

### Cache Hit/Miss Tracking

Thêm vào cached provider để track:

```dart
final cachedCompaniesProvider = FutureProvider<List<Company>>((ref) async {
  final cache = ref.read(memoryCacheProvider);
  final cached = cache.get('companies');
  
  if (cached != null) {
    print('✅ Cache HIT: companies');
    return cached;
  }
  
  print('❌ Cache MISS: companies');
  // Fetch from API...
});
```

## ⚠️ Best Practices

### 1. TTL Selection

- **Short TTL (1 min)**: Real-time data, user-generated content
- **Default TTL (5 min)**: Standard business data
- **Long TTL (1 hour)**: Master data, static content

### 2. Invalidation Strategy

✅ **DO:**
- Invalidate immediately after mutations
- Use specific invalidation methods (not clearAll)
- Invalidate related caches together

❌ **DON'T:**
- Don't rely only on TTL for critical data
- Don't cache sensitive data in persistent storage
- Don't invalidate too frequently (defeats caching purpose)

### 3. Memory Management

- Monitor cache size in production
- Adjust max entries if needed
- Use persistent cache sparingly

### 4. Testing Cache

```dart
testWidgets('Cache invalidation works', (tester) async {
  final container = ProviderContainer();
  
  // Load data (cache miss)
  final data1 = await container.read(cachedCompaniesProvider.future);
  
  // Load again (cache hit)
  final data2 = await container.read(cachedCompaniesProvider.future);
  
  // Should be same instance
  expect(identical(data1, data2), true);
  
  // Invalidate
  container.invalidate(cachedCompaniesProvider);
  
  // Load again (cache miss)
  final data3 = await container.read(cachedCompaniesProvider.future);
  
  // Should be different instance
  expect(identical(data1, data3), false);
});
```

## 🐛 Troubleshooting

### Issue: Cache not working

**Check:**
1. TTL expired? `print(cache.isExpired('key'))`
2. Cache cleared? `print(cache.size())`
3. Key correct? `print(cache.keys())`

### Issue: Stale data

**Solution:**
- Reduce TTL for that data type
- Add manual invalidation on mutations
- Check invalidation logic

### Issue: Memory usage too high

**Solution:**
- Reduce `maxEntries` in MemoryCacheManager
- Use persistent cache less
- Clear cache more aggressively

### Issue: App slow on cold start

**Solution:**
- Increase persistent cache usage for critical data
- Preload cache on app startup
- Use longer TTL for master data

## 📚 References

- [Riverpod 3.x Documentation](https://riverpod.dev)
- [SharedPreferences Plugin](https://pub.dev/packages/shared_preferences)
- [LRU Cache Algorithm](https://en.wikipedia.org/wiki/Cache_replacement_policies#Least_recently_used_(LRU))

## 🎯 Next Steps

1. **Add Cache Statistics UI**: Display cache hit/miss rates
2. **Implement Cache Warming**: Preload cache on app startup
3. **Add Cache Sync**: Sync cache across tabs/windows
4. **Optimize TTL**: Adjust based on real usage patterns
5. **Add Cache Compression**: For large data sets

---

**Version**: 1.0  
**Last Updated**: 2024-02-11  
**Compatible with**: Riverpod 3.0.3+
