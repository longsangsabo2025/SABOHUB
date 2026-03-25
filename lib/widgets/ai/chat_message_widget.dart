import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/ai_message.dart';
import 'message_bubble.dart';

/// Widget to display a single chat message
class ChatMessageWidget extends StatelessWidget {
  final AIMessage message;
  final String companyName;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAIAvatar(context),
          if (!message.isUser) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                MessageBubble(
                  message: message,
                  isUser: message.isUser,
                ),
                const SizedBox(height: 4),
                _buildMessageInfo(context),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser) _buildUserAvatar(context),
        ],
      ),
    );
  }

  Widget _buildAIAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy,
        color: Colors.blue[700],
        size: 24,
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.green[100],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.green[700],
        size: 24,
      ),
    );
  }

  Widget _buildMessageInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!message.isUser) ...[
          // AI badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Colors.blue[700]),
                const SizedBox(width: 4),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Time
        Text(
          _formatTime(message.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),

        // Token info for AI messages
        if (!message.isUser && message.totalTokens > 0) ...[
          const SizedBox(width: 8),
          Icon(Icons.token, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            '${message.totalTokens}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],

        // Cost for AI messages
        if (!message.isUser && message.estimatedCost > 0) ...[
          const SizedBox(width: 8),
          Icon(Icons.attach_money, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 2),
          Text(
            message.estimatedCost.toStringAsFixed(4),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],

        // Copy button
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _copyToClipboard(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.copy,
              size: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép tin nhắn'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
