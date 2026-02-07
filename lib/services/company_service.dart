import 'package:flutter/foundation.dart';

import '../core/services/supabase_service.dart';
import '../models/company.dart';
import 'branch_service.dart';

/// Company Service
/// Handles all company-related database operations
/// Note: Uses 'companies' table in database (renamed from 'stores')
class CompanyService {
  final _supabase = supabase.client;
  final _branchService = BranchService();

  /// Get all companies (excludes soft-deleted)
  /// Get all companies (admin only - for platform management)
  Future<List<Company>> getAllCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select(
              'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
          .isFilter('deleted_at', null) // Only get non-deleted companies
          .order('created_at', ascending: false);

      return (response as List).map((json) => Company.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch companies: $e');
    }
  }

  /// Get companies owned by current user (CEO)
  /// This is the PRIMARY method for CEO dashboard - only shows their companies
  Future<List<Company>> getMyCompanies({String? userId}) async {
    try {
      if (userId == null) {
        debugPrint('🏢 getMyCompanies: User not authenticated');
        return [];
      }
      
      debugPrint('🏢 getMyCompanies: Fetching for user $userId');
      
      final response = await _supabase
          .from('companies')
          .select('*')
          .or('created_by.eq.$userId,owner_id.eq.$userId')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final companies = (response as List).map((json) => Company.fromJson(json)).toList();
      debugPrint('🏢 getMyCompanies: Found ${companies.length} companies');
      return companies;
    } catch (e) {
      debugPrint('🏢 getMyCompanies ERROR: $e');
      throw Exception('Failed to fetch my companies: $e');
    }
  }

  /// Get all companies including soft-deleted ones (for admin/restore purposes)
  Future<List<Company>> getAllCompaniesIncludingDeleted() async {
    try {
      final response = await _supabase
          .from('companies')
          .select(
              'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
          .order('created_at', ascending: false);

      return (response as List).map((json) => Company.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all companies: $e');
    }
  }

  /// Get company by ID
  Future<Company?> getCompanyById(String id) async {
    try {
      final response = await _supabase
          .from('companies')
          .select(
              'id, name, address, phone, email, business_type, is_active, created_at, updated_at')
          .eq('id', id)
          .single();

      return Company.fromJson(response);
    } catch (e) {
      return null;
    }
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
    try {

      // ✅ Insert company WITH created_by (CEO owner)
      final response = await _supabase
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
          address: address, // Dùng địa chỉ công ty
          phone: phone, // Dùng số điện thoại công ty
          email: email, // Dùng email công ty
        );
      } catch (branchError) {
        // Không throw error nếu tạo chi nhánh thất bại, công ty vẫn được tạo
      }

      return company;
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  /// Update company
  Future<Company> updateCompany(String id, Map<String, dynamic> updates) async {
    debugPrint('🏢 CompanyService.updateCompany - ID: $id');
    debugPrint('🏢 Updates: $updates');
    try {
      final response = await _supabase
          .from('companies')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      debugPrint('🏢 Response: $response');
      return Company.fromJson(response);
    } catch (e) {
      debugPrint('🏢 ERROR: $e');
      throw Exception('Failed to update company: $e');
    }
  }

  /// Delete company (soft delete)
  /// Sets deleted_at timestamp instead of actually deleting the record
  Future<void> deleteCompany(String id) async {
    try {
      // Soft delete: Update deleted_at timestamp
      await _supabase.from('companies').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  /// Permanently delete company (hard delete)
  /// ⚠️ USE WITH CAUTION - This is irreversible!
  Future<void> permanentlyDeleteCompany(String id) async {
    try {
      await _supabase.from('companies').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to permanently delete company: $e');
    }
  }

  /// Restore a soft-deleted company
  Future<void> restoreCompany(String id) async {
    try {
      await _supabase.from('companies').update({
        'deleted_at': null,
      }).eq('id', id);
    } catch (e) {
      throw Exception('Failed to restore company: $e');
    }
  }

  /// Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      // Get employee count from both users and employees tables
      final usersResponse = await _supabase
          .from('users')
          .select('id')
          .eq('company_id', companyId);
      final employeesResponse = await _supabase
          .from('employees')
          .select('id')
          .eq('company_id', companyId);
      final totalEmployees = (usersResponse as List).length + (employeesResponse as List).length;

      // Get branch count for this company
      final branchesResponse = await _supabase
          .from('branches')
          .select('id')
          .eq('company_id', companyId);

      // Get table count across all branches of this company
      final tablesResponse = await _supabase
          .from('tables')
          .select('id')
          .eq('company_id', companyId);

      // Get monthly revenue from daily_revenue
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final revenueResponse = await _supabase
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
    } catch (e) {
      return {
        'employeeCount': 0,
        'branchCount': 0,
        'tableCount': 0,
        'monthlyRevenue': 0.0,
      };
    }
  }

  /// Subscribe to company changes
  Stream<List<Company>> subscribeToCompanies() {
    return _supabase
        .from('companies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Company.fromJson(json)).toList());
  }
}
