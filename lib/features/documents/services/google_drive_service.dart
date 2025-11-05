import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:mime/mime.dart';

/// Google Drive Service for file operations
class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;

  /// Scopes required for Google Drive access
  static const List<String> _scopes = [
    drive.DriveApi.driveFileScope,
    drive.DriveApi.driveAppdataScope,
  ];

  /// Initialize Google Sign-In
  Future<void> initialize() async {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
    );

    // Listen to sign-in state changes
    _googleSignIn!.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      if (account != null) {
        debugPrint('✅ Google Drive: User signed in: ${account.email}');
      } else {
        debugPrint('⚠️ Google Drive: User signed out');
      }
    });

    // Try to sign in silently
    try {
      await _googleSignIn!.signInSilently();
    } catch (e) {
      debugPrint('⚠️ Silent sign-in failed: $e');
    }
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    try {
      if (_googleSignIn == null) {
        await initialize();
      }

      final account = await _googleSignIn!.signIn();
      if (account != null) {
        _currentUser = account;

        // Get authenticated HTTP client
        final authClient = await _googleSignIn!.authenticatedClient();
        if (authClient != null) {
          _driveApi = drive.DriveApi(authClient);
          debugPrint('✅ Google Drive API initialized');
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error signing in to Google Drive: $e');
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();
      _currentUser = null;
      _driveApi = null;
      debugPrint('✅ Signed out from Google Drive');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
    }
  }

  /// Check if user is signed in
  bool get isSignedIn => _currentUser != null && _driveApi != null;

  /// Get current user
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Upload file to Google Drive
  Future<drive.File?> uploadFile({
    required File file,
    required String fileName,
    String? description,
    String? folderId,
  }) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      // Get file info
      final fileBytes = await file.readAsBytes();
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final fileSize = fileBytes.length;

      debugPrint('📤 Uploading file: $fileName');
      debugPrint('   Size: ${_formatBytes(fileSize)}');
      debugPrint('   Type: $mimeType');

      // Create Drive file metadata
      final driveFile = drive.File()
        ..name = fileName
        ..description = description
        ..mimeType = mimeType;

      // Set parent folder if provided
      if (folderId != null) {
        driveFile.parents = [folderId];
      }

      // Upload file
      final media = drive.Media(
        Stream.value(fileBytes),
        fileSize,
        contentType: mimeType,
      );

      final uploadedFile = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
        $fields:
            'id, name, mimeType, size, webViewLink, webContentLink, createdTime, modifiedTime',
      );

      debugPrint('✅ File uploaded successfully!');
      debugPrint('   ID: ${uploadedFile.id}');
      debugPrint('   Web View: ${uploadedFile.webViewLink}');

      return uploadedFile;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Download file from Google Drive
  Future<List<int>?> downloadFile(String fileId) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      debugPrint('📥 Downloading file: $fileId');

      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (var chunk in media.stream) {
        bytes.addAll(chunk);
      }

      debugPrint('✅ File downloaded: ${_formatBytes(bytes.length)}');
      return bytes;
    } catch (e) {
      debugPrint('❌ Error downloading file: $e');
      rethrow;
    }
  }

  /// Get file metadata
  Future<drive.File?> getFileMetadata(String fileId) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      final file = await _driveApi!.files.get(
        fileId,
        $fields:
            'id, name, mimeType, size, webViewLink, webContentLink, createdTime, modifiedTime, description',
      ) as drive.File;

      return file;
    } catch (e) {
      debugPrint('❌ Error getting file metadata: $e');
      return null;
    }
  }

  /// Delete file from Google Drive
  Future<bool> deleteFile(String fileId) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      debugPrint('🗑️ Deleting file: $fileId');
      await _driveApi!.files.delete(fileId);
      debugPrint('✅ File deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting file: $e');
      return false;
    }
  }

  /// List files in Google Drive
  Future<List<drive.File>> listFiles({
    String? folderId,
    int maxResults = 100,
  }) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      String query = "trashed = false";
      if (folderId != null) {
        query += " and '$folderId' in parents";
      }

      final fileList = await _driveApi!.files.list(
        q: query,
        pageSize: maxResults,
        orderBy: 'modifiedTime desc',
        $fields:
            'files(id, name, mimeType, size, webViewLink, webContentLink, createdTime, modifiedTime)',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('❌ Error listing files: $e');
      return [];
    }
  }

  /// Create folder in Google Drive
  Future<drive.File?> createFolder(String folderName,
      {String? parentFolderId}) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      if (parentFolderId != null) {
        folder.parents = [parentFolderId];
      }

      final createdFolder = await _driveApi!.files.create(
        folder,
        $fields: 'id, name, mimeType',
      );

      debugPrint(
          '✅ Folder created: ${createdFolder.name} (${createdFolder.id})');
      return createdFolder;
    } catch (e) {
      debugPrint('❌ Error creating folder: $e');
      return null;
    }
  }

  /// Search files by name
  Future<List<drive.File>> searchFiles(String searchQuery) async {
    try {
      if (!isSignedIn) {
        final signedIn = await signIn();
        if (!signedIn) {
          throw Exception('Not signed in to Google Drive');
        }
      }

      final query = "name contains '$searchQuery' and trashed = false";

      final fileList = await _driveApi!.files.list(
        q: query,
        pageSize: 50,
        orderBy: 'modifiedTime desc',
        $fields:
            'files(id, name, mimeType, size, webViewLink, createdTime, modifiedTime)',
      );

      return fileList.files ?? [];
    } catch (e) {
      debugPrint('❌ Error searching files: $e');
      return [];
    }
  }

  /// Helper: Format bytes to human readable string
  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}
