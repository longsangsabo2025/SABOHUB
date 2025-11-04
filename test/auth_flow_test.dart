import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sabohub/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication Flow Tests', () {
    testWidgets('App loads login page initially', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Verify that login page is shown
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
    });

    testWidgets('Quick login buttons work', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Find and tap CEO quick login
      final ceoLoginButton = find.text('CEO - Nhà hàng Sabo');
      expect(ceoLoginButton, findsOneWidget);

      await tester.tap(ceoLoginButton);
      await tester.pumpAndSettle();

      // Verify email and password are filled
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      expect(tester.widget<TextFormField>(emailField).controller?.text,
          'ceo1@sabohub.com');
      expect(
          tester.widget<TextFormField>(passwordField).controller?.text, 'demo');
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Try to login without filling fields
      final loginButton = find.text('Đăng nhập');
      await tester.tap(loginButton);
      await tester.pump();

      // Verify validation errors appear
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works',
        (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Find visibility toggle
      final visibilityToggle = find.byIcon(Icons.visibility);

      expect(visibilityToggle, findsOneWidget);

      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Verify password visibility icon changed
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    testWidgets('Signup link navigates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Find and tap signup link
      final signupLink = find.text('Đăng ký');
      expect(signupLink, findsOneWidget);

      await tester.tap(signupLink);
      await tester.pumpAndSettle();

      // Verify navigation to signup page
      expect(find.text('Tạo tài khoản'), findsOneWidget);
    });

    testWidgets('Forgot password link works', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: SaboHubApp()));
      await tester.pumpAndSettle();

      // Find and tap forgot password link
      final forgotPasswordLink = find.text('Quên mật khẩu?');
      expect(forgotPasswordLink, findsOneWidget);

      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Verify navigation to forgot password page
      expect(find.text('Khôi phục mật khẩu'), findsOneWidget);
    });
  });
}
