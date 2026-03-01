import '../core/services/base_service.dart';
import '../models/company.dart';
import 'branch_service.dart';

/// Company Service
/// Handles all company-related database operations
/// Note: Uses 'companies' table in database (renamed from 'stores')
class CompanyService extends BaseService {
  final _branchService = BranchService();

  /// Get all companies (excludes soft-deleted)
  /// Get all companies (admin only - for platform management)
  Future<List<Company>> getAllCompanies() async {
    return safeCall(
      operation: 'getAllCompanies',
      action: () async {
        final response = await client
            .from('companies')
            .select(
                'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);

        return (response as List).map((json) => Company.fromJson(json)).toList();
      },
    );
  }

  /// Get companies owned by current user (CEO)
  /// This is the PRIMARY method for CEO dashboard - only shows their companies
  Future<List<Company>> getMyCompanies({String? userId}) async {
    return safeCall(
      operation: 'getMyCompanies',
      action: () async {
        if (userId == null) {
          logInfo('getMyCompanies', 'User not authenticated');
          return [];
        }
        
        logInfo('getMyCompanies', 'Fetching for user $userId');
        
        final response = await client
            .from('companies')
            .select('*')
            .or('created_by.eq.$userId,owner_id.eq.$userId')
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false);

        final companies = (response as List).map((json) => Company.fromJson(json)).toList();
        logInfo('getMyCompanies', 'Found ${companies.length} companies');
        return companies;
      },
    );
  }

  /// Get all companies including soft-deleted ones (for admin/restore purposes)
  Future<List<Company>> getAllCompaniesIncludingDeleted() async {
    return safeCall(
      operation: 'getAllCompaniesIncludingDeleted',
      action: () async {
        final response = await client
            .from('companies')
            .select(
                'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
            .order('created_at', ascending: false);

        return (response as List).map((json) => Company.fromJson(json)).toList();
      },
    );
  }

  /// Get company by ID
  Future<Company?> getCompanyById(String id) async {
    return safeCall(
      operation: 'getCompanyById',
      action: () async {
        final response = await client
            .from('companies')
            .select(
                'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
            .eq('id', id)
            .maybeSingle();

        if (response == null) return null;
        return Company.fromJson(response);
      },
    );
  }

  /// Create new company
  Future<Company> createCompany({
    required String name,
    required String userId,
    String? address,
    String? phone,
    String? email,
    String? businessType,
  }) async {
    return safeCall(
      operation: 'createCompany',
      action: () async {
        final response = await client
            .from('companies')
            .insert({
              'name': name,
              'address': address,
              'phone': phone,
              'email': email,
              'business_type':
                  businessType ?? 'restaurant', // Default to restaurant
              'is_active': true,
              'created_by': userId, // ✅ Set CEO as company owner for RLS
            })
            .select(
                'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
            .single();

        final company = Company.fromJson(response);

        // 🎯 Tự động tạo chi nhánh "Trung tâm" cho công ty mới
        try {
          await _branchService.createBranch(
            companyId: company.id,
            name: 'Chi nhánh Trung tâm',
            address: address,
            phone: phone,
            email: email,
          );
        } catch (_) {
          // Không throw error nếu tạo chi nhánh thất bại, công ty vẫn được tạo
        }

        return company;
      },
    );
  }

  /// Update company
  Future<Company> updateCompany(String id, Map<String, dynamic> updates) async {
    return safeCall(
      operation: 'updateCompany',
      action: () async {
        final response = await client
            .from('companies')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        return Company.fromJson(response);
      },
    );
  }

  /// Delete company (soft delete)
  /// Sets deleted_at timestamp instead of actually deleting the record
  Future<void> deleteCompany(String id) async {
    return safeCall(
      operation: 'deleteCompany',
      action: () async {
        await client.from('companies').update({
          'deleted_at': DateTime.now().toIso8601String(),
        }).eq('id', id);
      },
    );
  }

  /// Permanently delete company (hard delete)
  /// ⚠️ USE WITH CAUTION - This is irreversible!
  Future<void> permanentlyDeleteCompany(String id) async {
    return safeCall(
      operation: 'permanentlyDeleteCompany',
      action: () async {
        await client.from('companies').delete().eq('id', id);
      },
    );
  }

  /// Restore a soft-deleted company
  Future<void> restoreCompany(String id) async {
    return safeCall(
      operation: 'restoreCompany',
      action: () async {
        await client.from('companies').update({
          'deleted_at': null,
        }).eq('id', id);
      },
    );
  }

  /// Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    return safeCall(
      operation: 'getCompanyStats',
      action: () async {
        final employeesResponse = await client
            .from('employees')
            .select('id')
            .eq('company_id', companyId);
        final totalEmployees = (employeesResponse as List).length;

        final branchesResponse = await client
            .from('branches')
            .select('id')
            .eq('company_id', companyId);

        final tablesResponse = await client
            .from('tables')
            .select('id')
            .eq('company_id', companyId);

        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final revenueResponse = await client
            .from('daily_revenue')
            .select('amount')
            .eq('company_id', companyId)
            .gte('date', firstDayOfMonth.toIso8601String().split('T')[0]);

        double monthlyRevenue = 0.0;
        for (var record in revenueResponse) {
          monthlyRevenue += (record['amount'] as num?)?.toDouble() ?? 0.0;
        }

        return {
          'employeeCount': totalEmployees,
          'branchCount': (branchesResponse as List).length,
          'tableCount': (tablesResponse as List).length,
          'monthlyRevenue': monthlyRevenue,
        };
      },
    );
  }

  /// Subscribe to company changes
  Stream<List<Company>> subscribeToCompanies() {
    return client
        .from('companies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Company.fromJson(json)).toList());
  }
}
