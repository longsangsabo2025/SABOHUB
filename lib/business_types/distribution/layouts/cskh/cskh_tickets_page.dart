import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../utils/quick_date_range_picker.dart';

/// CSKH Tickets Page
/// Danh sách yêu cầu hỗ trợ
class CSKHTicketsPage extends ConsumerStatefulWidget {
  const CSKHTicketsPage({super.key});

  @override
  ConsumerState<CSKHTicketsPage> createState() => _CSKHTicketsPageState();
}

class _CSKHTicketsPageState extends ConsumerState<CSKHTicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTickets = [];
  DateTimeRange? _dateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final supabase = Supabase.instance.client;
      final today = DateTime.now();

      // Get orders with issues (cancelled as "tickets")
      final problemOrders = await supabase
          .from('sales_orders')
          .select('id, order_number, customer_name, customer_phone, status, rejection_reason, cancellation_reason, created_at')
          .eq('company_id', companyId)
          .eq('status', 'cancelled')
          .order('created_at', ascending: false);

      // Apply date filter if set
      List<dynamic> filteredOrders = problemOrders;
      if (_dateFilter != null) {
        filteredOrders = problemOrders.where((order) {
          final createdAt = DateTime.tryParse(order['created_at'] ?? '');
          if (createdAt == null) return false;
          return !createdAt.isBefore(_dateFilter!.start) && 
                 createdAt.isBefore(_dateFilter!.end.add(const Duration(days: 1)));
        }).toList();
      }

      List<Map<String, dynamic>> tickets = [];

      for (var order in filteredOrders) {
        final status = order['status'] as String?;
        final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? today;
        
        String ticketStatus = 'open';
        String priority = 'medium';
        String subject = 'Đơn hàng có vấn đề';
        
        if (status == 'cancelled') {
          subject = 'Đơn đã hủy: ${order['cancellation_reason'] ?? 'Không rõ lý do'}';
          ticketStatus = today.difference(createdAt).inDays > 1 ? 'resolved' : 'open';
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

        tickets.add({
          'id': order['order_number'] ?? order['id'],
          'customer': order['customer_name'] ?? 'Khách hàng',
          'phone': order['customer_phone'] ?? '',
          'subject': subject,
          'status': ticketStatus,
          'priority': priority,
          'created_at': createdAt,
        });
      }

      setState(() {
        _allTickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load tickets', e);
      setState(() {
        _allTickets = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getTicketsByStatus(String status) {
    if (status == 'all') return _allTickets;
    return _allTickets.where((t) => t['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yêu cầu hỗ trợ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final openCount = _getTicketsByStatus('open').length;
    final pendingCount = _getTicketsByStatus('pending').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu hỗ trợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTickets();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: Column(
            children: [
              // Date filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showQuickDateRangePicker(context, current: _dateFilter);
                    if (picked != null) {
                      setState(() {
                        _dateFilter = picked.start.year == 1970 ? null : picked;
                        _isLoading = true;
                      });
                      _loadTickets();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _dateFilter != null ? Colors.indigo.shade50 : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: _dateFilter != null ? Border.all(color: Colors.indigo.shade300) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 15,
                            color: _dateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          _dateFilter != null ? getDateRangeLabel(_dateFilter!) : 'Lọc theo ngày',
                          style: TextStyle(
                            fontSize: 13,
                            color: _dateFilter != null ? Colors.indigo.shade700 : Colors.grey.shade600,
                          ),
                        ),
                        if (_dateFilter != null) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() { _dateFilter = null; _isLoading = true; });
                              _loadTickets();
                            },
                            child: Icon(Icons.close, size: 16, color: Colors.indigo.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Mới'),
                        if (openCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(openCount, Colors.red),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Đang xử lý'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          _buildBadge(pendingCount, Colors.orange),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Đã xong'),
                  const Tab(text: 'Tất cả'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList(_getTicketsByStatus('open')),
          _buildTicketList(_getTicketsByStatus('pending')),
          _buildTicketList(_getTicketsByStatus('resolved')),
          _buildTicketList(_allTickets),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTicket,
        icon: const Icon(Icons.add),
        label: const Text('Tạo yêu cầu'),
      ),
    );
  }

  Widget _buildBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTicketList(List<Map<String, dynamic>> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status'] as String;
    final priority = ticket['priority'] as String;
    final createdAt = ticket['created_at'] as DateTime;

    Color priorityColor;
    String priorityText;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        priorityText = 'Cao';
        break;
      case 'medium':
        priorityColor = Colors.orange;
        priorityText = 'Trung bình';
        break;
      default:
        priorityColor = Colors.blue;
        priorityText = 'Thấp';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTicketActions(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${ticket['id']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      priorityText,
                      style: TextStyle(
                        color: priorityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['subject'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    ticket['customer'],
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm - dd/MM').format(createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              if (status == 'open' || status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Call customer
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Gọi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            ticket['status'] = status == 'open' ? 'pending' : 'resolved';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                status == 'open' 
                                    ? 'Đã tiếp nhận xử lý' 
                                    : 'Đã hoàn thành!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: Icon(
                          status == 'open' ? Icons.play_arrow : Icons.check,
                          size: 18,
                        ),
                        label: Text(status == 'open' ? 'Xử lý' : 'Hoàn thành'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketActions(Map<String, dynamic> ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Xem chi tiết'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Gọi khách hàng'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.blue),
              title: const Text('Gửi tin nhắn'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Thêm ghi chú'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewTicket() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo yêu cầu mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên khách hàng',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nội dung yêu cầu',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã tạo yêu cầu mới!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
