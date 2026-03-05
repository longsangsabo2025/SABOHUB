import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ai_assistant.dart';
import '../../models/ai_message.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/ai/chat_input_widget.dart';
import '../../widgets/ai/chat_message_widget.dart';
import '../../widgets/ai/file_gallery_widget.dart';
import '../../widgets/ai/recommendations_list_widget.dart';
import '../../widgets/ai/usage_stats_card.dart';

/// AI Assistant Tab for company details page
class AIAssistantTab extends ConsumerStatefulWidget {
  final String companyId;
  final String companyName;

  const AIAssistantTab({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  ConsumerState<AIAssistantTab> createState() => _AIAssistantTabState();
}

class _AIAssistantTabState extends ConsumerState<AIAssistantTab> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showButton =
        _scrollController.hasClients && _scrollController.offset > 200;
    if (showButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showButton;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistantAsync = ref.watch(aiAssistantProvider(widget.companyId));

    return assistantAsync.when(
      data: (assistant) {
        return _buildChatInterface(assistant);
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      error: (error, stack) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'Không thể tải AI Assistant',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(aiAssistantProvider(widget.companyId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatInterface(AIAssistant assistant) {
    final messagesAsync = ref.watch(aiMessagesStreamProvider(assistant.id));

    return Column(
      children: [
        // Header with file gallery button
        _buildHeader(assistant),

        // Usage Stats Card
        _buildUsageStats(assistant),

        // Chat Messages
        Expanded(
          child: messagesAsync.when(
            data: (messages) => _buildMessageList(messages, assistant),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorView(error),
          ),
        ),

        // Chat Input
        ChatInputWidget(
          assistantId: assistant.id,
          companyId: widget.companyId,
          userId: ref.read(currentUserProvider)?.id ?? '',
          onMessageSent: () {
            // Scroll to bottom after sending message
            Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
          },
        ),
      ],
    );
  }

  Widget _buildHeader(AIAssistant assistant) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.smart_toy, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: () => _showRecommendations(assistant),
            tooltip: 'Xem đề xuất AI',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _showFileGallery(assistant),
            tooltip: 'Xem file đã tải lên',
          ),
        ],
      ),
    );
  }

  void _showRecommendations(AIAssistant assistant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb,
                          size: 28, color: Colors.orange[700]),
                      SizedBox(width: 12),
                      Text(
                        'Đề xuất từ AI',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Recommendations List
                Expanded(
                  child: RecommendationsListWidget(
                    assistantId: assistant.id,
                    companyId: widget.companyId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFileGallery(AIAssistant assistant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.folder, size: 28, color: Colors.blue[700]),
                      SizedBox(width: 12),
                      Text(
                        'File đã tải lên',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // File Gallery
                Expanded(
                  child: FileGalleryWidget(
                    assistantId: assistant.id,
                    companyId: widget.companyId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUsageStats(AIAssistant assistant) {
    final currentMonthUsage =
        ref.watch(currentMonthUsageProvider(widget.companyId));

    return currentMonthUsage.when(
      data: (usage) => usage != null
          ? UsageStatsCard(usage: usage)
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMessageList(List<AIMessage> messages, AIAssistant assistant) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ChatMessageWidget(
              message: message,
              companyName: widget.companyName,
            );
          },
        ),

        // Scroll to bottom button
        if (_showScrollToBottom)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: _scrollToBottom,
              child: const Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 24),
            Text(
              'Xin chào! 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Tôi là trợ lý AI của ${widget.companyName}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tôi có thể giúp bạn:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('📊 Phân tích doanh thu và chi phí'),
                  _buildFeatureItem('💡 Đưa ra các đề xuất cải thiện'),
                  _buildFeatureItem('📈 Dự đoán xu hướng kinh doanh'),
                  _buildFeatureItem('📄 Phân tích tài liệu và hình ảnh'),
                  _buildFeatureItem('❓ Trả lời các câu hỏi về nhà hàng'),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Gửi tin nhắn để bắt đầu trò chuyện! 💬',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    final String errorMessage = error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Lỗi tải AI Assistant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 8),
            Text(
              'Chi tiết lỗi:\n$errorMessage',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Company ID: ${widget.companyId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                    fontFamily: 'monospace',
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(aiAssistantProvider(widget.companyId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
