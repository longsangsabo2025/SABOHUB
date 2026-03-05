import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/keys/ceo_keys.dart';

import '../../providers/analytics_provider.dart';
import 'ceo_analytics_page.dart';
import 'ceo_reports_settings_page.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// CEO Finance Page — Gom: Phân tích + Báo cáo
/// Mọi thứ liên quan đến số liệu tài chính ở đây
class CEOFinancePage extends ConsumerStatefulWidget {
  const CEOFinancePage({super.key});

  @override
  ConsumerState<CEOFinancePage> createState() => _CEOFinancePageState();
}

class _CEOFinancePageState extends ConsumerState<CEOFinancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAnalytics = _tabController.index == 0;
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final periodLabel = {
          'week': 'tuần này',
          'month': 'tháng này',
          'quarter': 'quý này',
          'year': 'năm này',
        }[selectedPeriod] ??
        'tháng này';

    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => ceoScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'Tài chính',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: isAnalytics
            ? [
                IconButton(
                  icon: Icon(Icons.file_download_outlined,
                      size: 22, color: Theme.of(context).colorScheme.onSurface54),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đang tải xuống báo cáo $periodLabel...'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      size: 22, color: Theme.of(context).colorScheme.onSurface54),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Chia sẻ báo cáo $periodLabel'),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                ),
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 14),
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Phân tích'),
            Tab(text: 'Báo cáo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CEOAnalyticsPage(),
          CEOReportsPage(),
        ],
      ),
    );
  }
}
