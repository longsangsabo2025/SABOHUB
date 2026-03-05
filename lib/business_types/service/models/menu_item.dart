import 'package:flutter/material.dart';
import 'package:flutter_sabohub/core/theme/app_colors.dart';

enum MenuCategory {
  food('Món ăn', Icons.restaurant_menu, AppColors.success),
  drink('Đồ uống', Icons.local_cafe, AppColors.info),
  snack('Snack', Icons.cookie, AppColors.warning),
  other('Khác', Icons.shopping_basket, AppColors.primary);

  final String label;
  final IconData icon;
  final Color color;
  const MenuCategory(this.label, this.icon, this.color);
}

class MenuItem {
  final String id;
  final String name;
  final MenuCategory category;
  final double price;
  final String? description;
  final String? imageUrl;
  final bool isAvailable;
  final String companyId;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description,
    this.imageUrl,
    this.isAvailable = true,
    required this.companyId,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    MenuCategory? category,
    double? price,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    String? companyId,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      companyId: companyId ?? this.companyId,
    );
  }
}
