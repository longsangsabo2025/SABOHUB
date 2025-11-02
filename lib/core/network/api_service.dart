import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/app_errors.dart';
import '../errors/error_handler.dart';

/// API endpoints configuration
class ApiEndpoints {
  static const String baseUrl =
      'https://api.sabohub.com'; // Replace with actual API URL

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Staff endpoints
  static const String checkin = '/staff/checkin';
  static const String checkout = '/staff/checkout';
  static const String tasks = '/staff/tasks';
  static const String updateTask = '/staff/tasks';

  // Tables endpoints
  static const String tables = '/tables';
  static const String tableStatus = '/tables';

  // Messages endpoints
  static const String messages = '/messages';
  static const String sendMessage = '/messages';

  // Manager endpoints
  static const String employees = '/manager/employees';
  static const String reports = '/manager/reports';
  static const String finance = '/manager/finance';

  // CEO endpoints
  static const String analytics = '/ceo/analytics';
  static const String companies = '/ceo/companies';
}

/// HTTP methods
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
}

/// API request configuration
class ApiRequest {
  final String endpoint;
  final HttpMethod method;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
  final Duration? timeout;

  const ApiRequest({
    required this.endpoint,
    required this.method,
    this.data,
    this.queryParameters,
    this.headers,
    this.timeout,
  });
}

/// API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;
  final Map<String, dynamic>? metadata;

  const ApiResponse({
    this.data,
    this.message,
    required this.success,
    this.statusCode,
    this.metadata,
  });

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse<T>(
      data: data,
      message: message,
      success: true,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      message: message,
      success: false,
      statusCode: statusCode,
    );
  }
}

/// Main API service class
class ApiService {
  late final Dio _dio;
  final ErrorHandler _errorHandler = ErrorHandler();

  ApiService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  /// Setup Dio interceptors for logging, auth, and error handling
  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token if available
          final token = _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          final appError = _handleDioError(error);
          _errorHandler.handleError(appError);
          handler.next(error);
        },
      ),
    );

    // Logging interceptor (only in debug mode)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  /// Get authentication token (placeholder - implement based on your auth system)
  String? _getAuthToken() {
    // TODO: Implement token retrieval from secure storage
    return null;
  }

  /// Convert Dio error to AppError
  AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError(
          message: 'Connection timeout',
          statusCode: error.response?.statusCode,
          endpoint: error.requestOptions.path,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error';

        if (statusCode == 401) {
          return AuthenticationError(message: 'Authentication failed');
        } else if (statusCode == 403) {
          return PermissionError(message: 'Access denied');
        } else if (statusCode != null &&
            statusCode >= 400 &&
            statusCode < 500) {
          return ValidationError(message: message);
        } else {
          return NetworkError(
            message: message,
            statusCode: statusCode,
            endpoint: error.requestOptions.path,
          );
        }

      case DioExceptionType.cancel:
        return NetworkError(
          message: 'Request cancelled',
          endpoint: error.requestOptions.path,
        );

      case DioExceptionType.connectionError:
        return NetworkError(
          message: 'No internet connection',
          endpoint: error.requestOptions.path,
        );

      case DioExceptionType.unknown:
      default:
        return UnknownError(
          message: error.message ?? 'Unknown network error',
          originalError: error,
        );
    }
  }

  /// Generic request method
  Future<ApiResponse<T>> request<T>(
    ApiRequest request, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final options = Options(
        method: request.method.name.toUpperCase(),
        headers: request.headers,
      );

      final response = await _dio.request<dynamic>(
        request.endpoint,
        data: request.data,
        queryParameters: request.queryParameters,
        options: options,
      );

      // Parse response data
      T? data;
      if (fromJson != null && response.data != null) {
        data = fromJson(response.data);
      } else {
        data = response.data as T?;
      }

      return ApiResponse.success(
        data as T,
        statusCode: response.statusCode,
        message: response.data?['message'],
      );
    } on DioException catch (e) {
      final appError = _handleDioError(e);
      return ApiResponse.error(
        appError.message,
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      final appError = _errorHandler.handleError(e);
      return ApiResponse.error(appError.message);
    }
  }

  /// GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return request<T>(
      ApiRequest(
        endpoint: endpoint,
        method: HttpMethod.get,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  /// POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return request<T>(
      ApiRequest(
        endpoint: endpoint,
        method: HttpMethod.post,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  /// PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return request<T>(
      ApiRequest(
        endpoint: endpoint,
        method: HttpMethod.put,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  /// PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return request<T>(
      ApiRequest(
        endpoint: endpoint,
        method: HttpMethod.patch,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  /// DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic)? fromJson,
  }) {
    return request<T>(
      ApiRequest(
        endpoint: endpoint,
        method: HttpMethod.delete,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
      fromJson: fromJson,
    );
  }

  /// Update auth token
  void updateAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Download file
  Future<ApiResponse<String>> downloadFile(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );

      return ApiResponse.success(savePath);
    } on DioException catch (e) {
      final appError = _handleDioError(e);
      return ApiResponse.error(appError.message);
    }
  }

  /// Upload file
  Future<ApiResponse<T>> uploadFile<T>(
    String endpoint,
    String filePath, {
    String fieldName = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: await MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post<dynamic>(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );

      T? responseData;
      if (fromJson != null && response.data != null) {
        responseData = fromJson(response.data);
      } else {
        responseData = response.data as T?;
      }

      return ApiResponse.success(responseData as T);
    } on DioException catch (e) {
      final appError = _handleDioError(e);
      return ApiResponse.error(appError.message);
    }
  }
}

/// Riverpod provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
