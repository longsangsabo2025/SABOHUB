import 'dart:convert';
import 'package:dio/dio.dart';
import '../debug/debug_manager.dart';

/// Debug Interceptor for tracking API calls and responses
class DebugInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final startTime = DateTime.now();

    // Store start time for duration calculation
    options.extra['debug_start_time'] = startTime;

    // Log request details
    DebugManager.api(
      options.method,
      options.uri.toString(),
      request: {
        'headers': _sanitizeHeaders(options.headers),
        'queryParameters': options.queryParameters,
        'data': _sanitizeData(options.data),
      },
    );

    // Set context for this request
    DebugManager.setContext('last_request_url', options.uri.toString());
    DebugManager.setContext('last_request_method', options.method);

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final endTime = DateTime.now();
    final startTime =
        response.requestOptions.extra['debug_start_time'] as DateTime?;
    final duration = startTime != null ? endTime.difference(startTime) : null;

    // Log response
    DebugManager.api(
      response.requestOptions.method,
      response.requestOptions.uri.toString(),
      statusCode: response.statusCode,
      duration: duration,
      response: {
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
        'headers': _sanitizeHeaders(response.headers.map),
        'data': _sanitizeData(response.data),
      },
    );

    // Update context
    DebugManager.setContext('last_response_status', response.statusCode);
    DebugManager.setContext('last_response_time', duration?.inMilliseconds);

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final endTime = DateTime.now();
    final startTime = err.requestOptions.extra['debug_start_time'] as DateTime?;
    final duration = startTime != null ? endTime.difference(startTime) : null;

    // Log error
    DebugManager.error(
      'API Error: ${err.message}',
      tag: 'API',
      data: {
        'method': err.requestOptions.method,
        'url': err.requestOptions.uri.toString(),
        'statusCode': err.response?.statusCode,
        'duration': duration?.inMilliseconds,
        'type': err.type.toString(),
      },
      error: err,
      stackTrace: err.stackTrace,
    );

    // Update context
    DebugManager.setContext(
        'last_error_url', err.requestOptions.uri.toString());
    DebugManager.setContext('last_error_status', err.response?.statusCode);

    super.onError(err, handler);
  }

  /// Sanitize headers by removing sensitive information
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // Remove sensitive headers
    final sensitiveKeys = [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'x-auth-token',
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***HIDDEN***';
      }
      if (sanitized.containsKey(key.toLowerCase())) {
        sanitized[key.toLowerCase()] = '***HIDDEN***';
      }
    }

    return sanitized;
  }

  /// Sanitize request/response data
  dynamic _sanitizeData(dynamic data) {
    if (data == null) return null;

    try {
      // If it's already a map, sanitize it
      if (data is Map) {
        return _sanitizeMap(data);
      }

      // If it's a string, try to parse as JSON
      if (data is String) {
        try {
          final parsed = jsonDecode(data);
          if (parsed is Map) {
            return _sanitizeMap(parsed);
          }
          return data.length > 1000 ? '${data.substring(0, 1000)}...' : data;
        } catch (_) {
          // Not JSON, return truncated string
          return data.length > 1000 ? '${data.substring(0, 1000)}...' : data;
        }
      }

      // For other types, convert to string and truncate if needed
      final stringData = data.toString();
      return stringData.length > 1000
          ? '${stringData.substring(0, 1000)}...'
          : stringData;
    } catch (_) {
      return 'Error sanitizing data';
    }
  }

  /// Sanitize a map by removing sensitive fields
  Map<String, dynamic> _sanitizeMap(Map<dynamic, dynamic> map) {
    final sanitized = <String, dynamic>{};

    // Sensitive field names to hide
    final sensitiveFields = [
      'password',
      'token',
      'secret',
      'key',
      'authorization',
      'auth',
      'credential',
    ];

    map.forEach((key, value) {
      final keyString = key.toString().toLowerCase();

      // Check if field is sensitive
      bool isSensitive =
          sensitiveFields.any((field) => keyString.contains(field));

      if (isSensitive) {
        sanitized[key.toString()] = '***HIDDEN***';
      } else if (value is Map) {
        sanitized[key.toString()] = _sanitizeMap(value);
      } else if (value is List) {
        sanitized[key.toString()] = value.map((item) {
          if (item is Map) return _sanitizeMap(item);
          return item;
        }).toList();
      } else {
        sanitized[key.toString()] = value;
      }
    });

    return sanitized;
  }
}

/// Performance Interceptor for tracking API performance
class PerformanceInterceptor extends Interceptor {
  final Map<String, List<int>> _responseTimes = {};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime =
        response.requestOptions.extra['debug_start_time'] as DateTime?;
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final url = response.requestOptions.uri.toString();

      // Track response times for analytics
      _responseTimes.putIfAbsent(url, () => []);
      _responseTimes[url]!.add(duration.inMilliseconds);

      // Keep only last 10 records per URL
      if (_responseTimes[url]!.length > 10) {
        _responseTimes[url]!.removeAt(0);
      }

      // Calculate stats
      final times = _responseTimes[url]!;
      final avg = times.reduce((a, b) => a + b) / times.length;
      final max = times.reduce((a, b) => a > b ? a : b);
      final min = times.reduce((a, b) => a < b ? a : b);

      // Log performance metrics
      DebugManager.performance(
        'API Call',
        duration,
        metrics: {
          'url': url,
          'method': response.requestOptions.method,
          'statusCode': response.statusCode,
          'avg_response_time': avg.round(),
          'max_response_time': max,
          'min_response_time': min,
          'sample_count': times.length,
        },
      );

      // Warning for slow requests
      if (duration.inMilliseconds > 5000) {
        DebugManager.warning(
          'Slow API response detected: ${duration.inMilliseconds}ms',
          tag: 'PERF',
          data: {
            'url': url,
            'method': response.requestOptions.method,
            'duration': duration.inMilliseconds,
          },
        );
      }
    }

    super.onResponse(response, handler);
  }

  /// Get performance statistics
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};

    _responseTimes.forEach((url, times) {
      if (times.isNotEmpty) {
        final avg = times.reduce((a, b) => a + b) / times.length;
        final max = times.reduce((a, b) => a > b ? a : b);
        final min = times.reduce((a, b) => a < b ? a : b);

        stats[url] = {
          'average': avg.round(),
          'maximum': max,
          'minimum': min,
          'samples': times.length,
        };
      }
    });

    return stats;
  }
}
