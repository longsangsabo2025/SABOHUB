import '../core/services/supabase_service.dart';
import '../models/accounting.dart';
import '../utils/logger_service.dart';

/// Accounting Service
/// Handles all accounting-related database operations
class AccountingService {
  final _supabase = supabase.client;

  /// Get accounting summary for a period
  Future<AccountingSummary> getSummary({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      // Get daily revenue
      var revenueQuery = _supabase
          .from('daily_revenue')
          .select('amount')
          .eq('company_id', companyId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (branchId != null) {
        revenueQuery = revenueQuery.eq('branch_id', branchId);
      }

      final revenueData = await revenueQuery;
      double totalRevenue = 0.0;
      for (var record in revenueData) {
        totalRevenue += (record['amount'] as num?)?.toDouble() ?? 0.0;
      }

      // Get transactions for expenses
      var transactionQuery = _supabase
          .from('accounting_transactions')
          .select('type, amount')
          .eq('company_id', companyId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (branchId != null) {
        transactionQuery = transactionQuery.eq('branch_id', branchId);
      }

      final transactionData = await transactionQuery;
      double totalExpense = 0.0;
      int transactionCount = transactionData.length;

      for (var record in transactionData) {
        final type = record['type'] as String;
        final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;
        
        if (type != 'revenue') {
          totalExpense += amount;
        }
      }

      final netProfit = totalRevenue - totalExpense;
      final profitMargin = totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;

      return AccountingSummary(
        totalRevenue: totalRevenue,
        totalExpense: totalExpense,
        netProfit: netProfit,
        profitMargin: profitMargin,
        transactionCount: transactionCount,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e, stackTrace) {
      // ✅ Proper error logging instead of silent print
      logger.error('Failed to get accounting summary', e, stackTrace);
      logger.logUserAction('accounting_summary_error', {
        'company_id': companyId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'error': e.toString(),
      });
      
      // Return empty data with zeros
      return AccountingSummary(
        totalRevenue: 0,
        totalExpense: 0,
        netProfit: 0,
        profitMargin: 0,
        transactionCount: 0,
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  /// Get all transactions
  Future<List<AccountingTransaction>> getTransactions({
    required String companyId,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    try {
      var query = _supabase
          .from('accounting_transactions')
          .select()
          .eq('company_id', companyId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      if (type != null) {
        query = query.eq('type', type.value);
      }

      final response = await query.order('date', ascending: false);
      return (response as List)
          .map((json) => AccountingTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Get daily revenue records
  Future<List<DailyRevenue>> getDailyRevenue({
    required String companyId,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('daily_revenue')
          .select()
          .eq('company_id', companyId);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }

      final response = await query.order('date', ascending: false);
      return (response as List)
          .map((json) => DailyRevenue.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting daily revenue: $e');
      return [];
    }
  }

  /// Create transaction
  Future<AccountingTransaction> createTransaction({
    required String companyId,
    String? branchId,
    required TransactionType type,
    required double amount,
    required String description,
    required PaymentMethod paymentMethod,
    required DateTime date,
    String? category,
    String? referenceId,
    String? notes,
    required String createdBy,
  }) async {
    try {
      final response = await _supabase
          .from('accounting_transactions')
          .insert({
            'company_id': companyId,
            'branch_id': branchId,
            'type': type.value,
            'amount': amount,
            'description': description,
            'payment_method': paymentMethod.value,
            'date': date.toIso8601String(),
            'category': category,
            'reference_id': referenceId,
            'notes': notes,
            'created_by': createdBy,
          })
          .select()
          .single();

      return AccountingTransaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Update transaction
  Future<AccountingTransaction> updateTransaction(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('accounting_transactions')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      return AccountingTransaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _supabase.from('accounting_transactions').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  /// Create or update daily revenue
  Future<DailyRevenue> upsertDailyRevenue({
    required String companyId,
    required String branchId,
    required DateTime date,
    required double amount,
    int? tableCount,
    int? customerCount,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('daily_revenue')
          .upsert({
            'company_id': companyId,
            'branch_id': branchId,
            'date': date.toIso8601String().split('T')[0], // Date only
            'amount': amount,
            'table_count': tableCount ?? 0,
            'customer_count': customerCount ?? 0,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return DailyRevenue.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upsert daily revenue: $e');
    }
  }

  /// Get expense breakdown by category
  Future<Map<String, double>> getExpenseBreakdown({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      var query = _supabase
          .from('accounting_transactions')
          .select('type, amount')
          .eq('company_id', companyId)
          .neq('type', 'revenue')
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query;
      
      Map<String, double> breakdown = {};
      for (var record in response) {
        final type = record['type'] as String;
        final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;
        breakdown[type] = (breakdown[type] ?? 0.0) + amount;
      }

      return breakdown;
    } catch (e) {
      print('Error getting expense breakdown: $e');
      return {};
    }
  }

  /// Get revenue trend (daily revenue for chart)
  Future<List<Map<String, dynamic>>> getRevenueTrend({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      var query = _supabase
          .from('daily_revenue')
          .select('date, amount')
          .eq('company_id', companyId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('date', ascending: true);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting revenue trend: $e');
      return [];
    }
  }
}
