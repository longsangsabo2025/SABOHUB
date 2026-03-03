import 'package:flutter/material.dart';

/// Placeholder widget for Manufacturing pages while DB tables don't exist yet.
/// Shows a friendly "Coming Soon / Đang phát triển" screen instead of crashing.
class ManufacturingComingSoon extends StatelessWidget {
  /// Optional label to describe which feature is coming.
  final String? featureLabel;

  const ManufacturingComingSoon({super.key, this.featureLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Đang phát triển',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              featureLabel ?? 'Tính năng sản xuất sẽ sớm ra mắt',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Manufacturing module — Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
