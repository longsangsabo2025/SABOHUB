import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// Settings Service Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// User Settings State
class UserSettings {
  final bool notificationsEnabled;
  final bool autoSchedulingEnabled;
  final bool overtimeAlertsEnabled;
  final String themeMode;
  final String language;

  const UserSettings({
    required this.notificationsEnabled,
    required this.autoSchedulingEnabled,
    required this.overtimeAlertsEnabled,
    required this.themeMode,
    required this.language,
  });

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? autoSchedulingEnabled,
    bool? overtimeAlertsEnabled,
    String? themeMode,
    String? language,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      autoSchedulingEnabled: autoSchedulingEnabled ?? this.autoSchedulingEnabled,
      overtimeAlertsEnabled: overtimeAlertsEnabled ?? this.overtimeAlertsEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

/// User Settings Notifier (Riverpod 3.x compatible)
class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  late SettingsService _settingsService;

  @override
  Future<UserSettings> build() async {
    _settingsService = ref.read(settingsServiceProvider);
    final settings = await _settingsService.getAllSettings();
    return UserSettings(
      notificationsEnabled: settings['notifications'] as bool,
      autoSchedulingEnabled: settings['autoScheduling'] as bool,
      overtimeAlertsEnabled: settings['overtimeAlerts'] as bool,
      themeMode: settings['themeMode'] as String,
      language: settings['language'] as String,
    );
  }

  /// Update notifications setting
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _settingsService.setNotificationsEnabled(enabled);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(notificationsEnabled: enabled));
    }
  }

  /// Update auto scheduling setting
  Future<void> setAutoSchedulingEnabled(bool enabled) async {
    await _settingsService.setAutoSchedulingEnabled(enabled);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(autoSchedulingEnabled: enabled));
    }
  }

  /// Update overtime alerts setting
  Future<void> setOvertimeAlertsEnabled(bool enabled) async {
    await _settingsService.setOvertimeAlertsEnabled(enabled);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(overtimeAlertsEnabled: enabled));
    }
  }

  /// Update theme mode
  Future<void> setThemeMode(String mode) async {
    await _settingsService.setThemeMode(mode);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(themeMode: mode));
    }
  }

  /// Update language
  Future<void> setLanguage(String language) async {
    await _settingsService.setLanguage(language);
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(language: language));
    }
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    await _settingsService.clearAllSettings();
    ref.invalidateSelf();
  }
}

/// User Settings Provider
final userSettingsProvider = AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(() {
  return UserSettingsNotifier();
});
