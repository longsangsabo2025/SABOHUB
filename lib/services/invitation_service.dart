import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';

// Provider for InvitationService
final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService(ref: ref);
});

/// Invitation Service
/// Xử lý việc tạo và quản lý lời mời nhân viên
class InvitationService {
  final _supabase = Supabase.instance.client;
  final Ref? _ref;
  final _uuid = const Uuid();

  InvitationService({Ref? ref}) : _ref = ref;

  /// Tạo link mời nhân viên
  Future<Map<String, dynamic>> createInvitation({
    required String position,
    required UserRole role,
    required int maxUses,
    required String message,
  }) async {
    try {
      // Verify CEO is logged in
      User? currentUser;
      String? companyId;

      if (_ref != null) {
        final user = _ref.read(currentUserProvider);
        currentUser = user;
        companyId = currentUser?.companyId;
      }

      if (companyId == null || companyId.isEmpty) {
        throw Exception('Không tìm thấy công ty. Vui lòng đăng nhập lại.');
      }

      if (currentUser == null || currentUser.role != UserRole.ceo) {
        throw Exception('Chỉ CEO mới có thể tạo lời mời');
      }

      // Generate unique invitation code
      final invitationCode = _generateInvitationCode();
      final invitationId = _uuid.v4();

      // Create invitation record
      await _supabase.from('employee_invitations').insert({
        'id': invitationId,
        'company_id': companyId,
        'invitation_code': invitationCode,
        'position': position,
        'role': role.toUpperString(),
        'max_uses': maxUses,
        'current_uses': 0,
        'message': message,
        'created_by': currentUser.id,
        'expires_at':
            DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_active': true,
      });

      // Generate invitation URL
      final baseUrl = 'https://sabohub.com'; // Replace with your domain
      final invitationUrl = '$baseUrl/join/$invitationCode';

      return {
        'success': true,
        'invitationId': invitationId,
        'invitationCode': invitationCode,
        'invitationUrl': invitationUrl,
        'expiresAt': DateTime.now().add(const Duration(days: 7)),
      };
    } catch (e) {
      throw Exception('Lỗi tạo lời mời: $e');
    }
  }

  /// Lấy thông tin từ invitation code
  Future<Map<String, dynamic>?> getInvitationByCode(
      String invitationCode) async {
    try {
      final response = await _supabase
          .from('employee_invitations')
          .select('''
            *,
            companies!inner(name, id)
          ''')
          .eq('invitation_code', invitationCode)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      // Check if expired
      final expiresAt = DateTime.parse(response['expires_at']);
      if (expiresAt.isBefore(DateTime.now())) {
        return null;
      }

      // Check if max uses reached
      if (response['current_uses'] >= response['max_uses']) {
        return null;
      }

      return response;
    } catch (e) {
      throw Exception('Lỗi kiểm tra lời mời: $e');
    }
  }

  /// Sử dụng invitation để đăng ký
  Future<Map<String, dynamic>> useInvitation({
    required String invitationCode,
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Get invitation info
      final invitation = await getInvitationByCode(invitationCode);
      if (invitation == null) {
        throw Exception('Link mời không hợp lệ hoặc đã hết hạn');
      }

      // Check if email already exists in employees table
      final existingUser = await _supabase
          .from('employees')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Email này đã được sử dụng');
      }

      // Create Supabase auth user
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'company_id': invitation['company_id'],
          'role': invitation['role'],
        },
      );

      if (authResponse.user == null) {
        throw Exception('Không thể tạo tài khoản xác thực');
      }

      final userId = authResponse.user!.id;

      // Insert employee data
      await _supabase.from('employees').insert({
        'auth_user_id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': invitation['role'],
        'company_id': invitation['company_id'],
        'position': invitation['position'],
        'is_active': true,
        'invited_by': invitation['created_by'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update invitation usage count
      await _supabase.from('employee_invitations').update({
        'current_uses': invitation['current_uses'] + 1,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invitation['id']);

      return {
        'success': true,
        'userId': userId,
        'companyName': invitation['companies']['name'],
        'position': invitation['position'],
        'role': invitation['role'],
      };
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  /// Lấy danh sách lời mời của công ty
  Future<List<Map<String, dynamic>>> getCompanyInvitations(
      String companyId) async {
    try {
      final response = await _supabase
          .from('employee_invitations')
          .select('''
            *,
            users!created_by(name, email)
          ''')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Lỗi lấy danh sách lời mời: $e');
    }
  }

  /// Vô hiệu hóa lời mời
  Future<void> deactivateInvitation(String invitationId) async {
    try {
      await _supabase.from('employee_invitations').update({
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationId);
    } catch (e) {
      throw Exception('Lỗi vô hiệu hóa lời mời: $e');
    }
  }

  /// Generate unique invitation code
  String _generateInvitationCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';

    for (int i = 0; i < 8; i++) {
      code += chars[(random + i) % chars.length];
    }

    return code;
  }

  /// Validate invitation code format
  bool isValidInvitationCode(String code) {
    return RegExp(r'^[A-Z0-9]{8}$').hasMatch(code);
  }

  /// Generate shareable message
  String generateShareMessage({
    required String invitationUrl,
    required String companyName,
    required String position,
    String? customMessage,
  }) {
    final message =
        customMessage ?? 'Chào mừng bạn gia nhập đội ngũ của chúng tôi!';

    return '''
🎉 $message

📍 Công ty: $companyName
👔 Vị trí: $position

🔗 Đăng ký tại: $invitationUrl

Link có hiệu lực trong 7 ngày. Hãy đăng ký sớm để bảo đảm vị trí của bạn!

#SaboHub #TuyenDung
''';
  }
}

/// Extension để thêm tiện ích cho UserRole
extension UserRoleInvitation on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.shiftLeader:
        return 'Trưởng ca';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.ceo:
        return 'CEO';
      case UserRole.driver:
        return 'Tài xế';
      case UserRole.warehouse:
        return 'Nhân viên kho';
      case UserRole.shareholder:
        return 'Cổ đông';
      case UserRole.finance:
        return 'Kế toán';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superAdmin:
        return 'Quản lý toàn bộ hệ thống SABOHUB';
      case UserRole.manager:
        return 'Quản lý nhân viên và hoạt động cửa hàng';
      case UserRole.shiftLeader:
        return 'Điều phối và giám sát ca làm việc';
      case UserRole.staff:
        return 'Thực hiện các nhiệm vụ hàng ngày';
      case UserRole.ceo:
        return 'Quản lý toàn bộ hệ thống';
      case UserRole.driver:
        return 'Giao hàng và vận chuyển';
      case UserRole.warehouse:
        return 'Quản lý kho hàng và xuất nhập';
      case UserRole.shareholder:
        return 'Xem thông tin tài chính và cổ đông';
      case UserRole.finance:
        return 'Quản lý tài chính và kế toán';
    }
  }
}
