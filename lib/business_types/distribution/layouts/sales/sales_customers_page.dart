import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/customer_avatar.dart';
import '../../widgets/sales_features_widgets.dart';
import 'sheets/sales_customer_form_sheet.dart';
import 'sheets/sales_create_order_form.dart';
import 'sheets/sales_order_history_sheet.dart';

/// Customers Page - Simple internal page for sales role
class SalesCustomersPage extends ConsumerStatefulWidget {
  const SalesCustomersPage({super.key});

  @override
  ConsumerState<SalesCustomersPage> createState() => _SalesCustomersPageState();
}

class _SalesCustomersPageState extends ConsumerState<SalesCustomersPage> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  
  String _statusFilter = 'active';
  bool _showArchived = false;
  int _archivedCount = 0;
  
  String? _tierFilter;
  
  int _totalCustomers = 0;
  int _newThisMonth = 0;
  Map<String, int> _tierStats = {'diamond': 0, 'gold': 0, 'silver': 0, 'bronze': 0};

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

      final archivedData = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'inactive');
      _archivedCount = (archivedData as List).length;

      final allActive = await supabase
          .from('customers')
          .select('id, tier, created_at')
          .eq('company_id', companyId)
          .neq('status', 'inactive');
      _totalCustomers = (allActive as List).length;
      
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      _newThisMonth = allActive.where((c) {
        final createdAt = DateTime.tryParse(c['created_at']?.toString() ?? '');
        return createdAt != null && createdAt.isAfter(startOfMonth);
      }).length;
      
      _tierStats = {'diamond': 0, 'gold': 0, 'silver': 0, 'bronze': 0};
      for (var c in allActive) {
        final tier = c['tier']?.toString() ?? 'bronze';
        if (_tierStats.containsKey(tier)) {
          _tierStats[tier] = (_tierStats[tier] ?? 0) + 1;
        }
      }

      var query = supabase
          .from('customers')
          .select('*, referrers(id, name)')
          .eq('company_id', companyId);
          
      if (_showArchived) {
        query = query.eq('status', 'archived');
      } else {
        query = query.eq('status', _statusFilter);
      }
      
      if (_tierFilter != null) {
        query = query.eq('tier', _tierFilter!);
      }
      
      final data = await query.order('name');

      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers', e);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((c) {
      final name = (c['name'] ?? '').toLowerCase();
      final phone = (c['phone'] ?? '').toLowerCase();
      final code = (c['code'] ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query) || code.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCustomerDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Thêm KH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        _showArchived ? 'Lưu trữ' : 'Khách hàng',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (_archivedCount > 0)
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _showArchived = !_showArchived);
                            _loadCustomers();
                          },
                          icon: Icon(
                            _showArchived ? Icons.people : Icons.archive,
                            size: 16,
                            color: _showArchived ? Colors.indigo : Colors.orange.shade700,
                          ),
                          label: Text(
                            _showArchived ? 'DS KH' : 'LT ($_archivedCount)',
                            style: TextStyle(
                              color: _showArchived ? Colors.indigo : Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('${_filteredCustomers.length}', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  
                  if (!_showArchived) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Status filter popup
                        _buildCompactPopup<String>(
                          icon: Icons.circle,
                          label: _statusFilter == 'active' ? 'Hoạt động' : _statusFilter == 'inactive' ? 'Ngưng HĐ' : _statusFilter == 'blocked' ? 'Khóa' : 'Trạng thái',
                          isActive: true,
                          activeColor: _statusFilter == 'active' ? Colors.green : _statusFilter == 'inactive' ? Colors.grey.shade600 : _statusFilter == 'blocked' ? Colors.red : Colors.indigo,
                          items: [
                            PopupMenuItem(value: 'active', child: Text('✅ Hoạt động', style: TextStyle(fontWeight: _statusFilter == 'active' ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'inactive', child: Text('⏸ Ngưng HĐ', style: TextStyle(fontWeight: _statusFilter == 'inactive' ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'blocked', child: Text('🚫 Khóa', style: TextStyle(fontWeight: _statusFilter == 'blocked' ? FontWeight.bold : FontWeight.normal))),
                          ],
                          onSelected: (value) {
                            setState(() => _statusFilter = value);
                            _loadCustomers();
                          },
                        ),
                        const SizedBox(width: 6),
                        // Tier filter popup
                        _buildCompactPopup<String>(
                          icon: Icons.diamond_outlined,
                          label: _tierFilter == null ? 'Hạng' : _tierFilter == 'diamond' ? '💎' : _tierFilter == 'gold' ? '🥇' : _tierFilter == 'silver' ? '🥈' : '🥉',
                          isActive: _tierFilter != null,
                          activeColor: _tierFilter == 'diamond' ? Colors.cyan : _tierFilter == 'gold' ? Colors.amber.shade700 : _tierFilter == 'silver' ? Colors.grey.shade600 : _tierFilter == 'bronze' ? Colors.brown : Colors.indigo,
                          items: [
                            PopupMenuItem(value: '__all__', child: Text('👥 Tất cả (${_tierStats.values.fold(0, (a, b) => a + b)})', style: TextStyle(fontWeight: _tierFilter == null ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'diamond', child: Text('💎 Diamond (${_tierStats['diamond'] ?? 0})', style: TextStyle(fontWeight: _tierFilter == 'diamond' ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'gold', child: Text('🥇 Gold (${_tierStats['gold'] ?? 0})', style: TextStyle(fontWeight: _tierFilter == 'gold' ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'silver', child: Text('🥈 Silver (${_tierStats['silver'] ?? 0})', style: TextStyle(fontWeight: _tierFilter == 'silver' ? FontWeight.bold : FontWeight.normal))),
                            PopupMenuItem(value: 'bronze', child: Text('🥉 Bronze (${_tierStats['bronze'] ?? 0})', style: TextStyle(fontWeight: _tierFilter == 'bronze' ? FontWeight.bold : FontWeight.normal))),
                          ],
                          onSelected: (value) {
                            setState(() => _tierFilter = value == '__all__' ? null : value);
                            _loadCustomers();
                          },
                        ),
                        const Spacer(),
                        // Mini stats
                        Text('$_totalCustomers KH', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        if (_newThisMonth > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text('+$_newThisMonth', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm khách hàng...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Customer list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Không tìm thấy khách hàng', style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomerDialog,
                                icon: const Icon(Icons.person_add),
                                label: const Text('Thêm khách hàng mới'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadCustomers,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = _filteredCustomers[index];
                              return _buildCustomerCard(customer);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SalesCustomerFormSheet(
          onSaved: () {
            _loadCustomers();
          },
        ),
      ),
    );
  }

  void _showEditCustomerDialog(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SalesCustomerFormSheet(
          customer: customer,
          onSaved: () {
            _loadCustomers();
          },
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final name = customer['name'] ?? 'N/A';
    final phone = customer['phone'] ?? '';
    final district = customer['district'] ?? '';
    final channel = customer['channel'] as String?;
    final status = customer['status'] ?? 'active';
    final creditLimit = (customer['credit_limit'] ?? 0).toDouble();
    final totalDebt = (customer['total_debt'] ?? 0).toDouble();
    final paymentTerms = customer['payment_terms'] ?? 0;
    final tier = customer['tier'] as String? ?? 'bronze';
    final referrer = customer['referrers'] as Map<String, dynamic>?;
    final lastOrderDate = customer['last_order_date'] != null 
        ? DateTime.tryParse(customer['last_order_date'].toString()) 
        : null;
    
    final lastOrderColor = _getLastOrderColor(lastOrderDate);
    final isVIP = creditLimit > 10000000;
    final hasDebt = totalDebt > 0;
    
    String tierEmoji = '🥉';
    Color tierColor = Colors.brown;
    if (tier == 'diamond') { tierEmoji = '💎'; tierColor = Colors.cyan; }
    else if (tier == 'gold') { tierEmoji = '🥇'; tierColor = Colors.amber.shade700; }
    else if (tier == 'silver') { tierEmoji = '🥈'; tierColor = Colors.grey.shade600; }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCustomerActions(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CustomerAvatar(
                        seed: name,
                        radius: 22,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)],
                          ),
                          child: Text(tierEmoji, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isVIP) 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (channel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getChannelColor(channel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  channel,
                                  style: TextStyle(fontSize: 10, color: _getChannelColor(channel)),
                                ),
                              ),
                            if (district.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  district,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (referrer != null && referrer['name'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.people_alt_outlined, size: 12, color: Colors.purple.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'GT: ${referrer['name']}',
                                  style: TextStyle(fontSize: 10, color: Colors.purple.shade400, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      color: Colors.green,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: () => _callCustomer(phone),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    color: Colors.blue,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () => _createOrderForCustomer(customer),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Colors.grey.shade200),
              ),
              
              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _buildKPIItem(
                      '📅',
                      _formatLastOrder(lastOrderDate),
                      'Lần mua',
                      lastOrderColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '💳',
                      creditLimit > 0 
                          ? NumberFormat.compact(locale: 'vi').format(creditLimit)
                          : '0',
                      'Hạn mức',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '⏱️',
                      '$paymentTerms',
                      'Ngày TT',
                      Colors.purple,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      status == 'active' ? '✅' : '⛔',
                      status == 'active' ? 'Hoạt động' : 'Ngưng',
                      'Trạng thái',
                      status == 'active' ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              
              if (hasDebt || creditLimit > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CustomerDebtBadge(
                    totalDebt: totalDebt,
                    creditLimit: creditLimit,
                    onPaymentTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tính năng thanh toán đang phát triển')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIItem(String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildCompactPopup<T>({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required List<PopupMenuEntry<T>> items,
    required void Function(T) onSelected,
  }) {
    final color = isActive ? activeColor : Colors.grey.shade600;
    return PopupMenuButton<T>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Color _getChannelColor(String? channel) {
    switch (channel) {
      case 'Horeca': return Colors.purple;
      case 'GT Sỉ': return Colors.blue;
      case 'GT Lẻ': return Colors.green;
      default: return Colors.indigo;
    }
  }

  Color _getLastOrderColor(DateTime? lastOrderDate) {
    if (lastOrderDate == null) return Colors.grey;
    final days = DateTime.now().difference(lastOrderDate).inDays;
    if (days <= 7) return Colors.green;
    if (days <= 14) return Colors.orange;
    return Colors.red;
  }

  String _formatLastOrder(DateTime? date) {
    if (date == null) return 'Chưa mua';
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Hôm nay';
    if (days == 1) return 'Hôm qua';
    if (days < 7) return '$days ngày';
    if (days < 30) return '${days ~/ 7} tuần';
    return '${days ~/ 30} tháng';
  }

  void _showCustomerActions(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              customer['name'] ?? 'Khách hàng',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (customer['status'] != 'archived')
              _buildActionTile(Icons.shopping_cart, 'Tạo đơn hàng', Colors.blue, () {
                Navigator.pop(context);
                _createOrderForCustomer(customer);
              }),
            if ((customer['phone'] ?? '').toString().isNotEmpty)
              _buildActionTile(Icons.phone, 'Gọi điện', Colors.green, () {
                Navigator.pop(context);
                _callCustomer(customer['phone']);
              }),
            _buildActionTile(Icons.history, 'Lịch sử mua hàng', Colors.orange, () {
              Navigator.pop(context);
              _showOrderHistory(customer);
            }),
            _buildActionTile(Icons.edit, 'Chỉnh sửa', Colors.purple, () {
              Navigator.pop(context);
              _showEditCustomerDialog(customer);
            }),
            if (customer['status'] == 'archived')
              _buildActionTile(Icons.unarchive, 'Khôi phục', Colors.teal, () {
                Navigator.pop(context);
                _toggleArchiveCustomer(customer, false);
              })
            else
              _buildActionTile(Icons.archive, 'Lưu trữ', Colors.orange.shade700, () {
                Navigator.pop(context);
                _toggleArchiveCustomer(customer, true);
              }),
            _buildActionTile(Icons.delete_forever, 'Xóa vĩnh viễn', Colors.red, () {
              Navigator.pop(context);
              _confirmDeleteCustomer(customer);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _callCustomer(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể gọi số: $phone'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gọi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _createOrderForCustomer(Map<String, dynamic> customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SalesCreateOrderFormPage(preselectedCustomer: customer),
      ),
    );
  }

  Future<void> _toggleArchiveCustomer(Map<String, dynamic> customer, bool archive) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('customers')
          .update({'status': archive ? 'inactive' : 'active'})
          .eq('id', customer['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(archive 
                ? 'Đã lưu trữ khách hàng ${customer['name']}'
                : 'Đã khôi phục khách hàng ${customer['name']}'),
            backgroundColor: archive ? Colors.orange : Colors.green,
          ),
        );
        _loadCustomers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmDeleteCustomer(Map<String, dynamic> customer) {
    final isArchived = customer['status'] == 'archived';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Xác nhận xóa')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn xóa khách hàng "${customer['name']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác!',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            if (!isArchived) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Gợi ý: Bạn có thể lưu trữ khách hàng thay vì xóa.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!isArchived)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _toggleArchiveCustomer(customer, true);
              },
              icon: const Icon(Icons.archive, size: 18),
              label: const Text('Lưu trữ'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange.shade700),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final supabase = Supabase.instance.client;
                await supabase.from('customers').delete().eq('id', customer['id']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa khách hàng ${customer['name']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCustomers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showOrderHistory(Map<String, dynamic> customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SalesOrderHistorySheet(
            customer: customer,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}
