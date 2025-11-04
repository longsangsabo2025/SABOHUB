import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/navigation_models.dart';

/// Unified Bottom Navigation Widget
/// Supports all user roles with role-based item filtering
class UnifiedBottomNavigation extends ConsumerStatefulWidget {
  final UserRole userRole;
  final int currentIndex;
  final Function(int) onTap;
  final Function(String)? onRouteSelected;

  const UnifiedBottomNavigation({
    super.key,
    required this.userRole,
    required this.currentIndex,
    required this.onTap,
    this.onRouteSelected,
  });

  @override
  ConsumerState<UnifiedBottomNavigation> createState() =>
      _UnifiedBottomNavigationState();
}

class _UnifiedBottomNavigationState
    extends ConsumerState<UnifiedBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late List<NavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _navigationItems = NavigationConfig.getNavigationForRole(widget.userRole);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (index != widget.currentIndex) {
      // Haptic feedback
      HapticFeedback.lightImpact();

      // Scale animation
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });

      // Call callbacks
      widget.onTap(index);
      if (widget.onRouteSelected != null && index < _navigationItems.length) {
        widget.onRouteSelected!(_navigationItems[index].route);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Chia navigation items thành 2 hàng
    final itemsPerRow = (_navigationItems.length / 2).ceil();
    final firstRowItems = _navigationItems.take(itemsPerRow).toList();
    final secondRowItems = _navigationItems.skip(itemsPerRow).toList();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng 1
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: firstRowItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = index == widget.currentIndex;

                    return Expanded(
                      child: _NavigationButton(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => _handleTap(index),
                        scaleController: _scaleController,
                        theme: theme,
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Divider mỏng giữa 2 hàng
              if (secondRowItems.isNotEmpty)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              // Hàng 2
              if (secondRowItems.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: secondRowItems.asMap().entries.map((entry) {
                      final index = entry.key + firstRowItems.length;
                      final item = entry.value;
                      final isSelected = index == widget.currentIndex;

                      return Expanded(
                        child: _NavigationButton(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => _handleTap(index),
                          scaleController: _scaleController,
                          theme: theme,
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation button
class _NavigationButton extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final AnimationController scaleController;
  final ThemeData theme;

  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.scaleController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? 1.0 + (scaleController.value * 0.1) : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected && item.activeIcon != null
                              ? item.activeIcon!
                              : item.icon,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                      // Badge
                      if (item.badge != null && item.badge! > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.badge!.toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onError,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Label
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
