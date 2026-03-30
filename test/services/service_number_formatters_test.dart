import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/service/services/service_number_formatters.dart';

void main() {
  group('formatServiceRevenueCompact', () {
    test('formats millions with M suffix', () {
      expect(formatServiceRevenueCompact(1000000), '1.0M');
      expect(formatServiceRevenueCompact(2500000), '2.5M');
      expect(formatServiceRevenueCompact(10000000), '10.0M');
    });

    test('formats thousands with K suffix', () {
      expect(formatServiceRevenueCompact(1000), '1K');
      expect(formatServiceRevenueCompact(5500), '6K'); // toStringAsFixed(0) rounds
      expect(formatServiceRevenueCompact(999999), '1000K');
    });

    test('formats small values as-is', () {
      expect(formatServiceRevenueCompact(500), '500');
      expect(formatServiceRevenueCompact(0), '0');
    });
  });

  group('formatServiceCountCompact', () {
    test('formats millions with M suffix', () {
      expect(formatServiceCountCompact(1000000), '1.0M');
      expect(formatServiceCountCompact(2500000), '2.5M');
    });

    test('formats thousands with K suffix', () {
      expect(formatServiceCountCompact(1000), '1.0K');
      expect(formatServiceCountCompact(1500), '1.5K');
    });

    test('formats small values as-is', () {
      expect(formatServiceCountCompact(999), '999');
      expect(formatServiceCountCompact(0), '0');
    });
  });

  group('formatServiceCurrencyCompact', () {
    test('formats billions with B suffix', () {
      expect(formatServiceCurrencyCompact(1000000000), '1.0B');
      expect(formatServiceCurrencyCompact(2500000000), '2.5B');
    });

    test('formats millions with M suffix', () {
      expect(formatServiceCurrencyCompact(1000000), '1.0M');
      expect(formatServiceCurrencyCompact(5500000), '5.5M');
    });

    test('formats thousands with K suffix', () {
      expect(formatServiceCurrencyCompact(1000), '1.0K');
      expect(formatServiceCurrencyCompact(50000), '50.0K');
    });

    test('formats small values with comma grouping', () {
      expect(formatServiceCurrencyCompact(500), '500');
    });

    test('handles negative values correctly', () {
      expect(formatServiceCurrencyCompact(-5000000), '-5.0M');
      expect(formatServiceCurrencyCompact(-2000), '-2.0K');
    });
  });
}
