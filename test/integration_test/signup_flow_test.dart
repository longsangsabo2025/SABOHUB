import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../lib/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 Signup Flow Integration Test', () {
    testWidgets('Test complete signup flow from UI',
        (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✅ App started');

      // Navigate to signup page
      final signupButton = find.text('Đăng ký');
      if (signupButton.evaluate().isEmpty) {
        print('🔍 Looking for signup link...');
        final signupLink = find.textContaining('Tạo tài khoản');
        expect(signupLink, findsOneWidget);
        await tester.tap(signupLink);
        await tester.pumpAndSettle();
      } else {
        await tester.tap(signupButton);
        await tester.pumpAndSettle();
      }

      print('✅ Navigated to signup page');

      // Fill in signup form
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final testEmail = 'test$timestamp@gmail.com';
      final testPassword = 'Test123456';
      final testName = 'Test User $timestamp';

      print('📝 Filling form with:');
      print('  - Email: $testEmail');
      print('  - Name: $testName');

      // Find and fill name field
      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      expect(nameField, findsOneWidget, reason: 'Name field not found');
      await tester.enterText(nameField, testName);
      await tester.pumpAndSettle();

      // Find and fill email field
      final emailField = find.widgetWithText(TextFormField, 'Email');
      expect(emailField, findsOneWidget, reason: 'Email field not found');
      await tester.enterText(emailField, testEmail);
      await tester.pumpAndSettle();

      // Find and fill phone field (optional)
      final phoneField = find.widgetWithText(TextFormField, 'Số điện thoại');
      if (phoneField.evaluate().isNotEmpty) {
        await tester.enterText(phoneField, '0123456789');
        await tester.pumpAndSettle();
      }

      // Find and fill password field
      final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
      expect(passwordField, findsAtLeastNWidgets(1),
          reason: 'Password field not found');
      await tester.enterText(passwordField.first, testPassword);
      await tester.pumpAndSettle();

      // Find and fill confirm password field
      final confirmPasswordField =
          find.widgetWithText(TextFormField, 'Xác nhận mật khẩu');
      if (confirmPasswordField.evaluate().isNotEmpty) {
        await tester.enterText(confirmPasswordField, testPassword);
        await tester.pumpAndSettle();
      }

      print('✅ Form filled');

      // Accept terms
      final termsCheckbox = find.byType(Checkbox);
      if (termsCheckbox.evaluate().isNotEmpty) {
        await tester.tap(termsCheckbox.first);
        await tester.pumpAndSettle();
        print('✅ Terms accepted');
      }

      // Take screenshot before signup
      await tester.pumpAndSettle();
      print('📸 Taking screenshot before signup...');

      // Find and tap signup button
      final submitButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
      expect(submitButton, findsOneWidget, reason: 'Signup button not found');

      print('🚀 Tapping signup button...');
      await tester.tap(submitButton);

      // Wait for async signup operation
      await tester.pump(); // Start the signup
      await tester.pump(const Duration(milliseconds: 100)); // Small delay

      print('⏳ Waiting for signup to complete...');

      // Wait up to 10 seconds for navigation to email verification
      bool navigatedToVerification = false;
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));

        // Check if we're on email verification page
        final verificationPage = find.textContaining('Xác thực email');
        if (verificationPage.evaluate().isNotEmpty) {
          navigatedToVerification = true;
          print('✅ Successfully navigated to email verification page!');
          break;
        }

        // Check for any error messages
        final errorSnackbar = find.byType(SnackBar);
        if (errorSnackbar.evaluate().isNotEmpty) {
          print('❌ Error occurred during signup');
          break;
        }

        print('  Waiting... ${(i + 1) * 500}ms');
      }

      // Final check
      if (navigatedToVerification) {
        print('🎉 SUCCESS: Signup flow completed successfully!');
        print('📧 Email verification page displayed');

        // Verify email is displayed on verification page
        final emailText = find.textContaining(testEmail);
        expect(emailText, findsAtLeastNWidgets(1),
            reason: 'Email not found on verification page');
      } else {
        print('❌ FAILED: Did not navigate to email verification page');
        print('Current page widgets:');
        tester.allWidgets.take(10).forEach((widget) {
          print('  - ${widget.runtimeType}');
        });

        fail('Navigation to email verification page failed');
      }

      // Take final screenshot
      await tester.pumpAndSettle();
      print('📸 Test completed');
    });

    testWidgets('Test signup with existing email', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to signup
      final signupLink = find.textContaining('Tạo tài khoản');
      if (signupLink.evaluate().isNotEmpty) {
        await tester.tap(signupLink);
        await tester.pumpAndSettle();
      }

      // Fill form with existing email
      final nameField = find.widgetWithText(TextFormField, 'Họ và tên');
      await tester.enterText(nameField, 'Test User');
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Email');
      await tester.enterText(emailField, 'ceo@sabohub.com'); // Existing email
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');
      await tester.enterText(passwordField.first, 'Test123456');
      await tester.pumpAndSettle();

      final confirmPasswordField =
          find.widgetWithText(TextFormField, 'Xác nhận mật khẩu');
      if (confirmPasswordField.evaluate().isNotEmpty) {
        await tester.enterText(confirmPasswordField, 'Test123456');
        await tester.pumpAndSettle();
      }

      // Accept terms
      final termsCheckbox = find.byType(Checkbox);
      if (termsCheckbox.evaluate().isNotEmpty) {
        await tester.tap(termsCheckbox.first);
        await tester.pumpAndSettle();
      }

      // Tap signup
      final submitButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Wait for error message
      await tester.pump(const Duration(seconds: 2));

      // Should show error
      final errorSnackbar = find.byType(SnackBar);
      expect(errorSnackbar, findsOneWidget,
          reason: 'Error message should be displayed for existing email');

      print('✅ Correctly showed error for existing email');
    });

    testWidgets('Test signup validation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to signup
      final signupLink = find.textContaining('Tạo tài khoản');
      if (signupLink.evaluate().isNotEmpty) {
        await tester.tap(signupLink);
        await tester.pumpAndSettle();
      }

      // Try to submit without filling form
      final submitButton = find.widgetWithText(ElevatedButton, 'Đăng ký');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      final errorText = find.textContaining('Vui lòng');
      expect(errorText, findsAtLeastNWidgets(1),
          reason: 'Validation errors should be displayed');

      print('✅ Form validation working correctly');
    });
  });
}
