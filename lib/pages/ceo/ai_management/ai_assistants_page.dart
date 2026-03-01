import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ai_chat_service.dart';
import '../../../services/ceo_report_generator.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_logger.dart';

class AIAssistantsPage extends ConsumerStatefulWidget {
  const AIAssistantsPage({super.key});

  @override
  ConsumerState<AIAssistantsPage> createState() => _AIAssistantsPageState();
}

class _AIAssistantsPageState extends ConsumerState<AIAssistantsPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final aiMode = AIChatService().isAIEnabled;
    _addBotMessage(
      '👋 Xin chào! Tôi là trợ lý AI của SABOHUB.\n'
      '${aiMode ? "🤖 **Gemini AI đã kết nối** — Tôi có thể phân tích dữ liệu và trả lời tự do!" : "📊 Chế độ: Truy vấn dữ liệu (thêm GEMINI_API_KEY để nâng cấp AI)"}\n\n'
      'Bạn có thể hỏi tôi về:\n'
      '• 📊 **Doanh thu** — "Doanh thu hôm nay/tuần này/tháng này?"\n'
      '• 📦 **Đơn hàng** — "Có bao nhiêu đơn hàng mới?"\n'
      '• 👥 **Khách hàng** — "Top khách hàng?" \n'
      '• 📋 **Tồn kho** — "Sản phẩm nào sắp hết?"\n'
      '• 👨‍💼 **Nhân viên** — "Ai đi làm hôm nay?"\n'
      '• 📈 **Tổng quan** — "Báo cáo tổng quan"\n'
      '• 📄 **Xuất PDF** — "Xuất báo cáo PDF"\n'
      '${aiMode ? "• 💬 **Hỏi tự do** — Bất kỳ câu hỏi nào về kinh doanh!" : ""}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false, time: DateTime.now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final user = ref.read(currentUserProvider);
      final companyId = user?.companyId ?? '';
      final response = await AIChatService().processQuery(text, companyId);
      if (response == '__PDF_EXPORT__') {
        _addBotMessage('📄 Đang tạo báo cáo PDF...');
        await CeoReportGenerator().generateAndPrint(companyId);
        _addBotMessage('✅ Đã tạo báo cáo PDF!');
      } else {
        _addBotMessage(response);
      }
    } catch (e) {
      AppLogger.error('AI Chat error', e);
      _addBotMessage('❌ Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại.\n\n_${e.toString()}_');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.smart_toy, size: 24),
            const SizedBox(width: 8),
            const Text('AI Assistant'),
            if (AIChatService().isAIEnabled) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Gemini',
                  style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa lịch sử chat',
            onPressed: () {
              setState(() => _messages.clear());
              _addBotMessage('🗑️ Đã xóa lịch sử. Hỏi tôi bất cứ điều gì!');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Bắt đầu cuộc trò chuyện...'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index], theme);
                    },
                  ),
          ),

          // Quick action chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildQuickChip('📊 Doanh thu hôm nay'),
                _buildQuickChip('📦 Đơn hàng mới'),
                _buildQuickChip('📋 Tồn kho thấp'),
                _buildQuickChip('👥 Top khách hàng'),
                _buildQuickChip('📈 Báo cáo tổng quan'),
                _buildQuickChip('📄 Xuất PDF'),
                if (AIChatService().isAIEnabled)
                  _buildQuickChip('💡 Gợi ý tăng doanh thu'),
              ],
            ),
          ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Hỏi về doanh thu, đơn hàng, tồn kho...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    child: IconButton(
                      icon: Icon(
                        _isLoading ? Icons.hourglass_top : Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _controller.text = label;
          _sendMessage();
        },
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              child:
                  Icon(Icons.smart_toy, size: 18, color: theme.primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? theme.primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: const Icon(Icons.person, size: 18, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Icon(Icons.smart_toy,
                size: 18, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Đang xử lý...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}
