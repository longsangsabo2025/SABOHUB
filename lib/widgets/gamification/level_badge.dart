import 'package:flutter/material.dart';

import '../../models/gamification/ceo_profile.dart';

class LevelBadge extends StatelessWidget {
  final int level;
  final double size;
  final bool showTitle;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final tier = _tierForLevel(level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tier.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: tier.colors.first.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
              ),
            ),
          ),
        ),
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              CeoLevel.titleForLevel(level),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tier.colors.first,
              ),
            ),
          ),
      ],
    );
  }

  _LevelTier _tierForLevel(int level) {
    if (level >= 100) {
      return _LevelTier([const Color(0xFFFFD700), const Color(0xFFFF6F00)], 'Huyền Thoại');
    }
    if (level >= 76) {
      return _LevelTier([const Color(0xFFFF6F00), const Color(0xFFE65100)], 'Đế Vương');
    }
    if (level >= 51) {
      return _LevelTier([const Color(0xFFAB47BC), const Color(0xFF7B1FA2)], 'Tướng Quân');
    }
    if (level >= 31) {
      return _LevelTier([const Color(0xFF26C6DA), const Color(0xFF0097A7)], 'Doanh Nhân');
    }
    if (level >= 16) {
      return _LevelTier([const Color(0xFF66BB6A), const Color(0xFF2E7D32)], 'Ông Chủ');
    }
    if (level >= 6) {
      return _LevelTier([const Color(0xFF42A5F5), const Color(0xFF1565C0)], 'Chủ Tiệm');
    }
    return _LevelTier([const Color(0xFF78909C), const Color(0xFF455A64)], 'Tân Binh');
  }
}

class _LevelTier {
  final List<Color> colors;
  final String title;
  const _LevelTier(this.colors, this.title);
}
