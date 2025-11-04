import 'package:flutter/material.dart';

class QuickAddCompanyModal extends StatefulWidget {
  const QuickAddCompanyModal({super.key});

  @override
  State<QuickAddCompanyModal> createState() => _QuickAddCompanyModalState();
}

class _QuickAddCompanyModalState extends State<QuickAddCompanyModal> {
  String? selectedTemplate;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String selectedSize = 'Vừa';

  final List<CompanyTemplate> templates = [
    CompanyTemplate(
      id: 'billiards',
      icon: '🎱',
      name: 'Quán Billiards',
      category: 'Giải trí & Thể thao',
      suggestedArea: '200-500m²',
      suggestedStaff: '3-8 người',
      suggestedCapital: '500tr - 2 tỷ',
      color: Colors.green,
    ),
    CompanyTemplate(
      id: 'cafe',
      icon: '☕',
      name: 'Quán Café',
      category: 'Ăn uống & Giải trí',
      suggestedArea: '50-200m²',
      suggestedStaff: '2-6 người',
      suggestedCapital: '200tr - 1 tỷ',
      color: Colors.brown,
    ),
    CompanyTemplate(
      id: 'restaurant',
      icon: '🍜',
      name: 'Nhà hàng',
      category: 'Ăn uống',
      suggestedArea: '100-400m²',
      suggestedStaff: '5-15 người',
      suggestedCapital: '500tr - 3 tỷ',
      color: Colors.red,
    ),
    CompanyTemplate(
      id: 'retail',
      icon: '🛒',
      name: 'Cửa hàng bán lẻ',
      category: 'Bán lẻ',
      suggestedArea: '30-150m²',
      suggestedStaff: '2-8 người',
      suggestedCapital: '100tr - 1 tỷ',
      color: Colors.blue,
    ),
    CompanyTemplate(
      id: 'office',
      icon: '💼',
      name: 'Văn phòng/Dịch vụ',
      category: 'Dịch vụ',
      suggestedArea: '50-300m²',
      suggestedStaff: '3-20 người',
      suggestedCapital: '200tr - 2 tỷ',
      color: Colors.purple,
    ),
    CompanyTemplate(
      id: 'manufacturing',
      icon: '🏭',
      name: 'Sản xuất',
      category: 'Sản xuất',
      suggestedArea: '500-2000m²',
      suggestedStaff: '10-50 người',
      suggestedCapital: '2 tỷ - 10 tỷ',
      color: Colors.orange,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.9; // 90% of screen height
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: maxHeight,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTemplateSelection(),
                      if (selectedTemplate != null) ...[
                        const SizedBox(height: 20),
                        _buildQuickForm(),
                      ],
                    ],
                  ),
                ),
              ),
              if (selectedTemplate != null) ...[
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.flash_on, color: Colors.orange, size: 28),
        const SizedBox(width: 8),
        const Text(
          'Thêm công ty nhanh',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTemplateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn loại hình kinh doanh:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: templates.map((template) {
            final isSelected = selectedTemplate == template.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTemplate = template.id;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? template.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? template.color.withOpacity(0.1) : null,
                ),
                child: Column(
                  children: [
                    Text(
                      template.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? template.color : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickForm() {
    final template = templates.firstWhere((t) => t.id == selectedTemplate);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: template.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: template.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${template.icon} ${template.name}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: template.color,
            ),
          ),
          const SizedBox(height: 12),
          
          // Thông tin gợi ý
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildInfoRow('📊 Loại hình:', template.category),
                _buildInfoRow('📐 Diện tích:', template.suggestedArea),
                _buildInfoRow('👥 Nhân viên:', template.suggestedStaff),
                _buildInfoRow('💰 Vốn:', template.suggestedCapital),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Form nhập liệu
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên ${template.name.toLowerCase()}',
              hintText: 'VD: Billiards Golden Club',
              border: const OutlineInputBorder(),
              prefixIcon: Text(template.icon, style: const TextStyle(fontSize: 20)),
              prefixIconConstraints: const BoxConstraints(minWidth: 50),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Địa chỉ',
              hintText: 'VD: 123 Nguyễn Văn A, Q1, TP.HCM',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),
          
          // Chọn quy mô
          Row(
            children: [
              const Text('Quy mô: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              ...['Nhỏ', 'Vừa', 'Lớn'].map((size) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(size),
                    selected: selectedSize == size,
                    selectedColor: template.color.withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedSize = size;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _canSubmit() ? _submitQuickAdd : null,
            icon: const Icon(Icons.flash_on),
            label: const Text('Thêm nhanh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getSelectedTemplate()?.color,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  bool _canSubmit() {
    return selectedTemplate != null && 
           _nameController.text.isNotEmpty && 
           _addressController.text.isNotEmpty;
  }

  CompanyTemplate? _getSelectedTemplate() {
    if (selectedTemplate == null) return null;
    return templates.firstWhere((t) => t.id == selectedTemplate);
  }

  void _submitQuickAdd() {
    final template = _getSelectedTemplate()!;
    
    // Create company data to return
    final companyData = {
      'name': _nameController.text,
      'type': template.name,
      'icon': _getIconForTemplate(template.id),
      'color': template.color,
      'address': _addressController.text,
      'employees': _getEstimatedEmployees(selectedSize),
      'tables': _getEstimatedTables(selectedSize),
      'status': 'Hoạt động',
      'revenue': '0M', // New company starts with 0 revenue
      'size': selectedSize,
      'category': template.category,
    };
    
    Navigator.pop(context, companyData);
  }

  IconData _getIconForTemplate(String templateId) {
    switch (templateId) {
      case 'billiards':
        return Icons.sports_bar;
      case 'cafe':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'retail':
        return Icons.store;
      case 'office':
        return Icons.business;
      case 'manufacturing':
        return Icons.factory;
      default:
        return Icons.business;
    }
  }

  int _getEstimatedEmployees(String size) {
    switch (size) {
      case 'Nhỏ':
        return 3;
      case 'Vừa':
        return 8;
      case 'Lớn':
        return 15;
      default:
        return 5;
    }
  }

  int _getEstimatedTables(String size) {
    switch (size) {
      case 'Nhỏ':
        return 10;
      case 'Vừa':
        return 20;
      case 'Lớn':
        return 35;
      default:
        return 15;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class CompanyTemplate {
  final String id;
  final String icon;
  final String name;
  final String category;
  final String suggestedArea;
  final String suggestedStaff;
  final String suggestedCapital;
  final Color color;

  CompanyTemplate({
    required this.id,
    required this.icon,
    required this.name,
    required this.category,
    required this.suggestedArea,
    required this.suggestedStaff,
    required this.suggestedCapital,
    required this.color,
  });
}