import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../services/invitation_service.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// CEO tạo link mời nhân viên
class CreateInvitationPage extends ConsumerStatefulWidget {
  const CreateInvitationPage({super.key});

  @override
  ConsumerState<CreateInvitationPage> createState() =>
      _CreateInvitationPageState();
}

class _CreateInvitationPageState extends ConsumerState<CreateInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  final _positionController = TextEditingController();
  final _messageController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  int _maxUses = 1;
  bool _isLoading = false;
  String? _generatedLink;

  @override
  void initState() {
    super.initState();
    _messageController.text = 'Chào mừng bạn gia nhập đội ngũ của chúng tôi!';
  }

  @override
  void dispose() {
    _positionController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tạo link mời nhân viên',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildInvitationForm(),
              const SizedBox(height: 24),
              if (_generatedLink != null) ...[
                _buildGeneratedLink(),
                const SizedBox(height: 24),
              ],
              _buildCreateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade600,
            Colors.green.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.link,
              color: Theme.of(context).colorScheme.surface,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mời nhân viên gia nhập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tạo link để nhân viên tự đăng ký tài khoản',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.surface70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationForm() {
    return _buildSection(
      title: '📝 Thông tin lời mời',
      children: [
        // Position/Title field
        _buildTextField(
          controller: _positionController,
          label: 'Vị trí tuyển dụng',
          icon: Icons.work,
          hint: 'VD: Nhân viên bán hàng, Quản lý ca...',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập vị trí tuyển dụng';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Role selection
        _buildRoleSelector(),
        const SizedBox(height: 16),

        // Max uses
        _buildMaxUsesSelector(),
        const SizedBox(height: 16),

        // Welcome message
        _buildTextField(
          controller: _messageController,
          label: 'Lời chào (tùy chọn)',
          icon: Icons.message,
          maxLines: 3,
          hint: 'Tin nhắn chào mừng cho nhân viên mới...',
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chức danh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: UserRole.values
                .where((role) => role != UserRole.ceo)
                .map((role) {
              return _buildRoleOption(role);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role) {
    final roleInfo = _getRoleInfo(role);
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Radio<UserRole>(
              value: role,
              groupValue: _selectedRole,
              activeColor: Colors.blue.shade600,
              onChanged: (UserRole? value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(width: 12),
            Icon(
              roleInfo['icon'],
              color: roleInfo['color'],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleInfo['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    roleInfo['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  Widget _buildMaxUsesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số lượng có thể sử dụng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.grey),
              const SizedBox(width: 12),
              const Text('Link có thể được sử dụng:'),
              const Spacer(),
              DropdownButton<int>(
                value: _maxUses,
                underline: const SizedBox(),
                items: [1, 5, 10, 20, 50].map((uses) {
                  return DropdownMenuItem(
                    value: uses,
                    child: Text('$uses lần'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _maxUses = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedLink() {
    return _buildSection(
      title: '🔗 Link mời đã tạo',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Link đã được tạo thành công!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Link display
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _generatedLink!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyLink,
                      tooltip: 'Sao chép link',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Share buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareViaEmail,
                      icon: Icon(Icons.email, size: 18),
                      label: Text('Gửi Email'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareViaMessage,
                      icon: Icon(Icons.message, size: 18),
                      label: Text('Tin nhắn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCreateInvitation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.surface),
                ),
              )
            : const Text(
                'Tạo link mời',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return {
          'title': 'Super Admin',
          'description': 'Quản lý toàn bộ hệ thống SABOHUB',
          'icon': Icons.admin_panel_settings,
          'color': Colors.red,
        };
      case UserRole.manager:
        return {
          'title': 'Quản lý',
          'description': 'Quản lý nhân viên và hoạt động cửa hàng',
          'icon': Icons.supervisor_account,
          'color': Colors.orange,
        };
      case UserRole.shiftLeader:
        return {
          'title': 'Trưởng ca',
          'description': 'Điều phối và giám sát ca làm việc',
          'icon': Icons.people_outline,
          'color': Colors.green,
        };
      case UserRole.staff:
        return {
          'title': 'Nhân viên',
          'description': 'Thực hiện các nhiệm vụ hàng ngày',
          'icon': Icons.person,
          'color': Colors.blue,
        };
      case UserRole.ceo:
        return {
          'title': 'CEO',
          'description': 'Quản lý toàn bộ hệ thống',
          'icon': Icons.business_center,
          'color': Colors.purple,
        };
      case UserRole.driver:
        return {
          'title': 'Tài xế',
          'description': 'Giao hàng và vận chuyển',
          'icon': Icons.local_shipping,
          'color': Colors.teal,
        };
      case UserRole.warehouse:
        return {
          'title': 'Nhân viên kho',
          'description': 'Quản lý kho hàng và xuất nhập',
          'icon': Icons.warehouse,
          'color': Colors.brown,
        };
      case UserRole.finance:
        return {
          'title': 'Kế toán',
          'description': 'Quản lý tài chính và sổ sách',
          'icon': Icons.account_balance,
          'color': Colors.green.shade700,
        };
      case UserRole.shareholder:
        return {
          'title': 'Cổ đông',
          'description': 'Xem thông tin tài chính và cổ đông',
          'icon': Icons.trending_up,
          'color': Colors.cyan,
        };
    }
  }

  Future<void> _handleCreateInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invitationService = ref.read(invitationServiceProvider);

      final result = await invitationService.createInvitation(
        position: _positionController.text.trim(),
        role: _selectedRole,
        maxUses: _maxUses,
        message: _messageController.text.trim(),
      );

      setState(() {
        _generatedLink = result['invitationUrl'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã tạo link mời thành công!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Sao chép',
              textColor: Theme.of(context).colorScheme.surface,
              onPressed: _copyLink,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tạo link mời: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyLink() {
    if (_generatedLink != null) {
      Clipboard.setData(ClipboardData(text: _generatedLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📋 Đã sao chép link vào clipboard'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareViaEmail() {
    // Implement email sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📧 Tính năng gửi email đang phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareViaMessage() {
    // Implement message sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💬 Tính năng gửi tin nhắn đang phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
