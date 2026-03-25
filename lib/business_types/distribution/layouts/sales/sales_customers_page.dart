import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../providers/auth_provider.dart';
import '../../../../utils/app_logger.dart';
import '../../../../widgets/customer_avatar.dart';
import '../../../../widgets/customer_visits_sheet.dart';
import '../../../../utils/postgrest_sanitizer.dart';
import '../../models/odori_customer.dart';
import '../../pages/products/product_samples_page.dart';
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 30;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  bool _collapseHero = false;
  
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
    _scrollController.addListener(_onScroll);
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final shouldCollapse = _scrollController.offset > 64;
      if (shouldCollapse != _collapseHero) {
        setState(() => _collapseHero = shouldCollapse);
      }
    }

    if (!_scrollController.hasClients || _isLoading || _isLoadingMore || !_hasMore) {
      return;
    }
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 220) {
      _loadMoreCustomers();
    }
  }

  Future<void> _loadCustomers({bool reset = true, bool reloadStats = true}) async {
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;

      if (companyId == null) return;

      final supabase = Supabase.instance.client;

      if (reloadStats) {
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
      }

      if (reset) {
        _currentOffset = 0;
        _hasMore = true;
        setState(() {
          _isLoading = true;
          _customers = [];
        });
      }

      var query = supabase
          .from('customers')
          .select('*, referrers(id, name)')
          .eq('company_id', companyId);
          
      if (_showArchived) {
        query = query.eq('status', 'inactive');
      } else {
        query = query.eq('status', _statusFilter);
      }
      
      if (_tierFilter != null) {
        query = query.eq('tier', _tierFilter!);
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        final sanitized = PostgrestSanitizer.sanitizeSearch(search);
        query = query.or('name.ilike.%$sanitized%,phone.ilike.%$sanitized%,code.ilike.%$sanitized%');
      }
      
      final data = await query
          .order('name')
          .range(_currentOffset, _currentOffset + _pageSize - 1);

      final rows = List<Map<String, dynamic>>.from(data);

      setState(() {
        _customers = rows;
        _currentOffset = rows.length;
        _hasMore = rows.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load customers', e);
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreCustomers() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId;
      if (companyId == null) {
        setState(() => _isLoadingMore = false);
        return;
      }

      final supabase = Supabase.instance.client;
      var query = supabase
          .from('customers')
          .select('*, referrers(id, name)')
          .eq('company_id', companyId);

      if (_showArchived) {
        query = query.eq('status', 'inactive');
      } else {
        query = query.eq('status', _statusFilter);
      }

      if (_tierFilter != null) {
        query = query.eq('tier', _tierFilter!);
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        final sanitized = PostgrestSanitizer.sanitizeSearch(search);
        query = query.or('name.ilike.%$sanitized%,phone.ilike.%$sanitized%,code.ilike.%$sanitized%');
      }

      final data = await query
          .order('name')
          .range(_currentOffset, _currentOffset + _pageSize - 1);

      final rows = List<Map<String, dynamic>>.from(data);
      setState(() {
        _customers.addAll(rows);
        _currentOffset += rows.length;
        _hasMore = rows.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load more customers', e);
      setState(() => _isLoadingMore = false);
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _loadCustomers(reset: true, reloadStats: false);
    });
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    return _customers;
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool outlined = false,
  }) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(outlined ? 0.45 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }

  Widget _buildMiniStatCard(String value, String label, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: tint.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tint.withOpacity(0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final salesName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Nhân viên sale';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _collapseHero ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade700,
                            Colors.blue.shade600,
                            Colors.teal.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.groups_2, color: Colors.white, size: 14),
                                          SizedBox(width: 6),
                                          Text(
                                            'Sales Customer Hub',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      _showArchived ? 'Kho lưu trữ khách hàng' : 'Khách hàng của tôi',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        height: 1.05,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _showArchived
                                          ? 'Xem lại khách đã ngưng hoạt động, khôi phục nhanh hoặc kiểm tra lịch sử trước khi xử lý.'
                                          : 'Quản lý tệp khách hàng, theo dõi hạng, nợ và tạo đơn nhanh cho $salesName.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildHeaderChip(
                                icon: Icons.person,
                                label: salesName,
                                color: Colors.white,
                                outlined: true,
                              ),
                              _buildHeaderChip(
                                icon: Icons.inventory_2_outlined,
                                label: '${_filteredCustomers.length} khách đang hiển thị',
                                color: Colors.white,
                                outlined: true,
                              ),
                              if (_archivedCount > 0)
                                _buildHeaderChip(
                                  icon: _showArchived ? Icons.people : Icons.archive_outlined,
                                  label: _showArchived ? 'Về danh sách chính' : 'Lưu trữ ($_archivedCount)',
                                  color: Colors.white,
                                  outlined: true,
                                  onTap: () {
                                    setState(() => _showArchived = !_showArchived);
                                    _loadCustomers();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStatCard(
                                  '$_totalCustomers',
                                  'Tổng khách',
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMiniStatCard(
                                  '+$_newThisMonth',
                                  'Khách mới tháng',
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMiniStatCard(
                                  _tierFilter == null ? '4 hạng' : _tierFilter!.toUpperCase(),
                                  'Trạng thái lọc',
                                  Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _showAddCustomerDialog,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Thêm khách hàng'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo.shade800,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade700,
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_filteredCustomers.length} khách hàng',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showAddCustomerDialog,
                            icon: const Icon(Icons.person_add_alt_1, size: 16),
                            label: const Text('Thêm'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm khách hàng, mã KH, số điện thoại...',
                                    hintStyle: TextStyle(color: Colors.grey.shade500),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                            onPressed: () {
                                              _searchController.clear();
                                              _loadCustomers(reset: true, reloadStats: false);
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_showArchived) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildCompactPopup<String>(
                                icon: Icons.circle,
                                label: _statusFilter == 'active'
                                    ? 'Hoạt động'
                                    : _statusFilter == 'inactive'
                                        ? 'Ngưng HĐ'
                                        : _statusFilter == 'blocked'
                                            ? 'Khóa'
                                            : 'Trạng thái',
                                isActive: true,
                                activeColor: _statusFilter == 'active'
                                    ? Colors.green
                                    : _statusFilter == 'inactive'
                                        ? Colors.grey.shade600
                                        : _statusFilter == 'blocked'
                                            ? Colors.red
                                            : Colors.indigo,
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
                              const SizedBox(width: 8),
                              _buildCompactPopup<String>(
                                icon: Icons.diamond_outlined,
                                label: _tierFilter == null
                                    ? 'Hạng KH'
                                    : _tierFilter == 'diamond'
                                        ? '💎 Diamond'
                                        : _tierFilter == 'gold'
                                            ? '🥇 Gold'
                                            : _tierFilter == 'silver'
                                                ? '🥈 Silver'
                                                : '🥉 Bronze',
                                isActive: _tierFilter != null,
                                activeColor: _tierFilter == 'diamond'
                                    ? Colors.cyan
                                    : _tierFilter == 'gold'
                                        ? Colors.amber.shade700
                                        : _tierFilter == 'silver'
                                            ? Colors.grey.shade600
                                            : _tierFilter == 'bronze'
                                                ? Colors.brown
                                                : Colors.indigo,
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
                              Text(
                                '${_filteredCustomers.length} kết quả',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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
                                label: Text('Thêm khách hàng mới'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadCustomers(reset: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _filteredCustomers.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= _filteredCustomers.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
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
    if (tier == 'diamond') { tierEmoji = '💎'; }
    else if (tier == 'gold') { tierEmoji = '🥇'; }
    else if (tier == 'silver') { tierEmoji = '🥈'; }

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
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), blurRadius: 2)],
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
            _buildActionTile(Icons.location_on, 'Lịch sử ghé thăm', Colors.teal, () {
              Navigator.pop(context);
              _showVisitHistory(customer);
            }),
            _buildActionTile(Icons.card_giftcard, 'Mẫu sản phẩm', Colors.pink, () {
              Navigator.pop(context);
              _showProductSamples(customer);
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
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              try {
                final supabase = Supabase.instance.client;
                await supabase.from('customers').update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', customer['id']);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa khách hàng ${customer['name']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadCustomers();
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
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

  void _showVisitHistory(Map<String, dynamic> customer) {
    final odoriCustomer = OdoriCustomer.fromJson(customer);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomerVisitsSheet(
            customer: odoriCustomer,
            onChanged: () => _loadCustomers(),
          ),
        ),
      ),
    );
  }

  void _showProductSamples(Map<String, dynamic> customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductSamplesPage(
          initialCustomerId: customer['id']?.toString(),
          initialCustomerName: customer['name']?.toString(),
        ),
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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

