import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company.dart';
import '../providers/company_context_provider.dart';

/// Compact Company Switcher for CEO/Manager AppBar
/// Shows current context and allows quick navigation to any subsidiary
class CompanySwitcher extends ConsumerWidget {
  const CompanySwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(accessibleCompaniesProvider);

    return companiesAsync.when(
      data: (companies) {
        if (companies.isEmpty) return const SizedBox.shrink();

        // Filter out corporation type — only show subsidiaries
        final subsidiaries =
            companies.where((c) => !c.type.isCorporation).toList();
        if (subsidiaries.isEmpty) return const SizedBox.shrink();

        return _SwitcherButton(subsidiaries: subsidiaries);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SwitcherButton extends ConsumerWidget {
  final List<Company> subsidiaries;

  const _SwitcherButton({required this.subsidiaries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Company>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tooltip: 'Chuyển đổi giao diện công ty',
      onSelected: (company) {
        // Set the selectedSubsidiaryProvider → triggers routing rebuild
        ref.read(selectedSubsidiaryProvider.notifier).select(company);
      },
      itemBuilder: (context) => [
        // Header
        const PopupMenuItem<Company>(
          enabled: false,
          height: 36,
          child: Text(
            'Công ty con',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        PopupMenuDivider(height: 1),
        // Company items
        ...subsidiaries.map((company) => PopupMenuItem<Company>(
              value: company,
              height: 52,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: company.type.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      company.type.icon,
                      size: 18,
                      color: company.type.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          company.type.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: company.type.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            )),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 16),
            const SizedBox(width: 4),
            Text(
              '${subsidiaries.length} công ty',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
