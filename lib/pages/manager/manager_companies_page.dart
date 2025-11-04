import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ceo/widgets/companies_tab_simple.dart';
import '../../widgets/multi_account_switcher.dart';

/// Manager Companies Page
/// Allows manager to view companies (read-only or limited access)
class ManagerCompaniesPage extends ConsumerStatefulWidget {
  const ManagerCompaniesPage({super.key});

  @override
  ConsumerState<ManagerCompaniesPage> createState() => _ManagerCompaniesPageState();
}

class _ManagerCompaniesPageState extends ConsumerState<ManagerCompaniesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Công ty'),
        actions: const [
          MultiAccountSwitcher(),
          SizedBox(width: 8),
        ],
      ),
      body: const CompaniesTab(),
    );
  }
}
