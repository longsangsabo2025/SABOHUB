import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/staff.dart';

void main() {
  group('Staff JSON Roundtrip', () {
    test('parses full json correctly', () {
      final json = {'id': 'staff1', 'full_name': 'Huy', 'email': 'huy@sabo.com', 'role': 'staff', 'phone': '0123', 'avatar_url': 'url', 'company_id': 'c1', 'is_active': true, 'created_at': '2026-03-04T12:00:00Z', 'updated_at': '2026-03-04T12:00:00Z'};
      final staff = Staff.fromJson(json);
      expect(staff.id, 'staff1');
      expect(staff.name, 'Huy');
      expect(staff.status, 'active');
      
      final output = staff.toJson();
      expect(output['full_name'], 'Huy');
      expect(output['is_active'], true);
    });
  });
}

