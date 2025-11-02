import 'package:flutter/material.dart';

/// Table Status Enum
enum TableStatus {
  available('available', 'Trống', Color(0xFF10B981), Icons.check_circle),
  occupied('occupied', 'Đang chơi', Color(0xFFEF4444), Icons.sports_esports),
  reserved('reserved', 'Đã đặt', Color(0xFFF59E0B), Icons.bookmark),
  maintenance('maintenance', 'Bảo trì', Color(0xFF6B7280), Icons.build),
  cleaning('cleaning', 'Dọn dẹp', Color(0xFF8B5CF6), Icons.cleaning_services);

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
  final DateTime? startTime;
  final double? currentAmount;
  final String? customerName;
  final String? notes;

  const BilliardsTable({
    required this.id,
    required this.tableNumber,
    required this.companyId,
    required this.status,
    this.startTime,
    this.currentAmount,
    this.customerName,
    this.notes,
  });

  BilliardsTable copyWith({
    String? id,
    String? tableNumber,
    String? companyId,
    TableStatus? status,
    DateTime? startTime,
    double? currentAmount,
    String? customerName,
    String? notes,
  }) {
    return BilliardsTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      companyId: companyId ?? this.companyId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      currentAmount: currentAmount ?? this.currentAmount,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
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
