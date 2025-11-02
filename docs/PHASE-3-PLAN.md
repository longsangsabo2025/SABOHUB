# Phase 3: Inventory & Task Management - IMPLEMENTATION PLAN

**Date:** January 2025  
**Status:** 🚧 PLANNING  
**Strategy:** Pure Dart · Zero Native Plugins

---

## 📋 Overview

Phase 3 focuses on implementing **Inventory Management** and **Task Management** systems to complete the core business operations platform.

### Goals:

1. ✅ Track inventory items with low stock alerts
2. ✅ Record stock movements (in/out/adjustment/damaged)
3. ✅ Manage work tasks with assignments and due dates
4. ✅ Task prioritization and status tracking
5. ✅ Demo data for realistic testing scenarios

---

## 🏗️ Part A: Inventory Management

### Domain Models

#### 1. InventoryCategory Enum

```dart
enum InventoryCategory {
  food('Đồ ăn', Color(0xFFF59E0B)),
  beverage('Đồ uống', Color(0xFF3B82F6)),
  equipment('Thiết bị', Color(0xFF8B5CF6)),
  cleaning('Vệ sinh', Color(0xFF10B981)),
  other('Khác', Color(0xFF6B7280));
}
```

#### 2. StockMovementType Enum

```dart
enum StockMovementType {
  stockIn('Nhập kho', Color(0xFF10B981)),
  stockOut('Xuất kho', Color(0xFFEF4444)),
  adjustment('Điều chỉnh', Color(0xFF3B82F6)),
  damaged('Hư hỏng', Color(0xFF6B7280));
}
```

#### 3. InventoryItem Class (12 fields + 2 computed properties)

```dart
class InventoryItem {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final InventoryCategory category;
  final String unit; // 'kg', 'lít', 'cái', 'hộp'
  final double currentStock;
  final double minThreshold; // Low stock alert
  final double? cost; // Cost per unit
  final String? supplier;
  final DateTime? lastRestocked;
  final DateTime createdAt;

  // Computed
  bool get isLowStock => currentStock <= minThreshold;
  double get totalValue => (cost ?? 0) * currentStock;
}
```

**Business Rules:**

- `isLowStock` alerts when `currentStock <= minThreshold`
- `totalValue` calculates inventory worth: cost × currentStock
- `unit` examples: kg, lít, cái, hộp, thùng

#### 4. StockMovement Class (10 fields)

```dart
class StockMovement {
  final String id;
  final String itemId;
  final String itemName;
  final String companyId;
  final StockMovementType type;
  final double quantity;
  final String reason;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
}
```

**Movement Types:**

- `stockIn`: Nhập hàng mới vào kho
- `stockOut`: Xuất hàng (sử dụng, bán)
- `adjustment`: Điều chỉnh số lượng (kiểm kê)
- `damaged`: Hư hỏng, hết hạn

---

## 🏗️ Part B: Task Management

### Domain Models

#### 1. TaskPriority Enum

```dart
enum TaskPriority {
  low('Thấp', Color(0xFF6B7280)),
  medium('Trung bình', Color(0xFF3B82F6)),
  high('Cao', Color(0xFFF59E0B)),
  urgent('Khẩn cấp', Color(0xFFEF4444));
}
```

#### 2. TaskStatus Enum

```dart
enum TaskStatus {
  todo('Cần làm', Color(0xFF6B7280)),
  inProgress('Đang làm', Color(0xFF3B82F6)),
  completed('Hoàn thành', Color(0xFF10B981)),
  cancelled('Đã hủy', Color(0xFFEF4444));
}
```

#### 3. TaskCategory Enum

```dart
enum TaskCategory {
  operations('Vận hành', Color(0xFF3B82F6)),
  maintenance('Bảo trì', Color(0xFFF59E0B)),
  inventory('Kho hàng', Color(0xFF8B5CF6)),
  customerService('Khách hàng', Color(0xFF10B981)),
  other('Khác', Color(0xFF6B7280));
}
```

#### 4. Task Class (15 fields + 2 computed properties)

```dart
class Task {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final String? assignedTo; // Employee ID
  final String? assignedToName;
  final DateTime dueDate;
  final DateTime? completedAt;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String? notes;

  // Computed
  bool get isOverdue => status != completed/cancelled && dueDate < now
  bool get isDueSoon => dueDate within 24 hours && !overdue
}
```

**Business Rules:**

- `isOverdue`: Task past due date and not completed/cancelled
- `isDueSoon`: Task due within 24 hours (yellow alert)
- `assignedTo`: Optional - unassigned tasks available for pickup
- `completedAt`: Timestamp when status changed to completed

---

## 🔄 State Management Extensions

### AuthState New Fields

```dart
final List<InventoryItem> inventoryItems;
final List<StockMovement> stockMovements;
final List<Task> tasks;
```

### New Getters (9 total)

#### Inventory Getters:

```dart
List<InventoryItem> get currentCompanyInventory;
List<InventoryItem> get lowStockItems;
double get totalInventoryValue;
List<StockMovement> get currentCompanyMovements;
List<StockMovement> getMovementsByItemId(String itemId);
```

#### Task Getters:

```dart
List<Task> get currentCompanyTasks;
List<Task> get myTasks; // Assigned to current user
List<Task> get overdueTasks;
List<Task> get dueSoonTasks;
```

### AuthNotifier Methods

#### Inventory Methods (6 total):

```dart
// CRUD
void addInventoryItem(InventoryItem item);
void updateInventoryItem(String id, {various fields});
void deleteInventoryItem(String id);

// Stock Management
void stockIn(String itemId, double quantity, String reason);
void stockOut(String itemId, double quantity, String reason);
void adjustStock(String itemId, double newQuantity, String reason);
```

#### Task Methods (8 total):

```dart
// CRUD
void createTask(Task task);
void updateTask(String id, {various fields});
void deleteTask(String id);

// Status Management
void startTask(String id);
void completeTask(String id);
void cancelTask(String id);

// Assignment
void assignTask(String id, String employeeId, String employeeName);
void unassignTask(String id);
```

#### Demo Data Generators:

```dart
List<InventoryItem> _generateDemoInventory(List<Company> companies);
List<StockMovement> _generateDemoMovements(List<Company> companies);
List<Task> _generateDemoTasks(List<Company> companies);
```

---

## 🎨 UI Components

### 1. InventoryListPage (ConsumerStatefulWidget)

**Features:**

- Stats bar: Total items / Low stock count / Total value
- Category filter chips (All + 5 categories)
- Item cards showing:
  - Icon + Category badge (color-coded)
  - Item name + description
  - Current stock vs min threshold
  - Unit display (kg, lít, cái)
  - Low stock warning (red badge)
  - Total value if cost available
- Action bottom sheet:
  - Stock In (add quantity)
  - Stock Out (reduce quantity)
  - Adjust Stock (set exact quantity)
  - View Movements
  - Edit Item
  - Delete Item
- FAB: Add new item
- Empty state with "Add your first item"

**Layout:**

```
┌─────────────────────────────────────┐
│ ← Kho hàng                          │
├─────────────────────────────────────┤
│ [12 items] [3 low] [15.5M value]   │
│                                     │
│ [All][Food][Bev][Equip][Clean][Other]│
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 🍔 Đồ ăn  🔴 LOW                │ │
│ │ Phở bò                          │ │
│ │ Phở bò tái, chín cho khách      │ │
│ │                                 │ │
│ │ 5 / 20 kg ⚠️                    │ │
│ │ Giá trị: 250,000đ               │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 🥤 Đồ uống                      │ │
│ │ Coca Cola                       │ │
│ │ Coca Cola 330ml                 │ │
│ │                                 │ │
│ │ 50 / 10 cái ✅                  │ │
│ │ Giá trị: 500,000đ               │ │
│ └─────────────────────────────────┘ │
│                                     │
│                           [+ FAB]   │
└─────────────────────────────────────┘
```

### 2. InventoryFormPage (ConsumerStatefulWidget)

**Features:**

- Form fields:
  - Name (required)
  - Description (optional)
  - Category dropdown
  - Unit input (kg, lít, cái, hộp)
  - Current stock number
  - Min threshold number
  - Cost per unit (optional)
  - Supplier name (optional)
- Validation:
  - Name not empty
  - Stock >= 0
  - Threshold >= 0
  - Cost >= 0 if provided
- Save button with loading state
- Cancel button

### 3. StockMovementPage (ConsumerWidget)

**Features:**

- Header showing item name + current stock
- Movement history list:
  - Type icon + color (In/Out/Adjust/Damaged)
  - Quantity with +/- prefix
  - Reason description
  - Created by + timestamp
  - Running balance after movement
- Timeline-style layout
- Empty state: "No movements yet"

**Layout:**

```
┌─────────────────────────────────────┐
│ ← Stock Movements: Phở bò           │
│ Current Stock: 5 kg                 │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ⬆️ NHẬP KHO       +20 kg         │ │
│ │ Nhập hàng từ nhà cung cấp       │ │
│ │ by CEO John  •  2 hours ago     │ │
│ │ Balance: 25 kg → 5 kg           │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ⬇️ XUẤT KHO       -20 kg         │ │
│ │ Sử dụng cho khách hàng          │ │
│ │ by Staff A  •  1 hour ago       │ │
│ │ Balance: 25 kg → 5 kg           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### 4. TaskListPage (ConsumerStatefulWidget)

**Features:**

- Stats bar: Todo / In Progress / Completed / Overdue count
- Status filter chips (All + 4 statuses)
- Priority filter (All/Low/Med/High/Urgent)
- Task cards showing:
  - Priority badge (color-coded, left border)
  - Category icon + label
  - Task title + truncated description
  - Assigned to (avatar + name or "Unassigned")
  - Due date with overdue/due soon warnings
  - Status badge
- Action bottom sheet:
  - Start Task (todo → inProgress)
  - Complete Task
  - Cancel Task
  - Reassign
  - Edit Task
  - Delete Task
- FAB: Create new task
- Empty state

**Layout:**

```
┌─────────────────────────────────────┐
│ ← Công việc                         │
├─────────────────────────────────────┤
│ [5 todo] [2 doing] [10 done] [1 ⚠️] │
│                                     │
│ [All][Todo][Doing][Done][Cancelled] │
│ [All Priority][Low][Med][High][⚡]  │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │║🔴 URGENT                        │ │
│ │ 🔧 Bảo trì                      │ │
│ │ Sửa máy lạnh bàn 3              │ │
│ │ Máy lạnh không mát, cần...     │ │
│ │                                 │ │
│ │ 👤 Staff A                      │ │
│ │ ⏰ Overdue 2 hours ago ⚠️       │ │
│ │ [Đang làm]                      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │║🟡 HIGH                          │ │
│ │ 📦 Kho hàng                     │ │
│ │ Kiểm kê kho cuối tháng          │ │
│ │ Đếm tất cả mặt hàng...          │ │
│ │                                 │ │
│ │ 👤 Unassigned                   │ │
│ │ ⏰ Due in 6 hours 🕒            │ │
│ │ [Cần làm]                       │ │
│ └─────────────────────────────────┘ │
│                                     │
│                           [+ FAB]   │
└─────────────────────────────────────┘
```

### 5. TaskFormPage (ConsumerStatefulWidget)

**Features:**

- Form fields:
  - Title (required)
  - Description (required, multiline)
  - Category dropdown
  - Priority dropdown
  - Assign to employee dropdown (optional)
  - Due date/time picker (required)
  - Notes (optional, multiline)
- Real-time validation
- Save button with loading
- Cancel button
- Validation:
  - Title not empty
  - Description not empty
  - Due date must be future

---

## 🗺️ Navigation Integration

### HomePage Updates

Add 2 new Quick Action buttons:

```dart
_buildActionCard(context, 'Kho hàng', Icons.inventory, Color(0xFF8B5CF6)),
_buildActionCard(context, 'Công việc', Icons.task_alt, Color(0xFFF59E0B)),
```

Total: **10 buttons** on HomePage grid (2x5)

### Navigation Routes:

```
HomePage
  ├─ Kho hàng → InventoryListPage
  │             ├─ Add → InventoryFormPage
  │             ├─ Edit → InventoryFormPage(item)
  │             └─ Movements → StockMovementPage(item)
  └─ Công việc → TaskListPage
                ├─ Add → TaskFormPage
                └─ Edit → TaskFormPage(task)
```

---

## 📊 Demo Data

### Inventory Demo (per company):

```dart
// Billiards companies:
1. Phở bò (Food, 5/20 kg, LOW STOCK, 50K/kg)
2. Coca Cola (Beverage, 50/10 cái, OK, 10K/cái)
3. Bi da (Equipment, 15/5 cái, OK, 200K/cái)
4. Khăn lau (Cleaning, 20/10 cái, OK, 5K/cái)

// Cafe companies:
1. Cà phê rang (Beverage, 2/5 kg, LOW STOCK, 150K/kg)
2. Sữa tươi (Beverage, 10/5 lít, OK, 30K/lít)
3. Ly nhựa (Equipment, 100/50 cái, OK, 1K/cái)
4. Đường (Food, 15/10 kg, OK, 20K/kg)
```

### Stock Movements (2 per item):

```dart
Movement 1: Stock In (+20) "Nhập hàng từ nhà cung cấp" (2 hours ago)
Movement 2: Stock Out (-15) "Sử dụng cho khách hàng" (1 hour ago)
```

### Tasks Demo (per company):

```dart
// 1 Urgent task (overdue):
{
  title: "Sửa máy lạnh bàn 3",
  category: maintenance,
  priority: urgent,
  status: inProgress,
  assignedTo: random staff,
  dueDate: 2 hours ago,
}

// 1 High priority task (due soon):
{
  title: "Kiểm kê kho cuối tháng",
  category: inventory,
  priority: high,
  status: todo,
  assignedTo: null,
  dueDate: 6 hours from now,
}

// 1 Medium priority task (normal):
{
  title: "Lau dọn khu vực VIP",
  category: operations,
  priority: medium,
  status: todo,
  assignedTo: random staff,
  dueDate: tomorrow,
}

// 1 Completed task:
{
  title: "Nhập hàng tuần này",
  category: inventory,
  priority: medium,
  status: completed,
  completedAt: yesterday,
}
```

---

## 🧪 Testing Checklist

### Inventory Testing:

- [ ] Add new inventory item
- [ ] Edit existing item
- [ ] Delete item (with confirmation)
- [ ] Stock In increases currentStock
- [ ] Stock Out decreases currentStock
- [ ] Adjust Stock sets exact quantity
- [ ] Low stock badge appears when stock <= threshold
- [ ] Category filter works correctly
- [ ] Total value calculates correctly
- [ ] Movement history displays in correct order
- [ ] Demo data generates correctly

### Task Testing:

- [ ] Create new task
- [ ] Edit existing task
- [ ] Delete task (with confirmation)
- [ ] Start task (todo → inProgress)
- [ ] Complete task (any → completed, sets completedAt)
- [ ] Cancel task (any → cancelled)
- [ ] Assign task to employee
- [ ] Unassign task
- [ ] Overdue badge shows for past due date
- [ ] Due soon badge shows for <24h tasks
- [ ] Status filter works correctly
- [ ] Priority filter works correctly
- [ ] Demo data generates correctly

### Integration Testing:

- [ ] Homepage shows 10 action buttons
- [ ] Navigation to Inventory/Tasks works
- [ ] Multi-company isolation (each company has own data)
- [ ] CEO sees all inventory/tasks across companies
- [ ] Staff sees only their company data
- [ ] State persists after company switch

---

## 📈 Estimated Code Size

- **Inventory Models:** ~250 lines
- **Task Models:** ~250 lines
- **State Extensions:** ~150 lines (getters + fields + copyWith)
- **Inventory Methods:** ~300 lines (CRUD + stock management + demo)
- **Task Methods:** ~350 lines (CRUD + status + assignment + demo)
- **InventoryListPage:** ~400 lines
- **InventoryFormPage:** ~250 lines
- **StockMovementPage:** ~200 lines
- **TaskListPage:** ~450 lines
- **TaskFormPage:** ~300 lines
- **Navigation Updates:** ~20 lines

**Total:** ~2,920 lines of pure Dart code

---

## 🚀 Implementation Steps

### Step 1: Models (Priority: HIGH)

1. Add Inventory & Task models after Receipt class
2. Update AuthState with new fields
3. Update copyWith method
4. Add getters

### Step 2: State Management (Priority: HIGH)

1. Implement inventory CRUD methods
2. Implement stock movement methods
3. Implement task CRUD methods
4. Implement task status methods
5. Create demo data generators
6. Update login method to initialize demo data

### Step 3: UI - Inventory (Priority: MEDIUM)

1. Create InventoryListPage
2. Create InventoryFormPage
3. Create StockMovementPage
4. Add navigation from HomePage

### Step 4: UI - Tasks (Priority: MEDIUM)

1. Create TaskListPage
2. Create TaskFormPage
3. Add navigation from HomePage

### Step 5: Integration & Testing (Priority: LOW)

1. Test all features manually
2. Fix bugs
3. Optimize performance
4. Create documentation

---

## 🎯 Success Criteria

- [ ] All domain models implemented with copyWith
- [ ] State management complete with getters
- [ ] Inventory CRUD functional
- [ ] Stock movements tracked correctly
- [ ] Task CRUD functional
- [ ] Task assignment works
- [ ] Low stock alerts display correctly
- [ ] Overdue/due soon badges work
- [ ] Demo data realistic and useful
- [ ] UI responsive and intuitive
- [ ] Navigation smooth
- [ ] Zero native plugins added
- [ ] App builds successfully

---

## 📝 Notes

- **File Size Concern:** `main.dart` already ~5K lines. Consider splitting into modules if exceeds 7K lines.
- **Performance:** In-memory state works for demo. Consider Hive/SQLite for production.
- **Real-time Updates:** Current implementation is local-only. Need backend integration for multi-user scenarios.
- **Notifications:** Low stock + overdue task alerts can be added in Phase 4.
- **Reports:** Inventory value trends + task completion rates can be added in Phase 4.

---

**Next Action:** Implement Step 1 (Models) to add Inventory & Task domain models to `main.dart`.
