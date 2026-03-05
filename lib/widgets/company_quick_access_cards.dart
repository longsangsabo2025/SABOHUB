import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/company.dart';
import '../providers/company_context_provider.dart';
import '../providers/cached_data_providers.dart';

/// Quick Access Cards showing subsidiaries on CEO/Manager Dashboard
/// Each card displays company name, type, key stats, and switches layout
class CompanyQuickAccessCards extends ConsumerWidget {
  const CompanyQuickAccessCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(accessibleCompaniesProvider);

    return companiesAsync.when(
      data: (companies) {
        final subsidiaries =
            companies.where((c) => !c.type.isCorporation).toList();
        if (subsidiaries.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.domain,
                      size: 20, color: AppColors.backgroundDark),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Công ty con',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Truy cập nhanh các đơn vị kinh doanh',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Company cards
            ...subsidiaries.map(
              (company) => _CompanyQuickCard(company: company),
            ),
          ],
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          2,
          (_) => Container(
            height: 88,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyQuickCard extends ConsumerWidget {
  final Company company;

  const _CompanyQuickCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(cachedCompanyStatsProvider(company.id));

    return GestureDetector(
      onTap: () {
        // Set selectedSubsidiary → triggers layout switch to subsidiary
        ref.read(selectedSubsidiaryProvider.notifier).select(company);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: company.type.color.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: company.type.color.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Color-coded icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      company.type.color.withValues(alpha: 0.15),
                      company.type.color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  company.type.icon,
                  color: company.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Company info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: company.type.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            company.type.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: company.type.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Quick stats
                        statsAsync.when(
                          data: (stats) {
                            final emp = stats['employeeCount'] ?? 0;
                            return Text(
                              '$emp nhân viên',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                          loading: () => Text(
                            '...',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.grey400,
                            ),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: company.type.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: company.type.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
