// Extracted from distribution_manager_layout.dart
// Customers Management Page with search, filters, statistics, and CRUD operations

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/odori_customer.dart';
import '../../../../models/customer_tier.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/customer_revenue_service.dart';
import '../../../../services/customer_import_export_service.dart';
import '../../../../widgets/customer_tier_widgets.dart';
import '../../../../widgets/customer_addresses_sheet.dart';
import '../../../../widgets/customer_contacts_sheet.dart';
import '../../../../widgets/customer_debt_sheet.dart';
import '../../../../widgets/customer_visits_sheet.dart';
import '../../../../widgets/customer_avatar.dart';
import '../../../../pages/orders/order_form_page.dart';
import '../../../../pages/customers/customer_detail_page.dart';

// Extracted sub-components
import 'customers_sheets/customer_form_sheet.dart';
import 'customers_sheets/customer_order_history_sheet.dart';
import 'customers_sheets/credit_limit_sheet.dart';

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
  bool _showArchived = false; // Mặc định ẩn KH lưu trữ
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
  int _archivedCustomers = 0;
  int _newCustomersThisMonth = 0;
  double _totalCreditLimit = 0;
  
  // Customer Tier
  CustomerTier? _selectedTier;
  Map<String, CustomerRevenue> _revenueData = {};
  Map<CustomerTier, int> _tierStats = {};
  
  // Debounce & race condition prevention
  Timer? _searchDebounce;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStatistics();
    _loadRevenueData();
    _loadTierStats();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

      // Use count() for accurate statistics (not limited by 1000 row default)
      final totalResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .count(CountOption.exact);
      
      final activeResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'active')
          .count(CountOption.exact);
      
      final archivedResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .eq('status', 'inactive')
          .count(CountOption.exact);
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final newResponse = await supabase
          .from('customers')
          .select('id')
          .eq('company_id', companyId)
          .gte('created_at', startOfMonth.toIso8601String())
          .count(CountOption.exact);
      
      // For credit_limit sum, we need to fetch all - use pagination or RPC
      // For now, use a simple loop with pagination
      double totalCredit = 0;
      int offset = 0;
      const batchSize = 1000;
      while (true) {
        final creditResponse = await supabase
            .from('customers')
            .select('credit_limit')
            .eq('company_id', companyId)
            .range(offset, offset + batchSize - 1);
        
        final batch = creditResponse as List;
        if (batch.isEmpty) break;
        
        for (var c in batch) {
          totalCredit += (c['credit_limit'] as num?)?.toDouble() ?? 0;
        }
        
        if (batch.length < batchSize) break;
        offset += batchSize;
      }

      if (mounted) {
        setState(() {
          _totalCustomers = totalResponse.count;
          _activeCustomers = activeResponse.count;
          _archivedCustomers = archivedResponse.count;
          _newCustomersThisMonth = newResponse.count;
          _totalCreditLimit = totalCredit;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading statistics: $e');
    }
  }

  /// Load revenue data và tier statistics
  Future<void> _loadRevenueData() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final revenueMap = await CustomerRevenueService.getRevenueByCompany(companyId);

      if (mounted) {
        setState(() {
          _revenueData = revenueMap;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading revenue data: $e');
    }
  }

  /// Load tier statistics từ database (đếm theo trường tier của customers)
  Future<void> _loadTierStats() async {
    try {
      final companyId = ref.read(authProvider).user?.companyId ?? '';
      if (companyId.isEmpty) return;

      final Map<CustomerTier, int> stats = {
        CustomerTier.diamond: 0,
        CustomerTier.gold: 0,
        CustomerTier.silver: 0,
        CustomerTier.bronze: 0,
        CustomerTier.none: 0,
      };

      // Use pagination to fetch all customers (avoid 1000 limit)
      int offset = 0;
      const batchSize = 1000;
      while (true) {
        final response = await supabase
            .from('customers')
            .select('tier')
            .eq('company_id', companyId)
            .range(offset, offset + batchSize - 1);

        final batch = response as List;
        if (batch.isEmpty) break;

        for (var customer in batch) {
          final tier = _stringToTier(customer['tier'] ?? 'bronze');
          if (tier != null) {
            stats[tier] = (stats[tier] ?? 0) + 1;
          }
        }

        if (batch.length < batchSize) break;
        offset += batchSize;
      }

      if (mounted) {
        setState(() {
          _tierStats = stats;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading tier stats: $e');
    }
  }

  /// Lấy tier của khách hàng - ưu tiên tier từ database, sau đó mới dùng tier tính từ doanh số
  CustomerTier _getCustomerTier(String customerId) {
    // Tìm customer để lấy tier từ database
    final customer = _allCustomers.where((c) => c.id == customerId).firstOrNull;
    if (customer != null) {
      // Nếu tier đã được set thủ công (không phải bronze mặc định), ưu tiên dùng
      final dbTier = _stringToTier(customer.tier);
      if (dbTier != null) {
        return dbTier;
      }
    }
    // Fallback: dùng tier tính từ doanh số
    final revenue = _revenueData[customerId];
    return revenue?.tier ?? CustomerTier.none;
  }

  /// Convert string tier từ database sang CustomerTier enum
  CustomerTier? _stringToTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return CustomerTier.diamond;
      case 'gold':
        return CustomerTier.gold;
      case 'silver':
        return CustomerTier.silver;
      case 'bronze':
        return CustomerTier.bronze;
      default:
        return null;
    }
  }

  /// Lấy revenue info của khách hàng
  CustomerRevenue? _getCustomerRevenue(String customerId) {
    return _revenueData[customerId];
  }

  Future<void> _loadInitial() async {
    final thisVersion = ++_loadVersion;
    
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

      debugPrint('🔄 Loading initial customers for company: $companyId');

      var query = supabase
          .from('customers')
          .select('*, employees(full_name)')
          .eq('company_id', companyId);

      if (_selectedChannel != null) {
        query = query.eq('channel', _selectedChannel!);
      }
      if (_selectedStatus != null) {
        query = query.eq('status', _selectedStatus!);
      } else if (!_showArchived) {
        // Mặc định ẩn KH lưu trữ
        query = query.neq('status', 'inactive');
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,code.ilike.%$_searchQuery%,phone.ilike.%$_searchQuery%');
      }
      // Filter theo tier (query từ database)
      if (_selectedTier != null) {
        query = query.eq('tier', _selectedTier!.name);
      }

      final response = await query
          .order(_sortBy, ascending: _sortAscending, nullsFirst: false)
          .order('id', ascending: true)
          .limit(_pageSize)
          .range(0, _pageSize - 1);

      final customers = (response as List).map((json) => OdoriCustomer.fromJson(json)).toList();

      debugPrint('✅ Initial load: ${customers.length} customers');

      // Discard stale response if a newer request was started
      if (thisVersion != _loadVersion) return;
      
      setState(() {
        _allCustomers
          ..clear()
          ..addAll(customers);
        _hasMore = customers.length >= _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading customers: $e');
      if (thisVersion == _loadVersion) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;

    final thisVersion = _loadVersion;
    setState(() => _isLoadingMore = true);

    try {
      final newOffset = _currentOffset + _pageSize;
      final companyId = ref.read(authProvider).user?.companyId ?? '';

      debugPrint('🔄 Loading more customers: offset=$newOffset, current total=${_allCustomers.length}');

      var query = supabase
          .from('customers')
          .select('*, employees(full_name)')
          .eq('company_id', companyId);

      if (_selectedChannel != null) {
        query = query.eq('channel', _selectedChannel!);
      }
      if (_selectedStatus != null) {
        query = query.eq('status', _selectedStatus!);
      } else if (!_showArchived) {
        // Mặc định ẩn KH lưu trữ
        query = query.neq('status', 'inactive');
      }
      if (_searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$_searchQuery%,code.ilike.%$_searchQuery%,phone.ilike.%$_searchQuery%');
      }
      // Filter theo tier (query từ database)
      if (_selectedTier != null) {
        query = query.eq('tier', _selectedTier!.name);
      }

      final response = await query
          .order(_sortBy, ascending: _sortAscending, nullsFirst: false)
          .order('id', ascending: true)
          .limit(_pageSize)
          .range(newOffset, newOffset + _pageSize - 1);

      final newCustomers = (response as List).map((json) => OdoriCustomer.fromJson(json)).toList();

      debugPrint('✅ Loaded ${newCustomers.length} customers at offset $newOffset');

      // Discard stale response
      if (thisVersion != _loadVersion) return;
      
      // Deduplicate by ID before adding
      final existingIds = _allCustomers.map((c) => c.id).toSet();
      final uniqueNew = newCustomers.where((c) => !existingIds.contains(c.id)).toList();
      
      setState(() {
        _allCustomers.addAll(uniqueNew);
        _currentOffset = newOffset;
        _hasMore = newCustomers.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading more customers: $e');
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

  void _navigateToCustomerDetail(OdoriCustomer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailPage(customer: customer),
      ),
    ).then((result) {
      // If customer was deleted, refresh the list
      if (result == true) {
        _loadInitial();
      }
    });
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
            // Row 1: Thao tác nhanh
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
                _buildActionButton(Icons.location_on, 'Địa chỉ', Colors.teal, () {
                  Navigator.pop(context);
                  _showCustomerAddresses(customer);
                }),
                _buildActionButton(Icons.contacts, 'Liên hệ', Colors.purple, () {
                  Navigator.pop(context);
                  _showCustomerContacts(customer);
                }),
              ],
            ),
            const SizedBox(height: 12),
            // Row 2: Thông tin & lịch sử
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.receipt_long, 'Đơn hàng', Colors.orange, () {
                  Navigator.pop(context);
                  _showOrderHistory(customer);
                }),
                _buildActionButton(Icons.account_balance_wallet, 'Công nợ', Colors.red, () {
                  Navigator.pop(context);
                  _showCustomerDebt(customer);
                }),
                _buildActionButton(Icons.credit_score, 'Hạn mức', Colors.blue, () {
                  Navigator.pop(context);
                  _showCreditLimit(customer);
                }),
                _buildActionButton(Icons.place, 'Viếng thăm', Colors.indigo, () {
                  Navigator.pop(context);
                  _showCustomerVisits(customer);
                }),
              ],
            ),
            const SizedBox(height: 12),
            // Row 3: Quản lý
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.edit, 'Sửa', Colors.blueGrey, () {
                  Navigator.pop(context);
                  _showEditCustomerDialog(customer);
                }),
                // Archive/Unarchive button
                customer.status == 'inactive'
                    ? _buildActionButton(Icons.unarchive, 'Khôi phục', Colors.green, () {
                        Navigator.pop(context);
                        _toggleArchiveCustomer(customer, false);
                      })
                    : _buildActionButton(Icons.archive_outlined, 'Lưu trữ', Colors.orange, () {
                        Navigator.pop(context);
                        _toggleArchiveCustomer(customer, true);
                      }),
                _buildActionButton(Icons.delete_outline, 'Xóa', Colors.red.shade300, () {
                  Navigator.pop(context);
                  _confirmDeleteCustomer(customer);
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

  /// Dialog nhập khách hàng từ CSV
  Future<void> _showImportDialog(String companyId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đọc file'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang nhập khách hàng...'),
            ],
          ),
        ),
      );
    }

    try {
      final csvContent = String.fromCharCodes(file.bytes!);
      final importResult = await CustomerImportExportService.importFromCSV(
        companyId: companyId,
        csvContent: csvContent,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show result dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(importResult.hasErrors ? Icons.warning : Icons.check_circle, 
                     color: importResult.hasErrors ? Colors.orange : Colors.green),
                const SizedBox(width: 12),
                const Text('Kết quả nhập'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📥 Thêm mới: ${importResult.added} khách hàng'),
                Text('📝 Cập nhật: ${importResult.updated} khách hàng'),
                Text('⏭️ Bỏ qua: ${importResult.skipped} dòng'),
                if (importResult.hasErrors) ...[
                  const SizedBox(height: 12),
                  const Text('Lỗi:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ...importResult.errors.take(5).map((e) => Text('• $e', style: const TextStyle(fontSize: 12))),
                  if (importResult.errors.length > 5)
                    Text('... và ${importResult.errors.length - 5} lỗi khác', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Reload data
        _loadStatistics();
        _loadInitial();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi nhập file: $e'), backgroundColor: Colors.red),
        );
      }
    }
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

  /// Lưu trữ hoặc khôi phục khách hàng
  Future<void> _toggleArchiveCustomer(OdoriCustomer customer, bool archive) async {
    try {
      final newStatus = archive ? 'inactive' : 'active';
      await supabase
          .from('customers')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', customer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(archive 
                ? '📦 Đã lưu trữ "${customer.name}"' 
                : '✅ Đã khôi phục "${customer.name}"'),
            backgroundColor: archive ? Colors.orange : Colors.green,
          ),
        );
        _loadStatistics();
        _loadInitial();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteCustomer(OdoriCustomer customer) async {
    // Nếu chưa lưu trữ, gợi ý lưu trữ trước
    final isArchived = customer.status == 'inactive';
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            Text(isArchived ? 'Xác nhận xóa' : 'Xóa khách hàng'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArchived 
                ? 'Bạn có chắc muốn xóa vĩnh viễn:' 
                : 'Bạn muốn làm gì với khách hàng:'),
            const SizedBox(height: 8),
            Text(
              customer.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (customer.code.isNotEmpty)
              Text('Mã: ${customer.code}', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            if (!isArchived)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Nên lưu trữ thay vì xóa để giữ lại thông tin!',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            if (isArchived)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Hành động này không thể hoàn tác!',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Hủy'),
          ),
          if (!isArchived)
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'archive'),
              icon: const Icon(Icons.archive, size: 18),
              label: const Text('Lưu trữ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (result == 'archive') {
      _toggleArchiveCustomer(customer, true);
      return;
    }
    
    if (result != 'delete') return;

    try {
      await supabase.from('customers').delete().eq('id', customer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã xóa khách hàng "${customer.name}"'),
            backgroundColor: Colors.green,
          ),
        );
        _loadStatistics();
        _loadInitial();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa khách hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCustomerAddresses(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomerAddressesSheet(
        customer: customer,
        onChanged: () {
          // Optionally reload customer data if needed
        },
      ),
    );
  }

  void _showCustomerContacts(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomerContactsSheet(
        customer: customer,
        onChanged: () {
          // Optionally reload customer data if needed
        },
      ),
    );
  }

  void _showCustomerDebt(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomerDebtSheet(
        customer: customer,
        onChanged: () {
          _loadStatistics();
          _loadInitial();
        },
      ),
    );
  }

  void _showCreditLimit(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CreditLimitSheet(
        customer: customer,
        onChanged: () {
          _loadStatistics();
          _loadInitial();
        },
      ),
    );
  }

  void _showCustomerVisits(OdoriCustomer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomerVisitsSheet(
        customer: customer,
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
    return CustomerAvatar(
      seed: customer.name,
      radius: size / 2,
      border: customer.creditLimit > 10000000 
          ? Border.all(color: Colors.amber, width: 3)
          : null,
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
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(
                            const Duration(milliseconds: 400),
                            () => _loadInitial(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Làm mới',
                      onPressed: () {
                        _loadInitial();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Đã làm mới danh sách khách hàng'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
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
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.teal.shade700),
                      tooltip: 'Thêm tùy chọn',
                      onSelected: (value) async {
                        final companyId = ref.read(authProvider).user?.companyId;
                        if (companyId == null) return;
                        
                        if (value == 'export') {
                          try {
                            await CustomerImportExportService.exportToCSV(companyId: companyId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Đã xuất file CSV'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Lỗi xuất file: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } else if (value == 'import') {
                          _showImportDialog(companyId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download, color: Colors.teal),
                              SizedBox(width: 12),
                              Text('Xuất Excel/CSV'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.upload, color: Colors.orange),
                              SizedBox(width: 12),
                              Text('Nhập từ CSV'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Compact Filters - single row
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // Channel filter dropdown
                  _buildCompactPopup<String?>(
                    icon: Icons.store,
                    label: _selectedChannel ?? 'Kênh',
                    isActive: _selectedChannel != null,
                    activeColor: _selectedChannel == 'Horeca' ? Colors.purple : _selectedChannel == 'GT Sỉ' ? Colors.blue : _selectedChannel == 'GT Lẻ' ? Colors.green : Colors.teal,
                    items: [
                      PopupMenuItem(value: null, child: Text('Tất cả', style: TextStyle(fontWeight: _selectedChannel == null ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'Horeca', child: Text('🏨 Horeca', style: TextStyle(fontWeight: _selectedChannel == 'Horeca' ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'GT Sỉ', child: Text('📦 GT Sỉ', style: TextStyle(fontWeight: _selectedChannel == 'GT Sỉ' ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'GT Lẻ', child: Text('🛒 GT Lẻ', style: TextStyle(fontWeight: _selectedChannel == 'GT Lẻ' ? FontWeight.bold : FontWeight.normal))),
                    ],
                    onSelected: (value) {
                      setState(() => _selectedChannel = value);
                      _loadInitial();
                    },
                  ),
                  const SizedBox(width: 6),
                  // Status filter dropdown
                  _buildCompactPopup<String?>(
                    icon: Icons.circle,
                    label: _selectedStatus == 'active' ? 'Đang HĐ' : _selectedStatus == 'inactive' ? 'Ngưng HĐ' : 'Trạng thái',
                    isActive: _selectedStatus != null || _showArchived,
                    activeColor: _selectedStatus == 'active' ? Colors.green : _selectedStatus == 'inactive' ? Colors.red : Colors.orange,
                    items: [
                      PopupMenuItem(value: '__all__', child: Text('Tất cả', style: TextStyle(fontWeight: _selectedStatus == null ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'active', child: Text('✅ Đang HĐ', style: TextStyle(fontWeight: _selectedStatus == 'active' ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'inactive', child: Text('⏸ Ngưng HĐ', style: TextStyle(fontWeight: _selectedStatus == 'inactive' ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'inactive', child: Text('📦 Lưu trữ ($_archivedCustomers)', style: TextStyle(fontWeight: _selectedStatus == 'inactive' ? FontWeight.bold : FontWeight.normal))),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: '__toggle_archived__',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_showArchived ? Icons.visibility : Icons.visibility_off, size: 16, color: _showArchived ? Colors.orange : Colors.grey),
                            const SizedBox(width: 8),
                            Text(_showArchived ? 'Ẩn LT' : 'Hiện LT'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == '__toggle_archived__') {
                        setState(() => _showArchived = !_showArchived);
                      } else {
                        setState(() => _selectedStatus = value == '__all__' ? null : value);
                      }
                      _loadInitial();
                    },
                  ),
                  const SizedBox(width: 6),
                  // Tier filter dropdown
                  _buildCompactPopup<String>(
                    icon: Icons.diamond_outlined,
                    label: _selectedTier?.displayName ?? 'Hạng',
                    isActive: _selectedTier != null,
                    activeColor: _selectedTier?.color ?? Colors.teal,
                    items: [
                      PopupMenuItem(value: '__all__', child: Text('👥 Tất cả (${_tierStats.values.fold(0, (a, b) => a + b)})', style: TextStyle(fontWeight: _selectedTier == null ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'diamond', child: Text('💎 Kim Cương (${_tierStats[CustomerTier.diamond] ?? 0})', style: TextStyle(fontWeight: _selectedTier == CustomerTier.diamond ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'gold', child: Text('🥇 Vàng (${_tierStats[CustomerTier.gold] ?? 0})', style: TextStyle(fontWeight: _selectedTier == CustomerTier.gold ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'silver', child: Text('🥈 Bạc (${_tierStats[CustomerTier.silver] ?? 0})', style: TextStyle(fontWeight: _selectedTier == CustomerTier.silver ? FontWeight.bold : FontWeight.normal))),
                      PopupMenuItem(value: 'bronze', child: Text('🥉 Đồng (${_tierStats[CustomerTier.bronze] ?? 0})', style: TextStyle(fontWeight: _selectedTier == CustomerTier.bronze ? FontWeight.bold : FontWeight.normal))),
                    ],
                    onSelected: (value) {
                      CustomerTier? tier;
                      if (value == 'diamond') {
                        tier = CustomerTier.diamond;
                      } else if (value == 'gold') {
                        tier = CustomerTier.gold;
                      } else if (value == 'silver') {
                        tier = CustomerTier.silver;
                      } else if (value == 'bronze') {
                        tier = CustomerTier.bronze;
                      }
                      setState(() => _selectedTier = tier);
                      _loadInitial();
                    },
                  ),
                  const Spacer(),
                  // Customer count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_allCustomers.length} KH',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
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
                          CustomerRevenueService.clearCache();
                          await _loadStatistics();
                          await _loadRevenueData();
                          await _loadTierStats();
                          await _loadInitial();
                        },
                        child: Builder(
                          builder: (context) {
                            // Không cần filter client-side nữa vì đã query từ DB
                            // Giữ lại biến filteredCustomers để tương thích
                            final filteredCustomers = _allCustomers;
                            
                            if (filteredCustomers.isEmpty) {
                              if (_selectedTier != null) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_selectedTier!.emoji, style: const TextStyle(fontSize: 48)),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Không có khách hàng ${_selectedTier!.displayName}',
                                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return _buildEmptyState();
                            }
                            
                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              itemCount: filteredCustomers.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (BuildContext ctx, int index) {
                                if (index >= filteredCustomers.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return _buildCustomerCard(filteredCustomers[index]);
                              },
                            );
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
    final needsAddress = customer.address == null || customer.address!.isEmpty;
    final needsCoords = customer.lat == null || customer.lng == null;
    final hasWarning = needsAddress || needsCoords;
    final customerTier = _getCustomerTier(customer.id);
    final customerRevenue = _getCustomerRevenue(customer.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCustomerDetail(customer),
        onLongPress: () => _showCustomerActions(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar with warning badge
                  Stack(
                    children: [
                      _buildCustomerAvatar(customer),
                      if (hasWarning)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.priority_high, size: 10, color: Colors.white),
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
                            if (hasWarning)
                              Tooltip(
                                message: needsAddress 
                                    ? 'Thiếu địa chỉ' 
                                    : 'Thiếu tọa độ - cần bổ sung để hiển thị trên bản đồ',
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber, size: 10, color: Colors.red.shade700),
                                      const SizedBox(width: 2),
                                      Text(
                                        needsAddress ? 'Thiếu ĐC' : 'Thiếu tọa độ',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
                            // Tier Badge
                            if (customerTier != CustomerTier.none)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                child: CustomerTierBadge(tier: customerTier, showLabel: false, size: 16),
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
                            // Clickable address to open Google Maps
                            if (customer.district != null || customer.street != null) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _openGoogleMaps(customer),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.teal.shade400),
                                      const SizedBox(width: 2),
                                      Expanded(
                                        child: Text(
                                          _buildFullAddress(customer),
                                          style: TextStyle(
                                            fontSize: 11, 
                                            color: Colors.teal.shade600,
                                            decoration: TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.open_in_new, size: 10, color: Colors.teal.shade400),
                                    ],
                                  ),
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
                      customerTier.emoji,
                      customerRevenue != null 
                          ? NumberFormat.compact(locale: 'vi').format(customerRevenue.totalRevenue)
                          : '0',
                      'Doanh số',
                      customerTier.color,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildKPIItem(
                      '📦',
                      customerRevenue != null 
                          ? '${customerRevenue.completedOrders}'
                          : '0',
                      'Đơn hàng',
                      Colors.blue,
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
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
                    child: InkWell(
                      onTap: () => _showCreditLimit(customer),
                      borderRadius: BorderRadius.circular(8),
                      child: _buildKPIItem(
                        '💳',
                        customer.creditLimit > 0
                            ? NumberFormat.compact(locale: 'vi').format(customer.creditLimit)
                            : '—',
                        'Hạn mức',
                        Colors.blue,
                      ),
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
  
  /// Build full address from structured fields
  String _buildFullAddress(OdoriCustomer customer) {
    final parts = <String>[];
    if (customer.streetNumber != null && customer.streetNumber!.isNotEmpty) {
      parts.add(customer.streetNumber!);
    }
    if (customer.street != null && customer.street!.isNotEmpty) {
      parts.add(customer.street!);
    }
    if (customer.ward != null && customer.ward!.isNotEmpty) {
      // Add "Phường" prefix if it's a number
      final isNumber = int.tryParse(customer.ward!) != null;
      parts.add(isNumber ? 'Phường ${customer.ward}' : customer.ward!);
    }
    if (customer.district != null && customer.district!.isNotEmpty) {
      // Add "Quận" prefix if it's a number
      final isNumber = int.tryParse(customer.district!) != null;
      parts.add(isNumber ? 'Quận ${customer.district}' : customer.district!);
    }
    return parts.join(', ');
  }
  
  /// Open Google Maps with customer address
  Future<void> _openGoogleMaps(OdoriCustomer customer) async {
    String formattedAddress;
    
    // Build structured address for Google Maps
    final streetNumber = customer.streetNumber ?? '';
    final street = customer.street ?? '';
    final ward = customer.ward ?? '';
    final district = customer.district ?? '';
    final city = customer.city ?? 'Hồ Chí Minh';
    
    if (street.isNotEmpty && district.isNotEmpty) {
      // Format: 254 Nhật Tảo, Phường 6, Quận 10, Hồ Chí Minh, Việt Nam
      final parts = <String>[];
      if (streetNumber.isNotEmpty) {
        parts.add('$streetNumber $street');
      } else {
        parts.add(street);
      }
      if (ward.isNotEmpty) {
        final isNumber = int.tryParse(ward) != null;
        parts.add(isNumber ? 'Phường $ward' : ward);
      }
      final isDistrictNumber = int.tryParse(district) != null;
      parts.add(isDistrictNumber ? 'Quận $district' : district);
      parts.add(city);
      formattedAddress = '${parts.join(', ')}, Việt Nam';
    } else if (customer.address != null && customer.address!.isNotEmpty) {
      // Fallback to raw address field
      formattedAddress = customer.address!;
      if (!formattedAddress.toLowerCase().contains('việt nam')) {
        formattedAddress += ', Việt Nam';
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khách hàng chưa có địa chỉ'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final encodedAddress = Uri.encodeComponent(formattedAddress);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở Google Maps'), backgroundColor: Colors.red),
        );
      }
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
