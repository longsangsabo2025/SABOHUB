import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/documents/screens/documents_screen.dart';
import '../../providers/company_provider.dart';
import '../../models/company.dart';

/// CEO Documents Page - Quản lý tài liệu tất cả công ty
class CEODocumentsPage extends ConsumerStatefulWidget {
  const CEODocumentsPage({super.key});

  @override
  ConsumerState<CEODocumentsPage> createState() => _CEODocumentsPageState();
}

class _CEODocumentsPageState extends ConsumerState<CEODocumentsPage> {
  Company? _selectedCompany;

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(companiesProvider);

    return companiesAsync.when(
      data: (companies) {
        if (companies.isEmpty) {
          return _buildEmptyState();
        }

        // Auto-select first company if none selected
        if (_selectedCompany == null && companies.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedCompany = companies.first;
              });
            }
          });
          return const Center(child: CircularProgressIndicator());
        }

        // Show documents for selected company
        if (_selectedCompany != null) {
          return Column(
            children: [
              _buildCompanySelector(companies),
              Expanded(
                child: DocumentsScreen(
                  companyId: _selectedCompany!.id,
                ),
              ),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(companiesProvider);
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Company Selector
  Widget _buildCompanySelector(List<Company> companies) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.business, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          const Text(
            'Công ty:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<Company>(
              initialValue: _selectedCompany,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: companies.map((company) {
                return DropdownMenuItem(
                  value: company,
                  child: Text(
                    company.name,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (company) {
                if (company != null) {
                  setState(() {
                    _selectedCompany = company;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when no companies
  Widget _buildEmptyState() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có công ty nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng thêm công ty trước khi quản lý tài liệu',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
