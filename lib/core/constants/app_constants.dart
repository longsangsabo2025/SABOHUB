import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// App-wide constants for SABOHUB Flutter application
class AppConstants {
  // App Info
  static const String appName = 'SABOHUB';
  static const String appDescription = 'Quản lý quán bida chuyên nghiệp';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.success;
  static const Color accentColor = AppColors.warning; // Orange
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = AppColors.warning;
  static const Color successColor = AppColors.success;
  static const Color backgroundColor = AppColors.grey100;

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
