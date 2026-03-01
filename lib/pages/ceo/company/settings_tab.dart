import 'package:flutter/material.dart';
import '../../../utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/business_type.dart';
import '../../../models/company.dart';
import '../../../models/manager_permissions.dart';
import '../../../providers/company_provider.dart';
import '../../../providers/manager_permissions_provider.dart';
import '../../../providers/auth_provider.dart';
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
    // Get current user info from authProvider
    final authUser = ref.read(authProvider).user;
    final isUserCEO = authUser?.role.toString().toLowerCase().contains('ceo') ?? false;
    final currentUserId = authUser?.id;
    
    // For managers, check permissions
    final managerPermissionsAsync = isUserCEO || currentUserId == null
        ? null 
        : ref.watch(managerPermissionsByCompanyProvider({
            'managerId': currentUserId,
            'companyId': companyId,
          }));
    
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
          
          // Bank Account Section - Show for CEO or Manager with permission
          if (_canManageBankAccount(isUserCEO, managerPermissionsAsync))
            ...[
              _buildBankAccountSection(context, ref, company),
              const SizedBox(height: 24),
            ],
          
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

  /// Check if current user can manage bank account
  bool _canManageBankAccount(bool isUserCEO, AsyncValue<ManagerPermissions?>? managerPermissionsAsync) {
    // CEO always has access
    if (isUserCEO) return true;
    
    // For managers, check permissions
    if (managerPermissionsAsync != null) {
      return managerPermissionsAsync.when(
        data: (permissions) => permissions?.canManageBankAccount ?? false,
        loading: () => false,
        error: (_, __) => false,
      );
    }
    
    return false;
  }

  // Common banks with BIN codes
  static final List<Map<String, String>> _banks = [
    {'name': 'Vietcombank', 'bin': '970436'},
    {'name': 'BIDV', 'bin': '970418'},
    {'name': 'VietinBank', 'bin': '970415'},
    {'name': 'Techcombank', 'bin': '970407'},
    {'name': 'MB Bank', 'bin': '970422'},
    {'name': 'ACB', 'bin': '970416'},
    {'name': 'Sacombank', 'bin': '970403'},
    {'name': 'VPBank', 'bin': '970432'},
    {'name': 'TPBank', 'bin': '970423'},
    {'name': 'Agribank', 'bin': '970405'},
    {'name': 'SHB', 'bin': '970443'},
    {'name': 'HDBank', 'bin': '970437'},
    {'name': 'OCB', 'bin': '970448'},
    {'name': 'SeABank', 'bin': '970440'},
    {'name': 'VIB', 'bin': '970441'},
  ];

  /// Build bank account section with dual account support
  Widget _buildBankAccountSection(BuildContext context, WidgetRef ref, Company company) {
    final hasBank1 = company.bankAccountNumber != null && company.bankAccountNumber!.isNotEmpty;
    final hasBank2 = company.hasBankAccount2;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tài khoản ngân hàng (Chuyển khoản)',
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
              // Bank Account 1
              _buildBankAccountTile(
                context: context,
                ref: ref,
                company: company,
                accountNumber: 1,
                bankName: company.bankName,
                accountNo: company.bankAccountNumber,
                accountName: company.bankAccountName,
                bankBin: company.bankBin,
                isActive: company.activeBankAccount == 1,
                isConfigured: hasBank1,
              ),
              if (hasBank2 || hasBank1) Divider(height: 1, color: Colors.grey[200]),
              // Bank Account 2
              _buildBankAccountTile(
                context: context,
                ref: ref,
                company: company,
                accountNumber: 2,
                bankName: company.bankName2,
                accountNo: company.bankAccountNumber2,
                accountName: company.bankAccountName2,
                bankBin: company.bankBin2,
                isActive: company.activeBankAccount == 2,
                isConfigured: hasBank2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountTile({
    required BuildContext context,
    required WidgetRef ref,
    required Company company,
    required int accountNumber,
    required String? bankName,
    required String? accountNo,
    required String? accountName,
    required String? bankBin,
    required bool isActive,
    required bool isConfigured,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.green.withValues(alpha: 0.1) 
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.account_balance,
              color: isActive ? Colors.green[700] : Colors.grey[600],
              size: 20,
            ),
            if (isActive)
              Positioned(
                right: -2,
                top: -2,
                child: Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
              ),
          ],
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'TK $accountNumber${isActive ? " (Đang dùng)" : ""}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.green[700] : null,
              ),
            ),
          ),
          if (isConfigured && !isActive)
            SizedBox(
              height: 28,
              child: TextButton(
                onPressed: () => _switchActiveBankAccount(context, ref, company, accountNumber),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Chuyển sang', style: TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
      subtitle: isConfigured
          ? Text(
              '${bankName ?? "Ngân hàng"} - $accountNo\n$accountName',
              style: const TextStyle(fontSize: 12),
            )
          : const Text('Chưa cấu hình', style: TextStyle(fontSize: 12, color: Colors.orange)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () => _showBankAccountDialog(context, ref, company, accountNumber),
      isThreeLine: isConfigured,
    );
  }

  Future<void> _switchActiveBankAccount(BuildContext context, WidgetRef ref, Company company, int newActive) async {
    try {
      final service = CompanyService();
      await service.updateCompany(company.id, {
        'active_bank_account': newActive,
      });
      
      ref.invalidate(companyDetailsProvider(company.id));
      ref.invalidate(companiesProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.swap_horiz, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã chuyển sang tài khoản nhận tiền khác'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error switching bank account', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBankAccountDialog(BuildContext context, WidgetRef ref, Company company, int accountNumber) {
    final isAccount2 = accountNumber == 2;
    final bankNameController = TextEditingController(
      text: isAccount2 ? (company.bankName2 ?? '') : (company.bankName ?? ''),
    );
    final accountNumberController = TextEditingController(
      text: isAccount2 ? (company.bankAccountNumber2 ?? '') : (company.bankAccountNumber ?? ''),
    );
    final accountNameController = TextEditingController(
      text: isAccount2 ? (company.bankAccountName2 ?? '') : (company.bankAccountName ?? ''),
    );
    final bankBinController = TextEditingController(
      text: isAccount2 ? (company.bankBin2 ?? '') : (company.bankBin ?? ''),
    );
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_balance, color: Colors.blue.shade700),
              ),
              const SizedBox(width: 12),
              Text('Tài khoản $accountNumber'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình tài khoản $accountNumber để tạo QR chuyển khoản',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                
                // Bank dropdown
                DropdownButtonFormField<Map<String, String>>(
                  decoration: const InputDecoration(
                    labelText: 'Ngân hàng *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  value: _banks.cast<Map<String, String>?>().firstWhere(
                    (b) => b?['bin'] == bankBinController.text,
                    orElse: () => null,
                  ),
                  items: _banks.map((bank) => DropdownMenuItem(
                    value: bank,
                    child: Text(bank['name']!),
                  )).toList(),
                  onChanged: (bank) {
                    if (bank != null) {
                      bankNameController.text = bank['name']!;
                      bankBinController.text = bank['bin']!;
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Account number
                TextField(
                  controller: accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: 'VD: 0123456789',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Account holder name
                TextField(
                  controller: accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên chủ tài khoản *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    hintText: 'VD: NGUYEN VAN A',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                
                const SizedBox(height: 20),
                
                // Preview QR (if configured)
                if (bankBinController.text.isNotEmpty && accountNumberController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('Xem trước QR:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Image.network(
                          'https://img.vietqr.io/image/${bankBinController.text}-${accountNumberController.text}-compact.png?amount=100000&addInfo=Test',
                          width: 150,
                          height: 150,
                          errorBuilder: (_, __, ___) => const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${bankNameController.text} - ${accountNumberController.text}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (bankBinController.text.isEmpty || 
                    accountNumberController.text.isEmpty || 
                    accountNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                  );
                  return;
                }
                
                final bankName = bankNameController.text;
                final accNumber = accountNumberController.text;
                final accName = accountNameController.text;
                final bankBin = bankBinController.text;
                
                Navigator.pop(context);
                
                await _saveBankAccount(
                  context, ref, company,
                  bankName, accNumber, accName, bankBin,
                  accountNumber,
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveBankAccount(
    BuildContext context,
    WidgetRef ref,
    Company company,
    String bankName,
    String accountNumber,
    String accountName,
    String bankBin,
    int bankSlot,
  ) async {
    AppLogger.api('_saveBankAccount called for slot $bankSlot');
    AppLogger.api('Company ID: ${company.id}');
    AppLogger.api('Bank: $bankName, Account: $accountNumber, Name: $accountName, BIN: $bankBin');
    
    try {
      final service = CompanyService();
      final Map<String, dynamic> updateData;
      
      if (bankSlot == 2) {
        updateData = {
          'bank_name_2': bankName,
          'bank_account_number_2': accountNumber,
          'bank_account_name_2': accountName,
          'bank_bin_2': bankBin,
        };
      } else {
        updateData = {
          'bank_name': bankName,
          'bank_account_number': accountNumber,
          'bank_account_name': accountName,
          'bank_bin': bankBin,
        };
      }
      
      await service.updateCompany(company.id, updateData);
      
      // Refresh company data
      ref.invalidate(companyDetailsProvider(company.id));
      ref.invalidate(companiesProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Đã lưu tài khoản ngân hàng'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error saving bank account', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    AppLogger.api('Starting delete for company: ${company.id}');
    
    try {
      final service = CompanyService();
      AppLogger.api('Calling service.deleteCompany()...');
      await service.deleteCompany(company.id);
      AppLogger.api('Delete company successful!');

      // Invalidate companies cache
      ref.invalidate(companiesProvider);
      
      if (context.mounted) {
        AppLogger.nav('Navigating back after company delete');
        Navigator.of(context).pop(); // Return to companies list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa công ty'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error deleting company', e);
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
