import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/customer_tier.dart';

void main() {
  // ─── CustomerTier enum ─────────────────────────────────

  group('CustomerTier', () {
    test('has 5 values', () {
      expect(CustomerTier.values.length, 5);
    });

    test('displayName returns Vietnamese labels', () {
      expect(CustomerTier.diamond.displayName, 'Kim Cương');
      expect(CustomerTier.gold.displayName, 'Vàng');
      expect(CustomerTier.silver.displayName, 'Bạc');
      expect(CustomerTier.bronze.displayName, 'Đồng');
      expect(CustomerTier.none.displayName, 'Mới');
    });

    test('minRevenue matches documented thresholds', () {
      expect(CustomerTier.diamond.minRevenue, 100000000); // 100M
      expect(CustomerTier.gold.minRevenue, 20000000); // 20M
      expect(CustomerTier.silver.minRevenue, 5000000); // 5M
      expect(CustomerTier.bronze.minRevenue, 1);
      expect(CustomerTier.none.minRevenue, 0);
    });
  });

  // ─── fromRevenue ───────────────────────────────────────

  group('CustomerTierExtension.fromRevenue', () {
    test('null → none', () {
      expect(CustomerTierExtension.fromRevenue(null), CustomerTier.none);
    });

    test('0 → none', () {
      expect(CustomerTierExtension.fromRevenue(0), CustomerTier.none);
    });

    test('negative → none', () {
      expect(CustomerTierExtension.fromRevenue(-100), CustomerTier.none);
    });

    test('1 → bronze', () {
      expect(CustomerTierExtension.fromRevenue(1), CustomerTier.bronze);
    });

    test('4999999 → bronze', () {
      expect(CustomerTierExtension.fromRevenue(4999999), CustomerTier.bronze);
    });

    test('5000000 → silver', () {
      expect(CustomerTierExtension.fromRevenue(5000000), CustomerTier.silver);
    });

    test('19999999 → silver', () {
      expect(CustomerTierExtension.fromRevenue(19999999), CustomerTier.silver);
    });

    test('20000000 → gold', () {
      expect(CustomerTierExtension.fromRevenue(20000000), CustomerTier.gold);
    });

    test('99999999 → gold', () {
      expect(CustomerTierExtension.fromRevenue(99999999), CustomerTier.gold);
    });

    test('100000000 → diamond', () {
      expect(CustomerTierExtension.fromRevenue(100000000), CustomerTier.diamond);
    });

    test('500000000 → diamond', () {
      expect(CustomerTierExtension.fromRevenue(500000000), CustomerTier.diamond);
    });
  });

  // ─── fromString ────────────────────────────────────────

  group('CustomerTierExtension.fromString', () {
    test('parses known tier strings', () {
      expect(CustomerTierExtension.fromString('diamond'), CustomerTier.diamond);
      expect(CustomerTierExtension.fromString('gold'), CustomerTier.gold);
      expect(CustomerTierExtension.fromString('silver'), CustomerTier.silver);
      expect(CustomerTierExtension.fromString('bronze'), CustomerTier.bronze);
      expect(CustomerTierExtension.fromString('none'), CustomerTier.none);
    });

    test('case insensitive', () {
      expect(CustomerTierExtension.fromString('DIAMOND'), CustomerTier.diamond);
      expect(CustomerTierExtension.fromString('Gold'), CustomerTier.gold);
    });

    test('null → bronze (default)', () {
      expect(CustomerTierExtension.fromString(null), CustomerTier.bronze);
    });

    test('unknown string → bronze (default)', () {
      expect(CustomerTierExtension.fromString('platinum'), CustomerTier.bronze);
    });
  });

  // ─── CustomerRevenue ───────────────────────────────────

  group('CustomerRevenue', () {
    test('tier based on totalRevenue', () {
      const revenue = CustomerRevenue(
        customerId: 'c1',
        totalRevenue: 25000000, // 25M → gold
      );
      expect(revenue.tier, CustomerTier.gold);
    });

    test('completionRate = completedOrders / totalOrders * 100', () {
      const revenue = CustomerRevenue(
        customerId: 'c1',
        totalOrders: 10,
        completedOrders: 8,
      );
      expect(revenue.completionRate, 80.0);
    });

    test('completionRate is 0 when no orders', () {
      const revenue = CustomerRevenue(
        customerId: 'c1',
        totalOrders: 0,
      );
      expect(revenue.completionRate, 0);
    });

    test('paymentRate = paidAmount / totalRevenue * 100', () {
      const revenue = CustomerRevenue(
        customerId: 'c1',
        totalRevenue: 10000000,
        paidAmount: 7000000,
      );
      expect(revenue.paymentRate, 70.0);
    });

    test('paymentRate is 0 when no revenue', () {
      const revenue = CustomerRevenue(
        customerId: 'c1',
        totalRevenue: 0,
      );
      expect(revenue.paymentRate, 0);
    });

    group('fromJson', () {
      test('parses full JSON', () {
        final json = {
          'customer_id': 'c1',
          'company_id': 'comp-1',
          'customer_name': 'Shop ABC',
          'customer_type': 'retail',
          'total_orders': 20,
          'completed_orders': 18,
          'total_revenue': 50000000.0,
          'paid_amount': 45000000.0,
          'outstanding_amount': 5000000.0,
          'last_order_date': '2026-03-29',
        };

        final revenue = CustomerRevenue.fromJson(json);
        expect(revenue.customerId, 'c1');
        expect(revenue.customerName, 'Shop ABC');
        expect(revenue.totalOrders, 20);
        expect(revenue.totalRevenue, 50000000);
        expect(revenue.tier, CustomerTier.gold);
      });

      test('handles null/missing fields with defaults', () {
        final json = {'customer_id': 'c2'};
        final revenue = CustomerRevenue.fromJson(json);

        expect(revenue.totalOrders, 0);
        expect(revenue.completedOrders, 0);
        expect(revenue.totalRevenue, 0);
        expect(revenue.paidAmount, 0);
        expect(revenue.tier, CustomerTier.none);
      });
    });
  });
}
