import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../models/ai_message.dart';

/// Message bubble widget for chat interface
class MessageBubble extends StatelessWidget {
  final AIMessage message;
  final bool isUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[600] : Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              isUser ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight:
              isUser ? const Radius.circular(4) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          if (isUser)
            Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            )
          else
            MarkdownWidget(
              data: message.content,
              shrinkWrap: true,
              config: MarkdownConfig(
                configs: [
                  const PConfig(
                    textStyle: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const H1Config(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const H2Config(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const H3Config(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CodeConfig(
                    style: TextStyle(
                      backgroundColor: Colors.grey[200],
                      fontFamily: 'monospace',
                    ),
                  ),
                  PreConfig(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

          // Attachments
          if (message.hasAttachments) ...[
            const SizedBox(height: 12),
            _buildAttachments(context),
          ],

          // Analysis info
          if (message.hasAnalysis) ...[
            const SizedBox(height: 12),
            _buildAnalysisInfo(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: message.attachments.map((attachment) {
        return _buildAttachmentChip(context, attachment);
      }).toList(),
    );
  }

  Widget _buildAttachmentChip(
      BuildContext context, MessageAttachment attachment) {
    IconData icon;
    Color color;

    switch (attachment.type) {
      case 'image':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'spreadsheet':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      default:
        icon = Icons.attach_file;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUser ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUser ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isUser ? Colors.white : color),
          const SizedBox(width: 6),
          Text(
            attachment.url.split('/').last,
            style: TextStyle(
              color: isUser ? Colors.white : Colors.grey[800],
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'Đã phân tích',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
