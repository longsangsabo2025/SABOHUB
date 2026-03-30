import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/distribution/models/odori_product.dart';

void main() {
  // ─── Fixtures ──────────────────────────────────────────

  Map<String, dynamic> fullProductJson() => {
        'id': 'prod-1',
        'company_id': 'comp-1',
        'category_id': 'cat-1',
        'product_categories': {'name': 'Dầu ăn'},
        'sku': 'OIL-001',
        'barcode': '8935001234567',
        'name': 'Dầu ăn Odori 1L',
        'description': 'Dầu ăn cao cấp',
        'brand': 'Odori',
        'unit': 'chai',
        'cost_price': 30000,
        'selling_price': 45000,
        'wholesale_price': 40000,
        'min_wholesale_qty': 10,
        'track_inventory': true,
        'min_stock': 50,
        'max_stock': 500,
        'reorder_point': 100,
        'reorder_quantity': 200,
        'weight': 1.0,
        'weight_unit': 'kg',
        'status': 'active',
        'image_url': 'https://storage.example/oil.jpg',
        'images': ['img1.jpg', 'img2.jpg'],
        'attributes': {'origin': 'Vietnam'},
        'tags': ['cooking', 'oil'],
        'created_by': 'emp-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-03-15T12:00:00Z',
      };

  Map<String, dynamic> minimalProductJson() => {
        'id': 'prod-2',
        'company_id': 'comp-1',
        'sku': 'ITEM-002',
        'name': 'Sản phẩm mới',
        'selling_price': 10000,
        'created_at': '2026-03-01T00:00:00Z',
      };

  // ─── OdoriProduct Tests ────────────────────────────────

  group('OdoriProduct', () {
    group('fromJson', () {
      test('parses full JSON with category join', () {
        final p = OdoriProduct.fromJson(fullProductJson());

        expect(p.id, 'prod-1');
        expect(p.sku, 'OIL-001');
        expect(p.name, 'Dầu ăn Odori 1L');
        expect(p.categoryName, 'Dầu ăn');
        expect(p.brand, 'Odori');
        expect(p.unit, 'chai');
        expect(p.costPrice, 30000);
        expect(p.sellingPrice, 45000);
        expect(p.wholesalePrice, 40000);
        expect(p.minWholesaleQty, 10);
        expect(p.trackInventory, true);
        expect(p.reorderPoint, 100);
        expect(p.tags, ['cooking', 'oil']);
      });

      test('parses minimal JSON with defaults', () {
        final p = OdoriProduct.fromJson(minimalProductJson());

        expect(p.costPrice, 0); // default
        expect(p.unit, 'cái'); // default unit
        expect(p.trackInventory, true); // default
        expect(p.status, 'active'); // default
        expect(p.categoryName, isNull);
        expect(p.barcode, isNull);
        expect(p.images, isNull);
        expect(p.tags, isNull);
      });
    });

    group('computed getters', () {
      test('margin calculates profit percentage', () {
        final p = OdoriProduct.fromJson(fullProductJson());
        // (45000 - 30000) / 45000 * 100 = 33.33%
        expect(p.margin, closeTo(33.33, 0.01));
      });

      test('margin is 0 when sellingPrice is 0', () {
        final json = minimalProductJson()..['selling_price'] = 0;
        expect(OdoriProduct.fromJson(json).margin, 0);
      });

      test('isActive true for active status', () {
        expect(OdoriProduct.fromJson(fullProductJson()).isActive, true);
      });

      test('isActive false for inactive status', () {
        final json = fullProductJson()..['status'] = 'inactive';
        expect(OdoriProduct.fromJson(json).isActive, false);
      });

      test('needsReorder true when reorderPoint and minStock set', () {
        expect(OdoriProduct.fromJson(fullProductJson()).needsReorder, true);
      });

      test('needsReorder false when reorderPoint missing', () {
        expect(OdoriProduct.fromJson(minimalProductJson()).needsReorder, false);
      });
    });

    group('toJson', () {
      test('uses correct DB column names (NOT base_price)', () {
        final json = OdoriProduct.fromJson(fullProductJson()).toJson();

        // CRITICAL: DB uses selling_price NOT base_price
        expect(json['selling_price'], 45000);
        expect(json.containsKey('base_price'), false);

        expect(json['cost_price'], 30000);
        expect(json['sku'], 'OIL-001');
        expect(json['status'], 'active');
        expect(json['track_inventory'], true);

        // Join fields should NOT be in output
        expect(json.containsKey('product_categories'), false);
        expect(json.containsKey('created_by'), false);
      });

      test('roundtrip preserves data', () {
        final original = OdoriProduct.fromJson(fullProductJson());
        final json = original.toJson();

        // Verify key fields survive roundtrip
        expect(json['id'], 'prod-1');
        expect(json['name'], 'Dầu ăn Odori 1L');
        expect(json['wholesale_price'], 40000);
        expect(json['images'], ['img1.jpg', 'img2.jpg']);
        expect(json['attributes'], {'origin': 'Vietnam'});
      });
    });

    group('copyWith', () {
      test('preserves all fields when no args', () {
        final original = OdoriProduct.fromJson(fullProductJson());
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.sellingPrice, original.sellingPrice);
        expect(copy.status, original.status);
      });

      test('updates specified fields only', () {
        final original = OdoriProduct.fromJson(fullProductJson());
        final updated = original.copyWith(
          sellingPrice: 50000,
          status: 'inactive',
        );

        expect(updated.sellingPrice, 50000);
        expect(updated.status, 'inactive');
        expect(updated.name, original.name); // unchanged
        expect(updated.sku, original.sku); // unchanged
      });
    });
  });
}
