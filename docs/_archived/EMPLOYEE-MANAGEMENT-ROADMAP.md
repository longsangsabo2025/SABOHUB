# 🏢 Universal Small Business Management - Roadmap

## 🎯 Vision: Nền tảng quản lý TỔNG QUÁT cho mọi loại doanh nghiệp nhỏ

### Phase 1: Foundation - Company & Employee Management ⭐ (ĐANG LÀM)

#### 1.1 CEO Company Operations

- [x] View multiple companies
- [x] Switch between companies
- [ ] **Add new company** (Form: name, type, address, phone)
- [ ] **Edit company** (Update info)
- [ ] **Delete company** (With confirmation, soft delete)
- [ ] Company status (Active/Inactive)

#### 1.2 Employee Management (CORE FOCUS)

- [ ] **Employee Model**
  - id, name, email, phone, address
  - role (CEO, Manager, Shift Leader, Staff)
  - companyId (assigned company)
  - isActive (active/inactive status)
  - joinDate, salary (optional)
- [ ] **Employee CRUD**
  - Add employee to company
  - Edit employee info
  - Deactivate employee (soft delete)
  - Re-activate employee
- [ ] **Employee List Screen**
  - View all employees per company
  - Filter by role
  - Search by name
  - Sort by join date, name
- [ ] **Employee Detail Screen**
  - Full employee info
  - Edit button
  - Deactivate/Activate toggle
  - Work history (future)

#### 1.3 Dashboard Updates

- [ ] Show employee count per company
- [ ] "Manage Employees" quick action
- [ ] "Add Employee" FAB button
- [ ] Recent employees widget

---

### Phase 2: Shift & Schedule Management (NEXT)

#### 2.1 Shift Management

- [ ] Define shift templates (Morning, Afternoon, Night)
- [ ] Assign employees to shifts
- [ ] Shift calendar view
- [ ] Shift swap requests

#### 2.2 Attendance Tracking

- [ ] Check-in/Check-out system
- [ ] GPS location verification (optional)
- [ ] Attendance history
- [ ] Late/absent reports

#### 2.3 Schedule Planning

- [ ] Weekly schedule planner
- [ ] Auto-assign shifts
- [ ] Conflict detection
- [ ] Export schedule to employees

---

### Phase 3: Basic Operations (UNIVERSAL)

#### 3.1 Task Management

- [ ] Create tasks for employees
- [ ] Task status tracking
- [ ] Task priorities
- [ ] Due dates and reminders

#### 3.2 Announcements

- [ ] Company-wide announcements
- [ ] Push notifications
- [ ] Read receipts
- [ ] Important/urgent flags

#### 3.3 Reports (Basic)

- [ ] Employee performance summary
- [ ] Attendance reports
- [ ] Company overview
- [ ] Export to Excel/PDF

---

### Phase 4: Financial Basics

#### 4.1 Payroll

- [ ] Set employee salaries
- [ ] Calculate monthly pay
- [ ] Overtime tracking
- [ ] Payslip generation

#### 4.2 Expenses

- [ ] Record company expenses
- [ ] Categorize expenses
- [ ] Monthly expense reports
- [ ] Budget tracking

---

### Phase 5: Communication

#### 5.1 Internal Chat

- [ ] Employee messaging
- [ ] Group chats per company
- [ ] File sharing
- [ ] Notifications

#### 5.2 Notifications

- [ ] Push notifications
- [ ] Email notifications
- [ ] SMS alerts (optional)
- [ ] Notification preferences

---

## 🛠️ Technical Stack

### Current (Pure Flutter)

- **State Management**: Riverpod
- **Storage**: In-memory (StateNotifier)
- **UI**: Material 3 Dark Theme
- **Dependencies**: flutter_riverpod, intl

### Future (Phase 2+)

- **Backend**: Supabase
- **Auth**: JWT Tokens
- **Database**: PostgreSQL with RLS
- **Storage**: Supabase Storage
- **Realtime**: Supabase Subscriptions
- **Offline**: Hive/SharedPreferences

---

## 📊 Current Status

### ✅ Completed

- Multi-company architecture
- CEO can view and switch companies
- Company selection page
- Compact UI with optimized cards
- Role-based UI (CEO vs Staff)

### 🔄 In Progress

- Employee Management System
- Company CRUD operations

### ⏳ Pending

- Shift management
- Attendance tracking
- Task management
- Reports and analytics
- Backend integration

---

## 🎯 Immediate Next Steps (Session)

1. **Add Employee Model** to AuthState
2. **Create EmployeeListPage** (view employees per company)
3. **Create EmployeeFormPage** (add/edit employee)
4. **Update HomePage** with "Manage Employees" action
5. **Add demo employees** to test data

---

## 💡 Design Principles

1. **Universal First**: Features work for ANY business type
2. **Employee-Centric**: Focus on workforce management
3. **Simple & Intuitive**: Easy for small business owners
4. **Scalable**: Can add industry-specific features later
5. **Offline-First**: Work without internet (future)

---

## 🚀 Success Metrics

- CEO can manage multiple companies ✅
- Add/Edit/Remove employees easily
- Track employee attendance
- Generate basic reports
- Works offline (future)
