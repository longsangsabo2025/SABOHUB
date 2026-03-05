import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/token/token_transaction.dart';

void main() {
  group('TokenTransaction JSON Roundtrip', () {
    test('parses full json correctly', () {
      final json = {'id': 'tx1', 'wallet_id': 'w1', 'company_id': 'c1', 'type': 'earn', 'amount': 50.0, 'balance_before': 100.0, 'balance_after': 150.0, 'source_type': 'task', 'source_id': 'src1', 'description': 'Completed task X', 'created_at': '2026-03-04T12:00:00Z', 'metadata': null};
      final tx = TokenTransaction.fromJson(json);
      expect(tx.id, 'tx1');
      expect(tx.type, TokenTransactionType.earn);
      expect(tx.sourceType, TokenSourceType.task);
      expect(tx.amount, 50.0);
      
      final output = tx.toJson();
      expect(output['type'], 'earn');
      expect(output['source_type'], 'task');
    });
  });
}
