import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/models/odori_receivable.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullReceivableJson() => {
        'id': 'recv-1',
        'company_id': 'comp-1',
        'customer_id': 'cust-1',
        'customers': {'name': 'Shop ABC'},
        'reference_id': 'ord-1',
        'sales_orders': {'order_number': 'SO-2026-001'},
        'reference_number': 'INV-2026-001',
        'invoice_date': '2026-01-15',
        'due_date': '2026-02-14',
        'original_amount': 5000000,
        'paid_amount': 2000000,
        'write_off_amount': 0,
        'status': 'partial',
        'notes': 'Đợi thanh toán đợt 2',
        'created_at': '2026-01-15T10:00:00Z',
        'updated_at': '2026-02-01T08:00:00Z',
      };

  Map<String, dynamic> minimalReceivableJson() => {
        'id': 'recv-2',
        'company_id': 'comp-1',
        'customer_id': 'cust-2',
        'invoice_date': '2026-03-01',
        'due_date': '2026-03-31',
        'original_amount': 1000000,
        'status': 'open',
        'created_at': '2026-03-01T10:00:00Z',
      };

  // ─── OdoriReceivable Tests ─────────────────────────────

  group('OdoriReceivable', () {
    group('fromJson', () {
      test('parses full JSON with joins', () {
        final r = OdoriReceivable.fromJson(fullReceivableJson());

        expect(r.id, 'recv-1');
        expect(r.companyId, 'comp-1');
        expect(r.customerId, 'cust-1');
        expect(r.customerName, 'Shop ABC');
        expect(r.orderId, 'ord-1');
        expect(r.orderNumber, 'SO-2026-001');
        expect(r.invoiceNumber, 'INV-2026-001');
        expect(r.originalAmount, 5000000);
        expect(r.paidAmount, 2000000);
        expect(r.status, 'partial');
      });

      test('remainingAmount = original - paid - writeOff', () {
        final r = OdoriReceivable.fromJson(fullReceivableJson());
        // 5000000 - 2000000 - 0 = 3000000
        expect(r.remainingAmount, 3000000);
      });

      test('remainingAmount accounts for write_off_amount', () {
        final json = fullReceivableJson()
          ..['write_off_amount'] = 500000;
        final r = OdoriReceivable.fromJson(json);
        // 5000000 - 2000000 - 500000 = 2500000
        expect(r.remainingAmount, 2500000);
      });

      test('parses minimal JSON with defaults', () {
        final r = OdoriReceivable.fromJson(minimalReceivableJson());

        expect(r.paidAmount, 0);
        expect(r.remainingAmount, 1000000); // 1000000 - 0 - 0
        expect(r.customerName, isNull);
        expect(r.orderId, isNull);
        expect(r.orderNumber, isNull);
        expect(r.invoiceNumber, ''); // reference_number null → ''
        expect(r.notes, isNull);
      });
    });

    group('aging bucket logic', () {
      test('paid receivable → "paid" bucket', () {
        final json = minimalReceivableJson()..['status'] = 'paid';
        expect(OdoriReceivable.fromJson(json).agingBucket, 'paid');
      });

      test('not yet overdue → "current" bucket', () {
        // dueDate far in the future
        final json = minimalReceivableJson()
          ..['due_date'] = DateTime.now().add(const Duration(days: 60)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).agingBucket, 'current');
      });

      test('1-30 days overdue → "1-30" bucket', () {
        final json = minimalReceivableJson()
          ..['due_date'] = DateTime.now().subtract(const Duration(days: 15)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).agingBucket, '1-30');
      });

      test('31-60 days overdue → "31-60" bucket', () {
        final json = minimalReceivableJson()
          ..['due_date'] = DateTime.now().subtract(const Duration(days: 45)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).agingBucket, '31-60');
      });

      test('61-90 days overdue → "61-90" bucket', () {
        final json = minimalReceivableJson()
          ..['due_date'] = DateTime.now().subtract(const Duration(days: 75)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).agingBucket, '61-90');
      });

      test('>90 days overdue → "90+" bucket', () {
        final json = minimalReceivableJson()
          ..['due_date'] = DateTime.now().subtract(const Duration(days: 120)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).agingBucket, '90+');
      });
    });

    group('isOverdue', () {
      test('true when status is overdue', () {
        final json = minimalReceivableJson()..['status'] = 'overdue';
        expect(OdoriReceivable.fromJson(json).isOverdue, true);
      });

      test('true when open and past due date', () {
        final json = minimalReceivableJson()
          ..['status'] = 'open'
          ..['due_date'] = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).isOverdue, true);
      });

      test('false when open and not yet past due', () {
        final json = minimalReceivableJson()
          ..['status'] = 'open'
          ..['due_date'] = DateTime.now().add(const Duration(days: 30)).toIso8601String();
        expect(OdoriReceivable.fromJson(json).isOverdue, false);
      });
    });

    group('toJson', () {
      test('uses correct DB column names', () {
        final json = OdoriReceivable.fromJson(fullReceivableJson()).toJson();

        // DB uses reference_id, NOT order_id
        expect(json['reference_id'], 'ord-1');
        expect(json.containsKey('order_id'), false);

        // DB uses reference_number, NOT invoice_number
        expect(json['reference_number'], 'INV-2026-001');
        expect(json.containsKey('invoice_number'), false);

        expect(json['original_amount'], 5000000);
        expect(json['paid_amount'], 2000000);
        expect(json['status'], 'partial');
      });
    });
  });

  // ─── OdoriPayment Tests ────────────────────────────────

  group('OdoriPayment', () {
    Map<String, dynamic> paymentJson() => {
          'id': 'pay-1',
          'company_id': 'comp-1',
          'receivable_id': 'recv-1',
          'customer_id': 'cust-1',
          'customers': {'name': 'Shop ABC'},
          'payment_number': 'PAY-2026-001',
          'payment_date': '2026-02-01',
          'amount': 2000000,
          'payment_method': 'bank_transfer',
          'reference_number': 'REF-123',
          'collected_by': 'emp-1',
          'employees': {'full_name': 'Nhân viên A'},
          'notes': 'Thu đợt 1',
          'proof_image_url': 'https://storage.example/proof.jpg',
          'status': 'confirmed',
          'created_at': '2026-02-01T10:00:00Z',
        };

    test('parses full JSON with joins', () {
      final p = OdoriPayment.fromJson(paymentJson());

      expect(p.id, 'pay-1');
      expect(p.customerName, 'Shop ABC');
      expect(p.collectedByName, 'Nhân viên A');
      expect(p.amount, 2000000);
      expect(p.paymentMethod, 'bank_transfer');
      expect(p.status, 'confirmed');
    });

    test('default status is confirmed when null', () {
      final json = paymentJson()..remove('status');
      expect(OdoriPayment.fromJson(json).status, 'confirmed');
    });

    group('paymentMethodLabel Vietnamese labels', () {
      test('cash → Tiền mặt', () {
        final json = paymentJson()..['payment_method'] = 'cash';
        expect(OdoriPayment.fromJson(json).paymentMethodLabel, 'Tiền mặt');
      });

      test('bank_transfer → Chuyển khoản', () {
        final json = paymentJson()..['payment_method'] = 'bank_transfer';
        expect(OdoriPayment.fromJson(json).paymentMethodLabel, 'Chuyển khoản');
      });

      test('check → Séc', () {
        final json = paymentJson()..['payment_method'] = 'check';
        expect(OdoriPayment.fromJson(json).paymentMethodLabel, 'Séc');
      });

      test('mobile_payment → Ví điện tử', () {
        final json = paymentJson()..['payment_method'] = 'mobile_payment';
        expect(OdoriPayment.fromJson(json).paymentMethodLabel, 'Ví điện tử');
      });

      test('unknown → returns raw value', () {
        final json = paymentJson()..['payment_method'] = 'crypto';
        expect(OdoriPayment.fromJson(json).paymentMethodLabel, 'crypto');
      });
    });

    group('toJson', () {
      test('uses correct DB column names', () {
        final json = OdoriPayment.fromJson(paymentJson()).toJson();

        expect(json['receivable_id'], 'recv-1');
        expect(json['customer_id'], 'cust-1');
        expect(json['payment_number'], 'PAY-2026-001');
        expect(json['payment_method'], 'bank_transfer');
        expect(json['collected_by'], 'emp-1');
        expect(json['proof_image_url'], 'https://storage.example/proof.jpg');

        // Should NOT include join fields
        expect(json.containsKey('customers'), false);
        expect(json.containsKey('employees'), false);
      });
    });
  });
}
