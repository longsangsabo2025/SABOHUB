import 'package:shared_preferences/shared_preferences.dart';

/// Settings Service
/// Manages user preferences and settings persistence
class SettingsService {
  static const String _keyNotifications = 'settings_notifications';
  static const String _keyAutoScheduling = 'settings_auto_scheduling';
  static const String _keyOvertimeAlerts = 'settings_overtime_alerts';
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyLanguage = 'settings_language';

  /// Get notifications enabled setting
  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotifications) ?? true; // Default: enabled
  }

  /// Set notifications enabled setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }

  /// Get auto scheduling enabled setting
  Future<bool> getAutoSchedulingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoScheduling) ?? false; // Default: disabled
  }

  /// Set auto scheduling enabled setting
  Future<void> setAutoSchedulingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoScheduling, enabled);
  }

  /// Get overtime alerts enabled setting
  Future<bool> getOvertimeAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOvertimeAlerts) ?? true; // Default: enabled
  }

  /// Set overtime alerts enabled setting
  Future<void> setOvertimeAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOvertimeAlerts, enabled);
  }

  /// Get theme mode (light/dark/system)
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'light'; // Default: light
  }

  /// Set theme mode
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  /// Get language (vi/en)
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'vi'; // Default: Vietnamese
  }

  /// Set language
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  /// Clear all settings (logout/reset)
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyNotifications);
    await prefs.remove(_keyAutoScheduling);
    await prefs.remove(_keyOvertimeAlerts);
    await prefs.remove(_keyThemeMode);
    await prefs.remove(_keyLanguage);
  }

  /// Get all settings as a map
  Future<Map<String, dynamic>> getAllSettings() async {
    return {
      'notifications': await getNotificationsEnabled(),
      'autoScheduling': await getAutoSchedulingEnabled(),
      'overtimeAlerts': await getOvertimeAlertsEnabled(),
      'themeMode': await getThemeMode(),
      'language': await getLanguage(),
    };
  }
}
