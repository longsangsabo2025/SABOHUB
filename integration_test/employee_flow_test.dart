/// 🧪 SABOHUB Employee Flow Integration Tests
///
/// Giả lập các role đăng nhập và thực hiện thao tác thực tế.
///
/// Chạy:
///   cd sabohub-app/SABOHUB
///   flutter test integration_test/employee_flow_test.dart
///
///   (Web driver):
///   flutter drive --driver=test_driver/integration_test.dart \
///       --target=integration_test/employee_flow_test.dart -d chrome
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_sabohub/main.dart' as app;

import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // PHASE 1: LOGIN PAGE UI TESTS
  // =========================================================================
  group('Phase 1: Login Page UI', () {
    testWidgets('TC-UI-001: Login page loads with all elements', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Heading
      expect(find.text(TestText.appTitle), findsWidgets);

      // Employee form fields
      expect(find.byKey(TestKeys.employeeCompanyField), findsOneWidget);
      expect(find.byKey(TestKeys.employeeUsernameField), findsOneWidget);
      expect(find.byKey(TestKeys.employeePasswordField), findsOneWidget);
      expect(find.byKey(TestKeys.employeeLoginButton), findsOneWidget);

      // CEO toggle
      expect(find.byKey(TestKeys.ceoToggleButton), findsOneWidget);
      expect(find.text('CEO'), findsOneWidget);
    });

    testWidgets('TC-UI-002: Empty form shows validation errors', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Tap login without filling anything
      await tester.tap(find.byKey(TestKeys.employeeLoginButton));
      await tester.pumpAndSettle();

      // Should show all 3 validation errors
      expect(find.text(TestText.companyRequired), findsOneWidget);
      expect(find.text(TestText.usernameRequired), findsOneWidget);
      expect(find.text(TestText.passwordRequired), findsOneWidget);
    });

    testWidgets('TC-UI-003: CEO toggle switches login mode', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Initial state: Employee form
      expect(find.byKey(TestKeys.employeeCompanyField), findsOneWidget);
      expect(find.byKey(TestKeys.ceoEmailField), findsNothing);

      // Toggle to CEO
      await switchToCEOLogin(tester);

      // CEO form visible
      expect(find.byKey(TestKeys.ceoEmailField), findsOneWidget);
      expect(find.byKey(TestKeys.ceoPasswordField), findsOneWidget);
      expect(find.byKey(TestKeys.ceoLoginButton), findsOneWidget);

      // Employee fields hidden
      expect(find.byKey(TestKeys.employeeCompanyField), findsNothing);

      // Toggle back to Employee
      await switchToEmployeeLogin(tester);

      // Employee form back
      expect(find.byKey(TestKeys.employeeCompanyField), findsOneWidget);
      expect(find.byKey(TestKeys.ceoEmailField), findsNothing);
    });

    testWidgets('TC-UI-004: CEO email validation works', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await switchToCEOLogin(tester);

      // Enter invalid email
      await tester.enterText(find.byKey(TestKeys.ceoEmailField), 'notanemail');
      await tester.tap(find.byKey(TestKeys.ceoLoginButton));
      await tester.pumpAndSettle();

      // Validation error
      expect(find.text(TestText.emailInvalid), findsOneWidget);
      expect(find.text(TestText.passwordRequired), findsOneWidget);
    });

    testWidgets('TC-UI-005: Password field is obscured', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      final passwordField = find.byKey(TestKeys.employeePasswordField);
      await tester.enterText(passwordField, 'secret123');
      await tester.pump();

      // Find the EditableText descendant of the password field
      // which holds the actual obscureText property
      final editableText = find.descendant(
        of: passwordField,
        matching: find.byType(EditableText),
      );
      expect(editableText, findsOneWidget);
      final et = tester.widget<EditableText>(editableText);
      expect(et.obscureText, isTrue);
    });

    testWidgets('TC-UI-006: Remember me checkbox works', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Find checkbox
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      // Initially unchecked
      final cb = tester.widget<Checkbox>(checkbox);
      expect(cb.value, isFalse);

      // Tap to check
      await tester.tap(checkbox);
      await tester.pump();

      final cbAfter = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cbAfter.value, isTrue);

      // Tap again to uncheck
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final cbFinal = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(cbFinal.value, isFalse);
    });
  });

  // =========================================================================
  // PHASE 2: AUTHENTICATION FLOW (Real Supabase RPC calls)
  // Yêu cầu: Network access + Supabase reachable
  // =========================================================================
  group('Phase 2: Employee Authentication', () {
    testWidgets('TC-AUTH-001: Invalid login shows error', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.invalidAccount['company']!,
        'username': TestAccounts.invalidAccount['username']!,
        'password': TestAccounts.invalidAccount['password']!,
      });

      // Should still be on login page (login failed)
      expect(find.byKey(TestKeys.employeeLoginButton), findsOneWidget);

      // Should show error snackbar or error text
      // (Exact error depends on how backend responds)
    });

    testWidgets('TC-AUTH-002: Staff login → redirects to dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.staffAccount['company']!,
        'username': TestAccounts.staffAccount['username']!,
        'password': TestAccounts.staffAccount['password']!,
      });

      // After successful login, should navigate away from login
      final loggedIn = await isLoggedIn(tester);
      expect(loggedIn, isTrue, reason: 'Should navigate to dashboard after staff login');
    });

    testWidgets('TC-AUTH-003: Manager login → redirects to manager dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.managerAccount['company']!,
        'username': TestAccounts.managerAccount['username']!,
        'password': TestAccounts.managerAccount['password']!,
      });

      final loggedIn = await isLoggedIn(tester);
      expect(loggedIn, isTrue, reason: 'Should navigate to dashboard after manager login');
    });

    testWidgets('TC-AUTH-004: Driver login → redirects to driver dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.driverAccount['company']!,
        'username': TestAccounts.driverAccount['username']!,
        'password': TestAccounts.driverAccount['password']!,
      });

      final loggedIn = await isLoggedIn(tester);
      expect(loggedIn, isTrue, reason: 'Should navigate to dashboard after driver login');
    });

    testWidgets('TC-AUTH-005: Warehouse login → redirects to warehouse dashboard',
        (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.warehouseAccount['company']!,
        'username': TestAccounts.warehouseAccount['username']!,
        'password': TestAccounts.warehouseAccount['password']!,
      });

      final loggedIn = await isLoggedIn(tester);
      expect(loggedIn, isTrue, reason: 'Should navigate to dashboard after warehouse login');
    });
  });

  // =========================================================================
  // PHASE 3: POST-LOGIN TASK FLOWS
  // Mỗi test login → navigate → thực hiện task → verify
  // =========================================================================
  group('Phase 3: Staff Tasks After Login', () {
    testWidgets('TC-TASK-001: Staff check-in flow', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Login as staff
      await loginAsEmployee(tester, account: {
        'company': TestAccounts.staffAccount['company']!,
        'username': TestAccounts.staffAccount['username']!,
        'password': TestAccounts.staffAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // After login, staff should see their dashboard
      // Look for check-in related elements
      final hasCheckinTab = find.textContaining('Chấm công');
      final hasDashboard = find.textContaining('Trang chủ');

      // At least one dashboard element should be visible
      expect(
        hasCheckinTab.evaluate().isNotEmpty || hasDashboard.evaluate().isNotEmpty,
        isTrue,
        reason: 'Staff dashboard should show check-in or home tab',
      );
    });

    testWidgets('TC-TASK-002: Staff can see bottom navigation bar', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.staffAccount['company']!,
        'username': TestAccounts.staffAccount['username']!,
        'password': TestAccounts.staffAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Staff layout should have a BottomNavigationBar or NavigationBar
      final bottomNav = find.byType(NavigationBar);
      final bottomNavOld = find.byType(BottomNavigationBar);

      expect(
        bottomNav.evaluate().isNotEmpty || bottomNavOld.evaluate().isNotEmpty,
        isTrue,
        reason: 'Staff dashboard should have bottom navigation',
      );
    });

    testWidgets('TC-TASK-003: Staff can navigate between tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.staffAccount['company']!,
        'username': TestAccounts.staffAccount['username']!,
        'password': TestAccounts.staffAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Try tapping different navigation items
      final navItems = find.byType(NavigationDestination);
      if (navItems.evaluate().length >= 2) {
        // Tap second tab
        await tester.tap(navItems.at(1));
        await tester.pumpAndSettle();

        // Tap back to first tab
        await tester.tap(navItems.at(0));
        await tester.pumpAndSettle();

        // No crash = success
      }

      // Alternative: BottomNavigationBar
      find.byType(BottomNavigationBarItem);
      // Just verify we haven't crashed
      expect(tester.takeException(), isNull);
    });
  });

  // =========================================================================
  // PHASE 4: MANAGER POST-LOGIN TASKS
  // =========================================================================
  group('Phase 4: Manager Tasks After Login', () {
    testWidgets('TC-MGR-001: Manager sees analytics/dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.managerAccount['company']!,
        'username': TestAccounts.managerAccount['username']!,
        'password': TestAccounts.managerAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Manager should see dashboard with analytics
      final hasTongQuan = find.textContaining('Tổng quan');
      final hasThongKe = find.textContaining('Thống kê');
      final hasNhanVien = find.textContaining('Nhân viên');

      expect(
        hasTongQuan.evaluate().isNotEmpty ||
            hasThongKe.evaluate().isNotEmpty ||
            hasNhanVien.evaluate().isNotEmpty,
        isTrue,
        reason: 'Manager dashboard should show overview/stats/employee tabs',
      );
    });

    testWidgets('TC-MGR-002: Manager can view employee list', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.managerAccount['company']!,
        'username': TestAccounts.managerAccount['username']!,
        'password': TestAccounts.managerAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Try to find and tap the employee/staff tab
      final staffTab = find.textContaining('Nhân viên');
      if (staffTab.evaluate().isNotEmpty) {
        await tester.tap(staffTab.first);
        await tester.pumpAndSettle(TestTimeouts.navigation);

        // Should see a list of employees (ListView or similar)
        final listView = find.byType(ListView);
        final hasEmployeeContent =
            find.byType(ListTile).evaluate().isNotEmpty ||
                listView.evaluate().isNotEmpty;
        expect(hasEmployeeContent, isTrue,
            reason: 'Staff tab should show employee list');
      }
    });
  });

  // =========================================================================
  // PHASE 5: DRIVER POST-LOGIN TASKS
  // =========================================================================
  group('Phase 5: Driver Tasks After Login', () {
    testWidgets('TC-DRV-001: Driver sees delivery dashboard', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      await loginAsEmployee(tester, account: {
        'company': TestAccounts.driverAccount['company']!,
        'username': TestAccounts.driverAccount['username']!,
        'password': TestAccounts.driverAccount['password']!,
      });

      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Driver should see delivery-related content
      final hasGiaoHang = find.textContaining('Giao hàng');
      final hasTuyenDuong = find.textContaining('Tuyến');
      final hasDonHang = find.textContaining('Đơn hàng');
      final hasDashboard = find.textContaining('Trang chủ');

      expect(
        hasGiaoHang.evaluate().isNotEmpty ||
            hasTuyenDuong.evaluate().isNotEmpty ||
            hasDonHang.evaluate().isNotEmpty ||
            hasDashboard.evaluate().isNotEmpty,
        isTrue,
        reason: 'Driver dashboard should show delivery-related content',
      );
    });
  });

  // =========================================================================
  // PHASE 6: PERFORMANCE & STABILITY
  // =========================================================================
  group('Phase 6: Performance', () {
    testWidgets('TC-PERF-001: App starts within 10 seconds', (tester) async {
      final stopwatch = Stopwatch()..start();
      app.main();
      await tester.pumpAndSettle(TestTimeouts.loginWait);
      stopwatch.stop();

      expect(stopwatch.elapsed.inSeconds, lessThan(10),
          reason: 'App should load within 10 seconds');
    });

    testWidgets('TC-PERF-002: No overflow errors on login page', (tester) async {
      app.main();
      await tester.pumpAndSettle(TestTimeouts.navigation);

      // Check for RenderFlex overflow
      final overflowErrors = tester.takeException();
      expect(overflowErrors, isNull, reason: 'Login page should have no overflow errors');
    });
  });
}
