/// Task Comment Model
/// For threaded discussions within a task
class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Resolved from user lookup
  final String? userName;
  final String? userRole;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userRole,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userRole: json['user_role'] as String?,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'vừa xong';
  }
}
