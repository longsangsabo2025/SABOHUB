# 🚀 CRITICAL FIXES - QUICK START GUIDE

## 🎯 Immediate Actions Required

### 1️⃣ Database Migration (Backend Team)

```bash
# Run the critical schema fixes migration
cd SABOHUB
supabase db push

# Or if using raw SQL:
psql $DATABASE_URL < supabase/migrations/20251112_fix_critical_schema_issues.sql
```

**Expected Time:** 2-5 minutes  
**Downtime:** None (changes are additive)

---

### 2️⃣ Frontend Model Updates (Flutter Team)

#### Update `lib/models/attendance.dart`

```dart
class AttendanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final String? branchId;          // ✅ ADD THIS (was storeId)
  final String? scheduleId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? checkInLatitude;   // ✅ ADD THIS
  final double? checkInLongitude;  // ✅ ADD THIS
  final double? checkOutLatitude;  // ✅ ADD THIS
  final double? checkOutLongitude; // ✅ ADD THIS
  final String? notes;
  final double? totalHours;
  final bool isLate;
  final bool isEarlyLeave;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      employeeId: json['user_id'] as String,
      employeeName: json['employee_name'] as String? ?? '',
      companyId: json['company_id'] as String,
      branchId: json['branch_id'] as String?,  // ✅ Changed from store_id
      checkInLatitude: json['check_in_latitude'] as double?,    // ✅ ADD
      checkInLongitude: json['check_in_longitude'] as double?,  // ✅ ADD
      checkOutLatitude: json['check_out_latitude'] as double?,  // ✅ ADD
      checkOutLongitude: json['check_out_longitude'] as double?,// ✅ ADD
      ...
    );
  }
}
```

#### Update `lib/models/company.dart`

```dart
class Company {
  final String id;
  final String name;
  final String? legalName;          // ✅ ADD THIS
  final BusinessType businessType;
  final String? taxCode;            // ✅ ADD THIS
  final String? address;
  final String? phone;
  final String? email;
  final String? website;            // ✅ ADD THIS
  final String ownerId;             // ✅ ADD THIS (required)
  final String? logoUrl;
  final String? primaryColor;       // ✅ ADD THIS
  final String? secondaryColor;     // ✅ ADD THIS
  final String status;
  final Map<String, dynamic>? settings;  // ✅ ADD THIS
  final String? createdBy;          // ✅ ADD THIS
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      legalName: json['legal_name'] as String?,
      businessType: _parseBusinessType(json['business_type']),
      taxCode: json['tax_code'] as String?,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      ownerId: json['owner_id'] as String,
      logoUrl: json['logo_url'] as String?,
      primaryColor: json['primary_color'] as String? ?? '#007AFF',
      secondaryColor: json['secondary_color'] as String? ?? '#5856D6',
      status: json['status'] as String? ?? 'ACTIVE',
      settings: json['settings'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      deletedAt: _parseDateTime(json['deleted_at']),
    );
  }
}
```

#### Update `lib/models/branch.dart`

```dart
class Branch {
  final String id;
  final String companyId;
  final String name;
  final String? managerId;    // ✅ ADD THIS
  final String? code;         // ✅ ADD THIS
  final String? address;
  final String? phone;
  final String? email;
  final bool isActive;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      name: json['name'] as String,
      managerId: json['manager_id'] as String?,  // ✅ ADD
      code: json['code'] as String?,              // ✅ ADD
      ...
    );
  }
}
```

#### Update `lib/models/task.dart`

```dart
class Task {
  final String id;
  final String? branchId;
  final String? companyId;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskRecurrence recurrence;
  // ❌ REMOVE THIS FIELD (duplicate)
  // final String? assignedTo;
  final String? assigneeId;        // ✅ Keep only this
  final String? assignedToName;
  final String? assignedToRole;
  final int? progress;             // ✅ ADD THIS (0-100)
  ...

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      ...
      assigneeId: json['assignee_id'] as String?,  // ✅ Correct mapping
      progress: json['progress'] as int? ?? 0,     // ✅ ADD
      ...
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignee_id': assigneeId,  // ✅ Use correct column name
      'progress': progress,        // ✅ ADD
      ...
    };
  }
}
```

---

### 3️⃣ Service Updates

#### Update `lib/services/attendance_service.dart`

```dart
Future<AttendanceRecord> checkIn({
  required String userId,
  required String branchId,    // ✅ Changed from storeId
  required String companyId,   // ✅ ADD THIS parameter
  String? shiftId,
  String? location,
  double? latitude,            // ✅ ADD
  double? longitude,           // ✅ ADD
  String? photoUrl,
}) async {
  // Get employee info for caching
  final employeeResponse = await _supabase
      .from('users')
      .select('name, role')
      .eq('id', userId)
      .single();

  final response = await _supabase.from('attendance').insert({
    'user_id': userId,
    'branch_id': branchId,      // ✅ Changed from store_id
    'company_id': companyId,    // ✅ ADD THIS
    'shift_id': shiftId,
    'check_in': DateTime.now().toIso8601String(),
    'check_in_location': location,
    'check_in_latitude': latitude,    // ✅ ADD
    'check_in_longitude': longitude,  // ✅ ADD
    'check_in_photo_url': photoUrl,
    'employee_name': employeeResponse['name'],
    'employee_role': employeeResponse['role'],
    'is_late': false,
  }).select().single();

  return AttendanceRecord.fromJson(response);
}

Future<AttendanceRecord> checkOut({
  required String attendanceId,
  String? location,
  double? latitude,    // ✅ ADD
  double? longitude,   // ✅ ADD
  String? notes,
}) async {
  final response = await _supabase
      .from('attendance')
      .update({
        'check_out': DateTime.now().toIso8601String(),
        'check_out_location': location,
        'check_out_latitude': latitude,    // ✅ ADD
        'check_out_longitude': longitude,  // ✅ ADD
        'notes': notes,
      })
      .eq('id', attendanceId)
      .select()
      .single();

  return AttendanceRecord.fromJson(response);
}
```

#### Update `lib/services/task_service.dart`

```dart
Future<List<Task>> getTasksByStatus(TaskStatus status) async {
  final query = _supabase
      .from('tasks')
      .select('*')
      .eq('status', status.toDbValue())  // ✅ Always use toDbValue()
      .isFilter('deleted_at', null);

  final response = await query.order('due_date', ascending: true);
  return (response as List).map((json) => Task.fromJson(json)).toList();
}

Future<Task> createTask(Task task) async {
  final insertData = {
    'branch_id': task.branchId,
    'company_id': task.companyId,
    'title': task.title,
    'description': task.description,
    'category': task.category.name,
    'priority': task.priority.name,
    'status': task.status.toDbValue(),  // ✅ Use toDbValue()
    'assignee_id': task.assigneeId,     // ✅ Use correct field name
    'assigned_to_name': task.assignedToName,
    'assigned_to_role': task.assignedToRole,
    'progress': task.progress ?? 0,     // ✅ Include progress
    'due_date': task.dueDate.toIso8601String(),
    'created_by': task.createdBy,
    'created_by_name': task.createdByName,
    'notes': task.notes,
  };

  final response = await _supabase
      .from('tasks')
      .insert(insertData)
      .select()
      .single();

  return Task.fromJson(response);
}
```

---

## ✅ Verification Checklist

After applying all fixes, test these scenarios:

### Attendance
- [ ] Check-in with GPS location
- [ ] Check-out with GPS location
- [ ] View attendance list (CEO/Manager)
- [ ] View own attendance (Staff)

### Tasks
- [ ] Create task as CEO
- [ ] Create task as Manager
- [ ] View all tasks as CEO
- [ ] View company tasks as Manager
- [ ] View assigned tasks as Staff
- [ ] Update task progress
- [ ] Complete task

### Companies & Branches
- [ ] Create new company
- [ ] View company details with all fields
- [ ] Create branch with manager assignment
- [ ] View branch list

### File Upload
- [ ] Upload AI file
- [ ] View uploaded files
- [ ] Delete uploaded file

---

## 🐛 Common Issues & Solutions

### Issue: "relation 'profiles' does not exist"
**Solution:** Run the migration - all RLS policies have been updated to use 'users' table

### Issue: "column 'store_id' does not exist in attendance"
**Solution:** Run the migration - renamed to 'branch_id'

### Issue: "Task creation fails with status error"
**Solution:** Use `status.toDbValue()` instead of `status.name`

### Issue: "File upload returns permission denied"
**Solution:** Run the migration - storage policies now use 'users' table

---

## 📞 Support

- **Critical Issues:** Check `SUPABASE-FRONTEND-AUDIT-REPORT.md`
- **Migration Errors:** Review migration logs
- **Frontend Errors:** Check model field mappings

---

## 🎯 Success Metrics

After completing these fixes:
- ✅ 0 "relation does not exist" errors
- ✅ 0 "column does not exist" errors
- ✅ All user roles can perform their expected operations
- ✅ File uploads work correctly
- ✅ Attendance tracking works with GPS

**Estimated Fix Time:** 2-4 hours for all updates
