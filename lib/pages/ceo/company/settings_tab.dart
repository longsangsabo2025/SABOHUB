import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/business_type.dart';
import '../../../models/company.dart';
import '../../../services/company_service.dart';
import '../company_details_page.dart' show companyDetailsProvider;
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';

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
            title: 'Vị trí Check-in',
            items: [
              _SettingItem(
                icon: Icons.location_on,
                title: 'Cấu hình vị trí check-in',
                subtitle: company.checkInLatitude != null
                    ? 'Đã cấu hình: ${company.checkInLatitude!.toStringAsFixed(6)}, ${company.checkInLongitude!.toStringAsFixed(6)} (Bán kính: ${company.checkInRadius?.toInt() ?? 100}m)'
                    : 'Chưa cấu hình vị trí check-in',
                onTap: () => _showCheckInLocationDialog(context, ref, company),
                color: company.checkInLatitude != null
                    ? Colors.green
                    : Colors.orange,
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
          color: (item.color ?? Colors.blue).withValues(alpha: 0.1),
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
  void _showEditDialog(BuildContext context, WidgetRef ref, Company company) {
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Company company) {
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
    // Navigate to standalone create employee page
    context.push(AppRoutes.createEmployee);
  }

  Future<void> _showEmployeeListDialog(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đang được phát triển'),
      ),
    );
  }

  // Check-in Location Configuration
  Future<void> _showCheckInLocationDialog(
      BuildContext context, WidgetRef ref, Company company) async {
    await showDialog(
      context: context,
      builder: (context) => _CheckInLocationDialog(
        company: company,
        onSave: (lat, lng, radius) async {
          try {
            final service = CompanyService();
            await service.updateCompany(company.id, {
              'check_in_latitude': lat,
              'check_in_longitude': lng,
              'check_in_radius': radius,
            });

            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Đã cập nhật vị trí check-in')),
              );
              // Refresh company data
              ref.invalidate(companyDetailsProvider(company.id));
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

// Check-in Location Configuration Dialog
class _CheckInLocationDialog extends StatefulWidget {
  final Company company;
  final Function(double lat, double lng, double radius) onSave;

  const _CheckInLocationDialog({
    required this.company,
    required this.onSave,
  });

  @override
  State<_CheckInLocationDialog> createState() => _CheckInLocationDialogState();
}

class _CheckInLocationDialogState extends State<_CheckInLocationDialog> {
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _radiusController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(
      text: widget.company.checkInLatitude?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.company.checkInLongitude?.toString() ?? '',
    );
    _radiusController = TextEditingController(
      text: (widget.company.checkInRadius ?? 100.0).toString(),
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lấy vị trí hiện tại')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lấy vị trí: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cấu hình vị trí Check-in'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhân viên chỉ có thể check-in khi ở trong bán kính được thiết lập.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Latitude
            TextField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: 'Latitude (Vĩ độ)',
                hintText: 'Ví dụ: 10.762622',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            
            // Longitude
            TextField(
              controller: _lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude (Kinh độ)',
                hintText: 'Ví dụ: 106.660172',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            
            // Radius
            TextField(
              controller: _radiusController,
              decoration: const InputDecoration(
                labelText: 'Bán kính cho phép (mét)',
                hintText: 'Ví dụ: 100',
                border: OutlineInputBorder(),
                suffixText: 'm',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            // Get Current Location Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoading
                    ? 'Đang lấy vị trí...'
                    : 'Lấy vị trí hiện tại'),
              ),
            ),
            
            const SizedBox(height: 8),
            const Text(
              '💡 Mẹo: Đến đúng vị trí công ty và bấm "Lấy vị trí hiện tại"',
              style: TextStyle(fontSize: 12, color: Colors.blue),
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
            final lat = double.tryParse(_latController.text);
            final lng = double.tryParse(_lngController.text);
            final radius = double.tryParse(_radiusController.text) ?? 100.0;
            
            if (lat == null || lng == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Vui lòng nhập tọa độ hợp lệ')),
              );
              return;
            }
            
            widget.onSave(lat, lng, radius);
          },
          child: const Text('Lưu'),
        ),
      ],
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
