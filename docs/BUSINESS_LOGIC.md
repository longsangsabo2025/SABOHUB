# SABOHUB Business Logic & Rules

> Core business rules, role permissions, workflow flows.
> Cập nhật: 2026-02-07

## 1. Business Types

### Enum Definition (`models/business_type.dart`)
```dart
enum BusinessType {
  billiards, restaurant, hotel, cafe, retail,  // Entertainment group
  distribution, manufacturing                   // Distribution group
}
```

### Routing Logic
- `isDistribution` = `distribution` HOẶC `manufacturing`  
- `isEntertainment` = tất cả còn lại
- Routing quyết định dựa trên: `role` + `businessType` + `department`

## 2. Roles & Permissions

### Role Hierarchy
```
SUPER_ADMIN (Platform level - quản lý toàn bộ hệ thống)
  └── CEO (Company level - quản lý tất cả company mình sở hữu)
       └── MANAGER (Branch level - quản lý chi nhánh)
            └── SHIFT_LEADER (Team level - quản lý ca/nhóm)
                 └── STAFF (Individual - nhân viên)
                      ├── department: sales
                      ├── department: warehouse
                      ├── department: delivery / driver
                      ├── department: customer_service
                      └── department: finance
  DRIVER (Delivery role - giao hàng)
  WAREHOUSE (Warehouse role - kho)
  FINANCE (Finance role - kế toán)
```

### Role → Feature Access Matrix (Distribution)

| Feature | SuperAdmin | CEO | Manager | Staff-Sales | Staff-Warehouse | Staff-Driver | Staff-CSKH | Staff-Finance |
|---------|-----------|-----|---------|------------|----------------|-------------|-----------|--------------|
| View all companies | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Manage employees | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create orders | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Manage inventory | ❌ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| View deliveries | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Manage customer tickets | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| View financials | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| AI Assistant | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Task management | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |

### Distribution Layouts

| Layout | Department | Tab Count | Tabs |
|--------|-----------|-----------|------|
| DistributionManagerLayout | manager | 4+ | Dashboard, Orders, Customers, Inventory, Reports, Referrers |
| DistributionSalesLayout | sales | 4 | Dashboard, Orders, Customers, Create Order |
| DistributionWarehouseLayout | warehouse | 3 | Dashboard, Inventory, Picking/Packing |
| DistributionDriverLayout | delivery | 3 | Deliveries, Route, History |
| DistributionCustomerServiceLayout | customer_service | 4 | Dashboard, Tickets, Customers, Profile |
| DistributionFinanceLayout | finance | 7 | Dashboard, Orders, Invoices, Payments, Receivables, Profile |

## 3. Order Workflow

### Status Flow
```
draft → pending_approval → confirmed → processing → ready → completed
  ↓                  ↓                                 ↓
  cancelled      cancelled                         cancelled
```

### Payment Status Flow
```
unpaid → pending → partial → paid
  ↓                           ↓
  debt                    refunded
  ↓
  pending_transfer
```

### Delivery Status Flow
```
pending → awaiting_pickup → delivering → delivered
```

### Order Creation Flow
1. Sales staff creates order (`status: draft`)
2. Manager approves (`status: confirmed` hoặc `pending_approval`)
3. Warehouse picks and packs (`status: processing` → `ready`)
4. Driver picks up (`delivery_status: awaiting_pickup`)
5. Driver delivers (`delivery_status: delivering` → `delivered`)
6. Finance confirms payment (`payment_status: paid`)
7. Order completes (`status: completed`)

## 4. Inventory Workflow

### Movement Types
- `inbound`: Nhập kho (from supplier, production, return)
- `outbound`: Xuất kho (for order, sample, damaged)
- `adjustment`: Điều chỉnh (kiểm kê)
- `transfer`: Chuyển kho (between warehouses)

### Stock Deduction
- Tự động khi đơn hàng confirmed → `deduct_stock_for_order` RPC
- Manual adjustment qua inventory movement form

## 5. Customer Management

### Customer Types
- `retail`: Khách lẻ
- `wholesale`: Đại lý / Mua sỉ
- `distributor`: Nhà phân phối
- `horeca`: Hotel/Restaurant/Cafe
- `other`: Khác

### Customer Status
- `active`: Đang hoạt động
- `inactive`: Ngừng hoạt động (KHÔNG phải `archived`)
- `blocked`: Bị khóa

### Customer Tier System
- Tier based on revenue/spending
- Affects pricing and credit limits

## 6. Delivery Workflow

### Journey Plan
1. Manager/Sales tạo Journey Plan (`journey_plans`)
2. Thêm stops (`journey_plan_stops`) với sequence
3. Driver bắt đầu (`start_journey` RPC)
4. Driver check-in tại mỗi stop (`journey_checkins`)
5. Driver hoàn thành (`complete_journey` RPC)

### Delivery
1. Order ready → Create delivery (`deliveries`)
2. Assign driver (`driver_id`)
3. Driver starts (`start_delivery` RPC)
4. Driver completes/fails (`complete_delivery` / `fail_delivery` RPC)
5. Proof: `delivery_proof_url`, `delivery_notes`

## 7. Authentication Flow

### Login
```
Email + Password → employee_login RPC → JWT token + employee data
                                        ↓
                                 Save to local storage
                                        ↓
                                 Load on app restart
```

### Employee Creation
```
CEO/Manager → create_employee_with_auth RPC → auth.users record
                                              ↓
                                       employees record (company_id, role, department)
```

### Password Change
```
change_employee_password RPC (KHÔNG phải update_employee_password)
```

## 8. Notification System

### Distribution Notifications (OdoriNotificationService)
- Order status changes
- Delivery updates
- Payment reminders
- Low stock alerts
- Task assignments

### Notification Types
```dart
enum OdoriNotificationType {
  orderCreated, orderConfirmed, orderCompleted, orderCancelled,
  deliveryAssigned, deliveryStarted, deliveryCompleted, deliveryFailed,
  paymentReceived, paymentOverdue,
  stockLow, // ... etc
}
```

## 9. Multi-Company Architecture

### Data Isolation
- Mỗi employee thuộc 1 company (`employees.company_id`)
- RLS filter tất cả queries theo `company_id`
- SuperAdmin bypass RLS

### Company Onboarding
1. CEO signup → creates auth user
2. CEO creates company
3. CEO invites employees (invite_token)
4. Employee onboards → joins company

## 10. Key Business Rules

1. **Một employee chỉ thuộc 1 company** (no multi-tenancy per user)
2. **Order number tự động** via `generate_order_number` RPC
3. **Stock deduction tự động** khi order confirmed
4. **Payment tracking** per order + aggregated per customer (`total_debt`)
5. **GPS tracking** cho driver và staff (attendance check-in)
6. **Warehouse → Main warehouse** concept: `warehouses.is_main = true`
7. **Soft delete**: Dùng `is_active = false` thay vì xóa record
