import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/supabase_service.dart';
import '../providers/auth_provider.dart';

/// ⚠️⚠️⚠️ CRITICAL AUTHENTICATION ARCHITECTURE ⚠️⚠️⚠️
/// **EMPLOYEE KHÔNG CÓ TÀI KHOẢN AUTH SUPABASE!**
/// - Employee login qua mã nhân viên, KHÔNG có trong auth.users  
/// - ❌ KHÔNG ĐƯỢC dùng `supabase.auth.currentUser?.id`
/// - ✅ Dùng `ref.read(authProvider).user?.id` để lấy employee_id

/// Bug Report Dialog Widget
/// Allows users to report bugs/issues with optional screenshot
class BugReportDialog extends ConsumerStatefulWidget {
  const BugReportDialog({super.key});

  /// Show the bug report dialog
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BugReportDialog(),
    );
  }

  @override
  ConsumerState<BugReportDialog> createState() => _BugReportDialogState();
}

class _BugReportDialogState extends ConsumerState<BugReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isSubmitting = false;
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String _selectedCategory = 'bug';

  final List<Map<String, dynamic>> _categories = [
    {'value': 'bug', 'label': 'Lỗi phần mềm', 'icon': Icons.bug_report},
    {'value': 'ui', 'label': 'Giao diện', 'icon': Icons.design_services},
    {'value': 'performance', 'label': 'Hiệu suất chậm', 'icon': Icons.speed},
    {'value': 'data', 'label': 'Dữ liệu sai', 'icon': Icons.storage},
    {'value': 'feature', 'label': 'Đề xuất tính năng', 'icon': Icons.lightbulb},
    {'value': 'other', 'label': 'Khác', 'icon': Icons.help_outline},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chụp ảnh: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBytes = null;
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = SupabaseService().client;
      
      String? imageUrl;

      // Upload image if selected
      if (_selectedImage != null && _imageBytes != null) {
        final fileExt = _selectedImage!.name.split('.').last;
        final fileName = '${Random().nextDouble()}.$fileExt';
        
        await supabase.storage
            .from('bug-reports')
            .uploadBinary(fileName, _imageBytes!);

        imageUrl = supabase.storage
            .from('bug-reports')
            .getPublicUrl(fileName);
      }

      // Insert bug report
      // ⚠️ Dùng authProvider để lấy employee_id thay vì supabase.auth.currentUser
      final currentEmployee = ref.read(authProvider).user;
      
      await supabase.from('bug_reports').insert({
        'title': _titleController.text.trim(),
        'description': '[$_selectedCategory] ${_descriptionController.text.trim()}',
        'image_url': imageUrl,
        'user_id': null, // Employee không có auth user
        'employee_id': currentEmployee?.id,
        'status': 'open',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Đã gửi báo cáo lỗi! Cảm ơn bạn đã đóng góp.')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi báo cáo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.bug_report, color: Colors.red.shade700, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo lỗi',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        Text(
                          'Giúp chúng tôi cải thiện hệ thống',
                          style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category selection
                      Text(
                        'Loại vấn đề',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat['value'];
                          return ChoiceChip(
                            avatar: Icon(
                              cat['icon'] as IconData,
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            label: Text(cat['label'] as String),
                            selected: isSelected,
                            selectedColor: colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat['value'] as String);
                              }
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề *',
                          hintText: 'VD: Không thể tạo đơn hàng mới',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          if (value.trim().length < 5) {
                            return 'Tiêu đề quá ngắn (tối thiểu 5 ký tự)';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Mô tả chi tiết *',
                          hintText: 'Mô tả lỗi bạn gặp phải, các bước tái hiện lỗi...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.description),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng mô tả vấn đề';
                          }
                          if (value.trim().length < 10) {
                            return 'Mô tả quá ngắn (tối thiểu 10 ký tự)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Image attachment
                      Text(
                        'Đính kèm hình ảnh (tùy chọn)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_imageBytes != null) ...[
                        // Show selected image
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  onPressed: _removeImage,
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  iconSize: 20,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Image picker buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Chọn ảnh'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _takeScreenshot,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Chụp ảnh'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mô tả chi tiết giúp chúng tôi xử lý nhanh hơn. Hãy bao gồm: bạn đang làm gì, điều gì xảy ra, và điều gì bạn mong đợi.',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submitReport,
                      icon: _isSubmitting 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick button to show bug report dialog
class BugReportButton extends StatelessWidget {
  final bool showLabel;
  final Color? color;
  
  const BugReportButton({
    super.key, 
    this.showLabel = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return ListTile(
        leading: Icon(Icons.bug_report_outlined, color: color ?? Colors.red),
        title: const Text('Báo cáo lỗi'),
        subtitle: const Text('Gửi phản hồi về vấn đề gặp phải'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => BugReportDialog.show(context),
      );
    }
    
    return IconButton(
      icon: Icon(Icons.bug_report_outlined, color: color),
      tooltip: 'Báo cáo lỗi',
      onPressed: () => BugReportDialog.show(context),
    );
  }
}
