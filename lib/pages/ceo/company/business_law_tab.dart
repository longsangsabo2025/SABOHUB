import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/business_document.dart';
import '../../../models/company.dart';
import '../../../providers/cached_data_providers.dart';

/// Business Law Tab
/// Hiển thị tài liệu pháp lý doanh nghiệp và compliance status
class BusinessLawTab extends ConsumerWidget {
  final Company company;
  final String companyId;

  const BusinessLawTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(cachedBusinessDocumentsProvider(companyId));
    final complianceAsync = ref.watch(cachedComplianceStatusProvider(companyId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.blue[700], size: 32),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Luật doanh nghiệp',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Quản lý giấy tờ pháp lý và tuân thủ',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Compliance Status
          complianceAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
            data: (compliance) => _buildComplianceCard(context, compliance),
          ),
          
          const SizedBox(height: 24),
          
          // Documents List
          const Text(
            'Danh sách tài liệu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          documentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Lỗi: $error', style: const TextStyle(color: Colors.red)),
            ),
            data: (documents) {
              if (documents.isEmpty) {
                return Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Chưa có tài liệu pháp lý nào', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }
              
              return Column(
                children: documents.map((doc) => _buildDocumentCard(context, ref, doc)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceCard(BuildContext context, ComplianceStatus compliance) {
    final level = compliance.level;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(level.icon, color: level.color, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mức độ tuân thủ: ${level.label}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: level.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${compliance.complianceRate.toStringAsFixed(1)}% tài liệu bắt buộc đã tuân thủ',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tổng tài liệu',
                    compliance.totalDocuments.toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Bắt buộc',
                    compliance.requiredDocuments.toString(),
                    Icons.star,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Đang tuân thủ',
                    compliance.compliantDocuments.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Thiếu',
                    compliance.missingDocuments.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Hết hạn',
                    compliance.expiredDocuments.toString(),
                    Icons.error,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sắp hết hạn',
                    compliance.expiringSoonDocuments.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, WidgetRef ref, BusinessDocument doc) {
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
            Text('Loại: ${doc.type.label}'),
            Text('Số: ${doc.documentNumber}'),
            Text('Cơ quan cấp: ${doc.issuedBy}'),
            if (doc.expiryDate != null)
              Text(
                doc.isExpired
                    ? 'Hết hạn: ${_formatDate(doc.expiryDate!)}'
                    : doc.isExpiringSoon
                        ? 'Sắp hết hạn: ${_formatDate(doc.expiryDate!)} (còn ${doc.daysUntilExpiry} ngày)'
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
            Chip(
              label: Text(doc.status.label, style: const TextStyle(fontSize: 12)),
              backgroundColor: doc.status.color.withOpacity(0.1),
              labelStyle: TextStyle(color: doc.status.color),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
