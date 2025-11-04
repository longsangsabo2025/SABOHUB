import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_uploaded_file.dart';

/// Service for analyzing documents and extracting insights
class DocumentAnalysisService {
  final SupabaseClient _supabase;

  DocumentAnalysisService(this._supabase);

  /// Summarize document content
  Future<Map<String, dynamic>> summarizeDocument(String fileId) async {
    try {
      // Call Edge Function to summarize document
      final response = await _supabase.functions.invoke(
        'summarize-document',
        body: {'file_id': fileId},
      );

      if (response.data == null) {
        throw Exception('No response from summarize function');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to summarize document: $e');
    }
  }

  /// Extract key information from document
  Future<Map<String, dynamic>> extractKeyInfo(
    String fileId,
    List<String> fields,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'extract-info',
        body: {
          'file_id': fileId,
          'fields': fields,
        },
      );

      if (response.data == null) {
        throw Exception('No response from extract-info function');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to extract information: $e');
    }
  }

  /// Ask questions about a document
  Future<String> askDocument(
    String fileId,
    String question,
    List<Map<String, String>>? conversationHistory,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'ask-document',
        body: {
          'file_id': fileId,
          'question': question,
          'conversation_history': conversationHistory ?? [],
        },
      );

      if (response.data == null) {
        throw Exception('No response from ask-document function');
      }

      return response.data['answer'] as String;
    } catch (e) {
      throw Exception('Failed to ask document: $e');
    }
  }

  /// Extract text from PDF
  Future<String> extractPdfText(String fileId) async {
    try {
      final response = await _supabase.functions.invoke(
        'extract-pdf-text',
        body: {'file_id': fileId},
      );

      if (response.data == null) {
        throw Exception('No response from extract-pdf-text function');
      }

      return response.data['text'] as String;
    } catch (e) {
      throw Exception('Failed to extract PDF text: $e');
    }
  }

  /// Analyze menu items from images or documents
  Future<List<Map<String, dynamic>>> analyzeMenu(String fileId) async {
    try {
      final response = await _supabase.functions.invoke(
        'analyze-menu',
        body: {'file_id': fileId},
      );

      if (response.data == null) {
        throw Exception('No response from analyze-menu function');
      }

      return (response.data['items'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to analyze menu: $e');
    }
  }

  /// Compare documents
  Future<Map<String, dynamic>> compareDocuments(
    List<String> fileIds,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        'compare-documents',
        body: {'file_ids': fileIds},
      );

      if (response.data == null) {
        throw Exception('No response from compare-documents function');
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to compare documents: $e');
    }
  }

  /// Get document insights
  Future<List<Map<String, dynamic>>> getDocumentInsights(
    String fileId,
  ) async {
    try {
      // Get file details
      final fileResponse = await _supabase
          .from('ai_uploaded_files')
          .select()
          .eq('id', fileId)
          .single();

      final file = AIUploadedFile.fromJson(fileResponse);

      if (!file.hasAnalysis) {
        throw Exception('File has not been analyzed yet');
      }

      // Extract insights from analysis
      final analysis = file.analysisResults!;
      final insights = <Map<String, dynamic>>[];

      // Extract key insights based on file type
      if (file.isImage) {
        insights.addAll(_extractImageInsights(analysis));
      } else if (file.isPdf || file.isDocument) {
        insights.addAll(_extractDocumentInsights(analysis));
      }

      return insights;
    } catch (e) {
      throw Exception('Failed to get document insights: $e');
    }
  }

  List<Map<String, dynamic>> _extractImageInsights(
    Map<String, dynamic> analysis,
  ) {
    final insights = <Map<String, dynamic>>[];

    // Cleanliness insight
    if (analysis['cleanliness'] != null) {
      insights.add({
        'type': 'cleanliness',
        'title': 'Vệ sinh',
        'description': analysis['cleanliness'],
        'icon': 'cleaning_services',
      });
    }

    // Lighting insight
    if (analysis['lighting'] != null) {
      insights.add({
        'type': 'lighting',
        'title': 'Ánh sáng',
        'description': analysis['lighting'],
        'icon': 'lightbulb',
      });
    }

    // Layout insight
    if (analysis['layout'] != null) {
      insights.add({
        'type': 'layout',
        'title': 'Bố cục',
        'description': analysis['layout'],
        'icon': 'dashboard',
      });
    }

    // Improvement suggestions
    if (analysis['improvements'] != null) {
      insights.add({
        'type': 'improvements',
        'title': 'Đề xuất cải thiện',
        'description': analysis['improvements'],
        'icon': 'tips_and_updates',
      });
    }

    return insights;
  }

  List<Map<String, dynamic>> _extractDocumentInsights(
    Map<String, dynamic> analysis,
  ) {
    final insights = <Map<String, dynamic>>[];

    // Summary
    if (analysis['summary'] != null) {
      insights.add({
        'type': 'summary',
        'title': 'Tóm tắt',
        'description': analysis['summary'],
        'icon': 'summarize',
      });
    }

    // Key points
    if (analysis['key_points'] != null) {
      insights.add({
        'type': 'key_points',
        'title': 'Điểm chính',
        'description': (analysis['key_points'] as List).join('\n'),
        'icon': 'list',
      });
    }

    // Recommendations
    if (analysis['recommendations'] != null) {
      insights.add({
        'type': 'recommendations',
        'title': 'Khuyến nghị',
        'description': analysis['recommendations'],
        'icon': 'recommend',
      });
    }

    return insights;
  }
}
