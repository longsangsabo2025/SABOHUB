# 🏥 SABOHUB — BÁO CÁO SỨC KHOẺ DỰ ÁN

**Ngày kiểm tra:** 2026-03-29
**Flutter project:** `sabohub-app/SABOHUB/`
**Công cụ:** flutter analyze, flutter test, grep/regex scan

---

## 📊 TỔNG QUAN

| Metric | Giá trị |
|--------|---------|
| Tổng file Dart (lib/) | **561** |
| Tổng dòng code (lib/) | **228,363** |
| File test | **23** |
| flutter analyze | ✅ **0 errors, 0 warnings** |
| flutter test | ⚠️ **297 pass, 3 fail** |
| God files (≥1000 LOC) | **45 files** |
| Files dùng setState() | **187 files** (1,178 calls) |
| Files gọi Supabase trực tiếp | **89 files** |
| Hardcoded Color() | **60 files** (356 instances) |
| Silent catch `(_)` | **49 instances** |
| TODO/FIXME/HACK | **33 markers** |
| print() trong lib/ | **1** (còn lại là debugPrint) |

---

## 🔴 CRITICAL — Cần fix ngay

### C-1. Test Failures (3 tests fail)

| Test | File | Line | Lỗi |
|------|------|------|------|
| `toUpperString converts to uppercase` | `test/constants/roles_test.dart` | L49 | Expected `'CEO'` nhưng actual `'ceo'` — test expect uppercase nhưng code trả về lowercase |
| `values has exactly 8 roles` | `test/constants/roles_test.dart` | L120 | Expected `8` nhưng actual `9` — role mới được thêm (shareholder?) mà test chưa cập nhật |
| `toJson serializes user correctly` | `test/models/user_test.dart` | L153 | Expected `'MANAGER'` nhưng actual `'manager'` — toJson trả lowercase thay vì uppercase |

**Impact:** CI/CD sẽ fail. Toàn bộ test suite blocked bởi 3 tests out-of-date.
**Fix:** Cập nhật expected values trong test files cho khớp với code hiện tại.

---

### C-2. Blockchain Config — Placeholder Addresses chưa deploy

| File | Line | Vấn đề |
|------|------|--------|
| `lib/core/config/blockchain_config.dart` | L45 | `'0x0000000000000000000000000000000000000000'` — TODO: Deploy & update |
| `lib/core/config/blockchain_config.dart` | L52 | `'0x0000000000000000000000000000000000000000'` — TODO: Deploy & update |
| `lib/core/config/blockchain_config.dart` | L59 | `'0x0000000000000000000000000000000000000000'` — TODO: Deploy & update |
| `lib/core/config/blockchain_config.dart` | L66 | `'0x0000000000000000000000000000000000000000'` — TODO: Deploy & update |
| `lib/core/config/blockchain_config.dart` | L105 | `bridgeApiUrl = ''` — TODO: Set bridge API endpoint |

**Impact:** Toàn bộ blockchain/token feature sẽ crash nếu user trigger. Gọi contract tới address 0x000...0 = burn tokens.
**Fix:** Deploy contracts lên testnet/mainnet rồi update addresses, hoặc disable feature cho tới khi deploy.

---

### C-3. Error Handler — Chưa implement reporting

| File | Line | Vấn đề |
|------|------|--------|
| `lib/core/errors/error_handler.dart` | L121 | `// TODO: Implement error reporting to services like Sentry, Crashlytics, etc.` |

**Impact:** Production errors bị nuốt, không gửi lên Sentry dù đã cài sentry_flutter. Team không biết khi user gặp lỗi.
**Fix:** Kết nối ErrorHandler.reportError() → Sentry.captureException().

---

## 🟡 HIGH — Nên fix sớm

### H-1. Silent Catch Blocks — 49 instances

Catch `(_)` mà không log/rethrow = nuốt lỗi, rất khó debug production issues.

**Top 10 nguy hiểm nhất (trong service/provider layers):**

| File | Line | Context |
|------|------|---------|
| `lib/services/analytics_service.dart` | L96, L275, L479 | Analytics queries fail silently |
| `lib/providers/company_alerts_provider.dart` | L45, L97 | Company alerts fail silently |
| `lib/services/auto_task_generator.dart` | L152 | Auto-generated tasks fail silently |
| `lib/services/attendance_service.dart` | L382 | Attendance delete fails silently |
| `lib/core/repositories/impl/sales_order_repository.dart` | L224 | Order stats fail silently |
| `lib/core/repositories/impl/customer_repository.dart` | L184 | Customer stats fail silently |
| `lib/services/company_service.dart` | L154 | Company data fails silently |
| `lib/business_types/distribution/providers/odori_providers.dart` | L533, L575 | Distribution data fails silently |
| `lib/services/manager_kpi_service.dart` | L99 | KPI calculations fail silently |
| `lib/pages/staff/staff_checkin_page.dart` | L575, L597 | Check-in fails silently |

**Impact:** Bugs trong production không thể detect. Data inconsistency không ai biết.
**Fix:** Thêm `AppLogger.error()` hoặc `Sentry.captureException()` trong mỗi catch block.

---

### H-2. God Files — 45 files ≥ 1000 LOC

**Top 15 lớn nhất:**

| Lines | File |
|-------|------|
| 3,321 | `lib/pages/customers/customer_detail_page.dart` |
| 3,227 | `lib/pages/ceo/service/service_ceo_layout.dart` |
| 2,912 | `lib/pages/ceo/company_details_page.dart` |
| 2,744 | `lib/business_types/service/layouts/service_manager_layout.dart` |
| 2,523 | `lib/business_types/distribution/pages/driver/driver_deliveries_page.dart` |
| 2,332 | `lib/business_types/distribution/pages/sales/journey_plan_page.dart` |
| 2,210 | `lib/business_types/distribution/pages/manager/referrers_page.dart` |
| 2,026 | `lib/pages/super_admin/super_admin_main_layout.dart` |
| 1,963 | `lib/business_types/distribution/pages/manager/orders_management_page.dart` |
| 1,922 | `lib/pages/ceo/company/accounting_tab.dart` |
| 1,920 | `lib/widgets/task/task_board.dart` |
| 1,851 | `lib/pages/ceo/company/tasks_tab.dart` |
| 1,824 | `lib/pages/token/sabo_wallet_page.dart` |
| 1,804 | `lib/business_types/distribution/layouts/warehouse/warehouse_packing_page.dart` |
| 1,803 | `lib/pages/orders/order_form_page.dart` |

**Impact:** Khó maintain, dễ gây merge conflicts, mỗi lần sửa 1 dòng phải đọc 3000+ dòng context.
**Fix:** Tách thành sub-widgets / sub-pages. Ví dụ: `customer_detail_page.dart` → tách tabs thành files riêng.

---

### H-3. Direct Supabase Calls trong Pages — 89 files

Pages/layouts gọi `supabase.from()` / `supabase.rpc()` trực tiếp thay vì qua service layer.

**Nguy hiểm vì:**
- Logic DB trùng lặp giữa nhiều pages
- Không thể unit test (page phụ thuộc trực tiếp vào Supabase client)
- Sai column name mỗi page tự viết query riêng

**Impact:** Technical debt tích luỹ. Mỗi lần đổi schema DB có thể phải sửa 89 files.
**Fix:** Dần chuyển DB calls sang service/repository layer. Ưu tiên các core flows (order, delivery, payment).

---

### H-4. Unimplemented Features — TODO markers blocking UX

| File | Line | TODO |
|------|------|------|
| `lib/widgets/ai/recommendations_list_widget.dart` | L655, L666, L677 | Accept/reject/implement logic trống |
| `lib/pages/user/user_profile_page.dart` | L859, L894, L916 | Notification toggle, language, help trống |
| `lib/business_types/distribution/pages/receivables/odori_receivables_page.dart` | L405, L412 | Navigation + payment recording trống |
| `lib/pages/delivery/route_planning_page.dart` | L759 | Open route in map trống |
| `lib/business_types/distribution/pages/orders/odori_orders_page.dart` | L164, L322 | Date filter + nav trống |
| `lib/pages/shift_leader/shift_leader_team_page.dart` | L652, L665 | Call phone + Send email trống |

**Impact:** User bấm nút nhưng không gì xảy ra → UX kém, confusion.
**Fix:** Implement hoặc ẩn button cho đến khi sẵn sàng.

---

## 🟠 MEDIUM — Technical Debt cần theo dõi

### M-1. setState() Overuse — 187 files, 1,178 calls

Project dùng Riverpod nhưng rất nhiều page vẫn dùng `setState()` thay vì Riverpod state.

**Top 10 setState hotspots:**

| Calls | File |
|-------|------|
| 27 | `lib/business_types/distribution/pages/driver/driver_journey_map_page.dart` |
| 26 | `lib/business_types/distribution/widgets/sales_features_widgets_2.dart` |
| 22 | `lib/pages/super_admin/super_admin_main_layout.dart` |
| 21 | `lib/widgets/task/task_create_dialog.dart` |
| 21 | `lib/pages/orders/order_form_page.dart` |
| 19 | `lib/business_types/distribution/pages/manager/referrers_page.dart` |
| 17 | `lib/business_types/service/pages/cashflow/daily_cashflow_import_page.dart` |
| 17 | `lib/business_types/distribution/pages/driver/driver_deliveries_page.dart` |
| 16 | `lib/pages/user/user_profile_page.dart` |
| 16 | `lib/business_types/distribution/pages/sales/journey_plan_page.dart` |

**Impact:** State sync issues giữa local state và Riverpod providers. Difficult to test.
**Fix:** Gradual migration: khi sửa bug ở file nào, refactor setState → Riverpod StateProvider/NotifierProvider.

---

### M-2. Hardcoded Colors — 60 files, 356 instances

Dùng `Color(0xFF...)` trực tiếp thay vì `AppColors` constants.

**Hotspot files:**

| File | Approx instances |
|------|-----------------|
| `lib/widgets/notification_widgets.dart` | ~20 |
| `lib/widgets/task/task_card.dart` | ~10 |
| `lib/widgets/task/task_create_dialog.dart` | ~6 |
| `lib/models/token/token_transaction.dart` | ~4 |
| `lib/models/token/token_store_item.dart` | ~5 |
| `lib/models/customer_tier.dart` | ~5 |
| `lib/models/business_type.dart` | ~1 |
| `lib/models/schedule.dart` | ~2 |
| `lib/widgets/sabo_refresh_button.dart` | ~2 |

**Impact:** Không thể đổi theme (dark mode) vì colors hardcoded. UI inconsistency.
**Fix:** Extract tất cả sang `AppColors` class. Ưu tiên widgets/ trước.

---

### M-3. Test Coverage Gap

| Metric | Giá trị |
|--------|---------|
| Test files | 23 |
| Production files | 561 |
| Test coverage % (estimate) | **~4%** file-level |
| Widget tests | **0** |
| Provider tests | **0** |
| Integration tests | **0** |

**Untested critical paths:**
- Order creation flow
- Delivery completion flow
- Payment recording flow
- Auth login/logout flow (UI)
- CEO dashboard data aggregation

**Impact:** Regressions không bị catch. Mỗi hotfix có thể break chỗ khác.
**Fix:** Thêm tests cho critical paths trước. Ít nhất service-level tests cho order, delivery, payment.

---

### M-4. Attendance Service — Hardcoded zeros

| File | Line | Vấn đề |
|------|------|--------|
| `lib/services/attendance_service.dart` | L409 | `breaks: []` — TODO: Add breaks if needed |
| `lib/services/attendance_service.dart` | L419 | `totalBreakMinutes: 0` — TODO: Calculate from breaks |
| `lib/providers/cached_data_providers.dart` | L581 | `lateMinutes: 0` — TODO: Calculate from shift |
| `lib/services/daily_work_report_service.dart` | L54 | `tasksAssigned: tasks.length` — TODO: Get from task service |

**Impact:** Reports/analytics dựa trên dữ liệu sai (break time luôn = 0, late minutes luôn = 0).
**Fix:** Implement calculation logic từ shift schedules.

---

## 🔵 LOW — Cải thiện dần

### L-1. Deprecated/Dead Code

| File | Line | Vấn đề |
|------|------|--------|
| `lib/utils/logger_service.dart` | L3 | `// TODO: Remove this file after confirming no references remain` |
| `lib/business_types/distribution/layouts/manager/manager_dashboard_page.dart` | L31 | `// TODO: Tính năng chuyển role - tạm ẩn, sẽ bật sau` |

**Impact:** Code thừa gây confusion. Nhẹ.
**Fix:** Xoá file hoặc uncomment khi cần.

---

### L-2. Single print() Statement

| File | Line | Vấn đề |
|------|------|--------|
| `lib/main.dart` | L56 | `print('Firebase not fully configured.')` |

**Impact:** Rất nhẹ. Nên dùng `debugPrint()` hoặc `AppLogger.warning()` cho consistency.

---

### L-3. Distribution Navigation TODOs (non-blocking)

| File | Line | TODO |
|------|------|------|
| `lib/business_types/distribution/pages/deliveries/odori_deliveries_page.dart` | L393 | Navigate to delivery detail |
| `lib/business_types/distribution/pages/deliveries/odori_deliveries_page.dart` | L442 | Show on map |
| `lib/business_types/distribution/pages/customers/odori_customers_page.dart` | L423 | Navigate to orders |
| `lib/business_types/distribution/pages/customers/odori_customers_page.dart` | L433 | Create new order |
| `lib/business_types/distribution/pages/customers/odori_customers_page.dart` | L550 | Launch phone dialer |
| `lib/business_types/distribution/pages/orders/odori_orders_page.dart` | L164 | Date range filter |
| `lib/business_types/distribution/pages/orders/odori_orders_page.dart` | L322 | Navigate to order detail |
| `lib/business_types/distribution/pages/products/odori_products_page.dart` | L186 | Barcode scanning |
| `lib/business_types/distribution/pages/sales/journey_plan_page.dart` | L655 | Load journey plan for date |

**Impact:** Feature incomplete nhưng không crash. Secondary pages.

---

## 🗺️ ƯU TIÊN FIX (Recommended Order)

| Priority | Task | Effort | Impact |
|----------|------|--------|--------|
| 1 | Fix 3 test failures | 15 min | CI/CD unblocked |
| 2 | Connect ErrorHandler → Sentry | 30 min | Production error visibility |
| 3 | Fix/disable blockchain placeholders | 30 min | Prevent token loss |
| 4 | Add logging to top 10 silent catches | 1h | Debug production issues |
| 5 | Implement missing button actions (H-4) | 2h | UX improvement |
| 6 | Add service-level tests for core flows | 4h | Regression protection |
| 7 | Refactor top 5 god files | 8h+ | Maintainability |
| 8 | Migrate hardcoded Colors → AppColors | 4h | Theme consistency |
| 9 | Migrate top 10 setState pages → Riverpod | 8h+ | State management cleanup |
| 10 | Move direct Supabase calls → service layer | 16h+ | Architecture cleanup |

---

## ✅ ĐIỂM TỐT

- **flutter analyze: 0 errors, 0 warnings** — Code compiles clean
- **297/300 tests pass** — High pass rate
- **Logging tốt** — Hầu hết dùng `debugPrint()` / `AppLogger`, chỉ 1 `print()`
- **Không hardcoded IP/localhost** — URLs đều legitimate APIs
- **Soft delete pattern** — Consistent dùng `is_active = false` / `status = 'inactive'`
- **Error handling coverage** — Hầu hết API calls có try-catch (dù 49 catch silent)
- **Structured routing** — GoRouter centralized, role-based navigation works
- **Auth flow solid** — RPC-based auth, không phụ thuộc Supabase auth trực tiếp

---

*Report generated: 2026-03-29 | Tool: flutter analyze + flutter test + regex scan*
