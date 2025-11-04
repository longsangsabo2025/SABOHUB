import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/employee_document.dart';

class EmployeeDocumentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Lấy danh sách tài liệu của nhân viên
  Future<List<EmployeeDocument>> getEmployeeDocuments({
    required String companyId,
    String? employeeId,
    EmployeeDocumentType? type,
    bool? isVerified,
    DocumentStatus? status,
  }) async {
    try {
      // Build query step by step
      var query = _supabase
          .from('employee_documents')
          .select('*, employee:users!employee_id(id, full_name, email)')
          .eq('company_id', companyId);

      // Apply optional filters
      if (employeeId != null) {
        query = query.eq('employee_id', employeeId) as dynamic;
      }

      if (type != null) {
        query = query.eq('type', type.name) as dynamic;
      }

      if (isVerified != null) {
        query = query.eq('is_verified', isVerified) as dynamic;
      }

      if (status != null) {
        query = query.eq('status', status.name) as dynamic;
      }

      final response = await (query as dynamic).order('upload_date', ascending: false);
      
      return (response as List)
          .map((json) => EmployeeDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get employee documents: $e');
    }
  }

  /// Lấy danh sách hợp đồng lao động
  Future<List<LaborContract>> getLaborContracts({
    required String companyId,
    String? employeeId,
    ContractType? contractType,
    ContractStatus? status,
  }) async {
    try {
      var query = _supabase
          .from('labor_contracts')
          .select('*, employee:users!employee_id(id, full_name, email)')
          .eq('company_id', companyId);

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId) as dynamic;
      }

      if (contractType != null) {
        query = query.eq('contract_type', contractType.name) as dynamic;
      }

      if (status != null) {
        query = query.eq('status', status.name) as dynamic;
      }

      final response = await (query as dynamic).order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => LaborContract.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get labor contracts: $e');
    }
  }

  /// Thêm tài liệu mới
  Future<EmployeeDocument> uploadDocument({
    required String employeeId,
    required String companyId,
    required EmployeeDocumentType type,
    required String title,
    String? documentNumber,
    String? description,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? notes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'employee_id': employeeId,
        'company_id': companyId,
        'type': type.name,
        'title': title,
        'document_number': documentNumber,
        'description': description,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_size': fileSize,
        'issue_date': issueDate?.toIso8601String(),
        'expiry_date': expiryDate?.toIso8601String(),
        'uploaded_by': currentUser.id,
        'notes': notes,
        'status': 'active',
      };

      final response = await _supabase
          .from('employee_documents')
          .insert(data)
          .select()
          .single();

      return EmployeeDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Tạo hợp đồng lao động mới
  Future<LaborContract> createContract({
    required String employeeId,
    required String companyId,
    required ContractType contractType,
    required String contractNumber,
    required String position,
    String? department,
    required DateTime startDate,
    DateTime? endDate,
    DateTime? probationEndDate,
    double? basicSalary,
    Map<String, dynamic>? allowances,
    List<String>? benefits,
    String? workingHours,
    String? jobDescription,
    DateTime? signedDate,
    String? signedLocation,
    String? fileUrl,
    String? notes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'employee_id': employeeId,
        'company_id': companyId,
        'contract_type': contractType.name,
        'contract_number': contractNumber,
        'position': position,
        'department': department,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'probation_end_date': probationEndDate?.toIso8601String().split('T')[0],
        'basic_salary': basicSalary,
        'allowances': allowances,
        'benefits': benefits,
        'working_hours': workingHours,
        'job_description': jobDescription,
        'signed_date': signedDate?.toIso8601String().split('T')[0],
        'signed_location': signedLocation,
        'file_url': fileUrl,
        'status': 'active',
        'notes': notes,
        'created_by': currentUser.id,
      };

      final response = await _supabase
          .from('labor_contracts')
          .insert(data)
          .select()
          .single();

      return LaborContract.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create contract: $e');
    }
  }

  /// Xác minh tài liệu
  Future<void> verifyDocument(String documentId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('employee_documents')
          .update({
            'is_verified': true,
            'verified_date': DateTime.now().toIso8601String(),
            'verified_by': currentUser.id,
          })
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to verify document: $e');
    }
  }

  /// Cập nhật trạng thái tài liệu
  Future<void> updateDocumentStatus(String documentId, DocumentStatus status) async {
    try {
      await _supabase
          .from('employee_documents')
          .update({'status': status.name})
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to update document status: $e');
    }
  }

  /// Xóa tài liệu
  Future<void> deleteDocument(String documentId) async {
    try {
      await _supabase
          .from('employee_documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Lấy tài liệu sắp hết hạn (trong vòng 30 ngày)
  Future<List<EmployeeDocument>> getExpiringDocuments({
    required String companyId,
    int daysAhead = 30,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('employee_documents')
          .select('*, employee:users!employee_id(id, full_name, email)')
          .eq('company_id', companyId)
          .gte('expiry_date', now.toIso8601String())
          .lte('expiry_date', futureDate.toIso8601String())
          .order('expiry_date', ascending: true);

      return (response as List)
          .map((json) => EmployeeDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expiring documents: $e');
    }
  }

  /// Lấy hợp đồng sắp hết hạn
  Future<List<LaborContract>> getExpiringContracts({
    required String companyId,
    int daysAhead = 60,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('labor_contracts')
          .select('*, employee:users!employee_id(id, full_name, email)')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .gte('end_date', now.toIso8601String().split('T')[0])
          .lte('end_date', futureDate.toIso8601String().split('T')[0])
          .order('end_date', ascending: true);

      return (response as List)
          .map((json) => LaborContract.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expiring contracts: $e');
    }
  }

  /// Gia hạn hợp đồng
  Future<LaborContract> renewContract({
    required String oldContractId,
    required String contractNumber,
    required DateTime startDate,
    DateTime? endDate,
    double? basicSalary,
    Map<String, dynamic>? allowances,
    List<String>? benefits,
    String? notes,
  }) async {
    try {
      // Lấy thông tin hợp đồng cũ
      final oldContract = await _supabase
          .from('labor_contracts')
          .select()
          .eq('id', oldContractId)
          .single();

      // Cập nhật trạng thái hợp đồng cũ
      await _supabase
          .from('labor_contracts')
          .update({'status': 'expired'})
          .eq('id', oldContractId);

      // Tạo hợp đồng mới
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final newContractData = {
        'employee_id': oldContract['employee_id'],
        'company_id': oldContract['company_id'],
        'contract_type': oldContract['contract_type'],
        'contract_number': contractNumber,
        'position': oldContract['position'],
        'department': oldContract['department'],
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'basic_salary': basicSalary ?? oldContract['basic_salary'],
        'allowances': allowances ?? oldContract['allowances'],
        'benefits': benefits ?? oldContract['benefits'],
        'working_hours': oldContract['working_hours'],
        'job_description': oldContract['job_description'],
        'status': 'active',
        'notes': notes,
        'created_by': currentUser.id,
      };

      final response = await _supabase
          .from('labor_contracts')
          .insert(newContractData)
          .select()
          .single();

      return LaborContract.fromJson(response);
    } catch (e) {
      throw Exception('Failed to renew contract: $e');
    }
  }
}
