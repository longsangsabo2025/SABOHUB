import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_uploaded_file.dart';
import 'package:flutter/foundation.dart';

/// Service for handling file uploads for AI Assistant
class FileUploadService {
  final SupabaseClient _supabase;

  FileUploadService(this._supabase);

  /// Upload a file to Supabase Storage and create database record
  Future<AIUploadedFile> uploadFile({
    required String assistantId,
    required String companyId,
    required File file,
    required String fileName,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Determine file type and mime type
      final fileType = _getFileType(fileName);
      final mimeType = _getMimeType(fileName);
      final fileSize = await file.length();

      // Generate storage path
      final storagePath = _generateStoragePath(companyId, fileName);

      // Upload to Supabase Storage
      await _supabase.storage.from('ai-files').upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ),
          );

      // Get the public URL for the uploaded file
      final fileUrl = _supabase.storage.from('ai-files').getPublicUrl(storagePath);

      // Create database record
      final response = await _supabase
          .from('ai_uploaded_files')
          .insert({
            'assistant_id': assistantId,
            'company_id': companyId,
            'user_id': _supabase.auth.currentUser?.id,
            'file_name': fileName,
            'file_type': fileType,
            'mime_type': mimeType,
            'file_size': fileSize,
            'file_url': fileUrl,
            'status': 'uploaded',
          })
          .select()
          .single();

      return AIUploadedFile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload multiple files
  Future<List<AIUploadedFile>> uploadMultipleFiles({
    required String assistantId,
    required String companyId,
    required List<File> files,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    final uploadedFiles = <AIUploadedFile>[];

    for (final file in files) {
      try {
        final fileName = file.path.split('/').last;
        final uploadedFile = await uploadFile(
          assistantId: assistantId,
          companyId: companyId,
          file: file,
          fileName: fileName,
          tags: tags,
          metadata: metadata,
        );
        uploadedFiles.add(uploadedFile);
      } catch (e) {
        if (kDebugMode) {
          print('Failed to upload file ${file.path}: $e');
        }
        // Continue with other files
      }
    }

    return uploadedFiles;
  }

  /// Get public URL for a file
  String getFileUrl(String storagePath) {
    return _supabase.storage.from('ai-files').getPublicUrl(storagePath);
  }

  /// Download a file
  Future<List<int>> downloadFile(String storagePath) async {
    try {
      return await _supabase.storage.from('ai-files').download(storagePath);
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Delete a file from storage
  Future<void> deleteFile(String storagePath) async {
    try {
      await _supabase.storage.from('ai-files').remove([storagePath]);
    } catch (e) {
      throw Exception('Failed to delete file from storage: $e');
    }
  }

  /// Process uploaded file (extract text, analyze, etc.)
  Future<AIUploadedFile> processFile(String fileId) async {
    try {
      // Update status to processing
      await _supabase.from('ai_uploaded_files').update({
        'processing_status': 'processing',
      }).eq('id', fileId);

      // Call Edge Function to process file
      final response = await _supabase.functions.invoke(
        'process-file',
        body: {'file_id': fileId},
      );

      if (response.status != 200) {
        throw Exception('File processing failed: ${response.data}');
      }

      // Get updated file record
      final fileResponse = await _supabase
          .from('ai_uploaded_files')
          .select()
          .eq('id', fileId)
          .single();

      return AIUploadedFile.fromJson(fileResponse);
    } catch (e) {
      // Mark as failed
      await _supabase.from('ai_uploaded_files').update({
        'processing_status': 'failed',
        'processing_error': e.toString(),
      }).eq('id', fileId);

      throw Exception('Failed to process file: $e');
    }
  }

  /// Get file type from file name
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg']
        .contains(extension)) {
      return 'image';
    } else if (extension == 'pdf') {
      return 'pdf';
    } else if (['doc', 'docx', 'odt', 'rtf'].contains(extension)) {
      return 'doc';
    } else if (['xls', 'xlsx', 'ods', 'csv'].contains(extension)) {
      return 'spreadsheet';
    } else if (['txt', 'md', 'json', 'xml', 'yaml', 'yml']
        .contains(extension)) {
      return 'text';
    } else {
      return 'unknown';
    }
  }

  /// Get MIME type from file name
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    final mimeTypes = {
      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'odt': 'application/vnd.oasis.opendocument.text',
      'rtf': 'application/rtf',
      // Spreadsheets
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ods': 'application/vnd.oasis.opendocument.spreadsheet',
      'csv': 'text/csv',
      // Text
      'txt': 'text/plain',
      'md': 'text/markdown',
      'json': 'application/json',
      'xml': 'application/xml',
      'yaml': 'text/yaml',
      'yml': 'text/yaml',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Generate storage path for file
  String _generateStoragePath(String companyId, String fileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    return '$companyId/$timestamp-$cleanFileName';
  }

  /// Check if file size is within limits (10MB default)
  bool isFileSizeValid(int fileSize, {int maxSizeInMB = 10}) {
    return fileSize <= maxSizeInMB * 1024 * 1024;
  }

  /// Check if file type is supported
  bool isFileTypeSupported(String fileName) {
    final fileType = _getFileType(fileName);
    return fileType != 'unknown';
  }

  /// Get supported file extensions
  List<String> getSupportedExtensions() {
    return [
      // Images
      'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg',
      // Documents
      'pdf', 'doc', 'docx', 'odt', 'rtf',
      // Spreadsheets
      'xls', 'xlsx', 'ods', 'csv',
      // Text
      'txt', 'md', 'json', 'xml', 'yaml', 'yml',
    ];
  }

  /// Get max file size in MB
  int getMaxFileSizeInMB() {
    return 10; // 10MB default
  }
}
