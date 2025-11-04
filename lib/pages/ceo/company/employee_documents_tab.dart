import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/company.dart';
import '../../../models/employee_document.dart';
import '../../../providers/cached_data_providers.dart';

/// Employee Documents Tab
/// Hiển thị hồ sơ nhân viên và hợp đồng lao động
class EmployeeDocumentsTab extends ConsumerStatefulWidget {
  final Company company;
  final String companyId;

  const EmployeeDocumentsTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  ConsumerState<EmployeeDocumentsTab> createState() => _EmployeeDocumentsTabState();
}

class _EmployeeDocumentsTabState extends ConsumerState<EmployeeDocumentsTab> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EmployeeDocumentType? _selectedDocType;
  DocumentStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_shared, color: Colors.blue[700], size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ sơ nhân viên',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Quản lý giấy tờ và hợp đồng lao động',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Sub tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue[700],
                tabs: const [
                  Tab(icon: Icon(Icons.article), text: 'Giấy tờ nhân viên'),
                  Tab(icon: Icon(Icons.description), text: 'Hợp đồng lao động'),
                ],
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDocumentsTab(),
              _buildContractsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsTab() {
    final documentsAsync = ref.watch(cachedEmployeeDocumentsProvider(widget.companyId));

    return documentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Lỗi: $error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidateEmployeeDocuments(widget.companyId),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
      data: (documents) {
        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Chưa có giấy tờ nào', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showUploadDialog,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload giấy tờ'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<EmployeeDocumentType>(
                      value: _selectedDocType,
                      decoration: const InputDecoration(
                        labelText: 'Loại giấy tờ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả')),
                        ...EmployeeDocumentType.values.map((type) =>
                          DropdownMenuItem(value: type, child: Text(type.label)),
                        ),
                      ],
                      onChanged: (value) => setState(() => _selectedDocType = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<DocumentStatus>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả')),
                        ...DocumentStatus.values.map((status) =>
                          DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status.label),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _selectedStatus = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showUploadDialog,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                  ),
                ],
              ),
            ),
            // Documents list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return _buildDocumentCard(doc);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContractsTab() {
    final contractsAsync = ref.watch(cachedLaborContractsProvider(widget.companyId));

    return contractsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Lỗi: $error'),
          ],
        ),
      ),
      data: (contracts) {
        if (contracts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('Chưa có hợp đồng nào', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final contract = contracts[index];
            return _buildContractCard(contract);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(EmployeeDocument doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: doc.status.color.withOpacity(0.1),
          child: Icon(doc.type.icon, color: doc.status.color),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Nhân viên: ${doc.employeeName}'),
            Text('Loại: ${doc.type.label}'),
            if (doc.expiryDate != null)
              Text(
                doc.isExpired
                    ? 'Hết hạn: ${_formatDate(doc.expiryDate!)}'
                    : doc.isExpiringSoon
                        ? 'Sắp hết hạn: ${_formatDate(doc.expiryDate!)}'
                        : 'Hạn: ${_formatDate(doc.expiryDate!)}',
                style: TextStyle(
                  color: doc.isExpired
                      ? Colors.red
                      : doc.isExpiringSoon
                          ? Colors.orange
                          : Colors.grey,
                  fontWeight: doc.isExpired || doc.isExpiringSoon
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (doc.isVerified)
              Icon(Icons.verified, color: Colors.green[600], size: 20)
            else
              Icon(Icons.pending, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('Xem chi tiết')),
                const PopupMenuItem(value: 'verify', child: Text('Xác minh')),
                const PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
              onSelected: (value) => _handleDocumentAction(value as String, doc),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildContractCard(LaborContract contract) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contract.status.color.withOpacity(0.1),
          child: Icon(Icons.description, color: contract.status.color),
        ),
        title: Text(
          '${contract.employeeName} - ${contract.position}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Số HĐ: ${contract.contractNumber}'),
            Text('Loại: ${contract.type.label}'),
            Text('Từ ${_formatDate(contract.startDate)}${contract.endDate != null ? " đến ${_formatDate(contract.endDate!)}" : " (Không xác định)"}'),
            if (contract.isExpiringSoon && !contract.isExpired)
              Text(
                'Sắp hết hạn (còn ${contract.daysRemaining} ngày)',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            if (contract.isExpired)
              const Text(
                'Đã hết hạn',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(contract.status.label, style: const TextStyle(fontSize: 12)),
          backgroundColor: contract.status.color.withOpacity(0.1),
          labelStyle: TextStyle(color: contract.status.color),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _handleDocumentAction(String action, EmployeeDocument doc) async {
    switch (action) {
      case 'view':
        _showDocumentDetails(doc);
        break;
      case 'verify':
        await _verifyDocument(doc.id);
        break;
      case 'delete':
        await _deleteDocument(doc.id);
        break;
    }
  }

  void _showDocumentDetails(EmployeeDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nhân viên:', doc.employeeName),
              _buildDetailRow('Loại:', doc.type.label),
              _buildDetailRow('Trạng thái:', doc.status.label),
              if (doc.description != null) _buildDetailRow('Mô tả:', doc.description!),
              if (doc.expiryDate != null) 
                _buildDetailRow('Ngày hết hạn:', _formatDate(doc.expiryDate!)),
              _buildDetailRow('Ngày upload:', _formatDate(doc.uploadDate)),
              _buildDetailRow('Đã xác minh:', doc.isVerified ? 'Có' : 'Chưa'),
              if (doc.notes != null) _buildDetailRow('Ghi chú:', doc.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _verifyDocument(String documentId) async {
    try {
      final service = ref.read(employeeDocumentServiceProvider);
      await service.verifyDocument(documentId);
      ref.invalidateEmployeeDocuments(widget.companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xác minh tài liệu'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tài liệu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(employeeDocumentServiceProvider);
        await service.deleteDocument(documentId);
        ref.invalidateEmployeeDocuments(widget.companyId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài liệu'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showUploadDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng upload đang được phát triển'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
