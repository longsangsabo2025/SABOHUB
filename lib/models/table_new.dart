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
  final TableType type;
  final TableStatus status;
  final DateTime? startTime;
  final String? customerName;
  final String? assignedStaff;
  final List<String> notes;
  final DateTime lastUpdated;

  const BilliardsTable({
    required this.id,
    required this.tableNumber,
    required this.companyId,
    required this.type,
    required this.status,
    this.startTime,
    this.customerName,
    this.assignedStaff,
    this.notes = const [],
    required this.lastUpdated,
  });

  /// Calculate current session duration
  Duration get currentSessionDuration {
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime!);
  }

  /// Calculate current amount based on time played
  int get calculatedAmount {
    if (startTime == null) return 0;
    final hours = currentSessionDuration.inMinutes / 60.0;
    return (hours * type.hourlyRate).round();
  }

  /// Check if table is playable
  bool get isPlayable {
    return status == TableStatus.available || status == TableStatus.occupied;
  }

  /// Get formatted time display
  String get formattedDuration {
    final duration = currentSessionDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  BilliardsTable copyWith({
    String? id,
    String? tableNumber,
    String? companyId,
    TableType? type,
    TableStatus? status,
    DateTime? startTime,
    String? customerName,
    String? assignedStaff,
    List<String>? notes,
    DateTime? lastUpdated,
  }) {
    return BilliardsTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      companyId: companyId ?? this.companyId,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      customerName: customerName ?? this.customerName,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      notes: notes ?? this.notes,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'BilliardsTable(id: $id, tableNumber: $tableNumber, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BilliardsTable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Sample table data for demo
class TableSampleData {
  static List<BilliardsTable> get demoTables {
    final now = DateTime.now();

    return [
      // Pool 8 tables
      BilliardsTable(
        id: 'table_001',
        tableNumber: 'Bàn Pool 01',
        companyId: 'company_001',
        type: TableType.pool8,
        status: TableStatus.occupied,
        startTime: now.subtract(const Duration(hours: 1, minutes: 30)),
        customerName: 'Nguyễn Văn A',
        assignedStaff: 'Nhân viên 1',
        notes: ['Khách yêu cầu phục vụ nước'],
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_002',
        tableNumber: 'Bàn Pool 02',
        companyId: 'company_001',
        type: TableType.pool8,
        status: TableStatus.available,
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_003',
        tableNumber: 'Bàn Pool 03',
        companyId: 'company_001',
        type: TableType.pool8,
        status: TableStatus.reserved,
        startTime: now.add(const Duration(minutes: 30)),
        customerName: 'Trần Thị B',
        notes: ['Đặt lúc 19:30', 'Gọi xác nhận'],
        lastUpdated: now,
      ),

      // Pool 9 tables
      BilliardsTable(
        id: 'table_004',
        tableNumber: 'Bàn Pool 04',
        companyId: 'company_001',
        type: TableType.pool9,
        status: TableStatus.occupied,
        startTime: now.subtract(const Duration(minutes: 45)),
        customerName: 'Lê Văn C',
        assignedStaff: 'Nhân viên 2',
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_005',
        tableNumber: 'Bàn Pool 05',
        companyId: 'company_001',
        type: TableType.pool9,
        status: TableStatus.available,
        lastUpdated: now,
      ),

      // Snooker tables
      BilliardsTable(
        id: 'table_006',
        tableNumber: 'Bàn Snooker 01',
        companyId: 'company_001',
        type: TableType.snooker,
        status: TableStatus.occupied,
        startTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        customerName: 'Phạm Văn D',
        assignedStaff: 'Nhân viên 1',
        notes: ['Khách hàng VIP', 'Miễn phí nước'],
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_007',
        tableNumber: 'Bàn Snooker 02',
        companyId: 'company_001',
        type: TableType.snooker,
        status: TableStatus.maintenance,
        notes: ['Thay nỉ mới', 'Dự kiến xong 30 phút'],
        lastUpdated: now,
      ),

      // Carom tables
      BilliardsTable(
        id: 'table_008',
        tableNumber: 'Bàn Carom 01',
        companyId: 'company_001',
        type: TableType.carom,
        status: TableStatus.available,
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_009',
        tableNumber: 'Bàn Carom 02',
        companyId: 'company_001',
        type: TableType.carom,
        status: TableStatus.cleaning,
        assignedStaff: 'Nhân viên 3',
        notes: ['Dọn dẹp sau ca đêm'],
        lastUpdated: now,
      ),
      BilliardsTable(
        id: 'table_010',
        tableNumber: 'Bàn Pool 06',
        companyId: 'company_001',
        type: TableType.pool8,
        status: TableStatus.available,
        lastUpdated: now,
      ),
    ];
  }
}
