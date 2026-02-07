import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

/// CSKH Dashboard Page
/// Dashboard tổng quan cho nhân viên CSKH
class CSKHDashboardPage extends ConsumerStatefulWidget {
  const CSKHDashboardPage({super.key});

  @override
  ConsumerState<CSKHDashboardPage> createState() => _CSKHDashboardPageState();
}

class _CSKHDashboardPageState extends ConsumerState<CSKHDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentTickets = [];
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final DateTimeRange effectiveRange = _dateFilter ?? DateTimeRange(
        start: DateTime(today.year, today.month, today.day),
        end: DateTime(today.year, today.month, today.day),
      );
      final rangeStart = effectiveRange.start;
      final rangeEnd = effectiveRange.end.add(const Duration(days: 1));

      // Get total customers
      final customersCount = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .count();

      // Get orders with issues (cancelled as "tickets")
      final problemOrders = await supabase
          .from('sales_orders')
          .select('id, order_number, customer_name, status, rejection_reason, cancellation_reason, created_at')
          .eq('company_id', companyId)
          .eq('status', 'cancelled');

      // Count by "ticket" status
      int openTickets = 0;
      int pendingTickets = 0;
      int resolvedToday = 0;
      List<Map<String, dynamic>> recentIssues = [];

      for (var order in problemOrders) {
        final status = order['status'] as String?;
        final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? today;
        
        // Determine ticket status and priority
        String ticketStatus = 'open';
        String priority = 'medium';
        String subject = 'Đơn hàng có vấn đề';
        
        if (status == 'cancelled') {
          subject = 'Đơn đã hủy: ${order['cancellation_reason'] ?? 'Không rõ lý do'}';
          ticketStatus = createdAt.isAfter(rangeStart) && createdAt.isBefore(rangeEnd) ? 'open' : 'resolved';
          priority = 'low';
        } else if (status == 'rejected') {
          subject = 'Đơn bị từ chối: ${order['rejection_reason'] ?? 'Không rõ lý do'}';
          ticketStatus = 'open';
          priority = 'high';
        } else if (status == 'returned') {
          subject = 'Đơn bị trả lại';
          ticketStatus = 'pending';
          priority = 'high';
        }

        if (ticketStatus == 'open') openTickets++;
        else if (ticketStatus == 'pending') pendingTickets++;
        
        if (createdAt.isAfter(rangeStart) && createdAt.isBefore(rangeEnd) && ticketStatus == 'resolved') {
          resolvedToday++;
        }

        recentIssues.add({
          'id': order['order_number'] ?? order['id'],
          'customer': order['customer_name'] ?? 'Khách hàng',
          'subject': subject,
          'status': ticketStatus,
          'priority': priority,
          'created_at': createdAt,
        });
      }

      // Sort by date and take recent 5
      recentIssues.sort((a, b) => 
          (b['created_at'] as DateTime).compareTo(a['created_at'] as DateTime));

      setState(() {
        _stats = {
          'openTickets': openTickets,
          'pendingTickets': pendingTickets,
          'resolvedToday': resolvedToday,
          'totalCustomers': customersCount.count,
        };
        _recentTickets = recentIssues.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load CSKH dashboard', e);
      setState(() {
        _stats = {
          'openTickets': 0,
          'pendingTickets': 0,
          'resolvedToday': 0,
          'totalCustomers': 0,
        };
        _recentTickets = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CSKH - Tổng quan'),
        actions: [
          // Date filter button
          GestureDetector(
            onTap: () async {
              final picked = await showQuickDateRangePicker(context, current: _dateFilter);
              if (picked != null) {
                setState(() {
                  _dateFilter = picked.start.year == 1970 ? null : picked;
                  _isLoading = true;
                });
                _loadDashboardData();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _dateFilter != null ? Colors.indigo.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: _dateFilter != null ? Border.all(color: Colors.indigo.shade300) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14,
                      color: _dateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _dateFilter != null ? getDateRangeLabel(_dateFilter!) : 'Hôm nay',
                    style: TextStyle(
                      fontSize: 12,
                      color: _dateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 18,
                      color: _dateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    Card(
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.purple.shade100,
                              child: Icon(
                                Icons.support_agent,
                                size: 30,
                                color: Colors.purple.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xin chào, ${user?.name ?? 'CSKH'}!',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Chăm sóc khách hàng',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Đang mở',
                          _stats['openTickets']?.toString() ?? '0',
                          Icons.folder_open,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Đang xử lý',
                          _stats['pendingTickets']?.toString() ?? '0',
                          Icons.hourglass_empty,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Đã giải quyết',
                          _stats['resolvedToday']?.toString() ?? '0',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Khách hàng',
                          _stats['totalCustomers']?.toString() ?? '0',
                          Icons.people,
                          Colors.blue,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent tickets
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Yêu cầu gần đây',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedIndex = 1);
                          },
                          child: const Text('Xem tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ..._recentTickets.map((ticket) => _buildTicketCard(ticket)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String;
    final priority = ticket['priority'] as String;
    final createdAt = ticket['created_at'] as DateTime;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'open':
        statusColor = Colors.red;
        statusText = 'Mới';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Đang xử lý';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Đã giải quyết';
        break;
      default:
        statusColor = Colors.grey;
        statusText = status;
    }

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          ticket['subject'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ticket['customer']),
            Text(
              DateFormat('HH:mm - dd/MM').format(createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        isThreeLine: true,
        onTap: () {
          _showTicketDetail(ticket);
        },
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '#${ticket['id']}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['subject'],
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(ticket['customer']),
                subtitle: const Text('Khách hàng'),
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Nội dung yêu cầu:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khách hàng phản ánh về vấn đề với đơn hàng. Cần kiểm tra và xử lý sớm.',
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Gọi điện'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã tiếp nhận xử lý!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Xử lý'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  set _selectedIndex(int value) {
    // Navigate to parent's tab
  }
}
