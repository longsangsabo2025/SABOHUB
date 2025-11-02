# 🔧 REFACTORING GUIDE - SABOHUB FLUTTER

## 📊 Current Status

- ✅ Created folder structure
- ✅ Extracted all 13 domain models to `lib/models/`
- ⏳ Next: Extract providers and pages

## 📁 Folder Structure Created

```
lib/
├── models/ ✅
│   ├── models.dart (exports all)
│   ├── business_type.dart
│   ├── company.dart
│   ├── employee.dart
│   ├── table.dart
│   ├── menu_item.dart
│   ├── order.dart
│   ├── payment.dart
│   ├── session.dart
│   ├── receipt.dart
│   ├── inventory.dart
│   ├── stock_movement.dart
│   ├── task.dart
│   └── attendance.dart
├── providers/ (empty - needs AuthProvider)
├── pages/ (empty - needs all pages)
│   ├── auth/
│   ├── home/
│   ├── tables/
│   ├── menu/
│   ├── orders/
│   ├── sessions/
│   ├── employees/
│   ├── inventory/
│   ├── tasks/
│   └── reports/
└── widgets/ (empty - needs reusable widgets)
```

## ✅ Step 1: Models (COMPLETED)

All models extracted to separate files with proper imports.

## ⏭️ Step 2: Extract Auth Provider (NEXT)

**Location in main.dart:** Lines 1047-2600 (approx)
**Target file:** `lib/providers/auth_provider.dart`

**Components to extract:**

1. `AuthState` class (lines 1047-1423)
2. `AuthNotifier` class (lines 1424-2600)
3. `authProvider` instance
4. Demo data generators:
   - `_generateDemoCompanies()`
   - `_generateDemoEmployees()`
   - `_generateDemoTables()`
   - `_generateDemoMenuItems()`
   - `_generateDemoOrders()`
   - `_generateDemoSessions()`
   - `_generateDemoPayments()`
   - `_generateDemoInventory()`
   - `_generateDemoTasks()`
   - `_generateDemoAttendances()`
   - `_generateDemoShifts()`
   - `_generateDemoPerformances()`

**Import needed:**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
```

## 📋 Step 3: Extract Pages

**29 Pages to extract from main.dart:**

### Auth Pages (2)

- LoginPage → `lib/pages/auth/login_page.dart`
- CompanySelectionPage → `lib/pages/auth/company_selection_page.dart`

### Home (1)

- HomePage → `lib/pages/home/home_page.dart`

### Tables (1)

- TableListPage → `lib/pages/tables/table_list_page.dart`

### Menu (1)

- MenuListPage → `lib/pages/menu/menu_list_page.dart`

### Orders (3)

- OrderListPage → `lib/pages/orders/order_list_page.dart`
- PaymentPage → `lib/pages/orders/payment_page.dart`
- ReceiptPage → `lib/pages/orders/receipt_page.dart`

### Sessions (1)

- SessionListPage → `lib/pages/sessions/session_list_page.dart`

### Employees (6)

- EmployeeListPage → `lib/pages/employees/employee_list_page.dart`
- EmployeeFormPage → `lib/pages/employees/employee_form_page.dart`
- EmployeeDetailPage → `lib/pages/employees/employee_detail_page.dart`
- EmployeeAttendancePage → `lib/pages/employees/employee_attendance_page.dart`
- EmployeeSchedulePage → `lib/pages/employees/employee_schedule_page.dart`
- EmployeePerformancePage → `lib/pages/employees/employee_performance_page.dart`

### Inventory (3)

- InventoryListPage → `lib/pages/inventory/inventory_list_page.dart`
- InventoryFormPage → `lib/pages/inventory/inventory_form_page.dart`
- StockMovementPage → `lib/pages/inventory/stock_movement_page.dart`

### Tasks (2)

- TaskListPage → `lib/pages/tasks/task_list_page.dart`
- TaskFormPage → `lib/pages/tasks/task_form_page.dart`

### Reports (1) - NEW

- ReportsPage → `lib/pages/reports/reports_page.dart`

## 🧩 Step 4: Extract Reusable Widgets

**Common widgets used across pages:**

- StatCard → `lib/widgets/stat_card.dart`
- ActionCard → `lib/widgets/action_card.dart`
- MetricCard → `lib/widgets/metric_card.dart`

## 📝 Step 5: Create New main.dart

**Final main.dart should be ~50 lines:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pages/auth/login_page.dart';

void main() {
  runApp(const ProviderScope(child: SaboHubApp()));
}

class SaboHubApp extends StatelessWidget {
  const SaboHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaboHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const LoginPage(),
    );
  }
}
```

## 🔍 How to Extract a Page

**Template for each page file:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';

class PageNameHere extends ConsumerStatefulWidget {
  const PageNameHere({super.key});

  @override
  ConsumerState<PageNameHere> createState() => _PageNameHereState();
}

class _PageNameHereState extends ConsumerState<PageNameHere> {
  // ... paste page code here ...
}
```

## 🎯 Benefits After Refactoring

- ✅ Each file ~100-300 lines instead of 9696
- ✅ Faster hot reload (only changed files)
- ✅ Better IDE performance
- ✅ Easier team collaboration
- ✅ Cleaner git diffs
- ✅ Easier to test individual components
- ✅ Professional code structure

## 📏 Estimated Work

- **Models:** ✅ DONE (30 minutes)
- **Auth Provider:** ⏰ 20 minutes
- **Pages (29):** ⏰ 2-3 hours (if automated, ~30 minutes)
- **Widgets:** ⏰ 15 minutes
- **New main.dart:** ⏰ 5 minutes
- **Testing:** ⏰ 30 minutes

**Total:** ~4 hours manual OR ~2 hours with AI assistance

## 🚀 Current File: main.dart

- **Total lines:** 9696
- **Models:** Lines 1-1046 (✅ EXTRACTED)
- **AuthState:** Lines 1047-1423 (⏳ TO EXTRACT)
- **AuthNotifier:** Lines 1424-2600 (⏳ TO EXTRACT)
- **App Widget:** Lines 2601-2650 (⏳ TO EXTRACT)
- **Pages:** Lines 2651-9696 (⏳ TO EXTRACT)

## 📌 Next Immediate Actions

1. Extract AuthProvider to `lib/providers/auth_provider.dart`
2. Create example with LoginPage extraction
3. Create script/tool to automate remaining page extractions
4. Update main.dart with imports only
5. Run `flutter analyze` to verify
6. Run `flutter run` to test

## 💡 Pro Tips

- Use VSCode "Go to Symbol" (Ctrl+Shift+O) to navigate large files
- Search for `class.*Page extends` to find all pages
- Each page navigation needs to import the new path
- Keep demo data generators in AuthNotifier
- Test after extracting each major component

---

**Status:** Models ✅ | Provider ⏳ | Pages ⏳ | Complete 🎯
