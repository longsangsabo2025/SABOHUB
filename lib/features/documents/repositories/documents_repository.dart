import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/document.dart';

/// Repository for managing documents in Supabase
class DocumentsRepository {
  final SupabaseClient _supabase;

  DocumentsRepository(this._supabase);

  /// Table name
  static const String _tableName = 'documents';

  /// Get all documents for a company
  Future<List<Document>> getDocumentsByCompany(String companyId) async {
    try {
      debugPrint('📄 Fetching documents for company: $companyId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final documents = (response as List)
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Found ${documents.length} documents');
      return documents;
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      rethrow;
    }
  }

  /// Get all documents uploaded by a user
  Future<List<Document>> getDocumentsByUser(String userId) async {
    try {
      debugPrint('📄 Fetching documents uploaded by user: $userId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('uploaded_by', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final documents = (response as List)
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Found ${documents.length} documents');
      return documents;
    } catch (e) {
      debugPrint('❌ Error fetching documents: $e');
      rethrow;
    }
  }

  /// Get documents by type
  Future<List<Document>> getDocumentsByType({
    required String companyId,
    required String documentType,
  }) async {
    try {
      debugPrint('📄 Fetching $documentType documents for company: $companyId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .eq('document_type', documentType)
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final documents = (response as List)
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ Found ${documents.length} $documentType documents');
      return documents;
    } catch (e) {
      debugPrint('❌ Error fetching documents by type: $e');
      rethrow;
    }
  }

  /// Search documents
  Future<List<Document>> searchDocuments({
    required String companyId,
    required String searchQuery,
  }) async {
    try {
      debugPrint('🔍 Searching documents with query: $searchQuery');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .eq('is_deleted', false)
          .or('file_name.ilike.%$searchQuery%,description.ilike.%$searchQuery%')
          .order('created_at', ascending: false);

      final documents = (response as List)
          .map((json) => Document.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint(
          '✅ Found ${documents.length} documents matching "$searchQuery"');
      return documents;
    } catch (e) {
      debugPrint('❌ Error searching documents: $e');
      rethrow;
    }
  }

  /// Get a single document by ID
  Future<Document?> getDocumentById(String documentId) async {
    try {
      debugPrint('📄 Fetching document: $documentId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', documentId)
          .eq('is_deleted', false)
          .single();

      final document = Document.fromJson(response);
      debugPrint('✅ Document found: ${document.fileName}');
      return document;
    } catch (e) {
      debugPrint('❌ Error fetching document: $e');
      return null;
    }
  }

  /// Get document by Google Drive file ID
  Future<Document?> getDocumentByDriveFileId(String driveFileId) async {
    try {
      debugPrint('📄 Fetching document by Drive ID: $driveFileId');

      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('google_drive_file_id', driveFileId)
          .eq('is_deleted', false)
          .maybeSingle();

      if (response == null) return null;

      final document = Document.fromJson(response);
      debugPrint('✅ Document found: ${document.fileName}');
      return document;
    } catch (e) {
      debugPrint('❌ Error fetching document by Drive ID: $e');
      return null;
    }
  }

  /// Create a new document
  Future<Document> createDocument({
    required String googleDriveFileId,
    String? googleDriveWebViewLink,
    String? googleDriveDownloadLink,
    required String fileName,
    required String fileType,
    int? fileSize,
    String? fileExtension,
    required String companyId,
    required String uploadedBy,
    String documentType = 'general',
    String? category,
    List<String>? tags,
    String? description,
  }) async {
    try {
      debugPrint('📝 Creating document: $fileName');

      final data = {
        'google_drive_file_id': googleDriveFileId,
        'google_drive_web_view_link': googleDriveWebViewLink,
        'google_drive_download_link': googleDriveDownloadLink,
        'file_name': fileName,
        'file_type': fileType,
        'file_size': fileSize,
        'file_extension': fileExtension,
        'company_id': companyId,
        'uploaded_by': uploadedBy,
        'document_type': documentType,
        'category': category,
        'tags': tags,
        'description': description,
      };

      final response =
          await _supabase.from(_tableName).insert(data).select().single();

      final document = Document.fromJson(response);
      debugPrint('✅ Document created: ${document.id}');
      return document;
    } catch (e) {
      debugPrint('❌ Error creating document: $e');
      rethrow;
    }
  }

  /// Update document metadata
  Future<Document> updateDocument({
    required String documentId,
    String? fileName,
    String? documentType,
    String? category,
    List<String>? tags,
    String? description,
  }) async {
    try {
      debugPrint('📝 Updating document: $documentId');

      final data = <String, dynamic>{};
      if (fileName != null) data['file_name'] = fileName;
      if (documentType != null) data['document_type'] = documentType;
      if (category != null) data['category'] = category;
      if (tags != null) data['tags'] = tags;
      if (description != null) data['description'] = description;

      final response = await _supabase
          .from(_tableName)
          .update(data)
          .eq('id', documentId)
          .select()
          .single();

      final document = Document.fromJson(response);
      debugPrint('✅ Document updated: ${document.fileName}');
      return document;
    } catch (e) {
      debugPrint('❌ Error updating document: $e');
      rethrow;
    }
  }

  /// Soft delete a document
  Future<bool> deleteDocument(String documentId) async {
    try {
      debugPrint('🗑️ Soft deleting document: $documentId');

      await _supabase.from(_tableName).update({
        'is_deleted': true,
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', documentId);

      debugPrint('✅ Document soft deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      return false;
    }
  }

  /// Hard delete a document (permanent)
  Future<bool> hardDeleteDocument(String documentId) async {
    try {
      debugPrint('🗑️ Hard deleting document: $documentId');

      await _supabase.from(_tableName).delete().eq('id', documentId);

      debugPrint('✅ Document permanently deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error hard deleting document: $e');
      return false;
    }
  }

  /// Get documents count by company
  Future<int> getDocumentsCount(String companyId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('company_id', companyId)
          .eq('is_deleted', false);

      return (response as List).length;
    } catch (e) {
      debugPrint('❌ Error getting documents count: $e');
      return 0;
    }
  }

  /// Get total storage used by company (in bytes)
  Future<int> getTotalStorageUsed(String companyId) async {
    try {
      final documents = await getDocumentsByCompany(companyId);
      final totalBytes = documents.fold<int>(
        0,
        (sum, doc) => sum + (doc.fileSize ?? 0),
      );
      return totalBytes;
    } catch (e) {
      debugPrint('❌ Error calculating storage: $e');
      return 0;
    }
  }

  /// Stream documents for a company (real-time)
  Stream<List<Document>> streamDocuments(String companyId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((json) =>
                json['company_id'] == companyId && json['is_deleted'] == false)
            .map((json) => Document.fromJson(json))
            .toList());
  }
}
