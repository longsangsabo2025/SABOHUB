import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../providers/documents_drive_provider.dart';
import '../../../providers/auth_provider.dart';
import '../models/document.dart';

/// Documents Screen - Quản lý tài liệu
class DocumentsScreen extends ConsumerStatefulWidget {
  final String companyId;

  const DocumentsScreen({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _selectedType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize and load documents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsProvider.notifier).initializeDrive();
      ref.read(documentsProvider.notifier).loadDocuments(widget.companyId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final documentsState = ref.watch(documentsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📂 Quản lý tài liệu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
        actions: [
          // Google Drive Sign-in status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: documentsState.isSignedInToDrive
                ? IconButton(
                    icon: const Icon(Icons.cloud_done, color: Colors.green),
                    tooltip: 'Đã kết nối Google Drive',
                    onPressed: () {
                      _showDriveAccountDialog();
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.cloud_off, color: Colors.orange),
                    tooltip: 'Chưa kết nối Google Drive',
                    onPressed: () {
                      _signInToDrive();
                    },
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          _buildSearchAndFilter(),
          
          // Documents List
          Expanded(
            child: documentsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : documentsState.error != null
                    ? _buildErrorWidget(documentsState.error!)
                    : _buildDocumentsList(documentsState.documents),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadDocument(authState.user?.id ?? ''),
        icon: const Icon(Icons.upload_file),
        label: const Text('Tải lên'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  /// Search & Filter Bar
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm tài liệu...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        ref.read(documentsProvider.notifier).loadDocuments(widget.companyId);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              if (value.isEmpty) {
                ref.read(documentsProvider.notifier).loadDocuments(widget.companyId);
              } else {
                ref.read(documentsProvider.notifier).searchDocuments(widget.companyId, value);
              }
            },
          ),
          const SizedBox(height: 12),
          
          // Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                ...DocumentType.values.map((type) => 
                  _buildFilterChip(type.label, type.value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Filter chip
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedType = value);
          if (value == 'all') {
            ref.read(documentsProvider.notifier).loadDocuments(widget.companyId);
          } else {
            ref.read(documentsProvider.notifier).loadDocumentsByType(widget.companyId, value);
          }
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[700],
      ),
    );
  }

  /// Documents List
  Widget _buildDocumentsList(List<Document> documents) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có tài liệu nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút "Tải lên" để thêm tài liệu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  /// Document Card
  Widget _buildDocumentCard(Document document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showDocumentDetails(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // File icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        document.fileIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // File info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.fileName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              document.fileSizeFormatted,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                DocumentType.fromValue(document.documentType).label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.purple[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _showDocumentDetails(document);
                          break;
                        case 'download':
                          _downloadDocument(document);
                          break;
                        case 'edit':
                          _editDocument(document);
                          break;
                        case 'delete':
                          _deleteDocument(document);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 8),
                            Text('Xem chi tiết'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 8),
                            Text('Tải xuống'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Description if available
              if (document.description != null && document.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  document.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Footer: Date & Uploader
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Error Widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(documentsProvider.notifier).loadDocuments(widget.companyId);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Sign in to Google Drive
  Future<void> _signInToDrive() async {
    final success = await ref.read(documentsProvider.notifier).signInToDrive();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã kết nối Google Drive'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể kết nối Google Drive'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show Drive account dialog
  void _showDriveAccountDialog() {
    final driveService = ref.read(googleDriveServiceProvider);
    final account = driveService.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tài khoản Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account != null) ...[
              Text('Email: ${account.email}'),
              const SizedBox(height: 8),
              Text('Tên: ${account.displayName ?? "N/A"}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(documentsProvider.notifier).signOutFromDrive();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã ngắt kết nối Google Drive'),
                  ),
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Upload document
  Future<void> _uploadDocument(String userId) async {
    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;

    if (!mounted) return;

    // Show upload dialog with options
    String? description;
    String selectedType = 'general';
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tải lên tài liệu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File: $fileName',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                
                // Document type
                const Text('Loại tài liệu:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: DocumentType.values.map((type) {
                    return DropdownMenuItem(
                      value: type.value,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                const Text('Mô tả (tùy chọn):'),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập mô tả về tài liệu...',
                  ),
                  onChanged: (value) => description = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performUpload(file, fileName, userId, selectedType, description);
              },
              child: const Text('Tải lên'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform upload
  Future<void> _performUpload(
    File file,
    String fileName,
    String userId,
    String documentType,
    String? description,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải lên...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Upload
    final document = await ref.read(documentsProvider.notifier).uploadFile(
      file: file,
      fileName: fileName,
      companyId: widget.companyId,
      uploadedBy: userId,
      description: description,
      documentType: documentType,
    );

    if (!mounted) return;

    Navigator.of(context).pop(); // Close loading

    if (document != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tải lên thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể tải lên tài liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show document details
  void _showDocumentDetails(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(document.fileIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                document.fileName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Kích thước', document.fileSizeFormatted),
              _buildDetailRow('Loại', DocumentType.fromValue(document.documentType).label),
              _buildDetailRow('Ngày tạo', DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt)),
              if (document.description != null && document.description!.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Mô tả:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(document.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (document.googleDriveWebViewLink != null)
            TextButton(
              onPressed: () {
                // TODO: Open web view link
                Navigator.of(context).pop();
              },
              child: const Text('Xem trong Drive'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Download document
  Future<void> _downloadDocument(Document document) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải xuống...')),
    );

    final bytes = await ref
        .read(documentsProvider.notifier)
        .downloadFile(document.googleDriveFileId);

    if (!mounted) return;

    if (bytes != null) {
      // TODO: Save bytes to file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tải xuống thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể tải xuống tài liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Edit document
  void _editDocument(Document document) {
    // TODO: Implement edit document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng chỉnh sửa đang phát triển')),
    );
  }

  /// Delete document
  Future<void> _deleteDocument(Document document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${document.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(documentsProvider.notifier)
        .deleteDocument(document);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã xóa tài liệu'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Không thể xóa tài liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
