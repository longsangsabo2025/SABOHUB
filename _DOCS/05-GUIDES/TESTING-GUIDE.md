# 🎯 HƯỚNG DẪN TEST ỨNG DỤNG

## 📋 Mục lục
1. [Khởi động ứng dụng](#khởi-động-ứng-dụng)
2. [Đăng nhập](#đăng-nhập)
3. [Test CEO Dashboard](#test-ceo-dashboard)
4. [Test Manager Dashboard](#test-manager-dashboard)
5. [Database Info](#database-info)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Khởi động ứng dụng

### Prerequisites
- Flutter SDK installed
- Chrome browser
- Python 3.13 (for database scripts)

### Start the app
```bash
# From project root
flutter run -d chrome
```

App sẽ mở trên Chrome và hiển thị màn hình login.

---

## 🔐 Đăng nhập

### Option 1: Quick Login (Recommended for testing)
Click vào một trong các nút quick login:

1. **CEO - Nhà hàng Sabo**
   - Email: `ceo1@sabohub.com`
   - Role: CEO
   - Company: Nhà hàng Sabo HCM
   
2. **CEO - Cafe Sabo**
   - Email: `ceo2@sabohub.com`
   - Role: CEO
   - Company: Cafe Sabo Hà Nội

3. **Manager - Chi nhánh 1**
   - Email: `manager1@sabohub.com`
   - Role: BRANCH_MANAGER

4. **Staff - Chi nhánh 1**
   - Email: `staff1@sabohub.com`
   - Role: STAFF

### Option 2: Manual Login
1. Nhập email: `ceo1@sabohub.com`
2. Nhập password: `password123`
3. Click "Đăng nhập"

> **Note**: Hiện tại authentication đang ở demo mode, không cần password thực.

---

## 👔 Test CEO Dashboard

### 1. Login as CEO
Click nút **"CEO - Nhà hàng Sabo"** để đăng nhập.

### 2. Explore Dashboard Tabs

#### Tab 1: Công việc chiến lược
- Xem danh sách tasks của CEO
- Filter theo status: All, Pending, In Progress, Completed
- Search tasks
- Click vào task để xem chi tiết

**Expected Data:**
- Hiển thị danh sách tasks (có thể rỗng nếu chưa có CEO tasks)

#### Tab 2: Công việc được giao
- Xem tasks được assign cho CEO
- Các tính năng tương tự Tab 1

**Expected Data:**
- Hiển thị tasks assigned to current CEO

#### Tab 3: Phân tích công ty ✨ **MAIN FEATURE**
Đây là tab chính được kết nối với database thực!

**Expected Display:**
```
📊 Thống kê công việc theo công ty

┌─────────────────────────────────────┐
│  Nhà hàng Sabo HCM                 │
│                                     │
│  📋 Tổng: 5                        │
│  ✅ Hoàn thành: 3                  │
│  🔄 Đang làm: 1                    │
│  ⏰ Chờ xử lý: 1                   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Cafe Sabo Hà Nội                  │
│                                     │
│  📋 Tổng: 11                       │
│  ✅ Hoàn thành: 2                  │
│  🔄 Đang làm: 3                    │
│  ⏰ Chờ xử lý: 6                   │
└─────────────────────────────────────┘
```

### 3. Verify Real Data
Data trên tab "Phân tích" được query trực tiếp từ database:
- ✅ Real-time task counts
- ✅ Per-company statistics
- ✅ Automatic updates khi có task mới

---

## 👨‍💼 Test Manager Dashboard

### 1. Login as Manager
Click nút **"Manager - Chi nhánh 1"**

### 2. Explore Features
- View manager overview
- Access task management (reuses CEO tasks page)
- Check reports section
- Settings

**Current Status:**
- ✅ Navigation works
- ⏳ Some features are placeholders
- ✅ Task management functional

---

## 🗄️ Database Info

### Connection Details
```
Host: aws-1-ap-southeast-2.pooler.supabase.com
Port: 6543
Database: postgres
User: postgres.dqddxowyikefqcdiioyh
```

### Current Data

#### Companies (2)
```
1. Nhà hàng Sabo HCM
   - ID: 10000000-0000-0000-0000-000000000001
   - Tasks: 5 total (3 completed, 1 in_progress, 1 pending)

2. Cafe Sabo Hà Nội
   - ID: 10000000-0000-0000-0000-000000000002
   - Tasks: 11 total (2 completed, 3 in_progress, 6 pending)
```

#### Branches (4)
```
- Chi nhánh Quận 1 (Company 1)
- Chi nhánh Quận 3 (Company 1)
- Chi nhánh Quận 1 (Company 2)
- Chi nhánh Quận 3 (Company 2)
```

#### Users (10)
```
CEO (2):
  - ceo1@sabohub.com (Nhà hàng Sabo HCM)
  - ceo2@sabohub.com (Cafe Sabo Hà Nội)

BRANCH_MANAGER (4):
  - manager1@sabohub.com
  - manager2@sabohub.com
  - manager3@sabohub.com
  - manager4@sabohub.com

STAFF (4):
  - staff1@sabohub.com
  - staff2@sabohub.com
  - staff3@sabohub.com
  - staff4@sabohub.com
```

#### Tasks (16)
- Various statuses: pending, in_progress, completed
- Different priorities: low, medium, high, urgent
- 3 overdue tasks for testing
- Distributed across 2 companies

### Verify Data
Run verification script:
```bash
cd database
python verify_seeded_data.py
```

---

## 🔧 Troubleshooting

### App không start
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

### Layout warnings in console
- These are harmless focus-related warnings
- Don't affect functionality
- Can be ignored for now

### Empty data on CEO Analytics tab
1. Check if you're logged in as CEO
2. Verify database has tasks:
   ```bash
   cd database
   python verify_seeded_data.py
   ```
3. Check console for errors

### Login doesn't work
- Currently in demo mode
- Any email will work
- Navigation based on email pattern:
  - Contains "ceo" → CEO Dashboard
  - Contains "manager" → Manager Dashboard
  - Other → Staff Dashboard

### Need to reseed database
```bash
# Delete all tasks
cd database
python -c "import psycopg2; conn = psycopg2.connect(host='aws-1-ap-southeast-2.pooler.supabase.com', port=6543, database='postgres', user='postgres.dqddxowyikefqcdiioyh', password='Acookingoil123'); cur = conn.cursor(); cur.execute('DELETE FROM tasks'); conn.commit(); print('Deleted tasks')"

# Reseed
python seed_company_tasks.py
python seed_ceo_users.py
```

---

## 🎨 Features to Test

### ✅ Working Features
- [x] Login with quick buttons
- [x] CEO Dashboard navigation
- [x] CEO Analytics tab with real data
- [x] Company task statistics
- [x] Task filtering (on other tabs)
- [x] Role-based routing

### ⏳ Partial Features
- [ ] Real authentication (demo mode)
- [ ] Task creation (UI exists, needs backend)
- [ ] Task updates
- [ ] File attachments
- [ ] Notifications

### 📋 Planned Features
- [ ] Task approvals workflow
- [ ] Manager-specific dashboard
- [ ] Staff dashboard
- [ ] Real-time updates
- [ ] Mobile responsive layout

---

## 📊 What to Check

### CEO Analytics Tab Checklist
- [ ] Tab loads without errors
- [ ] See 2 company cards
- [ ] Each card shows:
  - [ ] Company name
  - [ ] Total tasks count
  - [ ] Completed tasks count
  - [ ] In progress tasks count
  - [ ] Pending tasks count
- [ ] Numbers match database:
  - [ ] Nhà hàng Sabo HCM: 5 total
  - [ ] Cafe Sabo Hà Nội: 11 total

### Task Management Checklist
- [ ] Task list displays
- [ ] Can filter by status
- [ ] Can search tasks
- [ ] Task details show correctly
- [ ] Assignee names visible
- [ ] Due dates formatted properly

---

## 🎯 Success Criteria

### App is working correctly if:
1. ✅ Login page shows with quick login buttons
2. ✅ Clicking CEO quick login navigates to CEO Dashboard
3. ✅ CEO Dashboard has 3 tabs
4. ✅ "Phân tích" tab shows 2 company cards
5. ✅ Company cards show correct task statistics
6. ✅ No critical errors in console (layout warnings OK)

---

## 📝 Notes for Developers

### Code Structure
```
lib/
├── services/
│   └── management_task_service.dart  # Main service for tasks
├── providers/
│   └── management_task_provider.dart # Riverpod providers
├── pages/
│   ├── ceo/
│   │   └── ceo_tasks_page.dart      # CEO dashboard
│   └── auth/
│       └── login_page.dart          # Enhanced login page
└── models/
    └── management_task.dart         # Task model

database/
├── seed_company_tasks.py    # Main seeding script
├── seed_ceo_users.py        # CEO users + overdue tasks
└── verify_seeded_data.py    # Verification script
```

### Key Files Modified
- `lib/services/management_task_service.dart` - Fixed auth & field names
- `lib/pages/ceo/ceo_tasks_page.dart` - Fixed empty data handling
- `lib/pages/auth/login_page.dart` - Added quick login

### Database Schema
- Users: role CHECK ('CEO', 'BRANCH_MANAGER', 'SHIFT_LEADER', 'STAFF')
- Tasks: priority CHECK ('low', 'medium', 'high', 'urgent')
- Tasks: status CHECK ('pending', 'in_progress', 'completed', 'cancelled')

---

## 🎉 Happy Testing!

If you encounter any issues not covered in this guide, check:
1. Console for error messages
2. Database connection
3. Supabase service status

**Date**: November 2, 2025
**Version**: 1.0.0
**Status**: Ready for Testing ✅
