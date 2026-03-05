import 'package:flutter/material.dart';

/// Widget displaying location/GPS validation status for employee check-in
/// Shows whether the employee is within the allowed check-in radius of the company
class LocationStatusWidget extends StatelessWidget {
  final String? companyId;

  const LocationStatusWidget({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder - location validation to be implemented
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Vị trí: Đang kiểm tra...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
