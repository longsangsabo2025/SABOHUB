import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../network/api_service.dart';

/// User repository for API operations
class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  /// Login user
  Future<ApiResponse<User>> login({
    required String email,
    required String password,
  }) async {
    return await _apiService.post<User>(
      ApiEndpoints.login,
      data: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => User.fromJson(json['user']),
    );
  }

  /// Get user profile
  Future<ApiResponse<User>> getProfile() async {
    return await _apiService.get<User>(
      ApiEndpoints.profile,
      fromJson: (json) => User.fromJson(json['user']),
    );
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    return await _apiService.put<User>(
      ApiEndpoints.updateProfile,
      data: {
        'name': name,
        if (phone != null) 'phone': phone,
        if (avatar != null) 'avatar': avatar,
      },
      fromJson: (json) => User.fromJson(json['user']),
    );
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    return await _apiService.post<void>(ApiEndpoints.logout);
  }
}

/// Staff repository for API operations
class StaffRepository {
  final ApiService _apiService;

  StaffRepository(this._apiService);

  /// Check in staff
  Future<ApiResponse<Map<String, dynamic>>> checkin({
    required double latitude,
    required double longitude,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.checkin,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Check out staff
  Future<ApiResponse<Map<String, dynamic>>> checkout() async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.checkout,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get staff tasks
  Future<ApiResponse<List<Map<String, dynamic>>>> getTasks() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.tasks,
      fromJson: (json) => List<Map<String, dynamic>>.from(json['tasks']),
    );
  }

  /// Update task status
  Future<ApiResponse<Map<String, dynamic>>> updateTask({
    required String taskId,
    required String status,
    String? notes,
  }) async {
    return await _apiService.patch<Map<String, dynamic>>(
      '${ApiEndpoints.updateTask}/$taskId',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Tables repository for API operations
class TablesRepository {
  final ApiService _apiService;

  TablesRepository(this._apiService);

  /// Get all tables
  Future<ApiResponse<List<Map<String, dynamic>>>> getTables() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.tables,
      fromJson: (json) => List<Map<String, dynamic>>.from(json['tables']),
    );
  }

  /// Update table status
  Future<ApiResponse<Map<String, dynamic>>> updateTableStatus({
    required String tableId,
    required String status,
  }) async {
    return await _apiService.patch<Map<String, dynamic>>(
      '${ApiEndpoints.tableStatus}/$tableId',
      data: {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Messages repository for API operations
class MessagesRepository {
  final ApiService _apiService;

  MessagesRepository(this._apiService);

  /// Get messages
  Future<ApiResponse<List<Map<String, dynamic>>>> getMessages({
    int page = 1,
    int limit = 20,
  }) async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.messages,
      queryParameters: {
        'page': page,
        'limit': limit,
      },
      fromJson: (json) => List<Map<String, dynamic>>.from(json['messages']),
    );
  }

  /// Send message
  Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required String message,
    String? recipientId,
    List<String>? attachments,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiEndpoints.sendMessage,
      data: {
        'message': message,
        if (recipientId != null) 'recipient_id': recipientId,
        if (attachments != null) 'attachments': attachments,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Manager repository for API operations
class ManagerRepository {
  final ApiService _apiService;

  ManagerRepository(this._apiService);

  /// Get employees
  Future<ApiResponse<List<Map<String, dynamic>>>> getEmployees() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.employees,
      fromJson: (json) => List<Map<String, dynamic>>.from(json['employees']),
    );
  }

  /// Get reports
  Future<ApiResponse<Map<String, dynamic>>> getReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.reports,
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
  }

  /// Get finance data
  Future<ApiResponse<Map<String, dynamic>>> getFinance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.finance,
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
  }
}

/// CEO repository for API operations
class CEORepository {
  final ApiService _apiService;

  CEORepository(this._apiService);

  /// Get analytics
  Future<ApiResponse<Map<String, dynamic>>> getAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _apiService.get<Map<String, dynamic>>(
      ApiEndpoints.analytics,
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
  }

  /// Get companies
  Future<ApiResponse<List<Map<String, dynamic>>>> getCompanies() async {
    return await _apiService.get<List<Map<String, dynamic>>>(
      ApiEndpoints.companies,
      fromJson: (json) => List<Map<String, dynamic>>.from(json['companies']),
    );
  }
}

/// Riverpod providers for repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return UserRepository(apiService);
});

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return StaffRepository(apiService);
});

final tablesRepositoryProvider = Provider<TablesRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return TablesRepository(apiService);
});

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return MessagesRepository(apiService);
});

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ManagerRepository(apiService);
});

final ceoRepositoryProvider = Provider<CEORepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return CEORepository(apiService);
});
