import '../core/services/supabase_service.dart';
import '../models/company.dart';

/// Company Service
/// Handles all company-related database operations
/// Note: Uses 'companies' table in database (renamed from 'stores')
class CompanyService {
  final _supabase = supabase.client;

  /// Get all companies
  Future<List<Company>> getAllCompanies() async {
    try {
      final response = await _supabase
          .from('companies')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Company.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch companies: $e');
    }
  }

  /// Get company by ID
  Future<Company?> getCompanyById(String id) async {
    try {
      final response =
          await _supabase.from('companies').select().eq('id', id).single();

      return Company.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create new company
  Future<Company> createCompany({
    required String name,
    String? address,
    String? phone,
    String? email,
    String? businessType,
  }) async {
    try {
      final response = await _supabase
          .from('companies')
          .insert({
            'name': name,
            'address': address,
            'phone': phone,
            'email': email,
            'business_type': businessType ?? 'billiards',
            'is_active': true,
          })
          .select()
          .single();

      return Company.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  /// Update company
  Future<Company> updateCompany(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('companies')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return Company.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  /// Delete company
  Future<void> deleteCompany(String id) async {
    try {
      await _supabase.from('companies').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  /// Get company statistics
  Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      // Get employee count for this company
      final employeesResponse = await _supabase
          .from('profiles')
          .select('id')
          .eq('company_id', companyId);

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
          .gte('date', firstDayOfMonth.toIso8601String());

      double monthlyRevenue = 0.0;
      for (var record in revenueResponse) {
        monthlyRevenue += (record['amount'] as num?)?.toDouble() ?? 0.0;
      }

      return {
        'employeeCount': (employeesResponse as List).length,
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
