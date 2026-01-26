# Distribution Manager Layout Refactoring Plan

## Vấn đề hiện tại
File `distribution_manager_layout.dart` đã phình to tới ~7700 dòng, khó maintain và vi phạm Single Responsibility Principle.

## Cấu trúc đề xuất

### 1. Layout chính (giữ ~500 dòng)
```
lib/layouts/distribution_manager_layout.dart
```
- Chỉ chứa `DistributionManagerLayout` class
- AppBar, Drawer, BottomNav
- Import các page từ thư mục con

### 2. Các Page đã được tách ra
```
lib/pages/distribution_manager/
├── distribution_manager_pages.dart      # Barrel export
├── distribution_dashboard_page.dart     # ✅ Đã tách
├── orders_management_page.dart          # ✅ Đã tách
├── customers_page.dart                  # 📝 Cần tách
├── inventory_page.dart                  # 📝 Cần tách
└── reports_page.dart                    # 📝 Cần tách
```

### 3. Role Bodies (embedded layouts)
```
lib/layouts/distribution_role_bodies/
├── sales_layout_body.dart               # 📝 Cần tách
├── warehouse_layout_body.dart           # 📝 Cần tách
├── driver_layout_body.dart              # 📝 Cần tách
├── cskh_layout_body.dart                # 📝 Cần tách
└── finance_layout_body.dart             # 📝 Cần tách
```

### 4. Shared Widgets
```
lib/widgets/distribution/
├── order_detail_sheet.dart              # ✅ Đã trong orders_management_page
├── customer_form_sheet.dart             # 📝 Cần tách
├── customer_order_history_sheet.dart    # 📝 Cần tách
├── product_detail_sheet.dart            # 📝 Cần tách
├── add_product_sheet.dart               # 📝 Cần tách
├── edit_product_sheet.dart              # 📝 Cần tách
└── adjust_stock_sheet.dart              # 📝 Cần tách
```

## Các file đã được tách

### distribution_dashboard_page.dart (~500 dòng)
- `DistributionDashboardPage` - Dashboard cơ bản
- `DistributionDashboardPageWithRoleSwitcher` - Dashboard với role switcher

### orders_management_page.dart (~800 dòng)
- `OrdersManagementPage` - Trang quản lý đơn hàng
- `OrderListByStatus` - List đơn hàng theo status
- `OrderDetailSheet` - Sheet chi tiết đơn hàng

## Cách sử dụng

Trong `distribution_manager_layout.dart`, import:

```dart
import '../pages/distribution_manager/distribution_manager_pages.dart';
```

Thay thế:
```dart
// OLD (private class trong cùng file)
const _DistributionDashboardPageWithRoleSwitcher()

// NEW (public class từ file riêng)
DistributionDashboardPageWithRoleSwitcher(
  onSwitchRole: (role) => setState(() => _currentView = role),
)
```

## Tiếp tục refactoring

Để hoàn thành việc refactoring, cần:

1. **Tách Customers Page** (~800 dòng)
   - `CustomersPage`
   - `CustomerFormSheet`
   - `CustomerOrderHistorySheet`
   - `SliverSearchBarDelegate`

2. **Tách Inventory Page** (~1200 dòng)
   - `InventoryPage`
   - `ProductDetailSheet`
   - `AddProductSheet`
   - `EditProductSheet`
   - `AdjustStockSheet`

3. **Tách Reports Page** (~200 dòng)
   - `ReportsPage`

4. **Tách Role Bodies** (~2000 dòng)
   - `SalesLayoutBody` + content pages
   - `WarehouseLayoutBody` + content pages
   - `DriverLayoutBody` + content pages
   - `CSKHLayoutBody` + content pages
   - `FinanceLayoutBody` + content pages

## Notes
- Các class đã được đổi từ private (`_ClassName`) sang public (`ClassName`)
- Thêm `super.key` cho các constructors
- Update imports trong các file khác nếu cần
