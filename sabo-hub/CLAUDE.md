# SABOHUB — Claude Code Instructions

## Vai trò
Bạn là SENIOR FLUTTER ENGINEER duy nhất. Tôi là PM.
Giao tiếp bằng tiếng Việt. Code bằng tiếng Anh.

## Project Overview
- **App**: SABOHUB — Hệ thống quản lý doanh nghiệp đa ngành (phân phối, dịch vụ giải trí, sản xuất). Web app quản lý từ CEO → Manager → Staff → Driver → Warehouse → Finance.
- **Package name**: `flutter_sabohub`
- **Flutter version**: SDK ^3.5.0
- **Dart version**: ^3.5.0
- **State management**: Riverpod 3.x (`flutter_riverpod: ^3.0.3`) — NotifierProvider, FutureProvider, Provider, StateProvider
- **Backend**: Supabase (`supabase_flutter: ^2.10.3`) — PostgreSQL + PostgREST + Realtime + Storage + Auth (PKCE flow)
- **Routing**: GoRouter (`go_router: ^14.8.0`) — Centralized in `lib/core/router/app_router.dart`
- **Error tracking**: Sentry (`sentry_flutter: ^8.12.0`)
- **Push notifications**: Firebase Messaging (`firebase_messaging: ^16.1.2`)
- **Production URL**: https://sabohub.vercel.app
- **Build target**: Web only (`flutter build web --no-tree-shake-icons`)

## Architecture thực tế

**Pattern**: Feature-first hybrid. Business domain code tách theo `business_types/`, shared code ở `pages/`, `models/`, `services/`, `providers/`. Không có Clean Architecture rõ ràng — nhiều page gọi Supabase trực tiếp thay vì qua service layer.

**Folder structure**:
```
lib/                              # 559 dart files total
├── main.dart                     # Entry point — Supabase init, Sentry, Firebase, ProviderScope
├── business_types/               # Feature-first business modules
│   ├── distribution/             # 90 files — B2B distribution (Odori brand)
│   │   ├── layouts/              # Tab layouts for Sales, Warehouse, Manager, CSKH, Finance
│   │   │   ├── sales/            # Sales dashboard, order creation, customer mgmt
│   │   │   │   └── sheets/       # Bottom sheets (order form, customer form, order history)
│   │   │   ├── warehouse/        # Dashboard, inventory, packing, picking
│   │   │   ├── manager/          # Manager dashboard
│   │   │   └── cskh/             # Customer service (CSKH) pages
│   │   ├── models/               # OdoriCustomer, OdoriProduct, OdoriSalesOrder, OdoriDelivery, OdoriReceivable, ProductSample
│   │   ├── pages/                # Standalone pages per domain
│   │   │   ├── customers/        # Customer list (full CRUD)
│   │   │   ├── deliveries/       # Delivery form, delivery list
│   │   │   ├── driver/           # Driver layouts, deliveries, routes, journey map, history
│   │   │   ├── finance/          # Dashboard, payments, receivables, invoices, orders summary, debt detail
│   │   │   ├── manager/          # Customers, inventory, orders mgmt, referrers, reports, survey
│   │   │   ├── orders/           # Order list
│   │   │   ├── products/         # Product list, product samples
│   │   │   ├── receivables/      # Receivables list, payment recording
│   │   │   └── sales/            # Journey plan, sales activity, journey map
│   │   ├── providers/            # odori_providers (FutureProvider for customers, products, orders, etc.)
│   │   │                          # inventory_provider, referrers_provider, driver_providers
│   │   ├── services/             # odori_service, odori_notification_service, sales_features_service
│   │   │                          # sales_route_service, store_visit_service
│   │   └── widgets/              # Invoice preview, sales feature widgets
│   ├── service/                  # 71 files — Entertainment/F&B (billiards, restaurant, café, hotel, retail)
│   │   ├── layouts/              # Manager, Shift Leader, Staff tab layouts
│   │   ├── models/               # Session, Bill, Reservation, Schedule, Event, MenuItem, etc.
│   │   ├── pages/                # Sessions, Menu, Cashflow, Schedule, Reports, Reservations, Learning
│   │   ├── providers/            # session_provider, menu_provider, reservation_provider, etc.
│   │   ├── services/             # session_service, menu_service, bill_service, reservation_service, etc.
│   │   └── widgets/              # Daily checklist, notification bell, weekly insight
│   └── manufacturing/            # 16 files — Production management
│       ├── layouts/              # Manufacturing manager layout
│       ├── models/               # manufacturing_models, quality_inspection
│       ├── pages/                # BOM, materials, suppliers, production/purchase orders, payables, QC
│       ├── providers/            # quality_provider
│       └── services/             # manufacturing_service, quality_service
├── pages/                        # 120 files — Shared/cross-business pages
│   ├── auth/                     # Login (dual), signup, forgot password, email verification, employee onboarding
│   ├── ceo/                      # CEO dashboard, analytics, companies, finance, schedule, tasks, reports
│   │   ├── ai_management/        # AI assistants, chat, models, prompts, projects
│   │   ├── company/              # Company detail tabs (overview, employees, attendance, accounting, etc.)
│   │   ├── distribution/         # CEO distribution overview (dashboard, finance, operations, sales, team)
│   │   ├── manufacturing/        # CEO manufacturing layout
│   │   ├── service/              # CEO service layout (content, event, tournament forms)
│   │   └── shared/               # CEO more page
│   ├── gamification/             # Quest hub, leaderboard, season pass, UyTin store, analytics
│   ├── token/                    # SABO wallet, token store, achievements, leaderboard, analytics
│   ├── manager/                  # Manager dashboard, staff, analytics, attendance, reports, tasks
│   ├── staff/                    # Staff check-in, tasks, reports, messages
│   ├── shift_leader/             # Shift leader reports, tasks, team
│   ├── super_admin/              # Super admin layout
│   ├── shareholder/              # Shareholder dashboard
│   ├── travis/                   # Travis AI chat (company AI assistant)
│   ├── common/                   # Company info
│   ├── admin/                    # Bug reports management
│   ├── company/                  # Company settings
│   ├── company_showcase/         # Company showcase
│   ├── customers/                # Customer detail, form
│   ├── delivery/                 # Route planning
│   ├── employees/                # Employee list, create, invite
│   ├── onboarding/               # Employee onboarding flow
│   ├── orders/                   # Order form, payment
│   ├── products/                 # Product form
│   ├── referral/                 # Referral page
│   ├── schedules/                # Schedule list, form
│   ├── warehouse/                # Picking, stock view
│   ├── user/                     # User profile
│   ├── role_based_dashboard.dart # ROUTING HUB — routes to correct layout based on user role + businessType
│   └── staff_main_layout.dart    # Staff tab layout
├── providers/                    # 38 files — Shared Riverpod providers
│   ├── auth/                     # auth_state, auth_notifier, auth_providers (barrel export)
│   ├── auth_provider.dart        # Re-exports auth/ barrel
│   └── [36 other providers]      # company, employee, task, payment, analytics, AI, theme, etc.
├── services/                     # 50 files — Shared service classes
│   ├── gamification/             # gamification_service
│   ├── token/                    # blockchain_service, token_service
│   └── [48 other services]       # employee_auth, order, payment, AI, analytics, attendance, etc.
├── models/                       # 60 files — Shared data models
│   ├── gamification/             # Achievement, quest, XP, season, badges, etc.
│   ├── token/                    # Bridge request, NFT, wallet, transactions
│   └── [core models]             # User, Company, Order, Payment, Task, Schedule, Employee, etc.
├── core/                         # 39 files — App infrastructure
│   ├── router/                   # app_router.dart — GoRouter config, route guards, route names
│   ├── theme/                    # AppColors, AppTextStyles, AppSpacing, AppTheme
│   ├── config/                   # supabase_config, sentry_config, blockchain_config
│   ├── agents/                   # AI agent system (orchestrator, executors, definitions)
│   ├── navigation/               # NavigationItem, NavigationGroup, role-based nav config
│   ├── repositories/             # base_repository, interfaces (i_customer, i_employee, i_sales_order)
│   │   └── impl/                 # Repository implementations (customer, employee, sales_order)
│   ├── services/                 # supabase_service (singleton), base_service
│   ├── viewmodels/               # base_view_model, travis_chat_view_model
│   ├── errors/                   # AppError hierarchy, ErrorHandler
│   ├── interfaces/               # Service interfaces (i_company, i_order, i_task)
│   ├── keys/                     # GlobalKey definitions for CEO widgets
│   └── common/                   # Result type
├── features/                     # 7 files — Newer feature modules (documents, Travis AI, CEO widgets)
├── layouts/                      # 4 files — Role-based main layouts (driver, manager, shift_leader, warehouse)
├── widgets/                      # 53 files — Shared UI widgets (AI, common, gamification, map, task, Travis)
├── constants/                    # roles.dart — SaboRole enum with all role definitions
└── utils/                        # app_logger.dart + other utilities
```

## Business Domain — Các entity chính

### Roles (SaboRole enum)
`superAdmin` | `ceo` | `manager` | `shiftLeader` | `staff` | `driver` | `warehouse` | `finance` | `shareholder`

### Business Types (BusinessType enum)
- **Service** (isService): `billiards`, `restaurant`, `hotel`, `cafe`, `retail`
- **Distribution** (isDistribution): `distribution`, `manufacturing`
- CEO quản lý **nhiều company** với nhiều business types khác nhau

### Core Models
| Model | Table DB | Fields quan trọng |
|-------|----------|-------------------|
| `User` | `employees` | id, name, email, role, department, companyId, businessType, warehouseId, isActive |
| `Company` | `companies` | id, name, type(BusinessType), address, bankName/Number, aiApiKey, checkInLat/Lng/Radius |
| `OdoriSalesOrder` | `sales_orders` | id, companyId, orderNumber, customerId, saleId, subtotal, discountPercent, discountAmount, total, paymentStatus, paymentMethod, status, deliveryStatus |
| `OdoriCustomer` | `customers` | id, companyId, code, name, type, phone, address, lat/lng, creditLimit, paymentTerms, assignedSaleId, tier, leadStatus, referrerId, totalDebt |
| `OdoriProduct` | `products` | id, companyId, sku, name, unit, costPrice, sellingPrice, trackInventory, minStock, status |
| `OdoriDelivery` | `deliveries` | id, companyId, deliveryNumber, driverId, plannedStops, completedStops, status |
| `OdoriReceivable` | `receivables` | id, companyId, customerId, orderId, invoiceNumber, originalAmount, paidAmount, remainingAmount, status |
| `TableSession` | `table_sessions` | id, tableId, companyId, startTime, endTime, hourlyRate, totalAmount, status |
| `Bill` | (bills) | id, companyId, billNumber, totalAmount, ocrData, status |
| `Payment` | `payments` | id, sessionId, companyId, amount, method, status |

### Distribution-specific tables
`sales_order_items`, `customer_payments`, `customer_visits`, `sales_routes`, `sell_in_transactions`, `receivables`, `product_samples`

### Shared tables
`employees`, `companies`, `branches`, `orders`, `order_items`, `payments`, `schedules`, `tasks`, `management_tasks`, `attendance`, `notifications`, `daily_work_reports`, `bug_reports`, `documents`, `analytics_events`, `kpi_targets`, `commission_rules`, `referrals`

## Supabase RPCs đang dùng
| RPC | Mục đích |
|-----|----------|
| `employee_login` | Login bằng company name + username + password |
| `create_employee_with_password` | Tạo employee mới |
| `create_employee_with_auth` | Tạo employee kèm auth account |
| `change_employee_password` | Đổi mật khẩu |
| `hash_password` | Hash password (server-side) |
| `complete_delivery` | Transaction-safe delivery completion (update delivery + sales_order) |
| `complete_delivery_transfer` | Delivery completion for transfer payment |
| `send_email_resend` | Gửi email qua Resend API |
| `get_ai_total_cost` | Tổng chi phí AI |
| `get_ai_usage_stats` | AI usage statistics |

### ⚠️ CRITICAL: Authentication Architecture
```
Employee KHÔNG CÓ tài khoản auth.users trong Supabase!
- Login = RPC `employee_login` → trả về employee data
- ❌ KHÔNG DÙNG supabase.auth.currentUser để lấy employee info
- ✅ LUÔN dùng ref.read(currentUserProvider) hoặc ref.watch(authProvider)
- Password = RPC `change_employee_password`, KHÔNG phải Supabase auth
- Session lưu local via SharedPreferences, restore khi mở app
```

## Screens & Features — Liệt kê theo role

### CEO
- Multi-company dashboard, company details (tabs: overview, employees, attendance, accounting, documents, tasks, settings, permissions)
- AI Management (assistants, chat, models, prompts, projects)
- Distribution CEO (dashboard, finance, operations, sales, team)
- Service CEO layout
- Manufacturing CEO layout
- Analytics, finance, schedule overview, reports settings, KanBan board, PDF reports
- Revenue dashboard, performance scorecard, daily reports
- Media dashboard, notifications, profile, utilities
- Gamification (game profile, quest config, analytics)

### Manager (Distribution)
- Dashboard, customers management (CRUD + credit limit + order history)
- Inventory (products, categories, warehouses, samples)
- Orders management, referrers management, reports (sales, receivables)
- Survey management

### Sales
- Dashboard, customers, orders list, create order (with discount)
- Journey plan (GPS-based route planning), sales activity, journey map

### Driver
- Delivery list + complete delivery flow (cash/transfer/debt)
- Route page (alternate delivery UI), journey map, history
- Google Maps route integration

### Warehouse
- Dashboard, inventory, picking, packing

### Finance
- Dashboard (order confirmation, transfer verification)
- Payments ("Thu tiền" tab — reads customer_payments)
- Accounts receivable (aging analysis)
- Invoices, orders summary, delivery history
- Manual receivable creation, payment recording

### Service (Billiards/Restaurant/etc.)
- Session management (start/pause/end table sessions)
- Menu management (CRUD menu items)
- Reservations (booking system)
- Shift scheduling
- Daily cashflow import, monthly P&L
- Invoice scanning (OCR)
- Staff daily reports, shift leader reviews, manager approvals
- Staff learning system
- Notifications

### Shared across roles
- Login (dual: CEO email auth + Employee company login)
- User profile, company settings
- Employee management (list, create, invite with onboarding link)
- Task management (CRUD + templates + KanBan)
- Schedule management
- Gamification (quests, leaderboard, season pass, UyTin store, achievements)
- SABO Token (wallet, token store, analytics, leaderboard — blockchain integration)
- Travis AI chat (company AI assistant via Gemini)
- Bug reports management
- Referral system
- Company showcase

## Dependencies chính (từ pubspec.yaml)

| Package | Version | Mục đích |
|---------|---------|----------|
| `flutter_riverpod` | ^3.0.3 | State management |
| `go_router` | ^14.8.0 | Routing |
| `supabase_flutter` | ^2.10.3 | Backend (Postgres + Auth + Realtime + Storage) |
| `firebase_core` | ^4.5.0 | Firebase platform |
| `firebase_messaging` | ^16.1.2 | Push notifications |
| `sentry_flutter` | ^8.12.0 | Error tracking |
| `dio` | ^5.4.0 | HTTP client |
| `geolocator` | ^14.0.2 | GPS/Location |
| `flutter_map` | ^8.2.2 | OpenStreetMap (free) |
| `fl_chart` | ^0.70.1 | Charts |
| `pdf` / `printing` | ^3.11.2 / ^5.13.4 | PDF generation & printing |
| `google_sign_in` | ^6.3.0 | Google OAuth |
| `sign_in_with_apple` | ^6.1.3 | Apple Sign In |
| `googleapis` | ^13.2.0 | Google Drive integration |
| `excel` | ^4.0.6 | Excel file parsing |
| `image_picker` | ^1.2.1 | Camera/Gallery |
| `shared_preferences` | ^2.2.2 | Local storage |
| `intl` | ^0.20.2 | Internationalization/date formatting |
| `dvhcvn` | 2.1.20250301 | Vietnam address picker |
| `confetti` | ^0.8.0 | Celebration animations |

## Quy tắc TUYỆT ĐỐI

### 1. KHÁM PHÁ TRƯỚC, CODE SAU
Trước khi sửa BẤT KỲ file nào:
- Đọc **TOÀN BỘ** file đó + các file import vào nó
- Chạy `grep -r "ClassName\|functionName"` tìm mọi nơi sử dụng
- Hiểu FLOW đầy đủ trước khi chạm code
- **Không chắc → HỎI, đừng đoán**

### 2. KHÔNG FIX MÒ — ROOT CAUSE
```
BƯỚC 1: Đọc error chính xác
BƯỚC 2: Trace ngược → file + dòng gây lỗi
BƯỚC 3: Hiểu TẠI SAO, không phải CHỖ NÀO
BƯỚC 4: Check fix có ảnh hưởng chỗ khác không
BƯỚC 5: Fix + verify
```

### 3. BLAST RADIUS CHECK
- Thay đổi ảnh hưởng bao nhiêu file?
- Widget/screen nào dùng chung state/model này?
- API call nào depend vào data shape này?
- **Blast radius > 3 files → BÁO tôi trước**

### 4. VERIFICATION BẮT BUỘC
Sau mỗi thay đổi:
```bash
flutter analyze          # 0 errors BẮT BUỘC
flutter test             # all pass (nếu có test liên quan)
flutter build web --no-tree-shake-icons  # nếu thay đổi lớn
```
Fail → **KHÔNG làm tiếp**. Fix ngay.

### 5. DB COLUMN TRAPS — Sai tên column phổ biến
| ❌ SAI (code cũ/giả định) | ✅ ĐÚNG (DB thật) |
|---------------------------|-------------------|
| `users` table | `employees` table (KHÔNG CÓ bảng `users`) |
| `is_active` boolean | `status` varchar ('active'/'inactive') — hầu hết tables |
| `total_amount` | `total` (trong `sales_orders`) |
| `employee_id` | `sale_id` (trong `sales_orders`) |
| `customer_type` | `type` (trong `customers`) |
| `customer_code` | `code` (trong `customers`) |
| `base_price` | `selling_price` (trong `products`) |
| `latitude`/`longitude` | `lat`/`lng` (trong `customers`) |
| `assigned_employee_id` | `assigned_sale_id` (trong `customers`) |
| `payment_term_days` | `payment_terms` (trong `customers`) |

### 6. BUILD RULES
- **LUÔN** dùng `--no-tree-shake-icons` khi build web
- **KHÔNG** import cross business_types (distribution ↔ service ↔ manufacturing)
- **Soft delete**: set `is_active = false` hoặc `status = 'inactive'`, KHÔNG xóa record
- **Auth**: `employee_login` RPC, KHÔNG phải Supabase auth trực tiếp

## Lỗi phổ biến trong PROJECT NÀY

### 1. Direct Supabase calls trong Pages (29+ files)
Nhiều page gọi `supabase.from('table')` trực tiếp thay vì qua service/provider. Dẫn đến:
- Logic trùng lặp giữa các pages
- Khó trace data flow khi debug
- Sai column name vì mỗi page tự viết query

### 2. God Files — Pages quá lớn
| File | Lines | Rủi ro |
|------|-------|--------|
| `customer_detail_page.dart` | 3,317 | Rất khó maintain, dễ break |
| `service_ceo_layout.dart` | 3,227 | CEO service layout monolith |
| `company_details_page.dart` | 2,912 | Company detail tabs |
| `service_manager_layout.dart` | 2,744 | Service manager monolith |
| `driver_deliveries_page.dart` | 2,515 | Driver delivery flow phức tạp |
| `journey_plan_page.dart` | 2,332 | Journey planning |
| `referrers_page.dart` | 2,210 | Referrer management |
| `super_admin_main_layout.dart` | 2,026 | Super admin layout |
| `orders_management_page.dart` | 1,963 | Order management |
| `accounting_tab.dart` | 1,922 | Accounting tab |

### 3. Duplicate Model Definitions
`OdoriCustomer` tồn tại ở 2 nơi với fields khác nhau:
- `lib/business_types/distribution/models/odori_customer.dart` (phiên bản mới, dùng trong providers)
- `lib/business_types/distribution/models/odori_models.dart` (phiên bản cũ, dùng `is_active` boolean + cũ hơn)

### 4. setState() trong ConsumerStatefulWidget
59 uses of `setState()` — một số trường hợp nên dùng Riverpod state thay vì local setState để tránh state sync issues.

### 5. 126 TODO/FIXME/HACK markers
Nhiều technical debt chưa được fix.

### 6. Hardcoded Color (29 instances)
Vẫn còn `Color(0xFF...)` rải rác thay vì dùng `AppColors`.

### 7. Hai driver pages làm gần giống nhau
- `driver_route_page.dart` — creates `customer_payments` khi cash ✅
- `driver_deliveries_page.dart` — ban đầu KHÔNG tạo `customer_payments` cho cash ❌ (đã fix 2026-03-29)
Cần cẩn thận khi sửa 1 file cần check file kia có cùng vấn đề không.

## Known Issues (từ flutter analyze)
```
flutter analyze → No issues found! (0 errors, 0 warnings)
```
Trạng thái clean tính đến 2026-03-29.

## File/Module dependencies (dễ break)

### High-coupling files — sửa 1 cái dễ vỡ cái khác
| File | Depends on | Used by |
|------|-----------|---------|
| `lib/models/user.dart` | `roles.dart`, `business_type.dart` | **Gần như toàn bộ app** — auth, providers, pages |
| `lib/providers/auth/auth_providers.dart` | `auth_state`, `auth_notifier` | Mọi page cần auth (currentUserProvider, authProvider) |
| `lib/core/router/app_router.dart` | `auth_provider`, `navigation_models`, hầu hết layouts | Entry point cho mọi navigation |
| `lib/pages/role_based_dashboard.dart` | Tất cả layout files theo role + businessType | GoRouter `/` route |
| `lib/constants/roles.dart` | Standalone | Toàn bộ role logic |
| `lib/models/business_type.dart` | `app_colors.dart` | Layout routing, CEO pages, role_based_dashboard |
| `lib/business_types/distribution/providers/odori_providers.dart` | `currentUserProvider`, all odori models | Mọi distribution page |
| `lib/business_types/distribution/models/odori_sales_order.dart` | Standalone | Orders, deliveries, finance, reports |
| `lib/business_types/distribution/models/odori_customer.dart` | Standalone | Customers, sales, orders, deliveries, finance, reports |

### Cross-module danger zones
- **Sales order flow**: `sales_create_order_page.dart` → `odori_providers.dart` → `sales_orders` table → `driver_deliveries_page.dart` / `driver_route_page.dart` → `customer_payments` table → `payments_page.dart` (Finance)
- **Delivery flow**: `warehouse_packing_page.dart` → `deliveries` table → `driver_deliveries_page.dart` → `sales_orders` update → `customer_payments` insert → `customers.total_debt` update
- **Auth flow**: `dual_login_page.dart` → `employee_login` RPC → `auth_notifier.dart` → `auth_providers.dart` → `app_router.dart` redirect → `role_based_dashboard.dart`

## Test Coverage
- **28 test files** (unit + integration)
- Test tập trung ở models, services, constants
- **KHÔNG có widget tests** cho business pages (distribution, service, manufacturing)
- **KHÔNG có tests** cho providers

## Supabase Connection (Python scripts)
```
Host: aws-1-ap-southeast-2.pooler.supabase.com:6543
DB: postgres
User: postgres.dqddxowyikefqcdiioyh
Pass: Acookingoil123
```
Python scripts nằm ở workspace root (file `_*.py`), dùng `.venv-2` environment.

## Workflow
```
1. SCAN → LOCATE → ANALYZE → PLAN → EXECUTE → VERIFY → REPORT
```

## Format báo cáo
```
✅ DONE: [mô tả]
📁 Files changed: [danh sách]
⚠️ Side effects: [none / liệt kê]
🧪 Verification: analyze ✓ | test ✓ | build ✓
```

## Khi không chắc chắn
**HỎI TÔI.** 1 câu hỏi = 30 giây. 1 fix sai = 2 tiếng debug.
