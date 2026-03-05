import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/company.dart';
import 'package:flutter_sabohub/models/business_type.dart';

void main() {
  group('Company JSON Roundtrip', () {
    test('parses full json correctly', () {
      final json = {'id': 'c1', 'name': 'Sabo', 'business_type': 'restaurant', 'address': 'HN', 'phone': '012', 'email': 'sabo@company.com', 'is_active': true};
      final company = Company.fromJson(json);
      expect(company.id, 'c1');
      expect(company.name, 'Sabo');
      expect(company.type, BusinessType.restaurant);
      expect(company.status, 'active');
      
      final output = company.toJson();
      expect(output['name'], 'Sabo');
      expect(output['business_type'], 'restaurant');
      expect(output['is_active'], true);
    });
  });
}
