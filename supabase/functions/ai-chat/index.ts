// Follow Deno's best practices for Edge Functions
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatRequest {
  assistant_id: string
  company_id: string
  message: string
  attachments?: Array<{ type: string; url: string }>
}

interface OpenAIMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Verify user is authenticated
    const {
      data: { user },
    } = await supabaseClient.auth.getUser()

    if (!user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Parse request body
    const { assistant_id, company_id, message, attachments }: ChatRequest = await req.json()

    if (!assistant_id || !company_id || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: assistant_id, company_id, message' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Get AI assistant record
    const { data: assistant, error: assistantError } = await supabaseClient
      .from('ai_assistants')
      .select('*')
      .eq('id', assistant_id)
      .eq('company_id', company_id)
      .single()

    if (assistantError || !assistant) {
      return new Response(JSON.stringify({ error: 'AI Assistant not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get company data for context
    const { data: company } = await supabaseClient
      .from('companies')
      .select('*')
      .eq('id', company_id)
      .single()

    // Get recent messages for context (last 10)
    const { data: recentMessages } = await supabaseClient
      .from('ai_messages')
      .select('role, content')
      .eq('assistant_id', assistant_id)
      .order('created_at', { ascending: false })
      .limit(10)

    // Build conversation context
    const conversationHistory: OpenAIMessage[] = (recentMessages || [])
      .reverse()
      .map((msg: any) => ({
        role: msg.role,
        content: msg.content,
      }))

    // Add system prompt with company context
    const systemPrompt = buildSystemPrompt(company, assistant)

    // Prepare messages for OpenAI
    const messages: OpenAIMessage[] = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory,
      { role: 'user', content: message },
    ]

    // Call OpenAI API
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiApiKey) {
      throw new Error('OpenAI API key not configured')
    }

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: assistant.model || 'gpt-4-turbo-preview',
        messages,
        temperature: assistant.temperature || 0.7,
        max_tokens: assistant.max_tokens || 2000,
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      throw new Error(`OpenAI API error: ${error}`)
    }

    const openaiData = await openaiResponse.json()
    const aiMessage = openaiData.choices[0].message.content
    const usage = openaiData.usage

    // Calculate cost (GPT-4 Turbo pricing: $0.01/1K prompt tokens, $0.03/1K completion tokens)
    const promptCost = (usage.prompt_tokens / 1000) * 0.01
    const completionCost = (usage.completion_tokens / 1000) * 0.03
    const totalCost = promptCost + completionCost

    // Analyze message for recommendations (if enabled)
    let analysis = null
    if (assistant.auto_generate_recommendations) {
      analysis = await analyzeForRecommendations(aiMessage, company_id, assistant_id)
    }

    // Return AI response
    return new Response(
      JSON.stringify({
        content: aiMessage,
        prompt_tokens: usage.prompt_tokens,
        completion_tokens: usage.completion_tokens,
        total_tokens: usage.total_tokens,
        estimated_cost: totalCost,
        analysis,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Error in ai-chat function:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

function buildSystemPrompt(company: any, assistant: any): string {
  const companyContext = company
    ? `
Thông tin về công ty:
- Tên: ${company.name}
- Loại hình: ${company.type || 'N/A'}
- Ngành nghề: ${company.industry || 'N/A'}
- Địa chỉ: ${company.address || 'N/A'}
- Số điện thoại: ${company.phone || 'N/A'}
- Email: ${company.email || 'N/A'}
- Website: ${company.website || 'N/A'}
`
    : ''

  return `Bạn là trợ lý AI chuyên nghiệp của SaboHub, một hệ thống quản lý nhà hàng thông minh.

${companyContext}

Nhiệm vụ của bạn:
1. Phân tích và đưa ra các đề xuất cải thiện dựa trên dữ liệu của công ty
2. Trả lời các câu hỏi về hoạt động kinh doanh
3. Tạo các báo cáo và phân tích chi tiết
4. Đề xuất các chiến lược tăng trưởng
5. Phân tích hình ảnh và tài liệu liên quan đến nhà hàng

Hướng dẫn:
- Trả lời bằng tiếng Việt, chuyên nghiệp và dễ hiểu
- Đưa ra số liệu cụ thể khi có thể
- Đề xuất các giải pháp thực tế và khả thi
- Sử dụng emoji phù hợp để làm rõ ý (📊 📈 💰 🎯 ✅ ⚠️)
- Phân tích xu hướng và đưa ra dự đoán khi được yêu cầu
- Luôn đề cập đến ROI và lợi ích kinh doanh

${assistant.system_prompt || ''}`
}

async function analyzeForRecommendations(
  message: string,
  companyId: string,
  assistantId: string
): Promise<any> {
  // Simple keyword-based analysis
  // In production, you would use more sophisticated NLP
  const keywords = {
    revenue: ['doanh thu', 'revenue', 'bán hàng', 'sales'],
    cost: ['chi phí', 'cost', 'tiết kiệm', 'saving'],
    customer: ['khách hàng', 'customer', 'satisfaction'],
    process: ['quy trình', 'process', 'workflow'],
    technology: ['công nghệ', 'technology', 'digital'],
  }

  const categories = []
  for (const [category, words] of Object.entries(keywords)) {
    if (words.some((word) => message.toLowerCase().includes(word))) {
      categories.push(category)
    }
  }

  return {
    detected_topics: categories,
    recommendation_potential: categories.length > 0 ? 'high' : 'low',
    suggested_categories: categories,
  }
}

/* To deploy:
1. Ensure you have Supabase CLI installed
2. Set environment variables:
   - OPENAI_API_KEY: Your OpenAI API key
   - SUPABASE_URL: Your Supabase project URL
   - SUPABASE_ANON_KEY: Your Supabase anon key

3. Deploy:
   supabase functions deploy ai-chat

4. Test:
   curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/ai-chat' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"assistant_id":"xxx","company_id":"xxx","message":"Hello"}'
*/
