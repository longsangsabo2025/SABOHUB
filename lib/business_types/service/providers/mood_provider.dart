import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mood_service.dart';
import '../../../providers/auth_provider.dart';

final moodServiceProvider = Provider<MoodService>((ref) => MoodService());

final weeklyMoodSummaryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final companyId = user.companyId ?? '';
  if (companyId.isEmpty) return [];
  final service = ref.read(moodServiceProvider);
  return service.getWeeklyMoodSummary(companyId);
});
