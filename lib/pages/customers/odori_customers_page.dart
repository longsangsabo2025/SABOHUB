import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/odori_customer.dart';
import '../../providers/odori_providers.dart';
import 'customer_form_page.dart';

class OdoriCustomersPage extends ConsumerStatefulWidget {
  const OdoriCustomersPage({super.key});

  @override
  ConsumerState<OdoriCustomersPage> createState() => _OdoriCustomersPageState();
}

class _OdoriCustomersPageState extends ConsumerState<OdoriCustomersPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  String? _typeFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider(CustomerFilters(
      status: _statusFilter,
      customerType: _typeFilter,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filter chips
          if (_statusFilter != null || _typeFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_statusFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_getStatusLabel(_statusFilter!)),
                          onDeleted: () => setState(() => _statusFilter = null),
                        ),
                      ),
                    if (_typeFilter != null)
                      Chip(
                        label: Text(_getTypeLabel(_typeFilter!)),
                        onDeleted: () => setState(() => _typeFilter = null),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          // Customer list
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Lỗi: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(customersProvider(const CustomerFilters())),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Chưa có khách hàng nào'),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(customersProvider(CustomerFilters(
                    status: _statusFilter,
                    customerType: _typeFilter,
                    search: _searchController.text.isEmpty ? null : _searchController.text,
                  )).future),
                  child: ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _CustomerCard(customer: customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bộ lọc',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Trạng thái'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _statusFilter == null,
                  onSelected: (_) {
                    setState(() => _statusFilter = null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Đang hoạt động'),
                  selected: _statusFilter == 'active',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'active');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Tạm ngưng'),
                  selected: _statusFilter == 'inactive',
                  onSelected: (_) {
                    setState(() => _statusFilter = 'inactive');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Loại khách hàng'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _typeFilter == null,
                  onSelected: (_) {
                    setState(() => _typeFilter = null);
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Trực tiếp'),
                  selected: _typeFilter == 'direct',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'direct');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('NPP'),
                  selected: _typeFilter == 'distributor',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'distributor');
                    Navigator.pop(context);
                  },
                ),
                ChoiceChip(
                  label: const Text('Đại lý'),
                  selected: _typeFilter == 'agent',
                  onSelected: (_) {
                    setState(() => _typeFilter = 'agent');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerFormPage(),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Đang hoạt động';
      case 'inactive':
        return 'Tạm ngưng';
      case 'blocked':
        return 'Đã khóa';
      default:
        return status;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'direct':
        return 'Trực tiếp';
      case 'distributor':
        return 'NPP';
      case 'agent':
        return 'Đại lý';
      default:
        return type;
    }
  }
}

class _CustomerCard extends StatelessWidget {
  final OdoriCustomer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(customer.status),
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.code,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (customer.address != null)
              Text(
                customer.address!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                _TypeBadge(type: customer.type ?? 'direct'),
                const SizedBox(width: 8),
                if (customer.channel != null)
                  _ChannelBadge(channel: customer.channel!),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(customer.creditLimit),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            Text(
              '${customer.paymentTerms} ngày',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: () => _showCustomerDetail(context),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCustomerDetail(BuildContext context) {
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
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getStatusColor(customer.status),
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          customer.code,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailRow(label: 'Loại', value: _getTypeLabel(customer.type ?? 'direct')),
              if (customer.channel != null)
                _DetailRow(label: 'Kênh', value: customer.channel!),
              if (customer.phone != null)
                _DetailRow(label: 'Điện thoại', value: customer.phone!, isPhone: true),
              if (customer.email != null)
                _DetailRow(label: 'Email', value: customer.email!),
              if (customer.address != null)
                _DetailRow(label: 'Địa chỉ', value: customer.address!),
              if (customer.taxCode != null)
                _DetailRow(label: 'Mã số thuế', value: customer.taxCode!),
              const Divider(height: 32),
              _DetailRow(
                label: 'Hạn mức tín dụng',
                value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(customer.creditLimit),
              ),
              _DetailRow(label: 'Thời hạn thanh toán', value: '${customer.paymentTerms} ngày'),
              if (customer.assignedSaleName != null)
                _DetailRow(label: 'Nhân viên phụ trách', value: customer.assignedSaleName!),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to orders
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Đơn hàng'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Create new order
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo đơn'),
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'direct':
        return 'Khách hàng trực tiếp';
      case 'distributor':
        return 'Nhà phân phối';
      case 'agent':
        return 'Đại lý';
      default:
        return type;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (type) {
      case 'direct':
        color = Colors.blue;
        label = 'Trực tiếp';
        break;
      case 'distributor':
        color = Colors.purple;
        label = 'NPP';
        break;
      case 'agent':
        color = Colors.orange;
        label = 'Đại lý';
        break;
      default:
        color = Colors.grey;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final String channel;

  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        channel.toUpperCase(),
        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPhone;

  const _DetailRow({required this.label, required this.value, this.isPhone = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: isPhone
                ? GestureDetector(
                    onTap: () {
                      // TODO: Launch phone dialer
                    },
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
          ),
        ],
      ),
    );
  }
}
