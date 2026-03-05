import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_sabohub/services/company_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakeTransformBuilder<T> extends Fake implements PostgrestTransformBuilder<T> {
  final dynamic data;
  FakeTransformBuilder(this.data);

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) async {
    return onValue(data as T);
  }
}

class FakeFilterBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  final dynamic data;
  FakeFilterBuilder(this.data);

  @override
  PostgrestFilterBuilder<T> isFilter(String column, dynamic value) => this;

  @override
  PostgrestFilterBuilder<T> or(String filters, {String? referencedTable}) => this;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) => this;

  @override
  PostgrestTransformBuilder<T> order(String column, {bool ascending = false, bool nullsFirst = false, String? referencedTable}) {
    return FakeTransformBuilder<T>(data);
  }
  
  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakeTransformBuilder<Map<String, dynamic>>(data);
  }
  
  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakeTransformBuilder<Map<String, dynamic>?>(data);
  }
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic responseData;
  FakeQueryBuilder(this.responseData);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
     return FakeFilterBuilder<List<Map<String, dynamic>>>(responseData);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late CompanyService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    service = CompanyService();
    service.mockClient = mockClient;
  });

  group('CompanyService Tests', () {
    test('getAllCompanies returns list of companies', () async {
      final mockData = [
        {
          'id': 'comp-101',
          'name': 'Test Company',
          'is_active': true,
          'business_type': 'restaurant',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }
      ];

      when(() => mockClient.from('companies')).thenAnswer((_) => FakeQueryBuilder(mockData));

      final result = await service.getAllCompanies();

      expect(result, isNotEmpty);
      expect(result.first.id, 'comp-101');
      expect(result.first.name, 'Test Company');
    });

    test('getCompanyById returns company if found', () async {
      final mockData = {
        'id': 'comp-102',
        'name': 'Specific Company',
        'is_active': true,
        'business_type': 'hotel',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('companies')).thenAnswer((_) => FakeQueryBuilder(mockData));

      final result = await service.getCompanyById('comp-102');

      expect(result, isNotNull);
      expect(result?.id, 'comp-102');
      expect(result?.name, 'Specific Company');
    });
  });
}
