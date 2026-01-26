import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/navigation/navigation_models.dart';

/// Grouped Navigation Drawer for CEO/Manager roles
class GroupedNavigationDrawer extends StatefulWidget {
  final UserRole userRole;
  final String currentRoute;

  const GroupedNavigationDrawer({
    super.key,
    required this.userRole,
    required this.currentRoute,
  });

  @override
  State<GroupedNavigationDrawer> createState() =>
      _GroupedNavigationDrawerState();
}

class _GroupedNavigationDrawerState extends State<GroupedNavigationDrawer> {
  final Set<String> _expandedGroups = {};

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationConfig.getNavigationForRole(widget.userRole);
    final theme = Theme.of(context);

    return Drawer(
      child: Column(
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'SABOHUB',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRoleLabel(widget.userRole),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navigation.length,
              itemBuilder: (context, index) {
                final navBase = navigation[index];

                if (navBase is SingleNav) {
                  return _buildNavItem(context, navBase.item);
                } else if (navBase is GroupNav) {
                  return _buildNavGroup(context, navBase.group);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavigationItem item) {
    final isActive = widget.currentRoute == item.route;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        isActive ? (item.activeIcon ?? item.icon) : item.icon,
        color: isActive ? theme.colorScheme.primary : null,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? theme.colorScheme.primary : null,
        ),
      ),
      selected: isActive,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      onTap: () {
        context.go(item.route);
        Navigator.pop(context); // Close drawer
      },
    );
  }

  Widget _buildNavGroup(BuildContext context, NavigationGroup group) {
    final isExpanded = _expandedGroups.contains(group.title);
    final hasActiveItem = group.items.any((item) => item.route == widget.currentRoute);
    final theme = Theme.of(context);

    return Column(
      children: [
        ListTile(
          leading: Icon(
            group.icon,
            color: hasActiveItem ? theme.colorScheme.primary : null,
          ),
          title: Text(
            group.title,
            style: TextStyle(
              fontWeight: hasActiveItem ? FontWeight.bold : FontWeight.w600,
              color: hasActiveItem ? theme.colorScheme.primary : null,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedGroups.remove(group.title);
              } else {
                _expandedGroups.add(group.title);
              }
            });
          },
        ),
        if (isExpanded)
          ...group.items.map((item) {
            final isActive = widget.currentRoute == item.route;

            return Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ListTile(
                leading: Icon(
                  isActive ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 20,
                  color: isActive ? theme.colorScheme.primary : null,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? theme.colorScheme.primary : null,
                  ),
                ),
                selected: isActive,
                selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
                onTap: () {
                  context.go(item.route);
                  Navigator.pop(context); // Close drawer
                },
              ),
            );
          }).toList(),
        const Divider(height: 1),
      ],
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.ceo:
        return 'CEO';
      case UserRole.manager:
        return 'Quản lý';
      case UserRole.shiftLeader:
        return 'Ca trưởng';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.driver:
        return 'Tài xế';
      case UserRole.warehouse:
        return 'Nhân viên kho';
    }
  }
}
