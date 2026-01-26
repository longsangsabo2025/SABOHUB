import 'package:flutter/material.dart';

/// Store Visit Form Screen - Offline-capable visit recording
/// TODO: Requires image_picker package to be added to pubspec.yaml
class StoreVisitFormScreen extends StatelessWidget {
  final String customerId;
  final String? checklistId;

  const StoreVisitFormScreen({
    super.key,
    required this.customerId,
    this.checklistId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi nhận thăm viếng'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Chức năng chụp ảnh đang phát triển',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Tính năng ghi nhận thăm viếng với hình ảnh sẽ được cập nhật trong phiên bản tiếp theo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Customer ID: $customerId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
