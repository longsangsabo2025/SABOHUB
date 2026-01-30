import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_upload_service.dart';

/// Widget để chọn và hiển thị ảnh sản phẩm/đối tượng
/// Hỗ trợ:
/// - Hiển thị ảnh hiện tại từ URL
/// - Chọn ảnh mới từ gallery/camera
/// - Preview ảnh đã chọn trước khi upload
/// - Xóa ảnh
class SaboImagePicker extends StatefulWidget {
  /// URL ảnh hiện tại (nếu có)
  final String? currentImageUrl;
  
  /// Callback khi có ảnh mới được chọn
  final ValueChanged<XFile?> onImageSelected;
  
  /// Callback khi URL ảnh thay đổi (sau khi upload)
  final ValueChanged<String?>? onImageUrlChanged;
  
  /// Kích thước widget
  final double width;
  final double height;
  
  /// Cho phép xóa ảnh
  final bool allowDelete;
  
  /// Cho phép chụp từ camera
  final bool allowCamera;
  
  /// Border radius
  final double borderRadius;
  
  /// Placeholder widget khi chưa có ảnh
  final Widget? placeholder;
  
  /// Icon khi không có ảnh
  final IconData emptyIcon;
  
  /// Màu nền khi không có ảnh
  final Color? emptyBackgroundColor;

  const SaboImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.onImageUrlChanged,
    this.width = 120,
    this.height = 120,
    this.allowDelete = true,
    this.allowCamera = true,
    this.borderRadius = 12,
    this.placeholder,
    this.emptyIcon = Icons.add_photo_alternate_outlined,
    this.emptyBackgroundColor,
  });

  @override
  State<SaboImagePicker> createState() => _SaboImagePickerState();
}

class _SaboImagePickerState extends State<SaboImagePicker> {
  final ImageUploadService _uploadService = ImageUploadService();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.emptyBackgroundColor ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImageContent(),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              // Edit overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasImage ? Icons.edit : Icons.add_a_photo,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasImage ? 'Đổi ảnh' : 'Thêm ảnh',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasImage =>
      _selectedImageBytes != null ||
      (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty);

  Widget _buildImageContent() {
    // Show selected image preview
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      );
    }

    // Show current image from URL
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.currentImageUrl!,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'Chọn ảnh',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImageOptions() async {
    final options = <Widget>[
      ListTile(
        leading: const Icon(Icons.photo_library, color: Colors.blue),
        title: const Text('Chọn từ thư viện'),
        onTap: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
      if (widget.allowCamera)
        ListTile(
          leading: const Icon(Icons.camera_alt, color: Colors.green),
          title: const Text('Chụp ảnh mới'),
          onTap: () {
            Navigator.pop(context);
            _pickImage(ImageSource.camera);
          },
        ),
      if (_hasImage && widget.allowDelete)
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Xóa ảnh'),
          onTap: () {
            Navigator.pop(context);
            _removeImage();
          },
        ),
    ];

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn hình ảnh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...options,
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? image;
      if (source == ImageSource.gallery) {
        image = await _uploadService.pickFromGallery();
      } else {
        image = await _uploadService.pickFromCamera();
      }

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
        widget.onImageSelected(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    widget.onImageSelected(null);
    widget.onImageUrlChanged?.call(null);
  }

  /// Reset về trạng thái ban đầu
  void reset() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  /// Lấy file ảnh đã chọn
  XFile? get selectedImage => _selectedImage;
}

/// Widget đơn giản hơn chỉ hiển thị ảnh sản phẩm
class ProductImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<XFile?> onImageSelected;
  final double size;

  const ProductImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.size = 100,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  XFile? _selectedImage;
  Uint8List? _previewBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Image preview
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Chọn ảnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                if (_hasImage)
                  TextButton.icon(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (_selectedImage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '* Ảnh sẽ được upload khi lưu',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  bool get _hasImage =>
      _previewBytes != null ||
      (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty);

  Widget _buildImagePreview() {
    if (_previewBytes != null) {
      return Image.memory(
        _previewBytes!,
        fit: BoxFit.cover,
      );
    }

    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.currentImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _previewBytes = bytes;
      });
      widget.onImageSelected(image);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _previewBytes = null;
    });
    widget.onImageSelected(null);
  }
}

/// Avatar picker cho nhân viên/user
class AvatarPicker extends StatefulWidget {
  final String? currentAvatarUrl;
  final String? initials;
  final ValueChanged<XFile?> onImageSelected;
  final double size;
  final Color? backgroundColor;

  const AvatarPicker({
    super.key,
    this.currentAvatarUrl,
    this.initials,
    required this.onImageSelected,
    this.size = 80,
    this.backgroundColor,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  XFile? _selectedImage;
  Uint8List? _previewBytes;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showOptions,
      child: Stack(
        children: [
          _buildAvatar(),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_previewBytes != null) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundImage: MemoryImage(_previewBytes!),
      );
    }

    if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.size / 2,
        backgroundImage: CachedNetworkImageProvider(widget.currentAvatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: widget.initials != null ? Text(widget.initials!) : null,
      );
    }

    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: widget.backgroundColor ?? Colors.blue.shade100,
      child: widget.initials != null
          ? Text(
              widget.initials!,
              style: TextStyle(
                fontSize: widget.size / 3,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            )
          : Icon(Icons.person, size: widget.size / 2, color: Colors.blue.shade700),
    );
  }

  Future<void> _showOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_previewBytes != null || widget.currentAvatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _previewBytes = bytes;
      });
      widget.onImageSelected(image);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _previewBytes = null;
    });
    widget.onImageSelected(null);
  }
}
