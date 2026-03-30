/// Centralized order status constants for sales_orders table.
/// USE THESE CONSTANTS instead of hardcoded strings to prevent status mismatches.
///
/// Flow: draft → pending_approval → confirmed → sent_to_warehouse → processing → ready → completed
///                                 ↘ cancelled
class OrderStatus {
  OrderStatus._();

  static const String draft = 'draft';
  static const String pending = 'pending';
  static const String pendingApproval = 'pending_approval';
  static const String confirmed = 'confirmed'; // Manager/ASM approved
  static const String sentToWarehouse = 'sent_to_warehouse';
  static const String processing = 'processing'; // Warehouse picking
  static const String ready = 'ready'; // Picked, ready for packing/delivery
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  /// Statuses visible to warehouse for picking
  static const List<String> warehousePickable = [confirmed, sentToWarehouse, pendingApproval];

  /// Statuses that count as "active" orders
  static const List<String> active = [pendingApproval, confirmed, sentToWarehouse, processing, ready];
}

/// Centralized delivery_status constants for sales_orders table.
///
/// Flow: pending → awaiting_pickup → delivering → delivered
///                                              ↘ failed
class DeliveryStatus {
  DeliveryStatus._();

  static const String pending = 'pending';
  static const String awaitingPickup = 'awaiting_pickup';
  static const String delivering = 'delivering';
  static const String delivered = 'delivered';
  static const String failed = 'failed';
}
