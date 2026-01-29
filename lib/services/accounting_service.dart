import '../core/services/supabase_service.dart';
import '../models/accounting.dart';
import '../utils/logger_service.dart';

/// Accounting Service
/// Handles all accounting-related database operations
/// Updated to use real data from sales_orders, sell_in_transactions, sell_out_transactions
class AccountingService {
  final _supabase = supabase.client;

  /// Get accounting summary for a period
  /// Now aggregates from sales_orders (revenue), sell_in_transactions (cost/expense)
  Future<AccountingSummary> getSummary({
    required String companyId,
    required DateTime startDate,
    required DateTime endDate,
    String? branchId,
  }) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Get revenue from completed sales_orders (payment_status = 'paid')
      var salesQuery = _supabase
          .from('sales_orders')
          .select('total, payment_status, status')
          .eq('company_id', companyId)
          .gte('order_date', startDateStr)
          .lte('order_date', endDateStr)
          .inFilter('status', ['completed', 'approved']);

      if (branchId != null) {
        salesQuery = salesQuery.eq('branch_id', branchId);
      }

      final salesData = await salesQuery;
      double totalRevenue = 0.0;
      double totalReceivable = 0.0; // Unpaid orders (debt)
      int paidOrderCount = 0;
      int unpaidOrderCount = 0;

      for (var record in salesData) {
        final total = (record['total'] as num?)?.toDouble() ?? 0.0;
        final paymentStatus = record['payment_status'] as String?;
        
        if (paymentStatus == 'paid') {
          totalRevenue += total;
          paidOrderCount++;
        } else {
          totalReceivable += total;
          unpaidOrderCount++;
        }
      }

      // Get expenses from sell_in_transactions (cost of goods purchased)
      var sellInQuery = _supabase
          .from('sell_in_transactions')
          .select('total_amount, status')
          .eq('company_id', companyId)
          .gte('transaction_date', startDateStr)
          .lte('transaction_date', endDateStr);

      final sellInData = await sellInQuery;
      double totalExpense = 0.0;
      int transactionCount = salesData.length + sellInData.length;

      for (var record in sellInData) {
        final amount = (record['total_amount'] as num?)?.toDouble() ?? 0.0;
        totalExpense += amount;
      }

      final netProfit = totalRevenue - totalExpense;
      final profitMargin =
          totalRevenue > 0 ? (netProfit / totalRevenue * 100) : 0.0;

      return AccountingSummary(
        totalRevenue: totalRevenue,
        totalExpense: totalExpense,
        netProfit: netProfit,
        profitMargin: profitMargin,
        transactionCount: transactionCount,
        startDate: startDate,
        endDate: endDate,
        // Extended data
        totalReceivable: totalReceivable,
        paidOrderCount: paidOrderCount,
        unpaidOrderCount: unpaidOrderCount,
      );
    } catch (e, stackTrace) {
      logger.error('Failed to get accounting summary', e, stackTrace);
      logger.logUserAction('accounting_summary_error', {
        'company_id': companyId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'error': e.toString(),
      });

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

  /// Get all transactions - combines sales_orders and sell_in as transactions
  Future<List<AccountingTransaction>> getTransactions({
    required String companyId,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
  }) async {
    try {
      List<AccountingTransaction> transactions = [];
      final startDateStr = startDate?.toIso8601String().split('T')[0];
      final endDateStr = endDate?.toIso8601String().split('T')[0];

      // Get sales orders as revenue transactions
      if (type == null || type == TransactionType.revenue) {
        var salesQuery = _supabase
            .from('sales_orders')
            .select('id, order_number, order_date, total, payment_method, payment_status, status, notes, created_at')
            .eq('company_id', companyId)
            .inFilter('status', ['completed', 'approved']);

        if (branchId != null) {
          salesQuery = salesQuery.eq('branch_id', branchId);
        }
        if (startDateStr != null) {
          salesQuery = salesQuery.gte('order_date', startDateStr);
        }
        if (endDateStr != null) {
          salesQuery = salesQuery.lte('order_date', endDateStr);
        }

        final salesData = await salesQuery.order('order_date', ascending: false);
        
        for (var record in salesData) {
          transactions.add(AccountingTransaction(
            id: record['id'] as String,
            companyId: companyId,
            branchId: branchId,
            type: TransactionType.revenue,
            amount: (record['total'] as num?)?.toDouble() ?? 0.0,
            description: 'Đơn hàng ${record['order_number']}',
            paymentMethod: _parsePaymentMethod(record['payment_method'] as String?),
            date: DateTime.parse(record['order_date'].toString()),
            category: 'sales',
            referenceId: record['order_number'] as String?,
            notes: record['notes'] as String?,
            createdAt: DateTime.parse(record['created_at'].toString()),
          ));
        }
      }

      // Get sell_in as expense transactions
      if (type == null || type == TransactionType.expense) {
        var sellInQuery = _supabase
            .from('sell_in_transactions')
            .select('id, transaction_code, transaction_date, total_amount, status, notes, created_at')
            .eq('company_id', companyId);

        if (startDateStr != null) {
          sellInQuery = sellInQuery.gte('transaction_date', startDateStr);
        }
        if (endDateStr != null) {
          sellInQuery = sellInQuery.lte('transaction_date', endDateStr);
        }

        final sellInData = await sellInQuery.order('transaction_date', ascending: false);
        
        for (var record in sellInData) {
          transactions.add(AccountingTransaction(
            id: record['id'] as String,
            companyId: companyId,
            branchId: branchId,
            type: TransactionType.expense,
            amount: (record['total_amount'] as num?)?.toDouble() ?? 0.0,
            description: 'Nhập hàng ${record['transaction_code']}',
            paymentMethod: PaymentMethod.transfer,
            date: DateTime.parse(record['transaction_date'].toString()),
            category: 'purchase',
            referenceId: record['transaction_code'] as String?,
            notes: record['notes'] as String?,
            createdAt: DateTime.parse(record['created_at'].toString()),
          ));
        }
      }

      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } catch (e) {
      logger.error('Failed to get transactions', e, null);
      return [];
    }
  }

  PaymentMethod _parsePaymentMethod(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'debt':
        return PaymentMethod.debt;
      default:
        return PaymentMethod.cash;
    }
  }

  /// Get daily revenue records - aggregated from sales_orders by date
  Future<List<DailyRevenue>> getDailyRevenue({
    required String companyId,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final startDateStr = startDate?.toIso8601String().split('T')[0];
      final endDateStr = endDate?.toIso8601String().split('T')[0];

      var query = _supabase
          .from('sales_orders')
          .select('order_date, total, payment_status')
          .eq('company_id', companyId)
          .inFilter('status', ['completed', 'approved']);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      if (startDateStr != null) {
        query = query.gte('order_date', startDateStr);
      }
      if (endDateStr != null) {
        query = query.lte('order_date', endDateStr);
      }

      final response = await query.order('order_date', ascending: false);
      
      // Group by date
      Map<String, DailyRevenue> dailyMap = {};
      for (var record in response) {
        final dateStr = record['order_date'].toString();
        final total = (record['total'] as num?)?.toDouble() ?? 0.0;
        
        if (dailyMap.containsKey(dateStr)) {
          final existing = dailyMap[dateStr]!;
          dailyMap[dateStr] = DailyRevenue(
            id: existing.id,
            companyId: companyId,
            branchId: branchId,
            date: existing.date,
            amount: existing.amount + total,
            orderCount: existing.orderCount + 1,
          );
        } else {
          dailyMap[dateStr] = DailyRevenue(
            id: dateStr,
            companyId: companyId,
            branchId: branchId,
            date: DateTime.parse(dateStr),
            amount: total,
            orderCount: 1,
          );
        }
      }
      
      return dailyMap.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      logger.error('Failed to get daily revenue', e, null);
      return [];
    }
  }

  /// Get receivables (công nợ) - unpaid sales orders
  Future<List<Map<String, dynamic>>> getReceivables({
    required String companyId,
    String? branchId,
  }) async {
    try {
      var query = _supabase
          .from('sales_orders')
          .select('id, order_number, order_date, customer_id, total, paid_amount, payment_status, status, created_at')
          .eq('company_id', companyId)
          .eq('payment_status', 'unpaid')
          .inFilter('status', ['completed', 'approved', 'pending']);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('order_date', ascending: false);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      logger.error('Failed to get receivables', e, null);
      return [];
    }
  }

  /// Get collections (thu tiền) - paid sales orders
  Future<List<Map<String, dynamic>>> getCollections({
    required String companyId,
    String? branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final startDateStr = startDate?.toIso8601String().split('T')[0];
      final endDateStr = endDate?.toIso8601String().split('T')[0];

      var query = _supabase
          .from('sales_orders')
          .select('id, order_number, order_date, customer_id, total, payment_method, payment_status, payment_collected_at, status')
          .eq('company_id', companyId)
          .eq('payment_status', 'paid');

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }
      if (startDateStr != null) {
        query = query.gte('order_date', startDateStr);
      }
      if (endDateStr != null) {
        query = query.lte('order_date', endDateStr);
      }

      final response = await query.order('payment_collected_at', ascending: false);
      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      logger.error('Failed to get collections', e, null);
      return [];
    }
  }

  /// Create transaction (legacy - keep for compatibility)
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

  /// Create or update daily revenue (legacy)
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
            'date': date.toIso8601String().split('T')[0],
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
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      // Get from sell_in_transactions
      var query = _supabase
          .from('sell_in_transactions')
          .select('total_amount, status')
          .eq('company_id', companyId)
          .gte('transaction_date', startDateStr)
          .lte('transaction_date', endDateStr);

      final response = await query;

      Map<String, double> breakdown = {
        'purchase': 0.0, // Nhập hàng
      };
      
      for (var record in response) {
        final amount = (record['total_amount'] as num?)?.toDouble() ?? 0.0;
        breakdown['purchase'] = (breakdown['purchase'] ?? 0.0) + amount;
      }

      return breakdown;
    } catch (e) {
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
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      var query = _supabase
          .from('sales_orders')
          .select('order_date, total')
          .eq('company_id', companyId)
          .eq('payment_status', 'paid')
          .inFilter('status', ['completed', 'approved'])
          .gte('order_date', startDateStr)
          .lte('order_date', endDateStr);

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      }

      final response = await query.order('order_date', ascending: true);
      
      // Group by date
      Map<String, double> dailyTotals = {};
      for (var record in response) {
        final dateStr = record['order_date'].toString();
        final total = (record['total'] as num?)?.toDouble() ?? 0.0;
        dailyTotals[dateStr] = (dailyTotals[dateStr] ?? 0.0) + total;
      }
      
      return dailyTotals.entries
          .map((e) => {'date': e.key, 'amount': e.value})
          .toList();
    } catch (e) {
      return [];
    }
  }
}
