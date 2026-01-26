import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../widgets/bug_report_dialog.dart';
import '../widgets/realtime_notification_widgets.dart';

import '../providers/auth_provider.dart';
import '../utils/app_logger.dart';

/// Distribution Customer Service Layout
/// Layout cho nhân viên CSKH của công ty phân phối (Odori)
/// Handles: Customer complaints, Support tickets, Customer feedback
class DistributionCustomerServiceLayout extends ConsumerStatefulWidget {
  const DistributionCustomerServiceLayout({super.key});

  @override
  ConsumerState<DistributionCustomerServiceLayout> createState() =>
      _DistributionCustomerServiceLayoutState();
}

class _DistributionCustomerServiceLayoutState
    extends ConsumerState<DistributionCustomerServiceLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _CSKHDashboardPage(),
    const _TicketsPage(),
    const _CustomersPage(),
    const _CSKHProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'CSKH';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('CSKH - $userName'),
        actions: const [
          RealtimeNotificationBell(),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Yêu cầu',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Khách hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CSKH DASHBOARD PAGE
// ============================================================================
class _CSKHDashboardPage extends ConsumerStatefulWidget {
  const _CSKHDashboardPage();

  @override
  ConsumerState<_CSKHDashboardPage> createState() => _CSKHDashboardPageState();
}

class _CSKHDashboardPageState extends ConsumerState<_CSKHDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentTickets = [];

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
      final startOfDay = DateTime(today.year, today.month, today.day);

      // Get total customers
      final customersCount = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .count();

      // Get orders with issues (cancelled, returned, rejected as "tickets")
      final problemOrders = await supabase
          .from('sales_orders')
          .select('id, order_number, customer_name, status, rejection_reason, cancellation_reason, created_at')
          .eq('company_id', companyId)
          .or('status.eq.cancelled,status.eq.rejected,status.eq.returned');

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
          ticketStatus = createdAt.isAfter(startOfDay) ? 'open' : 'resolved';
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
        
        if (createdAt.isAfter(startOfDay) && ticketStatus == 'resolved') {
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

  set _selectedIndex(int value) {
    // Navigate to parent's tab
  }
}

// ============================================================================
// TICKETS PAGE - Danh sách yêu cầu hỗ trợ
// ============================================================================
class _TicketsPage extends ConsumerStatefulWidget {
  const _TicketsPage();

  @override
  ConsumerState<_TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<_TicketsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTickets = [];

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

      // Get orders with issues (cancelled, returned, rejected as "tickets")
      final problemOrders = await supabase
          .from('sales_orders')
          .select('id, order_number, customer_name, customer_phone, status, rejection_reason, cancellation_reason, created_at')
          .eq('company_id', companyId)
          .or('status.eq.cancelled,status.eq.rejected,status.eq.returned')
          .order('created_at', ascending: false)
          .limit(100);

      List<Map<String, dynamic>> tickets = [];

      for (var order in problemOrders) {
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
        bottom: TabBar(
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

// ============================================================================
// CUSTOMERS PAGE - Danh sách khách hàng
// ============================================================================
class _CustomersPage extends ConsumerStatefulWidget {
  const _CustomersPage();

  @override
  ConsumerState<_CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<_CustomersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _customers = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('customers')
          .select('*')
          .eq('company_id', companyId)
          .order('name', ascending: true)
          .limit(100);

      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers', e);
      setState(() {
        _customers = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm khách hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final searchQuery = _searchController.text.toLowerCase();
                      
                      if (searchQuery.isNotEmpty &&
                          !customer['name'].toString().toLowerCase().contains(searchQuery) &&
                          !customer['phone'].toString().contains(searchQuery)) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildCustomerCard(customer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Text(
            customer['name'].toString()[0].toUpperCase(),
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer['phone'] ?? ''),
            if (customer['total_orders'] != null)
              Text(
                '${customer['total_orders']} đơn hàng',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone, color: Colors.green),
          onPressed: () {
            // Call customer
          },
        ),
        isThreeLine: true,
        onTap: () {
          _showCustomerDetail(customer);
        },
      ),
    );
  }

  void _showCustomerDetail(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.purple.shade100,
                    child: Text(
                      customer['name'].toString()[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer['phone'] ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (customer['address'] != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on),
                  title: const Text('Địa chỉ'),
                  subtitle: Text(customer['address']),
                ),
              ],
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Tổng đơn hàng'),
                trailing: Text(
                  '${customer['total_orders'] ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.history),
                      label: const Text('Lịch sử'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo yêu cầu'),
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
}

// ============================================================================
// CSKH PROFILE PAGE
// ============================================================================
class _CSKHProfilePage extends ConsumerWidget {
  const _CSKHProfilePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.purple.shade100,
                      child: Text(
                        (user?.name ?? 'C')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'CSKH',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Chăm sóc khách hàng',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.companyName ?? 'Công ty',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Đã xử lý', '156', Colors.green),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildStatItem('Đánh giá', '4.8', Colors.orange),
                    Container(width: 1, height: 40, color: Colors.grey.shade300),
                    _buildStatItem('Tháng này', '23', Colors.blue),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Menu items
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Thông tin cá nhân'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bar_chart_outlined),
                    title: const Text('Thống kê'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Cài đặt'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.bug_report_outlined, color: Colors.red.shade400),
                    title: const Text('Báo cáo lỗi'),
                    subtitle: const Text('Gửi phản hồi về vấn đề gặp phải'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => BugReportDialog.show(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(authProvider.notifier).logout();
                          },
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
