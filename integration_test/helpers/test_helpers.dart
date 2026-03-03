/// Test helper utilities for SABOHUB integration tests.
///
/// Provides common actions like login, navigation, and widget finding
/// that are reused across multiple test files.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_sabohub/main.dart' as app;

import 'test_config.dart';

/// Initialize the integration test environment and launch the app.
Future<void> initializeApp(WidgetTester tester) async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app.main();
  // Wait for app to fully load (Supabase init + first frame)
  await tester.pumpAndSettle(TestTimeouts.navigation);
}

/// Perform Employee login: fills company, username, password, taps login.
///
/// [account] should be a map with keys: company, username, password
/// Returns true if login button was found and tapped.
Future<bool> loginAsEmployee(
  WidgetTester tester, {
  required Map<String, String> account,
}) async {
  // Ensure we're on the employee login page
  final companyField = find.byKey(TestKeys.employeeCompanyField);
  final usernameField = find.byKey(TestKeys.employeeUsernameField);
  final passwordField = find.byKey(TestKeys.employeePasswordField);
  final loginButton = find.byKey(TestKeys.employeeLoginButton);

  // Verify all fields exist
  expect(companyField, findsOneWidget, reason: 'Company field not found');
  expect(usernameField, findsOneWidget, reason: 'Username field not found');
  expect(passwordField, findsOneWidget, reason: 'Password field not found');
  expect(loginButton, findsOneWidget, reason: 'Login button not found');

  // Fill in company name
  await tester.tap(companyField);
  await tester.pump(TestTimeouts.pumpDelay);
  await tester.enterText(companyField, account['company']!);
  await tester.pump(TestTimeouts.pumpDelay);

  // Fill in username
  await tester.tap(usernameField);
  await tester.pump(TestTimeouts.pumpDelay);
  await tester.enterText(usernameField, account['username']!);
  await tester.pump(TestTimeouts.pumpDelay);

  // Fill in password
  await tester.tap(passwordField);
  await tester.pump(TestTimeouts.pumpDelay);
  await tester.enterText(passwordField, account['password']!);
  await tester.pump(TestTimeouts.pumpDelay);

  // Tap login
  await tester.tap(loginButton);
  
  // Wait for RPC response + navigation
  await tester.pumpAndSettle(TestTimeouts.loginWait);

  return true;
}

/// Switch to CEO login mode by tapping the CEO toggle button.
Future<void> switchToCEOLogin(WidgetTester tester) async {
  final ceoToggle = find.byKey(TestKeys.ceoToggleButton);
  expect(ceoToggle, findsOneWidget, reason: 'CEO toggle button not found');
  await tester.tap(ceoToggle);
  await tester.pumpAndSettle();
}

/// Perform CEO login: switches to CEO mode, fills email + password.
Future<bool> loginAsCEO(
  WidgetTester tester, {
  required Map<String, String> account,
}) async {
  // Switch to CEO mode
  await switchToCEOLogin(tester);

  final emailField = find.byKey(TestKeys.ceoEmailField);
  final passwordField = find.byKey(TestKeys.ceoPasswordField);
  final loginButton = find.byKey(TestKeys.ceoLoginButton);

  expect(emailField, findsOneWidget, reason: 'CEO email field not found');
  expect(passwordField, findsOneWidget, reason: 'CEO password field not found');
  expect(loginButton, findsOneWidget, reason: 'CEO login button not found');

  // Fill email
  await tester.tap(emailField);
  await tester.pump(TestTimeouts.pumpDelay);
  await tester.enterText(emailField, account['email']!);
  await tester.pump(TestTimeouts.pumpDelay);

  // Fill password
  await tester.tap(passwordField);
  await tester.pump(TestTimeouts.pumpDelay);
  await tester.enterText(passwordField, account['password']!);
  await tester.pump(TestTimeouts.pumpDelay);

  // Tap login
  await tester.tap(loginButton);
  await tester.pumpAndSettle(TestTimeouts.loginWait);

  return true;
}

/// Switch back from CEO to Employee login mode.
Future<void> switchToEmployeeLogin(WidgetTester tester) async {
  final backButton = find.byKey(TestKeys.employeeBackButton);
  expect(backButton, findsOneWidget, reason: 'Employee back button not found');
  await tester.tap(backButton);
  await tester.pumpAndSettle();
}

/// Check if a SnackBar with given text is shown.
bool isSnackbarShowing(WidgetTester tester, String textContains) {
  final snackbar = find.byType(SnackBar);
  if (snackbar.evaluate().isEmpty) return false;
  return find.descendant(
    of: snackbar,
    matching: find.textContaining(textContains),
  ).evaluate().isNotEmpty;
}

/// Wait for navigation and check that we're no longer on the login page.
Future<bool> isLoggedIn(WidgetTester tester) async {
  await tester.pumpAndSettle(TestTimeouts.navigation);
  // If we can't find the login button, we've navigated away = logged in
  final loginButton = find.byKey(TestKeys.employeeLoginButton);
  return loginButton.evaluate().isEmpty;
}

/// Take a screenshot with a descriptive name (for CI).
Future<void> takeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot(name);
}
