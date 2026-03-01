import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Generates PDF daily/weekly/monthly reports for CEO
class CeoReportGenerator {
  static final CeoReportGenerator _instance = CeoReportGenerator._internal();
  factory CeoReportGenerator() => _instance;
  CeoReportGenerator._internal();

  final _supabase = Supabase.instance.client;
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  /// Generate and preview/download CEO daily report
  Future<void> generateAndPrint(String companyId, {DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final pdf = await _buildReport(companyId, reportDate);

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name:
          'SABOHUB_Report_${DateFormat('yyyyMMdd').format(reportDate)}.pdf',
    );
  }

  /// Generate raw PDF bytes (for sharing/saving)
  Future<List<int>> generateBytes(String companyId, {DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final pdf = await _buildReport(companyId, reportDate);
    return pdf.save();
  }

  Future<pw.Document> _buildReport(
      String companyId, DateTime reportDate) async {
    final dateStr = DateFormat('dd/MM/yyyy').format(reportDate);
    final todayStr = DateFormat('yyyy-MM-dd').format(reportDate);

    // Fetch all data in parallel
    final results = await Future.wait([
      _supabase
          .from('sales_orders')
          .select('total, status, customer_id')
          .eq('company_id', companyId)
          .gte('created_at', '${todayStr}T00:00:00')
          .lte('created_at', '${todayStr}T23:59:59'),
      _supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('is_active', true),
      _supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .gte('created_at', '${todayStr}T00:00:00'),
      _supabase
          .from('employees')
          .select('id, full_name')
          .eq('company_id', companyId)
          .eq('is_active', true),
      _supabase
          .from('attendance')
          .select('employee_id, is_late, check_in_time')
          .eq('company_id', companyId)
          .gte('check_in_time', '${todayStr}T00:00:00')
          .lte('check_in_time', '${todayStr}T23:59:59'),
      _supabase
          .from('products')
          .select('name, stock_quantity, min_stock_level, unit')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('stock_quantity', ascending: true)
          .limit(50),
      _supabase
          .from('deliveries')
          .select('status')
          .eq('company_id', companyId)
          .gte('created_at', '${todayStr}T00:00:00'),
    ]);

    final orders = results[0] as List;
    final allCustomers = results[1] as List;
    final newCustomers = results[2] as List;
    final employees = results[3] as List;
    final attendance = results[4] as List;
    final products = results[5] as List;
    final deliveries = results[6] as List;

    // Calculate metrics
    double totalRevenue = 0;
    int completedOrders = 0;
    int pendingOrders = 0;
    for (final o in orders) {
      totalRevenue += (o['total'] ?? 0).toDouble();
      final status = o['status'] as String? ?? '';
      if (status == 'completed' || status == 'delivered') completedOrders++;
      if (status == 'pending' || status == 'confirmed') pendingOrders++;
    }

    int lowStock = 0;
    final lowStockItems = <Map<String, dynamic>>[];
    for (final p in products) {
      final qty = (p['stock_quantity'] ?? 0) as num;
      final minLevel = (p['min_stock_level'] ?? 10) as num;
      if (qty <= minLevel) {
        lowStock++;
        if (lowStockItems.length < 10) lowStockItems.add(p);
      }
    }

    final checkedIn = attendance.length;
    final lateCount =
        attendance.where((a) => a['is_late'] == true).length;

    // Build PDF
    final pdf = pw.Document(
      title: 'SABOHUB Daily Report - $dateStr',
      author: 'SABOHUB System',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(dateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // KPI Summary
          _sectionTitle('TỔNG QUAN'),
          pw.SizedBox(height: 8),
          _kpiGrid([
            _kpiItem(
                'Doanh thu', _currencyFormat.format(totalRevenue)),
            _kpiItem('Đơn hàng', '${orders.length}'),
            _kpiItem('Hoàn thành', '$completedOrders'),
            _kpiItem('Chờ xử lý', '$pendingOrders'),
          ]),
          pw.SizedBox(height: 20),

          // Customers
          _sectionTitle('KHÁCH HÀNG'),
          pw.SizedBox(height: 8),
          _kpiGrid([
            _kpiItem('Tổng KH', '${allCustomers.length}'),
            _kpiItem('KH mới', '+${newCustomers.length}'),
          ]),
          pw.SizedBox(height: 20),

          // HR
          _sectionTitle('NHÂN SỰ'),
          pw.SizedBox(height: 8),
          _kpiGrid([
            _kpiItem('Tổng NV', '${employees.length}'),
            _kpiItem('Chấm công',
                '$checkedIn/${employees.length}'),
            _kpiItem('Đi trễ', '$lateCount'),
            _kpiItem('Tỷ lệ',
                '${employees.isNotEmpty ? (checkedIn * 100 ~/ employees.length) : 0}%'),
          ]),
          pw.SizedBox(height: 20),

          // Operations
          _sectionTitle('VẬN HÀNH'),
          pw.SizedBox(height: 8),
          _kpiGrid([
            _kpiItem('Giao hàng', '${deliveries.length} chuyến'),
            _kpiItem('Tồn kho thấp', '$lowStock SP'),
          ]),
          pw.SizedBox(height: 20),

          // Low stock table
          if (lowStockItems.isNotEmpty) ...[
            _sectionTitle('SẢN PHẨM TỒN KHO THẤP'),
            pw.SizedBox(height: 8),
            _buildLowStockTable(lowStockItems),
          ],
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader(String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.blue900),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SABOHUB',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                'CEO Daily Report',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            dateStr,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Page ${context.pageNumber}/${context.pagesCount} - Generated by SABOHUB',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _kpiGrid(List<pw.Widget> items) {
    return pw.Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items,
    );
  }

  pw.Widget _kpiItem(String label, String value) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildLowStockTable(List<Map<String, dynamic>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Sản phẩm', isHeader: true),
            _tableCell('Tồn kho', isHeader: true),
            _tableCell('Tối thiểu', isHeader: true),
            _tableCell('Đơn vị', isHeader: true),
          ],
        ),
        // Data rows
        ...items.map((p) => pw.TableRow(
              children: [
                _tableCell(p['name'] ?? ''),
                _tableCell('${p['stock_quantity'] ?? 0}'),
                _tableCell('${p['min_stock_level'] ?? 10}'),
                _tableCell(p['unit'] ?? ''),
              ],
            )),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }
}
