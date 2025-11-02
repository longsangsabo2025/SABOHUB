import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';

class TaskFormPage extends ConsumerStatefulWidget {
  final Task? task;

  const TaskFormPage({super.key, this.task});

  @override
  ConsumerState<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends ConsumerState<TaskFormPage> {
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa nhiệm vụ' : 'Thêm nhiệm vụ'),
      ),
      body: const Center(
        child: Text('Form thêm/sửa nhiệm vụ đang được phát triển'),
      ),
    );
  }
}
