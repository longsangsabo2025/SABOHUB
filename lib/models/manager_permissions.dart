/// Manager Permissions Model
/// Represents granular permissions for a Manager to access company tabs
class ManagerPermissions {
  final String id;
  final String managerId;
  final String companyId;

  // Tab View Permissions
  final bool canViewOverview;
  final bool canViewEmployees;
  final bool canViewTasks;
  final bool canViewDocuments;
  final bool canViewAiAssistant;
  final bool canViewAttendance;
  final bool canViewAccounting;
  final bool canViewEmployeeDocs;
  final bool canViewBusinessLaw;
  final bool canViewSettings;

  // Action Permissions
  final bool canCreateEmployee;
  final bool canEditEmployee;
  final bool canDeleteEmployee;
  final bool canCreateTask;
  final bool canEditTask;
  final bool canDeleteTask;
  final bool canApproveAttendance;
  final bool canEditCompanyInfo;
  final bool canManageBankAccount;

  // Metadata
  final String? grantedBy;
  final DateTime grantedAt;
  final DateTime updatedAt;
  final String? notes;

  const ManagerPermissions({
    required this.id,
    required this.managerId,
    required this.companyId,
    this.canViewOverview = true,
    this.canViewEmployees = true,
    this.canViewTasks = true,
    this.canViewDocuments = false,
    this.canViewAiAssistant = false,
    this.canViewAttendance = true,
    this.canViewAccounting = false,
    this.canViewEmployeeDocs = false,
    this.canViewBusinessLaw = false,
    this.canViewSettings = false,
    this.canCreateEmployee = false,
    this.canEditEmployee = false,
    this.canDeleteEmployee = false,
    this.canCreateTask = true,
    this.canEditTask = true,
    this.canDeleteTask = false,
    this.canApproveAttendance = true,
    this.canEditCompanyInfo = false,
    this.canManageBankAccount = false,
    this.grantedBy,
    required this.grantedAt,
    required this.updatedAt,
    this.notes,
  });

  /// Create from JSON
  factory ManagerPermissions.fromJson(Map<String, dynamic> json) {
    return ManagerPermissions(
      id: json['id'] as String,
      managerId: json['manager_id'] as String,
      companyId: json['company_id'] as String,
      canViewOverview: json['can_view_overview'] as bool? ?? true,
      canViewEmployees: json['can_view_employees'] as bool? ?? true,
      canViewTasks: json['can_view_tasks'] as bool? ?? true,
      canViewDocuments: json['can_view_documents'] as bool? ?? false,
      canViewAiAssistant: json['can_view_ai_assistant'] as bool? ?? false,
      canViewAttendance: json['can_view_attendance'] as bool? ?? true,
      canViewAccounting: json['can_view_accounting'] as bool? ?? false,
      canViewEmployeeDocs: json['can_view_employee_docs'] as bool? ?? false,
      canViewBusinessLaw: json['can_view_business_law'] as bool? ?? false,
      canViewSettings: json['can_view_settings'] as bool? ?? false,
      canCreateEmployee: json['can_create_employee'] as bool? ?? false,
      canEditEmployee: json['can_edit_employee'] as bool? ?? false,
      canDeleteEmployee: json['can_delete_employee'] as bool? ?? false,
      canCreateTask: json['can_create_task'] as bool? ?? true,
      canEditTask: json['can_edit_task'] as bool? ?? true,
      canDeleteTask: json['can_delete_task'] as bool? ?? false,
      canApproveAttendance: json['can_approve_attendance'] as bool? ?? true,
      canEditCompanyInfo: json['can_edit_company_info'] as bool? ?? false,
      canManageBankAccount: json['can_manage_bank_account'] as bool? ?? false,
      grantedBy: json['granted_by'] as String?,
      grantedAt: DateTime.parse(json['granted_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'manager_id': managerId,
      'company_id': companyId,
      'can_view_overview': canViewOverview,
      'can_view_employees': canViewEmployees,
      'can_view_tasks': canViewTasks,
      'can_view_documents': canViewDocuments,
      'can_view_ai_assistant': canViewAiAssistant,
      'can_view_attendance': canViewAttendance,
      'can_view_accounting': canViewAccounting,
      'can_view_employee_docs': canViewEmployeeDocs,
      'can_view_business_law': canViewBusinessLaw,
      'can_view_settings': canViewSettings,
      'can_create_employee': canCreateEmployee,
      'can_edit_employee': canEditEmployee,
      'can_delete_employee': canDeleteEmployee,
      'can_create_task': canCreateTask,
      'can_edit_task': canEditTask,
      'can_delete_task': canDeleteTask,
      'can_approve_attendance': canApproveAttendance,
      'can_edit_company_info': canEditCompanyInfo,
      'can_manage_bank_account': canManageBankAccount,
      'granted_by': grantedBy,
      'granted_at': grantedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Get list of enabled tabs (for UI rendering)
  List<int> getEnabledTabIndices() {
    final List<int> enabledTabs = [];
    if (canViewOverview) enabledTabs.add(0);
    if (canViewEmployees) enabledTabs.add(1);
    if (canViewTasks) enabledTabs.add(2);
    if (canViewDocuments) enabledTabs.add(3);
    if (canViewAiAssistant) enabledTabs.add(4);
    if (canViewAttendance) enabledTabs.add(5);
    if (canViewAccounting) enabledTabs.add(6);
    if (canViewEmployeeDocs) enabledTabs.add(7);
    if (canViewBusinessLaw) enabledTabs.add(8);
    if (canViewSettings) enabledTabs.add(9);
    return enabledTabs;
  }

  /// Get tab names for enabled tabs
  List<String> getEnabledTabNames() {
    final allTabs = [
      'Tổng quan',
      'Nhân viên',
      'Công việc',
      'Tài liệu',
      'AI Assistant',
      'Chấm công',
      'Kế toán',
      'Hồ sơ NV',
      'Luật DN',
      'Cài đặt',
    ];
    
    final enabledIndices = getEnabledTabIndices();
    return enabledIndices.map((index) => allTabs[index]).toList();
  }

  /// Copy with modifications
  ManagerPermissions copyWith({
    String? id,
    String? managerId,
    String? companyId,
    bool? canViewOverview,
    bool? canViewEmployees,
    bool? canViewTasks,
    bool? canViewDocuments,
    bool? canViewAiAssistant,
    bool? canViewAttendance,
    bool? canViewAccounting,
    bool? canViewEmployeeDocs,
    bool? canViewBusinessLaw,
    bool? canViewSettings,
    bool? canCreateEmployee,
    bool? canEditEmployee,
    bool? canDeleteEmployee,
    bool? canCreateTask,
    bool? canEditTask,
    bool? canDeleteTask,
    bool? canApproveAttendance,
    bool? canEditCompanyInfo,
    String? grantedBy,
    DateTime? grantedAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return ManagerPermissions(
      id: id ?? this.id,
      managerId: managerId ?? this.managerId,
      companyId: companyId ?? this.companyId,
      canViewOverview: canViewOverview ?? this.canViewOverview,
      canViewEmployees: canViewEmployees ?? this.canViewEmployees,
      canViewTasks: canViewTasks ?? this.canViewTasks,
      canViewDocuments: canViewDocuments ?? this.canViewDocuments,
      canViewAiAssistant: canViewAiAssistant ?? this.canViewAiAssistant,
      canViewAttendance: canViewAttendance ?? this.canViewAttendance,
      canViewAccounting: canViewAccounting ?? this.canViewAccounting,
      canViewEmployeeDocs: canViewEmployeeDocs ?? this.canViewEmployeeDocs,
      canViewBusinessLaw: canViewBusinessLaw ?? this.canViewBusinessLaw,
      canViewSettings: canViewSettings ?? this.canViewSettings,
      canCreateEmployee: canCreateEmployee ?? this.canCreateEmployee,
      canEditEmployee: canEditEmployee ?? this.canEditEmployee,
      canDeleteEmployee: canDeleteEmployee ?? this.canDeleteEmployee,
      canCreateTask: canCreateTask ?? this.canCreateTask,
      canEditTask: canEditTask ?? this.canEditTask,
      canDeleteTask: canDeleteTask ?? this.canDeleteTask,
      canApproveAttendance: canApproveAttendance ?? this.canApproveAttendance,
      canEditCompanyInfo: canEditCompanyInfo ?? this.canEditCompanyInfo,
      grantedBy: grantedBy ?? this.grantedBy,
      grantedAt: grantedAt ?? this.grantedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }
}
