import 'package:flutter/material.dart';
import '../../widgets/map/sabo_map_widget.dart';

class StaffTrackingPage extends StatefulWidget {
  const StaffTrackingPage({super.key});

  @override
  State<StaffTrackingPage> createState() => _StaffTrackingPageState();
}

class _StaffTrackingPageState extends State<StaffTrackingPage> {
  final List<Map<String, dynamic>> staffList = [
    {
      'id': 'NV001',
      'name': 'Nguyễn Văn A',
      'role': 'Tài xế giao hàng',
      'status': 'active',
      'location': 'Đường Lê Lợi, Q1',
      'lastUpdate': '2 phút trước',
      'batteryLevel': 85,
    },
    {
      'id': 'NV002',
      'name': 'Trần Thị B',
      'role': 'Nhân viên kinh doanh',
      'status': 'active',
      'location': 'Đường Cộng Hòa, Tân Bình',
      'lastUpdate': '1 phút trước',
      'batteryLevel': 92,
    },
    {
      'id': 'NV003',
      'name': 'Lê Văn C',
      'role': 'Tài xế giao hàng',
      'status': 'offline',
      'location': 'Không xác định',
      'lastUpdate': '15 phút trước',
      'batteryLevel': 25,
    },
  ];

  String? selectedStaffId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi nhân viên'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Summary
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusCard(
                  'Online',
                  _getStatusCount('active').toString(),
                  Icons.circle,
                  Colors.green,
                ),
                _buildStatusCard(
                  'Offline',
                  _getStatusCount('offline').toString(),
                  Icons.circle,
                  Colors.grey,
                ),
                _buildStatusCard(
                  'Tổng số',
                  staffList.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ],
            ),
          ),
          
          // Staff List
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final isSelected = selectedStaffId == staff['id'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: isSelected ? 4 : 1,
                  color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(staff['status']),
                      child: Text(
                        staff['name'][0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      staff['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff['role']),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                staff['location'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.battery_full,
                              size: 16,
                              color: _getBatteryColor(staff['batteryLevel']),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${staff['batteryLevel']}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          staff['lastUpdate'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        selectedStaffId = isSelected ? null : staff['id'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          // Map Widget
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const SaboMapWidget(
                  showCurrentLocation: true,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh staff positions
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đang cập nhật vị trí...')),
          );
        },
        tooltip: 'Làm mới vị trí',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, IconData icon, Color color) {
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
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'offline':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  int _getStatusCount(String status) {
    return staffList.where((staff) => staff['status'] == status).length;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bộ lọc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Chỉ hiển thị online'),
                value: false,
                onChanged: (bool? value) {
                  // Handle filter logic
                },
              ),
              CheckboxListTile(
                title: const Text('Pin thấp'),
                value: false,
                onChanged: (bool? value) {
                  // Handle filter logic
                },
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
                // Apply filters
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );
  }
}
