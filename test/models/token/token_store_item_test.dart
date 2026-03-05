import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/token/token_store_item.dart';

void main() {
  group('TokenStoreItem JSON Roundtrip', () {
    test('parses json correctly', () {
      final json = {'id': 'item1', 'company_id': 'c1', 'name': 'Voucher', 'description': 'desc', 'category': 'voucher', 'token_cost': 500, 'icon': '🎁', 'stock': 10, 'min_level': 2, 'created_at': '2026-03-04T12:00:00Z'};
      final item = TokenStoreItem.fromJson(json);
      expect(item.id, 'item1');
      expect(item.category, TokenStoreCategory.voucher);
      expect(item.tokenCost, 500.0);
      expect(item.minLevel, 2);
      
      final output = item.toJson();
      expect(output['name'], 'Voucher');
      expect(output['category'], 'voucher');
    });
  });
}
