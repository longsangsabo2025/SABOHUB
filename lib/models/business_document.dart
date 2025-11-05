import 'package:flutter/material.dart';

/// Enum cho các loại giấy tờ doanh nghiệp theo luật Việt Nam
enum BusinessDocumentType {
  // Giấy tờ thành lập
  businessLicense('Giấy phép kinh doanh', Icons.business_center,
      'Giấy chứng nhận đăng ký kinh doanh', true),
  taxCode(
      'Mã số thuế', Icons.receipt_long, 'Giấy chứng nhận đăng ký thuế', true),
  companyCharter('Điều lệ công ty', Icons.gavel, 'Điều lệ công ty', true),

  // Giấy phép hoạt động
  operatingLicense('Giấy phép hoạt động', Icons.verified,
      'Giấy phép hoạt động ngành nghề', false),
  foodSafety('ATTP', Icons.restaurant,
      'Giấy chứng nhận vệ sinh an toàn thực phẩm', false),
  fireSafety('PCCC', Icons.local_fire_department,
      'Giấy chứng nhận phòng cháy chữa cháy', true),
  environmentalLicense('Môi trường', Icons.eco, 'Giấy phép môi trường', false),

  // Hợp đồng
  leaseContract(
      'Hợp đồng thuê', Icons.home_work, 'Hợp đồng thuê mặt bằng', true),
  partnershipAgreement('Hợp đồng hợp tác', Icons.handshake,
      'Hợp đồng hợp tác kinh doanh', false),
  supplierContract('Hợp đồng nhà cung cấp', Icons.local_shipping,
      'Hợp đồng với nhà cung cấp', false),

  // Quy chế nội bộ
  laborRegulation('Quy chế lao động', Icons.rule, 'Nội quy lao động', true),
  salaryRegulation('Quy chế lương', Icons.payments, 'Quy chế trả lương', true),
  securityRegulation(
      'Quy chế bảo mật', Icons.security, 'Quy chế bảo mật thông tin', false),

  // Giấy phép lao động
  workPermit('Giấy phép lao động', Icons.work,
      'Giấy phép lao động (người nước ngoài)', false),
  socialInsuranceRegistration('Đăng ký BHXH', Icons.health_and_safety,
      'Giấy đăng ký tham gia bảo hiểm', true),

  // Báo cáo và khai báo
  annualReport(
      'Báo cáo thường niên', Icons.assessment, 'Báo cáo tài chính năm', true),
  taxDeclaration('Tờ khai thuế', Icons.description, 'Tờ khai thuế', true),

  // Khác
  intellectualProperty(
      'Sở hữu trí tuệ', Icons.copyright, 'Bằng sáng chế, nhãn hiệu', false),
  insurance('Bảo hiểm', Icons.shield, 'Hợp đồng bảo hiểm', false),
  other('Khác', Icons.insert_drive_file, 'Tài liệu khác', false);

  final String label;
  final IconData icon;
  final String description;
  final bool isRequired;

  const BusinessDocumentType(
      this.label, this.icon, this.description, this.isRequired);
}

/// Model cho tài liệu doanh nghiệp
class BusinessDocument {
  final String id;
  final String companyId;
  final BusinessDocumentType type;
  final String title;
  final String documentNumber; // Số giấy phép/quyết định
  final String? description;
  final String? fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime issueDate; // Ngày cấp
  final String issuedBy; // Cơ quan cấp
  final DateTime? expiryDate; // Ngày hết hạn
  final DateTime uploadDate;
  final String uploadedBy;
  final String? notes;
  final bool isVerified;
  final DateTime? verifiedDate;
  final String? verifiedBy;
  final BusinessDocStatus status;
  final DateTime? renewalDate; // Ngày gia hạn
  final String? renewalNotes;

  const BusinessDocument({
    required this.id,
    required this.companyId,
    required this.type,
    required this.title,
    required this.documentNumber,
    this.description,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    required this.issueDate,
    required this.issuedBy,
    this.expiryDate,
    required this.uploadDate,
    required this.uploadedBy,
    this.notes,
    this.isVerified = false,
    this.verifiedDate,
    this.verifiedBy,
    this.status = BusinessDocStatus.active,
    this.renewalDate,
    this.renewalNotes,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 &&
        daysUntilExpiry <= 90; // Cảnh báo trước 90 ngày
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final days = expiryDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  factory BusinessDocument.fromJson(Map<String, dynamic> json) {
    return BusinessDocument(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      type: BusinessDocumentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BusinessDocumentType.other,
      ),
      title: json['title'] as String,
      documentNumber: json['document_number'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      fileType: json['file_type'] as String?,
      fileSize: json['file_size'] as int?,
      issueDate: DateTime.parse(json['issue_date'] as String),
      issuedBy: json['issued_by'] as String,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      uploadDate: DateTime.parse(json['upload_date'] as String),
      uploadedBy: json['uploaded_by'] as String,
      notes: json['notes'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      verifiedDate: json['verified_date'] != null
          ? DateTime.parse(json['verified_date'] as String)
          : null,
      verifiedBy: json['verified_by'] as String?,
      status: BusinessDocStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BusinessDocStatus.active,
      ),
      renewalDate: json['renewal_date'] != null
          ? DateTime.parse(json['renewal_date'] as String)
          : null,
      renewalNotes: json['renewal_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'type': type.name,
      'title': title,
      'document_number': documentNumber,
      'description': description,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'issue_date': issueDate.toIso8601String(),
      'issued_by': issuedBy,
      'expiry_date': expiryDate?.toIso8601String(),
      'upload_date': uploadDate.toIso8601String(),
      'uploaded_by': uploadedBy,
      'notes': notes,
      'is_verified': isVerified,
      'verified_date': verifiedDate?.toIso8601String(),
      'verified_by': verifiedBy,
      'status': status.name,
      'renewal_date': renewalDate?.toIso8601String(),
      'renewal_notes': renewalNotes,
    };
  }
}

enum BusinessDocStatus {
  active('Còn hiệu lực', Colors.green),
  expired('Hết hạn', Colors.red),
  pending('Chờ cấp phép', Colors.orange),
  renewing('Đang gia hạn', Colors.blue),
  archived('Lưu trữ', Colors.grey);

  final String label;
  final Color color;
  const BusinessDocStatus(this.label, this.color);
}

/// Thông tin tóm tắt compliance (Tuân thủ pháp lý)
class ComplianceStatus {
  final int totalDocuments;
  final int requiredDocuments;
  final int compliantDocuments;
  final int expiredDocuments;
  final int expiringSoonDocuments;
  final int missingDocuments;

  const ComplianceStatus({
    required this.totalDocuments,
    required this.requiredDocuments,
    required this.compliantDocuments,
    required this.expiredDocuments,
    required this.expiringSoonDocuments,
    required this.missingDocuments,
  });

  double get complianceRate {
    if (requiredDocuments == 0) return 100.0;
    return (compliantDocuments / requiredDocuments) * 100;
  }

  ComplianceLevel get level {
    if (complianceRate >= 90) return ComplianceLevel.excellent;
    if (complianceRate >= 75) return ComplianceLevel.good;
    if (complianceRate >= 50) return ComplianceLevel.fair;
    return ComplianceLevel.poor;
  }
}

enum ComplianceLevel {
  excellent('Xuất sắc', Colors.green, Icons.check_circle),
  good('Tốt', Colors.blue, Icons.thumb_up),
  fair('Trung bình', Colors.orange, Icons.warning),
  poor('Kém', Colors.red, Icons.error);

  final String label;
  final Color color;
  final IconData icon;
  const ComplianceLevel(this.label, this.color, this.icon);
}
