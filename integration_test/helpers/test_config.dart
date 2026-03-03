/// Test configuration & constants for SABOHUB integration tests.
///
/// Contains test accounts, timeouts, and widget keys used across all tests.
library;

import 'package:flutter/material.dart';

// ============================================================================
// WIDGET KEYS — phải match với Key(...) trong dual_login_page.dart
// ============================================================================
class TestKeys {
  // Employee Login Form
  static const employeeCompanyField = Key('employee_company_field');
  static const employeeUsernameField = Key('employee_username_field');
  static const employeePasswordField = Key('employee_password_field');
  static const employeeLoginButton = Key('employee_login_button');

  // CEO Login Form
  static const ceoToggleButton = Key('ceo_toggle_button');
  static const ceoEmailField = Key('ceo_email_field');
  static const ceoPasswordField = Key('ceo_password_field');
  static const ceoLoginButton = Key('ceo_login_button');
  static const employeeBackButton = Key('employee_back_button');
}

// ============================================================================
// TEST ACCOUNTS — dùng trong integration test
// Các account này PHẢI tồn tại trong DB production.
// ============================================================================
class TestAccounts {
  /// Manager account — company: Odori, username: manager1
  static const managerAccount = {
    'company': 'Odori',
    'username': 'manager1',
    'password': '123456',
    'expectedRole': 'manager',
  };

  /// Staff account — company: Odori, username: staff1
  static const staffAccount = {
    'company': 'Odori',
    'username': 'staff1',
    'password': '123456',
    'expectedRole': 'staff',
  };

  /// Driver account — company: Odori, username: driver1
  static const driverAccount = {
    'company': 'Odori',
    'username': 'driver1',
    'password': '123456',
    'expectedRole': 'driver',
  };

  /// Warehouse account
  static const warehouseAccount = {
    'company': 'Odori',
    'username': 'kho',
    'password': '123456',
    'expectedRole': 'warehouse',
  };

  /// CEO account — uses email login
  static const ceoAccount = {
    'email': 'ceo1@sabohub.com',
    'password': '123456',
    'expectedRole': 'ceo',
  };

  /// Invalid credentials — for error testing
  static const invalidAccount = {
    'company': 'CompanyDoesNotExist999',
    'username': 'nonexistent_user',
    'password': 'wrong_password',
  };
}

// ============================================================================
// TIMEOUTS
// ============================================================================
class TestTimeouts {
  /// Wait for Supabase RPC call to return
  static const loginWait = Duration(seconds: 10);

  /// Wait for page transition / navigation
  static const navigation = Duration(seconds: 5);

  /// Wait for snackbar or toast to appear
  static const snackbar = Duration(seconds: 3);

  /// Quick pump for UI updates
  static const pumpDelay = Duration(milliseconds: 500);
}

// ============================================================================
// EXPECTED TEXT — Vietnamese text that should appear in the app
// ============================================================================
class TestText {
  // Login page
  static const appTitle = 'SABOHUB';
  static const employeeLoginHeading = 'Đăng nhập Nhân viên';
  static const ceoLoginHeading = 'Đăng nhập CEO';
  static const loginButton = 'Đăng nhập';
  static const ceoLoginButton = 'Đăng nhập CEO';
  static const companyLabel = 'Tên công ty';
  static const usernameLabel = 'Tên đăng nhập';
  static const passwordLabel = 'Mật khẩu';
  static const emailLabel = 'Email';
  static const rememberMe = 'Ghi nhớ đăng nhập';

  // Validation errors
  static const companyRequired = 'Vui lòng nhập tên công ty';
  static const usernameRequired = 'Vui lòng nhập tên đăng nhập';
  static const passwordRequired = 'Vui lòng nhập mật khẩu';
  static const emailRequired = 'Vui lòng nhập email';
  static const emailInvalid = 'Email không hợp lệ';

  // Success
  static const loginSuccessPrefix = 'Đăng nhập thành công!';
}
