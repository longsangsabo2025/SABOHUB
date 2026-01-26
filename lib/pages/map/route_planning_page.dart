import 'package:flutter/material.dart';

class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({super.key});

  @override
  State<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  final List<Map<String, dynamic>> routes = [
    {
      'id': 'T001',
      'name': 'Tuyến Quận 1 - Sáng',
      'type': 'Giao hàng',
      'status': 'active',
      'customers': 8,
      'distance': 12.5,
      'estimatedTime': 150,
      'currentLocation': 'Đường Lê Lợi',
      'progress': 0.45,
      'driver': 'Nguyễn Văn A',
    },
    {
      'id': 'T002',
      'name': 'Tuyến Tân Bình - Chiều',
      'type': 'Kinh doanh',
      'status': 'active',
      'customers': 12,
      'distance': 18.2,
      'estimatedTime': 195,
      'currentLocation': 'Đường Cộng Hòa',
      'progress': 0.25,
      'driver': 'Trần Thị B',
    },
    {
      'id': 'T003',
      'name': 'Tuyến Quận 7 - Toàn ngày',
      'type': 'Hỗn hợp',
      'status': 'planned',
      'customers': 15,
      'distance': 25.8,
      'estimatedTime': 300,
      'currentLocation': 'Chưa bắt đầu',
      'progress': 0.0,
      'driver': 'Lê Văn C',
    },
  ];

  String? selectedRouteId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuyến đường'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan', icon: Icon(Icons.dashboard)),
            Tab(text: 'Chi tiết', icon: Icon(Icons.route)),
            Tab(text: 'Tối ưu hóa', icon: Icon(Icons.insights)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateRouteDialog(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRouteDetailsTab(),
          _buildOptimizationTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      children: [
        // Quick Stats
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                'Đang hoạt động',
                _getStatusCount('active').toString(),
                Icons.directions_car,
                Colors.green,
              ),
              _buildStatCard(
                'Đã lên kế hoạch',
                _getStatusCount('planned').toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatCard(
                'Tổng tuyến',
                routes.length.toString(),
                Icons.route,
                Colors.blue,
              ),
            ],
          ),
        ),
        
        // Routes List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final isSelected = selectedRouteId == route['id'];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 2,
                color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              route['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusChip(route['status']),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Route Info
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.business,
                            route['type'],
                            Colors.purple,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.location_on,
                            '${route['customers']} điểm',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.straighten,
                            '${route['distance']} km',
                            Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Driver and Time
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            route['driver'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${(route['estimatedTime'] / 60).floor()}h ${route['estimatedTime'] % 60}m',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      
                      // Progress bar for active routes
                      if (route['status'] == 'active') ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${(route['progress'] * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: route['progress'],
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vị trí: ${route['currentLocation']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteDetailsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chi tiết tuyến đường',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn một tuyến để xem chi tiết',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tối ưu hóa tuyến đường',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Công cụ tối ưu hóa sẽ được triển khai',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Hoạt động';
        break;
      case 'planned':
        color = Colors.orange;
        text = 'Đã lên kế hoạch';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Hoàn thành';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getStatusCount(String status) {
    return routes.where((route) => route['status'] == status).length;
  }

  void _showCreateRouteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tạo tuyến mới'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Tên tuyến',
                  hintText: 'Nhập tên tuyến đường',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Loại tuyến',
                  hintText: 'Giao hàng / Kinh doanh',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Handle route creation
              },
              child: const Text('Tạo'),
            ),
          ],
        );
      },
    );
  }
}
