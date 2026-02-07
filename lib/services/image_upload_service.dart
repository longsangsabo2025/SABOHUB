import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Service thống nhất cho việc upload và quản lý hình ảnh trong ứng dụng
/// 
/// Hỗ trợ:
/// - Upload ảnh sản phẩm
/// - Upload ảnh đại diện (avatar)
/// - Upload ảnh khách hàng
/// - Upload ảnh công ty
/// - Hỗ trợ cả mobile và web
class ImageUploadService {
  final SupabaseClient _supabase;
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  ImageUploadService([SupabaseClient? supabase])
      : _supabase = supabase ?? Supabase.instance.client;

  /// Các bucket storage được sử dụng
  static const String bucketProducts = 'product-images';
  static const String bucketAvatars = 'avatars';
  static const String bucketCustomers = 'customer-images';
  static const String bucketCompanies = 'company-images';
  static const String bucketGeneral = 'uploads';
  static const String bucketPaymentProofs = 'payment-proofs';
  static const String bucketInvoiceImages = 'invoice-images';

  /// Chọn ảnh từ gallery
  Future<XFile?> pickFromGallery({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Chụp ảnh từ camera
  Future<XFile?> pickFromCamera({
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Upload ảnh sản phẩm
  Future<String?> uploadProductImage({
    required XFile imageFile,
    required String companyId,
    required String productId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketProducts,
      folder: companyId,
      filePrefix: productId,
    );
  }

  /// Upload ảnh đại diện nhân viên
  Future<String?> uploadAvatar({
    required XFile imageFile,
    required String companyId,
    required String userId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketAvatars,
      folder: companyId,
      filePrefix: userId,
    );
  }

  /// Upload ảnh khách hàng
  Future<String?> uploadCustomerImage({
    required XFile imageFile,
    required String companyId,
    required String customerId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketCustomers,
      folder: companyId,
      filePrefix: customerId,
    );
  }

  /// Upload ảnh công ty/logo
  Future<String?> uploadCompanyImage({
    required XFile imageFile,
    required String companyId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketCompanies,
      folder: 'logos',
      filePrefix: companyId,
    );
  }

  /// Upload ảnh tổng quát
  Future<String?> uploadGeneralImage({
    required XFile imageFile,
    required String folder,
    String? filePrefix,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketGeneral,
      folder: folder,
      filePrefix: filePrefix,
    );
  }

  /// Upload ảnh chứng minh thanh toán (chuyển khoản)
  Future<String?> uploadPaymentProof({
    required XFile imageFile,
    required String companyId,
    String? paymentId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketPaymentProofs,
      folder: companyId,
      filePrefix: paymentId ?? 'payment',
    );
  }

  /// Upload ảnh hóa đơn đơn hàng
  Future<String?> uploadInvoiceImage({
    required XFile imageFile,
    required String companyId,
    String? orderId,
  }) async {
    return _uploadImage(
      imageFile: imageFile,
      bucket: bucketInvoiceImages,
      folder: companyId,
      filePrefix: orderId ?? 'invoice',
    );
  }

  /// Core upload method - Hỗ trợ cả web và mobile
  Future<String?> _uploadImage({
    required XFile imageFile,
    required String bucket,
    required String folder,
    String? filePrefix,
  }) async {
    try {
      // Generate unique filename
      final extension = _getExtension(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = _uuid.v4().substring(0, 8);
      final prefix = filePrefix != null ? '${filePrefix}_' : '';
      final fileName = '$prefix${timestamp}_$uniqueId$extension';
      final storagePath = '$folder/$fileName';

      // Get file bytes - works on both web and mobile
      final Uint8List bytes = await imageFile.readAsBytes();
      final mimeType = _getMimeType(imageFile.path);

      // Upload to Supabase Storage
      await _supabase.storage.from(bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Xóa ảnh từ storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Parse bucket and path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find storage path after "storage/v1/object/public/"
      final storageIndex = pathSegments.indexOf('storage');
      if (storageIndex == -1) return false;
      
      // Get bucket and file path
      final bucket = pathSegments[storageIndex + 4]; // After storage/v1/object/public/
      final filePath = pathSegments.sublist(storageIndex + 5).join('/');
      
      await _supabase.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Get file extension
  String _getExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot != -1) {
      return path.substring(lastDot).toLowerCase();
    }
    return '.jpg';
  }

  /// Get MIME type from file extension
  String _getMimeType(String path) {
    final ext = _getExtension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Debug print for non-release builds only
  void debugPrint(String message) {
    // Only print in debug mode, not in production
    if (!kReleaseMode) {
      // ignore: avoid_print
      print('[ImageUploadService] $message');
    }
  }
}

/// Extension để dễ sử dụng ImagePicker
extension ImagePickerExt on ImagePicker {
  /// Hiện dialog chọn nguồn ảnh (Gallery hoặc Camera)
  static Future<ImageSource?> showImageSourceDialog(dynamic context) async {
    // This will be implemented in the widget layer
    return null;
  }
}
