import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../../../../../../core/theme/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Message model
class AIMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final AIFunctionCall? functionCall;
  final Map<String, dynamic>? functionResult;

  AIMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.functionCall,
    this.functionResult,
  });
}

/// Function call model
class AIFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  AIFunctionCall({
    required this.name,
    required this.arguments,
  });
}

/// AI Mode types
enum AIModeType { standard, document, autoExecute }

/// AI Mode configuration
class AIModeConfig {
  final String name;
  final String icon;
  final String description;
  final bool autoExecute;
  final List<String> allowedFunctions;

  const AIModeConfig({
    required this.name,
    required this.icon,
    required this.description,
    required this.autoExecute,
    required this.allowedFunctions,
  });
}

/// AI Assistant page for CEO
class CEOAIAssistantPage extends ConsumerStatefulWidget {
  const CEOAIAssistantPage({super.key});

  @override
  ConsumerState<CEOAIAssistantPage> createState() => _CEOAIAssistantPageState();
}

class _CEOAIAssistantPageState extends ConsumerState<CEOAIAssistantPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  bool _isLoading = false;
  AIModeType _currentMode = AIModeType.standard;
  bool _showModeSelector = false;

  /// AI Mode configurations
  static const Map<AIModeType, AIModeConfig> _aiModes = {
    AIModeType.standard: AIModeConfig(
      name: 'Trợ lý thông minh',
      icon: '🤖',
      description: 'AI hỗ trợ với xác nhận trước khi thực thi',
      autoExecute: false,
      allowedFunctions: ['all'],
    ),
    AIModeType.document: AIModeConfig(
      name: 'Phân tích tài liệu',
      icon: '📊',
      description: 'Tự động phân tích và trích xuất dữ liệu',
      autoExecute: true,
      allowedFunctions: [
        'analyze_revenue',
        'get_reports',
        'analyze_performance'
      ],
    ),
    AIModeType.autoExecute: AIModeConfig(
      name: 'Tự động hóa',
      icon: '⚡',
      description: 'Thực thi tự động mọi lệnh an toàn',
      autoExecute: true,
      allowedFunctions: ['all'],
    ),
  };

  /// Available AI functions (for future use)
  // ignore: unused_field
  static final List<Map<String, dynamic>> _aiFunctions = [
    {
      "name": "analyze_company_performance",
      "description": "Phân tích hiệu suất của tất cả công ty",
      "parameters": {
        "type": "object",
        "properties": {
          "period": {
            "type": "string",
            "enum": ["day", "week", "month", "quarter"]
          },
          "metrics": {
            "type": "array",
            "items": {"type": "string"}
          }
        },
        "required": ["period"]
      }
    },
    {
      "name": "get_executive_summary",
      "description": "Tạo báo cáo tổng quan điều hành",
      "parameters": {
        "type": "object",
        "properties": {
          "include_forecast": {"type": "boolean"},
          "focus_areas": {
            "type": "array",
            "items": {"type": "string"}
          }
        }
      }
    },
    {
      "name": "monitor_critical_alerts",
      "description": "Kiểm tra cảnh báo quan trọng cần chú ý",
      "parameters": {
        "type": "object",
        "properties": {
          "severity": {
            "type": "string",
            "enum": ["low", "medium", "high", "critical"]
          }
        }
      }
    },
    {
      "name": "analyze_revenue_trends",
      "description": "Phân tích xu hướng doanh thu",
      "parameters": {
        "type": "object",
        "properties": {
          "timeframe": {
            "type": "string",
            "enum": ["last_week", "last_month", "last_quarter"]
          },
          "compare_previous": {"type": "boolean"}
        },
        "required": ["timeframe"]
      }
    }
  ];

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
    final welcomeMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'assistant',
      content:
          '👋 Chào CEO! Tôi là AI trợ lý thông minh.\n\n🎯 Tôi có thể giúp bạn:\n• Phân tích hiệu suất công ty\n• Tạo báo cáo tổng quan\n• Theo dõi cảnh báo quan trọng\n• Phân tích xu hướng doanh thu\n\nBạn cần tôi hỗ trợ gì?',
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(welcomeMessage);
    });
  }

  /// Mock AI response for testing
  Map<String, dynamic> _mockAIResponse(String userInput) {
    final input = userInput.toLowerCase();

    if (input.contains('hiệu suất') || input.contains('performance')) {
      return {
        'content': 'Đang phân tích hiệu suất tất cả công ty...',
        'function_call': {
          'name': 'analyze_company_performance',
          'arguments': json.encode({
            'period': 'month',
            'metrics': ['revenue', 'growth']
          })
        }
      };
    }

    if (input.contains('báo cáo') || input.contains('tổng quan')) {
      return {
        'content': 'Đang tạo báo cáo tổng quan điều hành...',
        'function_call': {
          'name': 'get_executive_summary',
          'arguments': json.encode({
            'include_forecast': true,
            'focus_areas': ['revenue', 'operations']
          })
        }
      };
    }

    if (input.contains('cảnh báo') || input.contains('alert')) {
      return {
        'content': 'Đang kiểm tra cảnh báo quan trọng...',
        'function_call': {
          'name': 'monitor_critical_alerts',
          'arguments': json.encode({'severity': 'high'})
        }
      };
    }

    if (input.contains('doanh thu') || input.contains('revenue')) {
      return {
        'content': 'Đang phân tích xu hướng doanh thu...',
        'function_call': {
          'name': 'analyze_revenue_trends',
          'arguments':
              json.encode({'timeframe': 'last_month', 'compare_previous': true})
        }
      };
    }

    return {
      'content':
          'Tôi đã hiểu yêu cầu: "$userInput"\n\n🔧 Tôi có thể giúp bạn:\n• Phân tích hiệu suất công ty\n• Tạo báo cáo tổng quan\n• Theo dõi cảnh báo quan trọng\n• Phân tích xu hướng doanh thu\n\nVui lòng cho tôi biết cụ thể hơn!'
    };
  }

  /// Call AI with function calling capability
  Future<Map<String, dynamic>> _callAIWithFunctions(
      String userInput, List<AIMessage> history) async {
    final apiKey = dotenv.env['GITHUB_TOKEN']; // Using GitHub Models API

    // Mock mode for testing
    if (apiKey == null || apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 1));
      return _mockAIResponse(userInput);
    }

    // Real AI API call would go here
    // For now, return mock response
    await Future.delayed(const Duration(seconds: 1));
    return _mockAIResponse(userInput);
  }

  /// Execute AI function
  Future<Map<String, dynamic>> _executeFunction(
      String functionName, Map<String, dynamic> args) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    switch (functionName) {
      case 'analyze_company_performance':
        return {
          'success': true,
          'analysis': {
            'total_stores': 12,
            'top_performer': 'Sabo Pool Bình Thạnh',
            'revenue_growth': '+15.2%',
            'performance_score': 8.7
          },
          'insights': [
            '📈 Doanh thu tăng 15.2% so với tháng trước',
            '🏆 Sabo Pool Bình Thạnh dẫn đầu với 2.8 tỷ VNĐ',
            '⚠️ 3 cơ sở cần cải thiện hiệu suất',
            '💡 Gợi ý: Tăng marketing cho chi nhánh yếu'
          ]
        };

      case 'get_executive_summary':
        return {
          'success': true,
          'summary': {
            'total_revenue': '18.5 tỷ VNĐ',
            'growth_rate': '+12.8%',
            'active_locations': 12,
            'customer_satisfaction': 4.6
          },
          'forecast': {
            'next_month_revenue': '20.1 tỷ VNĐ',
            'growth_prediction': '+8.7%'
          },
          'key_insights': [
            '🎯 Đạt 103% target tháng này',
            '👥 Khách hàng hài lòng 4.6/5 điểm',
            '📊 Xu hướng tăng trưởng ổn định',
            '⭐ Chất lượng dịch vụ được đánh giá cao'
          ]
        };

      case 'monitor_critical_alerts':
        return {
          'success': true,
          'alerts': [
            {
              'type': 'revenue',
              'severity': 'high',
              'message': 'Doanh thu chi nhánh Quận 7 giảm 8% tuần này',
              'action_needed': 'Kiểm tra nguyên nhân và đưa ra biện pháp'
            },
            {
              'type': 'inventory',
              'severity': 'medium',
              'message': 'Kho thiết bị bi-a sắp hết tại 2 chi nhánh',
              'action_needed': 'Đặt hàng bổ sung trong 3 ngày'
            }
          ],
          'summary': 'Có 2 cảnh báo cần chú ý: 1 mức cao, 1 mức trung bình'
        };

      case 'analyze_revenue_trends':
        return {
          'success': true,
          'trends': {
            'current_month': '18.5 tỷ VNĐ',
            'previous_month': '16.4 tỷ VNĐ',
            'growth': '+12.8%',
            'trend_direction': 'increasing'
          },
          'analysis': [
            '📈 Tăng trưởng ổn định 12.8% so với tháng trước',
            '🎯 Vượt target 3% trong tháng này',
            '🔥 Weekend peaks: Thứ 7-CN đóng góp 40% doanh thu',
            '💼 Corporate events tăng 25% so với cùng kỳ'
          ]
        };

      default:
        return {
          'success': false,
          'error': 'Function không được hỗ trợ: $functionName'
        };
    }
  }

  /// Format function result for display
  String _formatFunctionResult(Map<String, dynamic> result) {
    if (result['success'] != true) {
      return '❌ ${result['error'] ?? 'Lỗi thực thi'}\n${result['suggestion'] ?? ''}';
    }

    String output = '✅ Thành công!\n\n';

    if (result['analysis'] != null) {
      final analysis = result['analysis'];
      output += '📊 **Phân tích hiệu suất:**\n';
      output += '• Tổng số cửa hàng: ${analysis['total_stores']}\n';
      output += '• Top performer: ${analysis['top_performer']}\n';
      output += '• Tăng trưởng: ${analysis['revenue_growth']}\n';
      output += '• Điểm hiệu suất: ${analysis['performance_score']}/10\n\n';

      if (result['insights'] != null) {
        output += '💡 **Insights:**\n';
        for (String insight in result['insights']) {
          output += '• $insight\n';
        }
      }
    }

    if (result['summary'] != null) {
      final summary = result['summary'];
      output += '📋 **Tổng quan điều hành:**\n';
      output += '• Doanh thu: ${summary['total_revenue']}\n';
      output += '• Tăng trưởng: ${summary['growth_rate']}\n';
      output += '• Số chi nhánh: ${summary['active_locations']}\n';
      output += '• Hài lòng KH: ${summary['customer_satisfaction']}/5\n\n';

      if (result['forecast'] != null) {
        final forecast = result['forecast'];
        output += '🔮 **Dự báo tháng tới:**\n';
        output += '• Doanh thu dự kiến: ${forecast['next_month_revenue']}\n';
        output += '• Tăng trưởng dự kiến: ${forecast['growth_prediction']}\n\n';
      }

      if (result['key_insights'] != null) {
        output += '🎯 **Key Insights:**\n';
        for (String insight in result['key_insights']) {
          output += '• $insight\n';
        }
      }
    }

    if (result['alerts'] != null) {
      output += '🚨 **Cảnh báo quan trọng:**\n';
      for (var alert in result['alerts']) {
        final severity = alert['severity'] == 'high' ? '🔴' : '🟡';
        output += '$severity ${alert['message']}\n';
        output += '   → ${alert['action_needed']}\n\n';
      }
      if (result['summary'] != null) {
        output += result['summary'];
      }
    }

    if (result['trends'] != null) {
      final trends = result['trends'];
      output += '📈 **Xu hướng doanh thu:**\n';
      output += '• Tháng này: ${trends['current_month']}\n';
      output += '• Tháng trước: ${trends['previous_month']}\n';
      output += '• Tăng trưởng: ${trends['growth']}\n\n';

      if (result['analysis'] != null) {
        output += '🔍 **Phân tích chi tiết:**\n';
        for (String analysis in result['analysis']) {
          output += '• $analysis\n';
        }
      }
    }

    return output;
  }

  /// Send message and handle AI response
  Future<void> _handleSend() async {
    if (_inputController.text.trim().isEmpty || _isLoading) return;

    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: _inputController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _inputController.clear();
    _scrollToBottom();

    try {
      // Call AI with function calling
      final aiResponse =
          await _callAIWithFunctions(userMessage.content, _messages);

      if (aiResponse['function_call'] != null) {
        // AI wants to call a function
        final functionCall = aiResponse['function_call'];
        final functionName = functionCall['name'];
        final functionArgs = json.decode(functionCall['arguments']);

        // Check if auto-execute is enabled for current mode
        final modeConfig = _aiModes[_currentMode]!;
        final shouldAutoExecute = modeConfig.autoExecute ||
            [
              'analyze_company_performance',
              'get_executive_summary',
              'monitor_critical_alerts',
              'analyze_revenue_trends'
            ].contains(functionName);

        // Show AI processing message
        final processingMessage = AIMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'assistant',
          content: shouldAutoExecute
              ? '⚡ Đang xử lý: ${_getFunctionDescription(functionName, functionArgs)}...'
              : '🤖 Tôi sẽ thực hiện:\n\n📋 **$functionName**\n${json.encode(functionArgs, toEncodable: (v) => v)}\n\n✅ Bạn có muốn tôi thực hiện không?',
          timestamp: DateTime.now(),
          functionCall:
              AIFunctionCall(name: functionName, arguments: functionArgs),
        );

        setState(() {
          _messages.add(processingMessage);
        });
        _scrollToBottom();

        if (shouldAutoExecute) {
          // Auto-execute function
          await _executeFunctionAndShowResult(functionName, functionArgs);
        } else {
          // Show confirmation dialog
          _showConfirmationDialog(functionName, functionArgs);
        }
      } else {
        // Normal AI response
        final assistantMessage = AIMessage(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          role: 'assistant',
          content: aiResponse['content'],
          timestamp: DateTime.now(),
        );

        setState(() {
          _messages.add(assistantMessage);
        });
        _scrollToBottom();
      }
    } catch (error) {
      final errorMessage = AIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content:
            '⚠️ Xin lỗi, đã có lỗi xảy ra.\n\nChi tiết: ${error.toString()}',
        timestamp: DateTime.now(),
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

  /// Execute function and show result
  Future<void> _executeFunctionAndShowResult(
      String functionName, Map<String, dynamic> functionArgs) async {
    try {
      final result = await _executeFunction(functionName, functionArgs);

      // Show result
      final resultMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'function',
        content: _formatFunctionResult(result),
        timestamp: DateTime.now(),
        functionResult: result,
      );

      setState(() {
        _messages.add(resultMessage);
      });
      _scrollToBottom();

      // Ask AI to summarize the result
      final summaryResponse = await _callAIWithFunctions(
        'Function $functionName executed successfully. Result: ${json.encode(result)}. Hãy tóm tắt kết quả cho CEO biết.',
        _messages,
      );

      final summaryMessage = AIMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: summaryResponse['content'],
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(summaryMessage);
      });
      _scrollToBottom();
    } catch (error) {
      final errorMessage = AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content: '❌ Lỗi khi thực hiện: ${error.toString()}',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
      });
      _scrollToBottom();
    }
  }

  /// Show confirmation dialog for function execution
  void _showConfirmationDialog(
      String functionName, Map<String, dynamic> functionArgs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 Xác nhận hành động'),
        content: Text(
            'Tôi sẽ ${_getFunctionDescription(functionName, functionArgs)}\n\nBạn có đồng ý không?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final cancelMessage = AIMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                role: 'assistant',
                content: '👌 Đã hủy. Bạn cần tôi làm gì khác không?',
                timestamp: DateTime.now(),
              );
              setState(() {
                _messages.add(cancelMessage);
              });
              _scrollToBottom();
            },
            child: const Text('❌ Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeFunctionAndShowResult(functionName, functionArgs);
            },
            child: const Text('✅ Đồng ý'),
          ),
        ],
      ),
    );
  }

  /// Get function description for confirmation
  String _getFunctionDescription(
      String functionName, Map<String, dynamic> args) {
    switch (functionName) {
      case 'analyze_company_performance':
        return 'phân tích hiệu suất ${args['period'] ?? 'tất cả'} công ty';
      case 'get_executive_summary':
        return 'tạo báo cáo tổng quan điều hành';
      case 'monitor_critical_alerts':
        return 'kiểm tra cảnh báo mức độ ${args['severity'] ?? 'tất cả'}';
      case 'analyze_revenue_trends':
        return 'phân tích xu hướng doanh thu ${args['timeframe'] ?? ''}';
      default:
        return 'thực hiện $functionName';
    }
  }

  /// Scroll to bottom
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

  /// Clear chat history
  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Xóa Lịch Sử Chat'),
        content: const Text(
            'Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
              });
              _addWelcomeMessage();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.info,
        title: const Text(
          '🤖 AI Trợ Lý CEO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _clearChatHistory,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          InkWell(
            onTap: () => setState(() => _showModeSelector = !_showModeSelector),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _aiModes[_currentMode]!.icon,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _aiModes[_currentMode]!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Coming Soon Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            child: const Row(
              children: [
                Icon(Icons.construction, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tính năng AI đang phát triển. Dữ liệu hiển thị là mô phỏng.',
                    style: TextStyle(fontSize: 13, color: Colors.brown),
                  ),
                ),
              ],
            ),
          ),

          // AI Mode Selector
          if (_showModeSelector) _buildModeSelector(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Loading indicator
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
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

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    maxLength: 500,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText:
                          'Giao việc, hỏi thông tin, yêu cầu phân tích...',
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
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
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        _inputController.text.trim().isNotEmpty && !_isLoading
                            ? AppColors.info
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
      ),
    );
  }

  /// Build AI mode selector
  Widget _buildModeSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn chế độ AI:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...AIModeType.values.map((mode) {
            final config = _aiModes[mode]!;
            final isSelected = mode == _currentMode;

            return InkWell(
              onTap: () {
                setState(() {
                  _currentMode = mode;
                  _showModeSelector = false;
                });

                // Add mode change message
                final modeChangeMessage = AIMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  role: 'assistant',
                  content:
                      '✨ Đã chuyển sang ${config.name}!\n\n${config.description}',
                  timestamp: DateTime.now(),
                );

                setState(() {
                  _messages.add(modeChangeMessage);
                });
                _scrollToBottom();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.info.withValues(alpha: 0.1)
                      : null,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.info
                        : const Color(0xFFE5E7EB),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(config.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected ? AppColors.info : null,
                            ),
                          ),
                          Text(
                            config.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle, color: AppColors.info),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build message bubble
  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.role == 'user';
    final isFunction = message.role == 'function';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                color: isFunction
                    ? AppColors.success
                    : AppColors.info,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isFunction ? Icons.settings : Icons.smart_toy,
                color: Colors.white,
                size: 20,
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
                color: isUser
                    ? AppColors.info
                    : isFunction
                        ? AppColors.success
                        : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: !isUser && !isFunction
                    ? Border.all(color: const Color(0xFFE5E7EB))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser || isFunction
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser || isFunction
                          ? Colors.white.withValues(alpha: 0.7)
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
                color: AppColors.info,
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
}
