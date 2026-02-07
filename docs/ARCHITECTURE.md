# SABOHUB Architecture

> Tài liệu tham chiếu kiến trúc cho AI assistant & developer.
> Cập nhật: 2026-02-07

## 1. Tổng Quan Hệ Thống

SABOHUB là **nền tảng đa loại hình doanh nghiệp** (multi-business-type platform). Mỗi loại hình (phân phối, giải trí, sản xuất...) có UI, logic, và workflow riêng, nhưng chia sẻ chung hạ tầng nền tảng.

### Tech Stack
- **Frontend**: Flutter 3.35+ (Dart 3.9+), target: Web (Chrome), tương lai: Android/iOS
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **State Management**: Riverpod (flutter_riverpod)
- **Routing**: GoRouter (go_router)
- **Package name**: `flutter_sabohub`

### Project Paths
```
sabo-hub/                              ← Workspace root
├── sabohub-app/SABOHUB/              ← Flutter project root
│   ├── lib/                          ← Main source code
│   ├── pubspec.yaml                  ← Dependencies
│   └── .env.local                    ← Supabase credentials
├── sabohub-nexus/                    ← Web admin (Next.js) - separate project
├── sabohub-automation/               ← Automation scripts (TypeScript)
└── *.py                              ← Database migration/check scripts
```

## 2. Kiến Trúc Thư Mục (`lib/`)

```
lib/                                   443 files total
├── main.dart                          ← Entry point, Supabase init, ProviderScope
│
├── core/                              ← Platform infrastructure
│   ├── config/                        ← supabase_config.dart (reads .env)
│   ├── constants/                     
│   ├── debug/                         
│   ├── errors/                        ← Error handling, exceptions
│   ├── navigation/                    ← navigation_models.dart
│   ├── network/                       ← Network layer
│   ├── repositories/                  ← Data access layer
│   ├── router/                        ← app_router.dart (GoRouter configuration)
│   ├── services/                      
│   └── theme/                         ← app_theme.dart (Material Design theme)
│
├── constants/                         ← roles.dart (SaboRole enum)
│
├── business_types/                    ← ⭐ BUSINESS-TYPE SPECIFIC CODE
│   ├── distribution/   (97 files)     ← Phân phối (Odori)
│   │   ├── layouts/                   ← 5 layout files + cskh/, manager/, sales/, warehouse/
│   │   ├── models/                    ← odori_customer, odori_product, odori_delivery...
│   │   ├── pages/                     ← manager/, driver/, finance/, sales/, deliveries/...
│   │   ├── providers/                 ← odori_providers.dart
│   │   ├── screens/                   ← delivery_tracking, sales_dashboard, dms/
│   │   ├── services/                  ← odori_service, sales_route, sell_in_sell_out...
│   │   └── widgets/                   ← sales_features_widgets
│   │
│   ├── entertainment/  (19 files)     ← Giải trí (Billiards, F&B)
│   │   ├── models/                    ← table, session, menu_item, bill
│   │   ├── pages/                     ← tables/, sessions/, menu/
│   │   ├── providers/                 ← table, session, menu
│   │   └── services/                  ← table, session, menu, bill
│   │
│   └── manufacturing/  (10 files)     ← Sản xuất
│       ├── models/                    ← manufacturing_models
│       ├── pages/manufacturing/       ← bom, materials, production, purchase, suppliers
│       └── services/                  ← manufacturing_service
│
├── layouts/                           ← Shared role layouts (non-business-type-specific)
│   ├── driver_main_layout.dart        
│   ├── manager_main_layout.dart       
│   ├── shift_leader_main_layout.dart  
│   └── warehouse_main_layout.dart     
│
├── pages/                             ← Shared pages (cross-business-type)
│   ├── auth/                          ← Login, signup, forgot password, verification
│   ├── ceo/                           ← CEO dashboard, companies, employees, AI, tasks
│   ├── super_admin/                   ← Super Admin layout
│   ├── staff/                         ← Staff pages (checkin, profile, tasks, reports)
│   ├── shift_leader/                  ← Shift leader pages
│   ├── manager/                       ← Manager pages (analytics, staff, attendance)
│   ├── employees/                     ← Employee CRUD, invitations
│   ├── customers/                     ← Customer detail, form (shared)
│   ├── products/                      ← Product form (shared)
│   ├── orders/                        ← Order form, list (shared)
│   ├── inventory/                     ← Inventory form, list, adjustment
│   ├── payments/                      ← Payment form, list
│   ├── warehouse/                     ← Warehouse stock view, picking
│   ├── attendance/                    ← Attendance list
│   ├── tasks/                         ← Task form, list
│   ├── schedules/                     ← Schedule form, list
│   ├── onboarding/                    ← Employee onboarding flow
│   ├── company/                       ← Company settings
│   ├── map/                           ← Map overview, tracking
│   ├── delivery/                      ← Route planning
│   ├── user/                          ← User profile
│   ├── admin/                         ← Admin pages
│   ├── common/                        ← Common pages
│   ├── test/                          ← Test pages
│   ├── role_based_dashboard.dart      ← ⭐ ROUTING HUB (role + businessType → layout)
│   └── staff_main_layout.dart         ← Default staff layout
│
├── models/                            ← Shared data models (~40 files)
│   ├── user.dart                      ← User model with role, department, businessType
│   ├── business_type.dart             ← BusinessType enum (distribution, entertainment...)
│   ├── company.dart, employee.dart    ← Core entities
│   ├── customer_address.dart, customer_contact.dart, customer_tier.dart
│   ├── attendance.dart, commission_*.dart, inventory*.dart, order.dart...
│   └── models.dart                    ← Barrel export file
│
├── services/                          ← Shared services (~40 files)
│   ├── employee_auth_service.dart     ← Auth logic
│   ├── employee_service.dart          ← Employee CRUD
│   ├── company_service.dart           ← Company management
│   ├── order_service.dart             ← Order processing
│   ├── payment_service.dart           ← Payment handling
│   ├── attendance_service.dart        ← Attendance tracking
│   ├── gps_tracking_service.dart      ← GPS/Location
│   ├── notification_service.dart      ← Push notifications
│   └── ...                            
│
├── providers/                         ← Riverpod providers (~30 files)
│   ├── auth_provider.dart             ← ⭐ Core auth state (currentUserProvider)
│   ├── company_provider.dart          
│   ├── employee_provider.dart         
│   ├── order_provider.dart            
│   └── ...                            
│
├── widgets/                           ← Shared UI components (~40 files)
│   ├── ai/                            ← AI assistant widgets
│   ├── common/                        ← Common reusable widgets
│   ├── map/                           ← Map widgets
│   ├── notification_center.dart       ← Notification center
│   ├── customer_*.dart                ← Customer-related sheets
│   ├── sabo_*.dart                    ← SABO branded components
│   └── ...                            
│
├── utils/                             ← Utilities
│   ├── app_logger.dart                ← Logging with AppLogger.nav(), .box()
│   ├── error_tracker.dart             ← Error tracking
│   └── ...                            
│
├── shared/widgets/                    ← Additional shared widgets
├── features/                          ← Feature modules (ceo/, documents/)
├── mixins/                            ← pagination_mixin.dart
└── examples/                          ← Example code
```

## 3. Routing Architecture

### Luồng chính
```
main.dart → SaboHubApp → GoRouter (app_router.dart) → RoleBasedDashboard → Layout
```

### Role → Layout Mapping (role_based_dashboard.dart)

```dart
switch (role) {
  superAdmin  → SuperAdminMainLayout          // Platform admin
  ceo         → CEOMainLayout                  // Executive dashboard
  manager:
    if (isDistribution) → DistributionManagerLayout
    else                → ManagerMainLayout     // Default
  shiftLeader → ShiftLeaderMainLayout
  staff:
    if (isDistribution):
      department == 'sales'            → DistributionSalesLayout
      department == 'warehouse'        → DistributionWarehouseLayout
      department == 'delivery'|'driver'→ DistributionDriverLayout
      department == 'customer_service' → DistributionCustomerServiceLayout
      department == 'finance'          → DistributionFinanceLayout
    else → StaffMainLayout              // Default
  driver:
    if (isDistribution) → DistributionDriverLayout
    else                → DriverMainLayout
  warehouse → WarehouseMainLayout
}
```

### Routing Decision Factors
1. **`role`**: Từ `employees.role` column (SUPER_ADMIN, CEO, MANAGER, SHIFT_LEADER, STAFF, DRIVER, WAREHOUSE)
2. **`businessType`**: Từ `companies.business_type` joined qua `employees.company_id` (distribution, manufacturing, billiards...)
3. **`department`**: Từ `employees.department` column (sales, warehouse, delivery, customer_service, finance)

## 4. State Management (Riverpod)

### Core Providers
- `authProvider` → `StateNotifier<AuthState>` — Login/logout/session management
- `currentUserProvider` → `User?` — Current logged-in user (derived from authProvider)
- Auth flow: `employee_login` RPC → save to local storage → restore on app start

### Pattern
```dart
// Read data
final user = ref.watch(currentUserProvider);

// Mutate state
ref.read(authProvider.notifier).login(email, password);

// Auto-refresh pattern
final data = ref.watch(someProvider);
```

## 5. Supabase Integration

### Configuration
- Credentials loaded from `.env.local` via `flutter_dotenv`
- Client accessed via `Supabase.instance.client`
- Auth: PKCE flow with auto token refresh

### Common Query Patterns
```dart
// Simple select with RLS
final data = await supabase.from('table').select().eq('company_id', companyId);

// Join query
final data = await supabase.from('employees').select('*, companies(*)');

// RPC call
final result = await supabase.rpc('function_name', params: {'key': value});

// Insert
await supabase.from('table').insert({'col': value});

// Update
await supabase.from('table').update({'col': value}).eq('id', id);
```

### Supabase Project
- Project ID: `dqddxowyikefqcdiioyh`
- Region: `ap-southeast-2` (Sydney)
- DB Pooler: `postgresql://postgres.dqddxowyikefqcdiioyh:****@aws-1-ap-southeast-2.pooler.supabase.com:6543/postgres`

## 6. Thêm Business Type Mới (Guide)

Khi cần thêm loại hình doanh nghiệp mới (VD: `logistics`):

1. **Thêm enum value** vào `models/business_type.dart`:
   ```dart
   logistics('Vận Tải', Icons.local_shipping, Color(0xFF...)),
   ```

2. **Tạo folder** `lib/business_types/logistics/`:
   ```
   logistics/
   ├── layouts/       ← Layout cho từng department
   ├── pages/         ← Pages riêng
   ├── models/        ← Data models riêng
   ├── services/      ← Business logic riêng
   ├── providers/     ← State management riêng
   └── widgets/       ← UI components riêng
   ```

3. **Cập nhật routing** trong `role_based_dashboard.dart`:
   ```dart
   if (businessType == BusinessType.logistics) {
     return const LogisticsManagerLayout();
   }
   ```

4. **Thêm routes** vào `app_router.dart` nếu cần deep-link

5. **Shared code** giữ nguyên trong `models/`, `services/`, `providers/`, `widgets/`

## 7. Build & Deploy

```bash
# Development
cd sabohub-app/SABOHUB
flutter run -d chrome

# Production build
flutter build web --no-tree-shake-icons

# Analyze
flutter analyze

# Output
build/web/   ← Deploy này lên hosting
```
