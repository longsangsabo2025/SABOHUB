import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';

class PDFReportPage extends ConsumerStatefulWidget {
  const PDFReportPage({super.key});

  @override
  ConsumerState<PDFReportPage> createState() => _PDFReportPageState();
}

class _PDFReportPageState extends ConsumerState<PDFReportPage> {
  String _reportType = 'task_summary';
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Xuất báo cáo PDF'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn loại báo cáo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            _buildReportOption(
              'task_summary',
              'Tổng hợp nhiệm vụ',
              'Thống kê task theo status, category, priority',
              Icons.assignment,
              Colors.blue,
            ),
            _buildReportOption(
              'employee_performance',
              'Hiệu suất nhân viên',
              'Bảng xếp hạng, điểm task, chấm công',
              Icons.people,
              Colors.green,
            ),
            _buildReportOption(
              'revenue_report',
              'Báo cáo doanh thu',
              'Doanh thu theo ngày, tổng hợp tháng',
              Icons.attach_money,
              Colors.orange,
            ),
            _buildReportOption(
              'media_report',
              'Báo cáo Media',
              'Thống kê kênh, followers, views',
              Icons.campaign,
              Colors.purple,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                    _isGenerating ? 'Đang tạo...' : 'Tạo & Xem PDF'),
                onPressed: _isGenerating ? null : _generateReport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
      String value, String title, String subtitle, IconData icon, Color color) {
    final isSelected = _reportType == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _reportType,
        onChanged: (v) => setState(() => _reportType = v ?? 'task_summary'),
        title: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        activeColor: color,
      ),
    );
  }

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = pw.Document();
      final supabase = Supabase.instance.client;
      final user = ref.read(authProvider).user;
      final companyId = user?.companyId;
      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      switch (_reportType) {
        case 'task_summary':
          await _buildTaskSummaryPDF(pdf, supabase, companyId, dateStr);
          break;
        case 'employee_performance':
          await _buildEmployeePDF(pdf, supabase, companyId, dateStr);
          break;
        case 'revenue_report':
          await _buildRevenuePDF(pdf, supabase, companyId, dateStr);
          break;
        case 'media_report':
          await _buildMediaPDF(pdf, supabase, companyId, dateStr);
          break;
      }

      if (mounted) {
        await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdf.save());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _buildTaskSummaryPDF(pw.Document pdf,
      SupabaseClient supabase, String? companyId, String dateStr) async {
    var query = supabase.from('tasks').select('status, priority, category, progress');
    if (companyId != null) query = query.eq('company_id', companyId);
    final tasks = List<Map<String, dynamic>>.from(await query);

    final byStatus = <String, int>{};
    final byCategory = <String, int>{};
    final byPriority = <String, int>{};
    for (final t in tasks) {
      final status = t['status'] as String? ?? 'pending';
      final cat = t['category'] as String? ?? 'general';
      final pri = t['priority'] as String? ?? 'medium';
      byStatus[status] = (byStatus[status] ?? 0) + 1;
      byCategory[cat] = (byCategory[cat] ?? 0) + 1;
      byPriority[pri] = (byPriority[pri] ?? 0) + 1;
    }

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'SABO - Bao cao nhiem vu'),
          pw.Text('Ngay: $dateStr'),
          pw.SizedBox(height: 20),
          pw.Text('Tong so: ${tasks.length} nhiem vu',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Theo trang thai:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...byStatus.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}')),
          pw.SizedBox(height: 12),
          pw.Text('Theo mang:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...byCategory.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}')),
          pw.SizedBox(height: 12),
          pw.Text('Theo uu tien:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...byPriority.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}')),
        ],
      ),
    ));
  }

  Future<void> _buildEmployeePDF(pw.Document pdf,
      SupabaseClient supabase, String? companyId, String dateStr) async {
    if (companyId == null) return;
    final employees = List<Map<String, dynamic>>.from(
      await supabase
          .from('employees')
          .select('full_name, role, department')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('full_name'),
    );

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'SABO - Danh sach nhan vien'),
          pw.Text('Ngay: $dateStr'),
          pw.SizedBox(height: 20),
          pw.Text('Tong: ${employees.length} nhan vien'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['STT', 'Ho ten', 'Chuc vu', 'Phong ban'],
            data: employees.asMap().entries.map((e) => [
              '${e.key + 1}',
              e.value['full_name'] ?? '',
              e.value['role'] ?? '',
              e.value['department'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    ));
  }

  Future<void> _buildRevenuePDF(pw.Document pdf,
      SupabaseClient supabase, String? companyId, String dateStr) async {
    final startDate =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String().split('T').first;
    var query = supabase
        .from('daily_revenue')
        .select('*')
        .gte('date', startDate)
        .order('date', ascending: false);
    if (companyId != null) query = query.eq('company_id', companyId);
    final data = List<Map<String, dynamic>>.from(await query);

    final total = data.fold<double>(
        0, (s, d) => s + ((d['total_revenue'] as num?)?.toDouble() ?? 0));

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'SABO - Bao cao doanh thu 30 ngay'),
          pw.Text('Ngay: $dateStr'),
          pw.SizedBox(height: 20),
          pw.Text('Tong doanh thu: ${NumberFormat('#,###', 'vi_VN').format(total)} VND',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          if (data.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Ngay', 'Doanh thu', 'Don hang', 'Khach hang'],
              data: data.take(30).map((d) => [
                d['date'] ?? '',
                NumberFormat('#,###', 'vi_VN').format(
                    (d['total_revenue'] as num?)?.toDouble() ?? 0),
                '${d['total_orders'] ?? 0}',
                '${d['total_customers'] ?? 0}',
              ]).toList(),
            ),
        ],
      ),
    ));
  }

  Future<void> _buildMediaPDF(pw.Document pdf,
      SupabaseClient supabase, String? companyId, String dateStr) async {
    var query = supabase.from('media_channels').select('*');
    if (companyId != null) query = query.eq('company_id', companyId);
    final channels = List<Map<String, dynamic>>.from(await query);

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(level: 0, text: 'SABO Media - Bao cao kenh'),
          pw.Text('Ngay: $dateStr'),
          pw.SizedBox(height: 20),
          pw.Text('Tong: ${channels.length} kenh'),
          pw.SizedBox(height: 12),
          if (channels.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: ['Kenh', 'Nen tang', 'Followers', 'Views', 'Videos', 'Trang thai'],
              data: channels.map((c) => [
                c['name'] ?? '',
                c['platform'] ?? '',
                '${c['followers_count'] ?? 0}',
                '${c['views_count'] ?? 0}',
                '${c['videos_count'] ?? 0}',
                c['status'] ?? '',
              ]).toList(),
            ),
        ],
      ),
    ));
  }
}
