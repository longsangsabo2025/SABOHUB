import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sabohub/pages/ceo/ceo_dashboard_page.dart';
import 'package:sabohub/pages/ceo/ceo_notifications_page.dart';
import 'package:sabohub/pages/ceo/ceo_profile_page.dart';

void main() {
  runApp(const ProviderScope(child: HeaderFeaturesTestApp()));
}

class HeaderFeaturesTestApp extends StatelessWidget {
  const HeaderFeaturesTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CEO Header Features Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HeaderFeaturesTestHome(),
    );
  }
}

class HeaderFeaturesTestHome extends StatelessWidget {
  const HeaderFeaturesTestHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CEO Header Features Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test các tính năng header đã phát triển:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CEODashboardPage(),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('CEO Dashboard (với header mới)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CEONotificationsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Trang Thông báo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CEOProfilePage(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('Trang Hồ sơ cá nhân'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tính năng đã phát triển:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Nút thông báo với badge hiển thị số lượng\n'
                      '• Trang thông báo với mock data đầy đủ\n'
                      '• Nút profile với trang hồ sơ chi tiết\n'
                      '• Tính năng chỉnh sửa thông tin cá nhân\n'
                      '• Cài đặt tài khoản và bảo mật',
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
