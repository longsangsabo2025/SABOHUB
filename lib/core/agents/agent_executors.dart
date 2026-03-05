import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/gemini_service.dart';
import '../../utils/app_logger.dart';
import 'agent_orchestrator.dart';
import 'agent_types.dart';

/// ============================================================================
/// AGENT EXECUTORS — Concrete Implementations
/// Bridges the AgentOrchestrator to actual SABOHUB services.
///
/// Each executor wraps existing logic:
/// - RouterExecutor → keyword intent classification (from AIChatService)
/// - DataFetcherExecutor → Supabase queries (from AIChatService handlers)
/// - AnalyzerExecutor → Gemini 2.0 Flash (from GeminiService)
/// - ResponderExecutor → markdown formatting
/// - ReviewerExecutor → quality validation
/// ============================================================================

class AgentExecutors {
  AgentExecutors._();

  /// Wire all executors into an orchestrator
  static void registerAll(AgentOrchestrator orchestrator) {
    orchestrator
      ..registerAgent(AgentRole.router, routerExecutor)
      ..registerAgent(AgentRole.dataFetcher, dataFetcherExecutor)
      ..registerAgent(AgentRole.analyzer, analyzerExecutor)
      ..registerAgent(AgentRole.responder, responderExecutor)
      ..registerAgent(AgentRole.reviewer, reviewerExecutor);
  }

  // ─── Router Executor ──────────────────────────────────────────

  static Future<Map<String, dynamic>> routerExecutor(
    AgentStep step,
    Map<String, dynamic> context,
  ) async {
    final query = (context['query'] as String? ?? '').toLowerCase().trim();

    // Keyword-based intent classification (ported from AIChatService)
    final intentMap = <String, List<String>>{
      'revenue': ['doanh thu', 'revenue', 'bán hàng', 'sales'],
      'orders': ['đơn hàng', 'order', 'đơn mới'],
      'customers': ['khách hàng', 'customer', 'top khách'],
      'inventory': ['tồn kho', 'inventory', 'sản phẩm', 'hết hàng', 'stock'],
      'employees': ['nhân viên', 'employee', 'đi làm', 'attendance', 'chấm công'],
      'overview': ['tổng quan', 'overview', 'báo cáo', 'report', 'dashboard'],
      'delivery': ['giao hàng', 'delivery', 'vận chuyển'],
      'debt': ['công nợ', 'debt', 'nợ'],
      'config': ['cấu hình', 'config', 'status', 'kết nối'],
      'pdf_export': ['pdf', 'xuất', 'export', 'in báo cáo', 'tải'],
      'telegram': ['telegram', 'test bot', 'gửi telegram'],
    };

    String intent = 'freeform';
    bool isComplex = false;

    for (final entry in intentMap.entries) {
      if (entry.value.any((k) => query.contains(k))) {
        intent = entry.key;
        break;
      }
    }

    // Detect complexity (comparison, multi-dimension queries)
    if (_matchesAny(query, ['so sánh', 'vs', 'top', 'xu hướng', 'trend'])) {
      isComplex = true;
    }

    // Detect time period
    String period = 'today';
    if (_matchesAny(query, ['hôm nay', 'today', 'ngày'])) {
      period = 'today';
    } else if (_matchesAny(query, ['tuần', 'week'])) {
      period = 'week';
    } else if (_matchesAny(query, ['tháng', 'month'])) {
      period = 'month';
    } else if (_matchesAny(query, ['năm', 'year'])) {
      period = 'year';
    }

    return {
      'intent': intent,
      'isComplex': isComplex,
      'period': period,
      'confidence': intent == 'freeform' ? 0.3 : 0.9,
    };
  }

  // ─── Data Fetcher Executor ────────────────────────────────────

  static final _supabase = Supabase.instance.client;
  static final _currencyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  static final _numberFormat = NumberFormat('#,###', 'vi_VN');

  static Future<Map<String, dynamic>> dataFetcherExecutor(
    AgentStep step,
    Map<String, dynamic> context,
  ) async {
    final intent = context['intent'] as String? ?? 'unknown';
    final companyId = context['companyId'] as String? ?? '';
    final period = context['period'] as String? ?? 'today';

    try {
      switch (intent) {
        case 'revenue':
          return await _fetchRevenue(companyId, period);
        case 'orders':
          return await _fetchOrders(companyId, period);
        case 'customers':
          return await _fetchCustomers(companyId);
        case 'inventory':
          return await _fetchInventory(companyId);
        case 'employees':
          return await _fetchEmployees(companyId);
        case 'overview':
          return await _fetchOverview(companyId);
        case 'delivery':
          return await _fetchDeliveries(companyId);
        case 'debt':
          return await _fetchDebt(companyId);
        default:
          return {
            'data': null,
            'localResponse': null,
          };
      }
    } catch (e) {
      AppLogger.error('DataFetcher error for $intent', e);
      return {
        'data': null,
        'localResponse': '❌ Không thể truy xuất dữ liệu. Lỗi: $e',
        'error': e.toString(),
      };
    }
  }

  // ─── Analyzer Executor ────────────────────────────────────────

  static final _gemini = GeminiService();

  static Future<Map<String, dynamic>> analyzerExecutor(
    AgentStep step,
    Map<String, dynamic> context,
  ) async {
    final query = context['query'] as String? ?? '';
    final localResponse = step.input['localResponse'] as String? ?? '';
    final intent = step.input['intent'] as String? ?? '';

    if (!GeminiService.isEnabled) {
      return {'analysis': null, 'insights': null};
    }

    // Skip AI for intents that don't benefit
    if (['config', 'pdf_export', 'telegram'].contains(intent)) {
      return {'analysis': null, 'insights': null};
    }

    try {
      final aiInsight = await _gemini.chat(
        query,
        businessContext: localResponse,
      );

      return {
        'analysis': aiInsight.isNotEmpty ? aiInsight : null,
        'insights': aiInsight.isNotEmpty ? aiInsight : null,
      };
    } catch (e) {
      AppLogger.error('Analyzer error', e);
      return {'analysis': null, 'insights': null};
    }
  }

  // ─── Responder Executor ───────────────────────────────────────

  static Future<Map<String, dynamic>> responderExecutor(
    AgentStep step,
    Map<String, dynamic> context,
  ) async {
    final localResponse = step.input['localResponse'] as String?;
    final analysis = step.input['analysis'] as String?;

    String response = localResponse ?? '';

    if (analysis != null && analysis.isNotEmpty) {
      response += '\n\n---\n🤖 **Phân tích AI:**\n$analysis';
    }

    return {'response': response};
  }

  // ─── Reviewer Executor ────────────────────────────────────────

  static Future<Map<String, dynamic>> reviewerExecutor(
    AgentStep step,
    Map<String, dynamic> context,
  ) async {
    final response = step.input['response'] as String? ?? '';
    final intent = context['intent'] as String? ?? '';

    double confidence = 0.5;
    String? correctedResponse;

    // Rule-based quality checks
    final checks = <String, bool>{
      'hasContent': response.length > 20,
      'hasFormatting': response.contains('**') || response.contains('•'),
      'hasEmoji': RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true)
          .hasMatch(response),
      'isVietnamese': RegExp(
              r'[àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]')
          .hasMatch(response.toLowerCase()),
      'noError': !response.startsWith('❌'),
      'appropriateLength': response.length >= 50 && response.length <= 5000,
    };

    // Calculate confidence from checks
    final passedChecks = checks.values.where((v) => v).length;
    confidence = passedChecks / checks.length;

    // Boost confidence for data-driven intents with numbers
    if (['revenue', 'orders', 'debt', 'overview'].contains(intent)) {
      if (RegExp(r'\d').hasMatch(response)) {
        confidence = (confidence + 0.1).clamp(0.0, 1.0);
      }
    }

    return {
      'confidence': confidence,
      'correctedResponse': correctedResponse,
      'checks': checks,
    };
  }

  // ─── Data Fetch Implementations ───────────────────────────────

  static DateTime _periodStart(String period) {
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

  static String _periodLabel(String period) {
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

  static Future<Map<String, dynamic>> _fetchRevenue(
      String companyId, String period) async {
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

    final label = _periodLabel(period);
    return {
      'data': {
        'totalRevenue': totalRevenue,
        'orderCount': orderCount,
        'completedCount': completedCount,
        'period': period,
      },
      'localResponse': '📊 **Doanh thu $label**\n\n'
          '💰 Tổng doanh thu: **${_currencyFormat.format(totalRevenue)}**\n'
          '📦 Số đơn hàng: **${_numberFormat.format(orderCount)}**\n'
          '✅ Đã hoàn thành: **${_numberFormat.format(completedCount)}**\n'
          '📈 Trung bình/đơn: **${orderCount > 0 ? _currencyFormat.format(totalRevenue / orderCount) : "0₫"}**',
    };
  }

  static Future<Map<String, dynamic>> _fetchOrders(
      String companyId, String period) async {
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

    final label = _periodLabel(period);
    return {
      'data': {'orders': orders, 'byStatus': byStatus, 'total': total},
      'localResponse': '📦 **Đơn hàng $label**\n\n'
          'Tổng: **${orders.length}** đơn — ${_currencyFormat.format(total)}\n\n'
          '$statusLines',
    };
  }

  static Future<Map<String, dynamic>> _fetchCustomers(
      String companyId) async {
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

    return {
      'data': {'customers': customers, 'totalCount': totalCount.length},
      'localResponse': '👥 **Khách hàng**\n\n'
          'Tổng số: **${totalCount.length}** khách hàng hoạt động\n\n'
          '**Top khách hàng gần đây:**\n$customerLines',
    };
  }

  static Future<Map<String, dynamic>> _fetchInventory(
      String companyId) async {
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

    return {
      'data': {
        'products': products,
        'lowStock': lowStock,
        'outOfStock': outOfStock,
      },
      'localResponse': '📋 **Tồn kho**\n\n'
          'Tổng sản phẩm: **${products.length}**\n'
          '🔴 Hết hàng: **$outOfStock**\n'
          '🟡 Sắp hết: **$lowStock**\n\n'
          '${lowStockItems.isEmpty ? '✅ Tất cả sản phẩm đều đủ hàng!' : '**Cần chú ý:**\n$itemList'}',
    };
  }

  static Future<Map<String, dynamic>> _fetchEmployees(
      String companyId) async {
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

    final checkedInIds = attendance.map((a) => a['employee_id']).toSet();
    final lateCount = attendance.where((a) => a['is_late'] == true).length;

    return {
      'data': {
        'employees': employees,
        'attendance': attendance,
        'checkedIn': checkedInIds.length,
        'late': lateCount,
      },
      'localResponse':
          '👨‍💼 **Nhân viên hôm nay** (${DateFormat('dd/MM/yyyy').format(today)})\n\n'
              '👥 Tổng nhân viên: **${employees.length}**\n'
              '✅ Đã chấm công: **${checkedInIds.length}**\n'
              '❌ Chưa chấm công: **${employees.length - checkedInIds.length}**\n'
              '⏰ Đi trễ: **$lateCount**\n'
              '📊 Tỷ lệ: **${employees.isNotEmpty ? (checkedInIds.length * 100 / employees.length).toStringAsFixed(0) : 0}%**',
    };
  }

  static Future<Map<String, dynamic>> _fetchOverview(
      String companyId) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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

    return {
      'data': {
        'revenue': todayRevenue,
        'orders': orders.length,
        'customers': customers.length,
        'products': products.length,
        'lowStock': lowStock,
        'attendance': attendance.length,
        'employees': employees.length,
        'deliveries': deliveries.length,
      },
      'localResponse':
          '📈 **BÁO CÁO TỔNG QUAN** — ${DateFormat('dd/MM/yyyy').format(DateTime.now())}\n\n'
              '💰 **Doanh thu hôm nay:** ${_currencyFormat.format(todayRevenue)} (${orders.length} đơn)\n'
              '👥 **Khách hàng:** ${_numberFormat.format(customers.length)} hoạt động\n'
              '📦 **Sản phẩm:** ${products.length} (⚠️ $lowStock sắp hết)\n'
              '👨‍💼 **Nhân viên:** ${attendance.length}/${employees.length} đã chấm công\n'
              '🚚 **Giao hàng:** ${deliveries.length} chuyến hôm nay\n'
              '\n---\n'
              '💡 _Hỏi chi tiết: "doanh thu tuần này", "top khách hàng", "tồn kho thấp"_',
    };
  }

  static Future<Map<String, dynamic>> _fetchDeliveries(
      String companyId) async {
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

    return {
      'data': {'deliveries': deliveries, 'byStatus': byStatus},
      'localResponse': '🚚 **Giao hàng hôm nay**\n\n'
          'Tổng: **${deliveries.length}** chuyến\n\n'
          '${statusLines.isEmpty ? '📭 Chưa có chuyến giao hàng nào hôm nay.' : statusLines}',
    };
  }

  static Future<Map<String, dynamic>> _fetchDebt(String companyId) async {
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

    return {
      'data': {'totalDebt': totalDebt, 'debtOrders': debtOrders},
      'localResponse': '💳 **Công nợ**\n\n'
          '💰 Tổng công nợ: **${_currencyFormat.format(totalDebt)}**\n'
          '📄 Số đơn còn nợ: **$debtOrders**\n'
          '📊 Trung bình/đơn: **${debtOrders > 0 ? _currencyFormat.format(totalDebt / debtOrders) : "0₫"}**',
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
