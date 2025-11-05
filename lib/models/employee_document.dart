import 'package:flutter/material.dart';

/// Enum cho các loại tài liệu nhân viên theo luật lao động Việt Nam
enum EmployeeDocumentType {
  // Hồ sơ cá nhân
  identityCard(
      'CMND/CCCD', Icons.badge, 'Chứng minh nhân dân/Căn cước công dân', true),
  curriculum(
      'Sơ yếu lý lịch', Icons.description, 'Sơ yếu lý lịch tự thuật', true),
  healthCertificate('Giấy khám sức khỏe', Icons.health_and_safety,
      'Giấy khám sức khỏe định kỳ', true),
  diploma('Bằng cấp', Icons.school, 'Bằng tốt nghiệp, chứng chỉ', false),
  experienceCertificate('Xác nhận kinh nghiệm', Icons.work_history,
      'Giấy xác nhận kinh nghiệm làm việc', false),

  // Hồ sơ lao động
  laborContract(
      'Hợp đồng lao động', Icons.article, 'Hợp đồng lao động chính thức', true),
  contractAppendix(
      'Phụ lục hợp đồng', Icons.note_add, 'Phụ lục/Bổ sung hợp đồng', false),
  recruitmentDecision('Quyết định tuyển dụng', Icons.how_to_reg,
      'Quyết định tuyển dụng', false),
  appointmentDecision('Quyết định bổ nhiệm', Icons.upgrade,
      'Quyết định bổ nhiệm/miễn nhiệm', false),
  jobHandover('Biên bản giao nhận', Icons.task_alt,
      'Biên bản giao nhận công việc', false),

  // Hồ sơ bảo hiểm
  socialInsuranceBook('Sổ BHXH', Icons.book, 'Sổ bảo hiểm xã hội', true),
  healthInsurance(
      'BHYT', Icons.local_hospital, 'Giấy đăng ký bảo hiểm y tế', true),
  unemploymentInsurance(
      'BHTN', Icons.security, 'Hợp đồng bảo hiểm thất nghiệp', false),

  // Giấy tờ khác
  criminalRecord(
      'Lý lịch tư pháp', Icons.gavel, 'Phiếu lý lịch tư pháp', false),
  familyRegister('Hộ khẩu', Icons.home, 'Sổ hộ khẩu', false),
  marriageCertificate(
      'Giấy kết hôn', Icons.favorite, 'Giấy chứng nhận kết hôn', false),
  birthCertificate('Giấy khai sinh', Icons.child_care, 'Giấy khai sinh', false),
  other('Khác', Icons.insert_drive_file, 'Tài liệu khác', false);

  final String label;
  final IconData icon;
  final String description;
  final bool isRequired; // Bắt buộc theo luật

  const EmployeeDocumentType(
      this.label, this.icon, this.description, this.isRequired);
}

/// Enum cho loại hợp đồng lao động theo luật
enum ContractType {
  indefinite(
      'Không xác định thời hạn', 'Hợp đồng lao động không xác định thời hạn'),
  definite('Xác định thời hạn', 'Hợp đồng từ 12 tháng đến 36 tháng'),
  seasonal('Theo mùa vụ',
      'Hợp đồng theo mùa vụ hoặc công việc nhất định dưới 12 tháng'),
  probation('Thử việc', 'Hợp đồng thử việc');

  final String label;
  final String description;
  const ContractType(this.label, this.description);
}

/// Model cho tài liệu nhân viên
class EmployeeDocument {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final EmployeeDocumentType type;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? fileType; // pdf, jpg, png, etc
  final int? fileSize; // in bytes
  final DateTime uploadDate;
  final DateTime? expiryDate; // Ngày hết hạn (nếu có)
  final String uploadedBy;
  final String? notes;
  final bool isVerified; // Đã xác minh
  final DateTime? verifiedDate;
  final String? verifiedBy;
  final DocumentStatus status;

  const EmployeeDocument({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.type,
    required this.title,
    this.description,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.uploadDate,
    this.expiryDate,
    required this.uploadedBy,
    this.notes,
    this.isVerified = false,
    this.verifiedDate,
    this.verifiedBy,
    this.status = DocumentStatus.active,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee_name'] as String? ?? '',
      companyId: json['company_id'] as String,
      type: EmployeeDocumentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmployeeDocumentType.other,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      uploadedBy: json['uploaded_by'] as String,
      notes: json['notes'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedDate: json['verified_date'] != null
          ? DateTime.parse(json['verified_date'] as String)
          : null,
      verifiedBy: json['verified_by'] as String?,
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DocumentStatus.active,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'company_id': companyId,
      'type': type.name,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'upload_date': uploadDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'uploaded_by': uploadedBy,
      'notes': notes,
      'is_verified': isVerified,
      'verified_date': verifiedDate?.toIso8601String(),
      'verified_by': verifiedBy,
      'status': status.name,
    };
  }
}

/// Trạng thái tài liệu
enum DocumentStatus {
  active('Đang hiệu lực', Colors.green),
  expired('Hết hạn', Colors.red),
  pending('Chờ xác minh', Colors.orange),
  archived('Lưu trữ', Colors.grey);

  final String label;
  final Color color;
  const DocumentStatus(this.label, this.color);
}

/// Model cho hợp đồng lao động
class LaborContract {
  final String id;
  final String employeeId;
  final String employeeName;
  final String companyId;
  final ContractType type;
  final String contractNumber;
  final DateTime signDate;
  final DateTime startDate;
  final DateTime? endDate; // null nếu không xác định thời hạn
  final String position;
  final String department;
  final double salary;
  final String? salaryNote;
  final String? workLocation;
  final String? jobDescription;
  final String? benefits; // Các quyền lợi
  final String? fileUrl;
  final ContractStatus status;
  final DateTime createdAt;
  final String createdBy;

  const LaborContract({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.companyId,
    required this.type,
    required this.contractNumber,
    required this.signDate,
    required this.startDate,
    this.endDate,
    required this.position,
    required this.department,
    required this.salary,
    this.salaryNote,
    this.workLocation,
    this.jobDescription,
    this.benefits,
    this.fileUrl,
    this.status = ContractStatus.active,
    required this.createdAt,
    required this.createdBy,
  });

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isExpiringSoon {
    if (endDate == null) return false;
    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 &&
        daysUntilExpiry <= 60; // Cảnh báo trước 60 ngày
  }

  int? get daysRemaining {
    if (endDate == null) return null;
    return endDate!.difference(DateTime.now()).inDays;
  }

  factory LaborContract.fromJson(Map<String, dynamic> json) {
    return LaborContract(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeName: json['employee']?['full_name'] as String? ?? '',
      companyId: json['company_id'] as String,
      type: ContractType.values.firstWhere(
        (e) => e.name == json['contract_type'],
        orElse: () => ContractType.indefinite,
      ),
      contractNumber: json['contract_number'] as String,
      signDate: json['signed_date'] != null
          ? DateTime.parse(json['signed_date'] as String)
          : DateTime.parse(json['created_at'] as String),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      position: json['position'] as String,
      department: json['department'] as String? ?? '',
      salary: (json['basic_salary'] as num?)?.toDouble() ?? 0.0,
      salaryNote: json['notes'] as String?,
      workLocation: json['signed_location'] as String?,
      jobDescription: json['job_description'] as String?,
      benefits: json['benefits'] != null
          ? (json['benefits'] as List).join(', ')
          : null,
      fileUrl: json['file_url'] as String?,
      status: ContractStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContractStatus.active,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'company_id': companyId,
      'contract_type': type.name,
      'contract_number': contractNumber,
      'signed_date': signDate.toIso8601String().split('T')[0],
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'position': position,
      'department': department,
      'basic_salary': salary,
      'notes': salaryNote,
      'signed_location': workLocation,
      'job_description': jobDescription,
      'benefits': benefits?.split(', ').toList(),
      'file_url': fileUrl,
      'status': status.name,
      'created_by': createdBy,
    };
  }
}

enum ContractStatus {
  active('Đang hiệu lực', Colors.green),
  expired('Hết hạn', Colors.red),
  terminated('Đã chấm dứt', Colors.orange),
  pending('Chờ ký', Colors.blue);

  final String label;
  final Color color;
  const ContractStatus(this.label, this.color);
}
