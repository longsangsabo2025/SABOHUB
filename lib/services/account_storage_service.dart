import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;

/// Service for storing and managing saved accounts
/// Allows users to save multiple accounts and switch between them with 1 click
class AccountStorageService {
  static const String _accountsKey = '@saved_accounts';

  /// Save current user account
  static Future<void> saveAccount(app_user.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);

      List<SavedAccount> accounts = [];
      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        accounts =
            accountsList.map((json) => SavedAccount.fromJson(json)).toList();
      }

      // Check if account already exists (use email or username as identifier)
      final identifier = user.email ?? user.id; // Use email if available, else use ID
      final existingIndex =
          accounts.indexWhere((acc) => acc.email == identifier);

      if (existingIndex >= 0) {
        // Update existing account
        accounts[existingIndex] = SavedAccount(
          email: identifier,
          name: user.name ?? 'Unknown',
          role: user.role.name,
          lastUsed: DateTime.now(),
        );
      } else {
        // Add new account
        accounts.add(SavedAccount(
          email: identifier,
          name: user.name ?? 'Unknown',
          role: user.role.name,
          lastUsed: DateTime.now(),
        ));
      }

      // Save to SharedPreferences
      final updatedJson =
          json.encode(accounts.map((acc) => acc.toJson()).toList());
      await prefs.setString(_accountsKey, updatedJson);
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Get all saved accounts
  static Future<List<SavedAccount>> getSavedAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);

      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        return accountsList.map((json) => SavedAccount.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Remove an account from saved list
  static Future<void> removeAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString(_accountsKey);

      if (accountsJson != null) {
        final List<dynamic> accountsList = json.decode(accountsJson);
        List<SavedAccount> accounts =
            accountsList.map((json) => SavedAccount.fromJson(json)).toList();

        accounts.removeWhere((acc) => acc.email == email);

        final updatedJson =
            json.encode(accounts.map((acc) => acc.toJson()).toList());
        await prefs.setString(_accountsKey, updatedJson);
      }
    } catch (e) {
      // Ignore storage errors
    }
  }

  /// Clear all saved accounts
  static Future<void> clearAllAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accountsKey);
    } catch (e) {
      // Ignore storage errors
    }
  }
}

/// Model for saved account
class SavedAccount {
  final String email;
  final String name;
  final String role;
  DateTime lastUsed;

  SavedAccount({
    required this.email,
    required this.name,
    required this.role,
    required this.lastUsed,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
        'role': role,
        'lastUsed': lastUsed.toIso8601String(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) => SavedAccount(
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        lastUsed: DateTime.parse(json['lastUsed'] as String),
      );
}
