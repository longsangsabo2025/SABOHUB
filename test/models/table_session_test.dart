import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/business_types/service/models/session.dart';

void main() {
  // ─── TableSession Tests ────────────────────────────────

  group('TableSession', () {
    TableSession makeSession({
      DateTime? startTime,
      DateTime? endTime,
      int totalPausedMinutes = 0,
      double hourlyRate = 50000,
      double tableAmount = 0,
      double ordersAmount = 0,
      SessionStatus status = SessionStatus.active,
    }) {
      return TableSession(
        id: 'sess-1',
        tableId: 'tbl-1',
        tableName: 'Bàn 1',
        companyId: 'comp-1',
        startTime: startTime ?? DateTime(2026, 3, 29, 14, 0),
        endTime: endTime,
        totalPausedMinutes: totalPausedMinutes,
        hourlyRate: hourlyRate,
        tableAmount: tableAmount,
        ordersAmount: ordersAmount,
        status: status,
      );
    }

    group('playingDuration', () {
      test('calculates total duration minus paused minutes', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 16, 30), // 2h30m total
          totalPausedMinutes: 30, // paused 30m
        );
        // 150 min total - 30 min paused = 120 min playing
        expect(session.playingDuration.inMinutes, 120);
      });

      test('duration getter returns inMinutes for backward compat', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 15, 0),
          totalPausedMinutes: 0,
        );
        expect(session.duration, 60);
      });

      test('zero paused minutes = full duration', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 10, 0),
          endTime: DateTime(2026, 3, 29, 12, 0),
          totalPausedMinutes: 0,
        );
        expect(session.playingDuration.inMinutes, 120);
      });
    });

    group('playingTimeFormatted', () {
      test('formats as Xh Ym', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 16, 45),
          totalPausedMinutes: 15,
        );
        // 165 min - 15 min = 150 min = 2h 30m
        expect(session.playingTimeFormatted, '2h 30m');
      });
    });

    group('calculateTableAmount', () {
      test('calculates hours * hourlyRate', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 16, 0), // 2 hours
          totalPausedMinutes: 0,
          hourlyRate: 50000,
        );
        // 2h * 50000 = 100000
        expect(session.calculateTableAmount(), 100000);
      });

      test('subtracts paused time before calculating', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 16, 0), // 2h total
          totalPausedMinutes: 60, // 1h paused
          hourlyRate: 50000,
        );
        // (120 - 60) min = 1h * 50000 = 50000
        expect(session.calculateTableAmount(), 50000);
      });

      test('handles fractional hours', () {
        final session = makeSession(
          startTime: DateTime(2026, 3, 29, 14, 0),
          endTime: DateTime(2026, 3, 29, 14, 30), // 30 min
          totalPausedMinutes: 0,
          hourlyRate: 60000,
        );
        // 0.5h * 60000 = 30000
        expect(session.calculateTableAmount(), 30000);
      });
    });

    group('calculateTotalAmount', () {
      test('sums tableAmount and ordersAmount', () {
        final session = makeSession(
          tableAmount: 100000,
          ordersAmount: 50000,
        );
        expect(session.calculateTotalAmount(), 150000);
      });

      test('zero when both are zero', () {
        final session = makeSession();
        expect(session.calculateTotalAmount(), 0);
      });
    });

    group('copyWith', () {
      test('preserves all fields when no args', () {
        final original = makeSession(
          tableAmount: 100000,
          ordersAmount: 50000,
          status: SessionStatus.paused,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.tableName, original.tableName);
        expect(copy.hourlyRate, original.hourlyRate);
        expect(copy.tableAmount, original.tableAmount);
        expect(copy.status, original.status);
      });

      test('updates specified fields only', () {
        final original = makeSession(status: SessionStatus.active);
        final updated = original.copyWith(
          status: SessionStatus.completed,
          tableAmount: 200000,
        );

        expect(updated.status, SessionStatus.completed);
        expect(updated.tableAmount, 200000);
        expect(updated.tableName, original.tableName); // unchanged
      });
    });
  });

  // ─── SessionStatus Tests ──────────────────────────────

  group('SessionStatus', () {
    test('has correct Vietnamese labels', () {
      expect(SessionStatus.active.label, 'Đang hoạt động');
      expect(SessionStatus.paused.label, 'Tạm dừng');
      expect(SessionStatus.completed.label, 'Hoàn thành');
      expect(SessionStatus.cancelled.label, 'Đã hủy');
    });

    test('has 4 values', () {
      expect(SessionStatus.values.length, 4);
    });
  });
}
