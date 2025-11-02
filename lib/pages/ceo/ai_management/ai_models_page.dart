import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AI Models Configuration Page
class AIModelsPage extends ConsumerStatefulWidget {
  const AIModelsPage({super.key});

  @override
  ConsumerState<AIModelsPage> createState() => _AIModelsPageState();
}

class _AIModelsPageState extends ConsumerState<AIModelsPage> {
  final List<AIModel> _models = [
    AIModel(
      id: 'gpt-4',
      name: 'GPT-4',
      provider: 'OpenAI',
      status: 'active',
      description: 'Most capable GPT model for complex tasks',
      pricing: '\$0.03/1K tokens',
      maxTokens: 8192,
      capabilities: ['Text Generation', 'Code', 'Analysis', 'Function Calling'],
    ),
    AIModel(
      id: 'claude-3',
      name: 'Claude 3 Sonnet',
      provider: 'Anthropic',
      status: 'active',
      description: 'Balanced performance and speed',
      pricing: '\$0.015/1K tokens',
      maxTokens: 200000,
      capabilities: ['Text Generation', 'Analysis', 'Long Context'],
    ),
    AIModel(
      id: 'gpt-3.5',
      name: 'GPT-3.5 Turbo',
      provider: 'OpenAI',
      status: 'active',
      description: 'Fast and cost-effective for simple tasks',
      pricing: '\$0.002/1K tokens',
      maxTokens: 16385,
      capabilities: ['Text Generation', 'Chat'],
    ),
    AIModel(
      id: 'gemini-pro',
      name: 'Gemini Pro',
      provider: 'Google',
      status: 'inactive',
      description: 'Google\'s multimodal AI model',
      pricing: '\$0.005/1K tokens',
      maxTokens: 32768,
      capabilities: ['Text', 'Vision', 'Code'],
    ),
    AIModel(
      id: 'llama-70b',
      name: 'Llama 2 70B',
      provider: 'Meta',
      status: 'inactive',
      description: 'Open source large language model',
      pricing: 'Free',
      maxTokens: 4096,
      capabilities: ['Text Generation', 'Open Source'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Models Configuration',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Quản lý và cấu hình các AI models',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addNewModel,
                icon: const Icon(Icons.add),
                label: const Text('Add Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Models',
                  '3',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Usage',
                  '2.4K',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Monthly Cost',
                  '\$124',
                  Icons.monetization_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Avg Response',
                  '1.2s',
                  Icons.speed,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Models Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _models.length,
              itemBuilder: (context, index) {
                return _buildModelCard(_models[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(AIModel model) {
    final isActive = model.status == 'active';
    final statusColor = isActive ? Colors.green : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? Colors.purple.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        model.provider,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    model.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              model.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Specs
            Row(
              children: [
                Icon(Icons.token, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${model.maxTokens}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Text(
                  model.pricing,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Capabilities
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: model.capabilities.take(2).map((capability) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    capability,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _configureModel(model),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Config'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isActive
                        ? () => _testModel(model)
                        : () => _activateModel(model),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.blue : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(isActive ? 'Test' : 'Activate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewModel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New AI Model'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Model Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Provider',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'API Endpoint',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add Model'),
          ),
        ],
      ),
    );
  }

  void _configureModel(AIModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure ${model.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provider: ${model.provider}'),
            Text('Max Tokens: ${model.maxTokens}'),
            Text('Pricing: ${model.pricing}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.visibility),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _testModel(AIModel model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test ${model.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Test Prompt',
                border: OutlineInputBorder(),
                hintText: 'Enter a test message...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
  }

  void _activateModel(AIModel model) {
    setState(() {
      model.status = 'active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${model.name} has been activated')),
    );
  }
}

class AIModel {
  final String id;
  final String name;
  final String provider;
  String status;
  final String description;
  final String pricing;
  final int maxTokens;
  final List<String> capabilities;

  AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.status,
    required this.description,
    required this.pricing,
    required this.maxTokens,
    required this.capabilities,
  });
}
