import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../providers/auth_provider.dart';
import '../../business_types/service/providers/shareholder_provider.dart';
import '../../business_types/service/models/shareholder.dart';

/// Shareholder Dashboard Layout
/// Cổ đông có thể xem thông tin cổ phần của mình
class ShareholderDashboard extends ConsumerStatefulWidget {
  ShareholderDashboard({super.key});

  @override
  ConsumerState<ShareholderDashboard> createState() => _ShareholderDashboardState();
}

class _ShareholderDashboardState extends ConsumerState<ShareholderDashboard> {
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final companyId = currentUser?.companyId;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.pie_chart, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('Cổ Đông Dashboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Colors.purple.shade700,
        elevation: 1,
        actions: [
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.purple.shade100,
                  child: Text(
                    (currentUser?.name ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currentUser?.name ?? 'Cổ đông',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Logout button
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: companyId == null
          ? const Center(child: Text('Không tìm thấy thông tin công ty'))
          : _buildBody(companyId, currentUser?.id ?? '', currentUser?.name ?? ''),
    );
  }

  Widget _buildBody(String companyId, String userId, String userName) {
    final historyAsync = ref.watch(shareholdersHistoryProvider(companyId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Lỗi: $e', style: const TextStyle(color: Colors.red)),
      ),
      data: (history) {
        if (history.isEmpty) {
          return const Center(
            child: Text('Chưa có dữ liệu cổ phần'),
          );
        }

        // Find user's shareholder data
        final availableYears = history.keys.toList()..sort((a, b) => b.compareTo(a));
        final shareholders = history[_selectedYear] ?? [];
        
        // Find current user's shareholder data by employee_id (primary) or name (fallback)
        final userShareholderData = shareholders.where(
          (sh) => sh.employeeId == userId || // Primary: match by employee_id
                  (sh.employeeId == null && ( // Fallback: match by name if no employee_id linked
                    sh.shareholderName.toUpperCase().contains(userName.toUpperCase()) ||
                    userName.toUpperCase().contains(sh.shareholderName.toUpperCase())
                  )),
        ).firstOrNull;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(userName, userShareholderData),
              const SizedBox(height: 20),

              // Year Selector
              _buildYearSelector(availableYears),
              const SizedBox(height: 20),

              // User's Share Info (if found)
              if (userShareholderData != null) ...[
                _buildMyShareCard(userShareholderData, shareholders),
                const SizedBox(height: 20),
              ],

              // Pie Chart Overview
              _buildPieChartCard(shareholders),
              const SizedBox(height: 20),

              // All Shareholders Table
              _buildShareholdersTable(shareholders),
              const SizedBox(height: 20),

              // Formula Explanation
              _buildFormulaCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(String userName, Shareholder? myData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade600, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.surface, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $userName!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  myData != null
                      ? 'Tỷ lệ sở hữu của bạn: ${myData.ownershipPercentage.toStringAsFixed(2)}%'
                      : 'Chào mừng đến với Cổ Đông Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (myData != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${myData.ownershipPercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearSelector(List<int> years) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.purple.shade600, size: 20),
          const SizedBox(width: 12),
          const Text('Chọn năm:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: years.map((year) {
                  final isSelected = year == _selectedYear;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedYear = year),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.purple.shade600 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Theme.of(context).colorScheme.surface : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyShareCard(Shareholder myData, List<Shareholder> allShareholders) {
    final netValue = myData.cashInvested - myData.depreciation;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade50,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Thông tin cổ phần của bạn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  'Vốn góp',
                  _formatCurrency(myData.cashInvested),
                  Icons.attach_money,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  'Khấu hao (30%)',
                  '- ${_formatCurrency(myData.depreciation)}',
                  Icons.trending_down,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  'Vốn ròng',
                  _formatCurrency(netValue),
                  Icons.account_balance,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  'Tỷ lệ sở hữu',
                  '${myData.ownershipPercentage.toStringAsFixed(2)}%',
                  Icons.pie_chart,
                  Colors.purple,
                ),
              ),
            ],
          ),
          if (myData.notes != null && myData.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      myData.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(List<Shareholder> shareholders) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.purple.shade700, size: 24),
              const SizedBox(width: 8),
              Text(
                'Cơ cấu cổ phần năm $_selectedYear',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Pie Chart
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    shareholders: shareholders,
                    colors: colors,
                    year: _selectedYear,
                    surfaceColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: shareholders.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final sh = entry.value;
                    final color = colors[idx % colors.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              sh.shareholderName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${sh.ownershipPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareholdersTable(List<Shareholder> shareholders) {
    final totalInvested = shareholders.fold<double>(0, (sum, sh) => sum + sh.cashInvested);
    final totalDepreciation = shareholders.fold<double>(0, (sum, sh) => sum + sh.depreciation);
    final totalNet = totalInvested - totalDepreciation;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: Colors.indigo.shade700, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Bảng chi tiết cổ phần',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(1.2),
              },
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade200),
              ),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.indigo.shade50),
                  children: [
                    _tableCell('Cổ đông', isHeader: true),
                    _tableCell('Vốn góp', isHeader: true),
                    _tableCell('KH 30%', isHeader: true),
                    _tableCell('Vốn ròng', isHeader: true),
                    _tableCell('Tỷ lệ', isHeader: true),
                  ],
                ),
                // Data rows
                ...shareholders.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final sh = entry.value;
                  final netValue = sh.cashInvested - sh.depreciation;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: idx % 2 == 0 ? Theme.of(context).colorScheme.surface : Colors.grey.shade50,
                    ),
                    children: [
                      _tableCell(sh.shareholderName),
                      _tableCell(_formatCurrencyShort(sh.cashInvested)),
                      _tableCell(_formatCurrencyShort(sh.depreciation)),
                      _tableCell(_formatCurrencyShort(netValue)),
                      _tableCell('${sh.ownershipPercentage.toStringAsFixed(2)}%'),
                    ],
                  );
                }),
                // Total row
                TableRow(
                  decoration: BoxDecoration(color: Colors.yellow.shade100),
                  children: [
                    _tableCell('TỔNG', isHeader: true),
                    _tableCell(_formatCurrencyShort(totalInvested), bold: true),
                    _tableCell(_formatCurrencyShort(totalDepreciation), bold: true),
                    _tableCell(_formatCurrencyShort(totalNet), bold: true),
                    _tableCell('100%', bold: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, {bool isHeader = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader || bold ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.indigo.shade900 : Colors.grey.shade800,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildFormulaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Công thức tính tỷ lệ sở hữu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _formulaItem('1. Khấu hao hàng năm = 30% × Vốn góp'),
          _formulaItem('2. Vốn ròng = Vốn góp − Khấu hao'),
          _formulaItem('3. Tỷ lệ sở hữu = (Vốn ròng / Tổng vốn ròng) × 100%'),
          const Divider(height: 20),
          Text(
            '📌 Khấu hao 30%/năm được áp dụng để tính giá trị hiện tại của vốn góp dựa trên giá trị sử dụng thực tế.',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.chevron_right, size: 16, color: Colors.blue.shade400),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return '${NumberFormat.currency(locale: 'vi', symbol: '', decimalDigits: 0).format(value)}đ';
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} tỷ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} tr';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} K';
    }
    return value.toStringAsFixed(0);
  }
}

/// Pie Chart Painter for Shareholder Dashboard
class _PieChartPainter extends CustomPainter {
  final List<Shareholder> shareholders;
  final List<Color> colors;
  final int year;
  final Color surfaceColor;

  _PieChartPainter({
    required this.shareholders,
    required this.colors,
    required this.year,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    double startAngle = -math.pi / 2; // Start from top

    for (int i = 0; i < shareholders.length; i++) {
      final sh = shareholders[i];
      final sweepAngle = (sh.ownershipPercentage / 100) * 2 * math.pi;
      final color = colors[i % colors.length];

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // White border between slices
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = surfaceColor
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Center hole (donut)
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = surfaceColor;
    canvas.drawCircle(center, radius * 0.45, centerPaint);

    // Year text in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: year.toString(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
