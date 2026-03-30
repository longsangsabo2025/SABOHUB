import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for all debt/receivable calculations.
///
/// ALL pages that need debt data MUST use this service instead of
/// writing their own queries. This prevents divergence between
/// dashboard, accounts receivable, and reports pages.
class DebtCalculationService {
  DebtCalculationService._();

  // ---------------------------------------------------------------------------
  // Core query: fetch raw unpaid data from DB
  // ---------------------------------------------------------------------------

  /// Fetches all unpaid sales orders for a company.
  /// Unified filter: `payment_status != 'paid'` AND `status != 'cancelled'`.
  static Future<List<Map<String, dynamic>>> fetchUnpaidOrders(
    String companyId, {
    String select = 'customer_id, total, paid_amount, created_at, order_date',
  }) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('sales_orders')
        .select(select)
        .eq('company_id', companyId)
        .neq('payment_status', 'paid')
        .neq('status', 'cancelled');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetches all unpaid manual receivables for a company.
  static Future<List<Map<String, dynamic>>> fetchManualReceivables(
    String companyId, {
    String select =
        'customer_id, original_amount, paid_amount, write_off_amount, due_date',
  }) async {
    final supabase = Supabase.instance.client;
    final data = await supabase
        .from('receivables')
        .select(select)
        .eq('company_id', companyId)
        .eq('reference_type', 'manual')
        .neq('status', 'paid');
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // Per-item balance helpers
  // ---------------------------------------------------------------------------

  /// Remaining balance for one sales order.
  static double orderBalance(Map<String, dynamic> order) {
    final total = (order['total'] ?? 0 as num).toDouble();
    final paid = (order['paid_amount'] ?? 0 as num).toDouble();
    final balance = total - paid;
    return balance > 0 ? balance : 0;
  }

  /// Remaining balance for one manual receivable.
  static double receivableBalance(Map<String, dynamic> recv) {
    final original = (recv['original_amount'] ?? 0 as num).toDouble();
    final paid = (recv['paid_amount'] ?? 0 as num).toDouble();
    final writeOff = (recv['write_off_amount'] ?? 0 as num).toDouble();
    final balance = original - paid - writeOff;
    return balance > 0 ? balance : 0;
  }

  // ---------------------------------------------------------------------------
  // Aging helpers
  // ---------------------------------------------------------------------------

  /// Days since order creation (used for aging).
  static int orderAgeDays(Map<String, dynamic> order) {
    final dateStr =
        (order['order_date'] ?? order['created_at'])?.toString();
    if (dateStr == null) return 0;
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 0;
    return DateTime.now().difference(date).inDays;
  }

  /// Aging bucket label for a given number of days.
  static String agingBucket(int days) {
    if (days > 90) return '90+';
    if (days > 60) return '61-90';
    if (days > 30) return '31-60';
    if (days > 0) return '1-30';
    return 'current';
  }

  /// Whether a sales order is overdue (> 30 days old).
  static bool isOrderOverdue(Map<String, dynamic> order) {
    return orderAgeDays(order) > 30;
  }

  /// Whether a manual receivable is overdue (past due_date).
  static bool isReceivableOverdue(Map<String, dynamic> recv) {
    final dueDateStr = recv['due_date']?.toString();
    if (dueDateStr == null) return false;
    final dueDate = DateTime.tryParse(dueDateStr);
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }

  // ---------------------------------------------------------------------------
  // High-level aggregation: compute full debt summary for a company
  // ---------------------------------------------------------------------------

  /// Returns a complete debt summary for a company.
  ///
  /// All pages (dashboard, reports, accounts receivable) should use this
  /// to get consistent numbers.
  static Future<DebtSummary> computeDebtSummary(String companyId) async {
    final results = await Future.wait([
      fetchUnpaidOrders(companyId),
      fetchManualReceivables(companyId),
    ]);

    final unpaidOrders = results[0];
    final manualReceivables = results[1];

    return computeDebtSummaryFromData(unpaidOrders, manualReceivables);
  }

  /// Pure computation from pre-fetched data (useful when caller already has
  /// the data or needs extra select columns).
  static DebtSummary computeDebtSummaryFromData(
    List<Map<String, dynamic>> unpaidOrders,
    List<Map<String, dynamic>> manualReceivables,
  ) {
    double totalReceivable = 0;
    final Map<String, double> debtByCustomer = {};
    final Set<String> overdueCustomerIds = {};
    final Set<String> allCustomerIds = {};
    final List<Map<String, dynamic>> agingItems = [];

    // --- Sales orders ---
    for (final order in unpaidOrders) {
      final balance = orderBalance(order);
      if (balance <= 0) continue;
      totalReceivable += balance;

      final custId = order['customer_id']?.toString() ?? '';
      if (custId.isNotEmpty) {
        allCustomerIds.add(custId);
        debtByCustomer[custId] = (debtByCustomer[custId] ?? 0) + balance;
      }

      final days = orderAgeDays(order);
      agingItems.add({
        'customer_id': custId,
        'balance': balance,
        'aging_bucket': agingBucket(days),
        'days_overdue': days,
        'source': 'sales_order',
      });

      if (days > 30 && custId.isNotEmpty) {
        overdueCustomerIds.add(custId);
      }
    }

    // --- Manual receivables ---
    for (final recv in manualReceivables) {
      final balance = receivableBalance(recv);
      if (balance <= 0) continue;
      totalReceivable += balance;

      final custId = recv['customer_id']?.toString() ?? '';
      if (custId.isNotEmpty) {
        allCustomerIds.add(custId);
        debtByCustomer[custId] = (debtByCustomer[custId] ?? 0) + balance;
      }

      if (isReceivableOverdue(recv) && custId.isNotEmpty) {
        overdueCustomerIds.add(custId);
      }
    }

    // Overdue amount = total debt of customers who have ANY overdue item
    final double overdueAmount = overdueCustomerIds.fold(
        0.0, (sum, id) => sum + (debtByCustomer[id] ?? 0));

    return DebtSummary(
      totalReceivable: totalReceivable,
      overdueAmount: overdueAmount,
      overdueCustomerCount: overdueCustomerIds.length,
      totalCustomerCount: allCustomerIds.length,
      debtByCustomer: debtByCustomer,
      overdueCustomerIds: overdueCustomerIds,
      agingItems: agingItems,
    );
  }
}

/// Immutable result of debt calculation — used by all consumer pages.
class DebtSummary {
  final double totalReceivable;
  final double overdueAmount;
  final int overdueCustomerCount;
  final int totalCustomerCount;
  final Map<String, double> debtByCustomer;
  final Set<String> overdueCustomerIds;
  final List<Map<String, dynamic>> agingItems;

  const DebtSummary({
    required this.totalReceivable,
    required this.overdueAmount,
    required this.overdueCustomerCount,
    required this.totalCustomerCount,
    required this.debtByCustomer,
    required this.overdueCustomerIds,
    required this.agingItems,
  });

  /// Aging summary grouped by bucket.
  Map<String, double> get agingSummary {
    final summary = <String, double>{
      'current': 0, '1-30': 0, '31-60': 0, '61-90': 0, '90+': 0,
    };
    for (final item in agingItems) {
      final bucket = item['aging_bucket']?.toString() ?? 'current';
      final balance = (item['balance'] as num?)?.toDouble() ?? 0;
      summary[bucket] = (summary[bucket] ?? 0) + balance;
    }
    return summary;
  }
}
