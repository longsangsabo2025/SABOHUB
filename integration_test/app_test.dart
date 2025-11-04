import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_sabohub/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SABOHUB E2E Tests', () {
    testWidgets('Complete Authentication Flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test 1: App loads with login page
      expect(find.text('Đăng nhập'), findsOneWidget);
      expect(find.text('SABOHUB'), findsWidgets);

      // Test 2: Quick login with CEO account
      final ceoButton = find.text('CEO - Nhà hàng Sabo');
      await tester.tap(ceoButton);
      await tester.pumpAndSettle();

      // Verify email and password are filled
      expect(find.text('ceo1@sabohub.com'), findsOneWidget);

      // Test 3: Click login button
      final loginButton = find.text('Đăng nhập').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test 4: Should navigate to CEO dashboard
      // This might take time for Supabase authentication
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify we're in the main app (look for navigation items or dashboard)
      expect(find.text('Tổng quan'), findsAny);
    });

    testWidgets('Error Handling Test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test invalid login
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'invalid@email.com');
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle();

      final loginButton = find.text('Đăng nhập').last;
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should show error message or stay on login page
      expect(find.text('Đăng nhập'), findsOneWidget);
    });
  });
}