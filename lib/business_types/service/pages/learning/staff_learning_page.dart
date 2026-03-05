import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Staff Learning Page — Wisey inspired micro-learning library
/// Static content page with categorized learning materials
class StaffLearningPage extends StatefulWidget {
  const StaffLearningPage({super.key});

  @override
  State<StaffLearningPage> createState() => _StaffLearningPageState();
}

class _StaffLearningPageState extends State<StaffLearningPage> {
  int _selectedCategory = 0;

  final List<_LearningCategory> _categories = [
    _LearningCategory(
      icon: '🎱',
      label: 'Kỹ năng',
      color: AppColors.info,
      materials: [
        _LearningMaterial(
          title: 'Cách phục vụ khách hàng billiards chuyên nghiệp',
          duration: '5 phút đọc',
          icon: Icons.article_outlined,
          tag: 'Dịch vụ',
          tagColor: AppColors.info,
        ),
        _LearningMaterial(
          title: 'Kỹ thuật bảo trì bàn bida chuẩn 9-ball',
          duration: '8 phút đọc',
          icon: Icons.build_outlined,
          tag: 'Kỹ thuật',
          tagColor: AppColors.paymentRefunded,
        ),
        _LearningMaterial(
          title: 'Xử lý phàn nàn khách hàng — LEAP framework',
          duration: '6 phút đọc',
          icon: Icons.support_agent_outlined,
          tag: 'Dịch vụ',
          tagColor: AppColors.info,
        ),
        _LearningMaterial(
          title: 'Quy trình mở/đóng ca đúng chuẩn',
          duration: '4 phút đọc',
          icon: Icons.timer_outlined,
          tag: 'Quy trình',
          tagColor: AppColors.success,
        ),
      ],
    ),
    _LearningCategory(
      icon: '🏆',
      label: 'Phát triển',
      color: AppColors.warning,
      materials: [
        _LearningMaterial(
          title: 'Kỹ năng làm việc nhóm hiệu quả',
          duration: '7 phút đọc',
          icon: Icons.people_outlined,
          tag: 'Kỹ năng mềm',
          tagColor: AppColors.warning,
        ),
        _LearningMaterial(
          title: 'Quản lý thời gian trong ca làm việc',
          duration: '5 phút đọc',
          icon: Icons.access_time_outlined,
          tag: 'Hiệu quả',
          tagColor: AppColors.error,
        ),
        _LearningMaterial(
          title: 'Giao tiếp tích cực với đồng nghiệp',
          duration: '6 phút đọc',
          icon: Icons.chat_bubble_outline,
          tag: 'Kỹ năng mềm',
          tagColor: AppColors.warning,
        ),
      ],
    ),
    _LearningCategory(
      icon: '⚡',
      label: 'Tập trung',
      color: AppColors.success,
      materials: [
        _LearningMaterial(
          title: 'Kỹ thuật Pomodoro — làm việc sâu 25 phút',
          duration: '4 phút đọc',
          icon: Icons.timer,
          tag: 'Focus',
          tagColor: AppColors.success,
        ),
        _LearningMaterial(
          title: 'Kiểm soát căng thẳng trong giờ cao điểm',
          duration: '6 phút đọc',
          icon: Icons.self_improvement,
          tag: 'Sức khỏe',
          tagColor: AppColors.paymentRefunded,
        ),
        _LearningMaterial(
          title: '5 thói quen buổi sáng tăng năng suất',
          duration: '5 phút đọc',
          icon: Icons.wb_sunny_outlined,
          tag: 'Thói quen',
          tagColor: AppColors.error,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final category = _categories[_selectedCategory];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.textPrimary, Color(0xFF334155)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📚 Thư viện học',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Học 5-10 phút mỗi ca — tiến bộ mỗi ngày',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.surface.withAlpha(178),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Daily tip banner
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.surface.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip hôm nay',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '"Mỉm cười là dịch vụ miễn phí mà khách hàng luôn nhớ nhất."',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.surface.withAlpha(204),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category tabs
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: _categories.asMap().entries.map((e) {
                  final i = e.key;
                  final cat = e.value;
                  final isSelected = i == _selectedCategory;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _categories.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withAlpha(25)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? cat.color : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(cat.icon,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected ? cat.color : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Materials list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: category.materials.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final material = category.materials[index];
                  return _buildMaterialCard(context, material);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, _LearningMaterial material) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📖 Đang mở: ${material.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _categories[_selectedCategory].color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                material.icon,
                color: _categories[_selectedCategory].color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: material.tagColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          material.tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: material.tagColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                        material.duration,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _LearningCategory {
  final String icon;
  final String label;
  final Color color;
  final List<_LearningMaterial> materials;

  const _LearningCategory({
    required this.icon,
    required this.label,
    required this.color,
    required this.materials,
  });
}

class _LearningMaterial {
  final String title;
  final String duration;
  final IconData icon;
  final String tag;
  final Color tagColor;

  const _LearningMaterial({
    required this.title,
    required this.duration,
    required this.icon,
    required this.tag,
    required this.tagColor,
  });
}
