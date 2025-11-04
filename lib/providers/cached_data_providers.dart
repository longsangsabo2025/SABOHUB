import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/company.dart';
import '../models/employee_document.dart';
import '../models/business_document.dart';
import '../services/company_service.dart';
import '../services/employee_document_service.dart';
import '../services/business_document_service.dart';
import 'cache_provider.dart';

/// Cached Companies Provider with auto-refresh
final cachedCompaniesProvider = FutureProvider.autoDispose<List<Company>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  
  // Try memory cache first
  final cached = memoryCache.get<List<Company>>('companies');
  if (cached != null) {
    return cached;
  }
  
  // Fetch from service
  final service = ref.watch(companyServiceProvider);
  final companies = await service.getAllCompanies();
  
  // Cache result
  memoryCache.set('companies', companies, config.defaultTTL);
  
  // Persist to disk
  try {
    final persistentCache = await ref.read(persistentCacheProvider.future);
    await persistentCache.set(
      'companies',
      companies.map((c) => c.toJson()).toList(),
      config.longTTL,
    );
  } catch (e) {
    // Ignore persistence errors
  }
  
  return companies;
});

/// Cached Company by ID Provider
final cachedCompanyProvider = FutureProvider.autoDispose.family<Company?, String>((ref, id) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_$id';
  
  // Try memory cache
  final cached = memoryCache.get<Company>(cacheKey);
  if (cached != null) {
    return cached;
  }
  
  // Fetch from service
  final service = ref.watch(companyServiceProvider);
  final company = await service.getCompanyById(id);
  
  if (company != null) {
    // Cache result
    memoryCache.set(cacheKey, company, config.defaultTTL);
    
    // Persist to disk
    try {
      final persistentCache = await ref.read(persistentCacheProvider.future);
      await persistentCache.set(cacheKey, company.toJson(), config.longTTL);
    } catch (e) {
      // Ignore
    }
  }
  
  return company;
});

/// Cached Employee Documents Provider
final cachedEmployeeDocumentsProvider = FutureProvider.autoDispose.family<List<EmployeeDocument>, String>(
  (ref, companyId) async {
    final memoryCache = ref.watch(memoryCacheProvider);
    final config = ref.watch(cacheConfigProvider);
    final cacheKey = 'employee_docs_$companyId';
    
    // Try memory cache
    final cached = memoryCache.get<List<EmployeeDocument>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Fetch from service
    final service = ref.watch(employeeDocumentServiceProvider);
    final docs = await service.getEmployeeDocuments(companyId: companyId);
    
    // Cache result
    memoryCache.set(cacheKey, docs, config.shortTTL); // Shorter TTL for frequently changing data
    
    return docs;
  },
);

/// Cached Labor Contracts Provider
final cachedLaborContractsProvider = FutureProvider.autoDispose.family<List<LaborContract>, String>(
  (ref, companyId) async {
    final memoryCache = ref.watch(memoryCacheProvider);
    final config = ref.watch(cacheConfigProvider);
    final cacheKey = 'labor_contracts_$companyId';
    
    // Try memory cache
    final cached = memoryCache.get<List<LaborContract>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Fetch from service
    final service = ref.watch(employeeDocumentServiceProvider);
    final contracts = await service.getLaborContracts(companyId: companyId);
    
    // Cache result
    memoryCache.set(cacheKey, contracts, config.defaultTTL);
    
    return contracts;
  },
);

/// Cached Business Documents Provider
final cachedBusinessDocumentsProvider = FutureProvider.autoDispose.family<List<BusinessDocument>, String>(
  (ref, companyId) async {
    final memoryCache = ref.watch(memoryCacheProvider);
    final config = ref.watch(cacheConfigProvider);
    final cacheKey = 'business_docs_$companyId';
    
    // Try memory cache
    final cached = memoryCache.get<List<BusinessDocument>>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Fetch from service
    final service = ref.watch(businessDocumentServiceProvider);
    final docs = await service.getCompanyDocuments(companyId: companyId);
    
    // Cache result
    memoryCache.set(cacheKey, docs, config.defaultTTL);
    
    // Persist to disk
    try {
      final persistentCache = await ref.read(persistentCacheProvider.future);
      await persistentCache.set(
        cacheKey,
        docs.map((d) => d.toJson()).toList(),
        config.longTTL,
      );
    } catch (e) {
      // Ignore
    }
    
    return docs;
  },
);

/// Cached Compliance Status Provider
final cachedComplianceStatusProvider = FutureProvider.autoDispose.family<ComplianceStatus, String>(
  (ref, companyId) async {
    final memoryCache = ref.watch(memoryCacheProvider);
    final config = ref.watch(cacheConfigProvider);
    final cacheKey = 'compliance_$companyId';
    
    // Try memory cache
    final cached = memoryCache.get<ComplianceStatus>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Fetch from service
    final service = ref.watch(businessDocumentServiceProvider);
    final status = await service.calculateComplianceStatus(companyId: companyId);
    
    // Cache result (shorter TTL as this is calculated)
    memoryCache.set(cacheKey, status, config.shortTTL);
    
    return status;
  },
);

/// Cache invalidation helpers
extension CacheInvalidation on WidgetRef {
  /// Invalidate company cache
  void invalidateCompany(String? companyId) {
    invalidate(cachedCompaniesProvider);
    if (companyId != null) {
      invalidate(cachedCompanyProvider(companyId));
    }
    
    // Clear memory cache
    read(memoryCacheProvider).invalidatePattern('company');
  }
  
  /// Invalidate employee documents cache
  void invalidateEmployeeDocuments(String companyId) {
    invalidate(cachedEmployeeDocumentsProvider(companyId));
    invalidate(cachedLaborContractsProvider(companyId));
    
    // Clear memory cache
    read(memoryCacheProvider).invalidatePattern('employee_docs');
    read(memoryCacheProvider).invalidatePattern('labor_contracts');
  }
  
  /// Invalidate business documents cache
  void invalidateBusinessDocuments(String companyId) {
    invalidate(cachedBusinessDocumentsProvider(companyId));
    invalidate(cachedComplianceStatusProvider(companyId));
    
    // Clear memory cache
    read(memoryCacheProvider).invalidatePattern('business_docs');
    read(memoryCacheProvider).invalidatePattern('compliance');
  }
  
  /// Clear all cache
  Future<void> clearAllCache() async {
    // Clear memory cache
    read(memoryCacheProvider).clear();
    
    // Clear persistent cache
    try {
      final persistentCache = await read(persistentCacheProvider.future);
      await persistentCache.clear();
    } catch (e) {
      // Ignore
    }
    
    // Invalidate all providers
    invalidate(cachedCompaniesProvider);
  }
}

/// Provider for employees service
final employeeDocumentServiceProvider = Provider<EmployeeDocumentService>((ref) {
  return EmployeeDocumentService();
});

/// Provider for business documents service
final businessDocumentServiceProvider = Provider<BusinessDocumentService>((ref) {
  return BusinessDocumentService();
});

/// Provider for company service
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});
