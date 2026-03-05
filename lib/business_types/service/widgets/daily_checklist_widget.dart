import 'package:flutter_sabohub/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../constants/roles.dart';
import 'package:flutter_sabohub/core/theme/color_scheme_extension.dart';

/// Daily Staff Checklist — Wisey inspired
/// Role-based checklist persisted in session memory
/// Each item checked earns a virtual "streak" display
class DailyChecklistWidget extends ConsumerStatefulWidget {
  const DailyChecklistWidget({super.key});

  @override
  ConsumerState<DailyChecklistWidget> createState() =>
      _DailyChecklistWidgetState();
}

class _DailyChecklistWidgetState extends ConsumerState<DailyChecklistWidget> {
  late List<_ChecklistItem> _items;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _items = [];
  }

  String get _todayKey {
    final user = ref.read(currentUserProvider);
    final uid = user?.id ?? 'anon';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return 'checklist_${uid}_$today';
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final boolList = _items.map((i) => i.isCompleted).toList();
    await prefs.setString(_todayKey, jsonEncode(boolList));
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_todayKey);
    if (saved != null && mounted) {
      final boolList = List<bool>.from(jsonDecode(saved));
      setState(() {
        for (var i = 0; i < _items.length && i < boolList.length; i++) {
          _items[i].isCompleted = boolList[i];
        }
      });
    }
  }

  List<_ChecklistItem> _buildItemsForRole(SaboRole role) {
    switch (role) {
      case SaboRole.staff:
        return [
          _ChecklistItem('Vệ sinh bàn billiards và khu vực chơi'),
          _ChecklistItem('Kiểm tra đủ cơ, bi, phấn trên mỗi bàn'),
          _ChecklistItem('Mở ca: điểm danh và nhận bàn giao'),
          _ChecklistItem('Ghi log doanh thu khai thác đầu ca'),
          _ChecklistItem('Báo cáo sự cố thiết bị (nếu có)'),
        ];
      case SaboRole.driver:
        return [
          _ChecklistItem('Kiểm tra phương tiện trước khi xuất phát'),
          _ChecklistItem('Nhận đơn giao hàng từ quản lý'),
          _ChecklistItem('Xác nhận địa chỉ giao hàng đầu ca'),
          _ChecklistItem('Ghi nhận tình trạng hàng hóa khi nhận'),
          _ChecklistItem('Cập nhật trạng thái giao hàng cuối ca'),
        ];
      case SaboRole.warehouse:
        return [
          _ChecklistItem('Kiểm tra tồn kho đầu ngày'),
          _ChecklistItem('Xử lý phiếu nhập/xuất kho tồn đọng'),
          _ChecklistItem('Sắp xếp khu vực lưu trữ gọn gàng'),
          _ChecklistItem('Kiểm tra hạn sử dụng (thực phẩm/đồ uống)'),
          _ChecklistItem('Lập báo cáo tồn kho cuối ca'),
        ];
      case SaboRole.shiftLeader:
        return [
          _ChecklistItem('Nhận bàn giao từ ca trước'),
          _ChecklistItem('Phân công nhiệm vụ nhân viên đầu ca'),
          _ChecklistItem('Kiểm tra KPI bàn và doanh thu tuần'),
          _ChecklistItem('Xử lý phản hồi khách hàng (nếu có)'),
          _ChecklistItem('Báo cáo nhanh quan sát ca cho quản lý'),
        ];
      default:
        return [
          _ChecklistItem('Check in đúng giờ'),
          _ChecklistItem('Hoàn thành nhiệm vụ được giao'),
          _ChecklistItem('Báo cáo cuối ngày'),
        ];
    }
  }

  int get _completedCount => _items.where((i) => i.isCompleted).length;
  double get _progress => _items.isEmpty ? 0 : _completedCount / _items.length;

  Color get _progressColor {
    if (_progress >= 1.0) return AppColors.success;
    if (_progress >= 0.6) return AppColors.info;
    if (_progress >= 0.3) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    if (!_initialized) {
      _items = _buildItemsForRole(user.role);
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadState());
    }

    final isAllDone = _completedCount == _items.length;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isAllDone
            ? Border.all(color: AppColors.success, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _progressColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAllDone ? Icons.emoji_events : Icons.checklist_rtl,
                    color: _progressColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checklist hôm nay',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_completedCount/${_items.length} hoàn thành',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAllDone)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text(
                          'Xuất sắc!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade100,
                color: _progressColor,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Checklist items
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _items.length - 1;
            return InkWell(
              onTap: () {
                setState(() => item.isCompleted = !item.isCompleted);
                _saveState();
              },
              borderRadius: isLast
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    )
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: item.isCompleted
                            ? _progressColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: item.isCompleted
                              ? _progressColor
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: item.isCompleted
                          ? Icon(Icons.check,
                              color: Theme.of(context).colorScheme.surface, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.isCompleted
                              ? Colors.grey.shade400
                              : Theme.of(context).colorScheme.onSurface87,
                          decoration: item.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ChecklistItem {
  final String title;
  bool isCompleted = false;

  _ChecklistItem(this.title);
}
