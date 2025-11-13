import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_assistant.dart';
import '../models/ai_message.dart';
import '../models/ai_recommendation.dart';
import '../models/ai_uploaded_file.dart';
import '../models/ai_usage_analytics.dart';

/// Service for managing AI Assistant operations
class AIService {
  final SupabaseClient _supabase;

  AIService(this._supabase);

  // ==================== AI ASSISTANT OPERATIONS ====================

  /// Get or create AI assistant for a company
  Future<AIAssistant> getOrCreateAssistant(String companyId) async {
    try {
      // First try to get existing assistant
      final existingResponse = await _supabase
          .from('ai_assistants')
          .select()
          .eq('company_id', companyId)
          .maybeSingle();

      if (existingResponse != null) {
        return AIAssistant.fromJson(existingResponse);
      }

      // Try creating with RLS bypassed for demo mode
      try {
        final createResponse = await _supabase
            .from('ai_assistants')
            .insert({
              'company_id': companyId,
              'name': 'AI Trợ lý',
              'model': 'gpt-4-turbo-preview',
              'settings': {},
              'is_active': true,
            })
            .select()
            .single();

        return AIAssistant.fromJson(createResponse);
      } catch (rlsError) {
        // Simple demo fallback - create minimal assistant object with valid UUID
        try {
          final now = DateTime.now();
          final uuid = const Uuid();
          final demoAssistant = AIAssistant(
            id: uuid.v4(), // Generate valid UUID
            companyId: companyId,
            name: 'AI Trợ lý Demo',
            model: 'gpt-4-turbo-preview',
            settings: <String, dynamic>{},
            isActive: true,
            createdAt: now,
            updatedAt: now,
          );

          return demoAssistant;
        } catch (demoError) {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Failed to get/create AI assistant: $e');
    }
  }

  /// Get AI assistant by ID
  Future<AIAssistant?> getAssistant(String assistantId) async {
    try {
      final response = await _supabase
          .from('ai_assistants')
          .select()
          .eq('id', assistantId)
          .maybeSingle();

      if (response == null) return null;
      return AIAssistant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get assistant: $e');
    }
  }

  /// Update AI assistant
  Future<AIAssistant> updateAssistant(
      String assistantId, Map<String, dynamic> updates) async {
    try {
      final response = await _supabase
          .from('ai_assistants')
          .update(updates)
          .eq('id', assistantId)
          .select()
          .single();

      return AIAssistant.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update assistant: $e');
    }
  }

  /// Delete AI assistant
  Future<void> deleteAssistant(String assistantId) async {
    try {
      await _supabase.from('ai_assistants').delete().eq('id', assistantId);
    } catch (e) {
      throw Exception('Failed to delete assistant: $e');
    }
  }

  // ==================== MESSAGE OPERATIONS ====================

  /// Get messages for an assistant
  Stream<List<AIMessage>> streamMessages(String assistantId) {
    return _supabase
        .from('ai_messages')
        .stream(primaryKey: ['id'])
        .eq('assistant_id', assistantId)
        .order('created_at', ascending: true)
        .map((data) => data.map((json) => AIMessage.fromJson(json)).toList());
  }

  /// Get messages (one-time fetch)
  Future<List<AIMessage>> getMessages(String assistantId,
      {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('ai_messages')
          .select()
          .eq('assistant_id', assistantId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List)
          .map((json) => AIMessage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Send a message and get AI response
  Future<AIMessage> sendMessage({
    required String assistantId,
    required String companyId,
    required String content,
    List<Map<String, String>>? attachments,
  }) async {
    try {
      // Create user message
      await _createMessage(
        assistantId: assistantId,
        companyId: companyId,
        role: 'user',
        content: content,
        attachments: attachments,
      );

      // Call Edge Function to get AI response
      final response = await _supabase.functions.invoke(
        'ai-chat',
        body: {
          'assistant_id': assistantId,
          'company_id': companyId,
          'message': content,
          'attachments': attachments,
        },
      );

      if (response.status != 200) {
        throw Exception('AI response failed: ${response.data}');
      }

      final aiResponse = response.data as Map<String, dynamic>;

      // Create AI message with response
      final aiMessage = await _createMessage(
        assistantId: assistantId,
        companyId: companyId,
        role: 'assistant',
        content: aiResponse['content'] as String,
        promptTokens: aiResponse['prompt_tokens'] as int?,
        completionTokens: aiResponse['completion_tokens'] as int?,
        totalTokens: aiResponse['total_tokens'] as int?,
        estimatedCost: (aiResponse['estimated_cost'] as num?)?.toDouble(),
        analysis: aiResponse['analysis'] as Map<String, dynamic>?,
      );

      return aiMessage;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Create a message record
  Future<AIMessage> _createMessage({
    required String assistantId,
    required String companyId,
    required String role,
    required String content,
    List<Map<String, String>>? attachments,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    double? estimatedCost,
    Map<String, dynamic>? analysis,
  }) async {
    try {
      final response = await _supabase
          .from('ai_messages')
          .insert({
            'assistant_id': assistantId,
            'company_id': companyId,
            'role': role,
            'content': content,
            'attachments': attachments ?? [],
            'prompt_tokens': promptTokens,
            'completion_tokens': completionTokens,
            'total_tokens': totalTokens,
            'estimated_cost': estimatedCost,
            'analysis': analysis,
          })
          .select()
          .single();

      return AIMessage.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('ai_messages').delete().eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Clear all messages for an assistant
  Future<void> clearMessages(String assistantId) async {
    try {
      await _supabase
          .from('ai_messages')
          .delete()
          .eq('assistant_id', assistantId);
    } catch (e) {
      throw Exception('Failed to clear messages: $e');
    }
  }

  // ==================== FILE OPERATIONS ====================

  /// Get uploaded files for an assistant
  Future<List<AIUploadedFile>> getUploadedFiles(String assistantId) async {
    try {
      final response = await _supabase
          .from('ai_uploaded_files')
          .select()
          .eq('assistant_id', assistantId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AIUploadedFile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get uploaded files: $e');
    }
  }

  /// Get uploaded file by ID
  Future<AIUploadedFile?> getUploadedFile(String fileId) async {
    try {
      final response = await _supabase
          .from('ai_uploaded_files')
          .select()
          .eq('id', fileId)
          .maybeSingle();

      if (response == null) return null;
      return AIUploadedFile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get uploaded file: $e');
    }
  }

  /// Update uploaded file
  Future<AIUploadedFile> updateUploadedFile(
    String fileId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabase
          .from('ai_uploaded_files')
          .update(updates)
          .eq('id', fileId)
          .select()
          .single();

      return AIUploadedFile.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update uploaded file: $e');
    }
  }

  /// Delete uploaded file
  Future<void> deleteUploadedFile(String fileId) async {
    try {
      // Get file info first to delete from storage
      final file = await getUploadedFile(fileId);
      if (file != null && file.fileUrl.isNotEmpty) {
        // Extract storage path from URL
        // URL format: https://xxx.supabase.co/storage/v1/object/public/ai-files/path
        final uri = Uri.parse(file.fileUrl);
        final pathSegments = uri.pathSegments;
        final bucketIndex = pathSegments.indexOf('ai-files');
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
          await _supabase.storage.from('ai-files').remove([storagePath]);
        }
      }

      // Delete from database
      await _supabase.from('ai_uploaded_files').delete().eq('id', fileId);
    } catch (e) {
      throw Exception('Failed to delete uploaded file: $e');
    }
  }

  // ==================== RECOMMENDATION OPERATIONS ====================

  /// Get recommendations for a company
  Future<List<AIRecommendation>> getRecommendations(
    String companyId, {
    String? status,
    String? category,
  }) async {
    try {
      var query = _supabase
          .from('ai_recommendations')
          .select()
          .eq('company_id', companyId);

      if (status != null) {
        query = query.eq('status', status);
      }
      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => AIRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  /// Get recommendation by ID
  Future<AIRecommendation?> getRecommendation(String recommendationId) async {
    try {
      final response = await _supabase
          .from('ai_recommendations')
          .select()
          .eq('id', recommendationId)
          .maybeSingle();

      if (response == null) return null;
      return AIRecommendation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get recommendation: $e');
    }
  }

  /// Update recommendation status
  Future<AIRecommendation> updateRecommendationStatus(
    String recommendationId,
    String status,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('ai_recommendations')
          .update({
            'status': status,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recommendationId)
          .select()
          .single();

      return AIRecommendation.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update recommendation status: $e');
    }
  }

  /// Delete recommendation
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      await _supabase
          .from('ai_recommendations')
          .delete()
          .eq('id', recommendationId);
    } catch (e) {
      throw Exception('Failed to delete recommendation: $e');
    }
  }

  // ==================== ANALYTICS OPERATIONS ====================

  /// Get total AI cost for a company
  Future<double> getTotalCost(String companyId) async {
    try {
      final response = await _supabase
          .rpc('get_ai_total_cost', params: {'p_company_id': companyId});

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('Failed to get total cost: $e');
    }
  }

  /// Get usage analytics for a period
  Future<List<AIUsageAnalytics>> getUsageAnalytics(
    String companyId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('ai_usage_analytics')
          .select()
          .eq('company_id', companyId);

      if (startDate != null) {
        query = query.gte('period_start', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('period_end', endDate.toIso8601String());
      }

      final response = await query.order('period_start', ascending: false);

      return (response as List)
          .map((json) => AIUsageAnalytics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get usage analytics: $e');
    }
  }

  /// Get current month usage
  Future<AIUsageAnalytics?> getCurrentMonthUsage(String companyId) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final response = await _supabase
          .from('ai_usage_analytics')
          .select()
          .eq('company_id', companyId)
          .gte('period_start', startOfMonth.toIso8601String())
          .lte('period_end', endOfMonth.toIso8601String())
          .maybeSingle();

      if (response == null) return null;
      return AIUsageAnalytics.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get current month usage: $e');
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStats(String companyId) async {
    try {
      final response = await _supabase
          .rpc('get_ai_usage_stats', params: {'p_company_id': companyId});

      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get usage stats: $e');
    }
  }
}
