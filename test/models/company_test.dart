import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/company.dart';
import 'package:flutter_sabohub/models/business_type.dart';

void main() {
  group('Company Model', () {
    group('fromJson', () {
      test('parses basic company JSON', () {
        final json = {
          'id': 'comp-001',
          'name': 'SABO Billiards Quận 7',
          'business_type': 'billiards',
          'address': '123 Nguyễn Huệ, Q7, HCM',
          'phone': '0281234567',
          'email': 'info@sabo.vn',
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.id, 'comp-001');
        expect(company.name, 'SABO Billiards Quận 7');
        expect(company.type, BusinessType.billiards);
        expect(company.address, '123 Nguyễn Huệ, Q7, HCM');
        expect(company.phone, '0281234567');
        expect(company.status, 'active');
      });

      test('parses distribution business type', () {
        final json = {
          'id': 'comp-002',
          'name': 'Odori Distribution',
          'business_type': 'distribution',
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.type, BusinessType.distribution);
        expect(company.type.isDistribution, true);
        expect(company.type.isEntertainment, false);
      });

      test('defaults to billiards for unknown business type', () {
        final json = {
          'id': 'comp-003',
          'name': 'Unknown',
          'business_type': 'space_station',
          'is_active': true,
        };

        final company = Company.fromJson(json);
        expect(company.type, BusinessType.billiards);
      });

      test('sets status to inactive when is_active is false', () {
        final json = {
          'id': 'comp-004',
          'name': 'Closed Shop',
          'business_type': 'cafe',
          'is_active': false,
        };

        final company = Company.fromJson(json);
        expect(company.status, 'inactive');
      });

      test('parses check-in location settings', () {
        final json = {
          'id': 'comp-005',
          'name': 'With Location',
          'business_type': 'restaurant',
          'check_in_latitude': 10.762622,
          'check_in_longitude': 106.660172,
          'check_in_radius': 100.0,
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.checkInLatitude, 10.762622);
        expect(company.checkInLongitude, 106.660172);
        expect(company.checkInRadius, 100.0);
      });

      test('parses bank account info for VietQR', () {
        final json = {
          'id': 'comp-006',
          'name': 'With Bank',
          'business_type': 'retail',
          'bank_name': 'Vietcombank',
          'bank_account_number': '1234567890',
          'bank_account_name': 'CONG TY SABO',
          'bank_bin': '970436',
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.bankName, 'Vietcombank');
        expect(company.bankAccountNumber, '1234567890');
        expect(company.bankAccountName, 'CONG TY SABO');
        expect(company.bankBin, '970436');
      });

      test('parses timestamps correctly', () {
        final json = {
          'id': 'comp-007',
          'name': 'With Dates',
          'business_type': 'hotel',
          'created_at': '2025-01-15T10:30:00.000Z',
          'updated_at': '2026-02-20T14:00:00.000Z',
          'deleted_at': '2026-02-25T09:00:00.000Z',
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.createdAt, isNotNull);
        expect(company.createdAt!.year, 2025);
        expect(company.deletedAt, isNotNull);
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'comp-008',
          'name': 'Minimal',
          'business_type': 'cafe',
          'is_active': true,
        };

        final company = Company.fromJson(json);

        expect(company.phone, isNull);
        expect(company.email, isNull);
        expect(company.logo, isNull);
        expect(company.checkInLatitude, isNull);
        expect(company.bankName, isNull);
        expect(company.address, '');
      });
    });

    group('toJson', () {
      test('serializes company correctly', () {
        final company = Company(
          id: 'comp-001',
          name: 'Test Company',
          type: BusinessType.restaurant,
          address: '456 Lê Lợi',
          tableCount: 20,
          monthlyRevenue: 150000000,
          employeeCount: 15,
          status: 'active',
        );

        final json = company.toJson();

        expect(json['id'], 'comp-001');
        expect(json['name'], 'Test Company');
        expect(json['business_type'], 'restaurant');
        expect(json['address'], '456 Lê Lợi');
        expect(json['table_count'], 20);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final company = Company(
          id: 'comp-001',
          name: 'Original',
          type: BusinessType.cafe,
          address: 'Old Address',
          tableCount: 10,
          monthlyRevenue: 50000000,
          employeeCount: 5,
        );

        final updated = company.copyWith(
          name: 'Updated Name',
          address: 'New Address',
        );

        expect(updated.name, 'Updated Name');
        expect(updated.address, 'New Address');
        expect(updated.id, 'comp-001'); // Unchanged
        expect(updated.type, BusinessType.cafe); // Unchanged
      });
    });

    group('businessType getter', () {
      test('returns type alias', () {
        final company = Company(
          id: '1',
          name: 'Test',
          type: BusinessType.manufacturing,
          address: '',
          tableCount: 0,
          monthlyRevenue: 0,
          employeeCount: 0,
        );

        expect(company.businessType, BusinessType.manufacturing);
        expect(company.businessType, company.type);
      });
    });
  });
}
