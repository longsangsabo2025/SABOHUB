import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/order.dart';

void main() {
  // ─── OrderItem Tests ───────────────────────────────────

  group('OrderItem', () {
    test('totalPrice = price * quantity', () {
      const item = OrderItem(
        menuItemId: 'mi-1',
        menuItemName: 'Cơm sườn',
        price: 45000,
        quantity: 3,
      );
      expect(item.totalPrice, 135000);
    });

    test('totalPrice = 0 when quantity is 0', () {
      const item = OrderItem(
        menuItemId: 'mi-2',
        menuItemName: 'Nước suối',
        price: 10000,
        quantity: 0,
      );
      expect(item.totalPrice, 0);
    });

    test('copyWith preserves fields when no args', () {
      const original = OrderItem(
        menuItemId: 'mi-1',
        menuItemName: 'Phở',
        price: 50000,
        quantity: 2,
        notes: 'Không hành',
      );
      final copy = original.copyWith();

      expect(copy.menuItemId, original.menuItemId);
      expect(copy.price, original.price);
      expect(copy.quantity, original.quantity);
      expect(copy.notes, original.notes);
    });

    test('copyWith overrides specified fields', () {
      const original = OrderItem(
        menuItemId: 'mi-1',
        menuItemName: 'Bún bò',
        price: 55000,
        quantity: 1,
      );
      final updated = original.copyWith(quantity: 3, notes: 'Thêm ớt');

      expect(updated.quantity, 3);
      expect(updated.notes, 'Thêm ớt');
      expect(updated.price, 55000); // unchanged
    });
  });

  // ─── Order Tests ───────────────────────────────────────

  group('Order', () {
    Order makeOrder({List<OrderItem>? items, OrderStatus? status}) {
      return Order(
        id: 'ord-1',
        companyId: 'comp-1',
        tableId: 'tbl-1',
        tableName: 'Bàn 5',
        items: items ??
            const [
              OrderItem(
                menuItemId: 'mi-1',
                menuItemName: 'Cơm sườn',
                price: 45000,
                quantity: 2,
              ),
              OrderItem(
                menuItemId: 'mi-2',
                menuItemName: 'Nước cam',
                price: 25000,
                quantity: 3,
              ),
            ],
        status: status ?? OrderStatus.pending,
        createdAt: DateTime(2026, 3, 29, 12, 0),
        customerName: 'Anh Minh',
      );
    }

    group('totalAmount', () {
      test('sums all item totalPrices', () {
        final order = makeOrder();
        // (45000 * 2) + (25000 * 3) = 90000 + 75000 = 165000
        expect(order.totalAmount, 165000);
      });

      test('total is alias for totalAmount', () {
        final order = makeOrder();
        expect(order.total, order.totalAmount);
      });

      test('is 0 for empty items', () {
        final order = makeOrder(items: []);
        expect(order.totalAmount, 0);
      });
    });

    group('itemCount', () {
      test('sums all quantities', () {
        final order = makeOrder();
        // 2 + 3 = 5
        expect(order.itemCount, 5);
      });

      test('is 0 for empty items', () {
        final order = makeOrder(items: []);
        expect(order.itemCount, 0);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no args', () {
        final original = makeOrder();
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.companyId, original.companyId);
        expect(copy.tableName, original.tableName);
        expect(copy.items.length, original.items.length);
        expect(copy.status, original.status);
        expect(copy.customerName, original.customerName);
      });

      test('updates status only', () {
        final original = makeOrder(status: OrderStatus.pending);
        final updated = original.copyWith(status: OrderStatus.completed);

        expect(updated.status, OrderStatus.completed);
        expect(updated.id, original.id); // unchanged
        expect(updated.items.length, original.items.length); // unchanged
      });
    });
  });

  // ─── OrderStatus Tests ────────────────────────────────

  group('OrderStatus', () {
    test('has correct Vietnamese labels', () {
      expect(OrderStatus.pending.label, 'Chờ xử lý');
      expect(OrderStatus.preparing.label, 'Đang chuẩn bị');
      expect(OrderStatus.ready.label, 'Sẵn sàng');
      expect(OrderStatus.completed.label, 'Hoàn thành');
      expect(OrderStatus.cancelled.label, 'Đã hủy');
    });

    test('has 5 values', () {
      expect(OrderStatus.values.length, 5);
    });
  });
}
