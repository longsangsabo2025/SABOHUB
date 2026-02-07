# SABOHUB Database Schema Reference

> Supabase PostgreSQL schema cho AI assistant tham chiếu khi audit/develop.
> Cập nhật: 2026-02-07 | Project ID: `dqddxowyikefqcdiioyh` | **142 tables** | 111+ RPCs

---

## Mục lục

1. [CORE Tables (19)](#1-core-tables-19)
2. [CUSTOMER Tables (5)](#2-customer-tables-5)
3. [DISTRIBUTION Tables (25)](#3-distribution-tables-25)
4. [MANUFACTURING Tables (16)](#4-manufacturing-tables-16)
5. [ENTERTAINMENT Tables (2)](#5-entertainment-tables-2)
6. [FINANCE Tables (13)](#6-finance-tables-13)
7. [AI Tables (6)](#7-ai-tables-6)
8. [GPS & Location Tables (3)](#8-gps--location-tables-3)
9. [Distributor Portal Tables (8)](#9-distributor-portal-tables-8)
10. [Store Visits & Surveys Tables (9)](#10-store-visits--surveys-tables-9)
11. [Sell-Through Tables (6)](#11-sell-through-tables-6)
12. [Competitor Tables (3)](#12-competitor-tables-3)
13. [OTHER Tables (28)](#13-other-tables-28)
14. [Bảng KHÔNG TỒN TẠI](#14-bảng-không-tồn-tại-tránh-reference)
15. [Tables Without RLS (22)](#15-tables-without-rls-22)
16. [Key RPCs (111+)](#16-key-rpcs-111)
17. [Column Name Pitfalls](#17-column-name-pitfalls-lỗi-thường-gặp)
18. [CHECK Constraints Reference](#18-check-constraints-reference)

---

## 1. CORE Tables (19)

### `employees` (28 cols) — RLS: YES
Primary user table. Mỗi user là 1 employee thuộc 1 company.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| auth_user_id | uuid UNIQUE | FK → auth.users |
| company_id | uuid | FK → companies |
| branch_id | uuid | FK → branches |
| warehouse_id | uuid | FK → warehouses |
| full_name | text | |
| email | text | |
| phone | text | |
| avatar_url | text | |
| role | text | CHECK: staff, shift_leader, manager, ceo, driver, warehouse, super_admin, finance (case-insensitive) |
| department | text | CHECK: sales, warehouse, delivery, customer_service, finance, production, hr, admin, management, other |
| salary_type | text | CHECK: fixed, hourly |
| employment_type | text | CHECK: full_time, part_time |
| is_active | boolean | DEFAULT true. **KHONG dung `status`** |
| created_at | timestamptz | |

> **CANH BAO**: KHONG co column `status`. Luon dung `is_active`.

### `companies` (26 cols) — RLS: NO
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| name | text | |
| business_type | text | distribution, manufacturing, billiards, restaurant, hotel, cafe, retail |
| is_active | boolean | **KHONG dung `status`** |
| owner_id | uuid | FK → auth.users |
| tax_id, address, phone, email | text | |

### `products` (29 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| company_id | uuid | FK → companies |
| name, sku, unit | text | |
| price, cost_price, selling_price | numeric | CHECK: >= 0 |
| category_id | uuid | FK → product_categories |
| status | text | CHECK: active, inactive, discontinued |
| is_active | boolean | |

### `product_categories` (11 cols) — RLS: YES
### `product_samples` (23 cols) — RLS: NO
CHECK: `feedback_rating` 1-5

### `inventory` (11 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| product_id | uuid | FK → products |
| warehouse_id | uuid | FK → warehouses |
| quantity | numeric | CHECK: >= 0 |
| reserved_quantity | numeric | CHECK: >= 0, <= quantity |
| min_quantity | numeric | Reorder point |

### `inventory_movements` (17 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| product_id, warehouse_id | uuid | |
| quantity | numeric | Positive = in, Negative = out |
| type | text | CHECK: in, out, transfer, adjustment, count |
| reference_type, reference_id | text, uuid | |

### `warehouses` (20 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| company_id | uuid | FK → companies |
| name | text | |
| type | text | CHECK: main, transit, vehicle, virtual |
| is_main | boolean | Main warehouse flag |
| is_active | boolean | |

### `branches` (13 cols) — RLS: YES
### `departments` (11 cols) — RLS: YES
### `employee_documents` (21 cols) — RLS: YES
### `employee_invitations` (16 cols) — RLS: YES
CHECK: `role_type` in CEO, BRANCH_MANAGER, SHIFT_LEADER, STAFF

### `notifications` (10 cols) — RLS: YES
CHECK: `type` in task_assigned, task_status_changed, task_completed, task_overdue, shift_reminder, attendance_issue, system, approval_request, approval_update

### `tasks` (21 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| company_id | uuid | |
| assigned_to | uuid | FK → employees |
| title, description | text | |
| status | text | CHECK: pending, in_progress, completed, cancelled |
| priority | text | CHECK: low, medium, high, urgent |
| category | text | CHECK: general, operations, sales, delivery, inventory, customer_service, maintenance, admin, other |
| progress | integer | CHECK: 0-100 |
| recurrence | text | CHECK: none, daily, weekly, monthly |

### `task_approvals` (14 cols) — RLS: YES
CHECK: `type` in report, budget, proposal, other | `status` in pending, approved, rejected

### `task_attachments` (8 cols) — RLS: NO
### `task_comments` (6 cols) — RLS: YES
### `task_templates` (21 cols) — RLS: YES

### `attendance` (33 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| employee_id | uuid | FK → employees |
| checkin_time, checkout_time | timestamptz | |
| checkin_lat, checkin_lng | double precision | |

---

## 2. CUSTOMER Tables (5)

### `customers` (46 cols) — RLS: YES
| Column | Type | CHECK Values |
|--------|------|-------------|
| id | uuid PK | |
| company_id | uuid | FK → companies |
| name | text | |
| status | text | **active, inactive, blocked** (KHONG co `archived`) |
| type | text | **retail, wholesale, distributor, horeca, other** (KHONG co `agent`, `direct`) |
| tier | text | **diamond, gold, silver, bronze** |
| total_debt | numeric | **KHONG co `total_orders`** |
| payment_terms | integer | CHECK: >= 0 |
| phone, email, address | text | |
| latitude, longitude | double precision | |

### `customer_addresses` (19 cols) — RLS: YES
### `customer_contacts` (13 cols) — RLS: YES
### `customer_payments` (11 cols) — RLS: NO
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| customer_id | uuid | FK → customers |
| order_id | uuid | FK → sales_orders (nullable) |
| amount | numeric | |
| payment_method | text | |
| payment_date | date | |

### `customer_visits` (17 cols) — RLS: YES
CHECK: `purpose` in sales, collection, support, survey, other | `result` in ordered, no_order, not_available, rescheduled

---

## 3. DISTRIBUTION Tables (25)

### `sales_orders` (57 cols) — RLS: YES
Don hang ban. Bang lon nhat.

| Column | Type | CHECK Values |
|--------|------|-------------|
| id | uuid PK | |
| order_number | text UNIQUE | Auto via `generate_order_number` RPC |
| company_id | uuid | FK → companies |
| customer_id | uuid | FK → customers |
| employee_id | uuid | FK → employees (nguoi tao) |
| status | text | **draft, pending_approval, confirmed, processing, ready, completed, cancelled** |
| payment_status | text | **unpaid, pending, partial, paid, refunded, pending_transfer, debt** |
| delivery_status | text | **pending, awaiting_pickup, delivering, delivered** |
| priority | text | **low, normal, high, urgent** |
| source | text | **app, web, zalo, phone, email, walk_in, other** |
| total | numeric | **KHONG PHAI `total_amount`** |
| tax_amount, discount_amount, shipping_fee | numeric | |
| paid_amount | numeric | |
| invoice_printed | boolean | |

> **CANH BAO**: Column ten `total` KHONG PHAI `total_amount`. Day la loi pho bien nhat.

### `sales_order_items` (18 cols) — RLS: YES
CHECK: `quantity` > 0, `unit_price` >= 0, `line_total` >= 0

### `sales_order_history` (8 cols) — RLS: YES
### `sales_routes` (15 cols) — RLS: YES
### `sales_targets` (21 cols) — RLS: YES
### `sales_reports` (13 cols) — RLS: NO
### `sales_rep_locations` (15 cols) — RLS: YES
### `sales_rep_locations_2026_01` (15 cols) — RLS: NO (partition)

### `deliveries` (34 cols) — RLS: YES
| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| order_id | uuid | FK → sales_orders |
| driver_id | uuid | FK → employees |
| status | text | CHECK: **planned, loading, in_progress, completed, cancelled** |
| delivery_address | text | |
| delivery_latitude, delivery_longitude | double precision | |
| delivered_at | timestamptz | |
| delivery_proof_url | text | |
| delivery_notes | text | |

### `delivery_items` (24 cols) — RLS: YES
CHECK: `status` in pending, in_transit, delivered, partial, failed, returned, rescheduled

### `delivery_item_products` (9 cols) — RLS: YES
### `delivery_tracking` (8 cols) — RLS: YES

### `journey_plans` (17 cols) — RLS: YES
### `journey_plan_stops` (17 cols) — RLS: YES
### `journey_checkins` (27 cols) — RLS: YES
### `route_customers` (9 cols) — RLS: YES
### `route_optimization_logs` (19 cols) — RLS: YES

### `payments` (21 cols) — RLS: YES
CHECK: `amount` > 0, `status` in pending/completed/cancelled/bounced, `payment_method` in cash/transfer/check/card/other

### `payment_allocations` (5 cols) — RLS: YES
CHECK: `amount` > 0

### `receivables` (19 cols) — RLS: YES
CHECK: `status` in open/partial/paid/overdue/written_off/disputed | `reference_type` in sales_order/invoice/other/manual | amounts >= 0

### `commission_rules` (17 cols) — RLS: YES
CHECK: `applies_to` in all/role/individual, `commission_percentage` 0-100

### `commission_rule_history` (8 cols) — RLS: NO
### `commissions` (17 cols) — RLS: NO
CHECK: `status` in pending/approved/paid/cancelled

### `referrers` (16 cols) — RLS: NO
CHECK: `status` in active/inactive, `commission_type` in first_order/all_orders

---

## 4. MANUFACTURING Tables (16)

Tat ca bat dau bang prefix `manufacturing_`. Tat ca co RLS: YES

| Table | Cols | Mo ta |
|-------|------|-------|
| `manufacturing_bom` | 20 | Bill of Materials (don pha che) |
| `manufacturing_bom_items` | 10 | Thanh phan trong BOM |
| `manufacturing_materials` | 18 | Nguyen lieu |
| `manufacturing_material_categories` | 6 | Phan loai nguyen lieu |
| `manufacturing_material_inventory` | 11 | Ton kho nguyen lieu |
| `manufacturing_material_transactions` | 14 | Giao dich nguyen lieu |
| `manufacturing_production_orders` | 25 | Lenh san xuat |
| `manufacturing_production_materials` | 12 | Nguyen lieu cho lenh SX |
| `manufacturing_production_output` | 13 | San pham dau ra |
| `manufacturing_purchase_orders` | 25 | Don mua hang |
| `manufacturing_purchase_order_items` | 13 | Chi tiet don mua |
| `manufacturing_purchase_receipts` | 9 | Phieu nhan hang |
| `manufacturing_purchase_receipt_items` | 10 | Chi tiet phieu nhan |
| `manufacturing_payables` | 16 | Cong no phai tra |
| `manufacturing_payable_payments` | 12 | Thanh toan cong no |
| `manufacturing_suppliers` | 21 | Nha cung cap (CHECK: `rating` 1-5) |

---

## 5. ENTERTAINMENT Tables (2)

### `table_sessions` (26 cols) — RLS: YES
Phien choi bida / giai tri.

CHECK: `status` in active/paused/completed/cancelled | `customer_count` > 0 | amounts >= 0

### `menu_items` (17 cols) — RLS: YES
CHECK: `category` in food/beverage/snack/equipment/other | prices >= 0 | stocks >= 0

> **Luu y**: Entertainment chua phat trien nhieu. Chi co 2 bang co ban.

---

## 6. FINANCE Tables (13)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `accounting_transactions` | 14 | YES | Giao dich ke toan. CHECK: type, payment_method, amount >= 0 |
| `bills` | 15 | YES | Hoa don. CHECK: status, total >= 0 |
| `bill_commissions` | 16 | NO | Hoa hong tren bill |
| `chart_of_accounts` | 25 | YES | He thong tai khoan ke toan |
| `financial_statements` | 10 | YES | Bao cao tai chinh |
| `financial_statement_lines` | 16 | YES | Chi tiet BCTC |
| `financial_transactions` | 18 | YES | CHECK: type in revenue/expense/investment/refund |
| `fiscal_periods` | 12 | YES | Ky ke toan. CHECK: start_date < end_date |
| `general_ledger` | 21 | YES | So cai |
| `journal_entries` | 28 | YES | But toan. CHECK: total_debit = total_credit |
| `journal_entry_lines` | 14 | NO | Chi tiet but toan |
| `payrolls` | 13 | YES | Bang luong. CHECK: status in draft/confirmed/paid |
| `salary_structures` | 14 | NO | Co cau luong |

---

## 7. AI Tables (6)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `ai_assistants` | 11 | YES | AI assistant instances |
| `ai_chat_history` | 11 | YES | Lich su chat. CHECK: role in user/assistant/system |
| `ai_messages` | 16 | YES | Tin nhan AI |
| `ai_recommendations` | 18 | YES | Goi y AI. CHECK: priority, status, category |
| `ai_uploaded_files` | 17 | YES | Files uploaded cho AI |
| `ai_usage_analytics` | 8 | YES | Phan tich su dung AI |

---

## 8. GPS & Location Tables (3)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `gps_locations` | 32 | YES | Dia diem GPS. CHECK: category, status |
| `gps_contact_history` | 12 | YES | Lich su lien he GPS |
| `checkins` | 10 | YES | Check-in tai dia diem |

---

## 9. Distributor Portal Tables (8)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `distributor_portals` | 16 | YES | Cong nha phan phoi |
| `distributor_portal_users` | 12 | NO | Users cong NPP |
| `distributor_inventory` | 13 | YES | Ton kho NPP |
| `distributor_price_lists` | 15 | YES | Bang gia NPP |
| `distributor_price_list_items` | 10 | NO | Chi tiet bang gia |
| `distributor_promotions` | 18 | YES | Khuyen mai NPP |
| `distributor_loyalty_points` | 9 | YES | Diem thuong NPP |
| `distributor_loyalty_transactions` | 10 | NO | Giao dich diem thuong |

---

## 10. Store Visits & Surveys Tables (9)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `store_visits` | 25 | YES | Ghe tham cua hang |
| `store_visit_checklist_responses` | 11 | YES | Phan hoi checklist |
| `store_visit_photos` | 12 | YES | Anh ghe tham |
| `store_inventory_checks` | 21 | NO | Kiem tra ton kho cua hang |
| `visit_checklists` | 11 | YES | Checklist ghe tham |
| `visit_checklist_responses` | 10 | YES | Phan hoi checklist |
| `visit_photos` | 11 | YES | Anh ghe tham (v2) |
| `surveys` | 14 | YES | Khao sat |
| `survey_responses` | 13 | YES | Phan hoi khao sat |

---

## 11. Sell-Through Tables (6)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `sell_in_transactions` | 15 | YES | Giao dich sell-in (nhap) |
| `sell_in_items` | 12 | YES | Chi tiet sell-in |
| `sell_out_transactions` | 20 | YES | Giao dich sell-out (ban ra) |
| `sell_out_items` | 8 | YES | Chi tiet sell-out |
| `sell_through_analytics` | 21 | YES | Phan tich sell-through |
| `sell_through_reports` | 18 | YES | Bao cao sell-through |

> **Luu y**: Cac bang sell_in/sell_out DA TON TAI (khac voi thong tin cu noi chua tao).

---

## 12. Competitor Tables (3)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `competitor_tracking` | 23 | YES | Theo doi doi thu |
| `competitor_reports` | 19 | YES | Bao cao doi thu |
| `competitor_observations` | 12 | YES | Quan sat doi thu |

---

## 13. OTHER Tables (28)

| Table | Cols | RLS | Mo ta |
|-------|------|-----|-------|
| `activity_logs` | 10 | YES | Log hoat dong |
| `approval_requests` | 10 | YES | Yeu cau phe duyet. CHECK: type, status |
| `bug_reports` | 9 | YES | Bao loi. CHECK: status |
| `business_documents` | 23 | YES | Tai lieu doanh nghiep |
| `business_targets` | 14 | NO | Muc tieu kinh doanh |
| `checklist_item_responses` | 11 | YES | |
| `checklist_items` | 11 | YES | |
| `collection_schedules` | 15 | YES | Lich thu tien |
| `daily_revenue` | 9 | YES | Doanh thu ngay |
| `daily_work_reports` | 17 | YES | Bao cao cong viec hang ngay |
| `executive_reports` | 14 | YES | Bao cao dieu hanh |
| `labor_contracts` | 23 | YES | Hop dong lao dong |
| `manager_permissions` | 26 | YES | Quyen quan ly |
| `market_analysis` | 11 | NO | Phan tich thi truong |
| `order_items` | 14 | NO | **Entertainment order items** (khac sales_order_items) |
| `orders` | 24 | YES | **Entertainment orders** (khac sales_orders) |
| `pos_materials` | 14 | YES | Vat lieu POS |
| `pos_material_deployments` | 14 | YES | Trien khai vat lieu POS |
| `profiles` | 6 | YES | **KHONG DUNG** (legacy, dung employees) |
| `quick_order_templates` | 12 | YES | Template dat hang nhanh |
| `recurring_task_instances` | 5 | YES | Instance task lap |
| `revenue_summary` | 13 | YES | Tom tat doanh thu. CHECK: period_type |
| `schedules` | 13 | YES | Lich trinh. CHECK: shift_type, status |
| `stock_movements` | 17 | NO | Di chuyen kho |
| `suppliers` | 18 | NO | Nha cung cap (legacy, dung manufacturing_suppliers) |
| `tables` | 9 | YES | Ban (billiards/entertainment). CHECK: status, table_type |
| `users` | 16 | YES | **KHONG DUNG** (legacy, dung employees) |
| `users_with_company` | 1 | NO | **KHONG DUNG** (view/legacy) |

---

## 14. Bang KHONG TON TAI (Tranh Reference)

| Table | Dung thay the |
|-------|--------------|
| `users` (as primary) | `employees` (bang `users` ton tai nhung KHONG dung) |
| `support_tickets` | `tasks` |
| `daily_reports` | `daily_work_reports` |
| `user_settings` | Khong ton tai |
| `stores` | Khong ton tai |
| `documents` | `employee_documents` hoac `business_documents` |
| `company_settings` | `companies` |
| `role_permissions` | `manager_permissions` |

---

## 15. Tables Without RLS (22)

> **Lo hong bao mat**: 22 bang chua co RLS policy.

| Table | Priority |
|-------|----------|
| `companies` | HIGH — core table |
| `commissions` | HIGH — financial data |
| `customer_payments` | HIGH — financial data |
| `referrers` | MEDIUM |
| `bill_commissions` | MEDIUM |
| `journal_entry_lines` | MEDIUM |
| `salary_structures` | MEDIUM |
| `commission_rule_history` | MEDIUM |
| `business_targets` | MEDIUM |
| `market_analysis` | MEDIUM |
| `order_items` | MEDIUM |
| `product_samples` | LOW |
| `sales_reports` | LOW |
| `sales_rep_locations_2026_01` | LOW (partition) |
| `stock_movements` | LOW |
| `store_inventory_checks` | LOW |
| `suppliers` | LOW |
| `task_attachments` | LOW |
| `distributor_loyalty_transactions` | LOW |
| `distributor_portal_users` | LOW |
| `distributor_price_list_items` | LOW |
| `users_with_company` | LOW (legacy) |

---

## 16. Key RPCs (111+)

### Authentication & User
| RPC | Mo ta |
|-----|-------|
| `employee_login(p_email, p_password)` | Login nhan vien |
| `change_employee_password(...)` | Doi mat khau. **KHONG PHAI `update_employee_password`** |
| `create_employee_with_auth(...)` | Tao employee + auth user |
| `create_employee_with_password(...)` | Tao employee voi password |
| `create_employee_by_ceo(...)` | CEO tao employee |
| `hash_password(...)` | Hash password |
| `is_ceo(...)` / `is_ceo_of_company(...)` | Check role CEO |
| `is_manager_or_above(...)` | Check role >= manager |
| `has_permission(...)` | Check permission |
| `get_current_user_role(...)` | Lay role hien tai |
| `get_current_user_company_id(...)` | Lay company_id |
| `get_current_user_branch_id(...)` | Lay branch_id |
| `get_effective_permissions(...)` | Lay quyen hieu luc |
| `create_default_manager_permissions(...)` | Tao quyen mac dinh |
| `custom_access_token_hook(...)` | Hook cho access token |

### Orders & Sales
| RPC | Mo ta |
|-----|-------|
| `generate_order_number(p_company_id)` | Tao ma don hang unique |
| `calculate_order_totals(...)` | Tinh tong don hang |
| `sales_order_items_recalculate(...)` | Tinh lai items |
| `track_order_status_change(...)` | Theo doi thay doi status |
| `get_sales_summary(...)` | Tom tat doanh so |

### Delivery & Journey
| RPC | Mo ta |
|-----|-------|
| `start_delivery(...)` | Bat dau giao hang |
| `complete_delivery(...)` | Hoan thanh giao hang |
| `complete_delivery_debt(...)` | Hoan thanh (ghi no) |
| `complete_delivery_transfer(...)` | Hoan thanh (chuyen khoan) |
| `fail_delivery(...)` | Giao hang that bai |
| `sync_order_delivery_status(...)` | Dong bo status |
| `generate_delivery_number(...)` | Tao ma giao hang |
| `update_delivery_stats(...)` | Cap nhat thong ke |
| `start_journey(...)` | Bat dau hanh trinh |
| `complete_journey(...)` | Hoan thanh hanh trinh |
| `create_journey_plan_from_route(...)` | Tao ke hoach tu route |
| `generate_journey_plan_number(...)` | Tao ma hanh trinh |

### Inventory
| RPC | Mo ta |
|-----|-------|
| `deduct_stock_for_order(...)` | Tru ton kho cho don hang |
| `process_inventory_movement(...)` | Xu ly xuat/nhap kho |
| `get_available_quantity(...)` | Lay SL kha dung |
| `get_total_stock(...)` | Tong ton kho |

### Payments & Receivables
| RPC | Mo ta |
|-----|-------|
| `generate_payment_number(...)` | Tao ma thanh toan |
| `create_receivable_from_order(...)` | Tao cong no tu don |
| `create_manual_receivable(...)` | Tao cong no thu cong |
| `sync_payment_to_receivables(...)` | Dong bo thanh toan <-> cong no |
| `update_receivable_on_payment(...)` | Cap nhat cong no khi tra |
| `update_overdue_receivables(...)` | Cap nhat qua han |
| `update_overdue_payables(...)` | Cap nhat qua han (mfg) |
| `send_overdue_digest_notifications(...)` | Gui thong bao qua han |

### Commissions
| RPC | Mo ta |
|-----|-------|
| `calculate_bill_commissions(...)` | Tinh hoa hong |
| `get_employee_commission_summary(...)` | Tom tat HH nhan vien |

### Manufacturing
| RPC | Mo ta |
|-----|-------|
| `calculate_bom_cost(...)` | Tinh chi phi BOM |
| `create_production_materials(...)` | Tao NL cho lenh SX |
| `update_production_on_output(...)` | Cap nhat khi san xuat xong |
| `generate_production_number(...)` | Tao ma san xuat |
| `generate_po_number(...)` | Tao ma PO |
| `update_po_totals(...)` / `update_po_received_quantity(...)` | Cap nhat PO |
| `update_payable_on_payment(...)` | Cap nhat cong no mfg |
| `get_payables_aging_report(...)` | Bao cao tuoi no |

### Sell-Through
| RPC | Mo ta |
|-----|-------|
| `record_sell_in(...)` | Ghi nhan sell-in |
| `record_sell_out(...)` | Ghi nhan sell-out |
| `calculate_sell_through(...)` | Tinh sell-through rate |
| `generate_sell_in_number(...)` | Tao ma sell-in |
| `generate_sell_out_number(...)` | Tao ma sell-out |
| `update_distributor_inventory_on_sell_in(...)` | Cap nhat ton kho NPP (sell-in) |
| `update_distributor_inventory_on_sell_out(...)` | Cap nhat ton kho NPP (sell-out) |

### Store Visits & Checkins
| RPC | Mo ta |
|-----|-------|
| `check_in_store(...)` / `check_out_store(...)` | Check-in/out cua hang |
| `generate_visit_number(...)` | Tao ma ghe tham |
| `get_today_visit_stats(...)` | Thong ke ghe tham hom nay |
| `generate_checkin_number(...)` | Tao ma checkin |
| `detect_late_checkin(...)` | Phat hien di muon |
| `prevent_duplicate_checkin(...)` | Chong check-in trung |

### Customers
| RPC | Mo ta |
|-----|-------|
| `generate_customer_code(...)` | Tao ma khach hang |
| `update_customer_last_order(...)` | Cap nhat don hang gan nhat |

### Reports & Notifications
| RPC | Mo ta |
|-----|-------|
| `get_daily_reports(...)` | Lay bao cao ngay |
| `submit_daily_report(...)` / `update_daily_report(...)` | Nop/sua bao cao |
| `generate_daily_executive_report(...)` | Tao bao cao dieu hanh |
| `submit_approval_request(...)` | Gui yeu cau phe duyet |
| `notify_task_assignment(...)` | Thong bao giao task |
| `notify_approval_request_created(...)` / `notify_approval_status_update(...)` | Thong bao phe duyet |
| `notify_report_submitted(...)` | Thong bao nop bao cao |
| `notify_telegram_event(...)` | Gui event Telegram |
| `update_notification_read_at(...)` | Danh dau da doc |

### AI
| RPC | Mo ta |
|-----|-------|
| `get_or_create_ai_assistant(...)` | Lay/tao AI assistant |
| `get_chat_session(...)` / `get_recent_chat_sessions(...)` | Lay phien chat |
| `cleanup_old_chat_history(...)` | Don chat cu |
| `get_ai_usage_stats(...)` / `get_ai_total_cost(...)` | Thong ke AI |

### Finance / Accounting
| RPC | Mo ta |
|-----|-------|
| `seed_standard_chart_of_accounts(...)` | Tao he thong TK chuan |
| `generate_journal_entry_number(...)` | Tao so but toan |
| `update_general_ledger_on_post(...)` | Cap nhat so cai |

### Timestamp Triggers (auto-generated)
`update_accounting_timestamp`, `update_accounting_updated_at`, `update_chat_history_timestamp`, `update_daily_work_reports_updated_at`, `update_distributor_portal_timestamp`, `update_employee_documents_updated_at`, `update_employee_invitations_updated_at`, `update_employees_updated_at`, `update_gps_locations_updated_at`, `update_labor_contracts_updated_at`, `update_manager_permissions_timestamp`, `update_sales_route_timestamp`, `update_store_visit_timestamp`, `update_task_comments_updated_at`, `update_task_template_updated_at`, `update_updated_at_column`, `update_business_documents_updated_at`, `update_approval_requests_updated_at`

---

## 17. Column Name Pitfalls (Loi Thuong Gap)

| Sai | Dung | Table |
|-----|------|-------|
| `total_amount` | `total` | sales_orders |
| `status` (employees) | `is_active` | employees |
| `status` (companies) | `is_active` | companies |
| `total_orders` (customers) | `total_debt` | customers |
| `archived` (customer status) | `inactive` | customers |
| `agent`, `direct` (customer type) | `wholesale`, `horeca`, `other` | customers |
| `update_employee_password` | `change_employee_password` | RPC |
| `.from('users')` | `.from('employees')` | Supabase query |
| `planned`, `in_progress`, `loading` | Use deliveries.status CHECK values | deliveries |
| `rejected`, `returned` | `cancelled` | sales_orders.status |
| `delivered` (as final order status) | `completed` | sales_orders.status |
| `source: 'manual'` | Use CHECK: app, web, zalo, phone, email, walk_in, other | sales_orders.source |

---

## 18. CHECK Constraints Reference

### employees
- `role`: staff, STAFF, shift_leader, SHIFT_LEADER, manager, MANAGER, ceo, CEO, driver, DRIVER, warehouse, WAREHOUSE, super_admin, SUPER_ADMIN, finance, FINANCE
- `department`: sales, warehouse, delivery, customer_service, finance, production, hr, admin, management, other
- `salary_type`: fixed, hourly
- `employment_type`: full_time, part_time

### sales_orders
- `status`: draft, pending_approval, confirmed, processing, ready, completed, cancelled
- `payment_status`: unpaid, pending, partial, paid, refunded, pending_transfer, debt
- `delivery_status`: pending, awaiting_pickup, delivering, delivered
- `priority`: low, normal, high, urgent
- `source`: app, web, zalo, phone, email, walk_in, other

### customers
- `status`: active, inactive, blocked
- `type`: retail, wholesale, distributor, horeca, other
- `tier`: diamond, gold, silver, bronze

### deliveries
- `status`: planned, loading, in_progress, completed, cancelled

### delivery_items
- `status`: pending, in_transit, delivered, partial, failed, returned, rescheduled

### payments
- `status`: pending, completed, cancelled, bounced
- `payment_method`: cash, transfer, check, card, other

### receivables
- `status`: open, partial, paid, overdue, written_off, disputed
- `reference_type`: sales_order, invoice, other, manual

### tasks
- `status`: pending, in_progress, completed, cancelled
- `priority`: low, medium, high, urgent
- `category`: general, operations, sales, delivery, inventory, customer_service, maintenance, admin, other

### warehouses
- `type`: main, transit, vehicle, virtual

### inventory_movements
- `type`: in, out, transfer, adjustment, count

### orders (entertainment)
- `status`: pending, preparing, ready, completed, cancelled

### table_sessions
- `status`: active, paused, completed, cancelled

### menu_items
- `category`: food, beverage, snack, equipment, other

### schedules
- `shift_type`: morning, afternoon, evening, full_day
- `status`: scheduled, confirmed, absent, late, cancelled

### accounting_transactions
- `type`: revenue, expense, salary, utility, maintenance, other
- `payment_method`: cash, bank, card, momo, other

### gps_locations
- `category`: laundry, spa, salon, pin, other
- `status`: potential, contacted, customer, rejected, closed

### notifications
- `type`: task_assigned, task_status_changed, task_completed, task_overdue, shift_reminder, attendance_issue, system, approval_request, approval_update

### tables (entertainment)
- `status`: available, occupied, reserved, maintenance
- `table_type`: standard, vip, premium
