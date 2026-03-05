# SABOHUB Flutter Architecture Audit Report

> **Ngày audit:** 4 tháng 3, 2026  
> **Chuẩn so sánh:** Flutter Official App Architecture Guide 2026 (Flutter 3.41.2)  
> **Project:** SABOHUB v1.5.1+18 | Flutter SDK ^3.5.0 | Riverpod 3.x  
> **Quy mô codebase:** ~502 file Dart | ~47 services | 33 providers | 80+ pages

---

## 📊 TỔNG QUAN

| # | Phần | Trạng thái | Điểm (1-10) | Effort cải thiện |
|---|------|-----------|-------------|-----------------|
| 1 | Folder Structure | ⚠️ Cần cải thiện | 4/10 | Cao |
| 2 | Layered Architecture | ❌ Vi phạm | 3/10 | Cao |
| 3 | MVVM Pattern | ❌ Vi phạm | 2/10 | Cao |
| 4 | State Management | ⚠️ Cần cải thiện | 5/10 | Trung bình |
| 5 | Repository Pattern | ❌ Vi phạm | 2/10 | Cao |
| 6 | Service Layer | ⚠️ Cần cải thiện | 4/10 | Trung bình |
| 7 | Dependency Injection | ⚠️ Cần cải thiện | 4/10 | Trung bình |
| 8 | Error Handling | ⚠️ Cần cải thiện | 5/10 | Trung bình |
| 9 | Navigation & Routing | ✅ Đạt | 7/10 | Thấp |
| 10 | Testing Readiness | ❌ Vi phạm | 2/10 | Cao |
| 11 | Code Quality & Conventions | ⚠️ Cần cải thiện | 4/10 | Trung bình |
| 12 | Scalability & Performance | ⚠️ Cần cải thiện | 4/10 | Trung bình |

**Điểm tổng: 46/120**  
**Mức độ tuân thủ Flutter Architecture 2026: 38%**

---

## PHẦN 1: CẤU TRÚC THƯ MỤC (Folder Structure) — ⚠️ 4/10

### Cấu trúc hiện tại

```
lib/
├── business_types/          # ⚠️ Không theo chuẩn — domain logic lẫn UI
│   ├── distribution/
│   ├── manufacturing/
│   └── service/
├── constants/               # ⚠️ Chỉ có 1 file (roles.dart)
├── core/                    # ✅ Tốt — config, errors, router, theme
│   ├── config/
│   ├── constants/
│   ├── errors/
│   ├── keys/
│   ├── navigation/
│   ├── network/             # ❌ Trống
│   ├── repositories/        # ❌ Trống
│   ├── router/
│   ├── services/
│   └── theme/
├── features/                # ⚠️ Mới chỉ có 2 features (ceo, documents)
│   ├── ceo/
│   └── documents/           # ✅ Duy nhất có Repository pattern
├── layouts/                 # ⚠️ Nên nằm trong ui/core/
├── main.dart
├── mixins/                  # ❌ Trống
├── models/                  # ✅ Có domain models riêng
├── pages/                   # ❌ Monolithic — 200+ files, không tách feature
│   ├── auth/
│   ├── ceo/
│   ├── orders/
│   └── ... (20+ subfolders)
├── providers/               # ⚠️ 33 providers — business logic lẫn state
├── services/                # ⚠️ 47 services — không đồng nhất
├── shared/                  # ❌ Trống
├── utils/                   # ✅ OK — logger, error tracker
└── widgets/                 # ⚠️ Shared widgets nhưng chứa cả business logic
```

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Tách rõ data/ và ui/ | ❌ | Không có data/ folder. Services + Providers lẫn lộn |
| Data layer tổ chức theo type | ⚠️ | Có `services/` nhưng không có `repositories/` ở root |
| UI layer tổ chức theo feature | ❌ | `pages/` chứa 200+ files theo kiểu flat, không phải feature-first |
| Folder domain/ riêng cho models | ⚠️ | Có `models/` nhưng nằm ngoài `domain/` |
| Folder ui/core/ cho shared widgets | ❌ | `widgets/` nằm root, không có ui/core/ |
| File/logic đặt sai layer | ❌ | Widgets gọi trực tiếp Supabase (customer_visits_sheet.dart, etc.) |

### Khuyến nghị
- **Effort: CAO** — Cần tái cấu trúc toàn bộ folder
- Chuyển dần sang cấu trúc chuẩn (xem phần Đề xuất cuối báo cáo)
- Ưu tiên di chuyển `features/documents/` pattern làm template cho các features khác

---

## PHẦN 2: LAYERED ARCHITECTURE — ❌ 3/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| UI chứa business logic trực tiếp | ❌ VI PHẠM | 181 files dùng setState cho business logic (1,170+ lần) |
| Data flow: Service → Repository → ViewModel → View | ❌ VI PHẠM | Không có Repository layer (trừ Documents). Không có ViewModel. |
| View gọi thẳng Service bypass Repository | ❌ VI PHẠM | Pages gọi trực tiếp Service và thậm chí `Supabase.instance.client` |
| ViewModel gọi thẳng HTTP/DB | ❌ VI PHẠM | Providers (đóng vai ViewModel) gọi thẳng Services, không qua Repository |
| Data drive UI hay UI drive data | ❌ VI PHẠM | Nhiều pages tự fetch data trong `initState()` rồi `setState()` |
| Circular dependency giữa layers | ⚠️ | `EmployeeService` nhận `Ref` — coupling Service → Riverpod |

### Vi phạm nghiêm trọng nhất

**1. Pages gọi thẳng Supabase:**
```dart
// ❌ HIỆN TẠI — order_form_page.dart (1,871 dòng)
// View layer trực tiếp query database
final response = await Supabase.instance.client
    .from('warehouses')
    .select()
    .eq('company_id', companyId);
```

**2. Widgets chứa data access:**
```dart
// ❌ HIỆN TẠI — customer_visits_sheet.dart, customer_debt_sheet.dart
final supabase = Supabase.instance.client;  // Top-level trong widget file
```

---

## PHẦN 3: MVVM PATTERN — ❌ 2/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Mỗi feature có 1 View + 1 ViewModel | ❌ VI PHẠM | **ZERO ViewModels** trong entire codebase |
| ViewModel import flutter/material.dart | N/A | Không có ViewModel |
| View chứa logic filter/sort/aggregate | ❌ VI PHẠM | Pages chứa toàn bộ business logic |
| ViewModel expose command pattern | N/A | Không có ViewModel |
| State quản lý trong ViewModel hay View | ❌ VI PHẠM | State rải rác trong 181 StatefulWidget files |
| Models immutable | ⚠️ | Hầu hết dùng `final` fields nhưng không consistent |

### Hiện trạng

Codebase hiện tại dùng **Page-Provider-Service** pattern, **KHÔNG** phải MVVM:

```
Kiến trúc hiện tại (thực tế):

Page (View + Logic + State)
  ├── setState() — local UI state + business logic
  ├── Supabase.instance.client — direct DB query
  └── ref.watch(provider) — shared state
      └── Provider (partial ViewModel)
          └── Service (data access)
```

So với chuẩn:
```
Kiến trúc chuẩn MVVM 2026:

View (Widget only)
  └── ViewModel (ChangeNotifier/Notifier)
      └── Repository (source of truth)
          └── Service (external API/DB)
```

### Code Example — BEFORE vs AFTER

**BEFORE (hiện tại — order_form_page.dart):**
```dart
class _OrderFormPageState extends ConsumerState<OrderFormPage> {
  List<Map<String, dynamic>> _warehouses = [];  // ❌ State trong View
  bool _isLoading = true;                        // ❌ State trong View
  
  @override
  void initState() {
    super.initState();
    _loadWarehouses();  // ❌ Business logic trong View
  }
  
  Future<void> _loadWarehouses() async {
    final response = await Supabase.instance.client  // ❌ Direct DB trong View
        .from('warehouses')
        .select()
        .eq('company_id', widget.companyId);
    setState(() {                                     // ❌ setState cho business data
      _warehouses = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }
  // ... 1,871 dòng code lẫn lộn
}
```

**AFTER (chuẩn MVVM):**
```dart
// 1. Service (data access only)
class OrderService extends BaseService {
  Future<List<Warehouse>> getWarehouses(String companyId) async {
    return safeCall(
      operation: 'getWarehouses',
      action: () async {
        final data = await client.from('warehouses')
            .select().eq('company_id', companyId);
        return (data as List).map((e) => Warehouse.fromJson(e)).toList();
      },
    );
  }
}

// 2. Repository (source of truth + caching)
class OrderRepository {
  final OrderService _service;
  OrderRepository(this._service);
  
  Future<List<Warehouse>> getWarehouses(String companyId) async {
    return _service.getWarehouses(companyId);
  }
}

// 3. ViewModel (UI state + logic)
class OrderFormViewModel extends AutoDisposeAsyncNotifier<OrderFormState> {
  @override
  Future<OrderFormState> build() async {
    final repo = ref.read(orderRepositoryProvider);
    final warehouses = await repo.getWarehouses(companyId);
    return OrderFormState(warehouses: warehouses);
  }
}

// 4. View (widgets only)
class OrderFormPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderFormViewModelProvider);
    return state.when(
      data: (data) => _buildForm(data),
      loading: () => const LoadingIndicator(),
      error: (e, _) => ErrorDisplay(error: e),
    );
  }
}
```

---

## PHẦN 4: STATE MANAGEMENT — ⚠️ 5/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| State management nào? Nhất quán? | ⚠️ | Riverpod 3.x **+** setState — KHÔNG nhất quán |
| setState cho business logic | ❌ VI PHẠM | 1,170+ setState calls across 181 files |
| State centralize trong ViewModel/Bloc | ❌ | Providers chứa 1 phần, pages chứa phần lớn |
| Global state cho shared data | ✅ | `authProvider`, `companyProvider`, `themeProvider` |
| State transitions: loading → success → error | ⚠️ | Providers dùng `AsyncValue` đúng, nhưng pages tự quản lý |

### Phân tích

- **Riverpod 3.x** được declare trong pubspec và sử dụng đúng syntax (`Notifier`, `AsyncNotifier`, `FutureProvider.autoDispose.family`)
- **Vấn đề chính:** Song song tồn tại 2 hệ thống state:
  - Riverpod providers (33 files) — cho shared/global state
  - `setState()` (181 files, 1,170 calls) — cho local page state + business logic
- **"God Provider":** `auth_provider.dart` = **1,017 dòng** chứa: auth flow, session management, Apple Sign-In, demo mode, multi-account switching

### Top setState offenders:
| File | setState calls |
|------|---------------|
| `pages/super_admin/super_admin_main_layout.dart` | 22 |
| `pages/orders/order_form_page.dart` | 21 |
| `pages/auth/dual_login_page.dart` | 16 |
| `pages/user/user_profile_page.dart` | 16 |
| `pages/ceo/company_details_page.dart` | 15 |
| Toàn bộ `business_types/` | 626 |

---

## PHẦN 5: REPOSITORY PATTERN — ❌ 2/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Mỗi loại data có Repository riêng | ❌ VI PHẠM | Chỉ có **1 Repository** (`DocumentsRepository`) trong 502 files |
| Repository có abstract class/interface | ❌ | `DocumentsRepository` là concrete class, không có interface |
| Repository xử lý caching/transformation | ⚠️ | `DocumentsRepository` transform data nhưng không cache |
| Well-defined inputs/outputs | ⚠️ | `DocumentsRepository` có tham số rõ ràng |
| Repository quá lớn cần tách | N/A | Chỉ có 1 (326 dòng) |

### Hiện trạng

- `core/repositories/` — **TRỐNG**
- `features/documents/repositories/documents_repository.dart` — **Duy nhất** nơi có Repository pattern
- Services đang đóng vai cả Repository: `OrderService`, `TaskService`, `EmployeeService`... đều trực tiếp query DB + transform data
- Không có abstraction layer giữa Service và Provider/Page

### Repository cần tạo (ưu tiên):
1. `UserRepository` — auth, profile, multi-account
2. `CompanyRepository` — company CRUD, settings
3. `OrderRepository` — orders, order items, pricing
4. `EmployeeRepository` — employees, documents, attendance
5. `TaskRepository` — tasks, assignments, comments
6. `CustomerRepository` — customers, contacts, addresses, revenue+
7. `PaymentRepository` — payments, accounting
8. `InventoryRepository` — warehouse, stock management

---

## PHẦN 6: SERVICE LAYER — ⚠️ 4/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| API calls trong Service class riêng | ✅ | 47+ service files tách riêng |
| Database queries trong Service | ✅ | Supabase queries chủ yếu trong services |
| Service có abstract class/interface | ❌ | 0 abstract interfaces (không thể mock) |
| Error handling tại Service level | ⚠️ | Chỉ 7/47 services extend `BaseService` |
| Tách riêng theo responsibility | ✅ | Có tách: AuthService, OrderService, TaskService, etc. |

### Chi tiết `BaseService` adoption:

| Service | Extends BaseService | Error Handling |
|---------|-------------------|----------------|
| `OrderService` | ✅ | `safeCall()` — typed errors |
| `CompanyService` | ✅ | `safeCall()` — typed errors |
| `ReferralService` | ✅ | `safeCall()` — typed errors |
| `TokenService` | ✅ | `safeCall()` — typed errors |
| `GamificationService` | ✅ | `safeCall()` — typed errors |
| `ShiftSchedulingService` | ✅ | `safeCall()` — typed errors |
| `ScheduleService` | ✅ | `safeCall()` — typed errors |
| **~40 other services** | ❌ | Raw `Supabase.instance.client` + ad-hoc try/catch |

### Vi phạm:
```dart
// ❌ HIỆN TẠI — task_service.dart (374 dòng)
class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;  // ❌ Hardcoded
  
  Future<List<Task>> getTasks(String companyId) async {
    try {
      final response = await _supabase.from('tasks')...
    } catch (e) {
      throw Exception('Failed to load tasks: $e');  // ❌ Generic exception
    }
  }
}
```

```dart
// ✅ CHUẨN — Nên extend BaseService
class TaskService extends BaseService {
  Future<List<Task>> getTasks(String companyId) async {
    return safeCall(
      operation: 'getTasks',
      action: () async {
        final data = await client.from('tasks')
            .select().eq('company_id', companyId);
        return (data as List).map((e) => Task.fromJson(e)).toList();
      },
    );
  }
}
```

---

## PHẦN 7: DEPENDENCY INJECTION — ⚠️ 4/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Dùng DI nào | ⚠️ | Riverpod providers + constructor hardcode |
| Service/Repo được inject vào ViewModel | ⚠️ | Providers `ref.read()` services, nhưng nhiều services tự khởi tạo |
| Instance khởi tạo trực tiếp trong View | ❌ VI PHẠM | Pages tạo Service instances: `GeminiService()`, `EmployeeAuthService()` |
| Singleton lạm dụng | ⚠️ | `ErrorHandler` dùng singleton; `Supabase.instance.client` khắp nơi |
| DI swap được cho testing | ❌ | Không có abstract interfaces → không mock được |

### Vi phạm cụ thể:
```dart
// ❌ HIỆN TẠI — dual_login_page.dart
class _DualLoginPageState extends ConsumerState<DualLoginPage> {
  final _geminiService = GeminiService();       // ❌ Hardcode trong View
  final _authService = EmployeeAuthService();   // ❌ Hardcode trong View
}
```

```dart
// ✅ CHUẨN — Inject qua Riverpod provider
final geminiServiceProvider = Provider((ref) => GeminiService());
final authServiceProvider = Provider((ref) => EmployeeAuthService());

// Trong View → chỉ ref.read(geminiServiceProvider)
```

---

## PHẦN 8: ERROR HANDLING — ⚠️ 5/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Result/Either pattern | ❌ | Không có. Dùng throw/catch |
| API errors map thành domain errors | ⚠️ | `BaseService.safeCall()` map PostgrestException → AppError, nhưng chỉ 7 services |
| try-catch trong View layer | ❌ VI PHẠM | Pages chứa `try-catch` blocks trực tiếp |
| Error boundary/fallback UI | ✅ | Có `ErrorBoundary` widget wrap toàn app |
| Network/timeout/auth errors xử lý riêng | ✅ | AppError hierarchy: NetworkError, AuthenticationError, ValidationError, PermissionError, SystemError |

### Điểm mạnh:
- **`AppError` hierarchy** được thiết kế tốt (`core/errors/app_errors.dart`, 180 dòng):
  - `ErrorSeverity`: low, medium, high, critical
  - `ErrorCategory`: network, authentication, validation, permission, system, unknown
  - `userMessage` getter cho từng category
  - `shouldReport` flag tự động cho high/critical
- **`ErrorHandler`** singleton có listener pattern + auto-convert exceptions
- **`ErrorBoundary`** widget wrap app level
- **LongSangErrorReporter** — auto-fix error reporting

### Điểm yếu:
- Chỉ 7/47 services sử dụng hệ thống error handling chuẩn
- ~40 services throw raw `Exception('...')` — mất toàn bộ error metadata
- Không có `Result<T, E>` pattern → caller phải try-catch everywhere

### Code Example — Result Pattern đề xuất:
```dart
// ✅ ĐỀ XUẤT — Result pattern
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Sử dụng trong Repository:
class OrderRepository {
  Future<Result<List<Order>>> getOrders(String companyId) async {
    try {
      final orders = await _service.getOrders(companyId);
      return Success(orders);
    } on AppError catch (e) {
      return Failure(e);
    }
  }
}

// Sử dụng trong ViewModel:
final result = await _repo.getOrders(companyId);
switch (result) {
  case Success(:final data):
    state = OrderFormState(orders: data);
  case Failure(:final error):
    state = OrderFormState.error(error.userMessage);
}
```

---

## PHẦN 9: NAVIGATION & ROUTING — ✅ 7/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Navigation: GoRouter 14.8 | ✅ | Phiên bản mới, được Flutter team khuyến nghị |
| Routes define tập trung | ✅ | `AppRoutes` class + `appRouterProvider` tập trung trong `app_router.dart` |
| Deep linking support | ✅ | GoRouter native support deep linking |
| Navigation logic ở đâu | ✅ | Trong router config, không hardcode trong pages |
| Auth guard / route protection | ✅ | `redirect` logic trong GoRouter check `authState.isAuthenticated` |

### Điểm cần cải thiện:
- **`app_router.dart` = 709 dòng** — nên tách thành route modules
- Routes dùng string constants (tốt) nhưng chưa type-safe hoàn toàn
- Nên tách route config theo feature module

---

## PHẦN 10: TESTING READINESS — ❌ 2/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Unit tests cho ViewModels | ❌ | Không có ViewModel → Không có test |
| Unit tests cho Repositories | ❌ | 1 Repository, 0 tests |
| Service mockable (abstract class) | ❌ | 0 abstract interfaces |
| Widget tests cho Views | ⚠️ | 1 widget test (`widget_test.dart`) |
| Integration tests | ⚠️ | 5 integration test files + Python E2E |
| Test coverage | ❌ | ~3% (15 test files / 502 source files) |
| Well-defined inputs/outputs | ❌ | Hầu hết classes hard-coupled |

### Test inventory hiện tại:
```
test/
├── constants/roles_test.dart
├── models/                          # ✅ 7 model tests
│   ├── attendance_test.dart
│   ├── business_type_test.dart
│   ├── company_test.dart
│   ├── staff_test.dart
│   ├── user_test.dart
│   └── token/ (2 files)
├── pages/ceo/company_details_test.dart
├── services/                        # ⚠️ 2 service tests
│   ├── attendance_service_test.dart
│   └── token_service_test.dart
├── features_test.dart
├── service_integration_test.dart
├── task_features_test.dart
└── widget_test.dart

integration_test/                    # ⚠️ 5 files
├── app_test.dart
├── create_employee_test.dart
├── employee_flow_test.dart
├── qa_complete_test.dart
└── qa_test_runner.dart
```

### Blockers cho testing:
1. **Không có abstract interfaces** → Không mock được Services
2. **Pages chứa business logic** → Không unit test được logic
3. **Direct `Supabase.instance.client`** → Không test offline
4. **`BaseService.mockClient`** setter tồn tại nhưng hầu hết services không extend BaseService

---

## PHẦN 11: CODE QUALITY & CONVENTIONS — ⚠️ 4/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| flutter_lints | ✅ | `flutter_lints: ^6.0.0` trong dev_dependencies |
| Naming conventions nhất quán | ⚠️ | Không theo `feature_view.dart` / `feature_view_model.dart`. Dùng `_page.dart` |
| File > 300 dòng cần refactor | ❌ VI PHẠM | **228/502 files (45%)** vượt 300 dòng |
| Single Responsibility Principle | ❌ VI PHẠM | `auth_provider.dart` = 1,017 dòng God class |
| Dead code / unused imports | ⚠️ | `shared/` và `mixins/` folders trống; `core/network/`, `core/repositories/` trống |
| Hardcoded strings/colors/dimensions | ⚠️ | `AppColors` constants ✅, nhưng nhiều hardcoded strings trong pages |

### Top 10 largest files:

| Dòng | File | Vấn đề |
|------|------|--------|
| 3,317 | `pages/customers/customer_detail_page.dart` | God Page — View + Logic + Data |
| 3,233 | `pages/ceo/service/service_ceo_layout.dart` | God Layout |
| 2,919 | `pages/ceo/company_details_page.dart` | God Page |
| 2,735 | `business_types/service/layouts/service_manager_layout.dart` | God Layout |
| 2,207 | `business_types/distribution/pages/manager/referrers_page.dart` | God Page |
| 2,088 | `business_types/distribution/pages/sales/journey_plan_page.dart` | God Page |
| 2,025 | `pages/super_admin/super_admin_main_layout.dart` | God Layout |
| 1,937 | `business_types/distribution/pages/driver/driver_deliveries_page.dart` | God Page |
| 1,935 | `widgets/task/task_board.dart` | God Widget |
| 1,920 | `pages/ceo/company/accounting_tab.dart` | God Tab |

### Tốt:
- `AppColors` — centralized color constants (263 dòng, tổ chức theo semantic purpose)
- `AppTheme` — centralized theme
- `AppConstants` — centralized constants
- `AppLogger` — structured logging
- `equatable` package cho models

---

## PHẦN 12: SCALABILITY & PERFORMANCE — ⚠️ 4/10

### Đánh giá chi tiết

| Tiêu chí | Trạng thái | Ghi chú |
|-----------|-----------|---------|
| Scale 10x users | ⚠️ | Supabase handles scaling, nhưng no caching layer → excessive API calls |
| Lazy loading cho routes | ✅ | GoRouter supports lazy route loading |
| Pagination cho danh sách dài | ⚠️ | Một số pages load toàn bộ data, không pagination |
| Image caching | ✅ | `cached_network_image: ^3.3.0` |
| Memory leak tiềm ẩn | ⚠️ | StreamControllers trong realtime services, StreamSubscriptions trong pages |

### Memory leak risks:
- `realtime_notification_service.dart` — 3 `StreamController.broadcast()` cần dispose đúng
- `sales_journey_map_page.dart` — `StreamSubscription<Position>? _positionStream`
- `driver_journey_map_page.dart` — `StreamSubscription<Position>? _positionStream`
- `auth_provider.dart` — `StreamSubscription<dynamic>? _authSubscription`

### Performance concerns:
- **No Repository caching** — mỗi lần navigate lại page → re-fetch từ Supabase
- **No offline support** — `connectivity_plus` installed nhưng chưa có offline-first strategy
- **Large widget trees** — 3,000+ line pages rebuild toàn bộ khi setState

---

## 🔴 CRITICAL (Cần sửa ngay)

1. **Không có ViewModel layer** — Toàn bộ app thiếu MVVM. 502 files không có 1 ViewModel.
2. **Pages chứa business logic + DB queries** — `order_form_page.dart` (1,871 dòng) gọi thẳng `Supabase.instance.client`
3. **Không có Repository layer** — Chỉ 1/47 data types có Repository (`DocumentsRepository`)
4. **45% files vượt 300 dòng** — 228 files, top file 3,317 dòng. God classes vi phạm SRP
5. **1,170+ setState calls** — Business logic rải rác trong 181 StatefulWidget files
6. **~3% test coverage** — 15 tests cho 502 source files, không mock được services

---

## 🟡 IMPORTANT (Nên sửa sớm)

1. **40/47 services không extend BaseService** — Error handling không đồng nhất
2. **0 abstract interfaces** cho services — Không mock, không swap, không test
3. **auth_provider.dart = 1,017 dòng God Provider** — Cần tách thành 4-5 providers nhỏ
4. **Widgets gọi Supabase trực tiếp** — `customer_visits_sheet.dart`, `customer_debt_sheet.dart`, etc.
5. **app_router.dart = 709 dòng** — Cần tách thành route modules
6. **Không có Result pattern** — Error handling dùng throw/catch tràn lan

---

## 🟢 NICE TO HAVE (Cải thiện dần)

1. **Thêm offline-first strategy** — Riverpod + local caching trong Repository
2. **Pagination cho tất cả list views** — Tránh load toàn bộ data
3. **Tách `business_types/` thành feature modules** — Mỗi business type = 1 package
4. **Naming conventions** — Chuyển từ `_page.dart` sang `_view.dart` + `_view_model.dart`
5. **Dọn folders trống** — `shared/`, `mixins/`, `core/network/`, `core/repositories/`
6. **Type-safe routing** — GoRouter TypedRoutes thay vì string-based

---

## 📋 MIGRATION PLAN

> Ưu tiên theo impact × effort. Thực hiện incremental — không break features hiện tại.

### Phase 1: Foundation (2-3 tuần)

**Bước 1: Tạo Result pattern + update BaseService**
- Effort: Thấp (1-2 ngày)
- Impact: Cao — tất cả code mới sẽ dùng
- Tạo `core/common/result.dart`
- Tất cả service mới phải return `Result<T>`

**Bước 2: Tạo abstract interfaces cho top 5 services**
- Effort: Trung bình (2-3 ngày)
- Impact: Cao — unlock testing
- `IOrderService`, `ITaskService`, `IEmployeeService`, `ICompanyService`, `IAuthService`

**Bước 3: Migrate tất cả services → extends BaseService**
- Effort: Trung bình (3-5 ngày)
- Impact: Cao — error handling đồng nhất
- Priority: Services có nhiều try-catch nhất trước

### Phase 2: Repository Layer (2-3 tuần)

**Bước 4: Tạo top 5 Repositories**
- Effort: Trung bình (5-7 ngày)
- `UserRepository`, `CompanyRepository`, `OrderRepository`, `TaskRepository`, `EmployeeRepository`
- Mỗi Repository wrap Service, thêm caching logic

**Bước 5: Wire Repositories vào Riverpod**
- Effort: Thấp (1-2 ngày)
- Tạo `repositoryProviders.dart`
- Update existing providers để dùng Repository thay vì Service trực tiếp

### Phase 3: MVVM Migration (4-8 tuần, incremental)

**Bước 6: Tách auth_provider.dart thành ViewModels**
- Effort: Cao (3-5 ngày)
- `AuthViewModel`, `SessionViewModel`, `MultiAccountViewModel`
- Giữ backward compatibility cho pages đang dùng

**Bước 7: Migrate 1 feature pilot → full MVVM**
- Effort: Trung bình (3-5 ngày)
- Chọn: Orders (business-critical, moderate complexity)
- Tạo `OrderFormViewModel`, `OrderListViewModel`
- Refactor `order_form_page.dart` 1,871 dòng → ~200 dòng View

**Bước 8: Migrate God Pages (>1500 dòng)**
- Effort: Cao (2-3 tuần)
- Từng page một: extract ViewModel → extract reusable widgets
- Target: mỗi page < 300 dòng

### Phase 4: Testing & Polish (Liên tục)

**Bước 9: Viết tests cho ViewModels + Repositories mới**
- Effort: Liên tục
- Target: 60% coverage cho business logic layer
- Mock services qua abstract interfaces

**Bước 10: Restructure folders**
- Effort: Trung bình (3-5 ngày) — sau khi Phase 3 xong
- Di chuyển sang cấu trúc chuẩn bên dưới
- Update tất cả import paths

---

## 📁 CẤU TRÚC THƯ MỤC ĐỀ XUẤT

```
lib/
├── main.dart
├── config/                          # App configuration
│   ├── env/
│   │   ├── app_env.dart
│   │   ├── sentry_config.dart
│   │   └── supabase_config.dart
│   ├── routes/
│   │   ├── app_router.dart          # Main router
│   │   ├── auth_routes.dart         # Auth route module
│   │   ├── ceo_routes.dart          # CEO route module
│   │   ├── staff_routes.dart
│   │   └── route_guards.dart
│   └── di/
│       ├── service_providers.dart   # Service DI
│       ├── repository_providers.dart
│       └── viewmodel_providers.dart
│
├── data/                            # Data layer — organized by TYPE
│   ├── repositories/                # Source of truth per data type
│   │   ├── auth_repository.dart
│   │   ├── company_repository.dart
│   │   ├── order_repository.dart
│   │   ├── employee_repository.dart
│   │   ├── task_repository.dart
│   │   ├── customer_repository.dart
│   │   ├── payment_repository.dart
│   │   └── document_repository.dart
│   └── services/                    # External system communication
│       ├── base_service.dart
│       ├── auth_service.dart
│       ├── company_service.dart
│       ├── order_service.dart
│       ├── employee_service.dart
│       ├── task_service.dart
│       ├── ai_service.dart
│       ├── notification_service.dart
│       └── ...
│
├── domain/                          # Domain models (shared across layers)
│   └── models/
│       ├── user.dart
│       ├── company.dart
│       ├── order.dart
│       ├── employee_user.dart
│       ├── task.dart
│       ├── result.dart              # Result<T> sealed class
│       └── errors/
│           ├── app_errors.dart
│           └── error_handler.dart
│
├── ui/                              # UI layer — organized by FEATURE
│   ├── core/                        # Shared UI components
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── app_colors.dart
│   │   ├── widgets/                 # Reusable widgets
│   │   │   ├── error_boundary.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── shimmer_loading.dart
│   │   │   └── keyboard_dismisser.dart
│   │   └── layouts/                 # Shared layout shells
│   │       ├── main_layout.dart
│   │       └── bottom_navigation.dart
│   │
│   ├── auth/                        # Auth feature
│   │   ├── login_view.dart
│   │   ├── login_view_model.dart
│   │   ├── signup_view.dart
│   │   └── signup_view_model.dart
│   │
│   ├── dashboard/                   # Role-based dashboards
│   │   ├── ceo/
│   │   │   ├── ceo_dashboard_view.dart
│   │   │   └── ceo_dashboard_view_model.dart
│   │   ├── manager/
│   │   └── staff/
│   │
│   ├── orders/                      # Orders feature
│   │   ├── order_list_view.dart
│   │   ├── order_list_view_model.dart
│   │   ├── order_form_view.dart
│   │   ├── order_form_view_model.dart
│   │   └── widgets/                 # Feature-specific widgets
│   │       └── order_item_card.dart
│   │
│   ├── employees/
│   ├── customers/
│   ├── tasks/
│   ├── payments/
│   ├── gamification/
│   ├── token/
│   └── ...
│
├── business_types/                  # Business-specific modules (optional packages)
│   ├── distribution/
│   ├── manufacturing/
│   └── service/
│
└── utils/                           # Pure utilities (no business logic)
    ├── app_logger.dart
    ├── error_tracker.dart
    └── performance_monitor.dart
```

---

## 💻 CODE EXAMPLES

### Example 1: Tách God Page → MVVM (Customer Detail)

**BEFORE — `customer_detail_page.dart` (3,317 dòng):**
```dart
class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadAllData();  // ❌ Gọi 5+ API calls trong View
  }
  
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final customer = await Supabase.instance.client
          .from('customers').select().eq('id', widget.customerId).single();
      final orders = await Supabase.instance.client
          .from('orders').select().eq('customer_id', widget.customerId);
      // ... 200+ dòng data fetching logic
      setState(() {
        _customer = customer;
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // ... 2,500+ dòng widget code + business logic lẫn lộn
  }
}
```

**AFTER — MVVM (3 files, mỗi file < 200 dòng):**

```dart
// 1. customer_detail_view_model.dart
@riverpod
class CustomerDetailViewModel extends _$CustomerDetailViewModel {
  @override
  Future<CustomerDetailState> build(String customerId) async {
    final repo = ref.read(customerRepositoryProvider);
    final customer = await repo.getCustomer(customerId);
    final orders = await repo.getCustomerOrders(customerId);
    final payments = await repo.getCustomerPayments(customerId);
    
    return CustomerDetailState(
      customer: customer,
      orders: orders,
      payments: payments,
    );
  }
  
  Future<void> updateCustomer(Customer updated) async {
    state = const AsyncLoading();
    final repo = ref.read(customerRepositoryProvider);
    final result = await repo.updateCustomer(updated);
    switch (result) {
      case Success(:final data):
        state = AsyncData(state.value!.copyWith(customer: data));
      case Failure(:final error):
        state = AsyncError(error, StackTrace.current);
    }
  }
}

// 2. customer_detail_state.dart (Freezed hoặc manual)
class CustomerDetailState {
  final Customer customer;
  final List<Order> orders;
  final List<Payment> payments;
  const CustomerDetailState({
    required this.customer,
    required this.orders,
    required this.payments,
  });
  CustomerDetailState copyWith({...}) => ...;
}

// 3. customer_detail_view.dart (~200 dòng)
class CustomerDetailView extends ConsumerWidget {
  final String customerId;
  const CustomerDetailView({required this.customerId, super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailViewModelProvider(customerId));
    
    return state.when(
      data: (data) => _CustomerDetailContent(state: data),
      loading: () => const CustomerDetailShimmer(),
      error: (e, _) => ErrorDisplay(
        error: e,
        onRetry: () => ref.invalidate(customerDetailViewModelProvider(customerId)),
      ),
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  final CustomerDetailState state;
  const _CustomerDetailContent({required this.state});
  
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CustomerInfoHeader(customer: state.customer),
        OrdersSection(orders: state.orders),
        PaymentsSection(payments: state.payments),
      ],
    );
  }
}
```

### Example 2: Service với Abstract Interface

```dart
// ✅ ĐỀ XUẤT — abstract interface cho testability

// data/services/i_order_service.dart
abstract class IOrderService {
  Future<List<Order>> getOrders(String companyId);
  Future<Order> createOrder(Order order);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
}

// data/services/order_service.dart
class OrderService extends BaseService implements IOrderService {
  @override
  Future<List<Order>> getOrders(String companyId) async {
    return safeCall(
      operation: 'getOrders',
      action: () async {
        final data = await client.from('orders')
            .select('*, order_items(*)')
            .eq('company_id', companyId)
            .order('created_at', ascending: false);
        return (data as List).map((e) => Order.fromJson(e)).toList();
      },
    );
  }
}

// test/services/mock_order_service.dart
class MockOrderService implements IOrderService {
  @override
  Future<List<Order>> getOrders(String companyId) async {
    return [Order.mock()];  // ✅ Easy to mock
  }
}
```

### Example 3: Result Pattern

```dart
// domain/models/result.dart
sealed class Result<T> {
  const Result();
  
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) {
    return switch (this) {
      Success(:final data) => success(data),
      Failure(:final error) => failure(error),
    };
  }
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Extension để dùng trong Repository
extension ResultExtension<T> on Future<T> {
  Future<Result<T>> toResult() async {
    try {
      return Success(await this);
    } on AppError catch (e) {
      return Failure(e);
    } catch (e, stack) {
      return Failure(SystemError(
        message: e.toString(),
        stackTrace: stack,
      ));
    }
  }
}
```

---

## TÓM TẮT

| Metric | Giá trị |
|--------|---------|
| **Tổng điểm** | **46/120 (38%)** |
| **ViewModels** | 0 |
| **Repositories** | 1 (DocumentsRepository) |
| **Services extending BaseService** | 7/47 (15%) |
| **Abstract interfaces** | 0 |
| **Files > 300 dòng** | 228/502 (45%) |
| **Largest file** | 3,317 dòng |
| **setState calls** | 1,170+ across 181 files |
| **Test coverage** | ~3% |
| **God Provider** | auth_provider.dart (1,017 dòng) |

**Ưu tiên #1:** Tạo Result pattern + abstract interfaces → unlock testing  
**Ưu tiên #2:** Tạo Repository layer cho top 5 data types  
**Ưu tiên #3:** MVVM migration bắt đầu từ Orders feature (pilot)  
**Ưu tiên #4:** Tách God Pages (>1500 dòng) thành View + ViewModel + Widgets
