import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_assistant.dart';
import '../models/ai_message.dart';
import '../models/ai_recommendation.dart';
import '../models/ai_uploaded_file.dart';
import '../models/ai_usage_analytics.dart';
import '../services/ai_service.dart';
import '../services/file_upload_service.dart';

// ==================== SERVICE PROVIDERS ====================

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// AI Service provider
final aiServiceProvider = Provider<AIService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AIService(supabase);
});

/// File Upload Service provider
final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return FileUploadService(supabase);
});

// ==================== AI ASSISTANT PROVIDERS ====================

/// Get or create AI assistant for a company
final aiAssistantProvider =
    FutureProvider.family<AIAssistant, String>((ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getOrCreateAssistant(companyId);
});

/// Update AI assistant
class AIAssistantNotifier extends AsyncNotifier<AIAssistant?> {
  @override
  FutureOr<AIAssistant?> build() {
    return null;
  }

  Future<void> updateAssistant(
      String assistantId, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      return aiService.updateAssistant(assistantId, updates);
    });
  }

  Future<void> deleteAssistant(String assistantId) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      await aiService.deleteAssistant(assistantId);
    });
  }
}

final aiAssistantNotifierProvider =
    AsyncNotifierProvider<AIAssistantNotifier, AIAssistant?>(
  () => AIAssistantNotifier(),
);

// ==================== MESSAGE PROVIDERS ====================

/// Stream messages for an assistant
final aiMessagesStreamProvider =
    StreamProvider.family<List<AIMessage>, String>((ref, assistantId) {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.streamMessages(assistantId);
});

/// Get messages (one-time)
final aiMessagesProvider =
    FutureProvider.family<List<AIMessage>, String>((ref, assistantId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getMessages(assistantId);
});

/// Send message notifier
class SendMessageNotifier extends AsyncNotifier<AIMessage?> {
  @override
  FutureOr<AIMessage?> build() {
    return null;
  }

  Future<void> sendMessage({
    required String assistantId,
    required String companyId,
    required String content,
    List<Map<String, String>>? attachments,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      return aiService.sendMessage(
        assistantId: assistantId,
        companyId: companyId,
        content: content,
        attachments: attachments,
      );
    });
  }

  Future<void> clearMessages(String assistantId) async {
    state = const AsyncValue.loading();
    await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      await aiService.clearMessages(assistantId);
    });
    state = const AsyncValue.data(null);
  }
}

final sendMessageNotifierProvider =
    AsyncNotifierProvider<SendMessageNotifier, AIMessage?>(
  () => SendMessageNotifier(),
);

// ==================== FILE UPLOAD PROVIDERS ====================

/// Get uploaded files for an assistant
final uploadedFilesProvider =
    FutureProvider.family<List<AIUploadedFile>, String>(
        (ref, assistantId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getUploadedFiles(assistantId);
});

/// File upload notifier
class FileUploadNotifier extends AsyncNotifier<List<AIUploadedFile>> {
  @override
  FutureOr<List<AIUploadedFile>> build() {
    return [];
  }

  /// Upload a single file
  /// 
  /// [userId] - Required: ID của user từ authProvider (không dùng auth.currentUser)
  Future<void> uploadFile({
    required String assistantId,
    required String companyId,
    required String userId,
    required dynamic file, // File from file_picker
    required String fileName,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      await fileUploadService.uploadFile(
        assistantId: assistantId,
        companyId: companyId,
        userId: userId,
        file: file,
        fileName: fileName,
        tags: tags,
        metadata: metadata,
      );

      // Refresh uploaded files list
      final aiService = ref.read(aiServiceProvider);
      return aiService.getUploadedFiles(assistantId);
    });
  }

  /// Upload multiple files
  /// 
  /// [userId] - Required: ID của user từ authProvider (không dùng auth.currentUser)
  Future<void> uploadMultipleFiles({
    required String assistantId,
    required String companyId,
    required String userId,
    required List<dynamic> files,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      // Cast files to File type
      final fileList = files.cast<dynamic>();
      await fileUploadService.uploadMultipleFiles(
        assistantId: assistantId,
        companyId: companyId,
        userId: userId,
        files: fileList.cast(),
        tags: tags,
        metadata: metadata,
      );

      // Refresh uploaded files list
      final aiService = ref.read(aiServiceProvider);
      return aiService.getUploadedFiles(assistantId);
    });
  }

  Future<void> deleteFile(String fileId, String assistantId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      await aiService.deleteUploadedFile(fileId);

      // Refresh uploaded files list
      return aiService.getUploadedFiles(assistantId);
    });
  }

  Future<void> processFile(String fileId, String assistantId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      await fileUploadService.processFile(fileId);

      // Refresh uploaded files list
      final aiService = ref.read(aiServiceProvider);
      return aiService.getUploadedFiles(assistantId);
    });
  }
}

final fileUploadNotifierProvider =
    AsyncNotifierProvider<FileUploadNotifier, List<AIUploadedFile>>(
  () => FileUploadNotifier(),
);

// ==================== RECOMMENDATION PROVIDERS ====================

/// Get recommendations for a company
final recommendationsProvider =
    FutureProvider.family<List<AIRecommendation>, String>(
        (ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getRecommendations(companyId);
});

/// Get recommendations by status
final recommendationsByStatusProvider = FutureProvider.family<
    List<AIRecommendation>, ({String companyId, String status})>(
  (ref, params) async {
    final aiService = ref.watch(aiServiceProvider);
    return aiService.getRecommendations(params.companyId,
        status: params.status);
  },
);

/// Get recommendations by category
final recommendationsByCategoryProvider = FutureProvider.family<
    List<AIRecommendation>, ({String companyId, String category})>(
  (ref, params) async {
    final aiService = ref.watch(aiServiceProvider);
    return aiService.getRecommendations(params.companyId,
        category: params.category);
  },
);

/// Recommendation notifier
class RecommendationNotifier extends AsyncNotifier<List<AIRecommendation>> {
  @override
  FutureOr<List<AIRecommendation>> build() {
    return [];
  }

  Future<void> updateRecommendationStatus(
    String recommendationId,
    String status,
    String companyId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      await aiService.updateRecommendationStatus(recommendationId, status);

      // Refresh recommendations list
      return aiService.getRecommendations(companyId);
    });
  }

  Future<void> deleteRecommendation(
      String recommendationId, String companyId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final aiService = ref.read(aiServiceProvider);
      await aiService.deleteRecommendation(recommendationId);

      // Refresh recommendations list
      return aiService.getRecommendations(companyId);
    });
  }
}

final recommendationNotifierProvider =
    AsyncNotifierProvider<RecommendationNotifier, List<AIRecommendation>>(
  () => RecommendationNotifier(),
);

// ==================== ANALYTICS PROVIDERS ====================

/// Get total AI cost for a company
final aiTotalCostProvider =
    FutureProvider.family<double, String>((ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getTotalCost(companyId);
});

/// Get usage analytics for a company
final usageAnalyticsProvider =
    FutureProvider.family<List<AIUsageAnalytics>, String>(
        (ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getUsageAnalytics(companyId);
});

/// Get current month usage
final currentMonthUsageProvider =
    FutureProvider.family<AIUsageAnalytics?, String>((ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getCurrentMonthUsage(companyId);
});

/// Get usage statistics
final usageStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final aiService = ref.watch(aiServiceProvider);
  return aiService.getUsageStats(companyId);
});
