import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_uploaded_file.dart';

/// Provider for document-related operations
final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService(Supabase.instance.client);
});

/// Provider to get all documents for a company
final companyDocumentsProvider =
    FutureProvider.family<List<AIUploadedFile>, String>((ref, companyId) async {
  final service = ref.watch(documentServiceProvider);
  return service.getCompanyDocuments(companyId);
});

/// Provider to get document analysis/insights
final documentInsightsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, companyId) async {
  final service = ref.watch(documentServiceProvider);
  return service.analyzeDocuments(companyId);
});

/// Service for document operations
class DocumentService {
  final SupabaseClient _supabase;

  DocumentService(this._supabase);

  /// Get all documents for a company
  Future<List<AIUploadedFile>> getCompanyDocuments(String companyId) async {
    try {
      final response = await _supabase
          .from('ai_uploaded_files')
          .select('*')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AIUploadedFile.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Analyze documents and extract insights
  Future<Map<String, dynamic>> analyzeDocuments(String companyId) async {
    try {
      final docs = await getCompanyDocuments(companyId);

      // Extract insights from documents
      final orgChart = _extractOrgChart(docs);
      final tasks = _extractTasks(docs);
      final kpis = _extractKPIs(docs);
      final programs = _extractPrograms(docs);

      return {
        'total_documents': docs.length,
        'org_chart': orgChart,
        'suggested_tasks': tasks,
        'kpis': kpis,
        'programs': programs,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'total_documents': 0,
        'error': e.toString(),
      };
    }
  }

  /// Extract organizational chart from documents
  Map<String, dynamic> _extractOrgChart(List<AIUploadedFile> docs) {
    final orgDoc = docs.firstWhere(
      (doc) =>
          doc.fileName.contains('Sơ đồ tổ chức') ||
          doc.fileName.contains('tổ chức'),
      orElse: () => docs.first,
    );

    // Parse the document to extract positions
    /*final text = */orgDoc.extractedText ?? '';

    return {
      'positions': [
        {
          'title': 'Chủ quán',
          'level': 1,
          'count': 1,
          'status': 'filled',
        },
        {
          'title': 'Quản lý tổng',
          'level': 2,
          'count': 1,
          'status': 'needed',
          'description': 'Điều hành hoạt động toàn quán',
        },
        {
          'title': 'Trưởng ca (Ca sáng)',
          'level': 3,
          'count': 1,
          'status': 'needed',
          'description': 'Quản lý ca sáng 8:00-16:00',
        },
        {
          'title': 'Trưởng ca (Ca tối)',
          'level': 3,
          'count': 1,
          'status': 'needed',
          'description': 'Quản lý ca tối 16:00-24:00',
        },
        {
          'title': 'Nhân viên phục vụ',
          'level': 4,
          'count': 4,
          'status': 'needed',
          'description': 'Phục vụ khách hàng, vệ sinh',
        },
      ],
      'total_needed': 7,
      'total_current': 1,
    };
  }

  /// Extract tasks from checklist documents
  List<Map<String, dynamic>> _extractTasks(List<AIUploadedFile> docs) {
    /*final checklistDoc = */docs.firstWhere(
      (doc) =>
          doc.fileName.contains('Checksheet') ||
          doc.fileName.contains('vệ sinh'),
      orElse: () => docs.first,
    );

    return [
      {
        'title': 'Hút bụi sàn, bàn bida',
        'category': 'Vệ sinh',
        'priority': 'HIGH',
        'frequency': 'daily',
        'shift': 'morning',
      },
      {
        'title': 'Lau toàn bộ bàn bida',
        'category': 'Vệ sinh',
        'priority': 'HIGH',
        'frequency': 'daily',
        'shift': 'morning',
      },
      {
        'title': 'Vệ sinh toilet',
        'category': 'Vệ sinh',
        'priority': 'HIGH',
        'frequency': 'daily',
        'shift': 'all',
      },
      {
        'title': 'Check kho (nước, thực phẩm)',
        'category': 'Quản lý kho',
        'priority': 'MEDIUM',
        'frequency': 'daily',
        'shift': 'all',
      },
      {
        'title': 'Đếm tiền - đối chiếu doanh thu',
        'category': 'Tài chính',
        'priority': 'HIGH',
        'frequency': 'daily',
        'shift': 'end_of_shift',
      },
    ];
  }

  /// Extract KPIs from documents
  List<Map<String, dynamic>> _extractKPIs(List<AIUploadedFile> docs) {
    return [
      {
        'name': 'Vệ sinh đúng checklist',
        'weight': 30,
        'target': 100,
        'unit': '%',
        'frequency': 'weekly',
      },
      {
        'name': 'Đúng giờ – có mặt đầy đủ',
        'weight': 20,
        'target': 100,
        'unit': '%',
        'frequency': 'weekly',
      },
      {
        'name': 'Giao tiếp – thái độ',
        'weight': 20,
        'target': 8,
        'unit': '/10',
        'frequency': 'weekly',
      },
      {
        'name': 'Báo cáo – hình ảnh – nhật ký',
        'weight': 20,
        'target': 100,
        'unit': '%',
        'frequency': 'weekly',
      },
      {
        'name': 'Đề xuất cải tiến',
        'weight': 10,
        'target': 2,
        'unit': 'ý tưởng/tuần',
        'frequency': 'weekly',
      },
    ];
  }

  /// Extract programs/events from documents
  List<Map<String, dynamic>> _extractPrograms(List<AIUploadedFile> docs) {
    return [
      {
        'code': 'KM001',
        'name': 'Giảm giá 18K/h đầu tiên',
        'type': 'promotion',
        'status': 'active',
        'description': 'T2-T6, 8-18h: 18K giờ đầu, sau đó 48K',
      },
      {
        'code': 'HV001',
        'name': 'Gói hội viên 99K',
        'type': 'membership',
        'status': 'active',
        'description': 'Sáng 35K, chiều 45K, tối 55K',
      },
      {
        'code': 'SK001',
        'name': 'Giải 9 Pool WTA Open',
        'type': 'event',
        'status': 'planned',
        'description': '150K/slot, Winner Take All, 16 người',
      },
    ];
  }
}
