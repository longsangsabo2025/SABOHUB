import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cache_provider.dart';

/// Theme provider with persistence - AsyncNotifierProvider version
/// Stores theme preference in SharedPreferences for persistence across app restarts
final themeProvider =
    AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    // Get SharedPreferences instance
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    
    // Load saved theme mode or default to light
    final themeModeIndex = prefs.getInt(_themeKey) ?? ThemeMode.light.index;
    return ThemeMode.values[themeModeIndex];
  }

  /// Set and persist new theme mode
  Future<void> setTheme(ThemeMode themeMode) async {
    state = const AsyncValue.loading();
    
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setInt(_themeKey, themeMode.index);
      
      state = AsyncValue.data(themeMode);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
