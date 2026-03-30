import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/services/debt_calculation_service.dart';

void main() {
  // ─── Per-item balance helpers ──────────────────────────

  group('DebtCalculationService.orderBalance', () {
    test('calculates total - paid_amount', () {
      final order = {'total': 5000000, 'paid_amount': 2000000};
      expect(DebtCalculationService.orderBalance(order), 3000000);
    });

    test('returns 0 when fully paid', () {
      final order = {'total': 1000000, 'paid_amount': 1000000};
      expect(DebtCalculationService.orderBalance(order), 0);
    });

    test('returns 0 when overpaid (no negative)', () {
      final order = {'total': 1000000, 'paid_amount': 1500000};
      expect(DebtCalculationService.orderBalance(order), 0);
    });

    test('handles null total → 0', () {
      final order = {'paid_amount': 500000};
      expect(DebtCalculationService.orderBalance(order), 0);
    });

    test('handles null paid_amount → full total', () {
      final order = {'total': 3000000};
      expect(DebtCalculationService.orderBalance(order), 3000000);
    });
  });

  group('DebtCalculationService.receivableBalance', () {
    test('calculates original - paid - writeOff', () {
      final recv = {
        'original_amount': 5000000,
        'paid_amount': 1000000,
        'write_off_amount': 500000,
      };
      expect(DebtCalculationService.receivableBalance(recv), 3500000);
    });

    test('returns 0 when fully settled', () {
      final recv = {
        'original_amount': 1000000,
        'paid_amount': 800000,
        'write_off_amount': 200000,
      };
      expect(DebtCalculationService.receivableBalance(recv), 0);
    });

    test('handles null amounts → defaults to 0', () {
      final recv = {'original_amount': 2000000};
      expect(DebtCalculationService.receivableBalance(recv), 2000000);
    });
  });

  // ─── Aging helpers ─────────────────────────────────────

  group('DebtCalculationService.agingBucket', () {
    test('current for 0 days', () {
      expect(DebtCalculationService.agingBucket(0), 'current');
    });

    test('1-30 for 1-30 days', () {
      expect(DebtCalculationService.agingBucket(1), '1-30');
      expect(DebtCalculationService.agingBucket(15), '1-30');
      expect(DebtCalculationService.agingBucket(30), '1-30');
    });

    test('31-60 for 31-60 days', () {
      expect(DebtCalculationService.agingBucket(31), '31-60');
      expect(DebtCalculationService.agingBucket(60), '31-60');
    });

    test('61-90 for 61-90 days', () {
      expect(DebtCalculationService.agingBucket(61), '61-90');
      expect(DebtCalculationService.agingBucket(90), '61-90');
    });

    test('90+ for >90 days', () {
      expect(DebtCalculationService.agingBucket(91), '90+');
      expect(DebtCalculationService.agingBucket(365), '90+');
    });
  });

  group('DebtCalculationService.orderAgeDays', () {
    test('calculates days since order_date', () {
      final daysAgo = DateTime.now().subtract(const Duration(days: 15));
      final order = {'order_date': daysAgo.toIso8601String()};
      expect(DebtCalculationService.orderAgeDays(order), 15);
    });

    test('falls back to created_at when order_date is null', () {
      final daysAgo = DateTime.now().subtract(const Duration(days: 10));
      final order = {'created_at': daysAgo.toIso8601String()};
      expect(DebtCalculationService.orderAgeDays(order), 10);
    });

    test('returns 0 when both dates are null', () {
      expect(DebtCalculationService.orderAgeDays({}), 0);
    });

    test('returns 0 for unparseable date', () {
      final order = {'order_date': 'not-a-date'};
      expect(DebtCalculationService.orderAgeDays(order), 0);
    });
  });

  group('DebtCalculationService.isOrderOverdue', () {
    test('true when order > 30 days old', () {
      final daysAgo = DateTime.now().subtract(const Duration(days: 35));
      final order = {'order_date': daysAgo.toIso8601String()};
      expect(DebtCalculationService.isOrderOverdue(order), true);
    });

    test('false when order <= 30 days old', () {
      final daysAgo = DateTime.now().subtract(const Duration(days: 25));
      final order = {'order_date': daysAgo.toIso8601String()};
      expect(DebtCalculationService.isOrderOverdue(order), false);
    });
  });

  group('DebtCalculationService.isReceivableOverdue', () {
    test('true when past due date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final recv = {'due_date': yesterday.toIso8601String()};
      expect(DebtCalculationService.isReceivableOverdue(recv), true);
    });

    test('false when due date in the future', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final recv = {'due_date': tomorrow.toIso8601String()};
      expect(DebtCalculationService.isReceivableOverdue(recv), false);
    });

    test('false when no due date', () {
      expect(DebtCalculationService.isReceivableOverdue({}), false);
    });
  });

  // ─── Aggregate: computeDebtSummaryFromData ─────────────

  group('DebtCalculationService.computeDebtSummaryFromData', () {
    test('computes totalReceivable from orders + receivables', () {
      final orders = [
        {'customer_id': 'c1', 'total': 5000000, 'paid_amount': 2000000, 'order_date': DateTime.now().toIso8601String()},
        {'customer_id': 'c2', 'total': 3000000, 'paid_amount': 0, 'order_date': DateTime.now().toIso8601String()},
      ];
      final receivables = [
        {'customer_id': 'c1', 'original_amount': 1000000, 'paid_amount': 0, 'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String()},
      ];

      final summary = DebtCalculationService.computeDebtSummaryFromData(orders, receivables);

      // (5M-2M) + 3M + 1M = 7M
      expect(summary.totalReceivable, 7000000);
    });

    test('tracks debt by customer', () {
      final orders = [
        {'customer_id': 'c1', 'total': 5000000, 'paid_amount': 0, 'order_date': DateTime.now().toIso8601String()},
        {'customer_id': 'c1', 'total': 2000000, 'paid_amount': 0, 'order_date': DateTime.now().toIso8601String()},
        {'customer_id': 'c2', 'total': 1000000, 'paid_amount': 0, 'order_date': DateTime.now().toIso8601String()},
      ];

      final summary = DebtCalculationService.computeDebtSummaryFromData(orders, []);

      expect(summary.debtByCustomer['c1'], 7000000);
      expect(summary.debtByCustomer['c2'], 1000000);
      expect(summary.totalCustomerCount, 2);
    });

    test('identifies overdue customers (>30 days for orders)', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 60));
      final recentDate = DateTime.now().subtract(const Duration(days: 5));

      final orders = [
        {'customer_id': 'c1', 'total': 5000000, 'paid_amount': 0, 'order_date': oldDate.toIso8601String()},
        {'customer_id': 'c2', 'total': 3000000, 'paid_amount': 0, 'order_date': recentDate.toIso8601String()},
      ];

      final summary = DebtCalculationService.computeDebtSummaryFromData(orders, []);

      expect(summary.overdueCustomerCount, 1);
      expect(summary.overdueCustomerIds.contains('c1'), true);
      expect(summary.overdueCustomerIds.contains('c2'), false);
    });

    test('empty data produces zero summary', () {
      final summary = DebtCalculationService.computeDebtSummaryFromData([], []);

      expect(summary.totalReceivable, 0);
      expect(summary.overdueAmount, 0);
      expect(summary.overdueCustomerCount, 0);
      expect(summary.totalCustomerCount, 0);
    });

    test('skips fully paid orders (balance <= 0)', () {
      final orders = [
        {'customer_id': 'c1', 'total': 1000000, 'paid_amount': 1000000, 'order_date': DateTime.now().toIso8601String()},
      ];

      final summary = DebtCalculationService.computeDebtSummaryFromData(orders, []);
      expect(summary.totalReceivable, 0);
      expect(summary.totalCustomerCount, 0);
    });
  });
}
