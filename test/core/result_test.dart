import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/core/common/result.dart';
import 'package:flutter_sabohub/core/errors/app_errors.dart';

void main() {
  group('Result.success', () {
    test('isSuccess returns true', () {
      const result = Result.success(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
    });

    test('dataOrNull returns data', () {
      const result = Result.success('hello');
      expect(result.dataOrNull, 'hello');
    });

    test('errorOrNull returns null', () {
      const result = Result.success(42);
      expect(result.errorOrNull, isNull);
    });

    test('dataOrThrow returns data', () {
      const result = Result.success(42);
      expect(result.dataOrThrow, 42);
    });
  });

  group('Result.failure', () {
    final error = ValidationError(message: 'Invalid input');

    test('isFailure returns true', () {
      final result = Result<int>.failure(error);
      expect(result.isFailure, true);
      expect(result.isSuccess, false);
    });

    test('dataOrNull returns null', () {
      final result = Result<int>.failure(error);
      expect(result.dataOrNull, isNull);
    });

    test('errorOrNull returns the error', () {
      final result = Result<int>.failure(error);
      expect(result.errorOrNull, error);
    });

    test('dataOrThrow throws the AppError', () {
      final result = Result<int>.failure(error);
      expect(() => result.dataOrThrow, throwsA(isA<ValidationError>()));
    });
  });

  group('Result.when', () {
    test('calls success callback for Success', () {
      const result = Result.success(10);
      final value = result.when(
        success: (data) => data * 2,
        failure: (_) => -1,
      );
      expect(value, 20);
    });

    test('calls failure callback for Failure', () {
      final result = Result<int>.failure(
        NetworkError(message: 'timeout'),
      );
      final value = result.when(
        success: (data) => data * 2,
        failure: (error) => -1,
      );
      expect(value, -1);
    });
  });

  group('Result.map', () {
    test('transforms success value', () {
      const result = Result.success(5);
      final mapped = result.map((data) => data.toString());

      expect(mapped.isSuccess, true);
      expect(mapped.dataOrNull, '5');
    });

    test('propagates failure unchanged', () {
      final error = SystemError(message: 'crash');
      final result = Result<int>.failure(error);
      final mapped = result.map((data) => data.toString());

      expect(mapped.isFailure, true);
      expect(mapped.errorOrNull?.message, 'crash');
    });
  });

  group('Result.flatMap', () {
    test('chains success → success', () async {
      const result = Result.success(10);
      final chained = await result.flatMap(
        (data) async => Result.success(data * 3),
      );

      expect(chained.isSuccess, true);
      expect(chained.dataOrNull, 30);
    });

    test('chains success → failure', () async {
      const result = Result.success(10);
      final chained = await result.flatMap(
        (data) async => Result<int>.failure(
          ValidationError(message: 'too big'),
        ),
      );

      expect(chained.isFailure, true);
      expect(chained.errorOrNull?.message, 'too big');
    });

    test('propagates failure without calling transform', () async {
      final error = NetworkError(message: 'no connection');
      final result = Result<int>.failure(error);
      var transformCalled = false;

      final chained = await result.flatMap((data) async {
        transformCalled = true;
        return Result.success(data);
      });

      expect(transformCalled, false);
      expect(chained.isFailure, true);
    });
  });

  group('Result equality', () {
    test('Success with same data are equal', () {
      expect(const Result.success(42), const Result.success(42));
    });

    test('Failure with same error are equal', () {
      final e1 = ValidationError(message: 'x');
      final e2 = ValidationError(message: 'x');
      expect(Result<int>.failure(e1), Result<int>.failure(e2));
    });
  });
}
