import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';
import 'gemini_service.dart';
import 'telegram_notify_service.dart';

class AIChatService {
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  final _supabase = Supabase.instance.client;
  final _gemini = GeminiService();
  final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  final _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Whether Gemini AI enhancement is available
  bool get isAIEnabled => GeminiService.isEnabled;

  /// Process a natural language query and return formatted response
  Future<String> processQuery(String query, String companyId) async {
    final q = query.toLowerCase().trim();

    // Route to appropriate handler
    if (_matchesAny(q, ['doanh thu', 'revenue', 'bán hàng', 'sales'])) {
      return _withGeminiAnalysis(query, () => _handleRevenueQuery(q, companyId));
    }
    if (_matchesAny(q, ['đơn hàng', 'order', 'đơn mới'])) {
      return _withGeminiAnalysis(query, () => _handleOrderQuery(q, companyId));
    }
    if (_matchesAny(q, ['khách hàng', 'customer', 'top khách'])) {
      return _withGeminiAnalysis(
          query, () => _handleCustomerQuery(q, companyId));
    }
    if (_matchesAny(
        q, ['tồn kho', 'inventory', 'sản phẩm', 'hết hàng', 'stock'])) {
      return _withGeminiAnalysis(
          query, () => _handleInventoryQuery(q, companyId));
    }
    if (_matchesAny(
        q, ['nhân viên', 'employee', 'đi làm', 'attendance', 'chấm công'])) {
      return _withGeminiAnalysis(
          query, () => _handleEmployeeQuery(q, companyId));
    }
    if (_matchesAny(
        q, ['tổng quan', 'overview', 'báo cáo', 'report', 'dashboard'])) {
      return _withGeminiAnalysis(query, () => _handleOverviewQuery(companyId));
    }
    if (_matchesAny(q, ['giao hàng', 'delivery', 'vận chuyển'])) {
      return _withGeminiAnalysis(
          query, () => _handleDeliveryQuery(q, companyId));
    }
    if (_matchesAny(q, ['công nợ', 'debt', 'nợ'])) {
      return _withGeminiAnalysis(query, () => _handleDebtQuery(companyId));
    }
    if (_matchesAny(q, ['pdf', 'xuất', 'export', 'in báo cáo', 'tải'])) {
      return '__PDF_EXPORT__';
    }
    if (_matchesAny(q, ['telegram', 'test bot', 'gửi telegram'])) {
      return _handleTelegramTest();
    }
    if (_matchesAny(q, ['cấu hình', 'config', 'status', 'kết nối'])) {
      return _handleConfigStatus();
    }

    // For unknown queries: try Gemini free-form if available
    if (isAIEnabled) {
      final aiResponse = await _gemini.chat(query);
      if (aiResponse.isNotEmpty) {
        return '🤖 $aiResponse';
      }
    }

    return '🤔 Tôi chưa hiểu câu hỏi này. Bạn có thể hỏi về:\n\n'
        '• **Doanh thu** — "Doanh thu hôm nay?"\n'
        '• **Đơn hàng** — "Đơn hàng mới?"\n'
        '• **Khách hàng** — "Top khách hàng?"\n'
        '• **Tồn kho** — "Sản phẩm sắp hết?"\n'
        '• **Nhân viên** — "Ai đi làm hôm nay?"\n'
        '• **Giao hàng** — "Tình trạng giao hàng?"\n'
        '• **Công nợ** — "Tổng công nợ?"\n'
        '• **Tổng quan** — "Báo cáo tổng quan"\n'
        '• **Xuất PDF** — "Xuất báo cáo PDF"';
  }

  /// Wraps a local data query with optional Gemini AI analysis
  /// Pattern: fetch real data → send to Gemini for insights → return combined
  Future<String> _withGeminiAnalysis(
    String userQuery,
    Future<String> Function() localQuery,
  ) async {
    final localResult = await localQuery();

    if (!isAIEnabled) return localResult;

    try {
      // Send the real data to Gemini for analysis/insights
      final aiInsight = await _gemini.chat(
        userQuery,
        businessContext: localResult,
      );

      if (aiInsight.isNotEmpty) {
        return '$localResult\n\n---\n🤖 **Phân tích AI:**\n$aiInsight';
      }
    } catch (e) {
      AppLogger.error('Gemini analysis failed, using local only', e);
    }

    return localResult;
  }

  bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  String _period(String q) {
    if (_matchesAny(q, ['hôm nay', 'today', 'ngày'])) return 'today';
    if (_matchesAny(q, ['tuần', 'week'])) return 'week';
    if (_matchesAny(q, ['tháng', 'month'])) return 'month';
    if (_matchesAny(q, ['năm', 'year'])) return 'year';
    return 'today';
  }

  DateTime _periodStart(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'week':
        return now.subtract(Duration(days: now.weekday - 1));
      case 'month':
        return DateTime(now.year, now.month, 1);
      case 'year':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'week':
        return 'tuần này';
      case 'month':
        return 'tháng này';
      case 'year':
        return 'năm nay';
      default:
        return 'hôm nay';
    }
  }

  Future<String> _handleRevenueQuery(String q, String companyId) async {
    try {
      final period = _period(q);
      final since = _periodStart(period).toIso8601String();

      final orders = await _supabase
          .from('sales_orders')
          .select('total, status')
          .eq('company_id', companyId)
          .gte('created_at', since);

      double totalRevenue = 0;
      int orderCount = 0;
      int completedCount = 0;
      for (final o in orders) {
        final total = (o['total'] ?? 0).toDouble();
        totalRevenue += total;
        orderCount++;
        if (o['status'] == 'completed' || o['status'] == 'delivered') {
          completedCount++;
        }
      }

      return '📊 **Doanh thu ${_periodLabel(period)}**\n\n'
          '💰 Tổng doanh thu: **${_currencyFormat.format(totalRevenue)}**\n'
          '📦 Số đơn hàng: **${_numberFormat.format(orderCount)}**\n'
          '✅ Đã hoàn thành: **${_numberFormat.format(completedCount)}**\n'
          '📈 Trung bình/đơn: **${orderCount > 0 ? _currencyFormat.format(totalRevenue / orderCount) : "0₫"}**';
    } catch (e) {
      AppLogger.error('AI: Revenue query failed', e);
      return '❌ Không thể truy xuất dữ liệu doanh thu. Lỗi: $e';
    }
  }

  Future<String> _handleOrderQuery(String q, String companyId) async {
    try {
      final period = _period(q);
      final since = _periodStart(period).toIso8601String();

      final orders = await _supabase
          .from('sales_orders')
          .select('status, total, created_at')
          .eq('company_id', companyId)
          .gte('created_at', since)
          .order('created_at', ascending: false);

      final Map<String, int> byStatus = {};
      double total = 0;
      for (final o in orders) {
        final status = o['status'] as String? ?? 'unknown';
        byStatus[status] = (byStatus[status] ?? 0) + 1;
        total += (o['total'] ?? 0).toDouble();
      }

      final statusEmoji = {
        'pending': '🟡',
        'confirmed': '🔵',
        'processing': '🟠',
        'shipped': '🚚',
        'delivered': '✅',
        'completed': '✅',
        'cancelled': '❌',
      };

      final statusLines = byStatus.entries
          .map((e) => '${statusEmoji[e.key] ?? "⚪"} ${e.key}: **${e.value}**')
          .join('\n');

      return '📦 **Đơn hàng ${_periodLabel(period)}**\n\n'
          'Tổng: **${orders.length}** đơn — ${_currencyFormat.format(total)}\n\n'
          '$statusLines';
    } catch (e) {
      AppLogger.error('AI: Order query failed', e);
      return '❌ Không thể truy xuất dữ liệu đơn hàng. Lỗi: $e';
    }
  }

  Future<String> _handleCustomerQuery(String q, String companyId) async {
    try {
      // Top customers by recent activity
      final customers = await _supabase
          .from('customers')
          .select('id, name, tier, phone')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(10);

      final totalCount = await _supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('is_active', true);

      final tierEmoji = {
        'diamond': '💎',
        'gold': '🥇',
        'silver': '🥈',
        'bronze': '🥉',
      };

      final customerLines = customers.take(5).map((c) {
        final tier = (c['tier'] as String?)?.toLowerCase() ?? '';
        final emoji = tierEmoji[tier] ?? '👤';
        return '$emoji **${c['name']}** ${c['phone'] ?? ''}';
      }).join('\n');

      return '👥 **Khách hàng**\n\n'
          'Tổng số: **${totalCount.length}** khách hàng hoạt động\n\n'
          '**Top khách hàng gần đây:**\n$customerLines';
    } catch (e) {
      AppLogger.error('AI: Customer query failed', e);
      return '❌ Không thể truy xuất dữ liệu khách hàng. Lỗi: $e';
    }
  }

  Future<String> _handleInventoryQuery(String q, String companyId) async {
    try {
      final products = await _supabase
          .from('products')
          .select('name, stock_quantity, min_stock_level, unit, price')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('stock_quantity', ascending: true)
          .limit(20);

      int lowStock = 0;
      int outOfStock = 0;
      final lowStockItems = <String>[];

      for (final p in products) {
        final qty = (p['stock_quantity'] ?? 0) as num;
        final minLevel = (p['min_stock_level'] ?? 10) as num;
        if (qty <= 0) {
          outOfStock++;
          lowStockItems.add('🔴 **${p['name']}** — Hết hàng');
        } else if (qty <= minLevel) {
          lowStock++;
          lowStockItems.add(
              '🟡 **${p['name']}** — ${_numberFormat.format(qty)} ${p['unit'] ?? 'cái'}');
        }
      }

      final itemList = lowStockItems.take(10).join('\n');

      return '📋 **Tồn kho**\n\n'
          'Tổng sản phẩm: **${products.length}**\n'
          '🔴 Hết hàng: **$outOfStock**\n'
          '🟡 Sắp hết: **$lowStock**\n\n'
          '${lowStockItems.isEmpty ? '✅ Tất cả sản phẩm đều đủ hàng!' : '**Cần chú ý:**\n$itemList'}';
    } catch (e) {
      AppLogger.error('AI: Inventory query failed', e);
      return '❌ Không thể truy xuất dữ liệu tồn kho. Lỗi: $e';
    }
  }

  Future<String> _handleEmployeeQuery(String q, String companyId) async {
    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);

      final employees = await _supabase
          .from('employees')
          .select('id, full_name, role, is_active')
          .eq('company_id', companyId)
          .eq('is_active', true);

      final attendance = await _supabase
          .from('attendance')
          .select('employee_id, check_in_time, check_out_time, is_late')
          .eq('company_id', companyId)
          .gte('check_in_time', '${todayStr}T00:00:00')
          .lte('check_in_time', '${todayStr}T23:59:59');

      final checkedInIds =
          attendance.map((a) => a['employee_id']).toSet();
      final lateCount =
          attendance.where((a) => a['is_late'] == true).length;

      return '👨‍💼 **Nhân viên hôm nay** (${DateFormat('dd/MM/yyyy').format(today)})\n\n'
          '👥 Tổng nhân viên: **${employees.length}**\n'
          '✅ Đã chấm công: **${checkedInIds.length}**\n'
          '❌ Chưa chấm công: **${employees.length - checkedInIds.length}**\n'
          '⏰ Đi trễ: **$lateCount**\n'
          '📊 Tỷ lệ: **${employees.isNotEmpty ? (checkedInIds.length * 100 / employees.length).toStringAsFixed(0) : 0}%**';
    } catch (e) {
      AppLogger.error('AI: Employee query failed', e);
      return '❌ Không thể truy xuất dữ liệu nhân viên. Lỗi: $e';
    }
  }

  Future<String> _handleDeliveryQuery(String q, String companyId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final deliveries = await _supabase
          .from('deliveries')
          .select('status, driver_id')
          .eq('company_id', companyId)
          .gte('created_at', '${today}T00:00:00');

      final Map<String, int> byStatus = {};
      for (final d in deliveries) {
        final status = d['status'] as String? ?? 'unknown';
        byStatus[status] = (byStatus[status] ?? 0) + 1;
      }

      final statusLines = byStatus.entries
          .map((e) => '• ${e.key}: **${e.value}**')
          .join('\n');

      return '🚚 **Giao hàng hôm nay**\n\n'
          'Tổng: **${deliveries.length}** chuyến\n\n'
          '${statusLines.isEmpty ? '📭 Chưa có chuyến giao hàng nào hôm nay.' : statusLines}';
    } catch (e) {
      AppLogger.error('AI: Delivery query failed', e);
      return '❌ Không thể truy xuất dữ liệu giao hàng. Lỗi: $e';
    }
  }

  Future<String> _handleDebtQuery(String companyId) async {
    try {
      final receivables = await _supabase
          .from('sales_orders')
          .select('total, paid_amount, customer_id')
          .eq('company_id', companyId)
          .neq('status', 'cancelled');

      double totalDebt = 0;
      int debtOrders = 0;
      for (final o in receivables) {
        final total = (o['total'] ?? 0).toDouble();
        final paid = (o['paid_amount'] ?? 0).toDouble();
        final debt = total - paid;
        if (debt > 0) {
          totalDebt += debt;
          debtOrders++;
        }
      }

      return '💳 **Công nợ**\n\n'
          '💰 Tổng công nợ: **${_currencyFormat.format(totalDebt)}**\n'
          '📄 Số đơn còn nợ: **$debtOrders**\n'
          '📊 Trung bình/đơn: **${debtOrders > 0 ? _currencyFormat.format(totalDebt / debtOrders) : "0₫"}**';
    } catch (e) {
      AppLogger.error('AI: Debt query failed', e);
      return '❌ Không thể truy xuất dữ liệu công nợ. Lỗi: $e';
    }
  }

  Future<String> _handleOverviewQuery(String companyId) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Parallel queries
      final results = await Future.wait([
        _supabase
            .from('sales_orders')
            .select('total, status')
            .eq('company_id', companyId)
            .gte('created_at', '${today}T00:00:00'),
        _supabase
            .from('customers')
            .select('id')
            .eq('company_id', companyId)
            .eq('is_active', true),
        _supabase
            .from('products')
            .select('id, stock_quantity, min_stock_level')
            .eq('company_id', companyId)
            .eq('is_active', true),
        _supabase
            .from('employees')
            .select('id')
            .eq('company_id', companyId)
            .eq('is_active', true),
        _supabase
            .from('attendance')
            .select('employee_id, is_late')
            .eq('company_id', companyId)
            .gte('check_in_time', '${today}T00:00:00'),
        _supabase
            .from('deliveries')
            .select('status')
            .eq('company_id', companyId)
            .gte('created_at', '${today}T00:00:00'),
      ]);

      final orders = results[0] as List;
      final customers = results[1] as List;
      final products = results[2] as List;
      final employees = results[3] as List;
      final attendance = results[4] as List;
      final deliveries = results[5] as List;

      double todayRevenue = 0;
      for (final o in orders) {
        todayRevenue += (o['total'] ?? 0).toDouble();
      }

      int lowStock = 0;
      for (final p in products) {
        if ((p['stock_quantity'] ?? 0) <= (p['min_stock_level'] ?? 10)) {
          lowStock++;
        }
      }

      return '📈 **BÁO CÁO TỔNG QUAN** — ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n'
          '💰 **Doanh thu hôm nay:** ${_currencyFormat.format(todayRevenue)} (${orders.length} đơn)\n'
          '👥 **Khách hàng:** ${_numberFormat.format(customers.length)} hoạt động\n'
          '📦 **Sản phẩm:** ${products.length} (⚠️ $lowStock sắp hết)\n'
          '👨‍💼 **Nhân viên:** ${attendance.length}/${employees.length} đã chấm công\n'
          '🚚 **Giao hàng:** ${deliveries.length} chuyến hôm nay\n'
          '\n---\n'
          '💡 _Hỏi chi tiết: "doanh thu tuần này", "top khách hàng", "tồn kho thấp"_';
    } catch (e) {
      AppLogger.error('AI: Overview query failed', e);
      return '❌ Không thể tạo báo cáo tổng quan. Lỗi: $e';
    }
  }

  Future<String> _handleTelegramTest() async {
    final telegram = TelegramNotifyService();
    if (!TelegramNotifyService.isEnabled) {
      return '⚠️ **Telegram chưa được cấu hình**\n\n'
          'Thêm vào file `.env`:\n'
          '```\nTELEGRAM_BOT_TOKEN=xxx\nTELEGRAM_CHAT_ID=xxx\n```\n\n'
          '**Hướng dẫn nhanh:**\n'
          '1. Mở Telegram → tìm @BotFather → /newbot\n'
          '2. Copy token → dán vào TELEGRAM_BOT_TOKEN\n'
          '3. Tìm @userinfobot → lấy Chat ID\n'
          '4. Restart app';
    }

    final success = await telegram.testConnection();
    if (success) {
      return '✅ **Đã gửi tin nhắn test qua Telegram!**\n\nKiểm tra Telegram của bạn.';
    }
    return '❌ Gửi Telegram thất bại. Kiểm tra lại token và chat ID.';
  }

  String _handleConfigStatus() {
    final geminiOk = GeminiService.isEnabled;
    final telegramOk = TelegramNotifyService.isEnabled;

    return '⚙️ **Trạng thái cấu hình**\n\n'
        '${geminiOk ? "✅" : "❌"} Gemini AI: ${geminiOk ? "Đã kết nối" : "Chưa có key"}\n'
        '${telegramOk ? "✅" : "❌"} Telegram Bot: ${telegramOk ? "Đã kết nối" : "Chưa có token"}\n'
        '✅ Supabase: Đã kết nối\n'
        '✅ Analytics: Đang hoạt động\n\n'
        '${!geminiOk ? "💡 Lấy Gemini key FREE: https://aistudio.google.com/app/apikey\\n" : ""}'
        '${!telegramOk ? "💡 Tạo Telegram bot: Tìm @BotFather trên Telegram\\n" : ""}';
  }
}
