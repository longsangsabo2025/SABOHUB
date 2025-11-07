import 'dart:async' show unawaited;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ai_provider.dart';
import '../../utils/logger_service.dart';

/// Chat input widget with file attachment support
class ChatInputWidget extends ConsumerStatefulWidget {
  final String assistantId;
  final String companyId;
  final VoidCallback? onMessageSent;

  const ChatInputWidget({
    super.key,
    required this.assistantId,
    required this.companyId,
    this.onMessageSent,
  });

  @override
  ConsumerState<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends ConsumerState<ChatInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<PlatformFile> _attachedFiles = [];
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Clear input immediately
    _controller.clear();
    final filesToUpload = List<PlatformFile>.from(_attachedFiles);
    setState(() {
      _isComposing = false;
      _attachedFiles.clear();
    });

    // Upload files if any
    List<Map<String, String>>? attachments;
    if (filesToUpload.isNotEmpty) {
      try {
        // Upload files to Supabase Storage
        final fileUploadService = ref.read(fileUploadServiceProvider);
        final uploadedFiles = <Map<String, String>>[];

        for (final file in filesToUpload) {
          if (file.path != null) {
            try {
              final uploadedFile = await fileUploadService.uploadFile(
                assistantId: widget.assistantId,
                companyId: widget.companyId,
                file: File(file.path!),
                fileName: file.name,
              );

              uploadedFiles.add({
                'type': uploadedFile.fileType,
                'url': uploadedFile.fileUrl,
                'file_id': uploadedFile.id,
              });

              // Automatically trigger file processing in background
              unawaited(
                fileUploadService.processFile(uploadedFile.id).catchError((e) {
                  logger.error('Failed to process file ${uploadedFile.fileName}', e);
                  return uploadedFile; // Return the original file on error
                }),
              );
            } catch (e) {
              logger.error('Failed to upload file ${file.name}', e);
            }
          }
        }

        attachments = uploadedFiles.isNotEmpty ? uploadedFiles : null;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi upload file: $e')),
          );
        }
      }
    }

    // Send message
    try {
      await ref.read(sendMessageNotifierProvider.notifier).sendMessage(
            assistantId: widget.assistantId,
            companyId: widget.companyId,
            content: text,
            attachments: attachments,
          );

      widget.onMessageSent?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
        );
      }
    }

    // Refocus input
    _focusNode.requestFocus();
  }

  void _handleAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt'
        ],
      );

      if (result != null) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn file: $e')),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  // ignore: unused_element
  String _getFileType(String extension) {
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return 'image';
    } else if (ext == 'pdf') {
      return 'pdf';
    } else if (['doc', 'docx'].contains(ext)) {
      return 'doc';
    } else if (['xls', 'xlsx'].contains(ext)) {
      return 'spreadsheet';
    } else {
      return 'text';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sendMessageAsync = ref.watch(sendMessageNotifierProvider);
    final isLoading = sendMessageAsync.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached files preview
          if (_attachedFiles.isNotEmpty) _buildAttachedFiles(),

          // Loading indicator
          if (isLoading)
            LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),

          // Input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: isLoading ? null : _handleAttachment,
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Đính kèm file',
                  color: Colors.grey[600],
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isLoading
                          ? 'AI đang suy nghĩ...'
                          : 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.blue[600]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isComposing = text.trim().isNotEmpty;
                      });
                    },
                    onSubmitted: (_) => _handleSubmit(),
                  ),
                ),

                const SizedBox(width: 8),

                // Send button
                CircleAvatar(
                  backgroundColor: _isComposing && !isLoading
                      ? Colors.blue[600]
                      : Colors.grey[300],
                  child: IconButton(
                    onPressed:
                        _isComposing && !isLoading ? _handleSubmit : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    color: Colors.white,
                    iconSize: 20,
                    tooltip: 'Gửi tin nhắn',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedFiles() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attachment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Đã đính kèm ${_attachedFiles.length} file',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _attachedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return _buildFileChip(file, index);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileChip(PlatformFile file, int index) {
    return Chip(
      avatar: Icon(
        _getFileIcon(file.extension ?? ''),
        size: 16,
        color: Colors.blue[700],
      ),
      label: Text(
        file.name,
        style: const TextStyle(fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => _removeAttachment(index),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    final ext = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
      return Icons.image;
    } else if (ext == 'pdf') {
      return Icons.picture_as_pdf;
    } else if (['doc', 'docx'].contains(ext)) {
      return Icons.description;
    } else if (['xls', 'xlsx'].contains(ext)) {
      return Icons.table_chart;
    } else {
      return Icons.insert_drive_file;
    }
  }
}
