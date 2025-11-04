import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ceo/widgets/companies_tab_simple.dart';

/// CEO Companies Management Page
/// Manages all companies in the enterprise
class CEOCompaniesPage extends ConsumerStatefulWidget {
  const CEOCompaniesPage({super.key});

  @override
  ConsumerState<CEOCompaniesPage> createState() => _CEOCompaniesPageState();
}

class _CEOCompaniesPageState extends ConsumerState<CEOCompaniesPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: CompaniesTab(),
    );
  }
}