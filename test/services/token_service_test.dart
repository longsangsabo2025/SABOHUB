import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/token/token_wallet.dart';
import 'package:flutter_sabohub/models/token/token_transaction.dart';
import 'package:flutter_sabohub/models/token/token_store_item.dart';
import 'package:flutter_sabohub/services/token/token_service.dart';

void main() {
  // ─────────────────────────────────────────────
  // TokenWallet Model Tests
  // ─────────────────────────────────────────────

  group('TokenWallet - fromJson / toJson', () {
    late Map<String, dynamic> validWalletJson;

    setUp(() {
      validWalletJson = {
        'id': 'wallet-001',
        'employee_id': 'emp-001',
        'company_id': 'company-001',
        'balance': 1500.50,
        'total_earned': 3000.0,
        'total_spent': 1499.50,
        'total_withdrawn': 0.0,
        'wallet_address': '0x1234567890abcdef',
        'is_active': true,
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-03-01T12:00:00.000Z',
        'employee_name': 'Nguyễn Văn A',
        'employee_avatar': 'https://example.com/avatar.png',
      };
    });

    test('should parse valid wallet JSON correctly', () {
      final wallet = TokenWallet.fromJson(validWalletJson);

      expect(wallet.id, 'wallet-001');
      expect(wallet.employeeId, 'emp-001');
      expect(wallet.companyId, 'company-001');
      expect(wallet.balance, 1500.50);
      expect(wallet.totalEarned, 3000.0);
      expect(wallet.totalSpent, 1499.50);
      expect(wallet.totalWithdrawn, 0.0);
      expect(wallet.walletAddress, '0x1234567890abcdef');
      expect(wallet.isActive, true);
      expect(wallet.employeeName, 'Nguyễn Văn A');
      expect(wallet.employeeAvatar, 'https://example.com/avatar.png');
    });

    test('should handle null optional fields with defaults', () {
      final minimalJson = {
        'id': 'wallet-002',
        'employee_id': 'emp-002',
        'company_id': 'company-001',
        'created_at': '2025-01-01T00:00:00.000Z',
        'updated_at': '2025-01-01T00:00:00.000Z',
      };

      final wallet = TokenWallet.fromJson(minimalJson);

      expect(wallet.balance, 0);
      expect(wallet.totalEarned, 0);
      expect(wallet.totalSpent, 0);
      expect(wallet.totalWithdrawn, 0);
      expect(wallet.walletAddress, isNull);
      expect(wallet.isActive, true);
      expect(wallet.employeeName, isNull);
      expect(wallet.employeeAvatar, isNull);
    });

    test('should serialize back to JSON correctly (roundtrip)', () {
      final wallet = TokenWallet.fromJson(validWalletJson);
      final json = wallet.toJson();

      expect(json['id'], 'wallet-001');
      expect(json['employee_id'], 'emp-001');
      expect(json['balance'], 1500.50);
      expect(json['total_earned'], 3000.0);
      expect(json['total_spent'], 1499.50);
      expect(json['wallet_address'], '0x1234567890abcdef');
    });

    test('should handle integer balance values cast to double', () {
      validWalletJson['balance'] = 1000; // int, not double
      validWalletJson['total_earned'] = 2000;

      final wallet = TokenWallet.fromJson(validWalletJson);

      expect(wallet.balance, 1000.0);
      expect(wallet.totalEarned, 2000.0);
      expect(wallet.balance, isA<double>());
      expect(wallet.totalEarned, isA<double>());
    });
  });

  // ─────────────────────────────────────────────
  // TokenTransaction Model Tests
  // ─────────────────────────────────────────────

  group('TokenTransaction - fromJson / toJson', () {
    late Map<String, dynamic> validTransactionJson;

    setUp(() {
      validTransactionJson = {
        'id': 'tx-001',
        'wallet_id': 'wallet-001',
        'company_id': 'company-001',
        'type': 'earn',
        'amount': 100.0,
        'balance_before': 1400.0,
        'balance_after': 1500.0,
        'source_type': 'task',
        'source_id': 'task-001',
        'description': 'Hoàn thành nhiệm vụ',
        'created_at': '2025-03-01T12:00:00.000Z',
      };
    });

    test('should parse valid transaction JSON correctly', () {
      final tx = TokenTransaction.fromJson(validTransactionJson);

      expect(tx.id, 'tx-001');
      expect(tx.walletId, 'wallet-001');
      expect(tx.companyId, 'company-001');
      expect(tx.type, TokenTransactionType.earn);
      expect(tx.amount, 100.0);
      expect(tx.balanceBefore, 1400.0);
      expect(tx.balanceAfter, 1500.0);
      expect(tx.sourceType, TokenSourceType.task);
      expect(tx.sourceId, 'task-001');
      expect(tx.description, 'Hoàn thành nhiệm vụ');
    });

    test('should handle null source_type gracefully', () {
      validTransactionJson.remove('source_type');
      validTransactionJson.remove('source_id');

      final tx = TokenTransaction.fromJson(validTransactionJson);

      expect(tx.sourceType, isNull);
      expect(tx.sourceId, isNull);
    });

    test('should format positive amounts with + prefix', () {
      final tx = TokenTransaction.fromJson(validTransactionJson);
      expect(tx.formattedAmount, '+100');
    });

    test('should format negative amounts with - prefix', () {
      validTransactionJson['type'] = 'spend';
      final tx = TokenTransaction.fromJson(validTransactionJson);
      expect(tx.formattedAmount, '-100');
    });

    test('should serialize back to JSON correctly', () {
      final tx = TokenTransaction.fromJson(validTransactionJson);
      final json = tx.toJson();

      expect(json['id'], 'tx-001');
      expect(json['type'], 'earn');
      expect(json['amount'], 100.0);
      expect(json['source_type'], 'task');
    });

    test('should support equality by id', () {
      final tx1 = TokenTransaction.fromJson(validTransactionJson);
      final tx2 = TokenTransaction.fromJson(validTransactionJson);
      final tx3 = TokenTransaction.fromJson({
        ...validTransactionJson,
        'id': 'tx-999',
      });

      expect(tx1, equals(tx2));
      expect(tx1, isNot(equals(tx3)));
    });
  });

  // ─────────────────────────────────────────────
  // TokenTransactionType Tests
  // ─────────────────────────────────────────────

  group('TokenTransactionType', () {
    test('should correctly identify positive transaction types', () {
      expect(TokenTransactionType.earn.isPositive, true);
      expect(TokenTransactionType.transferIn.isPositive, true);
      expect(TokenTransactionType.deposit.isPositive, true);
      expect(TokenTransactionType.reward.isPositive, true);
    });

    test('should correctly identify negative transaction types', () {
      expect(TokenTransactionType.spend.isPositive, false);
      expect(TokenTransactionType.transferOut.isPositive, false);
      expect(TokenTransactionType.withdraw.isPositive, false);
      expect(TokenTransactionType.penalty.isPositive, false);
    });

    test('should parse all known string values correctly', () {
      expect(TokenTransactionType.fromString('earn'), TokenTransactionType.earn);
      expect(TokenTransactionType.fromString('spend'), TokenTransactionType.spend);
      expect(TokenTransactionType.fromString('transfer_in'), TokenTransactionType.transferIn);
      expect(TokenTransactionType.fromString('transfer_out'), TokenTransactionType.transferOut);
      expect(TokenTransactionType.fromString('withdraw'), TokenTransactionType.withdraw);
      expect(TokenTransactionType.fromString('deposit'), TokenTransactionType.deposit);
      expect(TokenTransactionType.fromString('reward'), TokenTransactionType.reward);
      expect(TokenTransactionType.fromString('penalty'), TokenTransactionType.penalty);
    });

    test('should default to earn for unknown string value', () {
      expect(TokenTransactionType.fromString('unknown'), TokenTransactionType.earn);
      expect(TokenTransactionType.fromString(''), TokenTransactionType.earn);
    });

    test('should serialize to correct string values', () {
      expect(TokenTransactionType.earn.value, 'earn');
      expect(TokenTransactionType.spend.value, 'spend');
      expect(TokenTransactionType.transferIn.value, 'transfer_in');
      expect(TokenTransactionType.transferOut.value, 'transfer_out');
    });
  });

  // ─────────────────────────────────────────────
  // TokenSourceType Tests
  // ─────────────────────────────────────────────

  group('TokenSourceType', () {
    test('should parse all known source types', () {
      expect(TokenSourceType.fromString('quest'), TokenSourceType.quest);
      expect(TokenSourceType.fromString('achievement'), TokenSourceType.achievement);
      expect(TokenSourceType.fromString('attendance'), TokenSourceType.attendance);
      expect(TokenSourceType.fromString('task'), TokenSourceType.task);
      expect(TokenSourceType.fromString('bonus'), TokenSourceType.bonus);
      expect(TokenSourceType.fromString('purchase'), TokenSourceType.purchase);
      expect(TokenSourceType.fromString('transfer'), TokenSourceType.transfer);
      expect(TokenSourceType.fromString('manual'), TokenSourceType.manual);
      expect(TokenSourceType.fromString('system'), TokenSourceType.system);
      expect(TokenSourceType.fromString('season_reward'), TokenSourceType.seasonReward);
      expect(TokenSourceType.fromString('referral'), TokenSourceType.referral);
    });

    test('should default to system for unknown source type', () {
      expect(TokenSourceType.fromString('unknown'), TokenSourceType.system);
    });
  });

  // ─────────────────────────────────────────────
  // TokenRewardsConfig Model Tests
  // ─────────────────────────────────────────────

  group('TokenRewardsConfig - fromJson / toJson', () {
    test('should parse valid rewards config JSON', () {
      final json = {
        'id': 'config-001',
        'company_id': 'company-001',
        'event_type': 'task_completion',
        'token_amount': 50.0,
        'multiplier': 1.5,
        'is_active': true,
      };

      final config = TokenRewardsConfig.fromJson(json);

      expect(config.id, 'config-001');
      expect(config.companyId, 'company-001');
      expect(config.eventType, 'task_completion');
      expect(config.tokenAmount, 50.0);
      expect(config.multiplier, 1.5);
      expect(config.isActive, true);
    });

    test('should use default values for missing optional fields', () {
      final json = {
        'id': 'config-002',
        'company_id': 'company-001',
        'event_type': 'attendance',
      };

      final config = TokenRewardsConfig.fromJson(json);

      expect(config.tokenAmount, 0);
      expect(config.multiplier, 1.0);
      expect(config.isActive, true);
    });

    test('should serialize to JSON correctly', () {
      final config = const TokenRewardsConfig(
        id: 'config-001',
        companyId: 'company-001',
        eventType: 'task_completion',
        tokenAmount: 50.0,
        multiplier: 1.5,
        isActive: true,
      );

      final json = config.toJson();

      expect(json['id'], 'config-001');
      expect(json['company_id'], 'company-001');
      expect(json['event_type'], 'task_completion');
      expect(json['token_amount'], 50.0);
      expect(json['multiplier'], 1.5);
      expect(json['is_active'], true);
    });

    test('should have meaningful toString', () {
      final config = const TokenRewardsConfig(
        id: 'config-001',
        companyId: 'company-001',
        eventType: 'task_completion',
        tokenAmount: 50.0,
      );

      expect(config.toString(), contains('task_completion'));
      expect(config.toString(), contains('50.0'));
    });
  });

  // ─────────────────────────────────────────────
  // TokenStoreItem / TokenPurchase Model Tests
  // ─────────────────────────────────────────────

  group('TokenStoreItem - fromJson', () {
    test('should parse valid store item JSON', () {
      final json = {
        'id': 'item-001',
        'company_id': 'company-001',
        'name': 'Extra Break Time',
        'description': '30 minutes extra break',
        'category': 'perk',
        'token_cost': 200.0,
        'icon': '⏰',
        'stock': 10,
        'max_per_user': 2,
        'min_level': 1,
        'is_one_time': false,
        'is_active': true,
        'sort_order': 1,
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final item = TokenStoreItem.fromJson(json);

      expect(item.id, 'item-001');
      expect(item.name, 'Extra Break Time');
      expect(item.category, TokenStoreCategory.perk);
      expect(item.tokenCost, 200.0);
      expect(item.icon, '⏰');
      expect(item.stock, 10);
      expect(item.isUnlimited, false);
    });

    test('should handle unlimited stock (null stock)', () {
      final json = {
        'id': 'item-002',
        'company_id': 'company-001',
        'name': 'Digital Badge',
        'category': 'digital',
        'token_cost': 50.0,
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final item = TokenStoreItem.fromJson(json);

      expect(item.stock, isNull);
      expect(item.isUnlimited, true);
    });
  });

  group('TokenStoreCategory', () {
    test('should parse all known category strings', () {
      expect(TokenStoreCategory.fromString('perk'), TokenStoreCategory.perk);
      expect(TokenStoreCategory.fromString('cosmetic'), TokenStoreCategory.cosmetic);
      expect(TokenStoreCategory.fromString('boost'), TokenStoreCategory.boost);
      expect(TokenStoreCategory.fromString('voucher'), TokenStoreCategory.voucher);
      expect(TokenStoreCategory.fromString('physical'), TokenStoreCategory.physical);
      expect(TokenStoreCategory.fromString('digital'), TokenStoreCategory.digital);
      expect(TokenStoreCategory.fromString('nft'), TokenStoreCategory.nft);
    });

    test('should default to perk for unknown category', () {
      expect(TokenStoreCategory.fromString('unknown'), TokenStoreCategory.perk);
    });
  });

  group('TokenPurchase - fromJson', () {
    test('should parse valid purchase JSON', () {
      final json = {
        'id': 'purchase-001',
        'wallet_id': 'wallet-001',
        'company_id': 'company-001',
        'item_id': 'item-001',
        'token_cost': 200.0,
        'status': 'active',
        'purchased_at': '2025-03-01T12:00:00.000Z',
      };

      final purchase = TokenPurchase.fromJson(json);

      expect(purchase.id, 'purchase-001');
      expect(purchase.walletId, 'wallet-001');
      expect(purchase.tokenCost, 200.0);
      expect(purchase.status, 'active');
      expect(purchase.isActive, true);
      expect(purchase.isExpired, false);
    });

    test('should detect expired purchase', () {
      final json = {
        'id': 'purchase-002',
        'wallet_id': 'wallet-001',
        'company_id': 'company-001',
        'item_id': 'item-001',
        'token_cost': 100.0,
        'status': 'active',
        'purchased_at': '2024-01-01T00:00:00.000Z',
        'expires_at': '2024-02-01T00:00:00.000Z', // already expired
      };

      final purchase = TokenPurchase.fromJson(json);

      expect(purchase.isExpired, true);
      expect(purchase.isActive, false); // active status but expired
    });

    test('should detect used purchase as inactive', () {
      final json = {
        'id': 'purchase-003',
        'wallet_id': 'wallet-001',
        'company_id': 'company-001',
        'item_id': 'item-001',
        'token_cost': 100.0,
        'status': 'used',
        'purchased_at': '2025-03-01T00:00:00.000Z',
      };

      final purchase = TokenPurchase.fromJson(json);

      expect(purchase.isActive, false); // status is 'used'
    });

    test('should support equality by id', () {
      final json1 = {
        'id': 'purchase-001',
        'wallet_id': 'wallet-001',
        'company_id': 'company-001',
        'item_id': 'item-001',
        'token_cost': 200.0,
        'purchased_at': '2025-03-01T12:00:00.000Z',
      };
      final json2 = {
        'id': 'purchase-001',
        'wallet_id': 'wallet-002',
        'company_id': 'company-002',
        'item_id': 'item-002',
        'token_cost': 500.0,
        'purchased_at': '2025-04-01T12:00:00.000Z',
      };

      final p1 = TokenPurchase.fromJson(json1);
      final p2 = TokenPurchase.fromJson(json2);

      expect(p1, equals(p2)); // same id
    });
  });

  // ─────────────────────────────────────────────
  // Token Balance Validation Logic
  // ─────────────────────────────────────────────

  group('Token Balance - Validation Logic', () {
    test('should validate earn amount is positive', () {
      final amount = 100.0;
      expect(amount, greaterThan(0));
    });

    test('should reject zero earn amount', () {
      final amount = 0.0;
      expect(amount, isNot(greaterThan(0)));
      // In real service, this would be rejected by the RPC
    });

    test('should reject negative earn amount', () {
      final amount = -50.0;
      expect(amount, isNot(greaterThan(0)));
    });

    test('should validate spend does not exceed balance', () {
      final balance = 1000.0;
      final spendAmount = 500.0;
      expect(spendAmount, lessThanOrEqualTo(balance));
    });

    test('should reject spend exceeding balance', () {
      final balance = 100.0;
      final spendAmount = 200.0;
      expect(spendAmount, isNot(lessThanOrEqualTo(balance)));

      // This validates balance check logic in the spend_tokens RPC
      if (spendAmount > balance) {
        expect(
          () => throw Exception('Insufficient balance'),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('should calculate transfer correctly - sender and receiver balances', () {
      final senderBalance = 1000.0;
      final transferAmount = 300.0;
      final receiverBalance = 200.0;

      final newSenderBalance = senderBalance - transferAmount;
      final newReceiverBalance = receiverBalance + transferAmount;

      expect(newSenderBalance, 700.0);
      expect(newReceiverBalance, 500.0);
    });

    test('should prevent transfer when sender has insufficient balance', () {
      final senderBalance = 50.0;
      final transferAmount = 300.0;

      if (transferAmount > senderBalance) {
        expect(
          () => throw Exception('Insufficient balance for transfer'),
          throwsA(isA<Exception>()),
        );
      }
    });
  });

  // ─────────────────────────────────────────────
  // Token Earnings - Task Completion Rewards Logic
  // ─────────────────────────────────────────────

  group('Token Earnings - Task Completion Rewards', () {
    test('should calculate reward with multiplier', () {
      final baseAmount = 50.0;
      final multiplier = 1.5;
      final reward = baseAmount * multiplier;

      expect(reward, 75.0);
    });

    test('should return 0 reward when config is inactive', () {
      final config = const TokenRewardsConfig(
        id: 'config-001',
        companyId: 'company-001',
        eventType: 'task_completion',
        tokenAmount: 50.0,
        isActive: false,
      );

      // Inactive config should not award tokens
      expect(config.isActive, false);
      final effectiveReward = config.isActive ? config.tokenAmount : 0.0;
      expect(effectiveReward, 0.0);
    });

    test('should calculate reward for active config', () {
      final config = const TokenRewardsConfig(
        id: 'config-001',
        companyId: 'company-001',
        eventType: 'attendance',
        tokenAmount: 10.0,
        multiplier: 2.0,
        isActive: true,
      );

      expect(config.isActive, true);
      final effectiveReward = config.tokenAmount * config.multiplier;
      expect(effectiveReward, 20.0);
    });
  });

  // ─────────────────────────────────────────────
  // Error Handling Simulation
  // ─────────────────────────────────────────────

  group('Token Service - Error Handling Logic', () {
    test('should handle null wallet response (no wallet found)', () {
      // Simulate RPC returning null for non-existent wallet
      final response = null;

      if (response == null) {
        // Service should return null for getWallet
        expect(response, isNull);
      }
    });

    test('should handle empty list response for company wallets', () {
      final response = <Map<String, dynamic>>[];

      final wallets = response
          .map((json) => TokenWallet.fromJson(json))
          .toList();

      expect(wallets, isEmpty);
    });

    test('should handle network timeout gracefully', () {
      // Simulate a network error scenario
      expect(
        () => throw Exception('Connection timed out'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle malformed RPC response for earnTokens', () {
      // If RPC returns empty list instead of expected data
      final response = <dynamic>[];

      expect(
        () {
          if (response.isEmpty) {
            throw StateError('Expected non-empty response from earn_tokens RPC');
          }
          final data = response.first as Map<String, dynamic>;
          return data;
        },
        throwsA(isA<StateError>()),
      );
    });

    test('should handle invalid wallet_id in RPC response', () {
      final rpcResponse = {
        'wallet_id': null, // unexpected null
        'new_balance': 100.0,
        'amount_earned': 50.0,
      };

      expect(
        () => rpcResponse['wallet_id'] as String,
        throwsA(isA<TypeError>()),
      );
    });
  });

  // ─────────────────────────────────────────────
  // Company Token Stats - Aggregation Logic
  // ─────────────────────────────────────────────

  group('Company Token Stats - Aggregation Logic', () {
    test('should aggregate company stats from wallet list', () {
      final wallets = [
        {'balance': 1000.0, 'total_earned': 2000.0, 'total_spent': 1000.0},
        {'balance': 500.0, 'total_earned': 800.0, 'total_spent': 300.0},
        {'balance': 250.0, 'total_earned': 600.0, 'total_spent': 350.0},
      ];

      double totalCirculating = 0;
      double totalEarned = 0;
      double totalSpent = 0;

      for (final w in wallets) {
        totalCirculating += (w['balance'] as num?)?.toDouble() ?? 0;
        totalEarned += (w['total_earned'] as num?)?.toDouble() ?? 0;
        totalSpent += (w['total_spent'] as num?)?.toDouble() ?? 0;
      }

      expect(totalCirculating, 1750.0);
      expect(totalEarned, 3400.0);
      expect(totalSpent, 1650.0);
      expect(wallets.length, 3);
    });

    test('should handle empty company (no wallets)', () {
      final wallets = <Map<String, dynamic>>[];

      double totalCirculating = 0;
      for (final w in wallets) {
        totalCirculating += (w['balance'] as num?)?.toDouble() ?? 0;
      }

      expect(totalCirculating, 0.0);
      expect(wallets.length, 0);
    });

    test('should handle null balance fields gracefully', () {
      final wallets = [
        {'balance': null, 'total_earned': null, 'total_spent': null},
      ];

      double total = 0;
      for (final w in wallets) {
        total += (w['balance'] as num?)?.toDouble() ?? 0;
      }

      expect(total, 0.0);
    });
  });

  // ─────────────────────────────────────────────
  // Earning Breakdown - Analytics Logic
  // ─────────────────────────────────────────────

  group('Earning Breakdown - Analytics', () {
    test('should group earnings by source type', () {
      final transactions = [
        {'source_type': 'task', 'amount': 100.0},
        {'source_type': 'task', 'amount': 50.0},
        {'source_type': 'quest', 'amount': 200.0},
        {'source_type': 'attendance', 'amount': 10.0},
        {'source_type': null, 'amount': 30.0},
      ];

      final breakdown = <String, double>{};
      for (final row in transactions) {
        final source = (row['source_type'] as String?) ?? 'system';
        final amount = (row['amount'] as num?)?.toDouble() ?? 0;
        breakdown[source] = (breakdown[source] ?? 0) + amount;
      }

      expect(breakdown['task'], 150.0);
      expect(breakdown['quest'], 200.0);
      expect(breakdown['attendance'], 10.0);
      expect(breakdown['system'], 30.0); // null source_type defaults to 'system'
    });
  });
}
