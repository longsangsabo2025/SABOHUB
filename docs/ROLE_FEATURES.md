# SABOHUB - Role & Feature Inventory

> **MỤC ĐÍCH**: Tài liệu chi tiết tất cả tính năng của từng role trong hệ thống SABOHUB.
> Mỗi role được phân theo business type (Distribution, Manufacturing, Entertainment/Service).
>
> **CẬP NHẬT**: 2026-03-26

---

## Tổng Quan

| Thông số | Giá trị |
|----------|---------|
| Tổng role combinations | 18 |
| Tổng tabs (unique) | ~50 |
| Tổng features | 200+ |
| Business Types | Distribution, Manufacturing, Service (Billiards/F&B/Cafe/Hotel/Retail) |

### Role Hierarchy
```
SUPER_ADMIN (Platform level)
  └── CEO (Company level)
       └── MANAGER (Branch level)
            └── SHIFT_LEADER (Team/Shift level)
                 └── STAFF (Individual level)
                      ├── department: sales
                      ├── department: warehouse
                      ├── department: delivery / driver
                      ├── department: customer_service
                      └── department: finance
  DRIVER (Standalone delivery role)
  WAREHOUSE (Standalone warehouse role)
```

---

## 1. SUPERADMIN

| Layout | Business Type | Tabs |
|--------|--------------|------|
| `super_admin_main_layout.dart` | Platform-wide (không phân biệt) | 7 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Dashboard | `dashboard_rounded` | System overview, health indicator, quick access admin |
| 2 | Companies | `business_rounded` | List/create/edit companies |
| 3 | Users | `people_rounded` | User management, permissions, roles |
| 4 | Bug Reports | `bug_report_outlined` | View/filter bug reports, analytics |
| 5 | System Settings | `settings_rounded` | Platform config, email settings |
| 6 | Audit Logs | `history_rounded` | Activity log, filter by user/action/date, export |
| 7 | Profile | `person_rounded` | Admin profile, change password |

---

## 2. CEO

### 2a. CEO — Generic (Corporation / null)

| Layout | Tabs |
|--------|------|
| `ceo_main_layout.dart` | 4 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_rounded` | KPIs, daily pulse (revenue/orders/deliveries), pending approvals, company cards, AR summary |
| 2 | Quản lý | `business_center_rounded` | **Sub-tabs**: Công ty (subsidiaries), Công việc (tasks/approvals/templates) |
| 3 | Tài chính | `account_balance_rounded` | Revenue analytics, financial reports, budget tracking |
| 4 | Tiện ích | `apps_rounded` | **Sub-tabs**: Tài liệu (documents), AI Center (configure AI), Travis AI (chatbot) |

### 2b. CEO — Distribution

| Layout | Tabs |
|--------|------|
| `distribution_ceo_layout.dart` | 5 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_outlined` | Sales KPIs, order stats, revenue metrics, team performance |
| 2 | Kinh doanh | `shopping_cart_outlined` | Sales performance, customer analytics, order trends, revenue by product/region |
| 3 | Vận hành | `local_shipping_outlined` | Delivery stats, warehouse levels, logistics KPIs, driver performance |
| 4 | Tài chính | `account_balance_outlined` | AR, payment status, cash flow, cost breakdown |
| 5 | Nhiệm vụ | `assignment_outlined` | Team tasks, approvals, employee assignments |

### 2c. CEO — Manufacturing

| Layout | Tabs |
|--------|------|
| `manufacturing_ceo_layout.dart` | 5 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_outlined` | Production KPIs, plan vs actual, quality metrics, cost per unit |
| 2 | Sản xuất | `precision_manufacturing_outlined` | Production orders, scheduled vs actual, efficiency, work order status |
| 3 | Mua hàng | `shopping_bag_outlined` | Purchase orders, supplier performance, material costs |
| 4 | Tài chính | `account_balance_outlined` | Production costs, material costs, operating expenses, profitability |
| 5 | Nhiệm vụ | `assignment_outlined` | Production team tasks, quality approvals |

### 2d. CEO — Service (Billiards/F&B/Cafe/Hotel/Retail)

| Layout | Tabs |
|--------|------|
| `service_ceo_layout.dart` | 5 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | — | Corporation overview, multi-subsidiary view, consolidated metrics |
| 2 | Media Projects | — | Media/content projects, campaign management, budget allocation |
| 3 | Media Command | — | Media strategy, content calendar, campaign execution |
| 4 | Nhiệm vụ | — | Strategic tasks, cross-company initiatives, approvals |
| 5 | Tăng trưởng | — | Growth metrics, strategic KPIs, long-term metrics |

---

## 3. MANAGER

### 3a. Manager — Generic (fallback)

| Layout | Tabs |
|--------|------|
| `manager_main_layout.dart` | 6 |

| # | Tab | Tính năng |
|---|-----|-----------|
| 1 | Dashboard | Team KPIs, daily metrics, alerts |
| 2 | Company Info | Company/department details, contacts |
| 3 | Tasks | Create/assign tasks, track completion, reports |
| 4 | Attendance | Clock-in/out, attendance reports, late/absence logs, export |
| 5 | Analytics | Employee performance, sales analytics, trends |
| 6 | Staff | Staff list, profiles, permissions |

### 3b. Manager — Distribution

| Layout | Tabs |
|--------|------|
| `distribution_manager_layout.dart` | 5 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_outlined` | Daily sales, pending orders, inventory status, team performance |
| 2 | Đơn hàng | `receipt_long_outlined` | All orders, filter by status, create/edit/cancel orders |
| 3 | Khách hàng | `people_outlined` | Customer list, details, purchase history, balance |
| 4 | Kho | `inventory_2_outlined` | Stock levels, low stock alerts, adjustments, movements |
| 5 | Báo cáo | `bar_chart_outlined` | Sales/customer/inventory reports, revenue analysis, export |

### 3c. Manager — Manufacturing

| Layout | Tabs |
|--------|------|
| `manufacturing_manager_layout.dart` | 6 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_outlined` | Production overview, targets vs actual, quality metrics |
| 2 | Sản xuất | `precision_manufacturing_outlined` | Production orders, progress, quality check-ins, reports |
| 3 | Nguyên liệu | `inventory_outlined` | Raw materials, requisitions, stock levels, usage reports |
| 4 | Mua hàng | `shopping_cart_outlined` | Purchase orders, vendor management, price negotiations |
| 5 | Công nợ | `account_balance_wallet_outlined` | Supplier invoices, payment tracking, vendor statements |
| 6 | Chất lượng | `verified_outlined` | Quality metrics, defect reports, trends, compliance |

### 3d. Manager — Service (Billiards/F&B/Cafe/Hotel/Retail)

| Layout | Tabs |
|--------|------|
| `service_manager_layout.dart` | 6 |

| # | Tab | Tính năng |
|---|-----|-----------|
| 1 | Overview | Business overview, daily metrics, staff status, revenue KPIs |
| 2 | Projects | Project list, sessions/events, schedule, team assignments |
| 3 | Team | Staff list, assignments, performance tracking |
| 4 | Attendance | Check-in/out logs, attendance reports, shift tracking |
| 5 | Media | Media/content management, campaign tracking |
| 6 | Staff Performance | Individual performance, KPI tracking, rewards |

---

## 4. SHIFT LEADER

### 4a. Shift Leader — Generic (Distribution/Manufacturing)

| Layout | Tabs |
|--------|------|
| `shift_leader_main_layout.dart` | 6 |

| # | Tab | Tính năng |
|---|-----|-----------|
| 1 | Tasks | View shift tasks, mark complete, task notes |
| 2 | Check-in | Clock in/out, break management, attendance |
| 3 | Messages | Internal messaging, announcements |
| 4 | Team | Team members, shift roster, performance |
| 5 | Reports | Shift reports, activity summary, export |
| 6 | Company Info | Company details, contacts |

### 4b. Shift Leader — Service (Billiards/F&B/Cafe/Hotel/Retail)

| Layout | Tabs |
|--------|------|
| `service_shift_leader_layout.dart` | 6 + FAB |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard_outlined` | Shift overview, today's metrics, staff on duty, revenue |
| 2 | Phiên | `timer_outlined` | Active sessions, create/track sessions |
| 3 | Check-in | `fingerprint_outlined` | Staff attendance, clock in/out |
| 4 | Lịch ca | `calendar_month_outlined` | Shift schedule, staff assignments |
| 5 | Duyệt | `fact_check_outlined` | Review shift reports, approve timesheets |
| 6 | Báo cáo | `bar_chart_outlined` | Shift reports, revenue summary, export |
| FAB | Mở phiên | `play_arrow` | Quick create session |

---

## 5. STAFF — Distribution

### 5a. Staff Sales

| Layout | Department | Tabs |
|--------|-----------|------|
| `distribution_sales_layout.dart` | sales | 6 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `space_dashboard` | Daily KPIs, sales target vs actual, top customers, recent orders |
| 2 | Hành trình | `route` | Daily route/plan, customer visit schedule, check-in, store visits |
| 3 | Hoạt động | `timeline` | Activity timeline, customer interactions, visit notes, photos |
| 4 | Tạo đơn | `add_shopping_cart` | Create order, select customer, add products, set pricing |
| 5 | Đơn hàng | `receipt_long` | My orders list, filter by status, order details, history |
| 6 | Khách hàng | `people` | Customer list, add/edit customer, call, create order |

### 5b. Staff Warehouse

| Layout | Department | Tabs |
|--------|-----------|------|
| `distribution_warehouse_layout.dart` | warehouse | 4 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `space_dashboard` | Daily orders count, picking targets, packing status, KPIs |
| 2 | Nhận đơn | `assignment` | Picking task list, scan items, confirm picking |
| 3 | Đóng gói | `inventory_2` | Packing task list, pack items, print labels, confirm shipment |
| 4 | Tồn kho | `warehouse` | Stock levels, product search, adjustments, low stock alerts |

### 5c. Staff Driver / Delivery

| Layout | Department | Tabs |
|--------|-----------|------|
| `distribution_driver_layout_refactored.dart` | delivery / driver | 4 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Trang chủ | `home` | Daily deliveries count, route summary, today's revenue, pending |
| 2 | Giao hàng | `local_shipping` | 4 sub-tabs: Chờ nhận / Chờ kho / Đang giao / Đã giao. Delivery details, GPS, customer contact |
| 3 | Hành trình | `map` | Route visualization, GPS tracking, distance/time estimate |
| 4 | Lịch sử | `history` | Completed deliveries, date filters, proof of delivery |

### 5d. Staff Customer Service (CSKH)

| Layout | Department | Tabs |
|--------|-----------|------|
| `distribution_customer_service_layout.dart` | customer_service | 3 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard` | Open tickets, complaints, urgent issues, ticket aging, KPIs |
| 2 | Yêu cầu | `support_agent` | Ticket list, create/update/close tickets, assign, add notes |
| 3 | Khách hàng | `people` | Customer list, contact info, interaction history, complaints |

### 5e. Staff Finance

| Layout | Department | Tabs |
|--------|-----------|------|
| `distribution_finance_layout.dart` | finance | 5 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `space_dashboard` | Financial snapshot, receivables, paid/unpaid, overdue, collections |
| 2 | Đơn hàng | `shopping_bag` | Orders by status, invoice/payment status, order value |
| 3 | Hóa đơn | `receipt_long` | Invoice list, details, email/print invoice |
| 4 | Công nợ | `account_balance_wallet` | AR aging, customer balance, overdue tracking, payment reminders |
| 5 | Thu tiền | `payments` | Record payment, payment history, reconciliation |

---

## 6. STAFF — Service (Billiards/F&B/Cafe/Hotel/Retail)

| Layout | Tabs |
|--------|------|
| `service_staff_layout.dart` | 5 + FAB |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Tổng quan | `dashboard` | Daily overview, shift schedule, targets, revenue, tips |
| 2 | Phiên | `timer` | Active sessions, details, history, revenue per session |
| 3 | Báo cáo | `receipt_long` | Daily report, session summary, revenue total, submit |
| 4 | Check-in | `fingerprint` | Clock in/out, attendance status, shift details |
| 5 | Học | `menu_book` | Training materials, courses, certifications, progress |
| FAB | Mở phiên | `play_arrow` | Quick create session |

---

## 7. STAFF — Generic (fallback)

| Layout | Tabs |
|--------|------|
| `staff_main_layout.dart` | 4 |

| # | Tab | Tính năng |
|---|-----|-----------|
| 1 | Check-in | Clock in/out, current shift, break management |
| 2 | Tasks | View assigned tasks, mark complete, details |
| 3 | Messages | Announcements, internal messaging, notifications |
| 4 | Company Info | Company details, contacts |

---

## 8. Standalone Roles

### 8a. Driver (Standalone)

| Layout | Tabs |
|--------|------|
| `driver_main_layout.dart` | 2 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Lộ trình | `local_shipping` | Route details, delivery list, GPS, customer info, delivery confirmation |
| 2 | Lịch sử | `history` | Completed deliveries, history, proof of delivery, date filters |

### 8b. Warehouse (Standalone)

| Layout | Tabs |
|--------|------|
| `warehouse_main_layout.dart` | 2 |

| # | Tab | Icon | Tính năng |
|---|-----|------|-----------|
| 1 | Soạn hàng | `inventory_2` | Order list, pick items, scan SKU/QR, confirm, progress |
| 2 | Tồn kho | `warehouse` | Stock levels, product search, adjustments, movements, QR scanner |

---

## Cross-Role Features

| Feature | Roles có quyền |
|---------|---------------|
| Realtime Notifications | Tất cả roles |
| Profile / Change Password | Tất cả roles |
| Haptic Feedback trên tab | Tất cả layouts |
| Pull-to-Refresh | Hầu hết dashboard pages |
| GPS Tracking | Driver, Sales (store visits) |
| AI Assistant (Travis AI) | CEO (Generic) |
| Gamification / Quests | CEO Dashboard |
| Multi-Subsidiary Switch | CEO |
| Document Management | CEO (Utilities) |
| Store Visit (Check-in/out) | Sales staff |
| Sample Management | Manager, Sales |
| Journey Planning | Sales, Driver |

---

## Ghi Chú
- Entertainment (Service) business types: billiards, restaurant, hotel, cafe, retail
- Distribution business types: distribution, manufacturing
- Routing hub: `role_based_dashboard.dart` quyết định layout dựa trên `role` + `businessType` + `department`
- Layout files nằm tại:
  - Distribution: `lib/business_types/distribution/layouts/`
  - Manufacturing: `lib/business_types/manufacturing/pages/`
  - Service: `lib/pages/` (service_ceo_layout, service_manager_layout, etc.)
  - Shared: `lib/layouts/`, `lib/pages/`
