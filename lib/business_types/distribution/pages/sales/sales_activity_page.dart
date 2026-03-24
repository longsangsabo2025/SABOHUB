import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';


/// Sales Activity Timeline — chronological log of all sales activities
/// Shows: visits, orders created, samples sent, check-ins, calls, etc.
class SalesActivityPage extends ConsumerStatefulWidget {
  const SalesActivityPage({super.key});

  @override
  ConsumerState<SalesActivityPage> createState() => _SalesActivityPageState();
}

class _SalesActivityPageState extends ConsumerState<SalesActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_ActivityItem> _activities = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  // Stats
  int _totalVisits = 0;
  int _totalOrders = 0;
  int _totalSamples = 0;
  int _totalPhotos = 0;
  int _totalSurveys = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActivities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      final userId = user?.id;

      if (companyId == null || userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final activities = <_ActivityItem>[];

      // 1. Fetch store visits (check-in/out)
      final visits = await supabase
          .from('store_visits')
          .select('id, customer_id, check_in_time, check_out_time, status, customer_feedback, next_visit_notes, order_placed, order_amount, customers(name)')
          .eq('company_id', companyId)
          .eq('employee_id', userId)
          .gte('visit_date', dayStart.toIso8601String())
          .lt('visit_date', dayEnd.toIso8601String())
          .order('check_in_time', ascending: false);

      for (final v in visits) {
        final customerName = (v['customers'] as Map?)?['name'] ?? 'Khách hàng';
        if (v['check_in_time'] != null) {
          activities.add(_ActivityItem(
            type: _ActivityType.checkIn,
            title: 'Check-in: $customerName',
            subtitle: v['customer_feedback'] ?? 'Đang ghé thăm',
            time: DateTime.parse(v['check_in_time']),
            icon: Icons.login,
            color: Colors.green,
            metadata: {'visit_id': v['id']},
          ));
        }
        if (v['check_out_time'] != null) {
          final hasOrder = v['order_placed'] == true;
          activities.add(_ActivityItem(
            type: _ActivityType.checkOut,
            title: 'Check-out: $customerName',
            subtitle: hasOrder
                ? 'Đã đặt hàng ${_formatCurrency(v['order_amount'])}'
                : (v['next_visit_notes']?.toString().isNotEmpty == true
                    ? 'Vấn đề: ${v['next_visit_notes']}'
                    : 'Không đặt hàng'),
            time: DateTime.parse(v['check_out_time']),
            icon: Icons.logout,
            color: Colors.blue,
          ));
        }
      }

      // 2. Fetch orders created today
      final orders = await supabase
          .from('sales_orders')
          .select('id, order_number, total, status, created_at, customers(name)')
          .eq('company_id', companyId)
          .eq('sale_id', userId)
          .gte('created_at', dayStart.toIso8601String())
          .lt('created_at', dayEnd.toIso8601String())
          .order('created_at', ascending: false);

      for (final o in orders) {
        final customerName = (o['customers'] as Map?)?['name'] ?? 'Khách hàng';
        activities.add(_ActivityItem(
          type: _ActivityType.order,
          title: 'Tạo đơn: ${o['order_number'] ?? 'N/A'}',
          subtitle: '$customerName — ${_formatCurrency(o['total'])}',
          time: DateTime.parse(o['created_at']),
          icon: Icons.shopping_cart,
          color: Colors.orange,
          metadata: {'order_id': o['id']},
        ));
      }

      // 3. Fetch product samples sent today
      final samples = await supabase
          .from('product_samples')
          .select('id, status, sent_date, quantity, unit, products(name), customers(name)')
          .eq('company_id', companyId)
          .eq('sent_by_id', userId)
          .gte('sent_date', dayStart.toIso8601String().split('T')[0])
          .lte('sent_date', dayEnd.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      for (final s in samples) {
        final productName = (s['products'] as Map?)?['name'] ?? 'Sản phẩm';
        final customerName = (s['customers'] as Map?)?['name'] ?? 'Khách hàng';
        activities.add(_ActivityItem(
          type: _ActivityType.sample,
          title: 'Gửi mẫu: $productName',
          subtitle: '$customerName — ${s['quantity']} ${s['unit'] ?? ''}',
          time: DateTime.tryParse(s['sent_date']?.toString() ?? '') ?? dayStart,
          icon: Icons.card_giftcard,
          color: Colors.pink,
        ));
      }

      // 4. Fetch visit photos uploaded today
      final photos = await supabase
          .from('store_visit_photos')
          .select('id, taken_at, category')
          .eq('uploaded_by', userId)
          .gte('taken_at', dayStart.toIso8601String())
          .lt('taken_at', dayEnd.toIso8601String())
          .order('taken_at', ascending: false);

      for (final p in photos) {
        activities.add(_ActivityItem(
          type: _ActivityType.photo,
          title: 'Chụp ảnh điểm bán',
          subtitle: _getCategoryLabel(p['category']),
          time: DateTime.parse(p['taken_at']),
          icon: Icons.camera_alt,
          color: Colors.deepPurple,
        ));
      }

      // 5. Fetch survey responses submitted today
      final surveyResponses = await supabase
          .from('survey_responses')
          .select('id, created_at, surveys(title)')
          .eq('respondent_id', userId)
          .gte('created_at', dayStart.toIso8601String())
          .lt('created_at', dayEnd.toIso8601String())
          .order('created_at', ascending: false);

      for (final sr in surveyResponses) {
        final surveyTitle = (sr['surveys'] as Map?)?['title'] ?? 'Khảo sát';
        activities.add(_ActivityItem(
          type: _ActivityType.survey,
          title: 'Hoàn thành khảo sát',
          subtitle: surveyTitle,
          time: DateTime.parse(sr['created_at']),
          icon: Icons.poll,
          color: Colors.purple,
        ));
      }

      // Sort by time descending
      activities.sort((a, b) => b.time.compareTo(a.time));

      // Update stats
      _totalVisits = visits.length;
      _totalOrders = orders.length;
      _totalSamples = samples.length;
      _totalPhotos = photos.length;
      _totalSurveys = surveyResponses.length;

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load sales activities', e);
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount ?? 0).toDouble();
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(value);
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'shelf_display':
        return 'Trưng bày kệ';
      case 'competitor':
        return 'Đối thủ';
      case 'promotion':
        return 'Khuyến mãi';
      case 'posm':
        return 'POSM';
      default:
        return 'Ảnh điểm bán';
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Hoạt động Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: 'Chọn ngày',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isToday ? 'Hôm nay' : DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
                  style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadActivities,
              child: CustomScrollView(
                slivers: [
                  // Stats Summary
                  SliverToBoxAdapter(child: _buildStatsGrid()),

                  // Timeline
                  if (_activities.isEmpty)
                    SliverFillRemaining(child: _buildEmptyState())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildActivityTile(_activities[index], index),
                        childCount: _activities.length,
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatChip(Icons.store, '$_totalVisits', 'Ghé thăm', Colors.green),
          const SizedBox(width: 8),
          _buildStatChip(Icons.shopping_cart, '$_totalOrders', 'Đơn hàng', Colors.orange),
          const SizedBox(width: 8),
          _buildStatChip(Icons.card_giftcard, '$_totalSamples', 'Mẫu SP', Colors.pink),
          const SizedBox(width: 8),
          _buildStatChip(Icons.camera_alt, '$_totalPhotos', 'Ảnh', Colors.deepPurple),
          const SizedBox(width: 8),
          _buildStatChip(Icons.poll, '$_totalSurveys', 'Khảo sát', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có hoạt động nào',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Các hoạt động check-in, tạo đơn, gửi mẫu sẽ hiện ở đây',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(_ActivityItem item, int index) {
    final timeStr = DateFormat('HH:mm').format(item.time);
    final isFirst = index == 0;
    final isLast = index == _activities.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Timeline line + dot
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(child: Container(width: 2, color: Colors.grey.shade300))
                  else
                    Expanded(child: SizedBox()),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                      boxShadow: [
                        BoxShadow(color: item.color.withOpacity(0.3), blurRadius: 4, spreadRadius: 1),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(child: Container(width: 2, color: Colors.grey.shade300))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (item.subtitle.isNotEmpty)
                            Text(
                              item.subtitle,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ActivityType { checkIn, checkOut, order, sample, photo, survey }

class _ActivityItem {
  final _ActivityType type;
  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final Color color;
  final Map<String, dynamic>? metadata;

  _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.metadata,
  });
}
