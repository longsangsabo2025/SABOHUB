import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class EmployeeSchedulePage extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeSchedulePage({super.key, required this.employee});

  @override
  ConsumerState<EmployeeSchedulePage> createState() =>
      _EmployeeSchedulePageState();
}

class _EmployeeSchedulePageState extends ConsumerState<EmployeeSchedulePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch làm việc - ${widget.employee.name}'),
      ),
      body: const Center(
        child: Text('Trang lịch làm việc đang được phát triển'),
      ),
    );
  }
}
