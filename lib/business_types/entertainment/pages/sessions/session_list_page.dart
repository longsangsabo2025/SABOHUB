import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/session.dart';
import '../../providers/session_provider.dart';
import 'session_form_page.dart';
import '../../../../pages/orders/payment_page.dart';

class SessionListPage extends ConsumerStatefulWidget {
  const SessionListPage({super.key});

  @override
  ConsumerState<SessionListPage> createState() => _SessionListPageState();
}

class _SessionListPageState extends ConsumerState<SessionListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Auto refresh every 30 seconds for real-time updates
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        ref.invalidate(allSessionsProvider);
        ref.invalidate(sessionStatsProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionStats = ref.watch(sessionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phiên chơi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Stats cards
              sessionStats.when(
                data: (stats) => _buildStatsCards(stats),
                loading: () => const SizedBox(height: 40),
                error: (error, stack) => const SizedBox(height: 40),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Đang chơi'),
                  Tab(text: 'Tạm dừng'), 
                  Tab(text: 'Hoàn thành'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllSessionsTab(),
          _buildSessionsByStatusTab(SessionStatus.active),
          _buildSessionsByStatusTab(SessionStatus.paused),
          _buildSessionsByStatusTab(SessionStatus.completed),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStartSessionDialog(),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsCards(Map<String, dynamic> stats) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            'Đang chơi',
            '${stats['activeSessions']}',
            Colors.green,
            Icons.play_circle,
          ),
          const SizedBox(width: 2),
          _buildStatCard(
            'Tạm dừng',
            '${stats['pausedSessions']}',
            Colors.orange,
            Icons.pause_circle,
          ),
          const SizedBox(width: 2),
          _buildStatCard(
            'Hôm nay',
            '${stats['completedToday']}',
            Colors.blue,
            Icons.check_circle,
          ),
          const SizedBox(width: 2),
          _buildStatCard(
            'Doanh thu',
            '${(stats['todayRevenue'] as double).toInt()}K',
            Colors.purple,
            Icons.monetization_on,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllSessionsTab() {
    final allSessions = ref.watch(allSessionsProvider);
    
    return allSessions.when(
      data: (sessions) => _buildSessionsList(sessions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildSessionsByStatusTab(SessionStatus status) {
    final sessions = ref.watch(sessionsByStatusProvider(status));
    
    return sessions.when(
      data: (sessions) => _buildSessionsList(sessions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorWidget(error.toString()),
    );
  }

  Widget _buildSessionsList(List<TableSession> sessions) {
    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có phiên chơi nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sessions.length,
        itemBuilder: (context, index) => _buildSessionCard(sessions[index]),
      ),
    );
  }

  Widget _buildSessionCard(TableSession session) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.tableName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (session.customerName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            session.customerName!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: session.status.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.status.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Time and amount info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian chơi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        session.playingTimeFormatted,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${session.calculateTotalAmount().toInt()}K',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Action buttons for active/paused sessions
              if (session.status == SessionStatus.active || session.status == SessionStatus.paused) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (session.status == SessionStatus.active) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pauseSession(session.id),
                          icon: const Icon(Icons.pause, size: 16),
                          label: const Text('Tạm dừng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (session.status == SessionStatus.paused) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _resumeSession(session.id),
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Tiếp tục'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToPayment(session),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Thanh toán'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Lỗi: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    ref.invalidate(allSessionsProvider);
    ref.invalidate(sessionStatsProvider);
    for (final status in SessionStatus.values) {
      ref.invalidate(sessionsByStatusProvider(status));
    }
  }

  void _showStartSessionDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SessionFormPage(),
      ),
    );
  }

  void _showSessionDetails(TableSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSessionDetailsSheet(session),
    );
  }

  Widget _buildSessionDetailsSheet(TableSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          const SizedBox(height: 20),
          
          // Title
          Row(
            children: [
              Text(
                'Chi tiết phiên chơi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: session.status.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.status.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Session details
          _buildDetailRow('Bàn', session.tableName),
          if (session.customerName != null)
            _buildDetailRow('Khách hàng', session.customerName!),
          _buildDetailRow('Bắt đầu', _formatDateTime(session.startTime)),
          if (session.endTime != null)
            _buildDetailRow('Kết thúc', _formatDateTime(session.endTime!)),
          _buildDetailRow('Thời gian chơi', session.playingTimeFormatted),
          _buildDetailRow('Giá giờ', '${session.hourlyRate.toInt()}K/giờ'),
          _buildDetailRow('Tiền bàn', '${session.calculateTableAmount().toInt()}K'),
          _buildDetailRow('Tiền đồ ăn/uống', '${session.ordersAmount.toInt()}K'),
          _buildDetailRow('Tổng tiền', '${session.calculateTotalAmount().toInt()}K'),
          
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildDetailRow('Ghi chú', session.notes!),
          ],
          
          const SizedBox(height: 24),
          
          // Action buttons
          if (session.status == SessionStatus.active || session.status == SessionStatus.paused) ...[
            Row(
              children: [
                if (session.status == SessionStatus.active) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pauseSession(session.id);
                      },
                      icon: const Icon(Icons.pause),
                      label: const Text('Tạm dừng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (session.status == SessionStatus.paused) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _navigateToPayment(session);
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _endSession(session.id);
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Kết thúc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pauseSession(String sessionId) async {
    try {
      final sessionActions = ref.read(sessionActionsProvider);
      await sessionActions.pauseSession(sessionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tạm dừng phiên chơi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resumeSession(String sessionId) async {
    try {
      final sessionActions = ref.read(sessionActionsProvider);
      await sessionActions.resumeSession(sessionId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tiếp tục phiên chơi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _endSession(String sessionId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn kết thúc phiên chơi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kết thúc', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final sessionActions = ref.read(sessionActionsProvider);
        await sessionActions.endSession(sessionId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã kết thúc phiên chơi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Navigate to payment page for a session
  void _navigateToPayment(TableSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          session: session,
        ),
      ),
    );
  }
}
