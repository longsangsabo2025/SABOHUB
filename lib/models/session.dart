import 'package:flutter/material.dart';

enum SessionStatus {
  active('Đang hoạt động', Color(0xFF10B981)),
  paused('Tạm dừng', Color(0xFFF59E0B)),
  completed('Hoàn thành', Color(0xFF6B7280)),
  cancelled('Đã hủy', Color(0xFFEF4444));

  final String label;
  final Color color;
  const SessionStatus(this.label, this.color);
}

class TableSession {
  final String id;
  final String tableId;
  final String tableName;
  final String companyId;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime? pauseTime;
  final int totalPausedMinutes;
  final double hourlyRate;
  final double tableAmount; // Tiền bàn
  final double ordersAmount; // Tiền đồ ăn/uống
  final double totalAmount; // Tổng cộng
  final SessionStatus status;
  final String? customerName;
  final String? notes;
  final List<String> orderIds; // Danh sách order IDs liên kết

  const TableSession({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.companyId,
    required this.startTime,
    this.endTime,
    this.pauseTime,
    this.totalPausedMinutes = 0,
    required this.hourlyRate,
    this.tableAmount = 0,
    this.ordersAmount = 0,
    this.totalAmount = 0,
    required this.status,
    this.customerName,
    this.notes,
    this.orderIds = const [],
  });

  // Tính thời gian chơi thực tế (trừ thời gian pause)
  Duration get playingDuration {
    final endTimeToUse = endTime ?? DateTime.now();
    final totalDuration = endTimeToUse.difference(startTime);
    return totalDuration - Duration(minutes: totalPausedMinutes);
  }

  // Alias for backward compatibility
  int? get duration => playingDuration.inMinutes;

  // Format thời gian chơi
  String get playingTimeFormatted {
    final duration = playingDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Tính tiền bàn dựa trên thời gian chơi và giá giờ
  double calculateTableAmount() {
    final duration = playingDuration;
    final hours = duration.inMinutes / 60.0;
    return hours * hourlyRate;
  }

  // Tổng tiền (bàn + đồ ăn/uống)
  double calculateTotalAmount() {
    return tableAmount + ordersAmount;
  }

  TableSession copyWith({
    String? id,
    String? tableId,
    String? tableName,
    String? companyId,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pauseTime,
    int? totalPausedMinutes,
    double? hourlyRate,
    double? tableAmount,
    double? ordersAmount,
    double? totalAmount,
    SessionStatus? status,
    String? customerName,
    String? notes,
    List<String>? orderIds,
  }) {
    return TableSession(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pauseTime: pauseTime ?? this.pauseTime,
      totalPausedMinutes: totalPausedMinutes ?? this.totalPausedMinutes,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      tableAmount: tableAmount ?? this.tableAmount,
      ordersAmount: ordersAmount ?? this.ordersAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      orderIds: orderIds ?? this.orderIds,
    );
  }
}
