import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/ceo_ai_insights_service.dart';

/// ============================================================================
/// CEO AI INSIGHTS PROVIDER — Riverpod state for AI briefing
/// Auto-refreshes, provides loading states, caching
/// ============================================================================

final _aiService = CEOAIInsightsService();

/// Main briefing provider — CEO's AI Chief of Staff
final ceoBriefingProvider =
    FutureProvider.autoDispose<CEOBriefing>((ref) async {
  final user = ref.read(currentUserProvider);
  final companyId = user?.companyId;
  if (companyId == null) return CEOBriefing.empty();

  return _aiService.generateBriefing(companyId);
});
