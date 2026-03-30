import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/models/odori_delivery.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullDeliveryJson() => {
        'id': 'del-1',
        'company_id': 'comp-1',
        'delivery_number': 'DL-2026-001',
        'delivery_date': '2026-03-29',
        'driver_id': 'drv-1',
        'employees': {'full_name': 'Tài xế A'},
        'vehicle': 'Xe tải 1.5T',
        'vehicle_plate': '51C-12345',
        'planned_stops': 5,
        'completed_stops': 3,
        'failed_stops': 1,
        'total_amount': 5000000,
        'collected_amount': 3000000,
        'status': 'in_progress',
        'started_at': '2026-03-29T08:00:00Z',
        'notes': 'Giao khu vực Q7',
        'created_at': '2026-03-29T06:00:00Z',
        'updated_at': '2026-03-29T10:00:00Z',
        'delivery_items': [
          {
            'id': 'di-1',
            'delivery_id': 'del-1',
            'order_id': 'ord-1',
            'customer_id': 'cust-1',
            'customer_name': 'Shop A',
            'customer_address': '123 ABC',
            'sequence': 1,
            'order_amount': 1000000,
            'status': 'delivered',
            'created_at': '2026-03-29T06:00:00Z',
          }
        ],
      };

  Map<String, dynamic> minimalDeliveryJson() => {
        'id': 'del-2',
        'company_id': 'comp-1',
        'delivery_number': 'DL-2026-002',
        'delivery_date': '2026-03-29',
        'status': 'planned',
        'created_at': '2026-03-29T06:00:00Z',
      };

  // ─── OdoriDelivery Tests ───────────────────────────────

  group('OdoriDelivery', () {
    group('fromJson', () {
      test('parses full JSON with items', () {
        final delivery = OdoriDelivery.fromJson(fullDeliveryJson());

        expect(delivery.id, 'del-1');
        expect(delivery.deliveryNumber, 'DL-2026-001');
        expect(delivery.driverId, 'drv-1');
        expect(delivery.driverName, 'Tài xế A');
        expect(delivery.vehiclePlate, '51C-12345');
        expect(delivery.plannedStops, 5);
        expect(delivery.completedStops, 3);
        expect(delivery.failedStops, 1);
        expect(delivery.totalAmount, 5000000);
        expect(delivery.collectedAmount, 3000000);
        expect(delivery.status, 'in_progress');
        expect(delivery.items, isNotNull);
        expect(delivery.items!.length, 1);
      });

      test('parses minimal JSON with defaults', () {
        final delivery = OdoriDelivery.fromJson(minimalDeliveryJson());

        expect(delivery.plannedStops, 0);
        expect(delivery.completedStops, 0);
        expect(delivery.failedStops, 0);
        expect(delivery.totalAmount, 0);
        expect(delivery.collectedAmount, 0);
        expect(delivery.driverId, isNull);
        expect(delivery.driverName, isNull);
        expect(delivery.items, isNull);
      });
    });

    group('computed getters', () {
      test('remainingStops calculates correctly', () {
        final delivery = OdoriDelivery.fromJson(fullDeliveryJson());
        expect(delivery.remainingStops, 1); // 5 - 3 - 1
      });

      test('successRate as percentage', () {
        final delivery = OdoriDelivery.fromJson(fullDeliveryJson());
        expect(delivery.successRate, 60.0); // 3/5 * 100
      });

      test('successRate is 0 when no planned stops', () {
        final delivery = OdoriDelivery.fromJson(minimalDeliveryJson());
        expect(delivery.successRate, 0);
      });

      test('isInProgress returns true for in_progress status', () {
        final delivery = OdoriDelivery.fromJson(fullDeliveryJson());
        expect(delivery.isInProgress, true);
      });

      test('isCompleted returns true for completed status', () {
        final json = minimalDeliveryJson()..['status'] = 'completed';
        expect(OdoriDelivery.fromJson(json).isCompleted, true);
      });

      test('statusText returns Vietnamese labels', () {
        final statuses = {
          'planned': 'Đã lên kế hoạch',
          'loading': 'Đang xếp hàng',
          'in_progress': 'Đang giao',
          'completed': 'Hoàn thành',
          'cancelled': 'Đã hủy',
        };
        for (final entry in statuses.entries) {
          final json = minimalDeliveryJson()..['status'] = entry.key;
          expect(OdoriDelivery.fromJson(json).statusText, entry.value,
              reason: 'status=${entry.key}');
        }
      });

      test('formattedDeliveryDate returns dd/MM/yyyy', () {
        final delivery = OdoriDelivery.fromJson(minimalDeliveryJson());
        expect(delivery.formattedDeliveryDate, '29/03/2026');
      });
    });

    group('toJson', () {
      test('uses correct DB column names', () {
        final json = OdoriDelivery.fromJson(fullDeliveryJson()).toJson();

        expect(json['company_id'], 'comp-1');
        expect(json['delivery_number'], 'DL-2026-001');
        expect(json['driver_id'], 'drv-1');
        expect(json['vehicle_plate'], '51C-12345');
        expect(json['planned_stops'], 5);
        expect(json['completed_stops'], 3);
        expect(json['total_amount'], 5000000);
        expect(json['status'], 'in_progress');
      });
    });
  });

  // ─── OdoriDeliveryItem Tests ───────────────────────────

  group('OdoriDeliveryItem', () {
    test('parses from JSON correctly', () {
      final json = {
        'id': 'di-1',
        'delivery_id': 'del-1',
        'order_id': 'ord-1',
        'customer_id': 'cust-1',
        'customer_name': 'Shop A',
        'customer_address': '123 ABC',
        'latitude': 10.77,
        'longitude': 106.70,
        'sequence': 1,
        'order_amount': 1000000,
        'collected_amount': 1000000,
        'status': 'delivered',
        'delivered_at': '2026-03-29T14:30:00Z',
        'receiver_name': 'Anh Tuấn',
        'created_at': '2026-03-29T06:00:00Z',
      };
      final item = OdoriDeliveryItem.fromJson(json);

      expect(item.id, 'di-1');
      expect(item.customerName, 'Shop A');
      expect(item.latitude, 10.77);
      expect(item.sequence, 1);
      expect(item.orderAmount, 1000000);
      expect(item.isDelivered, true);
      expect(item.isPending, false);
      expect(item.isFailed, false);
    });

    test('status helpers work correctly', () {
      final baseJson = {
        'id': 'di-2',
        'delivery_id': 'del-1',
        'order_id': 'ord-1',
        'customer_id': 'cust-1',
        'sequence': 1,
        'status': 'pending',
        'created_at': '2026-03-29T06:00:00Z',
      };

      expect(OdoriDeliveryItem.fromJson(baseJson).isPending, true);

      baseJson['status'] = 'failed';
      expect(OdoriDeliveryItem.fromJson(baseJson).isFailed, true);
    });
  });
}
