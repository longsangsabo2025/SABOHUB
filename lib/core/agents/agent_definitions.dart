import 'agent_types.dart';

/// ============================================================================
/// SABO AGENT DEFINITIONS — Built-in Agents
/// Each agent is a specialist with specific tools and instructions.
/// Inspired by Codebuff's multi-agent approach (File Picker → Planner →
/// Editor → Reviewer), adapted for business intelligence.
/// ============================================================================

class SaboAgents {
  SaboAgents._();

  // ─── Router Agent ─────────────────────────────────────────────
  static const router = AgentDefinition(
    id: 'sabo-router',
    displayName: 'Intent Router',
    role: AgentRole.router,
    model: 'rule-based', // No LLM needed — keyword + pattern matching
    instructions: '''
Analyze user query and determine intent category:
- revenue / sales → DataFetcher(revenue)
- orders → DataFetcher(orders)
- inventory / stock → DataFetcher(inventory)
- employees / attendance → DataFetcher(employees)
- delivery → DataFetcher(delivery)
- debt → DataFetcher(debt)
- overview / report → DataFetcher(overview)
- comparison / trend → Planner(multi-step)
- unknown → Gemini free-form
''',
    toolNames: ['intent_classify', 'keyword_match'],
  );

  // ─── Data Fetcher Agent ───────────────────────────────────────
  static const dataFetcher = AgentDefinition(
    id: 'sabo-data-fetcher',
    displayName: 'Data Fetcher',
    role: AgentRole.dataFetcher,
    model: 'supabase-rpc', // Direct DB queries, no LLM
    instructions: '''
Fetch relevant data from Supabase based on intent:
- Use RPC calls for complex aggregations
- Respect company_id isolation
- Apply date ranges intelligently
- Return structured data for Analyzer
''',
    toolNames: [
      'supabase_query',
      'supabase_rpc',
      'date_range_calc',
    ],
  );

  // ─── Analyzer Agent ───────────────────────────────────────────
  static const analyzer = AgentDefinition(
    id: 'sabo-analyzer',
    displayName: 'Business Analyzer',
    role: AgentRole.analyzer,
    model: 'gemini-2.0-flash',
    instructions: '''
Bạn là chuyên gia phân tích kinh doanh của SABOHUB.
Nhận dữ liệu thực từ Data Fetcher, phân tích và đưa ra:
1. Tóm tắt ngắn gọn (2-3 câu)
2. Số liệu nổi bật (bold)
3. So sánh với kỳ trước nếu có
4. Phát hiện bất thường (anomaly detection)
5. Đề xuất hành động cụ thể (1-2 bullet)
Trả lời bằng tiếng Việt, dùng emoji phù hợp.
''',
    toolNames: ['gemini_analyze', 'trend_detect', 'anomaly_detect'],
    temperature: 0.3,
    maxTokens: 1024,
  );

  // ─── Responder Agent ──────────────────────────────────────────
  static const responder = AgentDefinition(
    id: 'sabo-responder',
    displayName: 'Response Formatter',
    role: AgentRole.responder,
    model: 'template-engine', // Mostly template-based, minimal LLM
    instructions: '''
Format the final response for the user:
- Combine data + analysis into a readable format
- Use markdown: **bold** for numbers, bullet points for lists
- Add relevant emoji for visual scanning
- Keep under 500 words
- End with a suggested follow-up question
''',
    toolNames: ['format_markdown', 'add_chart_data'],
  );

  // ─── Reviewer Agent ───────────────────────────────────────────
  static const reviewer = AgentDefinition(
    id: 'sabo-reviewer',
    displayName: 'Quality Reviewer',
    role: AgentRole.reviewer,
    model: 'rule-based',
    instructions: '''
Validate output quality before delivery:
- Check data accuracy (numbers match source)
- Verify response is in Vietnamese
- Ensure no sensitive data leakage
- Check response length (not too short, not too long)
- Verify emoji/formatting is consistent
- Score confidence based on data completeness
''',
    toolNames: ['validate_numbers', 'check_language', 'score_confidence'],
  );

  // ─── Planner Agent ────────────────────────────────────────────
  static const planner = AgentDefinition(
    id: 'sabo-planner',
    displayName: 'Task Planner',
    role: AgentRole.planner,
    model: 'gemini-2.0-flash',
    instructions: '''
For complex multi-step queries, create an execution plan:
1. Break down the query into sub-tasks
2. Determine data dependencies
3. Parallelize independent fetches
4. Order dependent analyses
5. Estimate execution time
Example: "So sánh doanh thu tuần này vs tuần trước"
→ Step 1: Fetch this week revenue (parallel)
→ Step 2: Fetch last week revenue (parallel)
→ Step 3: Calculate delta + percentage
→ Step 4: Analyze trend
→ Step 5: Format comparison
''',
    toolNames: ['plan_steps', 'estimate_time', 'spawn_subagent'],
    subAgentIds: ['sabo-data-fetcher', 'sabo-analyzer'],
    temperature: 0.2,
  );

  /// All registered agents
  static const List<AgentDefinition> all = [
    router,
    dataFetcher,
    analyzer,
    responder,
    reviewer,
    planner,
  ];

  /// Get agent by ID
  static AgentDefinition? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get agent by role
  static AgentDefinition? byRole(AgentRole role) {
    try {
      return all.firstWhere((a) => a.role == role);
    } catch (_) {
      return null;
    }
  }
}
