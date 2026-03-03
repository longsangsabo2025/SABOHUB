import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class TaskTestWidget extends StatefulWidget {
  const TaskTestWidget({super.key});

  @override
  TaskTestWidgetState createState() => TaskTestWidgetState();
}

class TaskTestWidgetState extends State<TaskTestWidget> {
  String _result = '';
  bool _loading = false;

  Future<void> _testCreateTask() async {
    setState(() {
      _loading = true;
      _result = 'Testing task creation...';
    });

    try {
      AppLogger.info('FLUTTER TEST: Starting task creation test');
      
      final supabase = Supabase.instance.client;
      AppLogger.info('FLUTTER TEST: Supabase client ready');
      
      // Prepare test data
      final taskData = {
        'title': 'FLUTTER TEST TASK',
        'description': 'Created from Flutter test widget',
        'category': 'general',
        'priority': 'medium',
        'status': 'pending',
        'progress': 0,
      };
      
      AppLogger.info('FLUTTER TEST: Task data prepared', taskData);
      
      // Attempt insert
      AppLogger.api('FLUTTER TEST: Calling supabase.from("tasks").insert()...');
      final response = await supabase
          .from('tasks')
          .insert(taskData)
          .select();
          
      AppLogger.api('FLUTTER TEST: Insert completed');
      AppLogger.api('FLUTTER TEST: Response', response);
      
      setState(() {
        _result = '✅ SUCCESS!\n\nCreated task: ${response[0]['title']}\nID: ${response[0]['id']}';
        _loading = false;
      });
      
    } catch (e, stackTrace) {
      AppLogger.error('FLUTTER TEST: ERROR occurred');
      AppLogger.error('FLUTTER TEST: Error', e, stackTrace);
      
      setState(() {
        _result = '❌ ERROR: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Task Creation Test Tool',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _testCreateTask,
            child: _loading 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Testing...'),
                  ],
                )
              : Text('🚀 Test Create Task'),
          ),
          if (_result.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _result.startsWith('✅') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _result.startsWith('✅') ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                _result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}