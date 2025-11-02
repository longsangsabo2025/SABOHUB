import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class EmployeeAttendancePage extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeAttendancePage({super.key, required this.employee});

  @override
  ConsumerState<EmployeeAttendancePage> createState() =>
      _EmployeeAttendancePageState();
}

class _EmployeeAttendancePageState
    extends ConsumerState<EmployeeAttendancePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chấm công - ${widget.employee.name}'),
      ),
      body: const Center(
        child: Text('Trang chấm công đang được phát triển'),
      ),
    );
  }
}
