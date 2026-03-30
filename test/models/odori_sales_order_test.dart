import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/models/odori_sales_order.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullOrderJson() => {
        'id': 'ord-1',
        'company_id': 'comp-1',
        'branch_id': 'br-1',
        'order_number': 'SO-2026-001',
        'order_date': '2026-03-29',
        'customer_id': 'cust-1',
        'customer_name': 'ABC Corp',
        'sale_id': 'emp-1',
        'subtotal': 1000000,
        'discount_percent': 10.0,
        'discount_amount': 100000,
        'tax_percent': 10.0,
        'tax_amount': 90000,
        'shipping_fee': 50000,
        'total': 1040000,
        'payment_method': 'bank_transfer',
        'payment_status': 'partial',
        'paid_amount': 500000,
        'due_date': '2026-04-28',
        'delivery_status': 'pending',
        'status': 'approved',
        'priority': 'high',
        'source': 'field_sales',
        'requires_approval': true,
        'approved_by': 'mgr-1',
        'approved_at': '2026-03-29T10:00:00Z',
        'created_by': 'emp-1',
        'created_at': '2026-03-29T08:00:00Z',
        'updated_at': '2026-03-29T10:00:00Z',
        'sales_order_items': [
          {
            'id': 'item-1',
            'order_id': 'ord-1',
            'product_id': 'prod-1',
            'product_name': 'Nước giặt Odori',
            'quantity': 10,
            'unit': 'thùng',
            'unit_price': 100000,
            'discount_amount': 10000,
            'line_total': 990000,
          }
        ],
      };

  Map<String, dynamic> minimalOrderJson() => {
        'id': 'ord-2',
        'company_id': 'comp-1',
        'order_date': '2026-03-29',
        'customer_id': 'cust-2',
        'created_at': '2026-03-29T08:00:00Z',
      };

  // ─── OdoriSalesOrder Tests ─────────────────────────────

  group('OdoriSalesOrder', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final order = OdoriSalesOrder.fromJson(fullOrderJson());

        expect(order.id, 'ord-1');
        expect(order.companyId, 'comp-1');
        expect(order.branchId, 'br-1');
        expect(order.orderNumber, 'SO-2026-001');
        expect(order.customerId, 'cust-1');
        expect(order.customerName, 'ABC Corp');
        expect(order.saleId, 'emp-1');
        expect(order.subtotal, 1000000);
        expect(order.discountPercent, 10.0);
        expect(order.discountAmount, 100000);
        expect(order.total, 1040000);
        expect(order.paymentStatus, 'partial');
        expect(order.paidAmount, 500000);
        expect(order.status, 'approved');
        expect(order.requiresApproval, true);
        expect(order.items, isNotNull);
        expect(order.items!.length, 1);
      });

      test('parses minimal JSON with defaults', () {
        final order = OdoriSalesOrder.fromJson(minimalOrderJson());

        expect(order.id, 'ord-2');
        expect(order.orderNumber, '');
        expect(order.subtotal, 0);
        expect(order.discountAmount, 0);
        expect(order.total, 0);
        expect(order.paymentStatus, 'unpaid');
        expect(order.paidAmount, 0);
        expect(order.status, 'draft');
        expect(order.requiresApproval, false);
        expect(order.items, isNull);
        expect(order.branchId, isNull);
        expect(order.saleId, isNull);
      });

      test('parses customer name from nested join', () {
        final json = minimalOrderJson()
          ..['customers'] = {'name': 'Nested Customer'};
        final order = OdoriSalesOrder.fromJson(json);
        expect(order.customerName, 'Nested Customer');
      });

      test('prefers top-level customer_name over nested join', () {
        final json = minimalOrderJson()
          ..['customer_name'] = 'Direct Name'
          ..['customers'] = {'name': 'Nested Name'};
        final order = OdoriSalesOrder.fromJson(json);
        expect(order.customerName, 'Direct Name');
      });
    });

    group('computed getters', () {
      test('remainingAmount calculates correctly', () {
        final order = OdoriSalesOrder.fromJson(fullOrderJson());
        expect(order.remainingAmount, 540000); // 1040000 - 500000
      });

      test('remainingAmount is full total when unpaid', () {
        final order = OdoriSalesOrder.fromJson(minimalOrderJson());
        expect(order.remainingAmount, 0); // total=0, paid=0
      });

      test('isPendingApproval returns true for pending_approval status', () {
        final json = minimalOrderJson()..['status'] = 'pending_approval';
        expect(OdoriSalesOrder.fromJson(json).isPendingApproval, true);
      });

      test('isPendingApproval returns false for other statuses', () {
        final json = minimalOrderJson()..['status'] = 'approved';
        expect(OdoriSalesOrder.fromJson(json).isPendingApproval, false);
      });

      test('isCompleted returns true for delivered and cancelled', () {
        final delivered = minimalOrderJson()..['status'] = 'delivered';
        final cancelled = minimalOrderJson()..['status'] = 'cancelled';
        expect(OdoriSalesOrder.fromJson(delivered).isCompleted, true);
        expect(OdoriSalesOrder.fromJson(cancelled).isCompleted, true);
      });

      test('isCompleted returns false for in-progress statuses', () {
        for (final s in ['draft', 'approved', 'processing', 'ready']) {
          final json = minimalOrderJson()..['status'] = s;
          expect(OdoriSalesOrder.fromJson(json).isCompleted, false,
              reason: 'status=$s should not be completed');
        }
      });

      test('isRejected checks rejectedAt presence', () {
        final rejected = minimalOrderJson()
          ..['rejected_at'] = '2026-03-29T12:00:00Z';
        final notRejected = minimalOrderJson();
        expect(OdoriSalesOrder.fromJson(rejected).isRejected, true);
        expect(OdoriSalesOrder.fromJson(notRejected).isRejected, false);
      });
    });

    group('toJson', () {
      test('roundtrips key fields correctly', () {
        final original = OdoriSalesOrder.fromJson(fullOrderJson());
        final json = original.toJson();

        expect(json['id'], 'ord-1');
        expect(json['company_id'], 'comp-1');
        expect(json['order_number'], 'SO-2026-001');
        expect(json['customer_id'], 'cust-1');
        expect(json['total'], 1040000);
        expect(json['payment_status'], 'partial');
        expect(json['paid_amount'], 500000);
        expect(json['status'], 'approved');
        expect(json['requires_approval'], true);
      });

      test('uses correct DB column names', () {
        final json = OdoriSalesOrder.fromJson(fullOrderJson()).toJson();

        // Verify snake_case DB column names
        expect(json.containsKey('company_id'), true);
        expect(json.containsKey('order_number'), true);
        expect(json.containsKey('customer_id'), true);
        expect(json.containsKey('sale_id'), true);
        expect(json.containsKey('discount_percent'), true);
        expect(json.containsKey('discount_amount'), true);
        expect(json.containsKey('shipping_fee'), true);
        expect(json.containsKey('payment_method'), true);
        expect(json.containsKey('payment_status'), true);
        expect(json.containsKey('paid_amount'), true);
        expect(json.containsKey('delivery_status'), true);
        expect(json.containsKey('requires_approval'), true);

        // Verify DB uses 'total' not 'total_amount'
        expect(json.containsKey('total'), true);
        expect(json.containsKey('total_amount'), false);
      });
    });
  });

  // ─── OdoriSalesOrderItem Tests ─────────────────────────

  group('OdoriSalesOrderItem', () {
    test('parses from JSON with product join', () {
      final json = {
        'id': 'item-1',
        'order_id': 'ord-1',
        'product_id': 'prod-1',
        'products': {'name': 'Nước giặt', 'sku': 'NG-001'},
        'quantity': 10,
        'unit': 'thùng',
        'unit_price': 100000,
        'discount_amount': 5000,
        'line_total': 995000,
      };
      final item = OdoriSalesOrderItem.fromJson(json);

      expect(item.productName, 'Nước giặt');
      expect(item.productSku, 'NG-001');
      expect(item.quantity, 10);
      expect(item.unitPrice, 100000);
      expect(item.lineTotal, 995000);
    });

    test('calculates line_total when missing from JSON', () {
      final json = {
        'id': 'item-2',
        'order_id': 'ord-1',
        'product_id': 'prod-1',
        'quantity': 5,
        'unit_price': 200000,
      };
      final item = OdoriSalesOrderItem.fromJson(json);

      // Fallback: quantity * unit_price
      expect(item.lineTotal, 1000000);
    });

    test('falls back to sales_order_id when order_id missing', () {
      final json = {
        'id': 'item-3',
        'sales_order_id': 'ord-99',
        'product_id': 'prod-1',
        'quantity': 1,
        'unit_price': 50000,
      };
      final item = OdoriSalesOrderItem.fromJson(json);
      expect(item.orderId, 'ord-99');
    });

    test('toJson uses correct column names', () {
      final json = {
        'id': 'item-1',
        'order_id': 'ord-1',
        'product_id': 'prod-1',
        'quantity': 10,
        'unit': 'thùng',
        'unit_price': 100000,
        'discount_amount': 5000,
        'line_total': 995000,
      };
      final output = OdoriSalesOrderItem.fromJson(json).toJson();

      expect(output['order_id'], 'ord-1');
      expect(output['product_id'], 'prod-1');
      expect(output['unit_price'], 100000);
      expect(output['line_total'], 995000);
    });
  });
}
