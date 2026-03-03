import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Prompts Management Page
class AIPromptsPage extends ConsumerWidget {
  const AIPromptsPage({super.key});

  static const _defaultPrompts = [
    {'title': 'Phân tích doanh thu', 'prompt': 'Phân tích doanh thu tháng này so với tháng trước', 'category': 'Báo cáo'},
    {'title': 'Top khách hàng', 'prompt': 'Liệt kê top 10 khách hàng mua nhiều nhất', 'category': 'Khách hàng'},
    {'title': 'Tồn kho thấp', 'prompt': 'Sản phẩm nào sắp hết hàng?', 'category': 'Kho'},
    {'title': 'Công nợ quá hạn', 'prompt': 'Khách hàng nào có công nợ quá hạn?', 'category': 'Tài chính'},
    {'title': 'Hiệu suất NV', 'prompt': 'Hiệu suất nhân viên bán hàng tuần này', 'category': 'Nhân sự'},
    {'title': 'Giao hàng hôm nay', 'prompt': 'Tổng hợp tình hình giao hàng hôm nay', 'category': 'Vận hành'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Prompt mẫu',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 4),
        Text(
          'Sử dụng các câu hỏi mẫu để hỏi AI trợ lý',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        ..._defaultPrompts.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              radius: 18,
              child: Icon(Icons.auto_awesome, size: 18, color: Colors.indigo.shade400),
            ),
            title: Text(p['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(p['prompt']!, style: const TextStyle(fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p['category']!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã copy: ${p['prompt']}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        )),
      ],
    );
  }
}
