import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/token/token_wallet.dart';

void main() {
  group('TokenWallet JSON Roundtrip', () {
    test('parses full json correctly', () {
      final json = {'id': 'w1', 'employee_id': 'e1', 'company_id': 'c1', 'balance': 100.5, 'total_earned': 150.0, 'total_spent': 49.5, 'total_withdrawn': 0.0, 'wallet_address': '0xABC', 'is_active': true, 'created_at': '2026-03-04T12:00:00Z', 'updated_at': '2026-03-04T12:00:00Z', 'employee_name': 'Huy', 'employee_avatar': null};
      final wallet = TokenWallet.fromJson(json);
      expect(wallet.id, 'w1');
      expect(wallet.balance, 100.5);
      expect(wallet.totalEarned, 150.0);
      expect(wallet.walletAddress, '0xABC');
      expect(wallet.employeeName, 'Huy');
      
      final output = wallet.toJson();
      expect(output['id'], 'w1');
      expect(output['balance'], 100.5);
      expect(output['wallet_address'], '0xABC');
    });
  });
}
