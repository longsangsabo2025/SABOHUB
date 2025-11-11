import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/auth_provider.dart';
import 'ceo_create_employee_page.dart';

/// Wrapper for CEO Create Employee Page
/// Auto-detects CEO's company from auth state
class CEOCreateEmployeeWrapper extends ConsumerStatefulWidget {
  const CEOCreateEmployeeWrapper({super.key});

  @override
  ConsumerState<CEOCreateEmployeeWrapper> createState() =>
      _CEOCreateEmployeeWrapperState();
}

class _CEOCreateEmployeeWrapperState
    extends ConsumerState<CEOCreateEmployeeWrapper> {
  String? _companyName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
  }

  Future<void> _fetchCompanyName() async {
    try {
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null || user.companyId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy công ty';
        });
        return;
      }

      // Query company name from database
      final response = await Supabase.instance.client
          .from('companies')
          .select('name')
          .eq('id', user.companyId!)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tìm thấy công ty';
        });
        return;
      }

      setState(() {
        _companyName = response['name'] as String;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Loading state
    if (_isLoading || authState.isLoading || user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get company info from user
    final companyId = user.companyId;

    // If error or no company, show error
    if (_errorMessage != null || companyId == null || companyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tạo nhân viên'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy công ty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Vui lòng tạo công ty trước khi tạo nhân viên',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Show create employee page with company info
    return CEOCreateEmployeePage(
      companyId: companyId,
      companyName: _companyName ?? 'Unknown Company',
    );
  }
}
