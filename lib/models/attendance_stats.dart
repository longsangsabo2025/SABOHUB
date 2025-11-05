/// Attendance statistics model
class AttendanceStats {
  final int totalEmployees;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int onLeaveCount;
  final double attendanceRate;

  const AttendanceStats({
    required this.totalEmployees,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.onLeaveCount,
    required this.attendanceRate,
  });
}
