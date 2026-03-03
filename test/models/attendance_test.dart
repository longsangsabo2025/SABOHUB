import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sabohub/models/attendance.dart';

void main() {
  group('AttendanceRecord Model', () {
    final now = DateTime(2026, 2, 26, 8, 0, 0);
    final checkOutTime = DateTime(2026, 2, 26, 17, 0, 0);

    AttendanceRecord createRecord({
      DateTime? checkIn,
      DateTime? checkOut,
      List<BreakRecord>? breaks,
      int totalWorked = 0,
      int totalBreak = 0,
    }) {
      return AttendanceRecord(
        id: 'att-001',
        employeeId: 'emp-001',
        employeeName: 'Nguyễn Văn A',
        companyId: 'comp-001',
        date: DateTime(2026, 2, 26),
        checkInTime: checkIn,
        checkOutTime: checkOut,
        breaks: breaks ?? [],
        status: AttendanceStatus.present,
        totalWorkedMinutes: totalWorked,
        totalBreakMinutes: totalBreak,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('Helper getters', () {
      test('isCheckedIn — checked in but not out', () {
        final record = createRecord(checkIn: now);

        expect(record.isCheckedIn, true);
        expect(record.isCheckedOut, false);
      });

      test('isCheckedOut — both check in and out', () {
        final record = createRecord(checkIn: now, checkOut: checkOutTime);

        expect(record.isCheckedIn, false);
        expect(record.isCheckedOut, true);
      });

      test('neither checked in nor out', () {
        final record = createRecord();

        expect(record.isCheckedIn, false);
        expect(record.isCheckedOut, false);
      });

      test('isOnBreak — last break has no end time', () {
        final record = createRecord(
          checkIn: now,
          breaks: [
            BreakRecord(
              id: 'brk-001',
              startTime: DateTime(2026, 2, 26, 12, 0),
              endTime: null,
            ),
          ],
        );

        expect(record.isOnBreak, true);
      });

      test('isOnBreak false — last break ended', () {
        final record = createRecord(
          checkIn: now,
          breaks: [
            BreakRecord(
              id: 'brk-002',
              startTime: DateTime(2026, 2, 26, 12, 0),
              endTime: DateTime(2026, 2, 26, 13, 0),
            ),
          ],
        );

        expect(record.isOnBreak, false);
      });
    });

    group('Duration formatting', () {
      test('workDurationFormatted', () {
        final record = createRecord(totalWorked: 510); // 8h 30m
        expect(record.workDurationFormatted, '8h 30m');
      });

      test('workDurationFormatted zero', () {
        final record = createRecord(totalWorked: 0);
        expect(record.workDurationFormatted, '0h 0m');
      });

      test('breakDurationFormatted', () {
        final record = createRecord(totalBreak: 75); // 1h 15m
        expect(record.breakDurationFormatted, '1h 15m');
      });

      test('breakDurationFormatted zero', () {
        final record = createRecord(totalBreak: 0);
        expect(record.breakDurationFormatted, '0h 0m');
      });
    });

    group('fromJson / toJson', () {
      test('parses JSON correctly', () {
        final json = {
          'id': 'att-002',
          'employee_id': 'emp-002',
          'employee_name': 'Trần B',
          'company_id': 'comp-001',
          'date': '2026-02-26',
          'check_in_time': '2026-02-26T08:00:00.000Z',
          'check_out_time': '2026-02-26T17:00:00.000Z',
          'status': 'present',
          'check_in_location': 'Văn phòng Q7',
          'check_in_latitude': 10.762622,
          'check_in_longitude': 106.660172,
          'notes': 'Normal day',
          'total_worked_minutes': 540,
          'total_break_minutes': 60,
          'breaks': [],
          'created_at': '2026-02-26T08:00:00.000Z',
          'updated_at': '2026-02-26T17:00:00.000Z',
        };

        final record = AttendanceRecord.fromJson(json);

        expect(record.id, 'att-002');
        expect(record.employeeName, 'Trần B');
        expect(record.status, AttendanceStatus.present);
        expect(record.checkInTime, isNotNull);
        expect(record.checkOutTime, isNotNull);
        expect(record.totalWorkedMinutes, 540);
        expect(record.checkInLatitude, 10.762622);
        expect(record.notes, 'Normal day');
      });

      test('toJson serializes date as date-only string', () {
        final record = createRecord(checkIn: now, totalWorked: 480);
        final json = record.toJson();

        expect(json['date'], '2026-02-26');
        expect(json['employee_id'], 'emp-001');
        expect(json['total_worked_minutes'], 480);
        expect(json['status'], 'present');
      });

      test('roundtrip fromJson → toJson → fromJson', () {
        final original = createRecord(
          checkIn: now,
          checkOut: checkOutTime,
          totalWorked: 540,
          totalBreak: 60,
        );

        final json = original.toJson();
        final restored = AttendanceRecord.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.employeeId, original.employeeId);
        expect(restored.employeeName, original.employeeName);
        expect(restored.totalWorkedMinutes, original.totalWorkedMinutes);
        expect(restored.status, original.status);
      });
    });

    group('copyWith', () {
      test('updates specific fields', () {
        final record = createRecord(checkIn: now);
        final updated = record.copyWith(
          checkOutTime: checkOutTime,
          status: AttendanceStatus.leftEarly,
          totalWorkedMinutes: 480,
        );

        expect(updated.checkOutTime, checkOutTime);
        expect(updated.status, AttendanceStatus.leftEarly);
        expect(updated.totalWorkedMinutes, 480);
        expect(updated.checkInTime, now); // Unchanged
      });
    });
  });

  group('AttendanceType Enum', () {
    test('has 4 types', () {
      expect(AttendanceType.values.length, 4);
    });

    test('labels are correct', () {
      expect(AttendanceType.checkIn.label, 'Check-in');
      expect(AttendanceType.checkOut.label, 'Check-out');
      expect(AttendanceType.breakStart.label, 'Bắt đầu nghỉ');
      expect(AttendanceType.breakEnd.label, 'Kết thúc nghỉ');
    });
  });

  group('AttendanceStatus Enum', () {
    test('has 6 statuses', () {
      expect(AttendanceStatus.values.length, 6);
    });

    test('labels are Vietnamese', () {
      expect(AttendanceStatus.present.label, 'Có mặt');
      expect(AttendanceStatus.absent.label, 'Vắng mặt');
      expect(AttendanceStatus.late.label, 'Muộn giờ');
      expect(AttendanceStatus.leftEarly.label, 'Về sớm');
      expect(AttendanceStatus.onBreak.label, 'Đang nghỉ');
      expect(AttendanceStatus.onLeave.label, 'Nghỉ phép');
    });
  });
}
