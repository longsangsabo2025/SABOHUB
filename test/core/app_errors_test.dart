import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/core/errors/app_errors.dart';

void main() {
  group('AppError.userMessage', () {
    test('network → Vietnamese network error message', () {
      final error = NetworkError(message: 'Connection refused');
      expect(error.userMessage,
          'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.');
    });

    test('authentication → session expired message', () {
      final error = AuthenticationError(message: 'Token expired');
      expect(error.userMessage,
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
    });

    test('validation → echoes actual message', () {
      final error = ValidationError(message: 'Tên không được để trống');
      expect(error.userMessage, 'Tên không được để trống');
    });

    test('permission → no permission message', () {
      final error = PermissionError(message: 'Forbidden');
      expect(error.userMessage,
          'Bạn không có quyền thực hiện hành động này.');
    });

    test('system → system error message', () {
      final error = SystemError(message: 'Internal error');
      expect(error.userMessage,
          'Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau.');
    });
  });

  group('AppError.shouldReport', () {
    test('true for high severity', () {
      final error = AuthenticationError(message: 'x');
      expect(error.severity, ErrorSeverity.high);
      expect(error.shouldReport, true);
    });

    test('true for critical severity', () {
      final error = SystemError(message: 'crash');
      expect(error.severity, ErrorSeverity.critical);
      expect(error.shouldReport, true);
    });

    test('false for medium severity', () {
      final error = NetworkError(message: 'timeout');
      expect(error.severity, ErrorSeverity.medium);
      expect(error.shouldReport, false);
    });

    test('false for low severity', () {
      final error = ValidationError(message: 'invalid');
      expect(error.severity, ErrorSeverity.low);
      expect(error.shouldReport, false);
    });
  });

  group('NetworkError', () {
    test('has correct category and severity', () {
      final error = NetworkError(
        message: 'Connection failed',
        statusCode: 503,
        endpoint: '/api/v1/orders',
      );
      expect(error.category, ErrorCategory.network);
      expect(error.severity, ErrorSeverity.medium);
      expect(error.statusCode, 503);
      expect(error.endpoint, '/api/v1/orders');
    });
  });

  group('ValidationError', () {
    test('supports field-level errors', () {
      final error = ValidationError(
        message: 'Validation failed',
        fieldErrors: {
          'email': ['Email không hợp lệ'],
          'phone': ['Số điện thoại phải có 10 số'],
        },
      );
      expect(error.fieldErrors!.keys.length, 2);
      expect(error.fieldErrors!['email']!.first, 'Email không hợp lệ');
    });
  });

  group('AppError Equatable', () {
    test('errors with same properties are equal', () {
      final e1 = ValidationError(message: 'test', code: 'V001');
      final e2 = ValidationError(message: 'test', code: 'V001');
      expect(e1, e2);
    });

    test('errors with different messages are not equal', () {
      final e1 = NetworkError(message: 'a');
      final e2 = NetworkError(message: 'b');
      expect(e1, isNot(e2));
    });
  });
}
