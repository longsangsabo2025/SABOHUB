import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/business_type.dart';
import '../../../models/company.dart';
import '../../../services/company_service.dart';
import '../create_employee_simple_dialog.dart';

/// Settings Tab for Company Details
/// Shows company settings, edit options, and dangerous actions
class SettingsTab extends ConsumerWidget {
  final Company company;
  final String companyId;

  const SettingsTab({
    super.key,
    required this.company,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cài đặt công ty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Employee Management Section
          _buildSettingSection(
            title: 'Quản lý nhân viên',
            items: [
              _SettingItem(
                icon: Icons.person_add,
                title: 'Tạo tài khoản nhân viên',
                subtitle: 'Tạo tài khoản cho quản lý, trưởng ca, nhân viên',
                onTap: () => _showCreateEmployeeDialog(context, company),
                color: Colors.blue,
              ),
              _SettingItem(
                icon: Icons.people,
                title: 'Danh sách nhân viên',
                subtitle: 'Xem và quản lý tài khoản nhân viên',
                onTap: () => _showEmployeeListDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingSection(
            title: 'Thông tin chung',
            items: [
              _SettingItem(
                icon: Icons.edit,
                title: 'Chỉnh sửa thông tin',
                subtitle: 'Cập nhật tên, địa chỉ, liên hệ',
                onTap: () => _showEditDialog(context, ref, company),
              ),
              _SettingItem(
                icon: Icons.category,
                title: 'Thay đổi loại hình',
                subtitle: 'Chọn loại hình kinh doanh',
                onTap: () =>
                    _showChangeBusinessTypeDialog(context, ref, company),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Trạng thái',
            items: [
              _SettingItem(
                icon: company.status == 'active'
                    ? Icons.pause_circle
                    : Icons.play_circle,
                title: company.status == 'active'
                    ? 'Tạm dừng hoạt động'
                    : 'Kích hoạt lại',
                subtitle: company.status == 'active'
                    ? 'Tạm dừng hoạt động công ty'
                    : 'Tiếp tục hoạt động',
                onTap: () => _toggleCompanyStatus(context, ref, company),
                color:
                    company.status == 'active' ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'Nguy hiểm',
            items: [
              _SettingItem(
                icon: Icons.delete_forever,
                title: 'Xóa công ty',
                subtitle: 'Xóa vĩnh viễn công ty và toàn bộ dữ liệu',
                onTap: () => _showDeleteDialog(context, ref, company),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<_SettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: Colors.grey[200]),
                _buildSettingItem(items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(_SettingItem item) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (item.color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: item.color ?? Colors.blue[700],
          size: 20,
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: item.color,
        ),
      ),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: const TextStyle(fontSize: 12))
          : null,
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: item.onTap,
    );
  }

  // Dialog Methods
  void _showEditDialog(
      BuildContext context, WidgetRef ref, Company company) {
    final nameController = TextEditingController(text: company.name);
    final addressController = TextEditingController(text: company.address);
    final phoneController = TextEditingController(text: company.phone ?? '');
    final emailController = TextEditingController(text: company.email ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa công ty'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên công ty *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên công ty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final service = CompanyService();
                  await service.updateCompany(company.id, {
                    'name': nameController.text.trim(),
                    'address': addressController.text.trim(),
                    'phone': phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    'email': emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cập nhật công ty thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showChangeBusinessTypeDialog(
      BuildContext context, WidgetRef ref, Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi loại hình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BusinessType.values.map((type) {
            return RadioListTile<BusinessType>(
              value: type,
              groupValue: company.type,
              title: Text(type.label),
              onChanged: (value) async {
                if (value != null) {
                  await _updateBusinessType(context, ref, company, value);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Company company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa công ty "${company.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCompany(context, ref, company);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  Future<void> _updateBusinessType(BuildContext context, WidgetRef ref,
      Company company, BusinessType newType) async {
    try {
      final service = CompanyService();
      await service.updateCompany(company.id, {
        'business_type': newType.toString().split('.').last,
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật loại hình')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _toggleCompanyStatus(
      BuildContext context, WidgetRef ref, Company company) async {
    final newStatus = company.status == 'active' ? 'inactive' : 'active';
    try {
      final service = CompanyService();
      await service.updateCompany(company.id, {
        'is_active': newStatus == 'active',
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'active'
                ? 'Đã kích hoạt công ty'
                : 'Đã tạm dừng công ty'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _deleteCompany(
      BuildContext context, WidgetRef ref, Company company) async {
    try {
      final service = CompanyService();
      await service.deleteCompany(company.id);
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Return to companies list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa công ty')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // Employee Management Methods
  Future<void> _showCreateEmployeeDialog(
      BuildContext context, Company company) async {
    await showDialog(
      context: context,
      builder: (context) => CreateEmployeeSimpleDialog(
        company: company,
      ),
    );
  }

  Future<void> _showEmployeeListDialog(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đang được phát triển'),
      ),
    );
  }
}

// Helper class for setting items
class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.color,
  });
}
