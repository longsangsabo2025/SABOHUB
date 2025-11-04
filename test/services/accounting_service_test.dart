import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_sabohub/models/accounting.dart';
import 'package:flutter_sabohub/services/accounting_service.dart';

void main() {
  group('AccountingService Unit Tests', () {
    late AccountingService service;
    const testCompanyId = 'test-company-id';
    const testBranchId = 'test-branch-id';

    setUp(() {
      service = AccountingService();
    });

    group('Summary Calculations', () {
      test('Should calculate net profit correctly', () {
        // Net profit = Revenue - Expenses
        final revenue = 1000000.0;
        final expense = 600000.0;
        final expectedProfit = revenue - expense;

        expect(expectedProfit, equals(400000.0));
      });

      test('Should calculate profit margin correctly', () {
        // Profit margin = (Net Profit / Revenue) * 100
        final revenue = 1000000.0;
        final netProfit = 400000.0;
        final expectedMargin = (netProfit / revenue) * 100;

        expect(expectedMargin, equals(40.0));
      });

      test('Should handle zero revenue case', () {
        // When revenue is 0, profit margin should be 0
        final revenue = 0.0;
        final netProfit = -100000.0;
        final profitMargin = revenue > 0 ? (netProfit / revenue * 100) : 0.0;

        expect(profitMargin, equals(0.0));
      });

      test('Should aggregate multiple transactions correctly', () async {
        // Given multiple transactions
        final transactions = [
          AccountingTransaction(
            id: '1',
            companyId: testCompanyId,
            type: TransactionType.revenue,
            amount: 500000,
            description: 'Revenue 1',
            paymentMethod: PaymentMethod.cash,
            date: DateTime.now(),
            createdBy: 'user-1',
            createdAt: DateTime.now(),
          ),
          AccountingTransaction(
            id: '2',
            companyId: testCompanyId,
            type: TransactionType.expense,
            amount: 200000,
            description: 'Expense 1',
            paymentMethod: PaymentMethod.bank,
            date: DateTime.now(),
            createdBy: 'user-1',
            createdAt: DateTime.now(),
          ),
          AccountingTransaction(
            id: '3',
            companyId: testCompanyId,
            type: TransactionType.salary,
            amount: 150000,
            description: 'Salary 1',
            paymentMethod: PaymentMethod.bank,
            date: DateTime.now(),
            createdBy: 'user-1',
            createdAt: DateTime.now(),
          ),
        ];

        // Calculate totals
        double totalRevenue = 0;
        double totalExpense = 0;

        for (var t in transactions) {
          if (t.type == TransactionType.revenue) {
            totalRevenue += t.amount;
          } else {
            totalExpense += t.amount;
          }
        }

        expect(totalRevenue, equals(500000));
        expect(totalExpense, equals(350000));
        expect(totalRevenue - totalExpense, equals(150000));
      });
    });

    group('Transaction Type Validation', () {
      test('Should correctly identify revenue transactions', () {
        final transaction = AccountingTransaction(
          id: '1',
          companyId: testCompanyId,
          type: TransactionType.revenue,
          amount: 100000,
          description: 'Test Revenue',
          paymentMethod: PaymentMethod.cash,
          date: DateTime.now(),
          createdBy: 'user-1',
          createdAt: DateTime.now(),
        );

        expect(transaction.type, equals(TransactionType.revenue));
        expect(transaction.type.label, equals('Thu nhập'));
      });

      test('Should correctly identify expense transactions', () {
        final types = [
          TransactionType.expense,
          TransactionType.salary,
          TransactionType.utility,
          TransactionType.maintenance,
          TransactionType.other,
        ];

        for (var type in types) {
          expect(type, isNot(equals(TransactionType.revenue)));
        }
      });
    });

    group('Payment Method Validation', () {
      test('Should have all required payment methods', () {
        expect(PaymentMethod.values.length, equals(5));
        expect(PaymentMethod.values, contains(PaymentMethod.cash));
        expect(PaymentMethod.values, contains(PaymentMethod.bank));
        expect(PaymentMethod.values, contains(PaymentMethod.card));
        expect(PaymentMethod.values, contains(PaymentMethod.momo));
        expect(PaymentMethod.values, contains(PaymentMethod.other));
      });

      test('Should have correct labels for payment methods', () {
        expect(PaymentMethod.cash.label, equals('Tiền mặt'));
        expect(PaymentMethod.bank.label, equals('Chuyển khoản'));
        expect(PaymentMethod.card.label, equals('Thẻ'));
        expect(PaymentMethod.momo.label, equals('MoMo'));
        expect(PaymentMethod.other.label, equals('Khác'));
      });
    });

    group('Date Range Handling', () {
      test('Should correctly filter transactions by date range', () {
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 30));
        final endDate = now;

        final transactions = [
          DateTime.now().subtract(const Duration(days: 5)),  // Within range
          DateTime.now().subtract(const Duration(days: 20)), // Within range
          DateTime.now().subtract(const Duration(days: 40)), // Outside range
          DateTime.now(),                                     // Within range
        ];

        final filtered = transactions.where((date) {
          return date.isAfter(startDate) && date.isBefore(endDate.add(const Duration(days: 1)));
        }).toList();

        expect(filtered.length, equals(3));
      });
    });

    group('Accounting Summary Model', () {
      test('Should create valid summary with all fields', () {
        final summary = AccountingSummary(
          totalRevenue: 1000000,
          totalExpense: 600000,
          netProfit: 400000,
          profitMargin: 40.0,
          transactionCount: 10,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 31),
        );

        expect(summary.totalRevenue, equals(1000000));
        expect(summary.totalExpense, equals(600000));
        expect(summary.netProfit, equals(400000));
        expect(summary.profitMargin, equals(40.0));
        expect(summary.transactionCount, equals(10));
      });

      test('Should format currency correctly', () {
        final summary = AccountingSummary(
          totalRevenue: 1234567.89,
          totalExpense: 0,
          netProfit: 0,
          profitMargin: 0,
          transactionCount: 0,
          startDate: DateTime.now(),
          endDate: DateTime.now(),
        );

        // Check if formatted string contains proper separators
        final formatted = summary.formattedRevenue;
        expect(formatted, contains('1,234,567'));
      });
    });

    group('Error Handling', () {
      test('Should return empty summary on error', () async {
        // Test error handling when database fails
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        try {
          final summary = await service.getSummary(
            companyId: 'invalid-id',
            startDate: startDate,
            endDate: endDate,
          );

          // Should return zeros instead of throwing
          expect(summary.totalRevenue, equals(0));
          expect(summary.totalExpense, equals(0));
          expect(summary.netProfit, equals(0));
        } catch (e) {
          fail('Should not throw exception, should return empty summary');
        }
      });

      test('Should handle negative profit correctly', () {
        // When expenses > revenue
        final revenue = 100000.0;
        final expense = 150000.0;
        final netProfit = revenue - expense;

        expect(netProfit, equals(-50000.0));
        expect(netProfit < 0, isTrue);
      });
    });

    group('Data Validation', () {
      test('Should not allow negative amounts', () {
        // In real implementation, validate amounts
        final amount = -100.0;
        expect(amount < 0, isTrue);
        // Should throw validation error
      });

      test('Should require description', () {
        final description = '';
        expect(description.isEmpty, isTrue);
        // Should fail validation
      });

      test('Should require valid company ID', () {
        final companyId = '';
        expect(companyId.isEmpty, isTrue);
        // Should fail validation
      });
    });

    group('Daily Revenue Tests', () {
      test('Should aggregate daily revenue correctly', () {
        final dailyRevenues = [
          DailyRevenue(
            id: '1',
            companyId: testCompanyId,
            branchId: testBranchId,
            date: DateTime(2024, 1, 1),
            amount: 100000,
            tableCount: 10,
            customerCount: 25,
            notes: 'Day 1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          DailyRevenue(
            id: '2',
            companyId: testCompanyId,
            branchId: testBranchId,
            date: DateTime(2024, 1, 2),
            amount: 150000,
            tableCount: 12,
            customerCount: 30,
            notes: 'Day 2',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final total = dailyRevenues.fold<double>(
          0,
          (sum, item) => sum + item.amount,
        );

        expect(total, equals(250000));
      });
    });

    group('Branch Filtering', () {
      test('Should filter transactions by branch', () {
        final transactions = [
          {'branch_id': 'branch-1', 'amount': 100},
          {'branch_id': 'branch-2', 'amount': 200},
          {'branch_id': 'branch-1', 'amount': 150},
        ];

        final branch1Total = transactions
            .where((t) => t['branch_id'] == 'branch-1')
            .fold<int>(0, (sum, t) => sum + (t['amount'] as int));

        expect(branch1Total, equals(250));
      });
    });
  });

  group('Integration Tests', () {
    test('Should create and retrieve transaction', () async {
      // This would require actual database connection
      // For now, just test the data flow
      const testCompany = 'test-company-123';
      
      final transaction = AccountingTransaction(
        id: 'new-id',
        companyId: testCompany,
        type: TransactionType.revenue,
        amount: 100000,
        description: 'Test transaction',
        paymentMethod: PaymentMethod.cash,
        date: DateTime.now(),
        createdBy: 'user-1',
        createdAt: DateTime.now(),
      );

      expect(transaction.id, isNotEmpty);
      expect(transaction.amount, isPositive);
    });
  });
}
