# 🔧 KẾ HOẠCH HÀNH ĐỘNG SỬA LỖI

**Dự án:** Flutter SABOHUB  
**Tạo ngày:** 2 Tháng 11, 2025  
**Tổng số issues:** 86  
**Ước tính thời gian:** 8-12 giờ

---

## 🎯 PRIORITY 1 - CRITICAL (Làm ngay - 2 giờ)

### 1. Fix Test File Error ❌
**File:** `test/widget_test.dart`  
**Line:** 15  
**Issue:** `The name 'MyApp' isn't a class`  

**Fix:**
```dart
// Tìm entry point thực tế của app và update test
import 'package:flutter_sabohub/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SaboHubApp()); // Thay MyApp
    
    // Add proper tests
  });
}
```

**Estimate:** 30 phút  
**Priority:** 🔴 CRITICAL

---

### 2. Fix BuildContext Async Issues (15 locations)

#### File: `lib/pages/manager/manager_staff_page.dart`
**Lines:** 584, 586, 595, 689, 691, 700, 750, 752, 761, 795, 797, 806

**Current Pattern:**
```dart
if (!mounted) return;
Navigator.pop(context); // ❌ Wrong
```

**Fixed Pattern:**
```dart
if (!mounted) return;
if (mounted) {
  Navigator.pop(context); // ✅ Correct
}
```

**Locations to fix:**
1. ✅ manager_staff_page.dart (10 locations)
2. ✅ ceo_companies_page.dart (2 locations - lines 352, 358)
3. ✅ ceo_stores_page.dart (2 locations - lines 352, 358)
4. ✅ shift_leader_tasks_page.dart (2 locations - lines 327, 401)

**Estimate:** 1.5 giờ  
**Priority:** 🔴 CRITICAL

---

## 🎯 PRIORITY 2 - HIGH (Làm trong ngày - 2 giờ)

### 3. Remove Unused Imports

#### File: `lib/pages/ceo/ai_management/ai_chat_interface.dart`

**Remove these lines:**
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Line 3 - Delete
import 'dart:convert'; // Line 4 - Delete
```

**Estimate:** 5 phút  
**Priority:** 🟠 HIGH

---

### 4. Remove Unused Fields

#### File: `lib/pages/ceo/ceo_ai_assistant_page.dart`
**Line:** 103
```dart
static final List<Map<String, dynamic>> _aiFunctions = [...]; // Delete hoặc use
```

**Options:**
- Option A: Delete if không dùng
- Option B: Implement function calling logic

#### File: `lib/pages/manager/manager_staff_page.dart`
**Lines:** 18-19
```dart
String _searchQuery = ''; // Line 18 - Delete hoặc implement
String? _filterRole; // Line 19 - Delete hoặc implement
```

**Recommendation:** Implement search and filter functionality

**Estimate:** 1 giờ  
**Priority:** 🟠 HIGH

---

### 5. Fix Null Safety Issues

#### File: `lib/pages/manager/manager_settings_page.dart`

**Location 1 - Line 122:**
```dart
// Before
(user.email ?? 'M')[0].toUpperCase(),

// After
user.email[0].toUpperCase(), // email cannot be null
```

**Location 2 - Line 136:**
```dart
// Before
user.email ?? 'Manager',

// After
user.email, // email cannot be null
```

**Location 3 - Line 206:**
```dart
// Before
user.email?.split('@')[0] ?? 'N/A'

// After
user.email.split('@')[0] // email cannot be null
```

**Location 4 - Line 221:**
```dart
// Before
user.email?.split('@')[0] ?? 'N/A'

// After
user.email.split('@')[0]
```

**Estimate:** 15 phút  
**Priority:** 🟠 HIGH

---

### 6. Remove Unused Variable

#### File: `lib/services/manager_kpi_service.dart`
**Line:** 144

```dart
// Before
final role = member['role'] as String? ?? 'staff';

// After - Delete line hoặc use variable
```

**Estimate:** 5 phút  
**Priority:** 🟠 HIGH

---

## 🎯 PRIORITY 3 - MEDIUM (Làm trong tuần - 4 giờ)

### 7. Update Deprecated TextFormField API

**Files to update (8+ locations):**
- `lib/pages/ceo/ai_management/ai_chat_interface.dart:102`
- `lib/pages/manager/manager_staff_page.dart:540, 652, 724`
- `lib/pages/shift_leader/shift_leader_tasks_page.dart:281, 290, 362, 371`

**Pattern:**
```dart
// Before
TextFormField(
  value: someValue, // ❌ Deprecated
)

// After
TextFormField(
  initialValue: someValue, // ✅ New API
)
```

**Estimate:** 1 giờ  
**Priority:** 🟡 MEDIUM

---

### 8. Update Color.withOpacity() to withValues()

**Files to update (20+ locations):**
- AI Management pages
- CEO pages
- Stores pages

**Pattern:**
```dart
// Before
color.withOpacity(0.5) // ❌ Deprecated

// After
color.withValues(alpha: 0.5) // ✅ New API
```

**Affected files:**
- `ai_chat_interface.dart` (3 locations)
- `ai_management_dashboard.dart` (4 locations)
- `ai_models_page.dart` (6 locations)
- `ceo_ai_assistant_page.dart` (3 locations)
- `ceo_companies_page.dart` (4 locations)
- `ceo_stores_page.dart` (4 locations)

**Estimate:** 2 giờ  
**Priority:** 🟡 MEDIUM

---

### 9. Replace Print with Logging Framework

#### File: `lib/pages/ceo/ceo_ai_assistant_page.dart`
**Lines:** 255, 262, 271

**Step 1:** Add logger package to `pubspec.yaml`
```yaml
dependencies:
  logger: ^2.5.0
```

**Step 2:** Create logger utility
```dart
// lib/core/utils/logger.dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(),
);
```

**Step 3:** Replace print statements
```dart
// Before
print('Some debug message');

// After
logger.d('Some debug message'); // Debug
logger.i('Some info message');  // Info
logger.e('Some error message'); // Error
```

**Estimate:** 1 giờ  
**Priority:** 🟡 MEDIUM

---

### 10. Add Const Keywords for Performance

**Files to update:**
- `ceo_companies_page.dart:90, 298`
- `ceo_stores_page.dart:90, 298`
- `ceo_dashboard_page.dart:229`
- `analytics_service.dart:47`

**Pattern:**
```dart
// Before
EdgeInsets.symmetric(horizontal: 16)

// After
const EdgeInsets.symmetric(horizontal: 16)
```

**Estimate:** 30 phút  
**Priority:** 🟡 MEDIUM

---

### 11. Fix Unnecessary Code

#### Location 1: Unnecessary toList
**File:** `ceo_ai_assistant_page.dart:916`
```dart
// Before
..._messages.toList()

// After
..._messages
```

#### Location 2: Unnecessary string interpolation
**File:** `shift_leader_reports_page.dart:535`
```dart
// Before
'$variableName'

// After
variableName
```

**Estimate:** 10 phút  
**Priority:** 🟡 MEDIUM

---

## 🎯 PRIORITY 4 - LOW (Backlog - 2 giờ)

### 12. Consider CSS-like Properties

**File:** `manager_dashboard_page.dart` (32 locations)

**Current:** Standard Flutter properties  
**Suggested:** CSS-like properties (optional)

**Example:**
```dart
// Current
SizedBox(height: 24)

// Suggested (if following web standards)
SizedBox(blockSize: 24)
```

**Decision:** Đánh giá xem có cần thiết không  
**Estimate:** 2 giờ nếu implement  
**Priority:** 🟢 LOW

---

## 📊 TRACKING PROGRESS

### Checklist

#### Priority 1 - CRITICAL
- [ ] Fix test file (test/widget_test.dart)
- [ ] Fix BuildContext issues in manager_staff_page.dart (10x)
- [ ] Fix BuildContext issues in ceo_companies_page.dart (2x)
- [ ] Fix BuildContext issues in ceo_stores_page.dart (2x)
- [ ] Fix BuildContext issues in shift_leader_tasks_page.dart (2x)

#### Priority 2 - HIGH
- [ ] Remove unused imports in ai_chat_interface.dart
- [ ] Handle unused field _aiFunctions in ceo_ai_assistant_page.dart
- [ ] Handle unused fields in manager_staff_page.dart
- [ ] Fix null safety in manager_settings_page.dart (4x)
- [ ] Remove unused variable in manager_kpi_service.dart

#### Priority 3 - MEDIUM
- [ ] Update TextFormField API (8 locations)
- [ ] Update Color.withOpacity API (20+ locations)
- [ ] Implement logging framework
- [ ] Add const keywords (5+ locations)
- [ ] Fix unnecessary code patterns (2 locations)

#### Priority 4 - LOW
- [ ] Evaluate CSS-like properties

---

## 🔄 SCRIPT HỖ TRỢ

### Run All Checks
```bash
# Analyze
flutter analyze

# Format
dart format lib/ test/

# Fix auto-fixable issues
dart fix --apply

# Run tests
flutter test

# Check outdated packages
flutter pub outdated
```

### Update Dependencies
```bash
# Update to compatible versions
flutter pub upgrade

# Update to major versions (cẩn thận!)
flutter pub upgrade --major-versions
```

---

## 📈 EXPECTED OUTCOMES

### After All Fixes
- ✅ **0 errors**
- ✅ **0 warnings**
- ✅ **~10 info messages** (CSS suggestions - optional)
- ✅ **All tests passing**
- ✅ **Code quality score: 95/100**

### Benefits
- 🚀 Better performance (const optimization)
- 🛡️ More reliable (proper BuildContext handling)
- 🧹 Cleaner codebase (no unused code)
- 📈 Future-proof (no deprecated APIs)
- 🔍 Better debugging (proper logging)

---

## 📞 SUPPORT

### Need Help?
- Flutter Documentation: https://docs.flutter.dev
- Dart Language Tour: https://dart.dev/guides/language/language-tour
- Flutter Community: https://flutter.dev/community

### Tools
- VS Code Flutter Extension
- Dart DevTools
- Flutter Inspector

---

**Được tạo bởi:** GitHub Copilot  
**Ngày cập nhật:** 2/11/2025
