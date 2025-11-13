# 🔗 PHÂN TÍCH LIÊN KẾT GIỮA CÁC ROLE TRONG CÙNG CÔNG TY

**Ngày:** 11/11/2025  
**Trạng thái:** ⚠️ **CHƯA HOÀN CHỈNH** - Cần cải thiện

---

## 📊 **TỔNG QUAN HIỆN TẠI**

### ✅ **ĐÃ CÓ (Working):**

1. **RLS Policies - Company Isolation** ✅
   - Mỗi user chỉ thấy data của công ty mình
   - 20 RLS policies đang hoạt động
   - Employees, tasks, attendance đã có company_id filter

2. **Role Hierarchy** ✅
   - CEO → Manager → Shift Leader → Staff
   - Permission cascade: CEO có full access, Staff chỉ xem được của mình
   - Code trong `lib/models/user.dart`:
   ```dart
   bool hasRole(UserRole requiredRole) {
     if (role == UserRole.ceo) return true;
     if (role == UserRole.manager) {
       return requiredRole == UserRole.manager ||
              requiredRole == UserRole.shiftLeader ||
              requiredRole == UserRole.staff;
     }
     ...
   }
   ```

3. **Navigation Filtering** ✅
   - Mỗi role có navigation riêng
   - Staff: 5 tabs (Tables, Checkin, Tasks, Messages, Company Info)
   - Shift Leader: 6 tabs (kế thừa Staff + Team, Reports)
   - Manager: 6 tabs (Dashboard, Companies, Tasks, Attendance, Analytics, Staff)
   - CEO: 8 tabs (All features)

---

## ❌ **CHƯA CÓ (Missing Linkage):**

### 🔴 **1. Manager KHÔNG thấy được Staff của mình**

**Vấn đề:**
- Manager tạo công ty
- Manager mời Staff, Shift Leader
- Nhưng Manager **KHÔNG có trang để xem danh sách nhân viên** của công ty mình

**Thiếu:**
```dart
❌ ManagerEmployeesPage - Không tồn tại
❌ EmployeeListWidget for Manager - Không có
❌ Manager không thấy "Ai đang làm việc cho tôi?"
```

**Cần:**
- Trang "Nhân viên" cho Manager
- Hiển thị: Danh sách Staff, Shift Leader trong công ty
- Chức năng: Xem profile, chỉnh sửa, vô hiệu hóa tài khoản

---

### 🔴 **2. Tasks KHÔNG liên kết với Employee**

**Vấn đề hiện tại:**
```dart
// lib/services/task_service.dart
Future<Task> createTask(Task task) async {
  final response = await _supabase.from('tasks').insert({
    'branch_id': task.branchId,
    'title': task.title,
    'assigned_to': task.assignedTo, // ⚠️ Chỉ có user_id
    // ❌ KHÔNG có: assigned_to_name, assigned_to_role
  });
}
```

**Hậu quả:**
- Task hiển thị assigned_to = UUID
- UI phải query lại database để lấy tên người được giao
- Performance kém khi load nhiều tasks

**Cần:**
- Thêm columns: `assigned_to_name`, `assigned_to_role`, `assigned_by_name`
- Khi tạo task, tự động populate tên từ employees table

---

### 🔴 **3. Shift Leader KHÔNG quản lý được Team**

**Trang hiện tại:**
```dart
// lib/pages/shift_leader/shift_leader_team_page.dart
// ⚠️ Page này CHỈ là placeholder, chưa có logic thật

class ShiftLeaderTeamPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Team Management - Coming Soon'), // ❌ Chưa làm
    );
  }
}
```

**Thiếu:**
- Danh sách Staff trong ca của Shift Leader
- Ai đang online/offline
- Lịch sử check-in của team
- Assign tasks cho Staff

---

### 🔴 **4. CEO KHÔNG thấy tất cả Companies và Employees**

**Vấn đề:**
- CEO có thể tạo nhiều công ty
- Nhưng **CEO Dashboard KHÔNG tổng hợp data từ tất cả công ty**

**CEO Dashboard hiện tại:**
```dart
// lib/pages/ceo/ceo_dashboard_page.dart
// ⚠️ Chỉ hiển thấy 1 công ty đang "active"
// ❌ Không có dropdown để switch giữa các công ty
// ❌ Không có tổng hợp cross-company analytics
```

**Cần:**
- Company Switcher cho CEO
- Analytics tổng hợp tất cả công ty
- Employee count per company
- Revenue per company

---

### 🔴 **5. Attendance KHÔNG liên kết với Branch và Employee**

**Database schema hiện tại:**
```sql
-- attendance table
CREATE TABLE attendance (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id), -- ✅ Có
  company_id UUID REFERENCES companies(id), -- ✅ Có
  branch_id UUID, -- ⚠️ Có nhưng không dùng
  check_in_time TIMESTAMPTZ,
  check_out_time TIMESTAMPTZ,
  -- ❌ THIẾU: employee_name, branch_name
);
```

**Hậu quả:**
- Manager xem attendance → Chỉ thấy UUID, không biết tên ai
- Không biết nhân viên check-in ở chi nhánh nào
- Phải JOIN 3 bảng mỗi lần load → Chậm

---

## 📋 **BẢNG SO SÁNH - LINKAGE STATUS**

| **Tính năng** | **Hiện tại** | **Cần có** | **Priority** |
|--------------|-------------|-----------|--------------|
| Company → Employees | ❌ Manager không thấy list | ✅ Employee list by company | 🔴 P0 |
| Task → Employee Name | ❌ Chỉ có UUID | ✅ Cached name trong task | 🔴 P0 |
| Shift Leader → Team | ❌ Placeholder page | ✅ Real team management | 🔴 P0 |
| CEO → All Companies | ⚠️ Chỉ thấy 1 công ty | ✅ Multi-company view | 🟡 P1 |
| Attendance → Employee | ❌ Chỉ có user_id | ✅ Cached employee info | 🟡 P1 |
| Manager → Branch Stats | ❌ Không có | ✅ Per-branch analytics | 🟡 P1 |
| Staff → Manager Contact | ❌ Không biết manager là ai | ✅ Show manager info | 🟢 P2 |

---

## 🎯 **KẾ HOẠCH KHẮC PHỤC**

### **Phase 1: Critical Linkage (P0) - 4 hours**

#### ✅ **Task 1: Add Employee Names to Tasks**
```sql
-- Migration: add_employee_names_to_tasks.sql
ALTER TABLE tasks ADD COLUMN assigned_to_name TEXT;
ALTER TABLE tasks ADD COLUMN assigned_by_name TEXT;
ALTER TABLE tasks ADD COLUMN assigned_to_role TEXT;
```

```dart
// Update TaskService.createTask()
Future<Task> createTask(Task task) async {
  // Lookup employee name
  final employee = await getEmployeeById(task.assignedTo);
  
  await _supabase.from('tasks').insert({
    'assigned_to': task.assignedTo,
    'assigned_to_name': employee.name, // NEW
    'assigned_to_role': employee.role, // NEW
    'assigned_by_name': currentUser.name, // NEW
  });
}
```

---

#### ✅ **Task 2: Create Manager Employees Page**
```dart
// NEW FILE: lib/pages/manager/manager_employees_page.dart
class ManagerEmployeesPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = ref.watch(currentCompanyIdProvider);
    final employees = ref.watch(employeesByCompanyProvider(companyId));
    
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return EmployeeCard(
          name: employee.name,
          role: employee.role,
          status: employee.isActive ? 'Active' : 'Inactive',
          onTap: () => showEmployeeDetails(employee),
        );
      },
    );
  }
}
```

---

#### ✅ **Task 3: Implement Shift Leader Team Management**
```dart
// UPDATE: lib/pages/shift_leader/shift_leader_team_page.dart
class ShiftLeaderTeamPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myBranchId = ref.watch(currentBranchIdProvider);
    final teamMembers = ref.watch(employeesByBranchProvider(myBranchId));
    
    return Column(
      children: [
        // Team Overview
        TeamStatsCard(
          totalMembers: teamMembers.length,
          onlineNow: teamMembers.where((e) => e.isOnline).length,
        ),
        
        // Team Members List
        Expanded(
          child: ListView(
            children: teamMembers.map((member) {
              return TeamMemberCard(
                name: member.name,
                role: member.role,
                isOnline: member.isOnline,
                lastCheckIn: member.lastCheckIn,
                onAssignTask: () => showTaskAssignDialog(member),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

---

### **Phase 2: Enhanced Linkage (P1) - 6 hours**

#### ✅ **Task 4: CEO Multi-Company Dashboard**
```dart
// NEW FILE: lib/pages/ceo/ceo_companies_overview_page.dart
class CEOCompaniesOverviewPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(allCompaniesProvider);
    
    return Column(
      children: [
        // Summary Cards
        Row(
          children: [
            StatCard(
              title: 'Total Companies',
              value: '${companies.length}',
              icon: Icons.business,
            ),
            StatCard(
              title: 'Total Employees',
              value: '${getTotalEmployees(companies)}',
              icon: Icons.people,
            ),
          ],
        ),
        
        // Company List
        Expanded(
          child: ListView(
            children: companies.map((company) {
              return CompanyCard(
                name: company.name,
                employeeCount: company.employeeCount,
                revenue: company.monthlyRevenue,
                onTap: () => navigateToCompanyDetail(company),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
```

---

#### ✅ **Task 5: Add Employee Info to Attendance**
```sql
-- Migration: add_employee_info_to_attendance.sql
ALTER TABLE attendance ADD COLUMN employee_name TEXT;
ALTER TABLE attendance ADD COLUMN employee_role TEXT;
ALTER TABLE attendance ADD COLUMN branch_name TEXT;

-- Update existing records
UPDATE attendance a
SET 
  employee_name = u.name,
  employee_role = u.role,
  branch_name = b.name
FROM users u, branches b
WHERE a.user_id = u.id AND a.branch_id = b.id;
```

---

### **Phase 3: Polish (P2) - 2 hours**

#### ✅ **Task 6: Staff sees Manager Contact Info**
```dart
// UPDATE: lib/pages/staff/staff_company_info_page.dart
// Add "Manager Contact" section
ManagerContactCard(
  name: manager.name,
  role: 'Your Manager',
  phone: manager.phone,
  email: manager.email,
  onCall: () => launchPhone(manager.phone),
  onEmail: () => launchEmail(manager.email),
);
```

---

## 🧪 **TESTING CHECKLIST**

### **Test Case 1: Manager Employees Page**
- [ ] Manager login → Navigate to "Nhân viên" tab
- [ ] Verify: See all Staff and Shift Leaders
- [ ] Verify: Can view employee details
- [ ] Verify: Can't see employees from other companies

### **Test Case 2: Task Assignment with Names**
- [ ] Manager creates task
- [ ] Assign to Staff member
- [ ] Verify: Task shows "Assigned to: [Staff Name]"
- [ ] Verify: Task shows "Assigned by: [Manager Name]"

### **Test Case 3: Shift Leader Team Page**
- [ ] Shift Leader login → Navigate to "Đội nhóm"
- [ ] Verify: See team members (Staff only)
- [ ] Verify: See online/offline status
- [ ] Verify: Can assign tasks from this page

### **Test Case 4: CEO Multi-Company View**
- [ ] CEO with 2+ companies
- [ ] Verify: Dashboard shows all companies
- [ ] Verify: Can switch between companies
- [ ] Verify: Analytics aggregate correctly

---

## 📊 **DATABASE CHANGES REQUIRED**

### **New Columns:**
```sql
-- tasks table
ALTER TABLE tasks ADD COLUMN assigned_to_name TEXT;
ALTER TABLE tasks ADD COLUMN assigned_to_role TEXT;
ALTER TABLE tasks ADD COLUMN assigned_by_name TEXT;

-- attendance table
ALTER TABLE attendance ADD COLUMN employee_name TEXT;
ALTER TABLE attendance ADD COLUMN employee_role TEXT;
ALTER TABLE attendance ADD COLUMN branch_name TEXT;

-- employees table (if not exists)
ALTER TABLE employees ADD COLUMN manager_id UUID REFERENCES users(id);
ALTER TABLE employees ADD COLUMN branch_id UUID REFERENCES branches(id);
```

### **New Indexes:**
```sql
CREATE INDEX idx_tasks_assigned_to_company ON tasks(assigned_to, company_id);
CREATE INDEX idx_attendance_branch_date ON attendance(branch_id, check_in_time);
CREATE INDEX idx_employees_manager ON employees(manager_id);
```

---

## 🎯 **EXPECTED OUTCOMES**

### **After Phase 1 (P0):**
- ✅ Manager thấy được tất cả nhân viên trong công ty
- ✅ Tasks hiển thị tên người được giao (không còn UUID)
- ✅ Shift Leader quản lý được team

### **After Phase 2 (P1):**
- ✅ CEO thấy tổng hợp tất cả công ty
- ✅ Attendance hiển thị tên nhân viên + chi nhánh
- ✅ Manager có analytics per branch

### **After Phase 3 (P2):**
- ✅ Staff biết manager của mình là ai
- ✅ UI/UX hoàn thiện
- ✅ All roles fully connected

---

## 📈 **PROGRESS TRACKING**

| **Phase** | **Tasks** | **Status** | **ETA** |
|-----------|-----------|-----------|---------|
| Phase 1 | 3/3 tasks | ⏳ Pending | 4 hours |
| Phase 2 | 2/2 tasks | ⏳ Pending | 6 hours |
| Phase 3 | 1/1 task | ⏳ Pending | 2 hours |
| **Total** | **6 tasks** | **0% Complete** | **12 hours** |

---

## 💡 **RECOMMENDATIONS**

1. **Start with Phase 1** - Critical for Manager UX
2. **Test incrementally** - Don't deploy all at once
3. **Document API changes** - Important for future maintenance
4. **Add cache providers** - For employee lists (performance)
5. **Update RLS policies** - Ensure manager can access employee data

---

**Kết luận:** Các tính năng **CHƯA được liên kết đầy đủ**. Cần làm 3 phases (12 hours) để hoàn chỉnh.

