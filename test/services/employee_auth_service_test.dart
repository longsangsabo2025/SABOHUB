import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sabohub/services/employee_auth_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakePostgrestFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final T _response;
  FakePostgrestFilterBuilder(this._response);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) async {
    return onValue(_response);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late EmployeeAuthService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    service = EmployeeAuthService(supabase: mockClient);
  });

  group('EmployeeAuthService Tests', () {
    test('login returns success when rpc returns valid data', () async {
      final mockData = {
        'success': true,
        'employee': {
          'id': 'emp-123',
          'company_id': 'comp-123',
          'username': 'staff01',
          'full_name': 'Test Staff',
          'role': 'STAFF',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      };

      when(() => mockClient.rpc('employee_login', params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(mockData));

      final result = await service.login(
        companyName: 'TestCompany',
        username: 'staff01',
        password: 'password',
      );

      expect(result.success, true);
      expect(result.employee?.id, 'emp-123');
      expect(result.employee?.fullName, 'Test Staff');
    });

    test('login returns error when rpc returns false', () async {
      final mockData = {
        'success': false,
        'error': 'Invalid credentials',
      };

      when(() => mockClient.rpc('employee_login', params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(mockData));

      final result = await service.login(
        companyName: 'TestCompany',
        username: 'staff01',
        password: 'wrong',
      );

      expect(result.success, false);
      expect(result.error, 'Invalid credentials');
    });
  });
}
