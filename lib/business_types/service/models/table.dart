import 'package:flutter/material.dart';
import '../../../../../../../../../../core/theme/app_colors.dart';

/// Table Status Enum
enum TableStatus {
  available('available', 'Trống', AppColors.success, Icons.check_circle),
  occupied('occupied', 'Đang chơi', AppColors.error, Icons.sports_esports),
  reserved('reserved', 'Đã đặt', AppColors.warning, Icons.bookmark),
  maintenance('maintenance', 'Bảo trì', Color(0xFF6B7280), Icons.build),
  cleaning('cleaning', 'Dọn dẹp', AppColors.primary, Icons.cleaning_services);

  const TableStatus(this.id, this.label, this.color, this.icon);

  final String id;
  final String label;
  final Color color;
  final IconData icon;
}

/// Table Type Enum
enum TableType {
  pool8('pool8', 'Pool 8 bi', '8-Ball Pool', 150000),
  pool9('pool9', 'Pool 9 bi', '9-Ball Pool', 180000),
  snooker('snooker', 'Snooker', 'Snooker Table', 250000),
  carom('carom', 'Carom', 'Carom Billiards', 200000);

  const TableType(this.id, this.displayName, this.fullName, this.hourlyRate);

  final String id;
  final String displayName;
  final String fullName;
  final int hourlyRate; // VND per hour
}

class BilliardsTable {
  final String id;
  final String tableNumber;
  final String companyId;
  final TableStatus status;
  final String? tableType;
  final double hourlyRate;
  final DateTime? startTime;
  final double? currentAmount;
  final String? customerName;
  final String? notes;
  final String? currentSessionId;

  const BilliardsTable({
    required this.id,
    required this.tableNumber,
    required this.companyId,
    required this.status,
    this.tableType,
    this.hourlyRate = 50000,
    this.startTime,
    this.currentAmount,
    this.customerName,
    this.notes,
    this.currentSessionId,
  });

  String get name => 'Bàn $tableNumber';

  String get typeLabel {
    switch (tableType?.toUpperCase()) {
      case 'POOL':
        return 'Pool (8-Ball)';
      case 'LO':
        return 'Lỗ (9-Ball)';
      case 'CAROM':
        return 'Carom';
      case 'SNOOKER':
        return 'Snooker';
      default:
        return tableType ?? 'Pool';
    }
  }

  BilliardsTable copyWith({
    String? id,
    String? tableNumber,
    String? companyId,
    TableStatus? status,
    String? tableType,
    double? hourlyRate,
    DateTime? startTime,
    double? currentAmount,
    String? customerName,
    String? notes,
    String? currentSessionId,
  }) {
    return BilliardsTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      tableType: tableType ?? this.tableType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      startTime: startTime ?? this.startTime,
      currentAmount: currentAmount ?? this.currentAmount,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }

  Duration? get playingDuration {
    if (startTime == null) return null;
    return DateTime.now().difference(startTime!);
  }

  String get playingTimeFormatted {
    final duration = playingDuration;
    if (duration == null) return '--:--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
