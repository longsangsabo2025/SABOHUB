import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_document.dart';

class BusinessDocumentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Lấy danh sách tài liệu doanh nghiệp
  Future<List<BusinessDocument>> getCompanyDocuments({
    required String companyId,
    BusinessDocumentType? type,
    BusinessDocStatus? status,
    bool? isVerified,
  }) async {
    try {
      var query = _supabase
          .from('business_documents')
          .select('*')
          .eq('company_id', companyId);

      if (type != null) {
        query = query.eq('type', type.name) as dynamic;
      }

      if (status != null) {
        query = query.eq('status', status.name) as dynamic;
      }

      if (isVerified != null) {
        query = query.eq('is_verified', isVerified) as dynamic;
      }

      final response = await (query as dynamic).order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => BusinessDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get business documents: $e');
    }
  }

  /// Thêm tài liệu mới
  Future<BusinessDocument> uploadDocument({
    required String companyId,
    required BusinessDocumentType type,
    required String title,
    required String documentNumber,
    String? description,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    required DateTime issueDate,
    required String issuedBy,
    DateTime? expiryDate,
    String? notes,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = {
        'company_id': companyId,
        'type': type.name,
        'title': title,
        'document_number': documentNumber,
        'description': description,
        'file_url': fileUrl,
        'file_type': fileType,
        'file_size': fileSize,
        'issue_date': issueDate.toIso8601String().split('T')[0],
        'issued_by': issuedBy,
        'expiry_date': expiryDate?.toIso8601String().split('T')[0],
        'uploaded_by': currentUser.id,
        'notes': notes,
        'status': 'active',
      };

      final response = await _supabase
          .from('business_documents')
          .insert(data)
          .select()
          .single();

      return BusinessDocument.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
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
          .from('business_documents')
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
  Future<void> updateDocumentStatus(String documentId, BusinessDocStatus status) async {
    try {
      await _supabase
          .from('business_documents')
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
          .from('business_documents')
          .delete()
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Lấy tài liệu sắp hết hạn (trong vòng 90 ngày)
  Future<List<BusinessDocument>> getExpiringDocuments({
    required String companyId,
    int daysAhead = 90,
  }) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      final response = await _supabase
          .from('business_documents')
          .select()
          .eq('company_id', companyId)
          .gte('expiry_date', now.toIso8601String().split('T')[0])
          .lte('expiry_date', futureDate.toIso8601String().split('T')[0])
          .order('expiry_date', ascending: true);

      return (response as List)
          .map((json) => BusinessDocument.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expiring documents: $e');
    }
  }

  /// Tính toán trạng thái tuân thủ pháp lý
  Future<ComplianceStatus> calculateComplianceStatus({
    required String companyId,
  }) async {
    try {
      // Lấy tất cả tài liệu
      final allDocuments = await getCompanyDocuments(companyId: companyId);
      
      // Các loại tài liệu bắt buộc
      final requiredTypes = BusinessDocumentType.values
          .where((type) => type.isRequired)
          .toList();
      
      // Đếm số tài liệu theo tiêu chí
      final totalDocuments = allDocuments.length;
      final requiredDocuments = requiredTypes.length;
      
      // Tài liệu tuân thủ: có, còn hiệu lực, đã xác minh
      final compliantDocuments = allDocuments.where((doc) {
        final isRequired = requiredTypes.any((type) => type == doc.type);
        if (!isRequired) return false;
        
        return doc.status == BusinessDocStatus.active && 
               doc.isVerified && 
               !doc.isExpired;
      }).length;
      
      // Tài liệu hết hạn
      final expiredDocuments = allDocuments
          .where((doc) => doc.isExpired)
          .length;
      
      // Tài liệu sắp hết hạn
      final expiringSoonDocuments = allDocuments
          .where((doc) => doc.isExpiringSoon && !doc.isExpired)
          .length;
      
      // Tài liệu bắt buộc còn thiếu
      final existingRequiredTypes = allDocuments
          .where((doc) => requiredTypes.contains(doc.type))
          .map((doc) => doc.type)
          .toSet();
      final missingDocuments = requiredTypes.length - existingRequiredTypes.length;
      
      return ComplianceStatus(
        totalDocuments: totalDocuments,
        requiredDocuments: requiredDocuments,
        compliantDocuments: compliantDocuments,
        expiredDocuments: expiredDocuments,
        expiringSoonDocuments: expiringSoonDocuments,
        missingDocuments: missingDocuments,
      );
    } catch (e) {
      throw Exception('Failed to calculate compliance status: $e');
    }
  }

  /// Gia hạn tài liệu
  Future<void> renewDocument({
    required String documentId,
    required DateTime renewalDate,
    DateTime? newExpiryDate,
    String? renewalNotes,
  }) async {
    try {
      await _supabase
          .from('business_documents')
          .update({
            'renewal_date': renewalDate.toIso8601String().split('T')[0],
            'expiry_date': newExpiryDate?.toIso8601String().split('T')[0],
            'renewal_notes': renewalNotes,
            'status': 'active',
          })
          .eq('id', documentId);
    } catch (e) {
      throw Exception('Failed to renew document: $e');
    }
  }
}
