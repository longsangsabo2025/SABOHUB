import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/common/mood_checkin_dialog.dart';

class MoodService {
  final _client = Supabase.instance.client;

  /// Insert mood log. Table: mood_logs(id, employee_id, company_id, mood, logged_at, date)
  /// Uses upsert on (employee_id, date) to allow one mood per day
  Future<void> logMood({
    required String employeeId,
    required String companyId,
    required StaffMood mood,
  }) async {
    await _client.from('mood_logs').upsert({
      'employee_id': employeeId,
      'company_id': companyId,
      'mood': mood.name, // 'great', 'okay', 'tired'
      'logged_at': DateTime.now().toIso8601String(),
      'date': DateTime.now().toIso8601String().substring(0, 10), // 'YYYY-MM-DD'
    }, onConflict: 'employee_id,date');
  }

  /// Get mood logs for company for last 7 days (for manager insight)
  Future<List<Map<String, dynamic>>> getWeeklyMoodSummary(String companyId) async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final response = await _client
        .from('mood_logs')
        .select('mood, logged_at, date')
        .eq('company_id', companyId)
        .gte('date', since.toIso8601String().substring(0, 10))
        .order('logged_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
