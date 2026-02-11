import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

// ============================================================================
// INVOICES PAGE - Modern UI with Odori PDF Template
// ============================================================================
class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  DateTimeRange? _invoiceDateFilter;
  final _invoiceSearchController = TextEditingController();
  Set<String> _selectedOrderIds = {};
  bool _isSelectMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      var queryBuilder = supabase
          .from('sales_orders')
          .select('''
            *,
            customers(name, phone, address),
            sales_order_items(id, product_name, quantity, unit, unit_price, line_total)
          ''')
          .eq('company_id', companyId)
          .neq('status', 'cancelled');

      if (_invoiceDateFilter != null) {
        queryBuilder = queryBuilder
            .gte('created_at', _invoiceDateFilter!.start.toIso8601String())
            .lt('created_at', _invoiceDateFilter!.end.add(const Duration(days: 1)).toIso8601String());
      }

      final data = await queryBuilder
          .order('created_at', ascending: false)
          .limit(200);

      setState(() {
        _orders = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load orders for invoices', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredOrders {
    var result = _orders;
    final query = _invoiceSearchController.text.toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((o) {
        final customer = o['customers'] as Map<String, dynamic>?;
        final name = (customer?['name'] ?? '').toLowerCase();
        final phone = (customer?['phone'] ?? '').toLowerCase();
        final code = (o['order_number'] ?? '').toLowerCase();
        return name.contains(query) || phone.contains(query) || code.contains(query);
      }).toList();
    }

    return result;
  }

  // Orders that are delivered but not printed yet
  List<Map<String, dynamic>> get _pendingInvoices {
    return _filteredOrders.where((o) {
      final deliveryStatus = o['delivery_status']?.toString();
      final invoicePrinted = o['invoice_printed'] == true;
      return deliveryStatus != 'delivered' && !invoicePrinted;
    }).toList();
  }

  // Orders delivered but not printed
  List<Map<String, dynamic>> get _deliveredNotPrinted {
    return _filteredOrders.where((o) {
      final deliveryStatus = o['delivery_status']?.toString();
      final invoicePrinted = o['invoice_printed'] == true;
      return deliveryStatus == 'delivered' && !invoicePrinted;
    }).toList();
  }

  // Orders with printed invoices
  List<Map<String, dynamic>> get _printedInvoices {
    return _filteredOrders.where((o) => o['invoice_printed'] == true).toList();
  }

  Future<void> _printInvoice(Map<String, dynamic> order) async {
    try {
      // Generate PDF
      final pdfBytes = await _generateInvoicePdf(order);

      // Print
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);

      // Mark as printed
      final supabase = Supabase.instance.client;
      await supabase
          .from('sales_orders')
          .update({'invoice_printed': true, 'invoice_printed_at': DateTime.now().toIso8601String()})
          .eq('id', order['id']);

      // Reload
      _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã in hóa đơn thành công'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to print invoice', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi in hóa đơn: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _reprintInvoice(Map<String, dynamic> order) async {
    try {
      final pdfBytes = await _generateInvoicePdf(order);
      await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
    } catch (e) {
      AppLogger.error('Failed to reprint invoice', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi in hóa đơn: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    }
  }

  Future<void> _printSelectedInvoices() async {
    if (_selectedOrderIds.isEmpty) return;

    final selectedOrders = _orders.where((o) => _selectedOrderIds.contains(o['id'])).toList();

    for (final order in selectedOrders) {
      await _printInvoice(order);
    }

    setState(() {
      _selectedOrderIds.clear();
      _isSelectMode = false;
    });
  }

  Future<Uint8List> _generateInvoicePdf(Map<String, dynamic> order) async {
    final pdf = pw.Document();
    final customer = order['customers'] as Map<String, dynamic>?;
    final items = (order['sales_order_items'] as List?) ?? [];
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    final orderDate = DateTime.tryParse(order['created_at'] ?? '');

    // Get company info from auth
    final authState = ref.read(authProvider);
    final companyName = authState.user?.companyName ?? 'CÔNG TY TNHH SẢN XUẤT THƯƠNG MẠI ODORI';

    // Calculate totals
    double subtotal = 0;
    for (final item in items) {
      final qty = (item['quantity'] ?? 0).toDouble();
      final price = (item['unit_price'] ?? 0).toDouble();
      subtotal += qty * price;
    }
    final discountAmount = (order['discount_amount'] ?? 0).toDouble();
    final taxAmount = (order['tax_amount'] ?? 0).toDouble();
    final shippingAmount = (order['shipping_fee'] ?? 0).toDouble();
    // Use the authoritative total from DB (already includes discount, tax, shipping)
    final total = (order['total'] ?? (subtotal - discountAmount + taxAmount + shippingAmount)).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(companyName,
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Địa chỉ: ${order['delivery_address'] ?? customer?['address'] ?? ''}',
                            style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Điện thoại: 028.1234.5678 | MST: 0123456789',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text('HÓA ĐƠN BÁN HÀNG',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Invoice info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Số HĐ: ${order['order_number'] ?? order['id'].toString().substring(0, 8).toUpperCase()}',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Ngày: ${orderDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(orderDate) : 'N/A'}',
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.SizedBox(height: 16),

              // Customer info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('THÔNG TIN KHÁCH HÀNG',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 6),
                    pw.Text('Tên: ${customer?['name'] ?? 'N/A'}',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Địa chỉ: ${order['delivery_address'] ?? customer?['address'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Điện thoại: ${customer?['phone'] ?? 'N/A'}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('STT', isHeader: true),
                      _buildTableCell('Sản phẩm', isHeader: true),
                      _buildTableCell('ĐVT', isHeader: true),
                      _buildTableCell('SL', isHeader: true),
                      _buildTableCell('Đơn giá', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Thành tiền', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Data rows
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final qty = (item['quantity'] ?? 0).toDouble();
                    final price = (item['unit_price'] ?? 0).toDouble();
                    final lineTotal = (item['line_total'] ?? qty * price).toDouble();

                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(item['product_name'] ?? 'N/A'),
                        _buildTableCell(item['unit'] ?? 'N/A'),
                        _buildTableCell(qty.toStringAsFixed(0)),
                        _buildTableCell(currencyFormat.format(price), align: pw.TextAlign.right),
                        _buildTableCell(currencyFormat.format(lineTotal), align: pw.TextAlign.right),
                      ],
                    );
                  }).toList(),
                ],
              ),

              pw.SizedBox(height: 16),

              // Totals
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Tạm tính: ', style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(width: 40),
                        pw.Text('${currencyFormat.format(subtotal)} đ',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    if (discountAmount > 0)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Giảm giá: ', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: 40),
                          pw.Text('-${currencyFormat.format(discountAmount)} đ',
                              style: const pw.TextStyle(fontSize: 10, color: PdfColors.red)),
                        ],
                      ),
                    if (taxAmount > 0)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Thuế: ', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: 40),
                          pw.Text('+${currencyFormat.format(taxAmount)} đ',
                              style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    if (shippingAmount > 0)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('Phí vận chuyển: ', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(width: 40),
                          pw.Text('+${currencyFormat.format(shippingAmount)} đ',
                              style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('TỔNG CỘNG: ',
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(width: 40),
                        pw.Text('${currencyFormat.format(total)} đ',
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Payment status
              if (order['payment_status'] == 'paid')
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    border: pw.Border.all(color: PdfColors.green),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('ĐÃ THANH TOÁN',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                )
              else
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    border: pw.Border.all(color: PdfColors.orange),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text('CHƯA THANH TOÁN',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Người mua hàng', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 30),
                      pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Người bán hàng', style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 30),
                      pw.Text('(Ký, ghi rõ họ tên)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text('Cảm ơn quý khách đã mua hàng!',
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Xuất hóa đơn',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_isSelectMode && _selectedOrderIds.isNotEmpty)
                        TextButton.icon(
                          onPressed: _printSelectedInvoices,
                          icon: const Icon(Icons.print),
                          label: Text('In ${_selectedOrderIds.length} HĐ'),
                        ),
                      IconButton(
                        icon: Icon(_isSelectMode ? Icons.close : Icons.checklist),
                        onPressed: () {
                          setState(() {
                            _isSelectMode = !_isSelectMode;
                            if (!_isSelectMode) _selectedOrderIds.clear();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadOrders();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _invoiceSearchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm mã đơn, khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _invoiceSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _invoiceSearchController.clear();
                                  setState(() {});
                                })
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Date filter
                  GestureDetector(
                    onTap: () async {
                      final picked = await showQuickDateRangePicker(context, current: _invoiceDateFilter);
                      if (picked != null) {
                        if (picked.start.year == 1970) {
                          setState(() => _invoiceDateFilter = null);
                        } else {
                          setState(() => _invoiceDateFilter = picked);
                        }
                        _loadOrders();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _invoiceDateFilter != null ? Colors.purple.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: _invoiceDateFilter != null ? Border.all(color: Colors.purple.shade300) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month,
                              color: _invoiceDateFilter != null ? Colors.purple.shade700 : Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _invoiceDateFilter != null
                                  ? getDateRangeLabel(_invoiceDateFilter!)
                                  : 'Chọn khoảng thời gian',
                              style: TextStyle(
                                  color: _invoiceDateFilter != null ? Colors.purple.shade700 : Colors.grey.shade700),
                            ),
                          ),
                          if (_invoiceDateFilter != null)
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.purple.shade700),
                              onPressed: () {
                                setState(() => _invoiceDateFilter = null);
                                _loadOrders();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      indicator: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: 'Chờ giao (${_pendingInvoices.length})'),
                        Tab(text: 'Đã giao (${_deliveredNotPrinted.length})'),
                        Tab(text: 'Đã in (${_printedInvoices.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOrdersList(_pendingInvoices, currencyFormat, canPrint: false),
                        _buildOrdersList(_deliveredNotPrinted, currencyFormat, canPrint: true),
                        _buildOrdersList(_printedInvoices, currencyFormat, canPrint: false, isPrinted: true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders, NumberFormat currencyFormat,
      {bool canPrint = false, bool isPrinted = false}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text('Không có đơn hàng nào',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final customer = order['customers'] as Map<String, dynamic>?;
          final total = (order['total'] ?? 0).toDouble();
          final orderDate = DateTime.tryParse(order['created_at'] ?? '');
          final isSelected = _selectedOrderIds.contains(order['id']);

          return GestureDetector(
            onTap: _isSelectMode && canPrint
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedOrderIds.remove(order['id']);
                      } else {
                        _selectedOrderIds.add(order['id']);
                      }
                    });
                  }
                : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.purple.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: Colors.purple.shade300, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_isSelectMode && canPrint) ...[
                    Checkbox(
                      value: isSelected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedOrderIds.add(order['id']);
                          } else {
                            _selectedOrderIds.remove(order['id']);
                          }
                        });
                      },
                      activeColor: Colors.purple.shade600,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPrinted ? Colors.green.shade50 : Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPrinted ? Icons.check_circle : Icons.receipt,
                      color: isPrinted ? Colors.green.shade600 : Colors.purple.shade600,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer?['name'] ?? 'Khách hàng',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '${order['order_number'] ?? order['id'].toString().substring(0, 8).toUpperCase()} • ${orderDate != null ? DateFormat('dd/MM HH:mm').format(orderDate) : 'N/A'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(currencyFormat.format(total),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      if (canPrint && !_isSelectMode)
                        GestureDetector(
                          onTap: () => _printInvoice(order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.print, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('In', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      if (isPrinted)
                        GestureDetector(
                          onTap: () => _reprintInvoice(order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh, size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 4),
                                Text('In lại', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
