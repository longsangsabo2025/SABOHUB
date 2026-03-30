import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/company.dart';
import 'package:flutter_sabohub/models/business_type.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullCompanyJson() => {
        'id': 'c1',
        'name': 'Sabo Corp',
        'business_type': 'restaurant',
        'address': '123 Nguyễn Huệ, Q1, HCM',
        'phone': '0901234567',
        'email': 'sabo@company.com',
        'logo': 'https://storage.example/logo.png',
        'is_active': true,
        'check_in_latitude': 10.7769,
        'check_in_longitude': 106.7009,
        'check_in_radius': 200.0,
        'bank_name': 'Vietcombank',
        'bank_account_number': '1234567890',
        'bank_account_name': 'CONG TY SABO',
        'bank_bin': '970436',
        'bank_name_2': 'Techcombank',
        'bank_account_number_2': '0987654321',
        'bank_account_name_2': 'SABO CORP',
        'bank_bin_2': '970407',
        'active_bank_account': 1,
        'ai_api_key': 'AIzaSy...',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
      };

  Map<String, dynamic> minimalCompanyJson() => {
        'id': 'c2',
        'name': 'Mini Co',
      };

  // ─── fromJson Tests ────────────────────────────────────

  group('Company.fromJson', () {
    test('parses full JSON correctly', () {
      final company = Company.fromJson(fullCompanyJson());

      expect(company.id, 'c1');
      expect(company.name, 'Sabo Corp');
      expect(company.type, BusinessType.restaurant);
      expect(company.address, '123 Nguyễn Huệ, Q1, HCM');
      expect(company.phone, '0901234567');
      expect(company.email, 'sabo@company.com');
      expect(company.status, 'active');
      expect(company.checkInLatitude, 10.7769);
      expect(company.checkInLongitude, 106.7009);
      expect(company.checkInRadius, 200.0);
      expect(company.aiApiKey, 'AIzaSy...');
    });

    test('parses minimal JSON with defaults', () {
      final company = Company.fromJson(minimalCompanyJson());

      expect(company.name, 'Mini Co');
      expect(company.type, BusinessType.billiards); // default
      expect(company.address, ''); // default
      expect(company.tableCount, 0); // always 0 from json
      expect(company.monthlyRevenue, 0.0);
      expect(company.employeeCount, 0);
      expect(company.status, 'active'); // is_active missing → active
      expect(company.activeBankAccount, 1); // default
    });

    test('is_active=false → status inactive', () {
      final json = fullCompanyJson()..['is_active'] = false;
      expect(Company.fromJson(json).status, 'inactive');
    });

    test('unknown business_type defaults to billiards', () {
      final json = fullCompanyJson()..['business_type'] = 'unknown_type';
      expect(Company.fromJson(json).type, BusinessType.billiards);
    });

    test('businessType getter is alias for type', () {
      final company = Company.fromJson(fullCompanyJson());
      expect(company.businessType, company.type);
    });
  });

  // ─── Bank Account Helpers ──────────────────────────────

  group('Bank account helpers', () {
    test('active bank = 1 returns primary bank values', () {
      final company = Company.fromJson(fullCompanyJson());

      expect(company.activeBankNameValue, 'Vietcombank');
      expect(company.activeBankAccountNumberValue, '1234567890');
      expect(company.activeBankAccountNameValue, 'CONG TY SABO');
      expect(company.activeBankBinValue, '970436');
    });

    test('active bank = 2 returns secondary bank values', () {
      final json = fullCompanyJson()..['active_bank_account'] = 2;
      final company = Company.fromJson(json);

      expect(company.activeBankNameValue, 'Techcombank');
      expect(company.activeBankAccountNumberValue, '0987654321');
      expect(company.activeBankAccountNameValue, 'SABO CORP');
      expect(company.activeBankBinValue, '970407');
    });

    test('hasBankAccount2 true when bank_account_number_2 exists', () {
      final company = Company.fromJson(fullCompanyJson());
      expect(company.hasBankAccount2, true);
    });

    test('hasBankAccount2 false when no secondary bank', () {
      final company = Company.fromJson(minimalCompanyJson());
      expect(company.hasBankAccount2, false);
    });
  });

  // ─── toJson Tests ──────────────────────────────────────

  group('Company.toJson', () {
    test('uses correct DB column names', () {
      final json = Company.fromJson(fullCompanyJson()).toJson();

      // CRITICAL: DB uses is_active (boolean) NOT status (string)
      expect(json['is_active'], true);
      expect(json.containsKey('status'), false);

      // DB uses business_type (string)
      expect(json['business_type'], 'restaurant');
      expect(json.containsKey('type'), false);
    });

    test('roundtrip preserves key fields', () {
      final json = Company.fromJson(fullCompanyJson()).toJson();

      expect(json['id'], 'c1');
      expect(json['name'], 'Sabo Corp');
      expect(json['address'], '123 Nguyễn Huệ, Q1, HCM');
      expect(json['phone'], '0901234567');
    });
  });

  // ─── copyWith Tests ────────────────────────────────────

  group('Company.copyWith', () {
    test('preserves all fields when no args', () {
      final original = Company.fromJson(fullCompanyJson());
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.type, original.type);
      expect(copy.bankName, original.bankName);
      expect(copy.activeBankAccount, original.activeBankAccount);
      expect(copy.aiApiKey, original.aiApiKey);
    });

    test('updates name and activeBankAccount only', () {
      final original = Company.fromJson(fullCompanyJson());
      final updated = original.copyWith(
        name: 'New Name',
        activeBankAccount: 2,
      );

      expect(updated.name, 'New Name');
      expect(updated.activeBankAccount, 2);
      expect(updated.type, original.type); // unchanged
      expect(updated.email, original.email); // unchanged
    });
  });
}
