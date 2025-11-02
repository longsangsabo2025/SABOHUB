import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// DEV ONLY - Role Switcher for quick testing
/// Remove this in production!
class DevRoleSwitcher extends ConsumerWidget {
  const DevRoleSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      return Positioned(
        bottom: 80,
        right: 16,
        child: FloatingActionButton(
          heroTag: 'dev_role_switcher',
          mini: true,
          backgroundColor: Colors.purple.shade700,
          onPressed: () => _showRoleSelector(context),
          child: const Icon(Icons.switch_account, size: 20),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showRoleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.engineering, color: Colors.purple.shade700),
                    const SizedBox(width: 12),
                    const Text(
                      'DEV MODE - Switch Role',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEBUG',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Role buttons
              _buildRoleButton(
                context,
                icon: Icons.business_center,
                title: 'CEO',
                subtitle: 'View all companies & analytics',
                color: Colors.blue,
                route: '/',
                roleIndex: 0,
              ),
              _buildRoleButton(
                context,
                icon: Icons.manage_accounts,
                title: 'Manager',
                subtitle: 'Manage staff & operations',
                color: Colors.green,
                route: '/',
                roleIndex: 1,
              ),
              _buildRoleButton(
                context,
                icon: Icons.supervisor_account,
                title: 'Shift Leader',
                subtitle: 'Lead team & assign tasks',
                color: Colors.orange,
                route: '/',
                roleIndex: 2,
              ),
              _buildRoleButton(
                context,
                icon: Icons.person,
                title: 'Staff',
                subtitle: 'Check-in & complete tasks',
                color: Colors.purple,
                route: '/',
                roleIndex: 3,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String route,
    required int roleIndex,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Navigate to home and trigger role change via route parameter
        context.go('/?role=$roleIndex');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
