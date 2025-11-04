import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/commission_rule.dart';

/// Commission Rule Service - CEO quản lý quy tắc hoa hồng
class CommissionRuleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tạo quy tắc hoa hồng mới (CEO)
  Future<CommissionRule> createRule({
    required String companyId,
    required String ruleName,
    String? description,
    required String appliesTo, // all, role, individual
    String? role,
    String? userId,
    required double commissionPercentage,
    double minBillAmount = 0,
    double? maxBillAmount,
    int priority = 0,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final data = {
      'company_id': companyId,
      'rule_name': ruleName,
      'description': description,
      'applies_to': appliesTo,
      'role': role,
      'user_id': userId,
      'commission_percentage': commissionPercentage,
      'min_bill_amount': minBillAmount,
      'max_bill_amount': maxBillAmount,
      'priority': priority,
      'is_active': true,
      'effective_from':
          (effectiveFrom ?? DateTime.now()).toIso8601String().split('T')[0],
      'effective_to': effectiveTo?.toIso8601String().split('T')[0],
      'created_by': currentUserId,
    };

    final response =
        await _supabase.from('commission_rules').insert(data).select().single();

    return CommissionRule.fromJson(response);
  }

  /// Lấy tất cả quy tắc của company
  Future<List<CommissionRule>> getRulesByCompany(String companyId,
      {bool? isActive}) async {
    var query = _supabase
        .from('commission_rules')
        .select()
        .eq('company_id', companyId)
        .order('priority', ascending: false)
        .order('created_at', ascending: false);

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query;
    return (response as List)
        .map((json) => CommissionRule.fromJson(json))
        .toList();
  }

  /// Lấy quy tắc theo ID
  Future<CommissionRule?> getRuleById(String ruleId) async {
    final response = await _supabase
        .from('commission_rules')
        .select()
        .eq('id', ruleId)
        .maybeSingle();

    return response != null ? CommissionRule.fromJson(response) : null;
  }

  /// Update quy tắc
  Future<CommissionRule> updateRule(
    String ruleId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _supabase
        .from('commission_rules')
        .update(updates)
        .eq('id', ruleId)
        .select()
        .single();

    return CommissionRule.fromJson(response);
  }

  /// Deactivate rule (soft delete)
  Future<CommissionRule> deactivateRule(String ruleId) async {
    final response = await _supabase
        .from('commission_rules')
        .update({'is_active': false})
        .eq('id', ruleId)
        .select()
        .single();

    return CommissionRule.fromJson(response);
  }

  /// Reactivate rule
  Future<CommissionRule> reactivateRule(String ruleId) async {
    final response = await _supabase
        .from('commission_rules')
        .update({'is_active': true})
        .eq('id', ruleId)
        .select()
        .single();

    return CommissionRule.fromJson(response);
  }

  /// Delete rule (hard delete)
  Future<void> deleteRule(String ruleId) async {
    await _supabase.from('commission_rules').delete().eq('id', ruleId);
  }

  /// Lấy quy tắc áp dụng cho nhân viên cụ thể
  Future<CommissionRule?> getApplicableRule({
    required String companyId,
    required String employeeId,
    required double billAmount,
    DateTime? billDate,
  }) async {
    final date = billDate ?? DateTime.now();
    final dateStr = date.toIso8601String().split('T')[0];

    // Get employee info
    final employeeData = await _supabase
        .from('users')
        .select('role')
        .eq('id', employeeId)
        .single();

    final employeeRole = employeeData['role'] as String;

    // Query rules with priority ordering
    final response = await _supabase
        .from('commission_rules')
        .select()
        .eq('company_id', companyId)
        .eq('is_active', true)
        .lte('effective_from', dateStr)
        .or('effective_to.is.null,effective_to.gte.$dateStr')
        .lte('min_bill_amount', billAmount)
        .or('max_bill_amount.is.null,max_bill_amount.gte.$billAmount')
        .or(
            'applies_to.eq.all,and(applies_to.eq.role,role.eq.$employeeRole),and(applies_to.eq.individual,user_id.eq.$employeeId)')
        .order('priority', ascending: false)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response != null ? CommissionRule.fromJson(response) : null;
  }

  /// Stream rules real-time
  Stream<List<CommissionRule>> streamRulesByCompany(String companyId) {
    return _supabase
        .from('commission_rules')
        .stream(primaryKey: ['id'])
        .eq('company_id', companyId)
        .order('priority', ascending: false)
        .map((data) =>
            (data as List).map((json) => CommissionRule.fromJson(json)).toList());
  }
}
