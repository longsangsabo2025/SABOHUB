// Follow Deno's best practices for Edge Functions
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.7.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ProcessFileRequest {
  file_id: string
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
    const { file_id }: ProcessFileRequest = await req.json()

    if (!file_id) {
      return new Response(JSON.stringify({ error: 'Missing file_id' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Get file record
    const { data: fileRecord, error: fileError } = await supabaseClient
      .from('ai_uploaded_files')
      .select('*')
      .eq('id', file_id)
      .single()

    if (fileError || !fileRecord) {
      return new Response(JSON.stringify({ error: 'File not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Update status to processing
    await supabaseClient
      .from('ai_uploaded_files')
      .update({ processing_status: 'processing' })
      .eq('id', file_id)

    try {
      // Download file from storage
      const { data: fileData, error: downloadError } = await supabaseClient.storage
        .from('ai-files')
        .download(fileRecord.storage_path)

      if (downloadError || !fileData) {
        throw new Error(`Failed to download file: ${downloadError?.message}`)
      }

      let extractedText = ''
      let analysis: any = null

      // Process based on file type
      if (fileRecord.file_type === 'image') {
        // Use OpenAI Vision API for image analysis
        analysis = await analyzeImage(fileData, fileRecord.file_name)
        extractedText = analysis.description || ''
      } else if (fileRecord.file_type === 'pdf') {
        // For PDF, we would need a PDF parsing library
        // For now, just mark as processed
        extractedText = 'PDF processing not yet implemented'
      } else if (fileRecord.file_type === 'text') {
        // Read text file
        extractedText = await fileData.text()
      } else {
        extractedText = `File type ${fileRecord.file_type} processing not yet implemented`
      }

      // Update file record with results
      await supabaseClient
        .from('ai_uploaded_files')
        .update({
          processing_status: 'completed',
          extracted_text: extractedText,
          analysis: analysis || {},
        })
        .eq('id', file_id)

      return new Response(
        JSON.stringify({
          success: true,
          extracted_text: extractedText,
          analysis,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    } catch (processingError: any) {
      // Update status to failed
      await supabaseClient
        .from('ai_uploaded_files')
        .update({
          processing_status: 'failed',
          processing_error: processingError.message,
        })
        .eq('id', file_id)

      throw processingError
    }
  } catch (error: any) {
    console.error('Error in process-file function:', error)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})

async function analyzeImage(imageData: Blob, fileName: string): Promise<any> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured')
  }

  try {
    // Convert image to base64
    const arrayBuffer = await imageData.arrayBuffer()
    const base64 = btoa(String.fromCharCode(...new Uint8Array(arrayBuffer)))
    const mimeType = imageData.type || 'image/jpeg'

    // Call OpenAI Vision API
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${openaiApiKey}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-vision-preview',
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Phân tích chi tiết hình ảnh này cho một nhà hàng/quán ăn. Hãy mô tả:
1. Những gì bạn nhìn thấy trong hình
2. Đánh giá về không gian, bài trí
3. Đề xuất cải thiện nếu có
4. Các yếu tố nổi bật

Trả lời bằng tiếng Việt một cách chi tiết và chuyên nghiệp.`,
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${base64}`,
                },
              },
            ],
          },
        ],
        max_tokens: 1000,
      }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`OpenAI Vision API error: ${error}`)
    }

    const result = await response.json()
    const description = result.choices[0].message.content

    return {
      description,
      model: 'gpt-4-vision-preview',
      analyzed_at: new Date().toISOString(),
      file_name: fileName,
      insights: extractInsights(description),
    }
  } catch (error: any) {
    console.error('Image analysis error:', error)
    throw new Error(`Failed to analyze image: ${error.message}`)
  }
}

function extractInsights(description: string): string[] {
  // Simple keyword extraction for insights
  const insights = []
  const text = description.toLowerCase()

  if (text.includes('sạch sẽ') || text.includes('gọn gàng')) {
    insights.push('Không gian sạch sẽ')
  }
  if (text.includes('đông khách') || text.includes('đông người')) {
    insights.push('Lượng khách đông')
  }
  if (text.includes('ánh sáng')) {
    insights.push('Ánh sáng được chú ý')
  }
  if (text.includes('bài trí') || text.includes('decor')) {
    insights.push('Có nhận xét về bài trí')
  }
  if (text.includes('cải thiện') || text.includes('đề xuất')) {
    insights.push('Có đề xuất cải thiện')
  }

  return insights
}

/* To deploy:
1. Ensure you have Supabase CLI installed
2. Set environment variables:
   - OPENAI_API_KEY: Your OpenAI API key
   - SUPABASE_URL: Your Supabase project URL
   - SUPABASE_ANON_KEY: Your Supabase anon key

3. Deploy:
   supabase functions deploy process-file

4. Test:
   curl -i --location --request POST 'https://your-project.supabase.co/functions/v1/process-file' \
     --header 'Authorization: Bearer YOUR_ANON_KEY' \
     --header 'Content-Type: application/json' \
     --data '{"file_id":"xxx"}'
*/
