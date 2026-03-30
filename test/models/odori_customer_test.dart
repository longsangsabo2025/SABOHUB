import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/models/odori_customer.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullCustomerJson() => {
        'id': 'cust-1',
        'company_id': 'comp-1',
        'branch_id': 'br-1',
        'code': 'KH-001',
        'name': 'Siêu thị ABC',
        'type': 'distributor',
        'phone': '0901234567',
        'phone2': '0909876543',
        'email': 'abc@example.com',
        'address': '123 Nguyễn Huệ',
        'city': 'HCM',
        'district': 'Quận 1',
        'ward': 'Phường Bến Nghé',
        'street_number': '123',
        'street': 'Nguyễn Huệ',
        'lat': 10.7769,
        'lng': 106.7009,
        'tax_code': '0123456789',
        'contact_person': 'Nguyễn Văn A',
        'payment_terms': 45,
        'credit_limit': 50000000.0,
        'category': 'retail',
        'channel': 'horeca',
        'tags': ['vip', 'hcm'],
        'assigned_sale_id': 'emp-1',
        'employees': {'full_name': 'Trần Văn B'},
        'status': 'active',
        'tier': 'gold',
        'referrer_id': 'ref-1',
        'referrers': {'name': 'Người giới thiệu C'},
        'lead_status': 'hot',
        'created_at': '2026-01-15T08:00:00Z',
        'updated_at': '2026-03-29T10:00:00Z',
      };

  Map<String, dynamic> minimalCustomerJson() => {
        'id': 'cust-2',
        'company_id': 'comp-1',
        'name': 'Test Customer',
        'created_at': '2026-03-29T08:00:00Z',
      };

  // ─── fromJson ──────────────────────────────────────────

  group('OdoriCustomer', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final customer = OdoriCustomer.fromJson(fullCustomerJson());

        expect(customer.id, 'cust-1');
        expect(customer.code, 'KH-001');
        expect(customer.name, 'Siêu thị ABC');
        expect(customer.type, 'distributor');
        expect(customer.phone, '0901234567');
        expect(customer.lat, 10.7769);
        expect(customer.lng, 106.7009);
        expect(customer.paymentTerms, 45);
        expect(customer.creditLimit, 50000000.0);
        expect(customer.channel, 'horeca');
        expect(customer.tags, ['vip', 'hcm']);
        expect(customer.assignedSaleId, 'emp-1');
        expect(customer.assignedSaleName, 'Trần Văn B');
        expect(customer.tier, 'gold');
        expect(customer.referrerId, 'ref-1');
        expect(customer.referrerName, 'Người giới thiệu C');
        expect(customer.leadStatus, 'hot');
        expect(customer.status, 'active');
      });

      test('parses minimal JSON with defaults', () {
        final customer = OdoriCustomer.fromJson(minimalCustomerJson());

        expect(customer.id, 'cust-2');
        expect(customer.code, '');
        expect(customer.name, 'Test Customer');
        expect(customer.type, isNull);
        expect(customer.phone, isNull);
        expect(customer.paymentTerms, 30);
        expect(customer.creditLimit, 0);
        expect(customer.status, 'active');
        expect(customer.tier, 'bronze');
        expect(customer.leadStatus, 'cold');
        expect(customer.tags, isNull);
        expect(customer.lat, isNull);
        expect(customer.lng, isNull);
      });
    });

    // ─── Getters ───────────────────────────────────────────

    group('computed getters', () {
      test('fullAddress combines address parts', () {
        final customer = OdoriCustomer.fromJson(fullCustomerJson());
        final addr = customer.fullAddress;
        expect(addr, contains('123'));
        expect(addr, contains('Nguyễn Huệ'));
        expect(addr, contains('Quận 1'));
        expect(addr, contains('HCM'));
      });

      test('fullAddress empty when no address parts', () {
        final customer = OdoriCustomer.fromJson(minimalCustomerJson());
        expect(customer.fullAddress, '');
      });

      test('hasLocation returns true when lat/lng present', () {
        final customer = OdoriCustomer.fromJson(fullCustomerJson());
        expect(customer.hasLocation, true);
      });

      test('hasLocation returns false when lat/lng missing', () {
        final customer = OdoriCustomer.fromJson(minimalCustomerJson());
        expect(customer.hasLocation, false);
      });
    });

    // ─── toJson ────────────────────────────────────────────

    group('toJson', () {
      test('uses correct DB column names', () {
        final json = OdoriCustomer.fromJson(fullCustomerJson()).toJson();

        // Verify snake_case DB column names — these are the TRAPS from CLAUDE.md
        expect(json.containsKey('code'), true);
        expect(json.containsKey('customer_code'), false);
        expect(json.containsKey('type'), true);
        expect(json.containsKey('customer_type'), false);
        expect(json.containsKey('lat'), true);
        expect(json.containsKey('latitude'), false);
        expect(json.containsKey('lng'), true);
        expect(json.containsKey('longitude'), false);
        expect(json.containsKey('assigned_sale_id'), true);
        expect(json.containsKey('assigned_employee_id'), false);
        expect(json.containsKey('payment_terms'), true);
        expect(json.containsKey('payment_term_days'), false);
      });

      test('roundtrips key fields', () {
        final original = OdoriCustomer.fromJson(fullCustomerJson());
        final json = original.toJson();

        expect(json['id'], 'cust-1');
        expect(json['company_id'], 'comp-1');
        expect(json['code'], 'KH-001');
        expect(json['name'], 'Siêu thị ABC');
        expect(json['payment_terms'], 45);
        expect(json['credit_limit'], 50000000.0);
        expect(json['tier'], 'gold');
        expect(json['lead_status'], 'hot');
        expect(json['status'], 'active');
        expect(json['tags'], ['vip', 'hcm']);
      });
    });

    // ─── copyWith ──────────────────────────────────────────

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = OdoriCustomer.fromJson(fullCustomerJson());
        final updated = original.copyWith(
          name: 'New Name',
          tier: 'diamond',
          creditLimit: 100000000,
        );

        expect(updated.name, 'New Name');
        expect(updated.tier, 'diamond');
        expect(updated.creditLimit, 100000000);
        // Unchanged fields preserved
        expect(updated.id, original.id);
        expect(updated.code, original.code);
        expect(updated.phone, original.phone);
      });

      test('preserves all fields when no changes', () {
        final original = OdoriCustomer.fromJson(fullCustomerJson());
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.code, original.code);
        expect(copy.paymentTerms, original.paymentTerms);
        expect(copy.creditLimit, original.creditLimit);
        expect(copy.tier, original.tier);
      });
    });
  });
}
