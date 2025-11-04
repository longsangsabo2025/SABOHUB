import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/documents/models/document.dart';
import '../features/documents/repositories/documents_repository.dart';
import '../features/documents/services/google_drive_service.dart';

/// Provider for Supabase client
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for Documents Repository
final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DocumentsRepository(supabase);
});

/// Provider for Google Drive Service
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

/// State for documents
class DocumentsState {
  final List<Document> documents;
  final bool isLoading;
  final String? error;
  final bool isSignedInToDrive;

  const DocumentsState({
    this.documents = const [],
    this.isLoading = false,
    this.error,
    this.isSignedInToDrive = false,
  });

  DocumentsState copyWith({
    List<Document>? documents,
    bool? isLoading,
    String? error,
    bool? isSignedInToDrive,
  }) {
    return DocumentsState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSignedInToDrive: isSignedInToDrive ?? this.isSignedInToDrive,
    );
  }
}

/// Documents Notifier
class DocumentsNotifier extends Notifier<DocumentsState> {
  late final DocumentsRepository _repository;
  late final GoogleDriveService _driveService;

  @override
  DocumentsState build() {
    _repository = ref.read(documentsRepositoryProvider);
    _driveService = ref.read(googleDriveServiceProvider);
    return const DocumentsState();
  }

  /// Initialize Google Drive
  Future<void> initializeDrive() async {
    try {
      await _driveService.initialize();
      state = state.copyWith(
        isSignedInToDrive: _driveService.isSignedIn,
      );
    } catch (e) {
      debugPrint('❌ Error initializing Google Drive: $e');
    }
  }

  /// Sign in to Google Drive
  Future<bool> signInToDrive() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final success = await _driveService.signIn();
      state = state.copyWith(
        isLoading: false,
        isSignedInToDrive: success,
      );
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign in: $e',
      );
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOutFromDrive() async {
    try {
      await _driveService.signOut();
      state = state.copyWith(isSignedInToDrive: false);
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  /// Load documents for a company
  Future<void> loadDocuments(String companyId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final documents = await _repository.getDocumentsByCompany(companyId);
      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents: $e',
      );
    }
  }

  /// Upload file to Google Drive and save metadata
  Future<Document?> uploadFile({
    required File file,
    required String fileName,
    required String companyId,
    required String uploadedBy,
    String? description,
    String documentType = 'general',
    String? category,
    List<String>? tags,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if signed in to Drive
      if (!_driveService.isSignedIn) {
        final signedIn = await signInToDrive();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      // Upload to Google Drive
      final driveFile = await _driveService.uploadFile(
        file: file,
        fileName: fileName,
        description: description,
      );

      if (driveFile == null) {
        throw Exception('Failed to upload file to Google Drive');
      }

      // Extract file info
      final fileExtension = fileName.contains('.')
          ? fileName.split('.').last
          : null;

      // Save metadata to Supabase
      final document = await _repository.createDocument(
        googleDriveFileId: driveFile.id!,
        googleDriveWebViewLink: driveFile.webViewLink,
        googleDriveDownloadLink: driveFile.webContentLink,
        fileName: fileName,
        fileType: driveFile.mimeType ?? 'application/octet-stream',
        fileSize: driveFile.size != null ? int.parse(driveFile.size!) : null,
        fileExtension: fileExtension,
        companyId: companyId,
        uploadedBy: uploadedBy,
        documentType: documentType,
        category: category,
        tags: tags,
        description: description,
      );

      // Update state
      state = state.copyWith(
        documents: [document, ...state.documents],
        isLoading: false,
      );

      return document;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload file: $e',
      );
      return null;
    }
  }

  /// Download file from Google Drive
  Future<List<int>?> downloadFile(String googleDriveFileId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      if (!_driveService.isSignedIn) {
        final signedIn = await signInToDrive();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      final bytes = await _driveService.downloadFile(googleDriveFileId);
      state = state.copyWith(isLoading: false);
      return bytes;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to download file: $e',
      );
      return null;
    }
  }

  /// Delete document (soft delete in Supabase + hard delete from Drive)
  Future<bool> deleteDocument(Document document) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Soft delete from Supabase
      final success = await _repository.deleteDocument(document.id);
      if (!success) {
        throw Exception('Failed to delete document from database');
      }

      // Delete from Google Drive
      if (_driveService.isSignedIn) {
        await _driveService.deleteFile(document.googleDriveFileId);
      }

      // Update state
      state = state.copyWith(
        documents: state.documents
            .where((doc) => doc.id != document.id)
            .toList(),
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete document: $e',
      );
      return false;
    }
  }

  /// Update document metadata
  Future<Document?> updateDocument({
    required String documentId,
    String? fileName,
    String? documentType,
    String? category,
    List<String>? tags,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedDoc = await _repository.updateDocument(
        documentId: documentId,
        fileName: fileName,
        documentType: documentType,
        category: category,
        tags: tags,
        description: description,
      );

      // Update state
      final updatedList = state.documents.map((doc) {
        return doc.id == documentId ? updatedDoc : doc;
      }).toList();

      state = state.copyWith(
        documents: updatedList,
        isLoading: false,
      );

      return updatedDoc;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update document: $e',
      );
      return null;
    }
  }

  /// Search documents
  Future<void> searchDocuments(String companyId, String query) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final documents = await _repository.searchDocuments(
        companyId: companyId,
        searchQuery: query,
      );
      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search documents: $e',
      );
    }
  }

  /// Get documents by type
  Future<void> loadDocumentsByType(String companyId, String documentType) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final documents = await _repository.getDocumentsByType(
        companyId: companyId,
        documentType: documentType,
      );
      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents: $e',
      );
    }
  }
}

/// Documents Provider
final documentsProvider = NotifierProvider<DocumentsNotifier, DocumentsState>(
  DocumentsNotifier.new,
);

/// Stream provider for real-time documents
final documentsStreamProvider = StreamProvider.family<List<Document>, String>(
  (ref, companyId) {
    final repository = ref.watch(documentsRepositoryProvider);
    return repository.streamDocuments(companyId);
  },
);
