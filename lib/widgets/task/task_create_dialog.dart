import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/management_task.dart';
import '../../core/theme/app_colors.dart';

// =============================================================================
// UNIFIED TASK CREATE/EDIT DIALOG — ONE dialog replacing 6 duplicate dialogs
// Lean, fast, no wizard bloat. Fields that matter, nothing else.
// Now with GROUPED TASK TEMPLATES + Media Channel picker!
// =============================================================================

/// Task Template — pre-fills ALL form fields for common workflows
class _TaskTemplate {
  final String name;
  final String icon;
  final String title; // can contain {channel} placeholder
  final String description; // can contain {channel} placeholder
  final TaskCategory category;
  final TaskPriority priority;
  final int dueDays;
  final List<String> checklist;
  final bool isMediaRelated; // needs media channel picker

  const _TaskTemplate({
    required this.name,
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.dueDays,
    required this.checklist,
    this.isMediaRelated = false,
  });
}

/// Template Group — organized by domain
class _TemplateGroup {
  final String name;
  final String icon;
  final Color color;
  final List<_TaskTemplate> templates;

  const _TemplateGroup({
    required this.name,
    required this.icon,
    required this.color,
    required this.templates,
  });
}

/// Grouped templates for organized display
final List<_TemplateGroup> _templateGroups = [
  // ═══ MEDIA & CONTENT ═══
  _TemplateGroup(
    name: 'Media & Content',
    icon: '🎬',
    color: const Color(0xFF7C3AED), // purple
    templates: [
      const _TaskTemplate(
        name: 'Video TikTok',
        icon: '🎬',
        title: 'Sản xuất Video TikTok — {channel}',
        description: 'Quay & edit video ngắn cho kênh {channel}. Theo trend hiện tại, đảm bảo nội dung hấp dẫn, đúng brand.',
        category: TaskCategory.videoProduction,
        priority: TaskPriority.high,
        dueDays: 3,
        isMediaRelated: true,
        checklist: [
          'Lên kịch bản / ý tưởng nội dung',
          'Chuẩn bị thiết bị & địa điểm quay',
          'Quay video',
          'Edit / hậu kỳ',
          'Duyệt nội dung (CEO/Manager)',
          'Upload lên kênh & tối ưu hashtag',
        ],
      ),
      const _TaskTemplate(
        name: 'Video YouTube',
        icon: '▶️',
        title: 'Sản xuất Video YouTube — {channel}',
        description: 'Sản xuất video dài cho kênh {channel}. Chất lượng cao, intro/outro, thumbnail chuyên nghiệp.',
        category: TaskCategory.videoProduction,
        priority: TaskPriority.high,
        dueDays: 7,
        isMediaRelated: true,
        checklist: [
          'Nghiên cứu chủ đề & SEO keyword',
          'Viết kịch bản chi tiết',
          'Setup ánh sáng & thiết bị quay',
          'Quay video',
          'Edit / hậu kỳ + subtitle',
          'Thiết kế thumbnail',
          'Duyệt nội dung (CEO/Manager)',
          'Upload & tối ưu SEO',
        ],
      ),
      const _TaskTemplate(
        name: 'Reels / Shorts',
        icon: '📱',
        title: 'Sản xuất Reels/Shorts — {channel}',
        description: 'Video ngắn dọc (< 60s) cho kênh {channel}. Format Reels/Shorts, viral-ready.',
        category: TaskCategory.videoProduction,
        priority: TaskPriority.medium,
        dueDays: 2,
        isMediaRelated: true,
        checklist: [
          'Chọn trend / hook hấp dẫn',
          'Quay video dọc (9:16)',
          'Edit nhanh + text overlay + âm nhạc',
          'Duyệt nội dung',
          'Upload lên kênh',
        ],
      ),
      const _TaskTemplate(
        name: 'Chụp ảnh SP',
        icon: '📸',
        title: 'Chụp ảnh sản phẩm — {channel}',
        description: 'Chụp ảnh sản phẩm/không gian cho kênh {channel}. Dùng cho post MXH, quảng cáo.',
        category: TaskCategory.media,
        priority: TaskPriority.medium,
        dueDays: 3,
        isMediaRelated: true,
        checklist: [
          'Lên danh sách sản phẩm cần chụp',
          'Chuẩn bị setup (background, ánh sáng)',
          'Chụp ảnh',
          'Retouch / chỉnh sửa ảnh',
          'Duyệt & chọn ảnh final',
          'Upload thư viện ảnh',
        ],
      ),
      const _TaskTemplate(
        name: 'Thiết kế đồ họa',
        icon: '🎨',
        title: 'Thiết kế đồ họa — {channel}',
        description: 'Thiết kế banner, poster, ảnh bìa cho kênh {channel}. Đúng brand guideline.',
        category: TaskCategory.media,
        priority: TaskPriority.medium,
        dueDays: 3,
        isMediaRelated: true,
        checklist: [
          'Brief yêu cầu (kích thước, nội dung)',
          'Tham khảo & lên concept',
          'Thiết kế bản nháp',
          'Chỉnh sửa theo feedback',
          'Xuất file final (các format)',
        ],
      ),
    ],
  ),

  // ═══ MXH & UPLOAD ═══
  _TemplateGroup(
    name: 'MXH & Phân phối',
    icon: '📲',
    color: const Color(0xFF3B82F6), // blue
    templates: [
      const _TaskTemplate(
        name: 'Upload MXH tuần',
        icon: '📲',
        title: 'Upload nội dung MXH tuần — {channel}',
        description: 'Đăng tải nội dung tuần lên kênh {channel}. Tối ưu SEO, hashtag, caption.',
        category: TaskCategory.socialMedia,
        priority: TaskPriority.medium,
        dueDays: 2,
        isMediaRelated: true,
        checklist: [
          'Chuẩn bị nội dung (video/ảnh/caption)',
          'Tối ưu caption & hashtag',
          'Đăng bài theo lịch',
          'Tương tác comment & DM',
          'Theo dõi số liệu (views/likes)',
          'Báo cáo kết quả tuần',
        ],
      ),
      const _TaskTemplate(
        name: 'Content Calendar tháng',
        icon: '📅',
        title: 'Lên kế hoạch Content tháng — {channel}',
        description: 'Xây dựng lịch đăng bài tháng cho kênh {channel}. Phân bổ theo chủ đề, trend, sự kiện.',
        category: TaskCategory.socialMedia,
        priority: TaskPriority.medium,
        dueDays: 5,
        isMediaRelated: true,
        checklist: [
          'Phân tích hiệu quả tháng trước',
          'Nghiên cứu trend & đối thủ',
          'Lên lịch content calendar',
          'Chuẩn bị nội dung (ảnh/video/text)',
          'Duyệt kế hoạch với CEO',
          'Triển khai theo lịch',
          'Báo cáo kết quả cuối tháng',
        ],
      ),
    ],
  ),

  // ═══ MARKETING ═══
  _TemplateGroup(
    name: 'Marketing',
    icon: '📢',
    color: const Color(0xFFF59E0B), // amber
    templates: [
      const _TaskTemplate(
        name: 'Chiến dịch Marketing',
        icon: '📢',
        title: 'Triển khai chiến dịch Marketing',
        description: 'Lên kế hoạch và thực thi chiến dịch marketing. Đo lường ROI và hiệu quả.',
        category: TaskCategory.marketing,
        priority: TaskPriority.high,
        dueDays: 14,
        checklist: [
          'Phân tích thị trường & đối thủ',
          'Lên chiến lược marketing',
          'Thiết kế tài liệu (banner/poster)',
          'Triển khai chiến dịch',
          'Đo lường hiệu quả & báo cáo',
        ],
      ),
      const _TaskTemplate(
        name: 'Tổ chức sự kiện',
        icon: '🎪',
        title: 'Tổ chức sự kiện',
        description: 'Lên kế hoạch và tổ chức sự kiện từ A-Z. Chuẩn bị địa điểm, khách mời, chương trình.',
        category: TaskCategory.eventPlanning,
        priority: TaskPriority.critical,
        dueDays: 30,
        checklist: [
          'Lên kế hoạch & timeline sự kiện',
          'Chuẩn bị địa điểm & thiết bị',
          'Liên hệ khách mời / đối tác',
          'Quảng bá sự kiện',
          'Tổ chức & điều phối ngày diễn ra',
          'Tổng kết & báo cáo sau sự kiện',
        ],
      ),
    ],
  ),

  // ═══ VẬN HÀNH ═══
  _TemplateGroup(
    name: 'Vận hành',
    icon: '⚙️',
    color: const Color(0xFF10B981), // green
    templates: [
      const _TaskTemplate(
        name: 'Vận hành ngày',
        icon: '⚙️',
        title: 'Checklist vận hành hàng ngày',
        description: 'Các bước kiểm tra & vận hành cơ bản mỗi ngày. Đảm bảo mọi thứ hoạt động trơn tru.',
        category: TaskCategory.operations,
        priority: TaskPriority.medium,
        dueDays: 1,
        checklist: [
          'Mở cửa & kiểm tra cơ sở vật chất',
          'Kiểm tra nhân sự ca làm việc',
          'Kiểm tra tồn kho & vật tư',
          'Xử lý vấn đề phát sinh',
          'Báo cáo cuối ngày',
        ],
      ),
      const _TaskTemplate(
        name: 'Bảo trì Billiards',
        icon: '🎱',
        title: 'Bảo trì bàn Billiards',
        description: 'Kiểm tra định kỳ, bảo trì thiết bị bàn chơi, thay nỉ nếu cần.',
        category: TaskCategory.billiards,
        priority: TaskPriority.medium,
        dueDays: 3,
        checklist: [
          'Kiểm tra thiết bị bàn chơi',
          'Bảo trì & thay nỉ',
          'Vệ sinh khu vực',
          'Kiểm đếm tồn kho phụ kiện',
          'Báo cáo hoàn tất',
        ],
      ),
      const _TaskTemplate(
        name: 'Báo cáo tuần',
        icon: '📊',
        title: 'Báo cáo tổng hợp tuần',
        description: 'Tổng hợp báo cáo hoạt động, doanh thu, KPI của tuần. Đánh giá và đề xuất cải thiện.',
        category: TaskCategory.general,
        priority: TaskPriority.medium,
        dueDays: 1,
        checklist: [
          'Thu thập số liệu doanh thu',
          'Tổng hợp KPI nhân viên',
          'Đánh giá hiệu quả hoạt động',
          'Ghi nhận vấn đề & đề xuất',
          'Gửi báo cáo cho CEO',
        ],
      ),
    ],
  ),

  // ═══ NHÂN SỰ ═══
  _TemplateGroup(
    name: 'Nhân sự',
    icon: '👥',
    color: const Color(0xFFEF4444), // red
    templates: [
      const _TaskTemplate(
        name: 'Tuyển dụng',
        icon: '👥',
        title: 'Tuyển dụng nhân viên mới',
        description: 'Quy trình tuyển dụng từ đăng tin đến onboarding. Đảm bảo chất lượng ứng viên.',
        category: TaskCategory.hr,
        priority: TaskPriority.medium,
        dueDays: 21,
        checklist: [
          'Đăng tuyển dụng',
          'Sàng lọc hồ sơ',
          'Phỏng vấn ứng viên',
          'Quyết định tuyển dụng',
          'Onboarding nhân viên mới',
        ],
      ),
    ],
  ),
];

/// Flatten all templates for quick lookup
List<_TaskTemplate> get _allTemplates =>
    _templateGroups.expand((g) => g.templates).toList();

/// Checklist templates per category — auto-suggested when CEO picks category
const Map<TaskCategory, List<String>> _checklistTemplates = {
  TaskCategory.videoProduction: [
    'Lên kịch bản / ý tưởng nội dung',
    'Chuẩn bị thiết bị & địa điểm quay',
    'Quay video',
    'Edit / hậu kỳ',
    'Duyệt nội dung (CEO/Manager)',
    'Xuất bản final',
  ],
  TaskCategory.socialMedia: [
    'Chuẩn bị nội dung (video/ảnh/caption)',
    'Upload lên YouTube',
    'Upload lên TikTok',
    'Upload lên Facebook/Instagram',
    'SEO & Hashtags',
    'Báo cáo kết quả (views/likes)',
  ],
  TaskCategory.marketing: [
    'Phân tích thị trường & đối thủ',
    'Lên chiến lược marketing',
    'Thiết kế tài liệu (banner/poster)',
    'Triển khai chiến dịch',
    'Đo lường hiệu quả & báo cáo',
  ],
  TaskCategory.eventPlanning: [
    'Lên kế hoạch & timeline sự kiện',
    'Chuẩn bị địa điểm & thiết bị',
    'Liên hệ khách mời / đối tác',
    'Quảng bá sự kiện',
    'Tổ chức & điều phối ngày diễn ra',
    'Tổng kết & báo cáo sau sự kiện',
  ],
  TaskCategory.hr: [
    'Đăng tuyển dụng',
    'Sàng lọc hồ sơ',
    'Phỏng vấn ứng viên',
    'Quyết định tuyển dụng',
    'Onboarding nhân viên mới',
  ],
  TaskCategory.billiards: [
    'Kiểm tra thiết bị bàn chơi',
    'Bảo trì & thay nỉ',
    'Vệ sinh khu vực',
    'Kiểm đếm tồn kho phụ kiện',
    'Báo cáo hoàn tất',
  ],
  TaskCategory.media: [
    'Lên brief & concept',
    'Chuẩn bị thiết bị / tài nguyên',
    'Thực hiện (chụp/thiết kế)',
    'Chỉnh sửa & duyệt',
    'Xuất file final',
  ],
};

class TaskCreateEditDialog extends StatefulWidget {
  final ManagementTask? task; // null = create mode
  final List<Map<String, dynamic>> assignees; // [{id, full_name, role?}]
  final List<Map<String, dynamic>>? companies; // [{id, name}] — CEO only
  final List<Map<String, dynamic>>? mediaChannels; // [{id, name, platform}]
  final String? defaultCompanyId;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const TaskCreateEditDialog({
    super.key,
    this.task,
    required this.assignees,
    this.companies,
    this.mediaChannels,
    this.defaultCompanyId,
    required this.onSave,
  });

  @override
  State<TaskCreateEditDialog> createState() => _TaskCreateEditDialogState();
}

class _TaskCreateEditDialogState extends State<TaskCreateEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleC;
  late final TextEditingController _descC;
  late TaskPriority _priority;
  late TaskCategory _category;
  String? _assignedTo;
  String? _companyId;
  DateTime? _dueDate;
  bool _saving = false;
  List<String> _checklistItems = [];
  Map<String, Map<String, dynamic>> _originalChecklistMap = {};
  _TaskTemplate? _appliedTemplate;
  bool _showTemplates = true;
  Map<String, dynamic>? _selectedChannel; // selected media channel
  String? _expandedGroup; // which group is expanded (null = all collapsed)

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleC = TextEditingController(text: t?.title ?? '');
    _descC = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.general;
    _assignedTo = t?.assignedTo;
    _companyId = t?.companyId ?? widget.defaultCompanyId;
    _dueDate = t?.dueDate;
    // Load existing checklist for edit mode
    if (t != null && t.checklist.isNotEmpty) {
      _checklistItems = t.checklist.map((c) => c.title).toList();
      _originalChecklistMap = {
        for (var c in t.checklist)
          c.title: {'id': c.id, 'is_done': c.isDone},
      };
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    super.dispose();
  }

  /// Apply a template — fills ALL form fields at once
  /// If template is media-related + channel selected, replaces {channel} placeholder
  void _applyTemplate(_TaskTemplate template) {
    final channelName = _selectedChannel?['name'] as String? ?? '';
    final hasChannel = channelName.isNotEmpty;

    setState(() {
      _appliedTemplate = template;
      _category = template.category;
      _priority = template.priority;
      _checklistItems = List.from(template.checklist);
      _dueDate = DateTime.now().add(Duration(days: template.dueDays));
      _showTemplates = false;

      // Fill title/description with channel name if available
      if (template.isMediaRelated && hasChannel) {
        _titleC.text = template.title.replaceAll('{channel}', channelName);
        _descC.text = template.description.replaceAll('{channel}', channelName);
      } else {
        _titleC.text = template.title.replaceAll(' — {channel}', '').replaceAll('{channel}', '');
        _descC.text = template.description.replaceAll('{channel}', '...');
      }
    });
  }

  /// Re-apply current template with new channel
  void _reapplyWithChannel() {
    if (_appliedTemplate != null && _appliedTemplate!.isMediaRelated) {
      final channelName = _selectedChannel?['name'] as String? ?? '';
      if (channelName.isNotEmpty) {
        setState(() {
          _titleC.text = _appliedTemplate!.title.replaceAll('{channel}', channelName);
          _descC.text = _appliedTemplate!.description.replaceAll('{channel}', channelName);
        });
      }
    }
  }

  /// Clear template — reset all fields
  void _clearTemplate() {
    setState(() {
      _appliedTemplate = null;
      _selectedChannel = null;
      _titleC.clear();
      _descC.clear();
      _category = TaskCategory.general;
      _priority = TaskPriority.medium;
      _checklistItems.clear();
      _dueDate = null;
    });
  }

  /// Platform icon for media channels
  IconData _platformIcon(String? platform) {
    switch (platform) {
      case 'youtube': return Icons.play_circle_fill;
      case 'tiktok': return Icons.music_note;
      case 'facebook': return Icons.facebook;
      case 'instagram': return Icons.camera_alt;
      case 'twitter': return Icons.alternate_email;
      case 'linkedin': return Icons.work;
      default: return Icons.language;
    }
  }

  Color _platformColor(String? platform) {
    switch (platform) {
      case 'youtube': return const Color(0xFFFF0000);
      case 'tiktok': return const Color(0xFF000000);
      case 'facebook': return const Color(0xFF1877F2);
      case 'instagram': return const Color(0xFFE4405F);
      case 'twitter': return const Color(0xFF1DA1F2);
      case 'linkedin': return const Color(0xFF0A66C2);
      default: return Colors.grey;
    }
  }

  /// Build the grouped template picker — sections that expand/collapse
  Widget _buildTemplatePicker() {
    final channels = widget.mediaChannels ?? [];
    final hasChannels = channels.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        GestureDetector(
          onTap: () => setState(() => _showTemplates = !_showTemplates),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _appliedTemplate != null
                        ? 'Mẫu: ${_appliedTemplate!.icon} ${_appliedTemplate!.name}'
                        : 'Chọn mẫu nhanh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (_appliedTemplate != null)
                  GestureDetector(
                    onTap: _clearTemplate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: Text('Xóa mẫu',
                          style: TextStyle(fontSize: 10, color: Colors.red[600], fontWeight: FontWeight.w500)),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  _showTemplates ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),

        // Grouped template list — collapsible
        if (_showTemplates) ...[
          const SizedBox(height: 8),

          // ── MEDIA CHANNEL PICKER (shown when templates visible & channels exist) ──
          if (hasChannels) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tv, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Text('Chọn kênh Media',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                      if (_selectedChannel != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedChannel = null),
                          child: Text('Bỏ chọn', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: channels.map((ch) {
                      final isSelected = _selectedChannel?['id'] == ch['id'];
                      final platform = ch['platform'] as String? ?? '';
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedChannel = isSelected ? null : ch);
                          // Re-apply template with new channel
                          if (!isSelected) _reapplyWithChannel();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? _platformColor(platform).withOpacity(0.12) : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? _platformColor(platform) : const Color(0xFFD1D5DB),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_platformIcon(platform), size: 13, color: _platformColor(platform)),
                              const SizedBox(width: 4),
                              Text(
                                ch['name'] as String? ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? _platformColor(platform) : const Color(0xFF374151),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 3),
                                Icon(Icons.check_circle, size: 11, color: _platformColor(platform)),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── TEMPLATE GROUPS ──
          ..._templateGroups.map((group) {
            final isExpanded = _expandedGroup == group.name;
            final hasSelectedInGroup = _appliedTemplate != null &&
                group.templates.contains(_appliedTemplate);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group header
                GestureDetector(
                  onTap: () => setState(() {
                    _expandedGroup = isExpanded ? null : group.name;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasSelectedInGroup
                          ? group.color.withOpacity(0.08)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text(group.icon, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(group.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hasSelectedInGroup ? group.color : const Color(0xFF374151),
                              )),
                        ),
                        Text('${group.templates.length}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),

                // Templates in group (collapsed = show only selected, expanded = show all)
                if (isExpanded || hasSelectedInGroup)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: group.templates
                          .where((t) => isExpanded || t == _appliedTemplate)
                          .map((t) {
                        final isSelected = _appliedTemplate == t;
                        return GestureDetector(
                          onTap: () => _applyTemplate(t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? group.color.withOpacity(0.12) : Colors.white,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: isSelected ? group.color : const Color(0xFFD1D5DB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(t.icon, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(t.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? group.color : const Color(0xFF374151),
                                    )),
                                if (t.isMediaRelated) ...[
                                  const SizedBox(width: 3),
                                  Icon(Icons.tv, size: 10, color: Colors.grey[400]),
                                ],
                                if (isSelected) ...[
                                  const SizedBox(width: 3),
                                  Icon(Icons.check_circle, size: 11, color: group.color),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 2),
              ],
            );
          }),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 480.0 : width * 0.92;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEdit ? Icons.edit_rounded : Icons.add_task_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isEdit ? 'Chỉnh sửa nhiệm vụ' : 'Tạo nhiệm vụ mới',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Template picker (create mode only)
                      if (!_isEdit) _buildTemplatePicker(),

                      // Title
                      _label('Tiêu đề *'),
                      TextFormField(
                        controller: _titleC,
                        decoration: _inputDeco('Nhập tiêu đề nhiệm vụ'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      // Description
                      _label('Mô tả'),
                      TextFormField(
                        controller: _descC,
                        decoration: _inputDeco('Mô tả chi tiết...'),
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 14),

                      // Priority + Category row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Ưu tiên'),
                                _buildPriorityPicker(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Phân loại'),
                                _buildCategoryPicker(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Assignee
                      if (widget.assignees.isNotEmpty) ...[
                        _label('Giao cho'),
                        _buildAssigneePicker(),
                        const SizedBox(height: 14),
                      ],

                      // Company (CEO only)
                      if (widget.companies != null && widget.companies!.isNotEmpty) ...[
                        _label('Công ty'),
                        _buildCompanyPicker(),
                        const SizedBox(height: 14),
                      ],

                      // Due date
                      _label('Hạn hoàn thành'),
                      _buildDueDatePicker(),
                      const SizedBox(height: 14),

                      // Checklist section
                      _buildChecklistSection(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Lưu thay đổi' : 'Tạo nhiệm vụ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildPriorityPicker() {
    return DropdownButtonFormField<TaskPriority>(
      value: _priority,
      decoration: _inputDeco(''),
      isDense: true,
      items: TaskPriority.values.map((p) {
        return DropdownMenuItem(
          value: p,
          child: Text(p.label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (v) => setState(() => _priority = v!),
    );
  }

  Widget _buildCategoryPicker() {
    return DropdownButtonFormField<TaskCategory>(
      value: _category,
      decoration: _inputDeco(''),
      isDense: true,
      items: TaskCategory.values.map((c) {
        return DropdownMenuItem(
          value: c,
          child: Text('${c.icon} ${c.label}', style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _category = v);
        // Auto-suggest checklist template for create mode
        if (!_isEdit && _checklistItems.isEmpty && _checklistTemplates.containsKey(v)) {
          _showTemplatePrompt(v);
        }
      },
    );
  }

  Widget _buildAssigneePicker() {
    return DropdownButtonFormField<String>(
      value: _assignedTo,
      decoration: _inputDeco('Chọn người thực hiện'),
      isDense: true,
      items: widget.assignees.map((a) {
        final name = a['full_name'] as String? ?? 'Unknown';
        final role = a['role'] as String? ?? '';
        return DropdownMenuItem(
          value: a['id'] as String,
          child: Text(
            role.isNotEmpty ? '$name ($role)' : name,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _assignedTo = v),
    );
  }

  Widget _buildCompanyPicker() {
    return DropdownButtonFormField<String>(
      value: _companyId,
      decoration: _inputDeco('Chọn công ty'),
      isDense: true,
      items: widget.companies!.map((c) {
        return DropdownMenuItem(
          value: c['id'] as String,
          child: Text(
            c['name'] as String? ?? '',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _companyId = v),
    );
  }

  Widget _buildDueDatePicker() {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 18, color: _dueDate != null ? AppColors.primary : const Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Text(
              _dueDate != null
                  ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                  : 'Chọn ngày...',
              style: TextStyle(
                fontSize: 13,
                color: _dueDate != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              ),
            ),
            const Spacer(),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF9CA3AF)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  // ═══ TEMPLATE PROMPT ═══
  void _showTemplatePrompt(TaskCategory cat) {
    final template = _checklistTemplates[cat];
    if (template == null) return;

    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Text(cat.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Thêm checklist "${cat.label}"?',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tự động thêm ${template.length} bước công việc:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              ...template.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontSize: 12)),
                      ),
                    ]),
                  )),
              const SizedBox(height: 8),
              Text('Bạn có thể chỉnh sửa sau khi thêm.',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bỏ qua'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _checklistItems = List.from(template));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thêm checklist'),
            ),
          ],
        ),
      );
    });
  }

  // ═══ CHECKLIST SECTION ═══
  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            _label('Checklist'),
            const Spacer(),
            if (_checklistItems.isEmpty && _checklistTemplates.containsKey(_category))
              GestureDetector(
                onTap: () => _showTemplatePrompt(_category),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('Dùng mẫu ${_category.label}',
                        style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            if (_checklistItems.isNotEmpty)
              GestureDetector(
                onTap: () => setState(() => _checklistItems.clear()),
                child: Text('Xóa hết', style: TextStyle(fontSize: 11, color: Colors.red[400])),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // Items list
        if (_checklistItems.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _checklistItems.length,
              onReorder: (old, neu) {
                setState(() {
                  if (neu > old) neu--;
                  final item = _checklistItems.removeAt(old);
                  _checklistItems.insert(neu, item);
                });
              },
              itemBuilder: (ctx, i) => Container(
                key: ValueKey('cl_$i'),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: i < _checklistItems.length - 1
                    ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)))
                    : null,
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_indicator_rounded, size: 16, color: Color(0xFF9CA3AF)),
                    ),
                    Container(
                      width: 18, height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                      ),
                    ),
                    Expanded(
                      child: Text(_checklistItems[i],
                          style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _checklistItems.removeAt(i)),
                      child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Add item button
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _addChecklistItem,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
            ),
            child: Row(
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Thêm bước', style: TextStyle(fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addChecklistItem() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Thêm bước', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Mô tả bước công việc...',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              setState(() => _checklistItems.add(v.trim()));
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) {
                setState(() => _checklistItems.add(v));
                Navigator.pop(ctx);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Thêm'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      // Build checklist JSON
      List<Map<String, dynamic>>? checklistJson;
      if (_checklistItems.isNotEmpty) {
        checklistJson = _checklistItems.asMap().entries.map((e) {
          final original = _originalChecklistMap[e.value];
          return {
            'id': original?['id'] ?? 'cl_${DateTime.now().millisecondsSinceEpoch}_${e.key}',
            'title': e.value,
            'is_done': original?['is_done'] ?? false,
          };
        }).toList();
      }

      final data = <String, dynamic>{
        'title': _titleC.text.trim(),
        'description': _descC.text.trim(),
        'priority': _priority.value,
        'category': _category.value,
        'assigned_to': _assignedTo,
        'company_id': _companyId,
        'due_date': _dueDate?.toIso8601String(),
        if (checklistJson != null) 'checklist': checklistJson,
      };

      await widget.onSave(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
