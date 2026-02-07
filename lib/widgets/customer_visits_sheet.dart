import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../business_types/distribution/models/odori_customer.dart';
// import 'sales_features_widgets.dart'; // Unused
// import 'sales_features_widgets_2.dart'; // Unused

final supabase = Supabase.instance.client;

/// Widget to display customer visit history
class CustomerVisitsSheet extends StatefulWidget {
  final OdoriCustomer customer;
  final VoidCallback? onChanged;

  const CustomerVisitsSheet({
    super.key,
    required this.customer,
    this.onChanged,
  });

  @override
  State<CustomerVisitsSheet> createState() => _CustomerVisitsSheetState();
}

class _CustomerVisitsSheetState extends State<CustomerVisitsSheet> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String? _error;

  // Statistics
  int _totalVisits = 0;
  int _visitsThisMonth = 0;
  DateTime? _lastVisitDate;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await supabase
          .from('customer_visits')
          .select('''
            id, visit_date, check_in_time, check_out_time,
            check_in_lat, check_in_lng, check_out_lat, check_out_lng,
            purpose, notes, photos, result, order_id,
            employee:employee_id(id, full_name),
            order:order_id(order_number, total)
          ''')
          .eq('customer_id', widget.customer.id)
          .order('visit_date', ascending: false)
          .order('check_in_time', ascending: false)
          .limit(100);

      final visits = List<Map<String, dynamic>>.from(response);

      // Calculate stats
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      int visitsThisMonth = 0;
      DateTime? lastVisit;

      for (final visit in visits) {
        final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
        if (visitDate != null) {
          if (lastVisit == null || visitDate.isAfter(lastVisit)) {
            lastVisit = visitDate;
          }
          if (visitDate.isAfter(thisMonthStart)) {
            visitsThisMonth++;
          }
        }
      }

      setState(() {
        _visits = visits;
        _totalVisits = visits.length;
        _visitsThisMonth = visitsThisMonth;
        _lastVisitDate = lastVisit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showVisitDetail(Map<String, dynamic> visit) {
    showDialog(
      context: context,
      builder: (context) => VisitDetailDialog(visit: visit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.place, color: Colors.indigo.shade600, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lịch sử viếng thăm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.customer.name,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                // Stats
                if (!_isLoading && _error == null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Tổng lượt', '$_totalVisits', Colors.indigo, Icons.directions_walk)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Tháng này', '$_visitsThisMonth', Colors.teal, Icons.calendar_month)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Lần cuối',
                          _lastVisitDate != null ? DateFormat('dd/MM').format(_lastVisitDate!) : 'N/A',
                          Colors.orange,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
                              const SizedBox(height: 8),
                              Text('Lỗi: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _loadVisits, child: const Text('Thử lại')),
                            ],
                          ),
                        ),
                      )
                    : _visits.isEmpty
                        ? _buildEmptyState()
                        : _buildVisitsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lượt viếng thăm nào',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Lịch sử check-in sẽ hiển thị ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsList() {
    // Group visits by month
    final groupedVisits = <String, List<Map<String, dynamic>>>{};
    for (final visit in _visits) {
      final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
      final monthKey = visitDate != null 
          ? DateFormat('MM/yyyy').format(visitDate)
          : 'Không xác định';
      groupedVisits.putIfAbsent(monthKey, () => []).add(visit);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedVisits.length,
      itemBuilder: (context, index) {
        final monthKey = groupedVisits.keys.elementAt(index);
        final monthVisits = groupedVisits[monthKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tháng $monthKey',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${monthVisits.length} lượt',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ...monthVisits.map((visit) => _buildVisitCard(visit)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
    final checkIn = DateTime.tryParse(visit['check_in_time']?.toString() ?? '');
    final checkOut = DateTime.tryParse(visit['check_out_time']?.toString() ?? '');
    final purpose = visit['purpose'] as String?;
    final result = visit['result'] as String?;
    final employee = visit['employee'] as Map<String, dynamic>?;
    final order = visit['order'] as Map<String, dynamic>?;
    final photos = visit['photos'] as List?;

    // Calculate duration
    String? duration;
    if (checkIn != null && checkOut != null) {
      final diff = checkOut.difference(checkIn);
      if (diff.inHours > 0) {
        duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
      } else {
        duration = '${diff.inMinutes}m';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showVisitDetail(visit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getResultColor(result).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getResultIcon(result),
                      color: _getResultColor(result),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (visitDate != null)
                              Text(
                                DateFormat('dd/MM/yyyy').format(visitDate),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            if (checkIn != null) ...[
                              Text(
                                ' • ${DateFormat('HH:mm').format(checkIn)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                            if (duration != null) ...[
                              Text(
                                ' ($duration)',
                                style: TextStyle(color: Colors.indigo.shade600, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                        if (employee != null)
                          Text(
                            employee['full_name'] ?? 'Nhân viên',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  if (photos != null && photos.isNotEmpty)
                    Badge(
                      label: Text('${photos.length}'),
                      child: Icon(Icons.photo_camera, color: Colors.grey.shade400, size: 20),
                    ),
                ],
              ),
              if (purpose != null || result != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (purpose != null)
                      _buildTag(_getPurposeText(purpose), Colors.blue),
                    if (result != null)
                      _buildTag(_getResultText(result), _getResultColor(result)),
                  ],
                ),
              ],
              if (order != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Đơn: ${order['order_number']}',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                      ),
                      if (order['total'] != null) ...[
                        const Text(' • '),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(order['total']),
                          style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  visit['notes'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  String _getPurposeText(String? purpose) {
    switch (purpose) {
      case 'sales': return 'Bán hàng';
      case 'collect': return 'Thu tiền';
      case 'survey': return 'Khảo sát';
      case 'delivery': return 'Giao hàng';
      case 'support': return 'Hỗ trợ';
      case 'introduction': return 'Giới thiệu SP';
      default: return purpose ?? 'Khác';
    }
  }

  String _getResultText(String? result) {
    switch (result) {
      case 'ordered': return 'Đặt hàng';
      case 'no_order': return 'Không đặt';
      case 'closed': return 'Đóng cửa';
      case 'not_available': return 'Không gặp';
      case 'collected': return 'Đã thu tiền';
      case 'pending': return 'Đang xử lý';
      default: return result ?? 'N/A';
    }
  }

  Color _getResultColor(String? result) {
    switch (result) {
      case 'ordered':
      case 'collected':
        return Colors.green;
      case 'no_order':
      case 'not_available':
        return Colors.orange;
      case 'closed':
        return Colors.red;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getResultIcon(String? result) {
    switch (result) {
      case 'ordered': return Icons.shopping_cart;
      case 'collected': return Icons.payments;
      case 'no_order': return Icons.remove_shopping_cart;
      case 'closed': return Icons.store_outlined;
      case 'not_available': return Icons.person_off;
      case 'pending': return Icons.hourglass_empty;
      default: return Icons.place;
    }
  }
}

/// Dialog to show visit details
class VisitDetailDialog extends StatelessWidget {
  final Map<String, dynamic> visit;

  const VisitDetailDialog({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    final visitDate = DateTime.tryParse(visit['visit_date']?.toString() ?? '');
    final checkIn = DateTime.tryParse(visit['check_in_time']?.toString() ?? '');
    final checkOut = DateTime.tryParse(visit['check_out_time']?.toString() ?? '');
    final employee = visit['employee'] as Map<String, dynamic>?;
    final photos = visit['photos'] as List?;
    final checkInLat = visit['check_in_lat'];
    final checkInLng = visit['check_in_lng'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, color: Colors.indigo.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      visitDate != null ? DateFormat('dd/MM/yyyy').format(visitDate) : 'Chi tiết viếng thăm',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee
                    if (employee != null)
                      _buildInfoRow(Icons.person, 'Nhân viên', employee['full_name'] ?? 'N/A'),

                    // Time
                    if (checkIn != null)
                      _buildInfoRow(Icons.login, 'Check-in', DateFormat('HH:mm:ss').format(checkIn)),
                    if (checkOut != null)
                      _buildInfoRow(Icons.logout, 'Check-out', DateFormat('HH:mm:ss').format(checkOut)),

                    // Purpose & Result
                    if (visit['purpose'] != null)
                      _buildInfoRow(Icons.flag, 'Mục đích', _getPurposeText(visit['purpose'])),
                    if (visit['result'] != null)
                      _buildInfoRow(Icons.check_circle, 'Kết quả', _getResultText(visit['result'])),

                    // Notes
                    if (visit['notes'] != null && (visit['notes'] as String).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Ghi chú:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(visit['notes']),
                      ),
                    ],

                    // Location
                    if (checkInLat != null && checkInLng != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openMap(checkInLat, checkInLng),
                          icon: const Icon(Icons.map),
                          label: const Text('Xem vị trí trên bản đồ'),
                        ),
                      ),
                    ],

                    // Photos
                    if (photos != null && photos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Hình ảnh (${photos.length}):', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final photoUrl = photos[index] as String?;
                            if (photoUrl == null) return const SizedBox();
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                photoUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _openMap(num lat, num lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _getPurposeText(String? purpose) {
    switch (purpose) {
      case 'sales': return 'Bán hàng';
      case 'collect': return 'Thu tiền';
      case 'survey': return 'Khảo sát';
      case 'delivery': return 'Giao hàng';
      case 'support': return 'Hỗ trợ';
      case 'introduction': return 'Giới thiệu SP';
      default: return purpose ?? 'Khác';
    }
  }

  String _getResultText(String? result) {
    switch (result) {
      case 'ordered': return 'Đặt hàng';
      case 'no_order': return 'Không đặt';
      case 'closed': return 'Đóng cửa';
      case 'not_available': return 'Không gặp';
      case 'collected': return 'Đã thu tiền';
      case 'pending': return 'Đang xử lý';
      default: return result ?? 'N/A';
    }
  }
}
