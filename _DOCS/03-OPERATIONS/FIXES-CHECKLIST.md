# ✅ CHECKLIST SỬA LỖI - THEO NGÀY

## 🗓️ NGÀY 1 (2-3 giờ) - CRITICAL & HIGH

### Morning Session
- [ ] **[30m]** Fix test file - test/widget_test.dart
  - [ ] Tìm entry point đúng của app
  - [ ] Update import statement
  - [ ] Run test để verify
  
- [ ] **[90m]** Fix BuildContext async issues
  - [ ] manager_staff_page.dart - 10 locations
    - [ ] Line 584, 586
    - [ ] Line 595
    - [ ] Line 689, 691, 700
    - [ ] Line 750, 752, 761
    - [ ] Line 795, 797, 806
  - [ ] ceo_companies_page.dart - 2 locations
    - [ ] Line 352, 358
  - [ ] ceo_stores_page.dart - 2 locations  
    - [ ] Line 352, 358
  - [ ] shift_leader_tasks_page.dart - 2 locations
    - [ ] Line 327, 401

### Afternoon Session
- [ ] **[5m]** Remove unused imports
  - [ ] ai_chat_interface.dart line 3 (flutter_dotenv)
  - [ ] ai_chat_interface.dart line 4 (dart:convert)

- [ ] **[60m]** Handle unused fields
  - [ ] ceo_ai_assistant_page.dart:103 (_aiFunctions)
    - [ ] Option A: Delete
    - [ ] Option B: Implement function calling
  - [ ] manager_staff_page.dart:18-19
    - [ ] Implement search functionality
    - [ ] Implement filter functionality

- [ ] **[15m]** Fix null safety issues
  - [ ] manager_settings_page.dart line 122
  - [ ] manager_settings_page.dart line 136  
  - [ ] manager_settings_page.dart line 206
  - [ ] manager_settings_page.dart line 221

- [ ] **[5m]** Remove unused variable
  - [ ] manager_kpi_service.dart:144 (role variable)

**End of Day 1:** Run `flutter analyze` - Nên còn ~75 info messages

---

## 🗓️ NGÀY 2 (3-4 giờ) - MEDIUM PRIORITY

### Morning Session  
- [ ] **[60m]** Update TextFormField deprecated API
  - [ ] ai_chat_interface.dart:102
  - [ ] manager_staff_page.dart:540
  - [ ] manager_staff_page.dart:652
  - [ ] manager_staff_page.dart:724
  - [ ] shift_leader_tasks_page.dart:281
  - [ ] shift_leader_tasks_page.dart:290
  - [ ] shift_leader_tasks_page.dart:362
  - [ ] shift_leader_tasks_page.dart:371

- [ ] **[60m]** Setup logging framework
  - [ ] Add logger package to pubspec.yaml
  - [ ] Create lib/core/utils/logger.dart
  - [ ] Replace print in ceo_ai_assistant_page.dart:255
  - [ ] Replace print in ceo_ai_assistant_page.dart:262
  - [ ] Replace print in ceo_ai_assistant_page.dart:271
  - [ ] Test logging works

### Afternoon Session
- [ ] **[120m]** Update Color.withOpacity to withValues
  - [ ] ai_chat_interface.dart (3 locations)
    - [ ] Line 340, 374
  - [ ] ai_management_dashboard.dart (4 locations)
    - [ ] Line 239, 287, 330, 332
  - [ ] ai_models_page.dart (6 locations)
    - [ ] Line 78, 194, 239 (2x), 243, 281, 345
  - [ ] ceo_ai_assistant_page.dart (3 locations)
    - [ ] Line 706, 875, 988
  - [ ] ceo_companies_page.dart (4 locations)
    - [ ] Line 79, 109, 133, 153
  - [ ] ceo_stores_page.dart (4 locations)
    - [ ] Line 79, 109, 133, 153

- [ ] **[30m]** Add const keywords
  - [ ] ceo_companies_page.dart:90
  - [ ] ceo_companies_page.dart:298
  - [ ] ceo_stores_page.dart:90
  - [ ] ceo_stores_page.dart:298
  - [ ] ceo_dashboard_page.dart:229
  - [ ] analytics_service.dart:47

- [ ] **[10m]** Fix unnecessary code patterns
  - [ ] ceo_ai_assistant_page.dart:916 (unnecessary toList)
  - [ ] shift_leader_reports_page.dart:535 (unnecessary interpolation)

**End of Day 2:** Run `flutter analyze` - Nên còn ~32 info (CSS warnings)

---

## 🗓️ OPTIONAL - BACKLOG

- [ ] **[120m]** Evaluate CSS-like properties in manager_dashboard_page.dart
  - [ ] Research if team wants to follow CSS standards
  - [ ] If yes, update 32 locations
  - [ ] If no, add lint ignore rules

---

## 🧪 TESTING CHECKLIST

Sau mỗi session:
- [ ] Run `flutter analyze` - Verify errors giảm
- [ ] Run `flutter test` - Verify tests pass
- [ ] Run `dart format lib/ test/` - Format code
- [ ] Run app on emulator - Verify no runtime errors
- [ ] Commit changes với message rõ ràng

---

## 📊 PROGRESS TRACKING

### Day 1 Metrics
- Start: 86 issues
- Target: ~75 issues (11 fixed)
- Critical: 0
- Warnings: 0

### Day 2 Metrics  
- Start: ~75 issues
- Target: ~32 issues (43 fixed)
- Info only: CSS warnings

### Final Metrics
- Target: 0-10 issues
- Code Quality: 95/100
- All tests: PASS

---

## 💾 GIT COMMITS

Suggested commit structure:

```bash
# Day 1 - Critical fixes
git commit -m "fix: update test file entry point"
git commit -m "fix: add mounted checks for BuildContext async usage"
git commit -m "chore: remove unused imports and fields"
git commit -m "fix: clean up null safety redundant operators"

# Day 2 - API updates
git commit -m "refactor: update TextFormField to use initialValue"
git commit -m "refactor: replace print with logger"
git commit -m "refactor: update Color.withOpacity to withValues"
git commit -m "perf: add const keywords for optimization"
git commit -m "refactor: clean up unnecessary code patterns"

# Final
git commit -m "docs: add codebase audit reports"
```

---

## 🎯 SUCCESS CRITERIA

- ✅ Flutter analyze shows 0 errors, 0 warnings
- ✅ All tests pass
- ✅ App runs without crashes
- ✅ Code quality score: 95/100
- ✅ No deprecated APIs in use
- ✅ No unused code
- ✅ Proper error handling

---

## 📞 NEED HELP?

- Stuck on BuildContext? Check: https://api.flutter.dev/flutter/widgets/State/mounted.html
- Deprecated APIs? Check: https://docs.flutter.dev/release/breaking-changes
- Logging? Check: https://pub.dev/packages/logger

---

**Last Updated:** 2/11/2025  
**Estimated Total Time:** 8-10 hours over 2 days
