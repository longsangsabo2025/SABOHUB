import 'package:flutter/material.dart';

/// App-wide constants for SABOHUB Flutter application
class AppConstants {
  // App Info
  static const String appName = 'SABOHUB';
  static const String appDescription = 'Quản lý quán bida chuyên nghiệp';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32); // Green
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  // API Configuration
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
  static const String apiBaseUrl = 'https://your-api.com';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String companyKey = 'selected_company';

  // Demo Users (matching React Native version)
  static const Map<String, Map<String, dynamic>> demoUsers = {
    'ceo@sabohub.com': {
      'id': '1',
      'name': 'Nguyễn Văn CEO',
      'email': 'ceo@sabohub.com',
      'role': 'CEO',
      'phone': '0901234567',
      'password': 'demo123',
    },
    'manager@sabohub.com': {
      'id': '2',
      'name': 'Trần Thị Quản Lý',
      'email': 'manager@sabohub.com',
      'role': 'MANAGER',
      'phone': '0902234567',
      'password': 'demo123',
    },
    'shift@sabohub.com': {
      'id': '3',
      'name': 'Lê Văn Trưởng Ca',
      'email': 'shift@sabohub.com',
      'role': 'SHIFT_LEADER',
      'phone': '0903234567',
      'password': 'demo123',
    },
    'staff@sabohub.com': {
      'id': '4',
      'name': 'Phạm Thị Nhân Viên',
      'email': 'staff@sabohub.com',
      'role': 'STAFF',
      'phone': '0904234567',
      'password': 'demo123',
    },
  };

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> allowedDocTypes = ['pdf', 'doc', 'docx', 'txt'];
}
