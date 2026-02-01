import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

/// Distributor Portal Screen - Mobile self-service portal
class DistributorPortalScreen extends ConsumerStatefulWidget {
  const DistributorPortalScreen({super.key});

  @override
  ConsumerState<DistributorPortalScreen> createState() =>
      _DistributorPortalScreenState();
}

class _DistributorPortalScreenState
    extends ConsumerState<DistributorPortalScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  // Portal data
  Map<String, dynamic>? _portal;
  List<Map<String, dynamic>> _priceLists = [];
  List<Map<String, dynamic>> _promotions = [];
  int _loyaltyPoints = 0;
  List<Map<String, dynamic>> _recentOrders = [];

  final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Get distributor's portal
      final portalResponse = await _supabase
          .from('distributor_portals')
          .select('*')
          .eq('distributor_id', userId)
          .single();

      _portal = portalResponse;
      _loyaltyPoints = _portal?['loyalty_points_balance'] ?? 0;

      // Get active price lists
      final priceListsResponse = await _supabase
          .from('distributor_price_lists')
          .select('*')
          .eq('is_active', true)
          .lte('valid_from', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(5);

      _priceLists = List<Map<String, dynamic>>.from(priceListsResponse);

      // Get active promotions
      final promotionsResponse = await _supabase
          .from('distributor_promotions')
          .select('*')
          .eq('is_active', true)
          .lte('valid_from', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(5);

      _promotions = List<Map<String, dynamic>>.from(promotionsResponse);

      // Get recent orders (assuming orders table integration)
      // This would link to your existing orders system
      _recentOrders = []; // Placeholder

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cổng thông tin NPP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Portal Info Card
                    _buildPortalInfoCard(),
                    const SizedBox(height: 16),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Loyalty Points
                    _buildLoyaltyCard(),
                    const SizedBox(height: 24),

                    // Active Promotions
                    _buildPromotionsSection(),
                    const SizedBox(height: 24),

                    // Price Lists
                    _buildPriceListsSection(),
                    const SizedBox(height: 24),

                    // Recent Orders
                    _buildRecentOrdersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPortalInfoCard() {
    if (_portal == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    (_portal!['distributor_code'] ?? 'NPP').substring(0, 1),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
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
                        _portal!['distributor_name'] ?? 'NPP',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mã: ${_portal!['distributor_code'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Hoạt động',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Tổng đơn',
                  '${_portal!['total_orders'] ?? 0}',
                  Icons.shopping_cart,
                ),
                _buildStatItem(
                  'Doanh số',
                  _currencyFormat.format(_portal!['total_orders_value'] ?? 0),
                  Icons.attach_money,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Đặt hàng nhanh',
            Icons.flash_on,
            Colors.orange,
            () => _navigateToQuickOrder(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Xem bảng giá',
            Icons.price_check,
            Colors.blue,
            () => _navigateToPriceLists(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard() {
    return Card(
      elevation: 2,
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.stars, color: Colors.purple[700], size: 48),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Điểm tích lũy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.purple[900],
                    ),
                  ),
                  Text(
                    '$_loyaltyPoints điểm',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[900],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // Show loyalty history
              },
              child: const Text('Xem chi tiết'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionsSection() {
    if (_promotions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khuyến mãi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _promotions.length,
            itemBuilder: (context, index) {
              final promo = _promotions[index];
              return _buildPromotionCard(promo);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promo) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      promo['promotion_name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                promo['description'] ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                'Giảm ${promo['discount_percentage'] ?? 0}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceListsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bảng giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _navigateToPriceLists,
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._priceLists.take(3).map((priceList) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.list_alt, color: Colors.blue[700]),
              title: Text(priceList['price_list_name'] ?? ''),
              subtitle: Text(
                'Mã: ${priceList['price_list_code'] ?? ''}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _viewPriceListDetails(priceList),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to orders list
              },
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentOrders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Chưa có đơn hàng nào'),
            ),
          )
        else
          ..._recentOrders.map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text('Đơn hàng #${order['order_number']}'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(
                    DateTime.parse(order['created_at']),
                  ),
                ),
                trailing: Text(
                  _currencyFormat.format(order['total_amount'] ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // View order details
                },
              ),
            );
          }).toList(),
      ],
    );
  }

  void _navigateToQuickOrder() {
    // Navigate to quick order screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng đặt hàng nhanh đang phát triển')),
    );
  }

  void _navigateToPriceLists() {
    // Navigate to price lists screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PriceListsScreen(),
      ),
    );
  }

  void _viewPriceListDetails(Map<String, dynamic> priceList) {
    // Show price list details
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              priceList['price_list_name'] ?? '',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Mã: ${priceList['price_list_code'] ?? ''}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToPriceLists();
              },
              child: const Text('Xem chi tiết'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Price Lists Screen - View all price lists
class PriceListsScreen extends StatelessWidget {
  const PriceListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng giá'),
      ),
      body: const Center(
        child: Text('Danh sách bảng giá đang phát triển'),
      ),
    );
  }
}
