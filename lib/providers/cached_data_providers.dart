import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_uploaded_file.dart';
import '../models/attendance.dart';
import '../models/attendance_stats.dart';
import '../models/company.dart';
import '../models/employee_document.dart';
import '../models/business_document.dart';
import '../services/attendance_service.dart';
import '../services/company_service.dart';
import '../services/employee_document_service.dart';
import '../services/business_document_service.dart';
import '../services/employee_service.dart';
import '../services/task_service.dart';
import 'cache_provider.dart';
import 'document_provider.dart';

// PHASE 3A - Multi-role dashboard providers
import 'ceo_dashboard_provider.dart';
import 'manager_provider.dart';
import 'staff_provider.dart';

/// Cached Companies Provider with auto-refresh
/// Uses getMyCompanies() to ensure CEO only sees their own companies
final cachedCompaniesProvider =
    FutureProvider.autoDispose<List<Company>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);

  // Try memory cache first
  final cached = memoryCache.get<List<Company>>('companies');
  if (cached != null) {
    return cached;
  }

  // Fetch from service - using getMyCompanies for data isolation
  final service = ref.watch(companyServiceProvider);
  final companies = await service.getMyCompanies();

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
final cachedCompanyProvider =
    FutureProvider.autoDispose.family<Company?, String>((ref, id) async {
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
final cachedEmployeeDocumentsProvider =
    FutureProvider.autoDispose.family<List<EmployeeDocument>, String>(
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
    memoryCache.set(cacheKey, docs,
        config.shortTTL); // Shorter TTL for frequently changing data

    return docs;
  },
);

/// Cached Labor Contracts Provider
final cachedLaborContractsProvider =
    FutureProvider.autoDispose.family<List<LaborContract>, String>(
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
final cachedBusinessDocumentsProvider =
    FutureProvider.autoDispose.family<List<BusinessDocument>, String>(
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
final cachedComplianceStatusProvider =
    FutureProvider.autoDispose.family<ComplianceStatus, String>(
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
    final status =
        await service.calculateComplianceStatus(companyId: companyId);

    // Cache result (shorter TTL as this is calculated)
    memoryCache.set(cacheKey, status, config.shortTTL);

    return status;
  },
);

/// Cached Company Stats Provider (Overview Tab)
final cachedCompanyStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, companyId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_stats_$companyId';

  // Try memory cache
  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(companyServiceProvider);
  final stats = await service.getCompanyStats(companyId);

  // Cache result (5 min TTL - stats don't change very often)
  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

/// Cached Company Employees Provider (Employees Tab)
final cachedCompanyEmployeesProvider =
    FutureProvider.autoDispose.family<List, String>((ref, companyId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_employees_$companyId';

  // Try memory cache
  final cached = memoryCache.get<List<dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(employeeServiceProvider);
  final employees = await service.getCompanyEmployees(companyId);

  // Cache result (1 min TTL - employee list changes frequently)
  memoryCache.set(cacheKey, employees, config.shortTTL);

  return employees;
});

/// Cached Company Tasks Provider (Tasks Tab)
final cachedCompanyTasksProvider =
    FutureProvider.autoDispose.family<List, String>((ref, companyId) async {
  print('🔵 [CachedProvider] cachedCompanyTasksProvider called for company: $companyId');
  
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_tasks_$companyId';

  // Try memory cache
  final cached = memoryCache.get<List<dynamic>>(cacheKey);
  if (cached != null) {
    print('💾 [CachedProvider] Returning ${cached.length} tasks from cache');
    return cached;
  }

  print('🌐 [CachedProvider] Cache miss, fetching from service...');
  
  // Fetch from service
  final service = ref.watch(taskServiceProvider);
  final tasks = await service.getTasksByCompany(companyId);
  
  print('✅ [CachedProvider] Service returned ${tasks.length} tasks, caching...');
  // Cache result (1 min TTL - tasks change frequently)
  memoryCache.set(cacheKey, tasks, config.shortTTL);

  return tasks;
});

/// Cached Company Task Stats Provider
final cachedCompanyTaskStatsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, companyId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_task_stats_$companyId';

  // Try memory cache
  final cached = memoryCache.get<Map<String, int>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(taskServiceProvider);
  final stats = await service.getCompanyTaskStats(companyId);

  // Cache result (5 min TTL)
  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

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

  /// Invalidate company stats cache (Overview Tab)
  void invalidateCompanyStats(String companyId) {
    invalidate(cachedCompanyStatsProvider(companyId));
    read(memoryCacheProvider).invalidatePattern('company_stats');
  }

  /// Invalidate company employees cache (Employees Tab)
  void invalidateCompanyEmployees(String companyId) {
    invalidate(cachedCompanyEmployeesProvider(companyId));
    read(memoryCacheProvider).invalidatePattern('company_employees');
  }

  /// Invalidate company tasks cache (Tasks Tab)
  void invalidateCompanyTasks(String companyId) {
    invalidate(cachedCompanyTasksProvider(companyId));
    invalidate(cachedCompanyTaskStatsProvider(companyId));
    read(memoryCacheProvider).invalidatePattern('company_tasks');
    read(memoryCacheProvider).invalidatePattern('company_task_stats');
  }

  /// Invalidate company documents cache (Documents Tab)
  void invalidateCompanyDocuments(String companyId) {
    invalidate(cachedCompanyDocumentsProvider(companyId));
    invalidate(cachedDocumentInsightsProvider(companyId));
    read(memoryCacheProvider).invalidatePattern('company_documents');
    read(memoryCacheProvider).invalidatePattern('document_insights');
  }

  /// Invalidate company attendance cache (Attendance Tab)
  void invalidateCompanyAttendance(String companyId, DateTime date) {
    final params = AttendanceQueryParams(companyId: companyId, date: date);
    invalidate(cachedCompanyAttendanceProvider(params));
    invalidate(cachedAttendanceStatsProvider(params));
    read(memoryCacheProvider).invalidatePattern('company_attendance');
    read(memoryCacheProvider).invalidatePattern('attendance_stats');
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

  /// Invalidate CEO dashboard cache
  void invalidateCEODashboard() {
    invalidate(cachedCEODashboardKPIsProvider);
    invalidate(cachedCEODashboardActivitiesProvider);
    read(memoryCacheProvider).invalidatePattern('ceo_dashboard');
  }

  /// Invalidate Manager dashboard cache
  void invalidateManagerDashboard(String? branchId) {
    invalidate(cachedManagerDashboardKPIsProvider(branchId));
    invalidate(
        cachedManagerRecentActivitiesProvider((branchId: branchId, limit: 10)));
    read(memoryCacheProvider).invalidatePattern('manager_dashboard');
    read(memoryCacheProvider).invalidatePattern('manager_activities');
  }

  /// Invalidate Staff stats cache (for Shift Leader & Staff dashboards)
  void invalidateStaffStats(String? userId) {
    invalidate(cachedStaffStatsProvider(userId));
    read(memoryCacheProvider).invalidatePattern('staff_stats');
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
final employeeDocumentServiceProvider =
    Provider<EmployeeDocumentService>((ref) {
  return EmployeeDocumentService();
});

/// Provider for business documents service
final businessDocumentServiceProvider =
    Provider<BusinessDocumentService>((ref) {
  return BusinessDocumentService();
});

/// Provider for employee service
final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService();
});

/// Provider for task service
final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService();
});

/// Provider for company service
final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

/// Cached Company Documents Provider (Documents Tab)
final cachedCompanyDocumentsProvider = FutureProvider.autoDispose
    .family<List<AIUploadedFile>, String>((ref, companyId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'company_documents_$companyId';

  // Try memory cache
  final cached = memoryCache.get<List<AIUploadedFile>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(documentServiceProvider);
  final documents = await service.getCompanyDocuments(companyId);

  // Cache result (5 min TTL - documents don't change very often)
  memoryCache.set(cacheKey, documents, config.defaultTTL);

  return documents;
});

/// Cached Document Insights Provider (Documents Tab)
final cachedDocumentInsightsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, companyId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'document_insights_$companyId';

  // Try memory cache
  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(documentServiceProvider);
  final insights = await service.analyzeDocuments(companyId);

  // Cache result (5 min TTL - insights are computed and don't change often)
  memoryCache.set(cacheKey, insights, config.defaultTTL);

  return insights;
});

/// Parameters for attendance query
class AttendanceQueryParams {
  final String companyId;
  final DateTime date;

  AttendanceQueryParams({
    required this.companyId,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceQueryParams &&
          runtimeType == other.runtimeType &&
          companyId == other.companyId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => companyId.hashCode ^ date.year ^ date.month ^ date.day;
}

/// Helper model for attendance records
class EmployeeAttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeeAvatar;
  final DateTime date;
  final DateTime? checkIn; // Made nullable
  final DateTime? checkOut;
  final AttendanceStatus status;
  final int lateMinutes;
  final double hoursWorked;
  final String? notes;

  EmployeeAttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeAvatar,
    required this.date,
    this.checkIn, // Made nullable
    this.checkOut,
    required this.status,
    required this.lateMinutes,
    required this.hoursWorked,
    this.notes,
  });
}

/// Cached Company Attendance Provider (Attendance Tab)
final cachedCompanyAttendanceProvider = FutureProvider.autoDispose
    .family<List<EmployeeAttendanceRecord>, AttendanceQueryParams>(
        (ref, params) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey =
      'company_attendance_${params.companyId}_${params.date.toString().substring(0, 10)}';

  // Try memory cache
  final cached = memoryCache.get<List<EmployeeAttendanceRecord>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service
  final service = ref.watch(attendanceServiceProvider);
  final records = await service.getCompanyAttendance(
    companyId: params.companyId,
    date: params.date,
  );

  // Convert to EmployeeAttendanceRecord format
  final attendanceRecords = records
      .map((record) => EmployeeAttendanceRecord(
            id: record.id,
            employeeId: record.employeeId,
            employeeName: record.employeeName,
            employeeAvatar: null, // Not available in new schema
            date: record.date,
            checkIn: record.checkInTime,
            checkOut: record.checkOutTime,
            status: record.status,
            lateMinutes: 0, // TODO: Calculate from shift
            hoursWorked: (record.totalWorkedMinutes / 60).toDouble(),
            notes: record.notes,
          ))
      .toList();

  // Cache result (1 min TTL - attendance changes frequently)
  memoryCache.set(cacheKey, attendanceRecords, config.shortTTL);

  return attendanceRecords;
});

/// Cached Attendance Stats Provider (Attendance Tab)
final cachedAttendanceStatsProvider = FutureProvider.autoDispose
    .family<AttendanceStats, AttendanceQueryParams>((ref, params) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey =
      'attendance_stats_${params.companyId}_${params.date.toString().substring(0, 10)}';

  // Try memory cache
  final cached = memoryCache.get<AttendanceStats>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch attendance records
  final attendanceRecords =
      await ref.watch(cachedCompanyAttendanceProvider(params).future);

  final today = params.date;
  final todayStart = DateTime(today.year, today.month, today.day);

  final todayRecords = attendanceRecords.where((record) {
    return record.date.isAfter(todayStart) &&
        record.date.isBefore(todayStart.add(const Duration(days: 1)));
  }).toList();

  final totalToday = todayRecords.length;
  final presentToday =
      todayRecords.where((r) => r.status == AttendanceStatus.present).length;
  final lateToday =
      todayRecords.where((r) => r.status == AttendanceStatus.late).length;
  final absentToday =
      todayRecords.where((r) => r.status == AttendanceStatus.absent).length;

  final stats = AttendanceStats(
    totalEmployees: totalToday,
    presentCount: presentToday,
    lateCount: lateToday,
    absentCount: absentToday,
    onLeaveCount:
        todayRecords.where((r) => r.status == AttendanceStatus.onLeave).length,
    attendanceRate: totalToday > 0 ? (presentToday / totalToday * 100) : 0,
  );

  // Cache result (5 min TTL - stats computed from attendance data)
  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});

// ============================================================================
// PHASE 3A - MULTI-ROLE DASHBOARD CACHING
// ============================================================================

/// Cached CEO Dashboard KPIs Provider (CEO Dashboard)
/// Caches system-wide metrics for CEO overview
final cachedCEODashboardKPIsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'ceo_dashboard_kpis';

  // Try memory cache
  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service using original provider
  final kpis = await ref.watch(ceoDashboardKPIProvider.future);

  // Cache result (5 min TTL - expensive system-wide calculations)
  memoryCache.set(cacheKey, kpis, config.defaultTTL);

  return kpis;
});

/// Cached CEO Dashboard Activities Provider (CEO Dashboard)
/// Caches recent activities across all companies
final cachedCEODashboardActivitiesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'ceo_dashboard_activities';

  // Try memory cache
  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service using original provider
  final activities = await ref.watch(ceoDashboardActivitiesProvider.future);

  // Cache result (1 min TTL - realtime activities)
  memoryCache.set(cacheKey, activities, config.shortTTL);

  return activities;
});

/// Cached Manager Dashboard KPIs Provider (Manager Dashboard)
/// Caches branch-specific metrics for manager overview
final cachedManagerDashboardKPIsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, branchId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'manager_dashboard_kpis_${branchId ?? "all"}';

  // Try memory cache
  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service using original provider
  final kpis = await ref.watch(managerDashboardKPIsProvider(branchId).future);

  // Cache result (5 min TTL - branch metrics change slowly)
  memoryCache.set(cacheKey, kpis, config.defaultTTL);

  return kpis;
});

/// Cached Manager Recent Activities Provider (Manager Dashboard)
/// Caches team activities for manager overview
final cachedManagerRecentActivitiesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String? branchId, int limit})>(
        (ref, params) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey =
      'manager_activities_${params.branchId ?? "all"}_${params.limit}';

  // Try memory cache
  final cached = memoryCache.get<List<Map<String, dynamic>>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service using original provider
  final activities =
      await ref.watch(managerRecentActivitiesProvider(params).future);

  // Cache result (1 min TTL - team activities update frequently)
  memoryCache.set(cacheKey, activities, config.shortTTL);

  return activities;
});

/// Cached Staff Stats Provider (Shift Leader & Staff Dashboards)
/// Caches staff statistics and status
final cachedStaffStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String?>((ref, userId) async {
  final memoryCache = ref.watch(memoryCacheProvider);
  final config = ref.watch(cacheConfigProvider);
  final cacheKey = 'staff_stats_${userId ?? "current"}';

  // Try memory cache
  final cached = memoryCache.get<Map<String, dynamic>>(cacheKey);
  if (cached != null) {
    return cached;
  }

  // Fetch from service using original provider
  final stats = await ref.watch(staffStatsProvider(userId).future);

  // Cache result (5 min TTL - personal stats don't change often)
  memoryCache.set(cacheKey, stats, config.defaultTTL);

  return stats;
});
