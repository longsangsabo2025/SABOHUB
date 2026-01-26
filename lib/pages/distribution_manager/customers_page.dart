// Extracted from distribution_manager_layout.dart
// Customers Management Page with search, filters, statistics, and CRUD operations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/odori_customer.dart';
import '../../providers/auth_provider.dart';
import '../orders/order_form_page.dart';

final supabase = Supabase.instance.client;

// ==================== CUSTOMERS PAGE (ENHANCED) ====================
class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _searchQuery = '';
  String? _selectedChannel;
  String? _selectedStatus;
  String _sortBy = 'last_order_date';
  bool _sortAscending = false;
  final List<OdoriCustomer> _allCustomers = [];
  int _currentOffset = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  final ScrollController _scrollController = ScrollController();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
  
  // Statistics
  int _totalCustomers = 0;
  int _activeCustomers = 0;
  int _newCustomersThisMonth = 0;
  double _totalCreditLimit = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStatistics();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final totalResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId);
      
      final activeResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'active');
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final newResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .gte('created_at', startOfMonth.toIso8601String());
      
      final creditResponse = await supabase
          .from('customers')
          .select('credit_limit')
          .eq('company_id', companyId);
      
      double totalCredit = 0;
      for (var c in (creditResponse as List)) {
        totalCredit += (c['credit_limit'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _totalCustomers = (totalResponse as List).length;
          _activeCustomers = (activeResponse as List).length;
          _newCustomersThisMonth = (newResponse as List).length;
          _totalCreditLimit = totalCredit;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _allCustomers.clear();
      _currentOffset = 0;
      _hasMore = true;
    });

    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) {
        setState(() => _isInitialLoading = false);
        return;
      }

      var query = supabase
          .from('customers')
          .select('*, employees(full_name)')
          .eq('company_id', companyId);

      if (_selectedChannel != null) {
        query = query.eq('channel', _selectedChannel!);
      }
      if (_selectedStatus != null) {
        query = query.eq('status', _selectedStatus!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,code.ilike.%$_searchQuery%,phone.ilike.%$_searchQuery%');
      }

      final response = await query
          .order(_sortBy, ascending: _sortAscending, nullsFirst: false)
          .range(0, _pageSize - 1);

      final customers = (response as List).map((json) => OdoriCustomer.fromJson(json)).toList();

      setState(() {
        _allCustomers.addAll(customers);
        _hasMore = customers.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final newOffset = _currentOffset + _pageSize;
      final companyId = ref.read(authProvider).user?.companyId ?? '';

      var query = supabase
          .from('customers')
          .select('*, employees(full_name)')
          .eq('company_id', companyId);

      if (_selectedChannel != null) {
        query = query.eq('channel', _selectedChannel!);
      }
      if (_selectedStatus != null) {
        query = query.eq('status', _selectedStatus!);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,code.ilike.%$_searchQuery%,phone.ilike.%$_searchQuery%');
      }

      final response = await query
          .order(_sortBy, ascending: _sortAscending, nullsFirst: false)
          .range(newOffset, newOffset + _pageSize - 1);

      final newCustomers = (response as List).map((json) => OdoriCustomer.fromJson(json)).toList();

      setState(() {
        _allCustomers.addAll(newCustomers);
        _currentOffset = newOffset;
        _hasMore = newCustomers.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm: $e')),
        );
      }
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sắp xếp theo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSortOption('Ngày mua gần nhất', 'last_order_date', Icons.calendar_today),
            _buildSortOption('Tên A-Z', 'name', Icons.sort_by_alpha),
            _buildSortOption('Hạn mức tín dụng', 'credit_limit', Icons.account_balance_wallet),
            _buildSortOption('Ngày tạo', 'created_at', Icons.access_time),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.teal : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected 
          ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.teal)
          : null,
      onTap: () {
        setState(() {
          if (_sortBy == value) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = value == 'name';
          }
        });
        Navigator.pop(context);
        _loadInitial();
      },
    );
  }

  void _showCustomerActions(OdoriCustomer customer) {
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
            Row(
              children: [
                _buildCustomerAvatar(customer, size: 50),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(customer.channel ?? customer.type ?? '', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.phone, 'Gọi điện', Colors.green, () {
                  Navigator.pop(context);
                  _makePhoneCall(customer.phone);
                }),
                _buildActionButton(Icons.shopping_cart, 'Tạo đơn', Colors.blue, () {
                  Navigator.pop(context);
                  _createOrderForCustomer(customer);
                }),
                _buildActionButton(Icons.history, 'Lịch sử', Colors.orange, () {
                  Navigator.pop(context);
                  _showOrderHistory(customer);
                }),
                _buildActionButton(Icons.edit, 'Sửa', Colors.purple, () {
                  Navigator.pop(context);
                  _showEditCustomerDialog(customer);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khách hàng chưa có số điện thoại'), backgroundColor: Colors.orange),
      );
      return;
    }
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gọi điện: $phone'), backgroundColor: Colors.green),
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

  void _createOrderForCustomer(OdoriCustomer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderFormPage(preselectedCustomer: customer),
      ),
    );
  }

  void _showOrderHistory(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => CustomerOrderHistorySheet(
          customer: customer,
          scrollController: scrollController,
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
        child: CustomerFormSheet(
          onSaved: (customer) {
            _loadStatistics();
            _loadInitial();
          },
        ),
      ),
    );
  }

  void _showEditCustomerDialog(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CustomerFormSheet(
          customer: customer,
          onSaved: (updatedCustomer) {
            _loadStatistics();
            _loadInitial();
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerAvatar(OdoriCustomer customer, {double size = 44}) {
    Color bgColor;
    Color textColor = Colors.white;
    
    if (customer.status == 'inactive') {
      bgColor = Colors.grey.shade400;
    } else if (customer.channel == 'Horeca') {
      bgColor = Colors.purple.shade400;
    } else if (customer.channel == 'GT Sỉ') {
      bgColor = Colors.blue.shade400;
    } else if (customer.channel == 'GT Lẻ') {
      bgColor = Colors.green.shade400;
    } else {
      bgColor = Colors.teal.shade400;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: customer.creditLimit > 10000000 
            ? Border.all(color: Colors.amber, width: 3)
            : null,
      ),
      child: Center(
        child: Text(
          customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: size * 0.4),
        ),
      ),
    );
  }

  String _formatLastOrder(DateTime? date) {
    if (date == null) return 'Chưa có đơn';
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Hôm nay';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '> 1 năm trước';
  }

  Color _getLastOrderColor(DateTime? date) {
    if (date == null) return Colors.grey;
    final diff = DateTime.now().difference(date).inDays;
    if (diff <= 7) return Colors.green;
    if (diff <= 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // Collapsible Statistics Header
          SliverAppBar(
            expandedHeight: 100,
            collapsedHeight: 0,
            toolbarHeight: 0,
            pinned: false,
            floating: false,
            snap: false,
            backgroundColor: Colors.teal.shade500,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade400, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('👥', _totalCustomers.toString(), 'Tổng KH')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('✅', _activeCustomers.toString(), 'Đang HĐ')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('🆕', _newCustomersThisMonth.toString(), 'KH mới')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildStatCard('💰', NumberFormat.compact(locale: 'vi').format(_totalCreditLimit), 'Hạn mức')),
                  ],
                ),
              ),
            ),
          ),

          // Pinned Search Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverSearchBarDelegate(
              minHeight: 56,
              maxHeight: 56,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm tên, mã, SĐT...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _loadInitial();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _showSortOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.sort, color: Colors.teal.shade700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible Filters
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _buildFilterChip('Tất cả', null, _selectedChannel == null),
                        const SizedBox(width: 6),
                        _buildFilterChip('Horeca', 'Horeca', _selectedChannel == 'Horeca', Colors.purple),
                        const SizedBox(width: 6),
                        _buildFilterChip('GT Sỉ', 'GT Sỉ', _selectedChannel == 'GT Sỉ', Colors.blue),
                        const SizedBox(width: 6),
                        _buildFilterChip('GT Lẻ', 'GT Lẻ', _selectedChannel == 'GT Lẻ', Colors.green),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        _buildStatusChip('Tất cả TT', null, _selectedStatus == null),
                        const SizedBox(width: 6),
                        _buildStatusChip('Đang HĐ', 'active', _selectedStatus == 'active', Colors.green),
                        const SizedBox(width: 6),
                        _buildStatusChip('Ngưng HĐ', 'inactive', _selectedStatus == 'inactive', Colors.red),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Text(
                          'Hiển thị ${_allCustomers.length} khách hàng',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        if (_hasMore)
                          Text('Kéo để tải thêm ↓', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      body: Stack(
        children: [
          _isInitialLoading
              ? const Center(child: CircularProgressIndicator())
              : _allCustomers.isEmpty
                  ? _buildEmptyState()
                  : NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        if (scrollNotification is ScrollEndNotification) {
                          if (scrollNotification.metrics.pixels >= 
                              scrollNotification.metrics.maxScrollExtent - 200) {
                            _loadMore();
                          }
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _loadStatistics();
                          await _loadInitial();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _allCustomers.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (BuildContext ctx, int index) {
                            if (index >= _allCustomers.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildCustomerCard(_allCustomers[index]);
                          },
                        ),
                      ),
                    ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: _showAddCustomerDialog,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Thêm KH', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value, 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected, [Color? activeColor]) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (activeColor ?? Colors.grey.shade700),
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor ?? Colors.teal,
      backgroundColor: activeColor?.withOpacity(0.1) ?? Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) {
        setState(() => _selectedChannel = isSelected ? null : value);
        _loadInitial();
      },
    );
  }

  Widget _buildStatusChip(String label, String? value, bool isSelected, [Color? activeColor]) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (activeColor ?? Colors.grey.shade700),
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor ?? Colors.teal,
      backgroundColor: activeColor?.withOpacity(0.1) ?? Colors.grey.shade100,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) {
        setState(() => _selectedStatus = isSelected ? null : value);
        _loadInitial();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Không tìm thấy khách hàng', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm', 
               style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(OdoriCustomer customer) {
    final lastOrderColor = _getLastOrderColor(customer.lastOrderDate);
    final isVIP = customer.creditLimit > 10000000;
    
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
                  _buildCustomerAvatar(customer),
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
                                customer.name,
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
                            if (customer.channel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getChannelColor(customer.channel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  customer.channel!,
                                  style: TextStyle(fontSize: 10, color: _getChannelColor(customer.channel)),
                                ),
                              ),
                            if (customer.district != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  customer.district!,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (customer.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      color: Colors.green,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gọi: ${customer.phone}')),
                        );
                      },
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
              
              Row(
                children: [
                  Expanded(
                    child: _buildKPIItem(
                      '📅',
                      _formatLastOrder(customer.lastOrderDate),
                      'Lần mua',
                      lastOrderColor,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '💳',
                      customer.creditLimit > 0 
                          ? NumberFormat.compact(locale: 'vi').format(customer.creditLimit)
                          : '0',
                      'Hạn mức',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '⏱️',
                      '${customer.paymentTerms}',
                      'Ngày TT',
                      Colors.purple,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      customer.status == 'active' ? '✅' : '⛔',
                      customer.status == 'active' ? 'Hoạt động' : 'Ngưng',
                      'Trạng thái',
                      customer.status == 'active' ? Colors.green : Colors.red,
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

  Color _getChannelColor(String? channel) {
    switch (channel) {
      case 'Horeca': return Colors.purple;
      case 'GT Sỉ': return Colors.blue;
      case 'GT Lẻ': return Colors.green;
      default: return Colors.grey;
    }
  }
}

// ==================== SLIVER DELEGATE FOR PINNED SEARCH BAR ====================
class SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  SliverSearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(SliverSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

// ==================== CUSTOMER FORM SHEET ====================
class CustomerFormSheet extends ConsumerStatefulWidget {
  final OdoriCustomer? customer;
  final Function(OdoriCustomer) onSaved;

  const CustomerFormSheet({
    super.key,
    this.customer,
    required this.onSaved,
  });

  @override
  ConsumerState<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  
  String _selectedChannel = 'GT Sỉ';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _codeController.text = widget.customer!.code;
      _phoneController.text = widget.customer!.phone ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _districtController.text = widget.customer!.district ?? '';
      _creditLimitController.text = widget.customer!.creditLimit.toString();
      _paymentTermsController.text = widget.customer!.paymentTerms.toString();
      _selectedChannel = widget.customer!.channel ?? 'GT Sỉ';
      _selectedStatus = widget.customer!.status;
    } else {
      _creditLimitController.text = '0';
      _paymentTermsController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _creditLimitController.dispose();
    _paymentTermsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final companyId = authState.user?.companyId;
      
      if (companyId == null || companyId.isEmpty) {
        throw Exception('Không tìm thấy company_id. Vui lòng đăng nhập lại.');
      }

      final customerData = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().isEmpty 
            ? 'KH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'
            : _codeController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'district': _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
        'channel': _selectedChannel,
        'status': _selectedStatus,
        'credit_limit': double.tryParse(_creditLimitController.text) ?? 0,
        'payment_terms': int.tryParse(_paymentTermsController.text) ?? 0,
        'company_id': companyId,
      };

      if (widget.customer != null) {
        await supabase
            .from('customers')
            .update(customerData)
            .eq('id', widget.customer!.id);
      } else {
        await supabase.from('customers').insert(customerData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.customer != null 
                ? 'Đã cập nhật khách hàng' 
                : 'Đã thêm khách hàng mới'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved(widget.customer ?? OdoriCustomer(
          id: '', 
          code: customerData['code'] as String, 
          name: customerData['name'] as String,
          companyId: companyId,
          status: _selectedStatus,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.person_add,
                    color: Colors.teal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing ? 'Chỉnh sửa khách hàng' : 'Thêm khách hàng mới',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên khách hàng *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.trim().isEmpty == true 
                    ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã KH',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(),
                        hintText: 'Tự động nếu trống',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'Quận/Huyện',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedChannel,
                      decoration: const InputDecoration(
                        labelText: 'Kênh',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Horeca', child: Text('Horeca')),
                        DropdownMenuItem(value: 'GT Sỉ', child: Text('GT Sỉ')),
                        DropdownMenuItem(value: 'GT Lẻ', child: Text('GT Lẻ')),
                      ],
                      onChanged: (value) => setState(() => _selectedChannel = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Hạn mức (VNĐ)',
                        prefixIcon: Icon(Icons.credit_card),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentTermsController,
                      decoration: const InputDecoration(
                        labelText: 'Ngày thanh toán',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái',
                  prefixIcon: Icon(Icons.toggle_on),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                  DropdownMenuItem(value: 'inactive', child: Text('Ngưng hoạt động')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              height: 20, 
                              width: 20, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CUSTOMER ORDER HISTORY SHEET ====================
class CustomerOrderHistorySheet extends StatefulWidget {
  final OdoriCustomer customer;
  final ScrollController scrollController;

  const CustomerOrderHistorySheet({
    super.key,
    required this.customer,
    required this.scrollController,
  });

  @override
  State<CustomerOrderHistorySheet> createState() => _CustomerOrderHistorySheetState();
}

class _CustomerOrderHistorySheetState extends State<CustomerOrderHistorySheet> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await supabase
          .from('sales_orders')
          .select('id, order_code, total_amount, status, created_at')
          .eq('customer_id', widget.customer.id)
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải lịch sử: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed': return 'Hoàn thành';
      case 'pending': return 'Chờ duyệt';
      case 'cancelled': return 'Đã hủy';
      case 'processing': return 'Đang xử lý';
      default: return status ?? 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lịch sử đơn hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(widget.customer.name, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Chưa có đơn hàng', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final createdAt = DateTime.tryParse(order['created_at'] ?? '');
                          final status = order['status'] as String?;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.receipt, color: _getStatusColor(status)),
                              ),
                              title: Text(
                                order['order_code'] ?? 'N/A',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                createdAt != null 
                                    ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt)
                                    : 'N/A',
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormat.format(order['total_amount'] ?? 0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(fontSize: 11, color: _getStatusColor(status)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          if (_orders.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('${_orders.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      const Text('Tổng đơn', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        currencyFormat.format(_orders.fold<double>(0, (sum, o) => sum + (o['total_amount'] ?? 0))),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const Text('Tổng giá trị', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
