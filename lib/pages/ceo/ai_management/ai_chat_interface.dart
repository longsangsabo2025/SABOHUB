import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Chat Interface - Popup chat window
class AIChatInterface extends ConsumerStatefulWidget {
  const AIChatInterface({super.key});

  @override
  ConsumerState<AIChatInterface> createState() => _AIChatInterfaceState();
}

class _AIChatInterfaceState extends ConsumerState<AIChatInterface> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedAssistant = 'ceo_assistant';

  // Available AI Assistants
  final Map<String, AIAssistant> _assistants = {
    'ceo_assistant': AIAssistant(
      id: 'ceo_assistant',
      name: 'CEO Executive Assistant',
      icon: '👔',
      description: 'Trợ lý điều hành cấp cao',
      systemPrompt:
          'You are a CEO executive assistant for SABOHUB billiards business...',
      model: 'gpt-4',
    ),
    'sales_advisor': AIAssistant(
      id: 'sales_advisor',
      name: 'Sales Advisor',
      icon: '💼',
      description: 'Tư vấn bán hàng và marketing',
      systemPrompt: 'You are a sales and marketing advisor...',
      model: 'gpt-4',
    ),
    'data_analyst': AIAssistant(
      id: 'data_analyst',
      name: 'Data Analyst',
      icon: '📊',
      description: 'Phân tích dữ liệu và báo cáo',
      systemPrompt:
          'You are a data analyst specializing in business intelligence...',
      model: 'claude-3',
    ),
    'support_agent': AIAssistant(
      id: 'support_agent',
      name: 'Support Agent',
      icon: '🎧',
      description: 'Hỗ trợ khách hàng',
      systemPrompt: 'You are a customer support specialist...',
      model: 'gpt-3.5',
    ),
  };

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final assistant = _assistants[_selectedAssistant]!;
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content:
          '${assistant.icon} Chào CEO! Tôi là ${assistant.name}.\n\n${assistant.description}\n\nTôi có thể giúp gì cho bạn hôm nay?',
      timestamp: DateTime.now(),
      assistantId: _selectedAssistant,
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentAssistant = _assistants[_selectedAssistant]!;

    return Column(
      children: [
        // Header with Assistant Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              // Assistant Selector
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedAssistant,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        currentAssistant.icon,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  items: _assistants.entries.map((entry) {
                    final assistant = entry.value;
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Row(
                        children: [
                          Text(assistant.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  assistant.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  assistant.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && value != _selectedAssistant) {
                      setState(() {
                        _selectedAssistant = value;
                        _messages.clear();
                      });
                      _addWelcomeMessage();
                    }
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Close Button
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          currentAssistant.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'AI đang suy nghĩ...',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
        ),

        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            children: [
              // Model info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  currentAssistant.model.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  maxLength: 1000,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn cho ${currentAssistant.name}...',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _inputController.text.trim().isNotEmpty && !_isLoading
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: IconButton(
                  onPressed:
                      _inputController.text.trim().isNotEmpty && !_isLoading
                          ? _handleSend
                          : null,
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final assistant = _assistants[message.assistantId ?? _selectedAssistant]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  assistant.icon,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    !isUser ? Border.all(color: const Color(0xFFE5E7EB)) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                    Text(
                      assistant.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : const Color(0xFF1F2937),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser
                          ? Colors.white.withOpacity(0.7)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleSend() async {
    if (_inputController.text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: _inputController.text.trim(),
      timestamp: DateTime.now(),
      assistantId: _selectedAssistant,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      // Mock AI response based on selected assistant
      await Future.delayed(const Duration(seconds: 2));

      final assistant = _assistants[_selectedAssistant]!;
      String response = _generateMockResponse(userMessage.content, assistant);

      final assistantMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        assistantId: _selectedAssistant,
      );

      setState(() {
        _messages.add(assistantMessage);
      });
      _scrollToBottom();
    } catch (error) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: '⚠️ Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại.',
        timestamp: DateTime.now(),
        assistantId: _selectedAssistant,
      );

      setState(() {
        _messages.add(errorMessage);
      });
      _scrollToBottom();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateMockResponse(String userInput, AIAssistant assistant) {
    final input = userInput.toLowerCase();

    switch (assistant.id) {
      case 'ceo_assistant':
        if (input.contains('doanh thu') || input.contains('revenue')) {
          return '📊 **Báo cáo doanh thu tháng này:**\n\n• Tổng doanh thu: 18.5 tỷ VNĐ (+12.8%)\n• Top performer: Sabo Pool Bình Thạnh\n• Xu hướng: Tăng trưởng ổn định\n• Gợi ý: Mở rộng mô hình thành công sang 2 chi nhánh mới';
        } else if (input.contains('hiệu suất') ||
            input.contains('performance')) {
          return '⭐ **Phân tích hiệu suất hệ thống:**\n\n• 12 chi nhánh đang hoạt động\n• Điểm hiệu suất trung bình: 8.7/10\n• 3 chi nhánh cần cải thiện\n• 💡 Đề xuất: Tập trung training cho đội ngũ yếu';
        } else {
          return '👔 Tôi là CEO Executive Assistant. Tôi có thể giúp bạn:\n\n• Phân tích doanh thu và hiệu suất\n• Báo cáo tổng quan điều hành\n• Đưa ra các quyết định strategtic\n• Theo dõi KPIs quan trọng\n\nBạn muốn tôi phân tích điều gì?';
        }

      case 'sales_advisor':
        if (input.contains('marketing') || input.contains('quảng cáo')) {
          return '💼 **Chiến lược Marketing Q4:**\n\n• Social Media: Tăng 40% engagement\n• Google Ads: ROI 3.2x\n• Event Marketing: 15 sự kiện đã tổ chức\n• 🎯 Gợi ý: Tập trung vào TikTok cho Gen Z';
        } else {
          return '💼 Chào CEO! Tôi là Sales Advisor. Tôi có thể hỗ trợ:\n\n• Chiến lược bán hàng\n• Phân tích thị trường\n• Tối ưu conversion rate\n• Marketing campaigns\n\nBạn cần tư vấn về lĩnh vực nào?';
        }

      case 'data_analyst':
        return '📊 **Data Analysis Report:**\n\n• Customer retention: 78% (+5%)\n• Average session time: 2.4h\n• Peak hours: 19:00-22:00\n• Trend: Weekend traffic tăng 25%\n\n🔍 **Insights:** Khách hàng thích đến vào cuối tuần và tối muộn.';

      case 'support_agent':
        return '🎧 **Customer Support Summary:**\n\n• Satisfaction score: 4.6/5\n• Response time: 2.3 phút\n• Resolved tickets: 97%\n• Common issues: Booking, Payment\n\n✅ **Recommendation:** Cải thiện hệ thống booking online.';

      default:
        return 'Tôi đã hiểu yêu cầu của bạn. Đang xử lý...';
    }
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
}

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final String? assistantId;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.assistantId,
  });
}

class AIAssistant {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String systemPrompt;
  final String model;

  AIAssistant({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.systemPrompt,
    required this.model,
  });
}
