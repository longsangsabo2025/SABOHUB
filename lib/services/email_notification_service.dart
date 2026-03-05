import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/supabase_service.dart';
import '../models/management_task.dart';
import '../utils/app_logger.dart';

/// Email Notification Service
/// Gửi email thông báo task cho nhân viên được assign
/// Sử dụng DB function send_email_resend() qua pg_net (đã hoạt động)
class EmailNotificationService {
  final _supabase = supabase.client;

  /// Gửi email nhắc nhở task (gọi RPC send_email_resend)
  /// Returns true nếu gửi thành công, throws Exception nếu lỗi
  Future<bool> sendTaskReminder({
    required ManagementTask task,
    String? customMessage,
  }) async {
    try {
      if (task.assignedTo == null) {
        throw Exception('Task chưa được assign cho ai');
      }

      AppLogger.api(
        '📧 [EmailNotificationService] Sending task reminder email for task: ${task.id}',
      );

      // Get assignee email from employees table
      final employee = await _supabase
          .from('employees')
          .select('email, full_name')
          .eq('id', task.assignedTo!)
          .single();

      final email = employee['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('Nhân viên chưa có email');
      }

      final employeeName = employee['full_name'] as String? ?? 'Bạn';

      // Generate email HTML content
      final subject = '🔔 Nhắc nhở: ${task.title}';
      final html = _generateReminderEmailHtml(task, employeeName, customMessage);

      // Call existing DB function send_email_resend(p_from, p_html, p_subject, p_to)
      await _supabase.rpc('send_email_resend', params: {
        'p_from': 'SABOHUB <noreply@sabocorp.com>',
        'p_to': email,
        'p_subject': subject,
        'p_html': html,
      });

      AppLogger.api(
        '✅ [EmailNotificationService] Email sent successfully to $email',
      );

      return true;
    } catch (e) {
      AppLogger.error(
        '❌ [EmailNotificationService] Failed to send email',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Generate HTML content for reminder email
  String _generateReminderEmailHtml(ManagementTask task, String employeeName, String? customMessage) {
    final priority = _priorityLabel(task.priority.value);
    final status = _statusLabel(task.status.value);
    final dueDate = task.dueDate != null 
        ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
        : 'Không có';
    final progress = task.progress;

    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;padding:0;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f3f4f6;">
  <table width="100%" cellpadding="0" cellspacing="0" style="max-width:600px;margin:0 auto;background:#fff;">
    <tr><td style="background:#8B5CF6;padding:24px;text-align:center;">
      <h1 style="color:#fff;margin:0;font-size:16px;font-weight:600;">🔔 NHẮC NHỞ NHIỆM VỤ</h1>
    </td></tr>
    <tr><td style="padding:24px;">
      <p style="margin:0 0 16px;color:#374151;">Xin chào <strong>$employeeName</strong>,</p>
      <h2 style="margin:0 0 16px;color:#111827;font-size:20px;">${task.title}</h2>
      ${task.description != null ? '<p style="margin:0 0 16px;color:#6b7280;">${task.description}</p>' : ''}
      ${customMessage != null ? '<div style="background:#faf5ff;border-left:4px solid #8B5CF6;padding:12px 16px;margin:0 0 16px;"><p style="margin:0;color:#6b21a8;font-style:italic;">"$customMessage"</p></div>' : ''}
      <table style="background:#f9fafb;border-radius:12px;width:100%;padding:16px;">
        <tr><td style="padding:8px 0;">
          <span style="color:#9ca3af;font-size:12px;">Trạng thái</span><br>
          <span style="color:#111827;font-weight:500;">$status</span>
        </td><td style="padding:8px 0;">
          <span style="color:#9ca3af;font-size:12px;">Độ ưu tiên</span><br>
          <span style="color:#111827;font-weight:500;">$priority</span>
        </td></tr>
        <tr><td style="padding:8px 0;">
          <span style="color:#9ca3af;font-size:12px;">Hạn chót</span><br>
          <span style="color:#111827;font-weight:500;">$dueDate</span>
        </td><td style="padding:8px 0;">
          <span style="color:#9ca3af;font-size:12px;">Tiến độ</span><br>
          <span style="color:#111827;font-weight:500;">$progress%</span>
        </td></tr>
      </table>
    </td></tr>
    <tr><td style="background:#f9fafb;padding:24px;text-align:center;border-top:1px solid #e5e7eb;">
      <p style="margin:0;color:#9ca3af;font-size:12px;">Email tự động từ SABOHUB</p>
    </td></tr>
  </table>
</body>
</html>
''';
  }

  String _priorityLabel(String value) {
    const labels = {
      'low': '🟢 Thấp',
      'medium': '🟡 Trung bình',
      'high': '🟠 Cao',
      'critical': '🔴 Khẩn cấp',
      'urgent': '🔴 Khẩn cấp',
    };
    return labels[value] ?? value;
  }

  String _statusLabel(String value) {
    const labels = {
      'pending': '⏳ Chờ xử lý',
      'in_progress': '🔄 Đang thực hiện',
      'completed': '✅ Hoàn thành',
      'cancelled': '❌ Đã hủy',
      'overdue': '⚠️ Quá hạn',
    };
    return labels[value] ?? value;
  }
}

/// Provider for EmailNotificationService
final emailNotificationServiceProvider = Provider<EmailNotificationService>(
  (ref) => EmailNotificationService(),
);
