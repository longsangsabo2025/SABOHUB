# 📋 Company Details Page Refactoring Plan

## 🎯 Mục Tiêu
Tách file `company_details_page.dart` (3720 dòng) thành các file nhỏ hơn, dễ maintain.

## 📁 Cấu Trúc Mới

```
lib/pages/ceo/company/
├── company_details_page.dart        # Main page (scaffold + TabController)
├── overview_tab.dart                # ✅ ĐÃ TẠO
├── employees_tab.dart               # TODO
├── tasks_tab.dart                   # TODO
├── documents_tab.dart               # TODO
├── settings_tab.dart                # TODO
└── widgets/
    ├── company_header.dart          # ✅ ĐÃ TẠO
    ├── stat_card.dart               # ✅ ĐÃ TẠO
    ├── employee_card.dart           # TODO
    ├── task_card.dart               # TODO
    └── document_card.dart           # TODO
```

## ✅ Files Đã Hoàn Thành

### 1. `widgets/company_header.dart` (180 dòng)
- Hiển thị header với gradient background
- Company logo/initial, name, type chip, status badge
- Back button và More options button

### 2. `widgets/stat_card.dart` (60 dòng)
- Widget hiển thị thống kê (icon, value, label)
- Reusable cho nhiều tabs

### 3. `overview_tab.dart` (320 dòng)
- Tab tổng quan với stats cards
- Company info card
- Contact card
- Timeline card
- Helper methods: _formatCurrency, _launchPhone, _launchEmail
- Providers: companyServiceProvider, companyStatsProvider

## 📝 TODO - Files Cần Tạo

### 4. `employees_tab.dart` (~600 dòng)
**Chức năng**:
- Header với employee stats
- Search và filter employees
- Employee list với real data
- Actions: Create, Edit, Toggle Status, Delete

**Providers cần**:
- companyEmployeesProvider
- companyEmployeesStatsProvider

**Widgets cần**:
- employee_card.dart

**Methods chính**:
- _buildEmployeeStatCard
- _buildEmployeeCard
- _showCreateEmployeeDialog
- _showEditEmployeeDialog
- _toggleEmployeeStatus
- _deleteEmployee

### 5. `tasks_tab.dart` (~500 dòng)
**Chức năng**:
- Header với task stats
- AI suggested tasks button
- Task list với task cards
- Actions: Create, Edit, View Details, Delete

**Providers cần**:
- companyTasksProvider
- companyTaskStatsProvider
- documentInsightsProvider

**Dialogs**:
- CreateTaskDialog (đã có)
- EditTaskDialog (đã có)
- TaskDetailsDialog (đã có)

**Methods chính**:
- _buildTaskStatCard
- _buildTaskCard
- _buildEmptyTasksState
- _showAISuggestedTasks
- _showCreateTaskDialog
- _createTaskFromSuggestion
- _createAllSuggestedTasks

### 6. `documents_tab.dart` (~400 dòng)
**Chức năng**:
- Document list
- AI insights section
- Org chart, tasks, KPIs, programs summaries
- Document upload

**Providers cần**:
- companyDocumentsProvider
- documentInsightsProvider

**Methods chính**:
- _buildInsightsSection
- _buildOrgChartSummary
- _buildTasksSummary
- _buildKPIsSummary
- _buildProgramsSummary
- _buildDocumentCard
- _showDocumentDetail

### 7. `settings_tab.dart` (~300 dòng)
**Chức năng**:
- Employee management section
- Company info section
- Status management
- Dangerous actions (delete)

**Methods chính**:
- _buildSettingSection
- _buildSettingItem
- _showEditDialog
- _showChangeBusinessTypeDialog
- _toggleCompanyStatus
- _deleteCompany

### 8. `widgets/employee_card.dart` (~150 dòng)
- Display employee info với avatar
- Role badge với màu sắc
- Status indicator
- Popup menu (Edit, Toggle Status, Delete)

### 9. `widgets/task_card.dart` (~100 dòng)
- Display task info
- Priority và status badges
- Due date với warning
- Popup menu (Edit, Delete)
- Click handler để mở TaskDetailsDialog

### 10. `widgets/document_card.dart` (~80 dòng)
- Display document với file size
- Status badge
- Upload date
- Click để xem details

## 🔄 Main Page Refactoring

### `company_details_page.dart` (mới - ~200 dòng)
```dart
import 'overview_tab.dart';
import 'employees_tab.dart';
import 'tasks_tab.dart';
import 'documents_tab.dart';
import 'ai_assistant_tab.dart'; // Giữ nguyên
import 'settings_tab.dart';
import 'widgets/company_header.dart';

class CompanyDetailsPage extends ConsumerStatefulWidget {
  final String companyId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CompanyHeader(company: company, ...),
          TabBar(...),
          Expanded(
            child: TabBarView(
              children: [
                OverviewTab(company: company, companyId: widget.companyId),
                EmployeesTab(company: company, companyId: widget.companyId),
                TasksTab(company: company, companyId: widget.companyId),
                DocumentsTab(company: company, companyId: widget.companyId),
                AIAssistantTab(companyId: widget.companyId, ...),
                SettingsTab(company: company, companyId: widget.companyId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 📊 Providers Organization

### Tạo `lib/providers/company_provider.dart`
```dart
// Tập trung tất cả company-related providers
final companyDetailsProvider = ...;
final companyBranchesProvider = ...;
final companyStatsProvider = ...;
final companyServiceProvider = ...;
```

### Tạo `lib/providers/employee_provider.dart` (đã có?)
```dart
final companyEmployeesProvider = ...;
final companyEmployeesStatsProvider = ...;
```

### Tạo `lib/providers/task_provider.dart` (đã có?)
```dart
final companyTasksProvider = ...;
final companyTaskStatsProvider = ...;
final taskServiceProvider = ...;
```

### Tạo `lib/providers/document_provider.dart` (đã có?)
```dart
final companyDocumentsProvider = ...;
final documentInsightsProvider = ...;
```

## 🎯 Benefits

### Trước Refactoring:
- ❌ 1 file 3720 dòng - khó navigate
- ❌ Khó maintain và debug
- ❌ Nhiều responsibilities trong 1 file
- ❌ Code reusability thấp

### Sau Refactoring:
- ✅ ~10 files, mỗi file 100-600 dòng
- ✅ Separation of concerns rõ ràng
- ✅ Dễ test từng component
- ✅ Reusable widgets
- ✅ Dễ add features mới
- ✅ Better code organization

## 🚀 Next Steps

1. ✅ Create folder structure
2. ✅ Create company_header.dart
3. ✅ Create stat_card.dart
4. ✅ Create overview_tab.dart
5. TODO: Create employees_tab.dart
6. TODO: Create tasks_tab.dart
7. TODO: Create documents_tab.dart
8. TODO: Create settings_tab.dart
9. TODO: Create employee_card.dart
10. TODO: Create task_card.dart
11. TODO: Create document_card.dart
12. TODO: Refactor main company_details_page.dart
13. TODO: Update imports across codebase
14. TODO: Test thoroughly

## 📌 Notes

- AIAssistantTab giữ nguyên vì đã là file riêng
- Các dialog (CreateTaskDialog, EditTaskDialog, etc.) giữ nguyên
- Focus vào separation of UI logic
- Providers có thể tổ chức trong folder riêng nếu cần

---

**Status**: 🟡 In Progress (30% Complete)
**Estimate**: ~2-3 hours để hoàn thành toàn bộ refactoring
