import 'package:flutter/material.dart';
import '../../widgets/map/route_tracking_map_widget.dart';
import '../../widgets/map/delivery_status_card.dart';

class DeliveryTrackingPage extends StatefulWidget {
  const DeliveryTrackingPage({super.key});

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  final List<Map<String, dynamic>> deliveries = [
    {
      'id': 'DH001',
      'customerName': 'Công ty ABC',
      'address': '123 Nguyễn Huệ, Q1, TP.HCM',
      'status': 'delivering',
      'driverName': 'Nguyễn Văn A',
      'estimatedTime': '15 phút',
      'progress': 0.7,
    },
    {
      'id': 'DH002',
      'customerName': 'Cửa hàng XYZ',
      'address': '456 Lê Lợi, Q3, TP.HCM',
      'status': 'completed',
      'driverName': 'Trần Văn B',
      'estimatedTime': 'Hoàn thành',
      'progress': 1.0,
    },
    {
      'id': 'DH003',
      'customerName': 'Siêu thị DEF',
      'address': '789 Cộng Hòa, Tân Bình, TP.HCM',
      'status': 'pending',
      'driverName': 'Lê Văn C',
      'estimatedTime': '30 phút',
      'progress': 0.0,
    },
  ];

  String? selectedDeliveryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi giao hàng'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh delivery data
              setState(() {});
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
                _buildStatusChip('Đang giao', _getStatusCount('delivering'), Colors.blue),
                _buildStatusChip('Hoàn thành', _getStatusCount('completed'), Colors.green),
                _buildStatusChip('Chờ giao', _getStatusCount('pending'), Colors.orange),
              ],
            ),
          ),
          
          // Delivery List
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: deliveries.length,
              itemBuilder: (context, index) {
                final delivery = deliveries[index];
                final isSelected = selectedDeliveryId == delivery['id'];
                
                return DeliveryStatusCard(
                  deliveryId: delivery['id'],
                  customerName: delivery['customerName'],
                  address: delivery['address'],
                  status: delivery['status'],
                  driverName: delivery['driverName'],
                  estimatedTime: delivery['estimatedTime'],
                  progress: delivery['progress'],
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      selectedDeliveryId = isSelected ? null : delivery['id'];
                    });
                  },
                );
              },
            ),
          ),
          
          // Map Widget - only show when a delivery is selected
          if (selectedDeliveryId != null)
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RouteTrackingMapWidget(
                    stops: const [], // Will be populated from selected delivery
                    showRouteLine: true,
                    autoTrack: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _getStatusCount(String status) {
    return deliveries.where((d) => d['status'] == status).length;
  }
}
